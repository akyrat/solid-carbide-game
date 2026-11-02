"""The scaling scan's maths and report (task T-493): which screens shrink as the window grows.

Coverage of a screen = the bounding box of its visible content Controls (screen_gallery.gd's "pieces")
as a share of the window area. A screen that scales with the window keeps its coverage; one that
stays the same pixel size on a bigger window loses it in proportion to the window's area.
Used by screen_gallery.py --sizes; no Godot in here, so the tests run on plain data.
"""
import json
from pathlib import Path

BASE = (1280, 720)
SIZES = [(1280, 720), (1920, 1080), (2560, 1440), (3840, 2160), (3440, 1440)]
SCREEN_FLAG = 0.85  # a screen's coverage under this share of its 1280 x 720 coverage is flagged
PIECE_FLAG = 0.70   # the same for one piece's area share
MIN_PIECE = 0.002   # pieces under 0.2% of the 1280 x 720 window are ignored (hairlines, dots)


def bbox(rects):
    """(x, y, w, h) of the union of [x, y, w, h] rects, or None when there are none."""
    if not rects:
        return None
    x0 = min(r[0] for r in rects)
    y0 = min(r[1] for r in rects)
    x1 = max(r[0] + r[2] for r in rects)
    y1 = max(r[1] + r[3] for r in rects)
    return (x0, y0, x1 - x0, y1 - y0)


def coverage(pieces, window):
    """Share (0..1) of the window the pieces' bounding box covers."""
    b = bbox([p["rect"] for p in pieces])
    if b is None:
        return 0.0
    return min(1.0, b[2] * b[3] / (window[0] * window[1]))


CONTAINERS = ("Panel", "PanelContainer")


def content_share(pieces, window):
    """Summed area share of the leaf pieces (labels, buttons, pictures, sliders; not panels), 0..1."""
    total = sum(p["rect"][2] * p["rect"][3] for p in pieces if p["class"] not in CONTAINERS)
    return min(1.0, total / (window[0] * window[1]))


def piece_share(piece, window):
    return piece["rect"][2] * piece["rect"][3] / (window[0] * window[1])


def ratio(value, base):
    return value / base if base > 0 else 1.0


def screen_result(pieces_by_size, windows=None):
    """pieces_by_size: {(w, h): [pieces]} -> coverage per size, ratios to 1280 x 720, and flags."""
    windows = windows or {}
    win = lambda size: tuple(windows.get(size, size))
    base_pieces = pieces_by_size.get(BASE, [])
    base_cov = coverage(base_pieces, BASE)
    cov = {f"{w}x{h}": coverage(p, win((w, h))) for (w, h), p in pieces_by_size.items()}
    bbox_ratios = {k: ratio(v, base_cov) for k, v in cov.items()}
    base_content = content_share(base_pieces, BASE)
    content = {f"{w}x{h}": content_share(p, win((w, h))) for (w, h), p in pieces_by_size.items()}
    content_ratios = {k: ratio(v, base_content) for k, v in content.items()}
    ratios = {k: min(bbox_ratios[k], content_ratios[k]) for k in bbox_ratios}
    base_by_path = {p["path"]: p for p in base_pieces}
    shrunk = {}
    for (w, h), pieces in pieces_by_size.items():
        if (w, h) == BASE:
            continue
        for p in pieces:
            b = base_by_path.get(p["path"])
            if b is None or piece_share(b, BASE) < MIN_PIECE:
                continue
            r = ratio(piece_share(p, win((w, h))), piece_share(b, BASE))
            if r < PIECE_FLAG:
                e = shrunk.setdefault(p["path"], {"path": p["path"], "class": p["class"], "base_share": piece_share(b, BASE), "ratios": {}})
                e["ratios"][f"{w}x{h}"] = r
    pieces = sorted(shrunk.values(), key=lambda e: min(e["ratios"].values()))
    others = [r for k, r in ratios.items() if k != "1280x720"]
    worst = min(others) if others else 1.0
    return {"coverage": cov, "content": content, "bbox_ratios": bbox_ratios, "content_ratios": content_ratios, "ratios": ratios, "worst_ratio": worst,
            "flagged": worst < SCREEN_FLAG, "shrinking_pieces": pieces}


def build_report(manifests):
    """manifests: {(w, h): manifest dict from the gallery}. -> {screens: {name: result}, order: worst first}."""
    names = []
    for m in manifests.values():
        for s in m["screens"]:
            if s["name"] not in names:
                names.append(s["name"])
    screens = {}
    for n in names:
        by_size, missing, windows = {}, [], {}
        for size, m in manifests.items():
            hit = next((s for s in m["screens"] if s["name"] == n), None)
            if hit is None:
                missing.append(f"{size[0]}x{size[1]}")
            else:
                by_size[size] = hit["pieces"]
                windows[size] = tuple(hit.get("image_size", size))
        if BASE in by_size:
            res = screen_result(by_size, windows)
        else:
            res = {"coverage": {}, "ratios": {}, "worst_ratio": 1.0, "flagged": False, "shrinking_pieces": []}
        res["missing_at"] = missing
        screens[n] = res
    order = sorted(screens, key=lambda n: screens[n]["worst_ratio"])
    return {"base": list(BASE), "sizes": [f"{w}x{h}" for w, h in SIZES], "screen_flag": SCREEN_FLAG,
            "piece_flag": PIECE_FLAG, "order": order, "screens": screens}


def write_markdown(report, path, notes=""):
    sizes = report["sizes"]
    lines = ["# Scaling report (T-493)", "",
             "Coverage = bounding box of a screen's visible content Controls as a share of the window; ratio = the worse of the bounding box's and the summed leaf-content area's (labels, buttons, pictures, sliders) against 1280x720. "
             f"A screen is flagged when its coverage at any size drops under {report['screen_flag']:.0%} of its 1280x720 coverage; "
             f"a piece when its area share drops under {report['piece_flag']:.0%}.", ""]
    if notes:
        lines += [notes, ""]
    flagged = [n for n in report["order"] if report["screens"][n]["flagged"]]
    lines += [f"## All screens ({len(flagged)} of {len(report['order'])} flagged), worst first", ""]
    lines += ["| Screen | " + " | ".join(sizes) + " |", "|---|" + "---|" * len(sizes)]
    for n in report["order"]:
        r = report["screens"][n]
        cells = []
        for s in sizes:
            c, q = r["coverage"].get(s), r["ratios"].get(s)
            cells.append("-" if c is None else f"{c:.0%} ({q:.2f}x)")
        name = "**" + n + "**" if r["flagged"] else n
        lines.append(f"| {name} | " + " | ".join(cells) + " |")
    lines += ["", "Cells: coverage (ratio to 1280x720). Bold = flagged.", ""]
    for n in flagged:
        r = report["screens"][n]
        lines += [f"## {n}", "", f"Contact sheet: `contact_sheets/{n}.png`. Worst ratio {r['worst_ratio']:.2f}.", ""]
        for e in r["shrinking_pieces"][:12]:
            worst = min(e["ratios"].values())
            lines.append(f"- `{e['path']}` ({e['class']}): area share at 1280x720 {e['base_share']:.1%}, worst ratio {worst:.2f}")
        if len(r["shrinking_pieces"]) > 12:
            lines.append(f"- ... {len(r['shrinking_pieces']) - 12} more pieces in the JSON")
        lines.append("")
    Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8")


def contact_sheet(images, labels, path, cell_h=360):
    """Side by side, each image scaled to cell_h tall, labelled. images are PIL images."""
    from PIL import Image, ImageDraw
    cells = []
    for im in images:
        w = max(1, round(im.width * cell_h / im.height))
        cells.append(im.convert("RGB").resize((w, cell_h), Image.LANCZOS))
    pad, bar = 6, 16
    sheet = Image.new("RGB", (sum(c.width for c in cells) + pad * (len(cells) + 1), cell_h + bar + pad * 2), (30, 30, 34))
    d = ImageDraw.Draw(sheet)
    x = pad
    for c, lab in zip(cells, labels):
        d.text((x, 2), lab, fill=(230, 230, 230))
        sheet.paste(c, (x, bar + pad))
        x += c.width + pad
    sheet.save(path)


def save_json(report, path):
    Path(path).write_text(json.dumps(report, indent=1) + "\n", encoding="utf-8")

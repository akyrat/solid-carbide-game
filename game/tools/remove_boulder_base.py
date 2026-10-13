"""Remove the stone disc under T-065's first sample boulder, keeping only the rock (free fix, no PixelLab).

Usage (from the repo root):
  python game/tools/remove_boulder_base.py build      # writes the cleaned sprite, its record and the previews
  python game/tools/remove_boulder_base.py check      # rebuilds in memory and compares with the committed files

Input:  art-archive/T-065/boulder_sample.png (the first sample, 160 x 160, 30 colours).
Output: art-archive/T-065/boulder_sample_nobase.png (+ .json record) and three previews.

How the rock is separated from the disc
- Above row SPLIT_ROW the sprite is only the rock (the disc starts at row 81), so every pixel there is kept as it is.
- From SPLIT_ROW down, the rock's lower edge is traced along its existing dark outline: rays from a point
  inside the rock's bottom look for an outline-coloured pixel near a rounded guide curve (a superellipse
  fitted by eye to the egg's lower half). Rays that find none, or find a pixel far from their neighbours
  (a disc tile line, a crack), fall back to the smoothed neighbours. The traced points form a polygon; pixels
  of the original inside it are kept, everything else below SPLIT_ROW (the disc, its pebbles, its magenta
  edge) becomes transparent.
- The rock's new lower edge: every kept pixel below SPLIT_ROW that touches a transparent pixel (4-neighbours)
  is set to the sprite's own outline colour, so the bottom gets one clean dark line like the rest of the
  outline. Where the disc hid the rock's bottom (the crack running into the disc), the polygon closes it
  with the guide curve, so the edge there is a short curve in the same outline colour.
- Nothing else changes: no new colours, no semi-transparent pixels, the canvas stays 160 x 160 and the
  rock stays where it was.
"""
import argparse
import json
import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
ARCHIVE = os.path.join(REPO, "art-archive", "T-065")
SRC = os.path.join(ARCHIVE, "boulder_sample.png")
OUT = os.path.join(ARCHIVE, "boulder_sample_nobase.png")
OUT_JSON = os.path.join(ARCHIVE, "boulder_sample_nobase.json")
PREVIEW = os.path.join(ARCHIVE, "boulder_sample_nobase_preview.png")
COMPARE = os.path.join(ARCHIVE, "boulder_sample_nobase_compare.png")
CAR_SCALE = os.path.join(ARCHIVE, "boulder_sample_nobase_car_scale.png")
CAR_SHEET = os.path.join(REPO, "game", "art", "car", "car_iso.png")
CAR_JSON = os.path.join(REPO, "game", "art", "car", "car_iso.json")

OUTLINE = (3, 3, 2)          # the sprite's own darkest outline colour
SPLIT_ROW = 81               # first row where the disc appears
CENTER = (81.5, 88.0)        # ray origin, inside the rock's bottom
GUIDE = (47.0, 31.0, 2.4)    # superellipse half-width, half-height, exponent (fitted by eye)
ANGLES = range(-12, 193)     # degrees, 0 = right, 90 = down
SEARCH = (-6.0, 4.0)         # how far inside / outside the guide curve a ray looks for the outline
OUTLIER_PX = 2.0             # a traced point this far from its neighbours' median radius is replaced
# The rock's lower right edge, rows 87 to 99, where the disc behind it hides the outline and the guide curve
# does not fit: pixel centres of the rock's own dark rim, read off the first sample (outline pixels at
# (127, 87), (125, 90) and (121, 99); dark rim pixels in between). They replace the traced points there.
RIGHT_EDGE = [(127, 87), (126, 89), (125, 91), (124, 93), (123, 94), (122, 96), (122, 97), (121, 98), (121, 99)]

DARK_BG = (24, 20, 38, 255)
LIGHT_BG = (232, 232, 236, 255)


def guide_radius(angle_deg, guide=GUIDE):
    a, b, n = guide
    t = math.radians(angle_deg)
    c, s = abs(math.cos(t)), abs(math.sin(t))
    return 1.0 / ((c / a) ** n + (s / b) ** n) ** (1.0 / n)


def trace_bottom(img, center=CENTER, guide=GUIDE, split_row=SPLIT_ROW, outline=OUTLINE):
    """Returns [(angle, radius)] of the rock's lower edge, one per angle in ANGLES."""
    w, h = img.size
    px = img.load()
    cx, cy = center
    found = []
    for d in ANGLES:
        t = math.radians(d)
        c, s = math.cos(t), math.sin(t)
        rexp = guide_radius(d, guide)
        best = None
        r = rexp + SEARCH[0]
        while r <= rexp + SEARCH[1] + 1e-9:
            x, y = int(math.floor(cx + r * c)), int(math.floor(cy + r * s))
            if y >= split_row and 0 <= x < w and y < h:
                p = px[x, y]
                if p[3] == 255 and p[:3] == outline and (best is None or abs(r - rexp) < abs(best - rexp)):
                    best = r
            r += 0.5
        found.append((d, best if best is not None else rexp, best is not None))
    # Replace outliers (disc tile lines, crack pixels) with the median of their neighbours.
    radii = [f[1] for f in found]
    clean = []
    for i, (d, r, hit) in enumerate(found):
        window = sorted(radii[max(0, i - 4):i + 5])
        med = window[len(window) // 2]
        clean.append((d, r if abs(r - med) <= OUTLIER_PX else med))
    return apply_anchors(clean, RIGHT_EDGE, center)


def apply_anchors(edge, anchors, center=CENTER):
    """Replaces the traced points whose angle lies within the anchors' angles with the anchors themselves."""
    if not anchors:
        return edge
    cx, cy = center
    pts = []
    for x, y in anchors:
        dx, dy = x + 0.5 - cx, y + 0.5 - cy
        pts.append((math.degrees(math.atan2(dy, dx)), math.hypot(dx, dy)))
    lo, hi = min(p[0] for p in pts), max(p[0] for p in pts)
    kept = [p for p in edge if not (lo <= p[0] <= hi)]
    return sorted(kept + pts, key=lambda p: p[0])


def point_in_polygon(x, y, poly):
    inside = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return inside


def rock_mask(img, center=CENTER, split_row=SPLIT_ROW):
    """Set of (x, y) kept as rock."""
    w, h = img.size
    px = img.load()
    cx, cy = center
    edge = trace_bottom(img, center=center, split_row=split_row)
    # Polygon through the traced pixels' outer corners (so the outline pixel itself is inside),
    # closed across the top at the split row, well outside the sprite's sides.
    poly = []
    for d, r in edge:
        t = math.radians(d)
        poly.append((cx + (r + 0.75) * math.cos(t), cy + (r + 0.75) * math.sin(t)))
    poly = [(poly[0][0], split_row - 1.0)] + poly + [(poly[-1][0], split_row - 1.0)]
    keep = set()
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            if y < split_row or point_in_polygon(x + 0.5, y + 0.5, poly):
                keep.add((x, y))
    # Drop pixels below the split that are no longer connected to the rock above it.
    seen = {p for p in keep if p[1] < split_row}
    stack = list(seen)
    while stack:
        x, y = stack.pop()
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if q in keep and q not in seen:
                seen.add(q)
                stack.append(q)
    return seen


def remove_base(img, split_row=SPLIT_ROW, outline=OUTLINE):
    """Returns (new RGBA image, stats)."""
    img = img.convert("RGBA")
    w, h = img.size
    src = img.load()
    keep = rock_mask(img, split_row=split_row)
    # Remove single-pixel spurs below the split (pixels with only one kept 4-neighbour), until none are left.
    changed = True
    spurs = 0
    while changed:
        changed = False
        for p in sorted(keep):
            x, y = p
            if y < split_row:
                continue
            n = sum(q in keep for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
            if n <= 1:
                keep.discard(p)
                spurs += 1
                changed = True
    # Start from a copy so everything kept (and every transparent pixel above the split) stays byte-identical.
    out = img.copy()
    dst = out.load()
    for y in range(split_row, h):
        for x in range(w):
            if (x, y) not in keep and src[x, y][3] == 255:
                dst[x, y] = (0, 0, 0, 0)
    # The outside: transparent pixels connected to the canvas border (the first sample's own transparent
    # holes inside the rock are not outside, so the pixels around them are left alone).
    outside = set()
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    stack = [p for p in stack if p not in keep]
    outside.update(stack)
    while stack:
        x, y = stack.pop()
        for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= q[0] < w and 0 <= q[1] < h and q not in keep and q not in outside:
                outside.add(q)
                stack.append(q)
    recoloured = 0
    for (x, y) in sorted(keep):
        if y < split_row:
            continue
        edge = any(q in outside for q in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
        if edge and dst[x, y][:3] != outline:
            dst[x, y] = outline + (255,)
            recoloured += 1
    removed = sum(1 for y in range(h) for x in range(w) if src[x, y][3] == 255) - len(keep)
    holes = sum(1 for y in range(h) for x in range(w) if (x, y) not in keep and (x, y) not in outside)
    return out, {"removed_pixels": removed, "outline_recoloured_pixels": recoloured, "spurs_removed": spurs,
                 "inner_transparent_pixels_left_as_they_were": holes}


def colours(img):
    return {p[:3] for p in img.getdata() if p[3] == 255}


def bbox(img):
    return img.getchannel("A").getbbox()


def on_bg(img, bg, scale):
    big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    canvas = Image.new("RGBA", big.size, bg)
    canvas.alpha_composite(big)
    return canvas


def preview(img, scale=4):
    """Dark and light background side by side."""
    a, b = on_bg(img, DARK_BG, scale), on_bg(img, LIGHT_BG, scale)
    out = Image.new("RGBA", (a.width * 2, a.height), DARK_BG)
    out.paste(a, (0, 0))
    out.paste(b, (a.width, 0))
    return out


def compare(before, after, scale=4):
    """Top row dark, bottom row light; original left, cleaned right."""
    cells = [[on_bg(before, DARK_BG, scale), on_bg(after, DARK_BG, scale)],
             [on_bg(before, LIGHT_BG, scale), on_bg(after, LIGHT_BG, scale)]]
    cw, ch = cells[0][0].size
    out = Image.new("RGBA", (cw * 2, ch * 2), DARK_BG)
    for r, row in enumerate(cells):
        for c, cell in enumerate(row):
            out.paste(cell, (c * cw, r * ch))
    return out


def car_scale_info(rock):
    """How the rock would be drawn next to the car, at the car's art scale.

    The car art is drawn at car_iso.json's px_per_unit (32 px per unit). The rock's widest row is matched
    to the 3-unit collision circle seen in the 2:1 isometric view: 3 * 32 * sqrt(2) = about 136 car-art
    pixels wide (a proposal; the draw scale is set when the art is swapped in).
    """
    with open(CAR_JSON) as f:
        car = json.load(f)
    ppu = car["car_size_px"]["length"] / car["car_size_units"]["length"]
    circle_w = 3.0 * ppu * math.sqrt(2.0)
    x0, y0, x1, y1 = bbox(rock)
    rock_w = x1 - x0
    return {"car_px_per_unit": ppu, "circle_width_car_px": circle_w, "rock_width_px": rock_w,
            "rock_height_px": y1 - y0, "scale": circle_w / rock_w}


def car_scale_preview(rock, zoom=3):
    """The car (frame 4, nose bottom-left) and the rock at the same game scale, on both backgrounds,
    with the 3-unit footprint ellipse drawn as a thin cyan guide under the rock."""
    from PIL import ImageDraw
    info = car_scale_info(rock)
    sheet = Image.open(CAR_SHEET).convert("RGBA")
    fw = sheet.height
    car = sheet.crop((4 * fw, 0, 5 * fw, fw))
    car = car.crop(bbox(car))
    car = car.resize((car.width * zoom, car.height * zoom), Image.NEAREST)
    r = rock.crop(bbox(rock))
    s = info["scale"] * zoom
    r = r.resize((round(r.width * s), round(r.height * s)), Image.NEAREST)
    pad = 24 * zoom
    gw = round(info["circle_width_car_px"] * zoom)
    gh = gw // 2
    W = pad + car.width + pad + max(r.width, gw) + pad
    H = pad + max(car.height, r.height) + pad
    panels = []
    for bg in (DARK_BG, LIGHT_BG):
        p = Image.new("RGBA", (W, H), bg)
        ground = pad + max(car.height, r.height)
        p.alpha_composite(car, (pad, ground - car.height))
        rx = pad + car.width + pad + (max(r.width, gw) - r.width) // 2
        ex = pad + car.width + pad + (max(r.width, gw) - gw) // 2
        # The 3-unit footprint guide: its front (lowest) point touches the rock's bottom row.
        d = ImageDraw.Draw(p)
        d.ellipse([ex, ground - gh, ex + gw, ground], outline=(0, 230, 230, 255), width=max(1, zoom // 2))
        p.alpha_composite(r, (rx, ground - r.height))
        panels.append(p)
    out = Image.new("RGBA", (W * 2, H), DARK_BG)
    out.paste(panels[0], (0, 0))
    out.paste(panels[1], (W, 0))
    return out, info


def record(src_img, out_img, stats, info):
    x0, y0, x1, y1 = bbox(out_img)
    return {
        "file": "boulder_sample_nobase.png",
        "source": "art-archive/T-065/boulder_sample.png (the first sample: one PixelLab /create-image-pixflux call, palette reduced to 30; see boulder_sample.json and boulder_sample_raw.json)",
        "made_by": "python game/tools/remove_boulder_base.py build",
        "change": ("the stone disc, its pebbles and its magenta edge removed below row %d (rows above it unchanged); "
                   "the rock's lower edge traced along its own dark outline, gaps closed with a rounded guide curve; "
                   "every rock pixel on the new lower edge set to the sprite's outline colour %s; no new colours"
                   % (SPLIT_ROW, list(OUTLINE))),
        "canvas": "kept at 160 x 160, the rock in the same place as in the first sample (not trimmed)",
        "image": {"width": out_img.width, "height": out_img.height},
        "rock_bbox": {"x0": x0, "y0": y0, "x1": x1 - 1, "y1": y1 - 1, "width": x1 - x0, "height": y1 - y0},
        "colours_before": len(colours(src_img)),
        "colours_after": len(colours(out_img)),
        "new_colours": len(colours(out_img) - colours(src_img)),
        "stats": stats,
        "car_scale_preview": {k: round(v, 3) for k, v in info.items()},
        "known_issue": ("the first sample already has %d fully transparent pixels inside the rock (mostly in the crack glow); "
                        "left as they are" % stats["inner_transparent_pixels_left_as_they_were"]),
        "pixellab_calls": 0,
        "task": "T-065",
        "status": "sample for the board's review, not game-ready",
    }


def build_all():
    src = Image.open(SRC).convert("RGBA")
    out, stats = remove_base(src)
    info = car_scale_info(out)
    return src, out, stats, info


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=["build", "check"])
    args = ap.parse_args(argv)
    src, out, stats, info = build_all()
    rec = record(src, out, stats, info)
    if args.command == "build":
        out.save(OUT)
        with open(OUT_JSON, "w", newline="\n") as f:
            json.dump(rec, f, indent=2)
            f.write("\n")
        preview(out).save(PREVIEW)
        compare(src, out).save(COMPARE)
        car_scale_preview(out)[0].save(CAR_SCALE)
        print(json.dumps(rec, indent=2))
        return 0
    committed = Image.open(OUT).convert("RGBA")
    same = committed.tobytes() == out.tobytes()
    print("committed sprite matches a fresh build: %s" % ("PASS" if same else "FAIL"))
    return 0 if same else 1


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Free checks and fixes for a redrawn car frame (T-584; Visual style, Decisions, "Redrawn car frames").

  python game/tools/car_frame_check.py strip CANDIDATE.png --frame K --out PNG [--scale 4]
        enlarged (nearest-neighbour) strip of live-sheet frames K-2..K+2 with CANDIDATE in slot K, dark and light
        backgrounds stacked, plus per-tile stats (opaque pixels, bbox, colours, shadow pixels).
  python game/tools/car_frame_check.py stats PNG [PNG ...]
        the same stats for any frames.
  python game/tools/car_frame_check.py shadow CANDIDATE.png --from NEIGHBOUR.png --out PNG
        copies the neighbour's drop-shadow pixels (the shadow colour) under the candidate where the candidate is
        transparent; the car's own pixels are never changed.
Every output is a new file; nothing is overwritten (the script refuses an existing --out).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
SHEET = REPO / "game/art/car/car_iso.png"
F = 128


def frame(k: int) -> Image.Image:
    sheet = Image.open(SHEET).convert("RGBA")
    return sheet.crop((k * F, 0, (k + 1) * F, F))


def shadow_colour(im: Image.Image):
    """The darkest fully opaque colour that sits below the car (the drop shadow), by count among the bottom rows."""
    px = im.load()
    counts: dict = {}
    for y in range(F):
        for x in range(F):
            p = px[x, y]
            if p[3] == 0:
                continue
            counts[p] = counts.get(p, 0) + 1
    return counts


def stats(im: Image.Image) -> dict:
    px = list(im.getdata())
    idx = [i for i, p in enumerate(px) if p[3] > 0]
    if not idx:
        return {"opaque_px": 0}
    xs = [i % F for i in idx]
    ys = [i // F for i in idx]
    return {"opaque_px": len(idx), "bbox": (min(xs), min(ys), max(xs), max(ys)),
            "colours": len({px[i] for i in idx}),
            "semi_transparent_px": sum(1 for i in idx if px[i][3] < 255)}


def refuse_existing(out: Path):
    if out.exists():
        sys.exit(f"refusing to overwrite {out}")
    out.parent.mkdir(parents=True, exist_ok=True)


def cmd_strip(a):
    cand = Image.open(a.candidate).convert("RGBA")
    ks = [k for k in range(a.frame - 2, a.frame + 3) if 0 <= k < 32]
    tiles = [(f"f{k}" + (" NEW" if k == a.frame else ""), cand if k == a.frame else frame(k)) for k in ks]
    if a.old:
        tiles.insert(ks.index(a.frame), (f"f{a.frame} old", frame(a.frame)))
    s = a.scale
    out = Image.new("RGBA", (F * s * len(tiles), F * s * 2), (0, 0, 0, 0))
    for row, bg in enumerate(((24, 24, 32, 255), (220, 220, 220, 255))):
        band = Image.new("RGBA", (F * s * len(tiles), F * s), bg)
        for i, (_, t) in enumerate(tiles):
            big = t.resize((F * s, F * s), Image.NEAREST)
            band.paste(big, (i * F * s, 0), big)
        out.paste(band, (0, row * F * s))
    refuse_existing(Path(a.out))
    out.save(a.out)
    print("strip ->", a.out, "order:", [n for n, _ in tiles])
    for n, t in tiles:
        print(f"{n:10s}", stats(t))


def cmd_stats(a):
    for p in a.pngs:
        print(p, stats(Image.open(p).convert("RGBA")))


def rows_of(im: Image.Image):
    px = list(im.getdata())
    return [px[y * F:(y + 1) * F] for y in range(F)]


def cmd_shadowstats(a):
    """Shadow pixels (build_car_noshadow's rule) and body bbox per frame, to compare a candidate with neighbours."""
    import build_car_noshadow as ns
    for p in a.pngs:
        im = Image.open(p).convert("RGBA")
        rows = rows_of(im)
        sh = ns.shadow_pixels(rows, 0, F)
        body = [(x, y) for y, r in enumerate(rows) for x, q in enumerate(r) if q[3] and (x, y) not in sh]
        bb = (min(x for x, _ in body), min(y for _, y in body), max(x for x, _ in body), max(y for _, y in body))
        sb = ((min(x for x, _ in sh), min(y for _, y in sh), max(x for x, _ in sh), max(y for _, y in sh))
              if sh else None)
        cols: dict = {}
        for (x, y) in sh:
            c = tuple(rows[y][x][:3])
            cols[c] = cols.get(c, 0) + 1
        print(p, {"shadow_px": len(sh), "shadow_bbox": sb, "body_bbox": bb, "shadow_colours": cols})


def cmd_zoom(a):
    tiles = [Image.open(p).convert("RGBA") for p in a.pngs]
    s = a.scale
    bg = (24, 24, 32, 255) if a.dark else (220, 220, 220, 255)
    out = Image.new("RGBA", (F * s * len(tiles), F * s), bg)
    for i, t in enumerate(tiles):
        big = t.resize((F * s, F * s), Image.NEAREST)
        out.paste(big, (i * F * s, 0), big)
    if a.crop:
        x0, y0, x1, y1 = (int(v) for v in a.crop.split(","))
        band = Image.new("RGBA", ((x1 - x0) * s * len(tiles), (y1 - y0) * s), bg)
        for i in range(len(tiles)):
            band.paste(out.crop((i * F * s + x0 * s, y0 * s, i * F * s + x1 * s, y1 * s)), (i * (x1 - x0) * s, 0))
        out = band
    refuse_existing(Path(a.out))
    out.save(a.out)
    print("zoom ->", a.out)


def cmd_shadow(a):
    cand = Image.open(a.candidate).convert("RGBA")
    nb = Image.open(a.source).convert("RGBA")
    colour = tuple(int(c) for c in a.colour.split(","))
    cp, np_ = cand.load(), nb.load()
    added = 0
    for y in range(F):
        for x in range(F):
            if np_[x, y][:3] == colour[:3] and np_[x, y][3] > 0 and cp[x, y][3] == 0:
                cp[x, y] = np_[x, y]
                added += 1
    refuse_existing(Path(a.out))
    cand.save(a.out)
    print("shadow pixels added:", added, "->", a.out)


NEAR_BLACK = {(6, 2, 27), (10, 4, 31), (12, 10, 33), (6, 9, 24), (8, 8, 15)}
N4 = ((1, 0), (-1, 0), (0, 1), (0, -1))
N8 = N4 + ((1, 1), (1, -1), (-1, 1), (-1, -1))


def lum(p) -> float:
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def islands(rows):
    """8-connected components of opaque pixels, largest first."""
    seen, comps = set(), []
    for y in range(F):
        for x in range(F):
            if rows[y][x][3] == 0 or (x, y) in seen:
                continue
            comp, stack = [], [(x, y)]
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                comp.append((cx, cy))
                for dx, dy in N8:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < F and 0 <= ny < F and rows[ny][nx][3] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            comps.append(comp)
    return sorted(comps, key=len, reverse=True)


def edge_report(rows) -> dict:
    """Edge pixels (opaque with a transparent 4-neighbour) and how many of them are not near-black."""
    edge = [(x, y) for y in range(F) for x in range(F) if rows[y][x][3]
            and any(0 <= x + dx < F and 0 <= y + dy < F and rows[y + dy][x + dx][3] == 0 for dx, dy in N4)]
    light = [p for p in edge if tuple(rows[p[1]][p[0]][:3]) not in NEAR_BLACK]
    bright = [p for p in light if lum(rows[p[1]][p[0]]) >= 150]
    return {"edge_px": len(edge), "edge_not_dark": len(light), "edge_bright_highlight": len(bright),
            "not_dark_share": round(len(light) / max(1, len(edge)), 3)}


def cmd_fix(a):
    """Free pixel fixes on a processed candidate: drop stray islands, close the outline round mid-tone edge
    pixels (bright highlights keep breaking it, as the style rule allows), add a drop shadow of the body
    shifted down by --shadow-dy in --shadow-colour where the frame is transparent. Only pixels that were
    transparent are ever painted, except the removed islands; the car's own pixels are kept."""
    im = Image.open(a.candidate).convert("RGBA")
    rows = [list(r) for r in rows_of(im)]
    print("before:", edge_report(rows))
    comps = islands(rows)
    removed = 0
    for comp in comps[1:]:
        if len(comp) <= a.max_island:
            for (x, y) in comp:
                rows[y][x] = (0, 0, 0, 0)
                removed += 1
    print("stray island pixels removed:", removed, "(islands:", [len(c) for c in comps], ")")
    outline = tuple(int(c) for c in a.outline_colour.split(",")) + (255,)
    added_outline = 0
    paint = set()
    for y in range(F):
        for x in range(F):
            p = rows[y][x]
            if p[3] == 0 or tuple(p[:3]) in NEAR_BLACK or lum(p) >= a.highlight:
                continue
            for dx, dy in N4:
                nx, ny = x + dx, y + dy
                if 0 <= nx < F and 0 <= ny < F and rows[ny][nx][3] == 0:
                    paint.add((nx, ny))
    for (x, y) in paint:
        rows[y][x] = outline
        added_outline += 1
    print("outline pixels added:", added_outline)
    shadow = tuple(int(c) for c in a.shadow_colour.split(",")) + (255,)
    added_shadow = 0
    if a.shadow_dy:
        body = {(x, y) for y in range(F) for x in range(F) if rows[y][x][3]}
        for (x, y) in body:
            for dy in range(1, a.shadow_dy + 1):
                nx, ny = x + a.shadow_dx, y + dy
                if 0 <= nx < F and 0 <= ny < F and rows[ny][nx][3] == 0:
                    rows[ny][nx] = shadow
                    added_shadow += 1
    print("shadow pixels added:", added_shadow)
    print("after:", edge_report(rows))
    out = Image.new("RGBA", (F, F))
    out.putdata([p for r in rows for p in r])
    refuse_existing(Path(a.out))
    out.save(a.out)
    print("fixed ->", a.out)


def majority(colours):
    counts: dict = {}
    for c in colours:
        counts[c] = counts.get(c, 0) + 1
    return max(counts, key=counts.get)


def despeckle(rows, contrast: float = 60.0, min_neighbours: int = 6) -> int:
    """Replaces interior specks: an opaque pixel with at least min_neighbours opaque 8-neighbours, none of them
    its own colour, whose brightness differs from the neighbours' majority colour by more than `contrast`. It takes
    that majority colour. Runs of two or more same-coloured pixels (stripe edges, panel lines) are never touched."""
    fixes = []
    for y in range(F):
        for x in range(F):
            p = rows[y][x]
            if p[3] != 255:
                continue
            nb = [rows[y + dy][x + dx] for dx, dy in N8 if 0 <= x + dx < F and 0 <= y + dy < F
                  and rows[y + dy][x + dx][3] == 255]
            if len(nb) < min_neighbours or any(q[:3] == p[:3] for q in nb):
                continue
            m = majority([q[:3] for q in nb])
            if abs(lum(p) - lum(m)) > contrast:
                fixes.append((x, y, m + (255,)))
    for x, y, c in fixes:
        rows[y][x] = c
    return len(fixes)


def row_diff(a, b) -> int:
    return sum(abs(p[i] - q[i]) for p, q in zip(a, b) for i in range(4))


def drop_rows(rows, n: int, band=(30, 100)) -> list:
    """Shortens the sprite by n rows: each time it removes the row in the band most like the row above it, and the
    rows above the cut move down by one (the bottom and the shadow stay put). Returns the rows removed, in order."""
    removed = []
    for _ in range(n):
        y0, y1 = band
        best = min(range(y0 + 1, y1), key=lambda y: row_diff(rows[y], rows[y - 1]))
        removed.append(best)
        del rows[best]
        rows.insert(0, [(0, 0, 0, 0)] * F)
    return removed


def smooth_shadow(rows, shadow, passes: int = 2):
    """Rounds the drop shadow's edge: a shadow-colour pixel with at most one opaque 4-neighbour goes transparent
    (a spike); a transparent pixel with three or more opaque 4-neighbours, all shadow-coloured or near-black, takes
    the shadow colour (a notch). The car's other pixels are never changed."""
    removed = added = 0
    dark = NEAR_BLACK | {tuple(shadow[:3])}
    for _ in range(passes):
        changes = []
        for y in range(F):
            for x in range(F):
                p = rows[y][x]
                nb = [rows[y + dy][x + dx] for dx, dy in N4 if 0 <= x + dx < F and 0 <= y + dy < F]
                opaque = [q for q in nb if q[3]]
                if p[3] and tuple(p[:3]) == tuple(shadow[:3]) and len(opaque) <= 1:
                    changes.append((x, y, (0, 0, 0, 0)))
                elif p[3] == 0 and len(opaque) >= 3 and all(tuple(q[:3]) in dark for q in opaque):
                    changes.append((x, y, tuple(shadow[:3]) + (255,)))
        for x, y, c in changes:
            rows[y][x] = c
            if c[3]:
                added += 1
            else:
                removed += 1
    return removed, added


def cmd_polish(a):
    """Free finish on a fixed candidate: despeckle, drop rows to the neighbours' height, smooth the shadow."""
    im = Image.open(a.candidate).convert("RGBA")
    rows = [list(r) for r in rows_of(im)]
    print("specks replaced:", despeckle(rows, a.contrast))
    if a.drop_rows:
        band = tuple(int(v) for v in a.band.split(","))
        print("rows dropped:", drop_rows(rows, a.drop_rows, band))
    shadow = tuple(int(c) for c in a.shadow_colour.split(","))
    if a.smooth_shadow:
        print("shadow spikes removed, notches filled:", smooth_shadow(rows, shadow, a.smooth_shadow))
    print("after:", edge_report(rows), "bbox:", stats(Image.frombytes("RGBA", (F, F), bytes(
        v for r in rows for p in r for v in p)))["bbox"])
    out = Image.new("RGBA", (F, F))
    out.putdata([tuple(p) for r in rows for p in r])
    refuse_existing(Path(a.out))
    out.save(a.out)
    print("polished ->", a.out)


def cmd_verify(a):
    """Free: the helper's own checks on a candidate for slot K without touching anything: every colour in the
    approved car palette, the centring shift `process` would apply, and the measured screen angle vs target."""
    import build_car_sheet as cs
    import redraw_car_frames as rc
    rows = cs.read_rows(Path(a.candidate))
    ref = cs.read_rows(rc.REPO / cs.REFERENCE)
    pal = cs.palette_of(ref)
    cols = cs.palette_of(rows)
    off = [c for c in cols if c not in pal]
    print(f"colours {len(cols)}, not in the approved palette: {off}")
    print("centring shift process would apply:", cs.centring_shift(rows, cs.bbox_centre(ref)))
    angle = rc.measure_rows(rows, a.frame)
    print(f"frame {a.frame}: nose seen at {angle} degrees on screen, target {rc.TARGETS[a.frame]} "
          f"({rc.mf.wrap180(angle - rc.TARGETS[a.frame]):+.1f} off)")


def cmd_centre(a):
    """Free: applies the whole-pixel centring `process` would apply (bbox centre to the reference's) and writes --out."""
    import build_car_sheet as cs
    import redraw_car_frames as rc
    rows = cs.read_rows(Path(a.candidate))
    ref = cs.read_rows(rc.REPO / cs.REFERENCE)
    dx, dy = cs.centring_shift(rows, cs.bbox_centre(ref))
    rc.save(cs.shift(rows, dx, dy), Path(a.out)) if not Path(a.out).exists() else sys.exit(f"refusing to overwrite {a.out}")
    print(f"shift ({dx}, {dy}) -> {a.out}")


def cmd_edges(a):
    for p in a.pngs:
        rows = rows_of(Image.open(p).convert("RGBA"))
        print(p, edge_report(rows), "islands:", [len(c) for c in islands(rows)][:8])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("strip")
    p.add_argument("candidate")
    p.add_argument("--frame", type=int, required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=4)
    p.add_argument("--old", action="store_true", help="also show the live sheet's current frame K")
    p.set_defaults(fn=cmd_strip)
    p = sub.add_parser("stats")
    p.add_argument("pngs", nargs="+")
    p.set_defaults(fn=cmd_stats)
    p = sub.add_parser("verify")
    p.add_argument("candidate")
    p.add_argument("--frame", type=int, required=True)
    p.set_defaults(fn=cmd_verify)
    p = sub.add_parser("centre")
    p.add_argument("candidate")
    p.add_argument("--out", required=True)
    p.set_defaults(fn=cmd_centre)
    p = sub.add_parser("edges")
    p.add_argument("pngs", nargs="+")
    p.set_defaults(fn=cmd_edges)
    p = sub.add_parser("fix")
    p.add_argument("candidate")
    p.add_argument("--out", required=True)
    p.add_argument("--max-island", type=int, default=3)
    p.add_argument("--outline-colour", default="6,2,27")
    p.add_argument("--highlight", type=float, default=150.0, help="edge pixels at least this bright keep breaking the outline")
    p.add_argument("--shadow-dy", type=int, default=0)
    p.add_argument("--shadow-dx", type=int, default=0)
    p.add_argument("--shadow-colour", default="10,4,31")
    p.set_defaults(fn=cmd_fix)
    p = sub.add_parser("polish")
    p.add_argument("candidate")
    p.add_argument("--out", required=True)
    p.add_argument("--contrast", type=float, default=60.0, help="brightness gap that makes a lone pixel a speck")
    p.add_argument("--drop-rows", type=int, default=0, help="rows to remove (the most redundant ones in --band)")
    p.add_argument("--band", default="30,100", help="y0,y1: rows that may be dropped")
    p.add_argument("--smooth-shadow", type=int, default=0, help="passes of shadow-edge smoothing")
    p.add_argument("--shadow-colour", default="10,4,31")
    p.set_defaults(fn=cmd_polish)
    p = sub.add_parser("shadowstats")
    p.add_argument("pngs", nargs="+")
    p.set_defaults(fn=cmd_shadowstats)
    p = sub.add_parser("zoom")
    p.add_argument("pngs", nargs="+")
    p.add_argument("--out", required=True)
    p.add_argument("--scale", type=int, default=6)
    p.add_argument("--crop", help="x0,y0,x1,y1 in frame pixels")
    p.add_argument("--dark", action="store_true")
    p.set_defaults(fn=cmd_zoom)
    p = sub.add_parser("shadow")
    p.add_argument("candidate")
    p.add_argument("--from", dest="source", required=True)
    p.add_argument("--colour", required=True, help="R,G,B of the shadow colour")
    p.add_argument("--out", required=True)
    p.set_defaults(fn=cmd_shadow)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()

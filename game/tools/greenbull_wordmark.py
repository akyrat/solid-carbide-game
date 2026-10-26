"""T-295 wordmark: Greenbull's emblem + GREENBULL in script-drawn pixel letters.

Free (no PixelLab). Letters are polygons rasterised at pixel centres (no anti-aliasing),
light green face, 3 px dark green drop shade below, 1 px near-black outline, then a
pixel-italic slant (1 px per 4 rows). The emblem (T-294, run 2) is pasted unchanged.

Version 1 of the style loop (code moved here from art-archive/T-295/style-loop/draw_v1.py).

Run (from the repo root):
    python game/tools/greenbull_wordmark.py art-archive/T-295/style-loop/v1.png
Run 2 (dark green leads): add --scheme dark (dark green face, 2 px light green top edge,
light green drop shade), e.g.
    python game/tools/greenbull_wordmark.py --scheme dark art-archive/T-295/style-loop/v1-2.png
It refuses to overwrite an existing file, so earlier loop versions are never lost.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
EMBLEM = ROOT / "art-archive" / "T-295" / "greenbull_emblem_64.png"

DARK = (12, 76, 44, 255)
LIGHT = (104, 220, 96, 255)
YELLOW = (247, 208, 52, 255)
OUTLINE = (14, 22, 18, 255)
CLEAR = (0, 0, 0, 0)

CANVAS = (256, 64)
WORD = "GREENBULL"
GLYPH_W, GLYPH_H = 16, 25
SPACING = 4          # px between letter boxes
SHADE = 3            # px drop shade straight down
SLANT_ROWS = 4       # shift 1 px right for every 4 rows up
GAP_AFTER_EMBLEM = 4


def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


# Each glyph: (outer polygon, [hole polygons]) in a 16 x 25 box.
GLYPHS = {
    "G": ([(4, 0), (16, 0), (16, 5), (5, 5), (5, 20), (11, 20), (11, 15), (8, 15), (8, 10),
           (16, 10), (16, 21), (12, 25), (4, 25), (0, 21), (0, 4)], []),
    "R": ([(0, 0), (12, 0), (16, 4), (16, 11), (13, 14), (16, 17), (16, 25), (11, 25), (11, 18),
           (8, 15), (5, 15), (5, 25), (0, 25)], [rect(5, 5, 11, 10)]),
    "E": ([(4, 0), (16, 0), (16, 5), (5, 5), (5, 10), (14, 10), (14, 15), (5, 15), (5, 20),
           (16, 20), (16, 25), (4, 25), (0, 21), (0, 4)], []),
    "N": ([(0, 0), (5, 0), (11, 11), (11, 0), (16, 0), (16, 25), (11, 25), (5, 14), (5, 25),
           (0, 25)], []),
    "B": ([(0, 0), (12, 0), (16, 4), (16, 10), (14, 12.5), (16, 15), (16, 21), (12, 25),
           (0, 25)], [rect(5, 5, 11, 10), rect(5, 15, 11, 20)]),
    "U": ([(0, 0), (5, 0), (5, 20), (11, 20), (11, 0), (16, 0), (16, 21), (12, 25), (4, 25),
           (0, 21)], []),
    "L": ([(0, 0), (5, 0), (5, 20), (16, 20), (16, 25), (4, 25), (0, 21)], []),
}


def inside(poly, px, py):
    """Even-odd point-in-polygon test."""
    hit = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > py) != (y2 > py):
            xc = x1 + (py - y1) * (x2 - x1) / (y2 - y1)
            if px < xc:
                hit = not hit
    return hit


def glyph_mask(ch):
    outer, holes = GLYPHS[ch]
    cells = set()
    for y in range(GLYPH_H):
        for x in range(GLYPH_W):
            cx, cy = x + 0.5, y + 0.5
            if inside(outer, cx, cy) and not any(inside(h, cx, cy) for h in holes):
                cells.add((x, y))
    return cells


# Colour schemes (run 1 = "light"; run 2 = "dark", where dark green leads as the board asked).
#   face: letter body colour; edge: colour of the face's top edge rows (None = no edge);
#   edge_rows: how many rows of the face's top edge; shade: drop shade colour.
SCHEMES = {
    "light": {"face": LIGHT, "edge": None, "edge_rows": 0, "shade": DARK},
    "dark": {"face": DARK, "edge": LIGHT, "edge_rows": 2, "shade": LIGHT},
}


def word_layer(word, scheme="light"):
    """Dict (x, y) -> colour for the word, before slant, origin at (1, 1)."""
    sc = SCHEMES[scheme]
    face = set()
    x0 = 1
    for ch in word:
        for (x, y) in glyph_mask(ch):
            face.add((x0 + x, 1 + y))
        x0 += GLYPH_W + SPACING
    shade = set()
    for (x, y) in face:
        for d in range(1, SHADE + 1):
            if (x, y + d) not in face:
                shade.add((x, y + d))
    body = face | shade
    outline = set()
    for (x, y) in body:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                p = (x + dx, y + dy)
                if p not in body:
                    outline.add(p)
    px = {p: OUTLINE for p in outline}
    px.update({p: sc["shade"] for p in shade})
    px.update({p: sc["face"] for p in face})
    if sc["edge"] is not None:
        for (x, y) in face:
            if any((x, y - d) not in face for d in range(1, sc["edge_rows"] + 1)):
                px[(x, y)] = sc["edge"]
    return px


def slant(px):
    max_y = max(y for _, y in px)
    return {(x + (max_y - y) // SLANT_ROWS, y): c for (x, y), c in px.items()}


def render(emblem_path=EMBLEM, scheme="light"):
    img = Image.new("RGBA", CANVAS, CLEAR)
    emblem = Image.open(emblem_path).convert("RGBA")
    img.paste(emblem, (0, (CANVAS[1] - emblem.height) // 2))

    px = slant(word_layer(WORD, scheme))
    min_x = min(x for x, _ in px); max_x = max(x for x, _ in px)
    min_y = min(y for _, y in px); max_y = max(y for _, y in px)
    w, h = max_x - min_x + 1, max_y - min_y + 1
    ox = emblem.width + GAP_AFTER_EMBLEM - min_x
    oy = (CANVAS[1] - h) // 2 - min_y
    if emblem.width + GAP_AFTER_EMBLEM + w > CANVAS[0]:
        raise ValueError(f"word too wide: {w}")
    for (x, y), c in px.items():
        img.putpixel((x + ox, y + oy), c)
    return img, emblem, (w, h)


def check(img, emblem):
    """Rule 1 and palette checks; returns a list of problems (empty = pass)."""
    problems = []
    cols = set(img.getdata())
    if any(c[3] not in (0, 255) for c in cols):
        problems.append("semi-transparent pixel")
    allowed = {c for c in emblem.getdata() if c[3] == 255} | {DARK, LIGHT, OUTLINE}
    extra = {c for c in cols if c[3] == 255} - allowed
    if extra:
        problems.append(f"colours outside the emblem palette: {sorted(extra)}")
    if img.getpixel((0, 0))[3] != 0 or img.getpixel((CANVAS[0] - 1, CANVAS[1] - 1))[3] != 0:
        problems.append("background corners not transparent")
    return problems


def main(argv):
    args = list(argv[1:])
    scheme = "light"
    if "--scheme" in args:
        i = args.index("--scheme")
        scheme = args[i + 1] if i + 1 < len(args) else ""
        del args[i:i + 2]
    if len(args) != 1 or scheme not in SCHEMES:
        print(__doc__)
        return 2
    out = Path(args[0])
    if out.exists():
        print(f"refusing to overwrite {out}")
        return 1
    img, emblem, (w, h) = render(scheme=scheme)
    problems = check(img, emblem)
    if problems:
        print("FAILED:", problems)
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    opaque = sorted({c for c in img.getdata() if c[3] == 255})
    print(f"saved {out} size={img.size} mode={img.mode} word={w}x{h} colours={opaque}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

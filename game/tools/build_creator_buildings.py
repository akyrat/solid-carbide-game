"""Draws the placeholder art of the level creator's small and long buildings (task T-254).

Reads data/level/creator_buildings.json (the one data file that names each piece's art per view and
mirror, with its footprint and anchor) and draws every texture it names as a flat box in the city's
palette B (Visual style, Decisions, "City colours": cool blue-grey walls, pale lit windows, never
Redgull red). Same input, same pixels. T-257 replaced the art (data paths now point to art/buildings/creator_final/, built by build_creator_buildings_art.py); this drawing only touches textures still under art/buildings/creator/.

  python game/tools/build_creator_buildings.py          draw the PNGs
  python game/tools/build_creator_buildings.py --check  check the data (anchors, files, colours)
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(HERE)
DATA = os.path.join(GAME, "data", "level", "creator_buildings.json")

# City palette B (city_palettes.py): roof, walls (+x face lighter than +y face), edge, lit windows.
ROOF = (156, 176, 196)
WALL_RIGHT = (96, 114, 134)
WALL_LEFT = (74, 92, 112)
EDGE = (20, 26, 36)
WINDOW = (214, 234, 250)
WINDOW_DIM = (130, 156, 180)
GLASS = (0, 0, 0, 0)
UNIT_ART = 32  # art px per unit of height; a ground unit is 16 screen px in x, 8 in y, doubled


def load():
    with open(DATA, encoding="utf-8") as f:
        return json.load(f)


def expected_anchor(w, h, height_units, scale=UNIT_ART):
    """Image size and the front corner's pixel for a box of footprint w x h and the given height."""
    up = round(height_units * scale)
    size = (round((w + h) * scale), up + round((w + h) * scale / 2))
    return size, (round(w * scale), size[1])


def draw_box(w, h, height_units, look):
    size, anchor = expected_anchor(w, h, height_units)
    ox = round(h * UNIT_ART)
    img = Image.new("RGBA", size, GLASS)
    d = ImageDraw.Draw(img)
    up = round(height_units * UNIT_ART)

    def g(x, y):  # a ground point (units from the box's top-left corner) in image pixels
        return (ox + (x - y) * UNIT_ART, up + (x + y) * UNIT_ART / 2)

    def lift(p, z):
        return (p[0], p[1] - z * UNIT_ART)

    a, b, c, dd = g(0, 0), g(w, 0), g(w, h), g(0, h)
    z = height_units
    d.polygon([dd, c, lift(c, z), lift(dd, z)], fill=WALL_LEFT)
    d.polygon([c, b, lift(b, z), lift(c, z)], fill=WALL_RIGHT)
    d.polygon([lift(a, z), lift(b, z), lift(c, z), lift(dd, z)], fill=ROOF)
    # Lit windows: columns every 1.5 units, two rows; the second look shifts the columns and dims the lower row.
    phase = 0.6 if look == 0 else 0.9
    for origin, along, length in ((dd, (1.0, 0.5), w), (c, (1.0, -0.5), h)):
        s = phase
        col = 0
        while s + 0.8 <= length - 0.3:
            for row, z0 in enumerate((0.7, 2.3)):
                lit = WINDOW if (look == 0 or row == 1 or col % 2 == 0) else WINDOW_DIM
                p0 = lift((origin[0] + along[0] * s * UNIT_ART, origin[1] + along[1] * s * UNIT_ART), z0)
                p1 = (p0[0] + along[0] * 0.8 * UNIT_ART, p0[1] + along[1] * 0.8 * UNIT_ART)
                d.polygon([p0, p1, lift(p1, 1.0), lift(p0, 1.0)], fill=lit)
            s += 1.5
            col += 1
    edges = [[lift(a, z), lift(b, z), lift(c, z), lift(dd, z), lift(a, z)], [dd, c, b], [dd, lift(dd, z)],
             [c, lift(c, z)], [b, lift(b, z)]]
    for line in edges:
        d.line(line, fill=EDGE, width=1)
    return img, anchor


def textures(data):
    for p in data["pieces"]:
        for t in p["textures"]:
            yield p, t


def res_path(res):
    return os.path.join(GAME, res.replace("res://", ""))


def build():
    data = load()
    for p, t in textures(data):
        if "/creator/" not in t["texture"]:  # final art (T-257) is never overwritten by the placeholder drawing
            continue
        w, h = t["footprint_units"]
        img, _ = draw_box(w, h, p["height_units"], int(t["variant"]))
        os.makedirs(os.path.dirname(res_path(t["texture"])), exist_ok=True)
        img.save(res_path(t["texture"]))


def check(data=None):
    """Problems with the data file: one line each (empty when fine)."""
    data = data or load()
    problems = []
    for p, t in textures(data):
        w, h = t["footprint_units"]
        size, anchor = expected_anchor(w, h, p["height_units"])
        if list(anchor) != list(t["anchor_art_px"]):
            problems.append("%s %s: anchor %s, expected %s" % (p["id"], t["view"], t["anchor_art_px"], list(anchor)))
        path = res_path(t["texture"])
        if os.path.isfile(path):
            im = Image.open(path).convert("RGBA")
            if im.size != size:
                problems.append("%s: size %s, expected %s" % (t["texture"], im.size, size))
            for r, g_, b, alpha in set(im.getdata()):
                if alpha not in (0, 255):
                    problems.append("%s: half-transparent pixel" % t["texture"])
                    break
                if alpha and r > 200 and g_ < 80 and b < 80:
                    problems.append("%s: Redgull red" % t["texture"])
                    break
        else:
            problems.append("%s: missing" % t["texture"])
        if t["view"] not in p["views"] or bool(t["mirror"]) not in p["mirrors"]:
            problems.append("%s: texture names a view or mirror the piece lacks" % p["id"])
    return problems


if __name__ == "__main__":
    if "--check" in sys.argv:
        ps = check()
        print("\n".join(ps) if ps else "OK")
        sys.exit(1 if ps else 0)
    build()
    print("Drew", sum(1 for _ in textures(load())), "textures")

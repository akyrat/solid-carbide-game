"""Builds T-065's game-ready boulder art from the two samples the board approved (free, no PixelLab).

Usage (from the repo root):
  python game/tools/build_boulder_art.py build    # writes game/art/boulders/ (sprites, records, boulders.json)
  python game/tools/build_boulder_art.py check    # rebuilds in memory and compares with the committed files

Inputs (kept in the archive, never changed):
- art-archive/T-065/boulder_sample_nobase.png: variant A, the first sample (PixelLab /create-image-pixflux)
  with its stone disc removed by game/tools/remove_boulder_base.py. Copied unchanged (160 x 160).
- art-archive/T-065/boulder_sample2.png: variant B, the low boxy second sample (PixelLab
  /create-image-bitforge), cleaned by a one-off stray-pixel cleanup and game/tools/reduce_palette.py.
  Its canvas is 160 x 128; it gets PAD_TOP fully transparent rows on top so every boulder frame is
  160 x 160 (no pixel of the rock changes, the rock keeps its place relative to the bottom).

With mirrors on (the default), each variant also gets a horizontally mirrored copy (A_mirror, B_mirror):
the same pixels flipped left to right, so four variants in all. The board can drop them with --no-mirrors.

boulders.json lists the variants in order, with each one's opaque bounding box and the convex hull of its
opaque pixels (art pixel corners). The map (scripts/level/mvp_map.gd) fits each sprite's bounding box
width to the 3-unit collision circle's on-screen width and uses the hull for its depth order.
"""
import argparse
import json
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
ARCHIVE = os.path.join(REPO, "art-archive", "T-065")
OUT_DIR = os.path.join(REPO, "game", "art", "boulders")
MANIFEST = "boulders.json"
FRAME = 160
PAD_TOP = 32  # variant B: 160 x 128 -> 160 x 160

SOURCES = [
    {
        "id": "a",
        "file": "boulder_a.png",
        "source": "art-archive/T-065/boulder_sample_nobase.png",
        "history": [
            "PixelLab POST /create-image-pixflux, 1 generation (record: art-archive/T-065/boulder_sample_raw.json; log: game/art/pixellab-generation-log.jsonl)",
            "palette 48 -> 30 colours by python game/tools/reduce_palette.py reduce (art-archive/T-065/boulder_sample.json)",
            "stone disc, pebbles and magenta rim removed, dark outline along the new bottom edge, by python game/tools/remove_boulder_base.py build (art-archive/T-065/boulder_sample_nobase.json)",
            "copied unchanged by python game/tools/build_boulder_art.py build",
        ],
        "pad_top": 0,
    },
    {
        "id": "b",
        "file": "boulder_b.png",
        "source": "art-archive/T-065/boulder_sample2.png",
        "history": [
            "PixelLab POST /create-image-bitforge with the first sample as style image (style strength 35), 1 generation (record: art-archive/T-065/boulder_sample2_raw.json; log: game/art/pixellab-generation-log.jsonl)",
            "one-off stray-pixel cleanup (thin 1-pixel lines and 5 detached specks removed), then palette 37 -> 30 colours by python game/tools/reduce_palette.py reduce (art-archive/T-065/boulder_sample2.json)",
            "padded from 160 x 128 to 160 x 160 with %d fully transparent rows on top by python game/tools/build_boulder_art.py build (no pixel of the rock changed)" % PAD_TOP,
        ],
        "pad_top": PAD_TOP,
    },
]


def opaque_bbox(img):
    """(x0, y0, x1, y1) of the opaque pixels, x1 and y1 exclusive."""
    return img.getchannel("A").getbbox()


def convex_hull(points):
    """Andrew's monotone chain; returns the hull counter-clockwise (in image coordinates), no repeats."""
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def opaque_hull(img):
    """Convex hull of the opaque pixels' corners (art pixels)."""
    a = img.getchannel("A")
    w, h = img.size
    px = a.load()
    pts = []
    for y in range(h):
        xs = [x for x in range(w) if px[x, y] == 255]
        if xs:
            for x in (xs[0], xs[-1] + 1):
                pts.append((x, y))
                pts.append((x, y + 1))
    return [list(p) for p in convex_hull(pts)]


def pad(img, top):
    if top == 0:
        return img.copy()
    out = Image.new("RGBA", (img.width, img.height + top), (0, 0, 0, 0))
    out.paste(img, (0, top))
    return out


def colours(img):
    return len({p[:3] for p in img.getdata() if p[3] == 255})


def build(mirrors=True):
    """Returns {file name: PIL image or JSON text} for everything in game/art/boulders/."""
    files, variants = {}, []
    for s in SOURCES:
        src = Image.open(os.path.join(REPO, s["source"])).convert("RGBA")
        base = pad(src, s["pad_top"])
        assert base.size == (FRAME, FRAME), base.size
        made = [(s["id"], s["file"], base, list(s["history"]), False)]
        if mirrors:
            m = base.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
            hist = list(s["history"]) + [
                "mirrored left to right (an extra variant; the same pixels) by python game/tools/build_boulder_art.py build"
            ]
            made.append((s["id"] + "_mirror", s["file"].replace(".png", "_mirror.png"), m, hist, True))
        for vid, name, img, hist, mirrored in made:
            x0, y0, x1, y1 = opaque_bbox(img)
            files[name] = img
            rec = {
                "file": name,
                "variant": vid,
                "source": s["source"],
                "mirrored": mirrored,
                "made_by": "python game/tools/build_boulder_art.py build",
                "history": hist,
                "image": {"width": img.width, "height": img.height},
                "bbox": {"x0": x0, "y0": y0, "x1": x1, "y1": y1, "width": x1 - x0, "height": y1 - y0},
                "colours": colours(img),
                "pixellab_calls_for_this_file": 0,
                "task": "T-065",
                "status": "game-ready (the board approved both samples as boulder variants, 2026-10-13)",
            }
            files[name.replace(".png", ".json")] = json.dumps(rec, indent=2) + "\n"
            variants.append({
                "id": vid,
                "texture": "res://art/boulders/" + name,
                "bbox": [x0, y0, x1, y1],
                "hull": opaque_hull(img),
            })
    manifest = {
        "about": "T-065 boulder variants (game/tools/build_boulder_art.py). bbox: opaque pixels [x0, y0, x1, y1), art pixels; hull: convex hull of the opaque pixels' corners. The map fits bbox width to the 3-unit collision circle's on-screen width and stands bbox bottom on the circle's front edge.",
        "frame": [FRAME, FRAME],
        "mirrors": mirrors,
        "variants": variants,
    }
    files[MANIFEST] = json.dumps(manifest, indent=2) + "\n"
    return files


def write(files, out_dir=OUT_DIR):
    os.makedirs(out_dir, exist_ok=True)
    for name, v in files.items():
        path = os.path.join(out_dir, name)
        if isinstance(v, str):
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(v)
        else:
            v.save(path)


def differences(files, out_dir=OUT_DIR):
    bad = []
    for name, v in files.items():
        path = os.path.join(out_dir, name)
        if not os.path.exists(path):
            bad.append(name + " missing")
            continue
        if isinstance(v, str):
            with open(path, encoding="utf-8") as f:
                if f.read() != v:
                    bad.append(name + " differs")
        else:
            cur = Image.open(path).convert("RGBA")
            if cur.size != v.size or list(cur.getdata()) != list(v.getdata()):
                bad.append(name + " differs")
    return bad


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("cmd", choices=["build", "check"])
    ap.add_argument("--no-mirrors", action="store_true", help="only the two approved variants, no mirrored copies")
    args = ap.parse_args(argv)
    files = build(mirrors=not args.no_mirrors)
    if args.cmd == "build":
        write(files)
        print("wrote %d files to %s" % (len(files), OUT_DIR))
        return 0
    bad = differences(files)
    for b in bad:
        print("FAIL", b)
    if not bad:
        print("OK: game/art/boulders matches a fresh build")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

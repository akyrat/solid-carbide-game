"""Side-by-side comparison sheet of the script and PixelLab trick illustrations (T-385).

One row per trick: script | PixelLab on a dark background, then the same on a light one,
enlarged with nearest filtering. Usage:
  python game/tools/compare_trick_sets.py <script_dir> <pixellab_dir> <out.png> [--scale 5]
"""
import argparse
import os

from PIL import Image, ImageDraw

IDS = ["extended_drift", "three_sixty", "alternate_drift", "air_one_eighty",
       "air_three_sixty", "airtime", "thread_the_needle"]
DARK = (24, 24, 32, 255)
LIGHT = (225, 225, 230, 255)


def build(script_dir, pixellab_dir, out, scale=5, ids=IDS):
    w, h = 64 * scale, 48 * scale
    pad, label_w = 8, 150
    cols = 4  # script dark, pixellab dark, script light, pixellab light
    width = label_w + cols * (w + pad) + pad
    head = 24
    sheet = Image.new("RGBA", (width, head + len(ids) * (h + pad) + pad), (90, 90, 90, 255))
    d = ImageDraw.Draw(sheet)
    titles = ["script / dark", "pixellab / dark", "script / light", "pixellab / light"]
    for c, t in enumerate(titles):
        d.text((label_w + c * (w + pad) + pad, 6), t, fill=(255, 255, 255, 255))
    for r, tid in enumerate(ids):
        y = head + r * (h + pad) + pad
        d.text((pad, y + h // 2), tid, fill=(255, 255, 255, 255))
        for c, (folder, bg) in enumerate([(script_dir, DARK), (pixellab_dir, DARK),
                                          (script_dir, LIGHT), (pixellab_dir, LIGHT)]):
            x = label_w + c * (w + pad) + pad
            cell = Image.new("RGBA", (w, h), bg)
            img = Image.open(os.path.join(folder, tid + ".png")).convert("RGBA")
            img = img.resize((w, h), Image.NEAREST)
            cell.alpha_composite(img)
            sheet.paste(cell, (x, y))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    sheet.save(out)
    return sheet.size


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("script_dir")
    ap.add_argument("pixellab_dir")
    ap.add_argument("out")
    ap.add_argument("--scale", type=int, default=5)
    a = ap.parse_args()
    print(build(a.script_dir, a.pixellab_dir, a.out, a.scale))

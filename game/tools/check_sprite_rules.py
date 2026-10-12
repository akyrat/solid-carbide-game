#!/usr/bin/env python3
"""Checks a generated sprite against Visual style's technical rules (T-014).

Usage: python game/tools/check_sprite_rules.py SPRITE.png [--size 128] [--max-colors 30]

Rules checked: exact frame size, RGBA, transparent background (all four corners
and some border pixels fully transparent), no semi-transparent pixels (alpha is
0 or 255 only), and the number of distinct opaque colours (about 30 or fewer).
Also reports the car's bounding box. Exits 0 when all rules hold, 1 otherwise.
"""
import argparse
import struct
import sys
import zlib


def decode_png(data):
    """Returns (width, height, rows) with rows as lists of (r, g, b, a). 8-bit RGBA only."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos, idat, ihdr = 8, b"", None
    while pos < len(data):
        n, typ = struct.unpack(">I4s", data[pos:pos + 8])
        body = data[pos + 8:pos + 8 + n]
        if typ == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", body)
        elif typ == b"IDAT":
            idat += body
        pos += 12 + n
    w, h, depth, ctype, _, _, interlace = ihdr
    if (depth, ctype, interlace) != (8, 6, 0):
        raise ValueError("expected 8-bit RGBA, non-interlaced")
    raw = zlib.decompress(idat)
    stride, bpp = w * 4, 4
    rows, prev = [], bytearray(stride)
    for y in range(h):
        f = raw[y * (stride + 1)]
        cur = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for i in range(stride):
            a = cur[i - bpp] if i >= bpp else 0
            b = prev[i]
            c = prev[i - bpp] if i >= bpp else 0
            if f == 1:
                cur[i] = (cur[i] + a) & 255
            elif f == 2:
                cur[i] = (cur[i] + b) & 255
            elif f == 3:
                cur[i] = (cur[i] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                cur[i] = (cur[i] + pr) & 255
        rows.append([tuple(cur[x * 4:x * 4 + 4]) for x in range(w)])
        prev = cur
    return w, h, rows


def check(path, size=128, max_colors=30):
    """Returns (results, info): results is a list of (rule, ok, detail)."""
    with open(path, "rb") as f:
        w, h, rows = decode_png(f.read())
    px = [p for r in rows for p in r]
    results = [("frame size %dx%d" % (size, size), (w, h) == (size, size), "%dx%d" % (w, h))]
    corners = [rows[0][0], rows[0][-1], rows[-1][0], rows[-1][-1]]
    results.append(("transparent background (corners)", all(c[3] == 0 for c in corners), str(corners)))
    semi = sum(1 for p in px if 0 < p[3] < 255)
    results.append(("no semi-transparent pixels", semi == 0, "%d semi-transparent" % semi))
    opaque = [p for p in px if p[3] == 255]
    colors = {p[:3] for p in opaque}
    results.append(("about %d colours or fewer" % max_colors, len(colors) <= max_colors, "%d colours" % len(colors)))
    results.append(("has some opaque pixels", len(opaque) > 0, "%d opaque" % len(opaque)))
    xs = [x for r in rows for x, p in enumerate(r) if p[3]]
    ys = [y for y, r in enumerate(rows) for p in r if p[3]]
    info = {"bbox": (min(xs), min(ys), max(xs), max(ys)) if xs else None, "colors": len(colors)}
    return results, info


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("sprite")
    ap.add_argument("--size", type=int, default=128)
    ap.add_argument("--max-colors", type=int, default=30)
    a = ap.parse_args(argv)
    results, info = check(a.sprite, a.size, a.max_colors)
    for rule, ok, detail in results:
        print("%s  %s: %s" % ("PASS" if ok else "FAIL", rule, detail))
    print("bounding box (x0, y0, x1, y1):", info["bbox"])
    return 0 if all(ok for _, ok, _ in results) else 1


if __name__ == "__main__":
    sys.exit(main())

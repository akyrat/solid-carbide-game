#!/usr/bin/env python3
"""Build the final Redgull logo files (T-075) from the board's pick.
128: the raw PixelLab output flattened to its own main red (135,17,27).
64 and 32: made from the 128 by area-averaging the alpha, then a hard threshold (no semi-transparent
pixels), then a small tidy so the eye cut-out and the beak tip survive:
  - the eye hole is kept at least 2x1 px (a 1-pixel hole is widened by one pixel to the right);
Usage: make_logo_sizes.py <raw.png> <out_dir>"""
import sys
from pathlib import Path
from PIL import Image

RED = (135, 17, 27, 255)


def flatten(im: Image.Image) -> Image.Image:
    """Every visible pixel (alpha >= 128) becomes RED; the rest transparent."""
    im = im.convert("RGBA")
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.putdata([RED if p[3] >= 128 else (0, 0, 0, 0) for p in im.getdata()])
    return out


def downscale(big: Image.Image, size: int) -> Image.Image:
    alpha = big.getchannel("A").resize((size, size), Image.BOX)
    mask = alpha.point(lambda v: 255 if v >= 128 else 0)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (size, size), RED), mask=mask)
    return out


def holes(im: Image.Image) -> list[list[tuple[int, int]]]:
    """Transparent regions fully enclosed by the shape (4-connected, not touching the border)."""
    w, h = im.size
    px = im.load()
    seen, found = set(), []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] or (x, y) in seen:
                continue
            stack, region, edge = [(x, y)], [], False
            seen.add((x, y))
            while stack:
                cx, cy = stack.pop()
                region.append((cx, cy))
                if cx in (0, w - 1) or cy in (0, h - 1):
                    edge = True
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not px[nx, ny][3] and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if not edge:
                found.append(region)
    return found


def tidy_eye(small: Image.Image, big: Image.Image) -> str:
    """Make sure the eye cut-out survives and is at least 2 px wide. Returns a note."""
    size = small.size[0]
    hs = holes(small)
    if not hs:
        # reopen the hole at the downscaled centre of the big eye hole
        eye = max(holes(big), key=len)
        cx = sum(p[0] for p in eye) / len(eye) * size / big.size[0]
        cy = sum(p[1] for p in eye) / len(eye) * size / big.size[1]
        x, y = int(cx), int(cy)
        small.putpixel((x, y), (0, 0, 0, 0))
        small.putpixel((x + 1, y), (0, 0, 0, 0))
        return f"eye hole had closed; reopened as 2x1 at ({x},{y})"
    eye = max(hs, key=len)
    if len(eye) == 1:
        x, y = eye[0]
        small.putpixel((x + 1, y), (0, 0, 0, 0))
        return f"1-px eye hole widened to 2x1 at ({x},{y})"
    return "eye hole fine, unchanged"


if __name__ == "__main__":
    raw, out = Path(sys.argv[1]), Path(sys.argv[2])
    big = flatten(Image.open(raw))
    big.save(out / "redgull_logo_128.png")
    for s in (64, 32):
        small = downscale(big, s)
        print(s, tidy_eye(small, big))
        small.save(out / f"redgull_logo_{s}.png")

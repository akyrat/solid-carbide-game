#!/usr/bin/env python3
"""The style guide's script checks, in one place (T-290).

The style guide is Visual style, Content, "Rules" (art) and Extended narrative, Content,
"Text rules" (text). The rules marked *(script)* are checked here, and every result names
the rule it checks, so the Style Evaluator can quote it:

  art   Visual style rule 1 (alpha 0 or 255 only, transparent background, at most 30 colours),
        rule 3 (the expected size: the whole image, or each frame of a one-row sheet) and
        rule 6 (Greenbull's light green and yellow only on Greenbull's own things; red is not
        reserved, T-298); Greenbull's logo check (flat brand art: rule 1, exempt from rule 2).
  text  Extended narrative text rule 2 (banned words, "Redgull" among them), rule 3 (no
        "Greenbull says ..." line) and rule 4 (format and length, by kind of text).

Command line (prints a JSON list of checks, each {"rule", "check", "ok", "detail"}; exits 1
when any check fails):

  python game/tools/style_rules.py art <png> [--size WxH] [--frames N] [--greenbull]
                                             [--allow-colour R,G,B ...] [--max-colors N] [--logo]
  python game/tools/style_rules.py text "<text>" --kind popup|card_title|card_desc|garage_name|garage_desc|label

Build scripts import from here: the PNG reader (decode_png), the sprite checks (check,
check_rows, split_sheet, check_sheet), Greenbull's colours (GREENBULL_*, greenbull_colour),
and the red-distance helpers the code-drawn colours still use (REDGULL_RED, HEART_COLOR,
red_distance, RED_MIN_DISTANCE, is_redgull_red, rgb_distance; renamed in a later ticket).
"""
import argparse
import colorsys
import json
import re
import struct
import sys
import zlib

# ---------------------------------------------------------------- Redgull red ----

# Redgull red as Visual style rule 6 gives it: the logo's red (game/art/logo/).
REDGULL_RED = (135, 17, 27)
# Redgull red as the HUD draws the likes heart (scripts/hud/hud.gd, HEART_COLOR = Color(0.86, 0.1, 0.16)).
HEART_COLOR = (219, 26, 41)
# Every colour that is not Redgull's keeps farther than this from HEART_COLOR (0..1 RGB
# distance), as the GUT tests check the code-drawn colours.
RED_MIN_DISTANCE = 0.5


def rgb_distance(a, b):
    """Euclidean distance of two colours, in 0..255 units."""
    return sum((x - y) ** 2 for x, y in zip(a[:3], b[:3])) ** 0.5


def red_distance(rgb, ref=HEART_COLOR):
    """Distance from `ref` (Redgull red as the HUD draws it), in 0..1 units."""
    return rgb_distance(rgb, ref) / 255.0


def is_redgull_red(rgb, max_dist=128, hue_deg=25):
    """True for Redgull red or anything that reads as a red: within half the colour range of
    HEART_COLOR (0.5 in 0..1 units, as the GUT tests), or a saturated red hue."""
    if rgb_distance(rgb, HEART_COLOR) < max_dist:
        return True
    h, s, v = colorsys.rgb_to_hsv(*(c / 255.0 for c in rgb[:3]))
    hue = h * 360.0
    return min(hue, 360.0 - hue) < hue_deg and s > 0.4 and v > 0.25


# ----------------------------------------------------------- Greenbull's colours ----

# Greenbull's palette as Visual style rule 6 gives it (Decisions, "Greenbull's look").
GREENBULL_DARK_GREEN = (12, 76, 44)    # the main colour, also the car's body: not checked here
GREENBULL_LIGHT_GREEN = (104, 220, 96)
GREENBULL_YELLOW = (247, 208, 52)
# The colours rule 6 keeps to Greenbull's own things.
GREENBULL_ACCENTS = (GREENBULL_LIGHT_GREEN, GREENBULL_YELLOW)
# A colour closer than this (0..255 RGB distance) to the light green or the yellow reads as it,
# measured as the red check measures closeness to the heart's red (about 0.1 in 0..1 units).
# Tight, so that the city's amber (255, 178, 60; 32 from the yellow), the car's headlights and
# the fire oranges keep clear (T-298); fire yellows closer than this need --allow-colour.
GREENBULL_MAX_DIST = 25


def greenbull_colour(rgb, max_dist=GREENBULL_MAX_DIST):
    """The Greenbull accent (light green or yellow) `rgb` reads as, or None."""
    for ref in GREENBULL_ACCENTS:
        if rgb_distance(rgb, ref) < max_dist:
            return ref
    return None


# ------------------------------------------------------------------ PNG reading ----

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


# ---------------------------------------------------------------- sprite checks ----
# The (name, ok, detail) form the build scripts use (formerly check_sprite_rules.py, T-014).

def _size_wh(size):
    return (size, size) if isinstance(size, int) else tuple(size)


def check(path, size=128, max_colors=30):
    """Returns (results, info): results is a list of (rule, ok, detail)."""
    with open(path, "rb") as f:
        w, h, rows = decode_png(f.read())
    return check_rows(rows, size, max_colors)


def check_rows(rows, size=128, max_colors=30):
    """The sprite checks on decoded rows (a list of rows of (r, g, b, a)). `size` is the
    side of a square frame, or (width, height)."""
    h, w = len(rows), len(rows[0])
    sw, sh = _size_wh(size)
    px = [p for r in rows for p in r]
    results = [("frame size %dx%d" % (sw, sh), (w, h) == (sw, sh), "%dx%d" % (w, h))]
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


def split_sheet(rows, frames):
    """Splits a one-row sheet into `frames` equal frames (lists of rows)."""
    w = len(rows[0])
    if w % frames:
        raise ValueError("sheet width %d is not a multiple of %d frames" % (w, frames))
    fw = w // frames
    return [[r[i * fw:(i + 1) * fw] for r in rows] for i in range(frames)]


def check_sheet(path, frames, size=128, max_colors=30):
    """Checks every frame of a one-row sheet. Returns a list of (results, info), one per frame."""
    with open(path, "rb") as f:
        w, h, rows = decode_png(f.read())
    return [check_rows(fr, size, max_colors) for fr in split_sheet(rows, frames)]


# ----------------------------------------------------------------- logo checks ----

def check_logo(im):
    """Greenbull's logo, emblem or wordmark (T-298; logo_checks below). `im` is a Pillow image.
    Returns a list of problems (empty = pass)."""
    return ["%s (%s)" % (c["check"], c["detail"]) for c in logo_checks(im) if not c["ok"]]


def check_redgull_logo(im):
    """The old Redgull logo's check (T-075), kept as its history since the rebrand (T-298):
    exactly one visible colour, a dark red, a transparent background and no semi-transparent
    pixels. `im` is a Pillow image. Returns a list of problems (empty = pass)."""
    im = im.convert("RGBA")
    px = list(im.getdata())
    problems = []
    if any(0 < p[3] < 255 for p in px):
        problems.append("semi-transparent pixels")
    visible = {p[:3] for p in px if p[3] == 255}
    if len(visible) != 1:
        problems.append(f"{len(visible)} visible colours (need 1)")
    else:
        r, g, b = next(iter(visible))
        if not (r > 100 and r > 2 * max(g, b) and r < 190):
            problems.append(f"colour {(r, g, b)} is not a dark red")
    if not any(p[3] == 0 for p in px):
        problems.append("no transparent pixels")
    if im.getpixel((0, 0))[3] != 0:
        problems.append("corner is not transparent")
    if not any(p[3] == 255 for p in px):
        problems.append("nothing visible")
    return problems


# ------------------------------------------------------- art checks, by rule number ----

def _result(rule, name, ok, detail):
    return {"rule": rule, "check": name, "ok": bool(ok), "detail": detail}


def art_checks(rows, size=None, frames=0, greenbull=False, allow=(), max_colors=30):
    """Visual style rules 1, 3 and 6 on decoded rows. `size` is (w, h) of the image, or of
    each frame when `frames` > 0; None skips the size check. `greenbull` marks one of
    Greenbull's own things (its light green and yellow are allowed); `allow` lists colours
    near them that rule 6 allows on this asset all the same (a fire's yellow, for example)."""
    out = []
    parts = split_sheet(rows, frames) if frames else [rows]
    for i, fr in enumerate(parts):
        prefix = "frame %d: " % i if frames else ""
        res, _ = check_rows(fr, size or (len(fr[0]), len(fr)), max_colors)
        for name, ok, detail in res:
            if name.startswith("frame size"):
                if size is not None:
                    out.append(_result(3, prefix + name.replace("frame size", "size"), ok, detail))
            else:
                out.append(_result(1, prefix + name, ok, detail))
    name = "Greenbull's light green and yellow only on Greenbull's things"
    if greenbull:
        out.append(_result(6, name, True, "one of Greenbull's own things"))
    else:
        allowed = {tuple(c) for c in allow}
        colours = {p[:3] for r in rows for p in r if p[3] == 255}
        found = sorted(c for c in colours if c not in allowed and greenbull_colour(c))
        out.append(_result(6, name, not found,
                           "Greenbull's colours: %s" % [list(c) for c in found[:5]] if found else "none"))
    return out


def logo_checks(im):
    """Greenbull's logo (emblem or wordmark) as rule results: flat brand art, so exempt from
    rule 2's shading and detail but bound by rule 1 (Visual style, Content, "Rules"); its
    colours are Greenbull's own, so rule 6 does not apply. `im` is a Pillow image."""
    im = im.convert("RGBA")
    w, h = im.size
    px = list(im.getdata())
    rows = [px[y * w:(y + 1) * w] for y in range(h)]
    res, _ = check_rows(rows, (w, h))
    return [_result(1, "Greenbull's logo: " + name, ok, detail)
            for name, ok, detail in res if not name.startswith("frame size")]


# ------------------------------------------------------------------ text checks ----

BANNED_WORDS = ("XP", "points", "Godzilla", "Redgull")
TEXT_LIMITS = {"card_title": 30, "card_desc": 90, "garage_name": 25, "garage_desc": 80}
KINDS = ("popup", "card_title", "card_desc", "garage_name", "garage_desc", "label")
# Names a label may capitalise after its first word (Extended narrative, text rule 2's names).
PROPER_NAMES = {"Greenbull", "Stunt", "Driver", "Tokyo"}


def text_checks(text, kind):
    """Extended narrative text rules 2, 3 and 4 on one piece of text of the given kind."""
    if kind not in KINDS:
        raise ValueError("unknown kind %r (one of %s)" % (kind, ", ".join(KINDS)))
    out = []
    found = [w for w in BANNED_WORDS if re.search(r"\b%s\b" % re.escape(w), text, re.IGNORECASE)]
    out.append(_result(2, "no banned words (%s)" % ", ".join(BANNED_WORDS), not found,
                       "found: %s" % ", ".join(found) if found else "none"))
    says = re.search(r"\bGreenbull\s+says\b", text, re.IGNORECASE)
    out.append(_result(3, 'no "Greenbull says ..." line', not says, "found" if says else "none"))
    one_line = "\n" not in text.strip()
    if kind == "popup":
        letters = [c for c in text if c.isalpha()]
        caps = bool(letters) and text == text.upper()
        out.append(_result(4, "popup: one line", one_line, repr(text)))
        out.append(_result(4, "popup: in capitals", caps, repr(text)))
        out.append(_result(4, 'popup: ends with "!"', text.rstrip().endswith("!"), repr(text)))
    elif kind == "label":
        words = text.split()
        first = next((c for c in text if c.isalpha()), "")
        later = [w for w in words[1:] if w[:1].isupper() and w.strip(".,:;!?") not in PROPER_NAMES]
        sentence = bool(first) and first.isupper() and not later and not (len(words) > 1 and text == text.upper())
        out.append(_result(4, "label: one line", one_line, repr(text)))
        out.append(_result(4, "label: sentence case", sentence,
                           "capitalised: %s" % later if later else repr(text)))
    else:
        limit = TEXT_LIMITS[kind]
        out.append(_result(4, "%s: at most %d characters" % (kind, limit), len(text) <= limit,
                           "%d characters" % len(text)))
        if kind == "garage_desc":
            digits = re.findall(r"\d+", text)
            out.append(_result(4, "garage_desc: names no number", not digits,
                               "numbers: %s" % digits if digits else "none"))
    return out


# --------------------------------------------------------------- command line ----

def _parse_size(s):
    m = re.fullmatch(r"(\d+)(?:x(\d+))?", s)
    if not m:
        raise argparse.ArgumentTypeError("size is W or WxH, like 128 or 48x32")
    w = int(m.group(1))
    return (w, int(m.group(2)) if m.group(2) else w)


def _parse_rgb(s):
    parts = s.split(",")
    if len(parts) != 3 or not all(p.strip().isdigit() for p in parts):
        raise argparse.ArgumentTypeError("a colour is R,G,B, like 204,18,28")
    return tuple(int(p) for p in parts)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    a_art = sub.add_parser("art", help="check a PNG against Visual style rules 1, 3 and 6")
    a_art.add_argument("png")
    a_art.add_argument("--size", type=_parse_size, help="WxH of the image, or of each frame with --frames")
    a_art.add_argument("--frames", type=int, default=0, help="a one-row sheet of this many frames")
    a_art.add_argument("--greenbull", action="store_true",
                       help="one of Greenbull's own things: rule 6 allows its light green and yellow")
    a_art.add_argument("--allow-colour", "--allow-red", dest="allow", type=_parse_rgb, action="append",
                       default=[], help="a colour near Greenbull's that rule 6 allows on this asset "
                       "(R,G,B); repeatable (--allow-red is its old name)")
    a_art.add_argument("--max-colors", type=int, default=30, help="the colour limit (default 30, rule 1)")
    a_art.add_argument("--logo", action="store_true",
                       help="Greenbull's logo check instead (emblem or wordmark: rule 1, exempt from rule 2)")
    a_text = sub.add_parser("text", help="check a text against Extended narrative text rules 2 to 4")
    a_text.add_argument("text")
    a_text.add_argument("--kind", required=True, choices=KINDS)
    a = ap.parse_args(argv)
    if a.cmd == "text":
        out = text_checks(a.text, a.kind)
    elif a.logo:
        from PIL import Image
        out = logo_checks(Image.open(a.png))
    else:
        try:
            with open(a.png, "rb") as f:
                _, _, rows = decode_png(f.read())
            out = art_checks(rows, a.size, a.frames, a.greenbull, a.allow, a.max_colors)
        except ValueError as e:
            out = [_result(1, "an 8-bit RGBA PNG that splits into the frames", False, str(e))]
    print(json.dumps(out, indent=1))
    return 0 if all(c["ok"] for c in out) else 1


if __name__ == "__main__":
    sys.exit(main())

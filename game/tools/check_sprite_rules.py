#!/usr/bin/env python3
"""Old name of the sprite check (T-014): the checks live in style_rules.py (T-290).

Usage: python game/tools/check_sprite_rules.py SPRITE.png [--size 128] [--max-colors 30] [--frames N]
runs `style_rules.py art SPRITE.png --size 128 ... --redgull` (rules 1 and 3; rule 6 is not
part of this old check). Exits 0 when all rules hold, 1 otherwise.
"""
import sys

from style_rules import check, check_rows, check_sheet, decode_png, split_sheet  # noqa: F401
import style_rules


def main(argv=None):
    args = list(sys.argv[1:] if argv is None else argv)
    if "--size" not in args:
        args += ["--size", "128"]  # the old default
    return style_rules.main(["art"] + args + ["--redgull"])


if __name__ == "__main__":
    sys.exit(main())

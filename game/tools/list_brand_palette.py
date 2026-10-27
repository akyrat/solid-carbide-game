#!/usr/bin/env python3
"""Lists the most common opaque colours of PNGs (T-308: finding Redgull's brand reds in the archived art).

  python game/tools/list_brand_palette.py FILE.png [FILE.png ...] [--top 12]
"""
import argparse
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style_rules  # noqa: E402


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+")
    ap.add_argument("--top", type=int, default=12)
    a = ap.parse_args(argv)
    for f in a.files:
        with open(f, "rb") as fh:
            _, _, rows = style_rules.decode_png(fh.read())
        c = collections.Counter(tuple(p[:3]) for r in rows for p in r if p[3] == 255)
        print(f, len(c), "colours")
        for k, v in c.most_common(a.top):
            print("   ", k, v)


if __name__ == "__main__":
    main()

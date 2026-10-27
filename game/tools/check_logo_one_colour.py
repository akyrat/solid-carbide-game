#!/usr/bin/env python3
"""HISTORY: the old logo's tool. The old logo's one-colour check (T-075), kept as its history since the rebrand
(T-298): the check is style_rules.check_old_logo. Greenbull's logo is checked by
check_greenbull_logo.py (or `style_rules.py art <png> --logo`).
Usage: check_logo_one_colour.py <png>; prints the problems, exit 0 on pass."""
import sys

from style_rules import check_old_logo as check

if __name__ == "__main__":
    from PIL import Image
    problems = check(Image.open(sys.argv[1]))
    print("; ".join(problems) or "ok")
    sys.exit(1 if problems else 0)

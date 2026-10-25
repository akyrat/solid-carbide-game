#!/usr/bin/env python3
"""Old name of the logo check (T-075): the check lives in style_rules.py (T-290).
Usage: check_logo_one_colour.py <png> runs `style_rules.py art <png> --logo`; exit 0 on pass."""
import sys

from style_rules import check_logo as check  # noqa: F401
import style_rules

if __name__ == "__main__":
    sys.exit(style_rules.main(["art", sys.argv[1], "--logo"]))

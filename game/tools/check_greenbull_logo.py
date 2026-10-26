#!/usr/bin/env python3
"""Greenbull's logo check (T-298), in place of the old one-colour Redgull check
(check_logo_one_colour.py): the emblem and the wordmark are flat brand art, exempt from
Visual style rule 2 but bound by rule 1 (Visual style, Content, "Rules"). The check is
style_rules.check_logo; this runs `style_rules.py art <png> --logo`.
Usage: check_greenbull_logo.py <png> [<png> ...]; exit 0 when every file passes."""
import sys

from style_rules import check_logo as check  # noqa: F401
import style_rules

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__.splitlines()[-1])
    sys.exit(max(style_rules.main(["art", p, "--logo"]) for p in sys.argv[1:]))

"""Record that the short GDD is up to date with the current long GDD.

Run from the repo root after regenerating the long GDD and bringing the short GDD up to date
(or confirming it needs no change):

  python tools/generate_long_gdd.py
  python tools/update_short_gdd_fingerprint.py
  python tools/generate_long_gdd.py --check

It rewrites the "Last updated from long GDD" line in docs/short-gdd/README.md with the long
GDD's current fingerprint. Only run it when the short GDD really reflects the long one.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import generate_long_gdd as g  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent


def update(readme=ROOT / "docs/short-gdd/README.md", long_gdd=ROOT / "docs/long-gdd.md"):
    """Rewrite the fingerprint line; returns (old line, new line)."""
    readme, long_gdd = Path(readme), Path(long_gdd)
    text = readme.read_text(encoding="utf-8")
    m = g.SHORT_LINE_RE.search(text)
    if not m:
        raise ValueError(f"no fingerprint line in {readme}")
    old = m.group(0)
    new = old.replace(old.split(": ")[-1], g.fingerprint(long_gdd.read_text(encoding="utf-8")))
    readme.write_text(text.replace(old, new), encoding="utf-8")
    return old, new


def main():
    old, new = update()
    print(old)
    print(new)
    return 0


if __name__ == "__main__":
    sys.exit(main())

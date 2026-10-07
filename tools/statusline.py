"""Claude Code status line: how close the game area docs are to an MVP-ready first draft.

Reads docs/mvp-readiness.json (maintained by the Project Lead) and prints one line,
for example:

  MVP docs 43% ▓▓▓▓░░░░░░  lowest: Garage design 5% · Weapons 10%

Claude Code runs it from the project's .claude/settings.json ("statusLine").
It ignores the session JSON Claude Code sends on stdin. It never fails loudly:
if the file is missing or broken, it prints a short notice instead.
"""

import json
import sys
from pathlib import Path

READINESS = Path(__file__).resolve().parent.parent / "docs" / "mvp-readiness.json"
BAR_WIDTH = 10


def bar(percent, width=BAR_WIDTH):
    filled = round(percent / 100 * width)
    return "▓" * filled + "░" * (width - filled)


def render(data, lowest=2):
    docs = data.get("docs") or {}
    if not docs:
        return "MVP docs: no readiness data"
    overall = round(sum(docs.values()) / len(docs))
    worst = sorted(docs.items(), key=lambda kv: kv[1])[:lowest]
    tail = " · ".join(f"{name} {pct}%" for name, pct in worst)
    return f"MVP docs {overall}% {bar(overall)}  lowest: {tail}"


def main():
    try:
        data = json.loads(READINESS.read_text(encoding="utf-8"))
        line = render(data)
    except (OSError, ValueError):
        line = "MVP docs: readiness file missing"
    sys.stdout.reconfigure(encoding="utf-8")
    print(line)


if __name__ == "__main__":
    main()

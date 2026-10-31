"""Append an agent's report to a ticket's `## Result notes` section (T-469).

The command guard can't tell a Bash write to a ticket from a status change, and the Edit tool is sometimes
refused on tickets, so agents write their notes with this script instead. It adds text at the end of the
`## Result notes` section and touches nothing else: not the header (status, qa_rounds, lead, ...), not any
other section.

Usage (always this repo's copy, also from a task's branch folder, so open task branches are found):

  python C:/solid-carbide-game/tools/task_notes.py T-012 --append report.md
  python C:/solid-carbide-game/tools/task_notes.py T-012 --text "What I did ..."

Exit codes: 0 appended, 1 refused (the reason is printed), 2 usage error.
"""

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import task_status as ts  # noqa: E402
import taskboard_sync as tb  # noqa: E402

NOTES_HEAD_RE = re.compile(r"^## Result notes[ \t]*$", re.M)
NEXT_HEAD_RE = re.compile(r"^## ", re.M)


def append_notes(text, addition):
    """The ticket text with `addition` added at the end of its `## Result notes` section. Raises
    ts.Refused when there is no such section or nothing to add."""
    addition = addition.replace("\r\n", "\n").strip("\n")
    if not addition.strip():
        raise ts.Refused("Nothing to append.")
    newline = "\r\n" if "\r\n" in text else "\n"
    norm = text.replace("\r\n", "\n")
    head = NOTES_HEAD_RE.search(norm)
    if not head:
        raise ts.Refused("The ticket has no \"## Result notes\" section.")
    nxt = NEXT_HEAD_RE.search(norm, head.end())
    end = nxt.start() if nxt else len(norm)
    body = norm[head.end():end].strip("\n")
    if body.strip() == tb.NOTES_PLACEHOLDER:
        body = ""
    new_body = (body + "\n\n" if body else "") + addition
    rest = norm[end:]
    out = norm[:head.end()] + "\n\n" + new_body + "\n" + ("\n" + rest if rest else "")
    return out.replace("\n", newline)


def run(task_id, addition, folders=None):
    path, _ = ts.find(task_id, folders)
    raw = path.read_bytes().decode("utf-8")
    new = append_notes(raw, addition)
    path.write_bytes(new.encode("utf-8"))
    return path


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("task")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--append", metavar="FILE", help="a file whose text is appended")
    src.add_argument("--text", help="the text to append")
    args = ap.parse_args(argv)
    if not re.fullmatch(r"T-\d+", args.task):
        print("The task id looks like T-123.", file=sys.stderr)
        return 2
    try:
        if args.append:
            f = Path(args.append)
            if not f.is_file():
                raise ts.Refused(f"No file {args.append}.")
            addition = f.read_text(encoding="utf-8")
        else:
            addition = args.text
        path = run(args.task, addition)
    except ts.Refused as e:
        print(f"Refused: {e}", file=sys.stderr)
        return 1
    print(f"Appended to the result notes of {args.task}: {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

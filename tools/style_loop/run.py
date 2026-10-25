"""The style loop's command line (role: entry point; tasks/README.md, "The style loop", T-291).

  python tools/style_loop/run.py art --task T-NNN --brief <file> --out <png>
         [--size WxH] [--frames N] [--redgull] [--allow-red R,G,B ...] [--max-colors N] [--fake FIXTURE]
      The Asset Generation Agent makes the PNG; every version is saved in art-archive/<task>/style-loop/,
      and the kept one is copied to --out. The script check options are style_rules.py's `art` options.
  python tools/style_loop/run.py text --task T-NNN --brief <file> --kind KIND [--out <file>] [--fake FIXTURE]
      The Narrative Theme Agent writes the text; KIND is style_rules.py's text kind (popup, label, ...).
      The kept text is printed, written in the Style review, and written to --out if given.

Each round goes into the task's `## Style review` section (the task file where it lives: its task folder while
its branch is open). A run that stays below 8 after 3 refines flags the task (task_status.py).

--fake FIXTURE answers from a JSON fixture with FakeClaude instead of calling Claude ({"generate": [...],
"refine": [...], "evaluate": [...]}, fixtures/). It never touches the real task: it works on a copy of the task
file in a new temporary folder (with its own task status record), where the archive and --out go too; the
folder's path is printed first and kept, so the result can be opened.
Exit codes: 0 kept at 8 or more, 1 kept below 8 (flagged), stopped or refused, 2 usage error.
"""

import argparse
import contextlib
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))   # tools/, for style_loop and goal_agent

import taskboard_sync as tb  # noqa: E402
import task_status as ts  # noqa: E402
from goal_agent.claude_call import FakeClaude, Pause, RealClaude  # noqa: E402
from style_loop import loop  # noqa: E402

style_rules = loop.style_rules


@contextlib.contextmanager
def sandbox(task_path):
    """A temporary folder with a copy of the task file, standing in for the repo: the status script and its
    guard record work there (as in test_task_status.py), so a fake run never changes a real task."""
    base = Path(tempfile.mkdtemp(prefix="style-loop-fake-"))
    (base / "tasks").mkdir()
    shutil.copyfile(task_path, base / "tasks" / task_path.name)
    saved = (tb.TASKS_DIR, tb.STATE_DIR, ts.LOG, tb.task_folders)
    tb.TASKS_DIR, tb.STATE_DIR = base / "tasks", base / ".board"
    ts.LOG = tb.STATE_DIR / "moves.log"
    tb.task_folders = lambda root=None: {}
    try:
        yield base
    finally:
        tb.TASKS_DIR, tb.STATE_DIR, ts.LOG, tb.task_folders = saved


def parser():
    ap = argparse.ArgumentParser(description="The style loop: generate, evaluate, refine below 8.")
    sub = ap.add_subparsers(dest="kind", required=True)
    for kind in ("art", "text"):
        p = sub.add_parser(kind, help=f"run the loop on {'a PNG' if kind == 'art' else 'a piece of text'}")
        p.add_argument("--task", required=True, help="the task, T-NNN")
        p.add_argument("--brief", required=True, help="a file with the brief for the generating agent")
        p.add_argument("--out", required=kind == "art", help="where the kept version goes")
        p.add_argument("--fake", metavar="FIXTURE", help="answer from a FakeClaude fixture, on a copy of the task")
    art, text = sub.choices["art"], sub.choices["text"]
    art.add_argument("--size", type=style_rules._parse_size, help="WxH of the image, or of each frame")
    art.add_argument("--frames", type=int, default=0, help="a one-row sheet of this many frames")
    art.add_argument("--redgull", action="store_true", help="one of Redgull's own things (rule 6 does not apply)")
    art.add_argument("--allow-red", type=style_rules._parse_rgb, action="append", default=[],
                     help="a red rule 6 allows on this asset (R,G,B); repeatable")
    art.add_argument("--max-colors", type=int, default=30)
    text.add_argument("--kind", dest="text_kind", required=True, choices=style_rules.KINDS)
    return ap


def main(argv=None, claude=None):
    tb.utf8_output()
    args = parser().parse_args(argv)
    try:
        task_path, _ = ts.find(args.task)
        brief_path = Path(args.brief)
        brief = brief_path.read_text(encoding="utf-8")
    except (ts.Refused, OSError) as e:
        print(f"Refused. {e}", file=sys.stderr)
        return 2
    with (sandbox(task_path) if args.fake else contextlib.nullcontext()) as base:
        if base:
            print(f"Fake run on a copy of {args.task}: {base}")
            task_path = base / "tasks" / task_path.name
        out = Path(args.out) if args.out else None
        if base and out:
            out = base / "out" / out.name
        spec = loop.Spec(kind=args.kind, task=args.task, task_file=task_path, root=task_path.parent.parent,
                         brief=brief, brief_name=brief_path.as_posix(), out=out,
                         text_kind=getattr(args, "text_kind", None), size=getattr(args, "size", None),
                         frames=getattr(args, "frames", 0), redgull=getattr(args, "redgull", False),
                         allow_red=getattr(args, "allow_red", []), max_colors=getattr(args, "max_colors", 30))
        claude = claude or (FakeClaude(args.fake) if args.fake else RealClaude())
        try:
            kept, rounds = loop.run(claude, spec)
        except Pause as e:
            print(f"Stopped. {e}", file=sys.stderr)
            return 1
        except ts.Refused as e:
            print(f"The record is written, but flagging the task was refused. {e}", file=sys.stderr)
            return 1
        for r in rounds:
            print(f"Round {r.n}: score {r.score}/10 ({loop.checks_summary(r.checks)})")
        print(f"Kept version {kept.n}, score {kept.score}/10: {loop.show_version(spec, kept.version)}")
        if kept.score < loop.PASS:
            print(f"Below {loop.PASS} after {loop.MAX_REFINES} refines: {args.task} is flagged for the board's review.")
        print(f"Style review written in {task_path}")
        return 0 if kept.score >= loop.PASS else 1


if __name__ == "__main__":
    sys.exit(main())

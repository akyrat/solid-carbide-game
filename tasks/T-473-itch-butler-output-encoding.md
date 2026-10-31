---
id: T-473
title: publish_itch.py reads butler's output safely on Windows
status: done
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, tools/publish_itch.py, tools/test_publish_itch.py, docs/working-with-the-board.md]
files_expected_to_change: [tools/publish_itch.py, tools/test_publish_itch.py, docs/working-with-the-board.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The first real push to itch.io (2026-10-31, version ebf53d8b) uploaded the build, but `python tools/publish_itch.py` then crashed: reading butler's output with the Windows console's default code page raised `UnicodeDecodeError: 'charmap' codec can't decode byte 0x90` (butler prints progress bars with non-ASCII characters), so stdout came back None and line 192 failed with `TypeError: unsupported operand type(s) for +: 'NoneType' and 'str'`. The Project Lead had to check with `butler status` by hand.

1. Run butler with its output decoded as UTF-8 with errors replaced (subprocess `encoding="utf-8", errors="replace"`), never None, and keep the key redacted.
2. After a push, run `butler status <ITCH_TARGET>` and print the channel's current version, so the script confirms the upload itself.
3. Return a non-zero exit code if butler fails, with its (redacted) output.
4. Also: butler was installed inside T-448's task folder (tools/bin/, git-ignored) and was lost when that worktree was removed; the Project Lead reinstalled it in the main checkout's tools/bin/. Say in docs/working-with-the-board.md ("Publishing to itch.io") that butler lives in the main checkout's tools/bin/ and how to reinstall it (the official download, https://broth.itch.zone/butler/windows-amd64/LATEST/archive/default).

Never run a real push in this ticket (stub butler in tests). Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] A test with a stubbed butler that prints non-ASCII bytes shows the script doesn't crash and prints its (redacted) output. (QA: pass - test_non_ascii_output_does_not_crash)
- [x] A test shows the script runs butler status after a push and prints the channel's version. (QA: pass - test_status_runs_after_push_and_prints_version)
- [x] A test shows a failing butler gives a non-zero exit code, and the key never appears in the output. (QA: pass - test_failing_butler_exits_nonzero_without_key)
- [x] docs/working-with-the-board.md, "Publishing to itch.io", says where butler lives and how to reinstall it. (QA: pass)
- [x] The tools Python tests pass (`python -m unittest discover -s tools -p "test_*.py"`), with the count in the result notes. (QA: pass - qa_check: 3 test sets pass; count 633 in notes)
- [x] Nothing under game/data/levels/ is changed or committed. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. tools/publish_itch.py: new run_butler() runs butler with encoding utf-8, errors replace (output never None, key redacted); after a successful push it runs butler status on ITCH_TARGET, prints it and a "Channel html5: now shows version X" line (or a warning if the version is not in the output); a failing push or status gives exit 1 with the redacted output. tools/test_publish_itch.py: stub butler prints non-ASCII bytes; new tests for no crash, status after push with version, failing butler gives non-zero and no key, run_butler never None. docs/working-with-the-board.md "Publishing to itch.io": butler lives in the main checkout's tools/bin/, reinstall from the official download URL. Tools Python tests: 633 run, OK. No real butler call; nothing under game/data/levels/ touched.
- 2026-10-31, in-progress → in-qa: ready for QA
- 2026-10-31, in-qa → done: QA passed

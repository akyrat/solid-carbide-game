---
id: T-558
title: publish_itch.py crashes printing butler's output on the Windows console
status: open
from: project-lead
to: qa-integration
lead: Rails
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, tools/publish_itch.py, tools/test_publish_itch.py, docs/working-with-the-board.md]
files_expected_to_change: [tools/publish_itch.py, tools/test_publish_itch.py]
model: sonnet
qa_rounds: 0
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

On 2026-11-07 `python tools/publish_itch.py` pushed version 89d2dd17 fine, then crashed at `out(text)` after `run_butler` (line 199): `UnicodeEncodeError: 'charmap' codec can't encode character '\u2219'`. butler's progress output has non-ASCII characters (\u2219, the check mark in `butler status`) and the console's cp1252 can't print them, so the script stopped before "Pushed version ...", the page link and the status check, and exited non-zero after a successful push. Make every print of butler's output (push and status) safe on a cp1252 console (for example replace what can't be encoded), keeping the key redaction, and read butler's output as UTF-8. Test with a fake butler whose output has \u2219 and \u221a under a cp1252 stdout.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never print or commit secrets from .env. Never run a real push: test with fakes and `--dry-run` only. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test runs the script's push path with a fake butler printing \u2219 and \u221a under a cp1252 stdout: it prints "Pushed version", the page link and the status, and exits 0. (QA: pass / fail)
- [ ] The redaction of the API key in butler's output still works (the existing test still passes). (QA: pass / fail)
- [ ] `python tools/publish_itch.py --dry-run` still works (the agent runs it). (QA: pass / fail)
- [ ] The tools test set passes (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

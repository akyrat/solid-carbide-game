---
id: T-216
title: The guard lets more read-only commands through
status: open
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/T-212-board-drag-out-of-qa-and-guard-false-alarms.md, tasks/T-213-guard-script-arguments-writing-task-headers.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

After T-212 and T-213 the guard (`.claude/hooks/board_gate.py`, `pre_shell`) still refuses some commands that can't write a task file's `status`, `qa_rounds` or `lead` line (board's go, 2026-10-21). Each refusal stops an agent. Cases seen this week:

- `sed -n '1,40p' <file>`: a sed that only prints (`-n` with `p`, no `-i`, no `w`), taken for a writing sed (T-207, T-070).
- `rm -f <dir>/*.png` of an agent's own capture folder under `art-archive/`, refused as "could be a ticket" (T-102).
- `source game/tools/godot_env.sh`, a script that only sets environment variables (T-102).
- `pip list`, and `git check-ignore -v .env` in a chain (T-070, T-207).
- an inline Python step that only reads images, when the same command also names task files (T-102, before T-212).
- `git ls-files -m | xargs git checkout --` to revert Godot's `.import` line-ending noise (T-071).

Let each of these through when it can't touch a task file's header lines, judged as T-212 and T-213 do (what the command or script actually writes, and where). Keep refusing everything the existing guard tests refuse, including a `rm` or `sed -i` on a task file, a `git checkout` of a task file, and scripts whose code or arguments write those lines. A refusal still names what made it refuse.

This changes a hook. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] Tests feed `pre_shell` each command listed above (with real file paths of the same shape) and the guard lets each through (QA: pass / fail)
- [ ] Tests show the guard still refuses `rm` and `sed -i` on a task file, `git checkout -- tasks/T-1-x.md`, and every case the existing guard tests refuse (QA: pass / fail)
- [ ] `tasks/README.md` describes the rule in a sentence or two (QA: pass / fail)
- [ ] All Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

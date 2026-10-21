---
id: T-248
title: The guard lets more harmless commands through (find, shell variables, Godot recording and import)
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
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/T-216-guard-read-only-false-alarms.md]
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

After T-216 the guard (`.claude/hooks/board_gate.py`, `pre_shell`) still refuses commands that can't write a task file's `status`, `qa_rounds` or `lead` line (board's go, 2026-10-22). Agents keep getting stopped by them, and some have reached the same result another way, which the rules forbid. Cases seen this week:

- a read-only `find` (T-243);
- a shell variable assignment such as `tmp=...` before a command (T-243);
- Godot run with `--write-movie <file>` to record a GIF's frames into an agent's own `art-archive/<task>/` folder (T-227);
- Godot run with `--import` (or `--headless --import`) to import the project's assets (T-227).

Rebuild each case with real paths of the same shape (the agents' folders, Godot's path from `game/tools/godot_env.sh`), and let each through when it can't touch a task file's header lines, judged as T-212, T-213 and T-216 do (what the command actually writes, and where). A `find` with `-delete`, `-exec` or `-fprint` on a tasks folder, and a `--write-movie` into a tasks folder, are still refused. Keep refusing everything the existing guard tests refuse. A refusal still names what made it refuse.

This changes a hook. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] Tests feed `pre_shell` each command listed above (with real paths of the same shape) and the guard lets each through (QA: pass / fail)
- [ ] Tests show the guard still refuses `find -delete` or `-exec rm` on a tasks folder, a `--write-movie` into a tasks folder, and every case the existing guard tests refuse (QA: pass / fail)
- [ ] `tasks/README.md` describes the change in a sentence or two, next to T-216's rule (QA: pass / fail)
- [ ] All Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

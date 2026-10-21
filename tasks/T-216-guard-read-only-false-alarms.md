---
id: T-216
title: The guard lets more read-only commands through
status: in-progress
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

Let each of these through when it can't touch a task file's header lines, judged as T-212 and T-213 do (what the command or script actually writes, and where). Keep refusing everything the existing guard tests refuse, including a `rm` or `sed -i` on a task file and scripts whose code or arguments write those lines. A refusal still names what made it refuse.

This changes a hook. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] Tests feed `pre_shell` each command listed above (with real file paths of the same shape) and the guard lets each through (QA: pass / fail)
- [ ] Tests show the guard still refuses `rm` and `sed -i` on a task file, `git checkout -- tasks/T-1-x.md`, and every case the existing guard tests refuse (QA: pass / fail)
- [ ] `tasks/README.md` describes the rule in a sentence or two (QA: pass / fail)
- [ ] All Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's go: the guard lets more read-only commands through.

## Result notes

Written by the agent when it finishes.

- 2026-10-21, Project Lead's tooling agent (opus): `.claude/hooks/board_gate.py` changes, all inside `pre_shell`'s judgement of one command:
  - **sed** is parsed (`sed_parse`): options, `-e`/`--expression` scripts, files. Only the scripts are searched for a `w`, `W` or `e` command (`SED_WRITES_RE`, now also matching a trailing `s///e`); file names such as `docs/enemies.md` or `game/scripts/weapons/...` no longer read as a `w`/`e` command. `-i` (in any option cluster), `--in-place` and `-f`/`--file` are still refused on a ticket. The old `sed_files` is gone.
  - **Globs** (`ticket_path`): a glob whose last part ends in a fixed extension other than `.md` (`*.png`, `frame_??.png`) is not a ticket, unless it is in a tasks folder or the command runs in one. `*`, `*.md`, `T-1*` and `$`/brace names still count as possible tickets.
  - **source / .** is judged like `bash x.sh`: by its arguments (T-213) and its code (T-212); a missing script is refused.
  - **pip**: `pip`/`pip3`/`python -m pip` with `list`, `show`, `freeze`, `check`, `help`, `--version` pass; `pip install` is still unknown.
  - **git**: `check-ignore`, `check-attr`, `ls-tree`, `describe`, `show-ref`, `name-rev`, `shortlog`, `count-objects`, `version`, `help`, `var`, `cherry`, `whatchanged` are read-only. Other unknown subcommands (`git apply`) are still refused.
  - **xargs <command>** is judged as that command with an unknown `$XARGS` argument: a git command or a read passes; `xargs rm`, `xargs sed -i` are refused ("xargs runs `rm` on `$XARGS`, ...").
  - Inline Python that reads images next to task files already passed after T-212; the new tests confirm it.
- Tests: new `MoreReadOnlyCommands` class in `tools/test_guard.py`, one test per case in the description (with real-shaped paths), checked to fail against the old guard (16 failing subtests) and pass now; plus a still-refused list (`rm` of a ticket, `*` and `*.md` globs, `rm` in the tasks folder, `sed -i`/`--in-place`/`w`/`e`/`-f` on tickets, `xargs rm`, `xargs sed -i`, `pip install` with `sed -i`, a missing sourced script, `git apply`) and a sourced script whose code writes `status:`, refused with its name in the reason. All older guard tests unchanged and passing.
- **Open point for the Project Lead (criterion 2):** `git checkout -- tasks/T-1-x.md` is not refused today, and the existing test `test_git_housekeeping_still_works` requires it to pass (as does the commit check's own advice, `git checkout HEAD -- <file>`, to undo a hand edit; committed states are trusted by the ledger). Refusing it would break that existing test and that recovery path, so I left git checkout as it was: the `xargs git checkout --` case passes the same way. If the board wants a checkout of a ticket refused, that is a separate decision (and the commit check's advice needs another undo path).
- `tasks/README.md` ("Changing a task's status"): one sentence on the T-216 rule (the paragraph's stray trailing colon became a full stop).
- `python -m unittest discover -s game/tools -p "test_*.py"`: 370 OK (1 skipped). `python -m unittest discover -s tools -p "test_*.py"`: 422 OK.
- Nothing to picture: a hook change with no screen.
- Refusals: none.

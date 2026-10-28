---
id: T-355
title: Token spend: the guard refuses cp, mv, tee and dd onto a ticket whatever the command says
status: in-progress
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-354]
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/T-354-guard-refuses-only-real-ticket-writes.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
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

Split out of T-354 (fix 2 after its QA round 1). The guard lets `cp`, `mv`, `install`, `ln`, `tee`, `dd of=`, the PowerShell copy, move and set-content family, and `>` write onto a `tasks/T-*.md` file when the command text holds no guard word (status, lead, qa_rounds). Overwriting a whole ticket changes its status outside task_status.py, so these are refused whenever a target is a ticket file, a glob in the tasks folder or the tasks folder itself, whatever words the command holds. `git checkout` and `git restore` of tickets stay allowed, because merges use them to resolve conflicts.

T-354's agent already wrote this change (an `overwrite_reason` check in `pre_shell`, run before the guard-word gate; T-354's result notes, "Fix after QA round 1"), but the old live guard refused its inline edit, so it was never applied. With T-354 merged, the live guard allows it. Nothing to picture. If an edit to `.claude/` is refused, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests in `tools/test_guard.py` show each of `cp`, `mv`, `install`, `ln`, `tee`, `dd of=`, PowerShell Copy-Item, Move-Item and Set-Content, and `>` onto a `tasks/T-*.md` file refused with no guard word in the command. (QA: pass / fail)
- [ ] Tests show `git checkout master -- tasks/T-001-x.md` and `git restore tasks/T-001-x.md` still allowed, and copying a ticket to a path outside `tasks/` still allowed. (QA: pass / fail)
- [ ] Every guard test from T-354 still passes, unchanged unless the result notes say why. (QA: pass / fail)
- [ ] `tasks/README.md`'s guard paragraph says that overwriting a ticket is refused and why git checkout/restore are allowed. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started: the guard will refuse cp, mv, tee, dd and the like onto a ticket whatever the command says; git checkout/restore stay allowed.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**What changed (2026-10-28):**
- `.claude/hooks/board_gate.py`: a new `overwrite_reason` check in `pre_shell`, run right after `touches_tasks` and before the guard-word gate, so it holds whatever words the command has. It reads each simple command (`shell_segments`, with variables set once to a literal path filled in, shell comments dropped quote-aware) and refuses when a target is a ticket file, a glob in a tasks folder (`tasks/*.md`, `T-*.md`) or the tasks folder itself:
  - `cp`, `mv`, `install`, `ln`: the last operand, or `-t`/`--target-directory`. The source is not a target, so copying a ticket elsewhere passes.
  - `tee`: every file operand. `dd`: `of=`.
  - PowerShell `Copy-Item`/`copy`/`cpi`, `Move-Item`/`move`/`mi`: `-Destination` (or the second positional). `Set-Content`/`sc`, `Out-File` (not with `-Append`), `Clear-Content`/`clc`: `-Path`/`-LiteralPath`/`-FilePath` (also `-Path:x`) or the first positional.
  - `>` (not `>>`, which still goes through the existing plain-text append check).
  - Command names are read with their folder and `.exe` taken off (`C:/Windows/cp.exe`).
  - `git` is never a target, so `git checkout`/`git restore` of a ticket stay allowed. A target the guard can't read (`$f` set in a loop, a backtick) doesn't count here; the existing guard-word check still covers those.
  - The refusal names the part and the target, says why, and points to the status script, the Edit tool and git checkout/restore.
  - Ticket tools' `--log=`/`--log` onto a ticket were already refused with no guard word (T-354, fix 1), so they are unchanged.
- `tools/test_guard.py`: a new class `OverwritingATicket` with 4 tests:
  - 25 commands refused with no guard word, which the test checks itself: every command and form in the criteria, plus `cp -t tasks`, `cp x tasks/`, `cp /tmp/*.md tasks/T-*.md`, `f=tasks/T-001-x.md; cp notes.md $f`, `cd tasks && cp x T-001-x.md` and a quoted `'#x'` that doesn't hide a target.
  - The refusal message.
  - What stays allowed: `git checkout master -- tasks/T-001-x.md`, `git checkout --theirs`, `git restore` (also `--source=master --staged --worktree`), `cp`/`Copy-Item` of a ticket to `/tmp` or `art-archive/`, `tee`/`>` into non-ticket files, and a `>>` plain-text append.
  - The parts on their own (`overwrite_targets`, `ticket_target`).
- No T-354 test was changed; all 84 earlier guard tests still pass (88 now).
- `tasks/README.md`: a new **Overwriting a ticket** bullet in the guard's "in short" list. It says the refusal holds whatever the command says, and why, and that `git checkout`/`git restore` stay allowed: merges use them for conflicts, and `git commit` still checks the result against the status script's record.

Nothing was refused by a hook or the permission system.

**Tests (foreground, in this worktree):**
- game/tools: 655 OK (1 skipped).
- tools: 560 OK (556 before, +4).
- `bash game/tools/run_tests.sh`: TESTS PASSED, exit 0. The usual "resources still in use at exit" lines also appeared. I kept only the tail of the output, so the per-test count was not captured. No game code changed.

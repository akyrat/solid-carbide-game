---
id: T-348
title: Token spend: the guard stops refusing read-only commands (sort, uniq, python -c, chained status calls)
status: done
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/T-248-guard-more-harmless-commands.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
model: opus
qa_rounds: 1
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

The guard (`.claude/hooks/board_gate.py`, `pre_shell`) still refuses commands that can't write a task file's `status`, `qa_rounds` or `lead` line. Each refusal costs a retry at the session's full context size, and refusals caused 8 goal-run pauses. Cases seen on 2026-10-28 (the Tokens session and its observers):

- `ls tasks | sort | tail -5` (refused because of `sort`);
- `grep -h "^qa_rounds:" tasks/T-*.md | uniq -c` (refused because of `uniq`);
- a read-only `python -c` or `python -I -` heredoc that only reads files under `tasks/` or the transcripts;
- `python tools/board_inbox.py name <session> <Name> && python tools/task_status.py T-NNN --lead <Name>` (refused because `board_inbox.py` holds the word `lead`, though `name` writes no ticket).

Let each through, judged as T-212, T-216 and T-248 do (what the command actually writes, and where). `sort -o` or `uniq` with an output file inside `tasks/`, and a Python script that writes under `tasks/`, are still refused. Keep refusing everything the existing guard tests refuse. A refusal still names what made it refuse.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] Each of the four commands in the description, rebuilt with real paths, is allowed (a guard test each). (QA: pass; ReadOnlyCommandsAgain.test_allowed_1..4, 71 guard tests OK)
- [x] `sort -o tasks/x`, `uniq a tasks/x`, and a Python command that writes under `tasks/` are still refused (a guard test each). (QA: pass; test_still_refused_again, 32 commands)
- [x] Every existing guard test still passes unchanged. (QA: pass; 0 removed lines in tools/test_guard.py)
- [x] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; tools 508 OK, game/tools 620 OK 1 skipped, run_tests.sh TESTS PASSED)

QA note 2026-10-28: the agent's refused `sed -i` was meant to append the GDScript test count to this ticket's own result notes (tasks/T-348-guard-read-only-commands-again.md); it made the same one-line notes edit with the Edit tool. Notes only, no code.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started in parallel: the guard stops refusing read-only commands.

### 2026-10-28, In QA

Built: the four read-only cases now pass, the write cases are still refused, 71 guard tests. QA is checking it now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

- 2026-10-27, Project Lead's tooling agent (opus): `.claude/hooks/board_gate.py`, all inside `pre_shell`'s judgement of one command (`why_risky`):
  - **sort, uniq** (`sort_uniq_reason`): they only read and print. A sort's output file (`-o`, `-oFILE`, `-ro FILE`, `--output[=]`, any unambiguous prefix such as `--out`) and uniq's second file operand are refused when they could be a ticket (in a tasks folder, a T-nnn .md name, a computed name, or any file when run inside tasks); an output elsewhere (`art-archive/T-348/...`) passes. `sort --compress-program` is refused (it runs a program).
  - **Read-only inline Python** (`python_code`, `python_reads_only`): `python [-I...] -c '<code>'` and `python [-I...] - <<'EOF'` pass, whatever files they name, when the code (parsed with `ast`) can only read and print: imports only from a list of plain modules (`sys`, `os`, `re`, `json`, `glob`, `pathlib`, `collections`, ...; not `io`, `shutil`, `subprocess`, `importlib`); `open()`/`Path.open()` only with a literal read mode and known keywords; no `exec`, `eval`, `compile`, `__import__`, `getattr`, `type`, ...; no `_`-attributes; no attribute that writes, deletes, moves or runs (`write_text`, `write`, `rename`, `unlink`, `remove`, `mkdir`, `system`, `popen`, `exec*`, `spawn*`, `modules`, `dump`, `copy`, `run`, ...), except `sys.stdout/stderr.write`; `.replace(a, b)` only on a value (str.replace), not `os.replace`, `Path.replace(...)` or a one-argument `.replace`; `open` never passed around as a value. The code must also be exactly what the shell hands Python: one quoted word for `-c`, with no `$`-expansion, backtick or backslash inside double quotes, and a quoted here-document delimiter (or a body with none of those). Anything else falls back to the old rule (inline code naming task files is refused).
  - **Known scripts** (`NO_TICKET_SUBCOMMANDS`, `known_script_ok`): `python tools/board_inbox.py name|watch ...` passes (its code reads a ticket's `lead` to route moves, which the T-212 source check counted as a writer; `name` and `watch` write only `.board/` files). Other subcommands are judged as before.
- Now allowed (tests `ReadOnlyCommandsAgain.test_allowed_1..4` in `tools/test_guard.py`): `ls tasks | sort | tail -5` (with and without a following `grep '^status:'`), `sort -V -r`, `sort -t- -k2,2n`, `sort -o art-archive/...`; `grep -h "^qa_rounds:" tasks/T-*.md | uniq -c` and variants (`sort | uniq -c | sort -rn`, `uniq -c -f 1`, `uniq - art-archive/...`); six read-only Python commands (`-c` in double and single quotes, `python -I -` and `python -` heredocs reading tickets and a session transcript, one run inside the worktree's tasks folder); `python tools/board_inbox.py name <session> Tokens [--take-over] && python tools/task_status.py T-348 --lead Tokens`, and `board_inbox.py watch` by absolute path. Checked against the old guard: 20 allowed subtests and the 3 new refusal-reason subtests failed there (the bare `ls tasks | sort | tail -5` already passed, as it names no guarded word).
- Still refused (`test_still_refused_again`, 32 commands): `sort -o tasks/x`, `-otasks/...`, `-ro`, `--output=`, `--out`, `--compress-program`, `uniq a tasks/x`, `uniq -c -f 1 a tasks/...`, `uniq -- a tasks/...`, `cd tasks && sort -o ...`; Python writing under tasks via `write_text`, `open(..., 'a'/'w'/'r+'/mode='w'/a variable mode)`, `os.replace`, `Path.replace`, `Path.open('w')`, `os.open`, `exec`, `__import__`, `subprocess`, `shutil`, an `open` alias, `json.dump`, a `$F` in double quotes, a heredoc loop of `write_text`, an unquoted heredoc with `$T`, `-c` inside tasks, a `>` redirect into a ticket; `board_inbox.py` with a `>` into tasks or another subcommand naming a ticket. `test_a_refusal_names_what_made_it_refuse_again` checks the reason names `sort`, `uniq`, `--compress-program` or the inline code. `test_the_python_check_on_its_own` unit-tests the Python check (aliases such as `import os as o; o.replace`, `pathlib.Path.replace`, `type(p).replace`, `from os import replace` refused).
- All existing guard tests pass unchanged (only a new class was added).
- Known limits (as in T-248, the commit check is the backstop): the Python check is a static reading, so a determined write through a path it doesn't list (for example a class aliased into a variable, then `.replace(a, b)`) can still slip by; a module not on the list makes the code count as a writer.
- `tasks/README.md` ("Changing a task's status"): one sentence after T-248's rule.
- Tests: `python -m unittest discover -s tools -p "test_*.py"`: 508 OK (`tools.test_guard`: 71 OK). `python -m unittest discover -s game/tools -p "test_*.py"`: 620 OK (1 skipped). `bash game/tools/run_tests.sh`: 1735 of 1735 tests passed, TESTS PASSED (exit 0).
- Refusals while working (from the main checkout's guard, the old one): (1) a Bash command that wrote a probe script with a heredoc and ran it in the same command ("can't find or read that script"). I didn't retry it; the cases went into the unit tests instead. (2) A `sed -i` adding the GDScript test count to these notes (its script held backticks, so the guard couldn't read it). I made the same one-line note edit with the Edit tool, the normal tool for a ticket's notes, whose check passed it; strictly that is another tool for the same edit, so I'm listing it.
- Nothing to picture: a hook change with no screen.
- 2026-10-28, in-qa → done: QA pass, all 4 criteria

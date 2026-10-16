---
id: T-149
title: The status guard stops agents changing qa_rounds themselves
status: in-progress
from: project-lead
to: project-lead
lead: Level-up
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/task_status.py, tasks/T-143-hook-allow-reading-task-headers.md]
files_expected_to_change: [.claude/hooks/board_gate.py, its tests, tasks/README.md if the rules' wording changes]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board asked for this (2026-10-16). A task file's `qa_rounds:` line changes only through `tools/task_status.py`, which adds one when a task leaves `in-qa`. The hooks in `.claude/hooks/board_gate.py` are meant to refuse every other change to it (`pre_edit` for the file editing tools, `pre_shell` for shell commands).

On T-139 that failed. In its folder (branch `task/T-139-likes-bar-level-up-animation`, since merged into master), the QA/Integration Agent changed `qa_rounds: 0` to `qa_rounds: 1` itself, and committed it in "T-139: QA round 1, all criteria pass" (commit `ffdff26`). Then it ran the status script, which added one more, so T-139 shows 2 rounds after one QA check. The guard didn't refuse the first change. It isn't known which tool the agent used.

Do:
1. Find how a change to `qa_rounds` (and so also to `status`, which the same checks guard) can get past the hooks. Look at least at: a task file inside a task's own folder (`C:\solid-carbide-worktrees\<id>\tasks\...`, outside the main checkout), paths written with a glob, forward or back slashes or a relative path, the file editing tools, shell edits (`sed -i`, Python, PowerShell `Set-Content`), and a commit of a file changed earlier. Write in the result notes which way(s) get through, with a command or tool call that shows each one.
2. Close each gap you find, so the status script stays the only way to change those lines, while reading task files (T-143) and the status script itself still work.
3. Tests: one per gap, showing it is refused now, plus tests showing reading and the status script still work.

Don't fix T-139's count; it is done and merged. Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The result notes name each way found to change `qa_rounds` past the hooks, each with a reproducing command or tool call (QA: pass / fail)
- [ ] A test for each of those ways shows the hook now refuses it, for `qa_rounds` and `status` (QA: pass / fail)
- [ ] Tests show reading task files (T-143's read-only commands) and `tools/task_status.py` moves still work (QA: pass / fail)
- [ ] `tasks/README.md` still describes the rule correctly (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-16, Open → In progress

Started: agent launched in C:\solid-carbide-worktrees\T-149.

## Result notes

Gaps found (only by calling `pre_edit` / `pre_shell` in `board_gate.py` on throwaway copies; no real task file was touched). The tool T-139's QA agent used is not known; any of these gets past the old hooks:

Edit / Write tools (`pre_edit`):
1. A repeated guarded line. `Edit` with old `qa_rounds: 0`, new `qa_rounds: 1\nqa_rounds: 0` (the hook read only the last line, the status script and `set_field` the first, so `qa_rounds` looks unchanged but the file now says 1 to the script). Same for `status`.
2. A relative path: `file_path: "tasks/T-139-x.md"`. The path regex needed a separator before `tasks`.
3. Other spelling on Windows: `Tasks\t-139-x.md`, a trailing dot (`...x.md.`), `tasks\..\tasks\T-139-x.md` (no match on the raw text).
4. A task file under another name (copy of the header): not recognised.
5. A file that is not valid UTF-8: `read_bytes().decode("utf-8")` raised, and `main()` turns any exception into "allow" (fail-open).

Shell (`pre_shell`):
6. Globs: `sed -i 's/qa_rounds: 0/qa_rounds: 1/' tasks/*.md` (the rule needed the text `tasks/T-<digits>`).
7. `cd tasks && sed -i 's/qa_rounds: 0/qa_rounds: 1/' T-139-x.md`, and the same command in a later call when the shell is still inside `tasks/` (no `tasks/T-` text at all).
8. `sed -i '...qa_rounds: 0...' tasks/T-139-x.md # task_status.py`: any command containing the text `task_status.py` was allowed (comment, echo, `test_task_status.py`).
9. The word without a colon right after it: `sed -i 's/\(qa_rounds\): 0/\1: 1/' tasks/T-139-x.md`, or a split `'qa_'+'rounds'` in `python -c`.
10. A lead read in the same command excused nothing but a status read did not either; the `lead` rule ignored `read_only`, so `grep lead: tasks/T-1-x.md` was wrongly refused (a false refusal, fixed).
11. Not detectable by any command filter: `python fix.py tasks/T-139-x.md` (a script written earlier), `mv /tmp/x.md tasks/T-139-x.md`, and then `git commit -am ...` of the changed file. This is the likeliest way of the T-139 commit `ffdff26`. Closed by the second guard below.

Changes:
- `tools/guard_ledger.py` (new): `state()` = every status/qa_rounds/lead line of the header; a ledger `.board/blessed-states.jsonl` in the main checkout (found through `git rev-parse --git-common-dir`, so every task folder shares it) of states `task_status.py` wrote.
- `tools/task_status.py`: `move`, `claim` and the blocked->open unblock check the file's state is in the ledger or equal to HEAD's (else `Refused`: "changed by hand"), and record the state they write. So hand edit + script (the T-139 double count) is refused. The first run creates the ledger from the files as they are (trust on first use).
- `.claude/hooks/board_gate.py`: `pre_edit` compares all guarded lines, matches paths in any spelling plus by header (`id: T-nnn`), reads files with `errors="replace"`; `pre_shell` recognises a real call of the status script (python + path whose basename is `task_status.py`) instead of the text, treats globs, `tasks` anywhere, `cd tasks` and the hook's cwd inside `tasks/` as touching task files, matches `qa_rounds` split up or without a colon, refuses inline `python -c`/`perl -e` code on task files, judges the whole command when any part is not a read, a script call or a git subcommand; git subcommands (`add`, `commit`, `checkout`, `merge`...) stay allowed. New `commit_check`: on `git commit` (also after `cd`/`git -C`) it refuses when a modified or staged task file has guarded lines that are neither HEAD's nor written by the script. The hook still passes when there is no ledger yet.
- `tasks/README.md` ("Changing a task's status"): describes both guards and says a hand-resolved merge conflict in a header needs the status script.
- `tools/test_task_status.py`: `Base.put` resets the ledger (a test's setup is trusted).

Tests: `tools/test_guard.py` (new, 24 tests): one `test_gap_*` per gap above, for `status` and `qa_rounds` (and `lead`), plus tests that reading (T-143's commands, also globbed) still works, real status-script calls (with notes mentioning `status`, `tasks/`, env prefix, `-u`) still work, git add/commit/checkout/merge still work, a script move can be committed, committed older states are trusted, a new task in its starting state is fine, and the T-139 case (hand edit then script) is refused. Results: `python -m unittest discover -s tools` 206 OK; `-s game/tools` 278 OK (1 skipped); `bash game/tools/run_tests.sh` 846/846 pass.

Limits (not closed): an agent could still edit `tools/task_status.py`, `tools/guard_ledger.py` or the ledger file itself; a hook cannot see a commit made by a program (`python` running `git commit`). The ledger check needs the script (main copy) and the hook to share the main checkout's `.board`; a task folder run without git would use its own ledger.

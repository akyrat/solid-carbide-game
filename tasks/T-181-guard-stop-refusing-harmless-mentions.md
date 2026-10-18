---
id: T-181
title: The status guard stops refusing harmless commands that only mention its words
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
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/guard_ledger.py, tools/test_guard.py, tasks/T-143-hook-allow-reading-task-headers.md, tasks/T-149-guard-qa-rounds-hand-edits.md, tasks/T-161-guard-false-refusals.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

On 2026-10-18 the status guard (`.claude/hooks/board_gate.py`, PreToolUse on Bash and PowerShell) refused more than a dozen commands that could not change any ticket's `status`, `qa_rounds` or `lead` line. Agents then made the same edits with the file editing tool, which breaks the rule never to route around a refusal. The board asked for a fix (2026-10-18).

Since T-149, a second guard checks every ticket that would be committed against the status script's record (`tools/guard_ledger.py`, run on `git commit`), so a hand edit of a guarded line can't be committed whatever tool made it. The shell check can therefore aim at commands that actually write a guarded header line, instead of any command that mentions one of the words near a ticket path.

**Commands refused today that must be allowed** (one test each; paths and ids as written, or close equivalents):
1. `cd /c/solid-carbide-game && test -z "$(git rev-parse -q --verify MERGE_HEAD)" && git add tasks/T-162-x.md && git commit -q -m "..." && git log --oneline -1 && git status --short` (a substitution and the word "status" from `git status`).
2. `python tools/task_status.py T-162 --lead X && git worktree add -q -b task/T-162-x /c/solid-carbide-worktrees/T-162 master && cp .env /c/solid-carbide-worktrees/T-162/.env && python tools/task_status.py T-162 in-progress --reply "..."` (status script calls with a `cp` that writes outside `tasks/`).
3. A loop over task folders: `for t in T-151 T-152; do git -C $t add tasks/ && git -C $t commit -q -m "$t: notes"; done`.
4. `git -C /c/solid-carbide-worktrees/G-002 merge -q --no-edit master; git -C /c/solid-carbide-worktrees/T-166 merge -q --no-edit playtest/G-002; python -c "import json;print(len(json.load(open('.claude/settings.json'))['permissions']['allow']))"`.
5. `printf '%s\n' "- 2026-10-18, Project Lead: ... the Project Lead's to run ..." >> tasks/T-176-x.md` (an append to a ticket's result notes whose text says "Lead"; the appended line is not a header line).
6. `python -m unittest tools.test_task_status` (a test run that names the status script).
7. A Python heredoc that edits `tools/task_status.py` or `tools/goal_agent/goal_file.py` (code files, not tickets) and mentions "status".
8. `python /c/solid-carbide-game/tools/task_status.py T-166; git -C /c/solid-carbide-worktrees/T-166 log --oneline -3; git -C /c/solid-carbide-worktrees/T-166 diff --name-only` (read-only).

**Must still be refused** (the existing tests in `tools/test_guard.py` from T-143, T-149 and T-161 keep passing): any shell command that writes a ticket's header `status:`, `qa_rounds:` or `lead:` line (`sed -i`, redirects or heredocs into a ticket that set those lines, Python or PowerShell writes of them, and the other cases those tests cover), and the commit-time ledger check.

Approach is the builder's choice; one way is to refuse only when a command both writes to a ticket file (or can't be shown not to) and its text could set a guarded header line (a `status:`, `qa_rounds:` or `lead:` field at a line start, or a write the hook can't read), rather than on the bare words. Keep the hook's refusal messages.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, including every existing test in `tools/test_guard.py` (QA: pass / fail)
- [ ] `tools/test_guard.py` has one test per command in the "must be allowed" list above (8 tests), each showing the hook lets it through (QA: pass / fail)
- [ ] A test shows a shell command that writes `status: done` (or `lead:`, `qa_rounds:`) into a ticket's header is still refused, and one that a commit of a hand-edited ticket header is still refused by the ledger check (QA: pass / fail)

## Updates

### 2026-10-18, Open → In progress

Started: the status guard will refuse only commands that could actually write a ticket's status, qa_rounds or lead line, not ones that just mention the words. Today's false refusals become tests.

## Result notes

**What changed** (`.claude/hooks/board_gate.py`, shell check only; the Edit/Write check, the commit-time ledger check and the refusal messages are unchanged):

- The shell check now judges each simple command on its own instead of refusing the whole command line when any part is neither a read, a status script call nor git. A part is allowed when it is a read (now also `git -C <path> log/diff/...`, `test`, `[`, `true`, `false`, `printf`, `pwd`), a status script call, git, a test run (`python -m unittest|pytest`), inline code (`python -c`, `perl -e`, a heredoc fed to an interpreter) that names no task file, tasks folder or `.md` glob, a file write (`cp`, `mv`, `rm`, `tee`, `sed -i`, `Set-Content`, ...) none of whose arguments could be a ticket, or an append (`>>`) of plain text to a ticket in which no line starts with `status:`, `qa_rounds:` or `lead:` (echo/printf/Write-Output words, or `cat` of a here-document). Everything else is still refused when the command mentions the words and names task files, as before.
- "Could be a ticket" (`ticket_path`): a path with a `tasks` folder in it, a `T-nnn*.md` name, a name the shell expands (`$`, globs, braces), no name, or any file when the command runs in a tasks folder (or `cd`s to a computed folder). Worktree paths such as `/c/solid-carbide-worktrees/T-162/.env` no longer count.
- `$( ... )` substitutions are read: the commands inside become parts of their own, unless the substitution names task files, holds a heredoc, backtick or `case`, or is arithmetic (then the command is refused as unreadable, as before). A redirect into a computed file name (`> $(...)`) is unreadable. A `for x in ...` loop head is no command.
- `>` (truncate) into a ticket is always refused; `>>` with text the hook can't read (`$`, backticks, numeric escapes, `cat file`) is refused.
- The bare-word pre-check now matches `lead` without a word boundary, so `printf 'x\nlead: A' >> ticket` is not missed (it was before this ticket).
- Module docstring updated; the unused `read_only()` and `safe_target()` were replaced by `ticket_path()`, `Segment`, `substitution()`, `risky_segment()` and helpers, each with a docstring.

**Tests** (`tools/test_guard.py`, new class `HarmlessMentions`, plus one in `Git`):

- Criterion 1: `python -m unittest discover -s tools -p "test_*.py"`: 329 tests, OK (319 before plus 10 new). Every T-143 test (`test_task_status.Hook`), T-149 and T-161 test passes unchanged.
- Criterion 2, one test per "must be allowed" command: `test_allowed_1_commit_with_a_substitution_and_git_status`, `test_allowed_2_claim_worktree_copy_env_and_start`, `test_allowed_3_a_loop_over_task_folders`, `test_allowed_4_merges_then_inline_python_that_reads_settings`, `test_allowed_5_a_result_note_appended_to_a_ticket`, `test_allowed_6_a_test_run_naming_the_status_script`, `test_allowed_7_a_python_heredoc_editing_code_files` (both `tools/task_status.py` and `tools/goal_agent/goal_file.py`), `test_allowed_8_read_only_status_and_git_in_a_task_folder`.
- Criterion 3: `HarmlessMentions.test_still_refused_writes_of_a_guarded_header_line` (18 commands writing `status:`, `lead:` or `qa_rounds:` into a ticket by printf/echo/Write-Output appends, escapes, variables, heredocs, `sed -i`, `cp`, `Set-Content -Path:`, a substitution, a loop, Python, `cd $T`, an unknown script); `Git.test_t181_a_header_hand_edit_is_still_refused_at_commit` (a hand-edited `status:` line is refused at `git commit` by the ledger check; a result-note edit commits).

**tasks/README.md (documents_affected), for the Project Lead to update.** The sentence in "Changing a task's status" that ends "...or that the hook can't tell is read-only, is refused:" is now out of date. Suggested wording: "Shell commands may mention those lines as long as they can't write them: reads (`grep -n "^status:" tasks/T-012*.md`, `sed -n` without `-i`, `head`, `cat`, `git log`, `Select-String`, `Get-Content`), status script calls, git, test runs, writes to files that can't be tickets, and appends of plain text to a ticket's notes with no line starting `status:`, `qa_rounds:` or `lead:` (T-181). A command that could write those lines into a ticket (`sed -i`, `>`, `>>` of such a line, `tee`, `perl -i`, Python or PowerShell writes that name a task file), or that the hook can't read (a computed file name or folder, a substitution that names task files), is refused:"

**While building:** the live hook in the main checkout refused `python -m unittest tools.test_guard tools.test_task_status` run from this folder (path holds `T-181`, command holds "status"), one more case of this ticket's problem. Not worked around; only the full `discover` run was used.

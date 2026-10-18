---
id: T-181
title: The status guard stops refusing harmless commands that only mention its words
status: open
from: project-lead
to: project-lead
lead:
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

## Result notes

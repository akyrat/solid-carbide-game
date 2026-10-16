---
id: T-149
title: The status guard stops agents changing qa_rounds themselves
status: open
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

## Result notes

Written by the agent when it finishes.

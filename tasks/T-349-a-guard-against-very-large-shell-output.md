---
id: T-349
title: Token spend: a guard against very large shell output
status: open
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
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, .claude/settings.json]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/test_guard.py, tasks/README.md]
model: sonnet
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

Shell output was about 33 MB across the sessions, and whole docs printed with `cat` or `sed` were among the largest results; whatever lands in a conversation is re-sent on every later call. The board's idea (2026-10-28): when a command would print too much, don't let it into the conversation as is.

First find out, from the Claude Code hooks documentation, what a hook can do here: refuse a command before it runs (PreToolUse) and say why, or also shorten its output after it ran (PostToolUse). Write the answer in the result notes with the source.

Then build the cheap part: a PreToolUse check (in the existing guard or beside it) that refuses a shell command printing a whole file over a size limit (for example `cat`, `type`, `Get-Content`, or `sed -n` over more than a few hundred lines, of a file over 20 KB), and tells the agent to use a line range, a search, or the Read tool with an offset and limit. Small files and commands already capped (`head`, `tail`, `| head`) pass. Propose the limit in the result notes.

The board's further idea, a Haiku agent summarising large output for the agent to double-check, is a later step: describe in the result notes whether hooks allow it and what it would cost, and don't build it.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes say what PreToolUse and PostToolUse hooks can do with shell output, citing the documentation. (QA: pass / fail)
- [ ] `cat` of a file over the limit is refused with a message naming the alternatives; `cat` of a small file, `head -50` of a big one and `grep` on a big one pass (a guard test each). (QA: pass / fail)
- [ ] The result notes cover the Haiku-summary idea (possible or not, cost) without building it. (QA: pass / fail)
- [ ] Every existing guard test still passes unchanged. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

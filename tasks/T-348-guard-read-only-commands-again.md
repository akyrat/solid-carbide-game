---
id: T-348
title: Token spend: the guard stops refusing read-only commands (sort, uniq, python -c, chained status calls)
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
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, tools/test_guard.py, tasks/T-248-guard-more-harmless-commands.md]
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

The guard (`.claude/hooks/board_gate.py`, `pre_shell`) still refuses commands that can't write a task file's `status`, `qa_rounds` or `lead` line. Each refusal costs a retry at the session's full context size, and refusals caused 8 goal-run pauses. Cases seen on 2026-10-28 (the Tokens session and its observers):

- `ls tasks | sort | tail -5` (refused because of `sort`);
- `grep -h "^qa_rounds:" tasks/T-*.md | uniq -c` (refused because of `uniq`);
- a read-only `python -c` or `python -I -` heredoc that only reads files under `tasks/` or the transcripts;
- `python tools/board_inbox.py name <session> <Name> && python tools/task_status.py T-NNN --lead <Name>` (refused because `board_inbox.py` holds the word `lead`, though `name` writes no ticket).

Let each through, judged as T-212, T-216 and T-248 do (what the command actually writes, and where). `sort -o` or `uniq` with an output file inside `tasks/`, and a Python script that writes under `tasks/`, are still refused. Keep refusing everything the existing guard tests refuse. A refusal still names what made it refuse.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each of the four commands in the description, rebuilt with real paths, is allowed (a guard test each). (QA: pass / fail)
- [ ] `sort -o tasks/x`, `uniq a tasks/x`, and a Python command that writes under `tasks/` are still refused (a guard test each). (QA: pass / fail)
- [ ] Every existing guard test still passes unchanged. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

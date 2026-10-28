---
id: T-343
title: Token spend: agents write their full report on the ticket and hand back one short line
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
files_to_read_first: [tasks/README.md, .claude/agents/qa-integration.md, tools/goal_agent/build.py]
files_expected_to_change: [.claude/agents/, tools/goal_agent/build.py, tools/goal_agent/test_build.py, tasks/README.md]
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

Subagent reports pasted back into the Project Lead's conversation were the largest single cost in the long sessions (about 880k characters, 11% of the weighted cost in session 88cd). From now on (board's go, 2026-10-28) an agent writes its full report in the ticket's result notes and hands back at most about 300 characters: the ticket id, done or blocked, and one line on what the Project Lead must act on. The same for QA: the pass or fail per criterion stays on the ticket, the hand-back is one line.

Two more lines go in the same hand-back wording (board's go, 2026-10-28, through the Tokens session's recommendations): run tests in the foreground and leave no background jobs when handing back (finished agents with leftover background test runs woke up again and re-sent their hand-back, 60k to 150k tokens each time); and commit the ticket, result notes and QA results included, before handing back (the wave-1 QA agents left their pass results uncommitted in the worktree, which held up the merges).

Change the hand-back rule where the agents get it: the common hand-back wording in each agent definition (`.claude/agents/*.md`; only that wording, not their roles), the goal runner's agent and QA prompts (`tools/goal_agent/build.py`), and `tasks/README.md`. The board approved this change to the agent definitions for this ticket. Don't touch anything else in the definitions.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every agent definition in `.claude/agents/` tells the agent to put its full report in the ticket's result notes and to hand back one short line (about 300 characters at most), to run tests in the foreground and leave no background jobs, and to commit the ticket (result notes and QA results included) before handing back; the diff touches nothing else in them. (QA: pass / fail)
- [ ] The goal runner's agent and QA prompts say the same, and a test in `tools/goal_agent/test_build.py` checks it. (QA: pass / fail)
- [ ] `tasks/README.md` states the rule once, and the other places point to it. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

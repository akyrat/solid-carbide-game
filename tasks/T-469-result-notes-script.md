---
id: T-469
title: A script appends an agent's report to a ticket's result notes
status: open
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, tasks/_TEMPLATE.md, tools/task_status.py, tools/test_task_status.py, .claude/hooks/]
files_expected_to_change: [tools/task_notes.py, tools/test_task_notes.py, tasks/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-10-31: agents keep hitting refusals when they write their result notes. The command guard refuses Bash writes to ticket files (it can't tell them from status changes), and the auto-mode classifier sometimes refuses the Edit tool on a ticket too (T-446, T-443, T-436). Agents then either stop, or use the Edit tool as a workaround, which breaks the rule against getting around a refusal.

Write `tools/task_notes.py T-NNN --append FILE` (and `--text "..."`), which appends to the ticket's `## Result notes` section only, finding the ticket's file on its open branch the same way task_status.py does. It must never touch the header (status, qa_rounds, lead or any other line) or any other section, and it refuses anything else. Make it one of the commands the guard lets through, like task_status.py: read .claude/hooks/ to see how the guard recognises the status script. If the guard or `.claude/settings.json` (the allow list) needs a change, don't make it: write exactly what to change in the result notes, since only the board changes permissions. Update tasks/README.md ("Handing back") so agents write their notes with this script. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `tools/task_notes.py T-NNN --text "..."` appends to the Result notes section only, and a test shows the header and every other section are byte for byte unchanged. (QA: pass / fail)
- [ ] It finds the ticket on its open branch folder like task_status.py, and refuses a missing ticket or section (tests). (QA: pass / fail)
- [ ] The result notes say whether the command guard lets it through as is, and if not, exactly what change the board would need to make. (QA: pass / fail)
- [ ] tasks/README.md ("Handing back") tells agents to use it. (QA: pass / fail)
- [ ] The tools and game/tools Python tests pass (`python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

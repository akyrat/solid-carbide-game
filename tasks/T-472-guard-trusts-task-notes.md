---
id: T-472
title: The command guard trusts tools/task_notes.py like the status script
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
depends_on: [T-469]
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, tasks/T-469-result-notes-script.md, .claude/hooks/board_gate.py, tools/test_guard.py]
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
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-10-31: T-469 added tools/task_notes.py, which appends an agent's report to a ticket's result notes only. The command guard lets plain calls through, but refuses a call whose --text mentions tasks together with words like status or lead, which agents' reports often do. T-469's result notes say what to change: add tools/task_notes.py to the guard's trusted ticket tools (TICKET_TOOLS in .claude/hooks/board_gate.py, around line 1658), the way task_status.py is trusted.

The board asked for this change and approves editing the hook for it; if the permission system or the safety check asks, the board answers the prompt. If the edit is refused anyway, don't get around it: stop and say so. Change only what trusting task_notes.py needs; every other guard rule stays exactly as it is.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A guard test shows `python tools/task_notes.py T-NNN --text "..."` is let through whatever its text says (status, lead, tasks). (QA: pass / fail)
- [ ] Guard tests show a direct write to a ticket's status line (sed, cp, a python - script) is still refused exactly as before. (QA: pass / fail)
- [ ] Only the trusted-tools list (and its test) changed in board_gate.py (diff in the result notes). (QA: pass / fail)
- [ ] tasks/README.md ("Handing back") says agents use task_notes.py for their result notes. (QA: pass / fail)
- [ ] The tools Python tests pass (`python -m unittest discover -s tools -p "test_*.py"`), with the count in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

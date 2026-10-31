---
id: T-452
title: Text: the HUD layout editor's labels
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/data/pause_text.json]
files_expected_to_change: [game/data/pause_text.json, docs/hud-and-menus.md]
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "The player can move the HUD's pieces"): the pause screen gets a way to edit the HUD's placement. The linked UI ticket (it depends on this one) needs its text first, written into game/data/pause_text.json beside the pause screen's other labels and in their style: (1) the pause screen button that opens the HUD layout editor; (2) a one-line hint shown while editing (drag a piece to move it); (3) the button that resets the layout to the default; (4) the button that finishes editing and goes back to the pause screen. Each goes through the style loop (tasks/README.md, "The style loop"). Text-only work: write "no screenshots: text-only work" in the result notes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/pause_text.json has the four texts under their own keys and stays valid JSON. (QA: pass / fail)
- [ ] Each text's style loop score is in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) lists the texts or their keys. (QA: pass / fail)
- [ ] The game/tools Python tests pass (`python -m unittest discover -s game/tools -p "test_*.py"`), with the count in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

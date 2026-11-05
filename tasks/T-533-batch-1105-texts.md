---
id: T-533
title: Texts: reverse drift and aura trick popups, the pause screen's Resume button, the rail grind popup
status: open
from: project-lead
to: narrative-theme
lead: Rails
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/drifting.md, game/data/pause_text.json]
files_expected_to_change: [docs/hud-and-menus.md]
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

Final text, through the style loop, for: (1) the popup of the new reverse drift trick (Drifting, Decisions, "A reverse drift trick"), same size and style as LONG DRIFT! / FULL 360!; (2) the popup of the new aura trick ("An aura trick": stay still 5 s, then paid every second; the board calls it the aura trick); (3) the label of the pause screen's new Resume button (HUD and menus, Decisions, "Resume on the pause screen, buttons stacked"), one short word or two like the existing Restart and Exit; (4) the popup of the rail grind (Drifting, Decisions, "Rail grinding, a prototype"); the old prototype's card was GRIND! (Drifting, Content, "Trick prototype (reference)"); reuse it if it still fits. Also, for each of the three tricks, a one-line trick list entry and its keycap recipe in the same form as the existing ones (HUD and menus, "Each trick shows the keys that make it"), for when the trick list is updated. Record the texts in HUD and menus, Content, and in the result notes.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes give the final text of the four pieces and the three trick list entries with recipes, each with its style loop score of 8 or more. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content records the texts. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

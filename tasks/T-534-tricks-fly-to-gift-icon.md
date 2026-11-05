---
id: T-534
title: Tricks fly to the gift icon
status: open
from: project-lead
to: ui
lead: Rails
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, game/docs/hud-and-menus/hud.md]
files_expected_to_change: [game/scripts/hud/, game/scenes/hud/, game/data/hud.json, game/tests/, game/docs/hud-and-menus/hud.md, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "Tricks fly to the gift icon". Each time a trick or the combo pays subs, a small effect (for example a few glowing particles or a token) flies from the car's place on screen to the gift icon at the right end of the sub goal bar, and arrives about when the bar fills. Placeholder effect drawn in code, no generated art, no new text. It must follow the HUD's scale and the player's HUD layout (the icon can be moved by the HUD layout editor). Keep it cheap: several tricks at once must not drop the frame rate.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] When a trick pays subs, an effect node is spawned that travels from the car's screen position to the gift icon's current position and frees itself on arrival (test). (QA: pass / fail)
- [ ] It goes to the icon's moved position when the HUD layout has been edited, and scales with the HUD size (test). (QA: pass / fail)
- [ ] Ten tricks paid on the same frame spawn at most a bounded number of nodes, with the bound in data (test). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content and game/docs/hud-and-menus/hud.md describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF or frame strip in art-archive/T-534/screenshots/ shows the effect flying from the car to the gift icon in a run. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

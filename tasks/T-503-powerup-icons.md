---
id: T-503
title: Icons: Rusty Paintjob's spray can and the Polarized Steering Wheel
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, game/art/power_ups/]
files_expected_to_change: [game/art/power_ups/, art-archive/, game/tests/unit/]
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

The board, 2026-11-02 (docs/drifting.md, Decisions, "Rusty Paintjob and the Polarized Steering Wheel"): two new power-up icons, in the style of the other power-up icons (game/art/power_ups/, Visual style). 1. **Rusty Paintjob**: a rusty-looking spray can (it replaces Rusty Overcoat's icon, game/art/power_ups/rusty_overcoat.png; keep the old one in art-archive). 2. **Polarized Steering Wheel**: a steering wheel (it replaces T-502's placeholder). Same size, outline and palette as the other icons. The board's go for PixelLab (2026-11-02): through the style loop, each asset at most 4 generations (the first plus up to 3 refines), 8 in all; write the planned calls and their cost in the result notes before calling; 600 s HTTP timeout. Swap the art into the game yourself (the icons in the power-up overlay, the HUD and wherever the others show) and keep every generation in art-archive/T-NNN/. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/art/power_ups/ has the spray can for rusty_overcoat and the steering wheel for the new power-up, the same size as the other icons; the old Rusty Overcoat icon is kept in art-archive. (QA: pass / fail)
- [ ] Every generation is in art-archive/T-NNN/, and the result notes count them (at most 4 per asset, 8 in all). (QA: pass / fail)
- [ ] The ticket's Style review records the style loop for both assets, with their scores. (QA: pass / fail)
- [ ] The power-up overlay and the HUD show the new icons (screenshots on dark and light, enlarged). (QA: pass / fail)
- [ ] The full Godot test set passes in QA (the art tests included). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

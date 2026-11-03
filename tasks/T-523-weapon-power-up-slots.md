---
id: T-523
title: Weapon and power-up slots: 3-slot grids with tier pips
status: needs-playtest
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, docs/visual-style.md, game/scripts/hud/hud.gd, tasks/README.md]
files_expected_to_change: [game/scripts/hud/, game/data/hud.json, game/tests/unit/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 1
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

Build docs/hud-and-menus.md, Decisions, "Weapon and power-up slots": the HUD's weapon icons sit in a grid of 3 slots (a table-like frame around them) in the top-left weapon column, and the driving power-ups the player owns get 3 slots in a second column beside it; empty slots show as an empty frame; each icon has small tier pips (count read from each item's max tier in data, so 5 for weapons and 2 for power-ups after T-520, built in parallel). In the HUD style sheet's look (visual-style.md, "The HUD style sheet"), drawn in code, no PixelLab. The HUD layout editor and HUD scaling keep working (the pieces move together). No text. Update docs/hud-and-menus.md Content.

The board, 2026-11-03: the run is shortened to 4 minutes (3:00 build, kaiju 3:00 to 4:00). Decisions: docs/game-loop-architecture.md "A 4-minute run: 3 minutes to build, 1 minute of kaiju"; docs/weapons.md "Shorter trees: 5 tiers"; docs/drifting.md "Two tiers and three slots for the driving power-ups"; docs/enemies.md "Paced for the 4-minute run"; docs/hud-and-menus.md "Weapon and power-up slots". T-519 to T-523 are built in parallel and combined by the Project Lead into one build (T-521's folder) that the board plays before anything merges. Many existing tests assume the 8-minute run, the kaiju at 7:00 and 8 tiers: update the ones your change breaks (say which in the result notes), never delete a test's purpose. Numbers you choose are proposals for the playtest, in game/data with a _comment. Never write, move or commit anything in game/data/levels/. SFX stay off. Stage files by name, never .uid/.import noise. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-519 to T-523) from C:\solid-carbide-worktrees\T-521\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: the weapon grid always shows 3 slots, filled in the order weapons are collected, empty frames for the rest. (QA: pass)
- [ ] A unit test: the power-up grid shows 3 slots the same way, filled as power-ups are collected. (QA: pass)
- [ ] A unit test: an icon's pips equal its max tier from data and the filled ones its current tier. (QA: pass)
- [ ] The HUD layout editor and the HUD size slider still place and scale the grids (tests). (QA: pass)
- [ ] docs/hud-and-menus.md Content describes the grids. (QA: pass)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass)
- [ ] Screenshots of the HUD with 1, 2 and 3 weapons and some power-ups, under art-archive/T-NNN/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Started: weapon and power-up slots.

### 2026-11-03, In progress → In QA

Weapon and power-up 3-slot grids with tier pips are in, tests pass, screenshots in art-archive/T-523/screenshots.

### 2026-11-03, In QA → Needs playtest

QA passed; play it in T-521's combined 4-minute-run build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built: SlotGrid (slot_grid.gd, drawn in code, HUD style sheet look) x2 inside the existing weapon_icons piece (weapon grid, power-up grid beside it, always same size, so layout editor and size slider move/scale both). 3 slots each, filled in order collected, empty frames; pips = max tier from data (weapon.max_tier(), PowerUpData.max_tier), filled to current tier; narrower if more pips than fit. Weapon 'xN' count kept. Power-up icons 32px art at 1x. Hud.bind calls setup_power_ups(state). Weapons beyond 3 are owned but have no slot/row. Tests: new test_hud_slot_grids.gd (6); updated test_hud_weapon_icons.gd (3 rows not 4; 6-weapon fit test now checks piece rect). Ran layout, layout_editor, scaling, size_slider, heart_row, style, weapon_icons, slot_grids: all pass. Doc: hud-and-menus.md Content, 'The weapon and power-up slots'. Screenshots: art-archive/T-523/screenshots/hud_slots_1/2/3.png (fixtures t523_slots_shot*.tscn). Proposals: frame size, white pips, grid ends y~291 clear of the mission page.

QA round: all 7 criteria pass; test sets pass; screenshots 1/2/3 weapons checked (3-slot grids, pips read max tier from data).

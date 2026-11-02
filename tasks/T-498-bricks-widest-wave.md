---
id: T-498
title: Bricks tier 8: the widest wave with two extra crash rings
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-495, T-496]
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/bricks.gd, game/data/weapons.json]
files_expected_to_change: [game/data/weapons.json, game/scripts/weapons/bricks.gd, game/scripts/data/weapon_data.gd, game/art/weapons/, game/tools/, game/tests/unit/, docs/weapons.md, game/docs/weapons/]
model: opus
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

The board, 2026-11-02 (docs/weapons.md, Decisions, "The board's own upgrade trees"): Bricks tier 8 (Widest Wave) multiplies the wave's radius by 3 on top of the earlier tiers (4 x1.4 x1.5 x3, about 25 units) and is a new wave: 2 extra outer crash rings around the usual one, and the wave travels from the inner ring out to the outer ones, for a sense of huge impact. Each ring hits enemies (damage and minion knockback, never pushing the kaiju) as the wave reaches it, once per enemy per landing. The board's note: "Effectively, this will be a new animation, where we add 2 extra outer layer crash circles around the existing one, massively increasing the width (probably gonna be 3 times bigger). I want the animation to look like a wave coming from the inner to the outer circles to give sense of huge impact." Add the tier to weapons.json (a new effect for this tier, your choice of name, with value 3) and draw the art the same way as T-325's wave sheets (script-drawn, no PixelLab); the radii the new tiers 2 and 5 reach get their sheets too, so no radius falls back to the placeholder ring. Mind T-481's frame-time work on bricks: the big wave must not bring back frame drops (measure the landing frame time headless and write it in the result notes). Ring timing is a proposal for the playtest. Describe it in docs/weapons.md Content (Bricks) and game/docs/weapons/. Never write, move or commit anything in game/data/levels/. SFX stay off.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] weapons.json bricks has tier 8 with the new effect and value 3, and bricks reaches tier 8 in the level-up offers; the tier 8 card is T-495's text. (QA: pass / fail)
- [ ] A unit test: at tier 8 the wave's radius is 3 times the tier 7 radius. (QA: pass / fail)
- [ ] A unit test: an enemy near the outer edge is hit later than one near the car (when the wave reaches its ring), every enemy in reach is hit exactly once per landing, and the kaiju is damaged but never pushed. (QA: pass / fail)
- [ ] Every radius the bricks tiers reach (tiers 1 to 8) has a wave sheet in game/art/weapons/ (no placeholder ring), and the tier 8 sheet shows 3 rings drawn inner to outer. (QA: pass / fail)
- [ ] The landing frame time at tier 8, measured headless, is in the result notes. (QA: pass / fail)
- [ ] docs/weapons.md (Bricks) describes tier 8. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots or a frame strip of the tier 8 wave, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

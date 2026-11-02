---
id: T-496
title: Weapon data for the board's upgrade trees
status: open
from: project-lead
to: game-data
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-495]
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/data/weapons.json, game/scripts/data/weapon_data.gd, game/scripts/weapons/starting_gun.gd, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/data/weapons.json, game/scripts/data/weapon_data.gd, game/scripts/weapons/level_up_offers.gd, game/tests/unit/, docs/weapons.md, game/docs/weapons/]
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

The board, 2026-11-02 (docs/weapons.md, Decisions, "The board's own upgrade trees"): put the board's tier lists into game/data/weapons.json for the gun, Hot Take Exhaust, Hot Drop, Bricks tiers 2 to 7 and Wiper Blade tiers 2 to 7, in the board's order, with the board's numbers. All of these use effects the game already understands for that weapon (data only). Bricks tier 8 (T-498) and Wiper Blade tier 8 (T-499) need new code and are added by those tasks; leave them out here, so Bricks and Wiper end at tier 7 until then (check the level-up offers stop at a weapon's last tier and don't break on a 7-tier weapon). The gun drops to 8 tiers (its own max_tier 8) and its targets stay 1 all run: no set_targets tier remains. The gun's single-target stream (each bullet, as it leaves, aims at its target if it is alive, otherwise at the closest living enemy) is already built (T-408) and is what the board wants; check it still holds with more bullets and the x4 fire rate. Update every _comment in weapons.json and every place in docs/weapons.md (Content) and game/docs/weapons/ that states the old tiers or numbers, and the tests that pin old tier values. Never write, move or commit anything in game/data/levels/. SFX stay off.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] weapons.json tiers match the Decisions entry for gun (tiers 2 to 8), flamethrower (2 to 8), molotov (2 to 8), bricks (2 to 7) and wiper (2 to 7): effect and value per tier, checked by a unit test. (QA: pass / fail)
- [ ] The gun's max_tier is 8 and no gun tier uses set_targets; a unit test shows a gun at tier 8 aims at one target at a time, and a bullet whose target died before it left aims at the closest living enemy. (QA: pass / fail)
- [ ] A unit test shows the level-up offers never offer bricks or wiper past their last tier. (QA: pass / fail)
- [ ] Neon Underglow's block in weapons.json is unchanged. (QA: pass / fail)
- [ ] docs/weapons.md Content and game/docs/weapons/ no longer state the removed tiers (Multi-Target Mode, turn speed, the molotov damage and fire-duration tiers, the wiper damage tiers). (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots of the level-up screen offering a changed card for at least three weapons, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

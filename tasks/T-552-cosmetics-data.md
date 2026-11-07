---
id: T-552
title: Cosmetics data: the jump effects, their prices, unlocking with coins, the saved choice
status: done
from: project-lead
to: game-data
lead: Rails
epic: garage
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/drifting.md, docs/hud-and-menus.md]
files_expected_to_change: [game/data/, game/scripts/, game/tests/, docs/garage-design.md]
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

Build the data side of Garage design, Decisions, "Cosmetics". A data file listing the cosmetics: for now the 5 jump effects (ids dash_cloud, spring, jet_thrust, stunt_sparks, shockwave_ring), each with its price in coins (dash_cloud free and unlocked from the start; propose the others' prices against what the garage upgrades cost and what a run earns, with your reasons). In the save (the same save as the garage, with its version and backup, Garage design, "A broken save never wipes progress"): which cosmetics are unlocked and which jump effect is picked, defaulting to dash_cloud for an old save. A small API the UI (T-553) and the car (T-551) use: list, is_unlocked, can_afford, buy (spends the coins, saves), equip, equipped_jump_effect. No texts here (names come from T-550's data).

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The cosmetics data lists the 5 jump effects with prices, dash_cloud free and unlocked (test). (QA: pass; test_cosmetics 7 tests, full sets pass)
- [ ] Buying spends the coins and unlocks it, refused without enough coins; equipping saves the choice; both survive a reload (tests). (QA: pass; test_cosmetics 7 tests, full sets pass)
- [ ] An old save without cosmetics loads with dash_cloud unlocked and picked, and loses nothing (test). (QA: pass; test_cosmetics 7 tests, full sets pass)
- [ ] docs/garage-design.md Content gives the prices with their reasons and the API. (QA: pass; test_cosmetics 7 tests, full sets pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass; test_cosmetics 7 tests, full sets pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: cosmetics data, prices and the saved choice.

### 2026-11-07, In progress → In QA

Built: cosmetics data, prices 0/150/300/450/600 coins, saved choice. QA now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. Added game/data/cosmetics.json (5 jump effects; prices proposed: dash_cloud 0 free+unlocked, spring 150, jet_thrust 300, stunt_sparks 450, shockwave_ring 600; reasons in docs/garage-design.md 'Cosmetics data': a run earns ~250 coins, cheapest upgrade level 40, so ~0.6 run of coins per step), game/scripts/data/cosmetics_data.gd (CosmeticsData), and the saved choice in PlayerProgress (progress.json gains cosmetics:{unlocked,jump_effect}, same SafeSave version/backup; an old save loads with dash_cloud unlocked and picked, nothing lost; unknown ids dropped, a locked pick falls back to dash_cloud). API for T-551 and T-553, all on PlayerProgress (GameFlow.progress): cosmetics_list() -> [{id,price,unlocked,equipped}] in menu order; is_unlocked(id); can_afford(id); buy_cosmetic(id) -> {ok,reason} (reasons NOT_ENOUGH_COINS, ALREADY_UNLOCKED, UNKNOWN_COSMETIC; spends, saves, does not equip); equip(id) -> bool (unlocked only, saves); equipped_jump_effect() -> String (the car reads this at jump). 'changed' signal emits after buy/equip. Docs: docs/garage-design.md, game/docs/data/game-data.md. Tests run (foreground): test_cosmetics.gd (7 tests, all pass), test_player_progress.gd, test_safe_save.gd, test_garage_data.gd all pass. No screenshots: nothing to show (data only).
- 2026-11-07, in-qa → done: QA passed; data, no board review needed

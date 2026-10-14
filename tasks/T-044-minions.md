---
id: T-044
title: Minions: spawn, chase the car, contact damage, die and drop coins
status: needs-playtest
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-036, T-039, T-033]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-039-enemy-data.md, tasks/T-033-car-collisions-and-knockback.md, game/README.md]
files_expected_to_change: [the enemy code and scenes, tests, docs/enemies.md, game/README.md]
model: opus
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-036 (the run), T-039 (the numbers) and T-033 (car collisions and knockback) are done.**

Build the MVP minion as Enemies, Decisions describes it, with T-039's numbers:
1. **Spawning:** minions come in from the edges of the screen, in numbers that grow slightly over the run (the run's clock, T-036).
2. **Movement:** they walk towards the car. They use T-033's enemy collision layer, so the car never bounces off them.
3. **Contact damage:** while touching the car, a minion damages it through the run's damage function (T-036) at the data's rate, and knocks it back through T-033's knockback function.
4. **Taking damage:** a public damage function the weapons call (T-041, T-042). Document it for them. A minion dies at 0 health.
5. **Coins:** on death a minion may drop coins (the data's chance and amount). Driving over a coin collects it through the run's add-coins function (T-036).
6. Minions stop when the run is paused, and are cleared when a new run starts.

Minions and coins are placeholders for now (simple shapes in the palette; minions light green). The final minion and coin art come from separate art tasks.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

**Draw order (from T-034's QA, 2026-10-13):** once T-034 (see-through buildings) is merged, buildings get a depth order and the car is drawn just under the buildings covering it. Minions must get a place in that order too (see `map.car_z_index()` and game/README.md, "See-through buildings"), or they will be drawn under every building even when in front of one. The fade itself stays car-only.

## Acceptance criteria

- [x] A test simulates the run's clock and shows there are more minions at the end of the 7 minutes than at the start, as the data says (QA: pass)
- [x] A test shows a minion moves towards the car (QA: pass)
- [x] A test keeps a minion touching the car and shows the car's health drops at the data's rate and the car is knocked back (QA: pass)
- [x] A test damages a minion to 0 and shows it dies; over many deaths, coins drop at about the data's chance (QA: pass)
- [x] A test drives the car over a coin and shows the run's coin total goes up and the coin disappears (QA: pass)
- [x] A test shows minions don't move while the run is paused, and are cleared when a new run starts (QA: pass)
- [x] A screenshot of the run shows placeholder minions around the car (QA: pass)
- [x] `game/README.md` documents the enemies' damage function for the weapon tasks, and `docs/enemies.md` describes the built minion in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it). There are no weapons yet, so this playtest covers spawning, chasing, contact damage, knockback, pause and draw order. Killing minions and coins are checked by the tests only, and the board judges them in a playtest once the starting gun (T-041) is in. No debug kill key (board, 2026-10-14).

## Result notes

Written by the Enemy Behavior Agent (2026-10-14).

**Built** (branch `task/T-044-minions`, folder `C:\solid-carbide-worktrees\T-044`):
- `game/scripts/enemies/minion_spawner.gd`: the run's minions (`run.minions`). Spawning from `EnemyData.minions_wanted(run seconds, spawn_multiplier)`, one every `spawn_interval_seconds` while fewer are around, `spawn_margin_units` beyond the visible screen's edge, on the map and clear of buildings and boulders. Moves, contact damage, coin drops, clearing on a new run (`run.world_rebuilt`), and the draw order, all in `step(dt)` once per physics step (pausable).
- `game/scripts/enemies/minion.gd`: one minion (`CharacterBody2D`, layer 3, mask 1): walks at the car, slides along and walks round obstacles, contact damage through `RunState.damage_car()` with knockback through `car.apply_knockback()`, and the public `take_damage(amount)` for the weapons; dies at 0 health (`died` signal).
- `game/scripts/enemies/coin.gd`: a coin (`Area2D`, layer 4, mask 2); driving over it calls `RunState.add_coins(1)` and removes it.
- `game/scripts/enemies/minion_sprite.gd`, `coin_sprite.gd`: placeholders drawn in code (a light green four-legged lizard, gold coins; no Redgull red).
- `game/scripts/enemies/enemy_depth.gd`: minions' and coins' place in the buildings' depth order, the map's rule for the car (`map.car_z_index()`); the fade stays car-only.
- `game/scripts/run/run.gd`: adds the spawner (`minions`, child `Minions`) and binds it. Nothing else changed there.
- Combo hook for T-085: `run.minions.spawn_multiplier` (1.0 now) multiplies `minions_wanted`. T-085 sets it from `RunState.combo_spawn_multiplier()`.
- No numbers in `game/data/enemies.json` changed. No debug or cheat input.

**How to see it:** open `C:\solid-carbide-worktrees\T-044\game\project.godot`, press F5, then Start. Minions come in from the screen's edges within a second and chase the car.

**Screenshots** (taken from a run started from the main menu): `C:\solid-carbide-worktrees\T-044\art-archive\T-044\screenshots\minions.png` (12 placeholder minions and two coins around the car) and `C:\solid-carbide-worktrees\T-044\art-archive\T-044\screenshots\minions_draw_order.png` (the car beside a block of skyscrapers and two boulders, with minions in front of and behind them). To retake them: `bash game/tools/screenshot.sh res://tests/fixtures/minions_demo.tscn screenshots/minions.png 20` and the same with `minions_draw_order_demo.tscn`.

**Tests:** `game/tests/unit/enemies/test_minions.gd`, 19 tests, all pass. They cover every criterion: the count at 0:00 (12), halfway and at 7:00 (20) with the run's clock moved on; walking straight at the car at the data's speed (and round a building); contact damage of 5 per hit every 0.5 s (4 hits in 2 s) with knockback of 8 away from the minion each hit; death at 0 health; coins dropping in 364 of 600 deaths (60.7%, seed 44; data: 60%), 2 each; driving over a coin adding 1 to the run's coins and removing the coin and its drawing; no movement or spawning while paused; a new run clearing all minions and coins. Full GUT suite: 573 of 573 pass (53 scripts, `TESTS PASSED`). Python tool tests: `game/tools` 235 OK (1 skipped), `tools` 130 OK.

**Documents affected:** `docs/enemies.md` (Content only: "The minion (built in task T-044)"; Summary, Decisions and Open questions unchanged), `game/README.md` (new "Minions" section with the damage function for T-041 and T-042, plus one line each in "Folder layout" and "Collision layers").

**Choices I made where the docs leave it open** (Enemies, Decisions: spawning and contact damage are proposed by this agent, and the board judges them in playtests):
- Minions do not walk through buildings, walls or boulders. They slide along them and walk round one that blocks their way.
- A minion the car has left a whole screen behind is removed without coins, and a new one comes in at the screen's edge, so the swarm stays around the car (the car is faster than the minions).
- Contact damage is per minion: each touching minion hits every 0.5 s, the first hit as soon as it touches.
- A drop is 2 separate 1-coin pickups, spread round the spot where the minion died. Coins stay until collected or a new run.
- Some numbers are in code because they are placeholder sizes and rules, not balancing numbers: the minion's and the coin's radius (0.5 units each) and the separation between minions (1.2 units). If the board wants to tune them, the Game Data Agent can move them into `enemies.json`.

**For the board's playtest:**
- **Spawning and chase:** whether 12 to 20 minions feel right, and whether they arrive fast enough at the start (they fill up over the first 6 s).
- **Contact damage and knockback:** stop the car and let them reach it. Health drops 5 per hit, and each hit cuts the combo.
- **Pause:** Escape freezes the minions.
- **Draw order:** drive past the skyscrapers. Minions behind a skyscraper are hidden by it, and those in front are drawn over it. Since the fade is car-only, a minion behind an opaque skyscraper is not visible at all. Also: where the car and a minion share a depth level, the car is always drawn over the minion, even when the minion stands just in front of it.
- **Placeholder size:** the minion is drawn about 1 unit (the car's width) across.
- Killing minions and coins can't be played yet (no weapons, no debug key); the tests cover them.

**QA (QA/Integration Agent, 2026-10-14, round 1): all 9 criteria pass.**
- Clock test: `test_more_minions_at_the_end_of_the_7_minutes_than_at_the_start` (12 at 0:00, 20 at 7:00, matching `minions_wanted`). Pass.
- Movement: `test_minion_moves_towards_the_car` (and round a building). Pass.
- Contact damage and knockback: `test_touching_minion_damages_the_car_at_the_data_rate_and_knocks_it_back` (5 per 0.5 s, knockback away from the minion). Pass.
- Death and coin chance: `test_minion_dies_at_zero_health`, `test_coins_drop_at_about_the_data_chance` (600 deaths, about 60%). Pass.
- Coin pickup: `test_driving_over_a_coin_collects_it` (coins up, coin gone). Pass.
- Pause and new run: `test_minions_stand_still_while_paused`, `test_new_run_clears_minions_and_coins`. Pass.
- Screenshots: `art-archive/T-044/screenshots/minions.png` shows 12 light green placeholder lizards and two gold coins around the car; `minions_draw_order.png` shows minions around the car beside boulders and skyscrapers. The only red on screen is the board-approved HUD heart; the placeholders have no Redgull red (also `test_placeholders_avoid_redgull_red`). Pass.
- Docs: `git diff master -- docs/enemies.md` touches only the Content section (Summary, Decisions, Open questions unchanged); `game/README.md` has a new "Minions" section documenting `take_damage(amount: float)` for T-041 and T-042. Pass.
- Tests, run by QA in this folder: GUT 573 of 573 pass (53 scripts, `TESTS PASSED`, exit 0); `game/tools` Python 235 OK (1 skipped); `tools` Python 130 OK. Pass.
- Also checked: `game/data/enemies.json` is unchanged from `master`; no input handling (no `Input.`, `_input`, `_unhandled_input`, key or action checks) in the new enemy scripts, the fixture or the `run.gd` change, so no debug or cheat input. Godot's line-ending-only `.import` changes from the test run were left uncommitted.

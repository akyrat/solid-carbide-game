---
id: T-360
title: Wrecked: the car smokes and burns for 3 seconds when its last heart is gone
status: done
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/hud-and-menus.md, game/docs/game-loop/the-run.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/scripts/run/run_state.gd, game/scripts/game/game_flow.gd, game/scripts/driving/, tasks/T-317-the-time-s-up-screen.md, tasks/T-320-the-recap-screen.md]
files_expected_to_change: [game/scripts/run/, game/scripts/driving/, game/scripts/game/game_flow.gd, game/data/, game/tests/unit/, game/docs/game-loop/the-run.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, art-archive/]
model: opus
qa_rounds: 2
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Game loop architecture, Decisions, "Wrecked: the stream keeps rolling", 2026-10-29), in its words: "when the player dies, don't end the scene yet and just disable the controls. Keep any movement that the car had. And then maybe we can show some smoke coming out of it ... Maybe it'd be really cool to add some flames as well ... So for 3 seconds, the car is still on the screen, kind of crashed and smoking. Then we show the recap." Like the end of a livestream that doesn't cut away.

When the car loses its last heart:
- The run's result is decided at that moment (a loss), but the scene stays for **3 seconds** before the run ends (the same `run_ended` as today, so the recap, T-320, or the main menu follows exactly as now).
- **The controls go dead**: no steering, throttle, brake, drift or handbrake input reaches the car. The car **keeps the movement it had** and slows to a stop with its normal physics (it can still slide, spin out or bump into things; the camera keeps following). Driving & Drift's code owns the car: add the smallest switch that turns its input off, and don't change how it handles while alive.
- The car can't take damage, collect coins, likes or gift packs, or score tricks during the 3 seconds. Enemies, the timer and the HUD carry on or freeze: your proposal for the playtest (the board wants the stream to feel like it is still live: the HUD stays on screen).
- **Smoke and flames** come out of the car for the 3 seconds: placeholders in code first (simple pixel puffs and flickers, none of Greenbull's colours, Visual style, Content, "Rules", rule 6). The linked art ticket (pixel art smoke and flames animations) swaps its art in; the board wants to play this ticket with that art, so they are played together.
- Pause still works during the 3 seconds. The time's up screen (T-317) is the timer's loss; this is the health loss; a kaiju kill ends the run as before.
- The 3 seconds and any other numbers go in a data file in `game/data/` (proposals for the playtest). No text.

The board's review: lose all your hearts at speed: the car slides on, uncontrollable, then sits crashed, smoking and burning for 3 seconds before the recap.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Losing the last heart starts a 3-second wreck (±0.1 s, from a data file) and the run ends after it with the same result and signal as before; a kaiju kill and the time's up loss are unchanged (tests). (QA: pass)
- [ ] During the wreck no player input moves the car, the car keeps its velocity and slows with its normal physics, and handling while alive is unchanged (tests). (QA: pass)
- [ ] During the wreck the car takes no damage and collects no coins, likes, gift packs or tricks; pause freezes the wreck (tests). (QA: pass)
- [ ] Smoke and flames show on the car for the whole wreck (placeholders in code, drawn in the right place as the car moves). (QA: pass)
- [ ] Game loop architecture, HUD and menus and game/docs/game-loop/the-run.md describe it. (QA: pass)
- [ ] A screenshot and a GIF of the whole wreck after losing the last heart at speed are in `art-archive/<id>/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started (build B, End of a run): the Game Loop Agent is making the car slide on with dead controls and sit smoking and burning for 3 seconds when its last heart is gone, with placeholders, on top of the run stats (T-319).

### 2026-10-29, Needs playtest → In progress

Quick tuning: the enemies keep coming and swarm the wrecked car during the 3 seconds, with no damage or likes.

### 2026-10-29, Needs playtest → Done

Approved in build B. Done; the pixel art smoke and flames (T-361) start now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Game Loop Agent, 2026-10-29: built, ready for QA** (commit c7aff363 on `task/T-360-wrecked-the-stream-keeps-rolling`, on top of T-319).

What it does:
- `RunState` (`game/scripts/run/run_state.gd`): `damage_car()` taking the last heart now calls `_wreck()` instead of ending the run. It decides the loss at once (`result` "loss", `loss_reason` "health", the recap summary taken, `running` false, so the clock, coins, likes, tricks, gift packs, damage, healing, kills and a kaiju kill all stop counting), sends the new `wreck_started(seconds)`, and counts `wreck_left` down in `advance()` (from `_process`, pausable, so pause freezes it). At 0 it sends the same `run_ended(result, coins)` as before. `is_wrecked()`, `wreck_seconds` (from data; 0 ends at once, as before). A kaiju kill and the time's up still end the run at once with no wreck. `recap().loss_reason` is "health" (T-319's tests green).
- Data: `game/data/run.json`, new `wreck` section: `seconds` 3.0 (the board's number) and the placeholder smoke and flame numbers (proposals). `RunData.wreck_seconds()` and `RunData.wreck()` (`game/scripts/data/run_data.gd`).
- The car (`game/scripts/driving/car.gd`, Driving & Drift's): only `var input_enabled := true`; when false, `physics_step()` replaces W, S and steer with no input. Nothing else changed, so live handling is identical and every driving test stays green. A dead car coasts exactly like a car with no keys held (tested step by step).
- The run scene (`game/scripts/run/run.gd`): on `wreck_started` it sets `car.input_enabled = false` and starts the effect; the effect follows `car_sprite.position` after every car step; a new run stops it (and builds a new car with input on). The camera keeps following through the normal `sync_view`.
- Smoke and flames: `game/scripts/run/wreck_effect.gd` (child `WreckEffect` of the View, above the car sprite). Placeholders drawn in code with opaque 2 px squares: grey puffs (three greys, lit from the top left) that leave the car, stay where they were left, rise, grow and shrink, 12 a second; five flickering flame tongues on the car in red, orange, light orange and a white-hot core, 16 px high. No Greenbull colours (tested: every colour more than 40 RGB steps from each of Greenbull's three). **Swap seam for T-361:** set `smoke_frames` / `flame_frames` (SpriteFrames, animation "default"): a puff draws the frame for its age, the flames loop at the animation speed; the placeholder is used only while they are null.

Proposals for the playtest (the board's open questions; also in Game loop architecture, Content, "Wrecked", and HUD and menus, Content, "During the wreck"):
- **HUD stays on screen** as it was at the last heart (empty hearts, coins, sub goal, viewers counter), nothing new on it, no text.
- **The clock stops** at the last heart (= the recap's time survived).
- **Enemies, the kaiju, meteors, weapons, gift drops and pickups freeze** for the 3 s: they already stop when `is_running()` is false, so this needed no change in other agents' code. Letting the enemies swarm the wreck instead would need a small Enemy Behavior change; offered as an alternative after the playtest.
- **The car's slide:** no input at all (no throttle, brake or steering), normal coasting physics, walls still bounce it, jumps still land.
- The engine sound stops at the last heart (run_sounds already follows `is_running()`).

Tests changed because the loss on health now waits for the wreck (each now calls `state.advance(state.wreck_seconds)` after the last heart): `test_run_state.gd` (2), `test_run_hearts.gd` (2), `test_run_scene.gd` (1), `test_screen_flow.gd` (1), `level_creator/test_play_level.gd` (1), `test_run_sounds.gd` (1: the engine is silent from the next frame after the last heart, and after the run ends). New: `game/tests/unit/run/test_wreck.gd`, 17 tests (3 s from data and ended within 0.1 s, same result and coins, clock stopped, nothing counting, kaiju kill and time's up unchanged, pause freezing the wreck, a new run, 0 s, dead controls = coasting with no keys, live controls unchanged, the effect's puffs/flames/colours/follow, the art swap, the whole wreck in the run scene).

Test runs (foreground, all green):
- `python -m unittest discover -s game/tools -p "test_*.py"`: 657 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 573 tests, OK.
- `bash game/tools/run_tests.sh`: 150 scripts, 1844 tests, 1844 passing, 1245401 asserts, TESTS PASSED.

Screenshots: `art-archive/T-360/screenshots/wreck.png` (1.2 s into the wreck: the car on fire with its smoke trail, the HUD with empty hearts and the clock stopped) and `wreck.gif` (from 1.0 s to 5.0 s: drive into a drift, the last heart, the slide, 3 s smoking and burning, back to the main menu). Made by `bash game/tools/record_wreck.sh` with the fixture `game/tests/fixtures/wreck_demo.tscn`.

Weak spots, honestly: the placeholder smoke reads as stacked grey blobs and the flames as a small square bonfire; fine as a stand-in for T-361's art. The frozen minions look a little odd next to a sliding car; that is the cheapest proposal, and the enemies carrying on is the alternative.

**QA round 1, 2026-10-29: all 7 criteria pass.** qa_check: 3 test sets pass, 3 documents changed, 2 screenshots (wreck.png shows flames on the car and a smoke trail with the HUD kept; wreck.gif present). New tests in test_wreck.gd cover each behaviour criterion. Proposals (HUD, clock, enemies) left to the board's playtest.

Documents affected: `docs/game-loop-architecture.md` (flowchart, the run scene bullet, Content "Wrecked", Screen flow), `docs/hud-and-menus.md` (The HUD, "During the wreck"), `game/docs/game-loop/the-run.md` (hearts bullet, "Wrecked (T-360)"). No refusals.
- 2026-10-29, needs-playtest → in-progress: The board (2026-10-29, after playing build B): I don't want the monsters to stop moving when I die, when the car gets destroyed. I want them to keep coming and swarming the car. But with no like interaction or anything, they just come and swarm over the car.

**Quick tuning (board, 2026-10-29)**, the board's words: "I don't want the monsters to stop moving when I die, when the car gets destroyed. I want them to keep coming and swarming the car. But with no like interaction or anything, they just come and swarm over the car." Done (commit 774c395c):
- `game/scripts/enemies/minion_spawner.gd` (Enemy Behavior's code, changed on the board's request): `step()` carries on while `state.is_wrecked()`: it prunes, spawns and walks the minions to the car, but through `move_step(dt, false)`, which skips `contact_step()` (no damage, no knockback). `move_step()`'s new `contacts` argument defaults to true, so every other caller is unchanged.
- `game/scripts/enemies/kaiju_boss.gd`: during the wreck a kaiju already there walks to the car (new `_walk_to_car()`, the same walking as before, factored out) with no contact and no arrival.
- Everything else stays: the weapons don't fire, so nothing dies (no coins, likes or kills); meteors, gift drops and pickups stand still; once `run_ended` fires the enemies stand still as before.
- Tests: new `test_minions_swarm_the_wreck_without_touching_it` and `test_the_kaiju_swarms_the_wreck_without_touching_it` (they close in, no damage, no knockback; still after the run ends). The two "nothing moves after the run ends" tests that pinned the freeze now step past the wreck first.
- Docs: Game loop architecture, Content, "Wrecked" (the freeze proposal replaced by "The enemies swarm the wreck", with the board's words) and `game/docs/game-loop/the-run.md`, "Wrecked (T-360)".
- GIF and screenshot retaken (`art-archive/T-360/screenshots/wreck.gif`, `wreck.png`): the fixture now drops a ring of 10 minions round the car just before the last heart, so the swarm closing in on the burning wreck shows.
- Test runs (foreground, all green): game/tools 657 OK (1 skipped); tools 573 OK; GUT 150 scripts, 1846/1846 passing, 1245413 asserts. No refusals.

**QA final round, 2026-10-29 (after the swarm tweak): all 7 criteria pass.** qa_check: 3 test sets, 3 documents, 2 screenshots pass. The retaken wreck.png shows the minions closing in on the burning, smoking wreck with the HUD kept; criteria 1-3 hold with the swarm (tests: no damage, no knockback, no coins, likes or kills). Docs describe the swarm.
- 2026-10-29, needs-playtest → done: The board played build B after the swarm tweak and approved it (2026-10-29); its only change was to the recap screen.

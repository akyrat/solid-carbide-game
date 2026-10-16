---
id: T-144
title: Gift pack drop: a helicopter drops the gift pack, and driving over it opens the level-up screen (placeholders)
status: in-qa
from: project-lead
to: game-loop
lead: Level-up
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/weapons.md, docs/visual-style.md, game/README.md, tasks/T-052-level-up-screen.md, tasks/T-043-level-up-weapon-choices.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [the run and level-up flow scripts and scenes, new helicopter and package scenes with placeholder art, their GUT tests, docs/game-loop-architecture.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Game loop architecture, Decisions, "Gift pack drop", 2026-10-16): the level-up screen should no longer just appear. When the player levels up, a **helicopter sent by Redgull flies over the screen and drops a package** (the gift pack). **When the player drives over the package, the level-up screen opens** (the existing gift pack screen from T-052, with the same offers from T-043).

This task builds that flow with **placeholders**, so the board can play it before any art exists:

- On a level-up, the level-up screen does not open. The level-up effect (T-112) and the likes bar behave as they do now.
- A placeholder helicopter (a simple shape, not Redgull red: `docs/working-with-the-board.md`, "Placeholders never use Redgull red") flies across the screen and drops a placeholder package, which falls and lands on the map.
- The package stays on the ground as an object the car can drive over. When the car touches it, the package disappears and the level-up screen opens, pausing the run as it does now; the choice works as before.
- Build it so the art tasks (T-145 helicopter, T-146 package) can swap their sprites in without changing behaviour: one clearly named sprite node or texture path each, written in `game/README.md`.

Any number that tunes the flow (helicopter speed, drop height, fall time and so on) goes in the game's data files, not in code, so it can be tuned in playtests.

**The board's answers** (2026-10-16; also in Game loop architecture, Decisions, "Gift pack drop"):
1. The run keeps going (clock, enemies, likes, the drain) while the helicopter comes and the package waits on the ground. The run pauses only when the level-up screen opens, as it does now.
2. The package lands a short way ahead of the car, on open road (not inside a building or a boulder).
3. One package per level-up. Several level-ups before a pickup mean several packages; each one opens its own level-up screen when driven over.
4. The package stays on the ground until it is picked up.
5. When a landed package is off screen, an arrow at the screen edge points to it (placeholder look, not Redgull red; it sits clear of the other HUD parts).

**One playtest build:** the board plays the whole new level-up (this task, T-139, T-140, T-141, T-145, T-146) together in one build, not piece by piece. The art tasks T-145 and T-146 branch from this task's branch to swap their art in.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A GUT test shows that a level-up no longer opens the level-up screen by itself, and instead starts the helicopter, which crosses the screen and drops a package that lands on the map (QA: pass / fail)
- [ ] A GUT test shows that when the car overlaps the landed package, the package is removed and the level-up screen opens with the same offers as before (T-043), and the run pauses as it did (QA: pass / fail)
- [ ] GUT tests cover the board's five answers above (QA: pass / fail)
- [ ] The placeholder helicopter and package are not Redgull red, and the tuning numbers are read from a data file (a test checks both) (QA: pass / fail)
- [ ] `game/README.md` says which node or texture each art task replaces, and `docs/game-loop-architecture.md` describes the built flow (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run, level up, watch the helicopter drop the package, and drive over it to open the level-up screen.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-16, Open → In progress

Started: agent launched in C:\solid-carbide-worktrees$t. Part of the one level-up playtest build.

## Result notes

Written by the agent when it finishes.

**Game Loop Agent, 2026-10-16.**

What was built (full description: `game/README.md`, "The gift pack drop"; flow: `docs/game-loop-architecture.md`, Content, "The gift pack drop"):

- `game/scripts/run/gift_drops.gd` (`GiftDrops`, node `run.gift_drops`): listens to `RunState.level_up` (unchanged, so T-139's likes-bar animation and T-112's burst still fire at the level-up moment). Each level-up sends one helicopter across the screen (from beyond the left edge to beyond the right edge of the camera's view at that moment), carrying the package; over the landing spot it drops it, the package falls straight down and lands. Driving over a landed package (car centre within the pickup radius) removes it and calls the new `RunState.open_choice(level)`, which pauses the run and sends `level_up_choice_started`, so the existing T-052 screen opens with T-043's offers. Several packages each open their own screen; picked up together they queue. Packages stay until picked up; a new run clears them. Pausable: nothing moves while the pause or level-up screen is open; nothing after the run ends.
- `run.gd` now keeps `state.pause_on_level_up` off (a level-up no longer pauses by itself). The switch still works as before for tests (switch on = old direct flow, no helicopter).
- Landing spot: `land_ahead_units` ahead along the car's motion (its nose when still), checked with a new `mvp_map.gd` helper `is_open_spot(centre, radius)` (no building, boulder or map edge within `clearance_units`; `can_place_meteor_boulder()` now calls it, behaviour unchanged). If blocked it tries other angles and distances, nearest to straight ahead first.
- Off-screen arrow: `game/scripts/run/gift_arrows.gd` (`GiftArrows`, CanvasLayer 11, over the HUD, under the level-up screen): one pale cyan placeholder arrow per off-screen landed package, on a track 12 px inside the screen edge, pointing at the package, slid along the edge to stay 8 px clear of the timer, health column, coins row and the likes bar group.
- The helicopter flies `drop_height_px` above the landing spot but never above the screen's top edge (found in screenshots at the board's zoomed-in camera, where it would have been out of sight).

Tuning file and keys: `game/data/gift_pack.json` (read by `game/scripts/data/gift_pack_data.gd`, `GiftPackData`): `helicopter.speed_px_per_second` 520, `helicopter.drop_height_px` 90, `helicopter.offscreen_margin_px` 80, `package.fall_seconds` 0.7, `package.land_ahead_units` 8, `package.clearance_units` 1.0, `package.pickup_radius_units` 2.0. Proposals for the playtest.

Art swap (T-145, T-146): `game/scenes/run/gift_helicopter.tscn` and `game/scenes/run/gift_package.tscn` each have one `Sprite2D` named `Sprite`. T-145 replaces the texture of `GiftHelicopter/Sprite` (now `res://art/gift_pack/helicopter_placeholder.png`, 42x20, scale 1.5, facing right); T-146 replaces the texture of `GiftPackage/Sprite` (now `res://art/gift_pack/package_placeholder.png`, 16x16, offset (0, -8), bottom on the landing spot). Placeholders drawn by `game/tools/build_gift_placeholders.py` (no PixelLab, 0 generations): steel-blue helicopter, tan box with cyan ribbon, no red.

No new player-facing text.

Tests: new `game/tests/unit/run/test_gift_drops.gd` (30 tests: level-up sends the helicopter, not the screen; it crosses the screen, drops, the package lands; pickup removes it and opens the screen with the same offers, pausing the run, and a real drive onto it; the five answers; never above the screen top; placeholders not red; one named sprite each; numbers from the data file and from a test file). `test_level_up_screen.gd` and two screenshot fixtures now open the screen by picking up the package. New Python tests `game/tools/test_build_gift_placeholders.py`. Results (final run): full GUT suite 807/807 passed, `python -m unittest discover -s game/tools` 270 OK (1 skipped), `python -m unittest discover -s tools` 182 OK.

Screenshot fixtures: `res://tests/fixtures/gift_drop_demo.tscn` (helicopter crossing, package landing) and `res://tests/fixtures/gift_drop_arrow_demo.tscn` (off-screen arrow).

For the board: with nothing left to offer (both weapons at their last tier) a package still drops, and picking it up skips the choice at once (T-043's rule), so nothing visible happens. A landed package behind a building is covered by it (the building does not fade for packages).
- 2026-10-16, in-progress → in-qa: Gift pack drop built with placeholders: each level-up sends a helicopter across the screen that drops a package ahead of the car on open road; driving over it opens the level-up screen (run pauses then); off-screen arrow; numbers in game/data/gift_pack.json; art swap via GiftHelicopter/Sprite and GiftPackage/Sprite; GUT 807/807, Python tool tests OK

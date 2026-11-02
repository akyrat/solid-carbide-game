---
id: T-502
title: Driving power-up: the Polarized Steering Wheel
status: needs-playtest
from: project-lead
to: driving-drift
lead: Greenbull
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/data/power_ups.json, game/scripts/data/power_up_data.gd, game/scripts/weapons/bricks.gd]
files_expected_to_change: [game/data/power_ups.json, game/scripts/, game/art/power_ups/, game/tests/unit/, docs/drifting.md, game/docs/]
model: opus
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

The board, 2026-11-02 (docs/drifting.md, Decisions, "Rusty Paintjob and the Polarized Steering Wheel"): a fifth driving power-up, a mission gift like the others. When the player stops accelerating, steers, then accelerates again in a direction different from the one the car is moving in, the car gets a short speed burst. The condition is close to the cruise boost's (the motion lines when W brings the car up to cruise speed; Drifting, Decisions). Tiers 1 to 3 only make the burst bigger. Tier 4 makes it a little bigger again and also sets off an impact shock at the car: Bricks' normal wave (the tier 1 wave: radius 4, damage 6, minions pushed 4, the kaiju damaged and never pushed; reuse Bricks' code and its r4 wave sheet), whether or not the car owns Bricks.

Your proposals for the playtest (write them in power_ups.json with reasons, like the other power-ups): the angle between where the car faces and where it moves when W is pressed again (start at 60 degrees), how long the coast may last before it no longer counts, the burst per tier (about +20 / +30 / +40 / +45% speed for about half a second), and no cooldown between bursts. Show the burst with the cruise boost's motion lines or a stronger version of them. Its icon until T-503's art: a placeholder drawn by a script (a simple wheel), never PixelLab. Its texts come from T-501 (read its result notes for the keys). Add it to the power-up pool and the gift pack, the trick list or tutorial only if the other power-ups appear there. Update Drifting (Content, the power-ups) and game/docs/. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] power_ups.json has polarized_steering_wheel (or a similar id) with 4 tiers, each with its burst numbers and reasons, and tier 4 with the shock. (QA: pass; data test green, 4 tiers and shock_bricks_tier in power_ups.json)
- [ ] A unit test: letting go of W, steering, then pressing W again with the car facing at least the threshold angle away from its movement gives a burst; pressing W again with the car facing roughly where it moves gives none; holding W throughout gives none. (QA: pass; tests for burst, threshold, no burst facing forward, holding W)
- [ ] A unit test: the burst grows from tier 1 to 4 as in the data. (QA: pass; test_the_burst_grows_from_tier_1_to_4_as_in_the_data)
- [ ] A unit test: at tier 4 a burst sets off one wave (radius 4, damage 6) that damages minions in reach and pushes them, damages the kaiju without pushing it, with or without Bricks owned; below tier 4 no wave. (QA: pass; three wave tests, with and without Bricks, none below tier 4)
- [ ] The power-up appears in the mission gift offers like the others (unit test) and uses T-501's texts (no placeholder text). (QA: pass; gift-pool test in test_power_up_offers.gd; overlay shot shows real T-501 text)
- [ ] docs/drifting.md (Content) describes it with its numbers. (QA: pass; Content tier list and new section)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass; qa_check tests PASS, 2 sets)
- [ ] Screenshots of the burst and of the tier 4 shock, and of the power-up overlay showing it, under art-archive/T-NNN/screenshots/. (QA: pass; viewed burst, shock and tier 4 overlay shots, 8 files)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-501's texts.

### 2026-11-02, In progress → In QA

Polarized Steering Wheel built: burst +20/30/40/45% for 0.5 s after lift-steer-gas at 60 degrees or more, tier 4 Bricks tier 1 shock; tests and screenshots in.

### 2026-11-02, In QA → Needs playtest

QA passed all 8 criteria; ready for the board's playtest in the combined build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### T-502 result (Driving & Drift)

**What it does.** A fifth driving power-up, `polarized_steering_wheel`, a mission gift like the others. Let go of W, steer, press W again with the nose at least 60 degrees off the direction of travel: for 0.5 s the forward speed is held at least at the tier's multiplier x the speed carried into the press (cruise speed at the least). Tier 4 also sends Bricks' tier 1 wave at the car (radius 4, damage 6, minions pushed 4, the kaiju damaged and never pushed), with or without Bricks owned; owning Bricks even at its widest-wave tier does not change it.

**Proposals for the playtest (power_ups.json, with reasons):**
- burst x1.2 / 1.3 / 1.4 / 1.45 (+20 / +30 / +40 / +45%), 0.5 s on every tier; tier 4 `shock_bricks_tier: 1`.
- angle at least 60 degrees (every tier); the coast may last at most 1.2 s (enough for a 180-degree swing at the turn rate); the car must move at least 2 units/s; on the ground only; no cooldown.
- Mine, not in the data: S held during the coast cancels it (so reversing then W is no burst); a wall hit ends a running burst and the wreck drops it (as Rev Charge does); the burst's size comes from the speed carried in. Measured: after a lift from near top speed and a 75-degree steer the car carries about 12.4 units/s, so the bursts are about 14.8 / 16.1 / 17.3 / 17.9 units/s forward (top speed 16.5).
- The shock gets the garage damage bonus, like every weapon's wave; its hits are credited to "polarized_steering_wheel", not Bricks, so the recap's Bricks kills stay Bricks' own.
- The look: the cruise boost's motion lines, three sets side by side across the car, looping for the half second (the art is not scaled).

**Files.**
- New: game/scripts/driving/polarized_steering_wheel.gd (the rule, `car.polarized`), game/scripts/driving/polarized_shock.gd (the run's "PolarizedShock": its own bricks.gd node bound to the rack, never on the rack's list; calls Bricks' send_wave with weapons.json bricks tier 1), game/art/power_ups/polarized_steering_wheel.png (script-drawn placeholder steering wheel; no PixelLab) from game/tools/draw_power_up_icon_polarized_steering_wheel.py, its test game/tools/test_draw_power_up_icon_polarized_steering_wheel.py, game/tests/unit/test_polarized_steering_wheel.gd, fixtures game/tests/fixtures/t502_polarized_demo.gd, t502_polarized_burst.tscn, t502_polarized_shock.tscn, t502_overlay_tier1_shot.tscn, t502_overlay_tier4_shot.tscn.
- Changed: game/data/power_ups.json (the fifth entry), game/scripts/data/power_up_data.gd (IDS), game/scripts/driving/car.gd (wiring, wall hit, wreck), game/scripts/run/run.gd (tier on new car and power_ups_changed, the shock node), game/scripts/driving/boost_effect.gd (play_strong), game/scripts/ui/power_up_screen.gd (describe(): `{burst_percent}` and the tier 4 line from `descriptions_tier4`), game/scripts/menu/tutorial_slides.gd (the fifth icon on the missions slide, since the other four are there; each icon now keeps its 96 px square under a wide name, Bouncy Bumpers' was stretched before).
- Tests changed for five power-ups: tests/unit/run/test_power_up_offers.gd (+ a gift-pool test), tests/unit/test_power_up_screen.gd (+ the card text test), tests/unit/test_tutorial_slides.gd.
- The id comes from data (PowerUpData.ids()), so T-505's God mode picks it up.

**Texts:** T-501's keys, no placeholder: names.polarized_steering_wheel, descriptions.polarized_steering_wheel (tiers 1 to 3) and descriptions_tier4.polarized_steering_wheel (tier 4). The overlay shots show "+45% speed, a shock..." at tier 4.

**Tests run (each with -gselect):** test_polarized_steering_wheel.gd 12/12 (106 asserts), test_power_up_offers.gd 12/12, test_power_up_screen.gd 22/22, test_tutorial_slides.gd 26/26, test_rev_charge.gd 17/17, test_boost.gd 8/8, test_boost_art.gd 6/6, test_mission_data.gd 5/5, test_missions.gd 16/16, test_bricks.gd 25/25, test_bouncy_bumpers.gd 3/3, test_jump_power_up.gd 12/12, test_missions_power_ups_run.gd 4/4, test_car_collisions.gd 19/19, test_mission_texts.gd 4/4, test_drift_prototype.gd 15/15. Python: test_draw_power_up_icon_polarized_steering_wheel 5/5.

**Screenshots (art-archive/T-502/screenshots/):** burst_tier1.png and burst_tier1_zoom.png (the stronger motion lines), shock_tier4.png and shock_tier4_zoom.png (the r4 wave hitting and shoving a ring of minions), overlay_tier1.png and overlay_tier4.png (the card at tiers 1 and 4), tutorial_power_ups.png (the missions slide with five icons), icon_placeholder_preview.png (the placeholder icon at 8x, dark and light).

**Honest notes for the playtest:** the stronger lines are clearly denser than the cruise boost's but still modest; T-503 or an effect ticket may want a real burst effect. The burst also triggers the normal cruise boost lines on the same press (W below cruise speed snaps up), which is fine but means two effects overlap.

**Documents affected:** docs/drifting.md (Content: the tier list and a new section "The Polarized Steering Wheel (task T-502)"), game/docs/driving/drift.md ("Polarized Steering Wheel (T-502)"). Not mine, for the Project Lead: docs/hud-and-menus.md still lists four power-ups (T-501 noted it). No SFX, nothing in game/data/levels/.

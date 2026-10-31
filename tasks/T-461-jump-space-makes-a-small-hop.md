---
id: T-461
title: Jump: Space makes a small hop on the car's real height, and its airtime counts for missions
status: in-qa
from: project-lead
to: driving-drift
lead: Goal-G-009
epic: driving
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-455, T-457]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/tricks.md, game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/scripts/driving/trick_detector.gd, game/scripts/run/run_state.gd, game/scripts/run/missions.gd, game/data/power_ups.json]
files_expected_to_change: [game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/tests/unit/test_jump_power_up.gd, game/tests/fixtures/jump_power_up_demo.gd, game/tests/fixtures/jump_power_up_demo.tscn, game/docs/driving/tricks.md, docs/drifting.md]
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

Drifting, Decisions, 'Driving power-ups': Jump. With it owned, Space makes a small hop, using the car's existing height system (takeoff speed, gravity, landing, passing over obstacles at height, the airtime and air-spin tricks) with the tier's numbers from power_ups.json. Without it, Space keeps whatever it does today. Proposals to document in Drifting, Content: whether it works only on the ground (no double jump), any cooldown. Airtime from a hop counts for the airtime, AIR 180 and AIR 360 goals (board, 2026-10-31), through the existing trick events.

Screenshots or a short GIF of a hop.

The board's review: play a run with Jump at each tier: the hop's height and feel, and spinning in it.

## Acceptance criteria

- [ ] With Jump owned, Space on the ground lifts the car through the existing height path and it lands; the hop's peak height or airtime matches each tier's numbers (GUT tests per tier). (QA: pass / fail)
- [ ] Without the power-up, Space changes nothing in the car's height or speed (GUT test). (QA: pass / fail)
- [ ] A simulated hop with an air spin advances the tracker's airtime and AIR 180 goals (GUT test using the mission tracker). (QA: pass / fail)
- [ ] Screenshots or a GIF of a hop are in art-archive/<id>/screenshots/; Drifting, Content, describes the hop and its proposals. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-461.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Driving & Drift Agent, 2026-10-31. Done; ready for QA.

**What was built**
- `game/scripts/driving/jump_power_up.gd` (new, the car's `jump`): with Jump owned, a Space press on the ground calls the height model's new `CarHeight.hop(takeoff_speed)` with the tier's `takeoff_speed` from `power_ups.json`; the tier's `cooldown_seconds` then runs. At tier 0 it returns at once (nothing changes).
- `game/scripts/driving/car_height.gd`: `hop(vz)` (ground only; emits the existing `took_off(false, vz)` and a new `hopped(vz)`), so everything after is the existing air path: gravity 12, landing, sides met at height, obstacles passed at height (run.gd's `update_car_obstacles(car, car.height)`), the airtime / AIR 180 / AIR 360 tricks. With no ground source (`ground == null`) an airborne car now falls to flat ground at 0 instead of being snapped to 0, so the hop also works without elevation (before, nothing could be airborne there).
- `game/scripts/driving/car.gd`: input action `car_jump` (Space, added to `game/project.godot`), taken as an event in `_unhandled_input` so the Space that takes a card on a paused overlay never hops; `press_jump()` for scripted driving. The jump step runs at the start of `physics_step()`, before the model's update, so the hop's first step is already in the air.
- `game/scripts/run/run.gd` (not in files_expected_to_change; one line): `_apply_rev_charge_tier()` also sets `car.jump`'s tier from `RunState.power_up_tier("jump")`, on run start and on `power_ups_changed`.

**Hop numbers (flat ground, tiers 1 to 4):** peak 1.04 / 1.50 / 2.04 / 2.67 units, airtime 0.83 / 1.00 / 1.17 / 1.33 s.

**Proposals (documented in Drifting, Content, "Jump (task T-461)")**: ground only, no double jump (a press in the air is dropped, not buffered); the cooldown counts from the takeoff, in the air too, and a press on cooldown is dropped; one hop per press; hops from any ground (street, rooftop, ramp), straight up.

**Finding for Game Data / the board (numbers unchanged):** at the base air turn rate (1.25 x 191.9 = 240 deg/s) tier 1 already fits an air 180 (~200 deg), and tier 4 (~320 deg) does not quite fit an air 360 without the garage air turn upgrade, unlike the tier reasons in power_ups.json say. Also tier 1's reason says "about 0.6 s"; it is 0.83 s with gravity 12.

**Tests** (`game/tests/unit/test_jump_power_up.gd`, 12 tests): tier numbers from the JSON; per tier, airtime steps and peak match 2v/g and v^2/2g and the car lands back at 0; higher tiers hop higher and longer; the height path's signals (took_off, hopped, landed); hop with no ground source; without the power-up, Space changes nothing in height, speed or position (two cars compared step by step), also with no ground; no double jump and the cooldown; one hop per press; flat speed kept; the run gives the car the owned tier; a tier 3 hop steering A advances a RunMissions tracker's airtime goal by the hop's seconds and its AIR 180 goal by 1, through the car's `trick` and `airtime_trick` signals.

**Test sets (all pass):**
- GUT `bash game/tools/run_tests.sh`: 198 scripts, 2407/2407 tests passed (1037 s).
- `python -m unittest discover -s game/tools -p "test_*.py"`: 767 tests OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 614 tests OK.

**Screenshots** (`art-archive/T-461/screenshots/`, a run with Jump at tier 4, W held, one hop at step 40 with A held in the air): `jump_tier4_1_before.png`, `jump_tier4_2_peak.png` (car lifted over its shadow, airtime counter 0.68), `jump_tier4_peak_zoom.png` (x3), `jump_tier4_3_spinning_down.png` (turned, airtime 1.16), `jump_tier4_after_landing.png`, and the GIF `jump_tier4_hop_spin.gif`. Fixtures: `game/tests/fixtures/jump_power_up_demo.tscn` and `jump_power_up_gif.tscn` (how to record: `game/docs/driving/tricks.md`, "Jump (T-461)").

**Documents affected:** `docs/drifting.md` (Content, "Jump (task T-461)"); also `game/docs/driving/tricks.md` ("Jump (T-461)").

**PixelLab:** 0 generations. No art or player-facing text (no style loop needed).

**Refusals:** one, not essential: `ls` of Godot's user data folder (outside the worktree) was refused; I recorded the GIF frames to the git-ignored `screenshots/` folder at the repo root instead.

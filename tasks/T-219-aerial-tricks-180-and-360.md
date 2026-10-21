---
id: T-219
title: "Aerial tricks: a 180 and a 360 turned in the air"
status: in-qa
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-218]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md, game/scripts/driving/trick_detector.gd, game/scripts/data/combo_data.gd, game/scripts/hud/trick_popups.gd, tasks/T-218-text-aerial-trick-popups.md]
files_expected_to_change: [game/scripts/driving/trick_detector.gd, game/data/, game/scripts/hud/, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-219/screenshots/]
model: opus
qa_rounds: 3
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

The board's first aerial tricks (Drifting, Decisions, "Aerial tricks", 2026-10-21): while the car is airborne (off a ramp or a rooftop's edge, on the elevation map that the run now plays on), turning its heading **180 degrees** during one airtime is the 180 trick, and turning it a **full 360** is the 360 trick. Direction doesn't matter: a left and a right turn are the same trick.

Detect them in `trick_detector.gd` from the car's heading and its airborne state (`car_height.gd`), alongside the existing ground tricks, and feed them into the existing combo (how tricks raise it: Game loop architecture, Decisions; the numbers live in the combo data) and the existing trick popups, with T-218's texts word for word (HUD and menus, Content). Proposals for the playtest, written in the result notes and in Drifting, Content: what each is worth, whether a 360 also counts its 180 or only the 360, what a 540 or 720 gives, whether the turn must be finished before landing, and how an air turn interacts with a drift 360 that spans the jump. Don't change how the car drives or turns in the air.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots and a short GIF of each trick in a run (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show a 180 turn during one airtime gives the 180 trick, and a full turn the 360 trick, the same for left and right turns; a smaller turn, or the same turn on the ground, gives neither (QA: pass; test_air_tricks.gd covers 180/360 both ways, smaller and ground turns; GUT 1244/1244)
- [ ] Each aerial trick raises the combo through the existing combo data and shows its popup with T-218's text word for word (tests, and a screenshot of each popup in a run) (QA: pass; texts match T-218, popup PNGs exist incl. air_360_run_straight_popup.png; GIF frame shows AIR 360! +0.5 alone, no drift lines)
- [ ] A GIF of each trick in a run on the elevation map is in `art-archive/T-219/screenshots/` (QA: pass; air_180_run.gif and air_360_run_straight.gif are in art-archive/T-219/screenshots/; frames checked: car spins above its shadow while the street scrolls straight, lands to AIR 360!)
- [ ] The car's driving and air steering are unchanged (existing driving tests pass unchanged); the proposals are in the result notes and Drifting, Content (QA: pass; ground driving tests unchanged; the 3 edited height tests keep their purpose (compare only on the ground, launch at cruise speed); air changes are only faster spin, pay once, no air drifting)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT 1244/1244, tools 439 OK, game/tools 388 OK (1 skipped))

The board's review: play a run and do both aerial tricks off the rooftops and ramps.
Board review files: the GIFs in `art-archive/T-219/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started: the air 180 and air 360, with AIR 180! and AIR 360!.

### 2026-10-21, In progress → In QA

Built: AIR 180! and AIR 360! with combo values. The air 180 works off a height-6 rooftop; the air 360 can't be reached on today's map (the longest airtime is 1.0 s, a 360 needs 1.9 s). Sent to QA.

### 2026-10-21, In QA → Needs playtest

QA passed all 5.

### 2026-10-21, Needs playtest → In progress

Back to the agent: faster turning in the air, so AIR 360! can be done off the tallest rooftop.

### 2026-10-21, In progress → In QA

Faster air turning in (2.5x, a tuning value): AIR 360! works off a height-6 rooftop with about 0.2 s of margin. Final QA round.

### 2026-10-21, In QA → Needs playtest

QA round 2 passed all 5.

### 2026-10-21, Needs playtest → In progress

Back to the agent: each spin pays once.

### 2026-10-21, In progress → In QA

Each spin pays once is in: an air spin pays only AIR 360!. Final QA check.

### 2026-10-21, In QA → Needs playtest

Final QA passed all 5. Ready for the board: C:\solid-carbide-worktrees\T-219\game\project.godot or Play on T-219 in the Builds tab; spin off a height-6 rooftop.

### 2026-10-21, Needs playtest → In progress

Back to the agent: no drifting in the air; the car keeps its takeoff path and only spins.

### 2026-10-21, In progress → In QA

No drifting in the air is in: the car keeps its takeoff path and only spins. Final QA check.

## Result notes

Driving & Drift Agent, 2026-10-21.

**Built.** `trick_detector.gd` has two new tricks, `air_one_eighty` and `air_three_sixty` (in `TRICK_IDS`, plus `AIR_TRICK_IDS`), found by a new `observe_air(airborne, turned)`. `car.gd` calls it once per physics step after its height step, with `height_model.airborne` and the heading's change on that step. It only reads; the driving and the air steering are unchanged. `combo.json` has `trick_add.air_one_eighty` 0.25 and `.air_three_sixty` 0.5, so the run's existing `add_trick` raises the combo through `ComboData`. `trick_popups.gd` shows T-218's texts word for word, AIR 180! and AIR 360!, at the normal size with "+{amount}". `make_turn_gif.py` has `--glob` and `--every` so it can build GIFs from Godot movie-maker frames.

**Proposals for the playtest** (also in Drifting, Content, "Aerial tricks"):
- Worth: air 180 is +0.25 (the same as a drift 360). Air 360 is +0.5 (the same as an alternate drift).
- A 360 counts only the 360, not its 180 as well. The airtime's best turn is paid in half turns: 540 gives an air 360 and an air 180, and 720 gives two air 360s.
- The turn must be finished before landing. Only heading turned on steps that end in the air counts, and the tricks are paid out on the landing step.
- Either direction counts. Turning back starts a new count, the airtime keeps its largest turn, and letting go of the steering keeps the count.
- A drift 360 that spans a jump and the air turn count independently. The drift 360 still counts through the air as before, so one spin can give FULL 360! and AIR 180!.

**Honest limit: the air 360 can't be done on today's map.** The car turns 191.9 degrees a second. The longest airtime is a fall from a height-6 rooftop: 50 steps, 1.0 s, 191.9 degrees at most. A 360 needs 94 steps (1.9 s), a fall of about 21 units. The air 180 is just possible: the player must steer for the whole fall, and starting 4 steps (0.08 s) late misses it. Ramp hops (about 0.7 s) are too short. Making the 360 reachable is the board's decision (taller rooftops or ramps, lower gravity, or a faster turn in the air); I didn't change any of them.

**Recordings** (`art-archive/T-219/screenshots/`):
- `air_180_run.gif`: a real run on the elevation map. The car drives off a height-6 rooftop's side with W and turns with A in the air (50 steps, about 188 degrees). Its round shadow is on the street, it lands facing the other way, and AIR 180! +0.25 pops with LONG DRIFT! +0.05 under it (the drift keys were held in the air). The car is sometimes close to the top edge of the crop but always in frame.
- `air_360_staged_drop.gif`: staged, because no real jump is long enough. In a run, the car is let go 22 units above the gravel square and the camera is zoomed out to 30 so it stays in frame. The car is small, but it visibly turns a full circle (95 steps, 364.6 degrees), lands, and AIR 360! +0.5 shows with Combo x1.5.
- Popups: `air_180_popup.png` (the run, AIR 180! +0.25, Combo x1.3) and `air_360_popup.png` (the staged drop at the run's own zoom, AIR 360! +0.5, Combo x1.5).

**Tests.** There is a new `game/tests/unit/test_air_tricks.gd` with 21 tests. They cover the detector (180 and 360 both ways, smaller turns, the same turns on the ground, 540 and 720, two airtimes, turning back, reset). They also cover the real car falling and driving off a height-6 rooftop on the map's ground, detection off, and the run's combo and popups with the exact texts. In `test_tricks.gd`, only `test_ids` changed, to list the two new ids. Every driving test passes unchanged. Results: the GUT suite passes 1233/1233, `tools` 414 OK, `game/tools` 388 OK (1 skipped). `test_make_turn_gif.py` has a new test for `--glob`/`--every`.

**Refused by a hook (skipped, not retried):**
1. A Bash command that set a shell variable to the scratchpad path, to count GIF frames. The guard couldn't tell it wouldn't write a ticket. I ran the read on its own afterwards.
2. A `python -` heredoc that edited `docs/drifting.md` and `game/README.md`, refused because its text contained `**`. I then made those two doc edits with the Edit tool. They don't touch any ticket.

Documents affected: `docs/drifting.md` (Content, "Aerial tricks (task T-219)"), `game/README.md` ("Tricks").
- 2026-10-21, needs-playtest → in-progress: Board (2026-10-21): faster turning in the air, so an air 360 fits in a jump off the tallest rooftop

**Tweak, 2026-10-21 (Driving & Drift Agent): faster turning in the air.** The task first said not to change how the car turns in the air. The board has now asked for exactly that (Drifting, Decisions, "Aerial tricks"), so this tweak changes air steering on purpose. Ground steering is unchanged.
- **Built:**
  - `car_tuning.gd` has a new tuning value, `air_turn_multiplier`. It is a tuning value like the other handling settings, not a constant in the driving code, and it has its own `AIR_SETTINGS` group and an "In the air" slider in the drift prototype's tuning panel, from 1 to 4.
  - `turn_rate_for(airborne)` is the ground rate (191.9 deg/s) times the multiplier while airborne.
  - `car.gd` sets `model.airborne` from the height model before each step, and `car_model.gd` turns at that rate.
- **Proposed value: 2.5**, which is 479.75 deg/s, 9.6 degrees per physics step.
  - A fall off a height-6 rooftop counts 49 steps in the air.
  - A 360 needs 38 steps (0.76 s), which leaves about 0.2 s of margin: starting the turn 10 steps late still gives AIR 360!, while 12 steps late gives only AIR 180!.
  - A 180 needs 19 steps (0.38 s), half the 360, and also fits a ramp hop (about 0.7 s).
  - The most a rooftop fall can turn is about 470 degrees, so there is no 540 on today's map.
  - 2.4 was tried first and left only about 9 steps (0.18 s) of margin.
- **For the playtest:** with W held, the air turn is also a drift. The faster turn then completes FULL 360! mid-air as well, so a whole-fall air 360 with W held usually pays FULL 360! +0.25 and AIR 360! +0.5, as the independent-counting proposal says. If that pays too much, the board can decide that air steps don't count for the drift 360.
- **Tests:**
  - `test_air_tricks.gd` now has 24 tests. They cover: the ground rate unchanged (191.9) and the multiplier in the tuning defaults; the real car turning one ground step on the ground and 2.5 times that in the air; a real 6-unit fall steering throughout giving AIR 360! both ways; the 0.2 s margin (10 steps late is a 360, 12 late a 180); 19 steps giving the 180 and 18 giving nothing; and driving off a height-6 rooftop and turning, and the run's combo, now giving AIR 360!.
  - `test_car_height.gd`, `test_flat_driving_unchanged_by_height`: this test compares a car with height and one without, step by step, and the car with height went through the air. It now sets the multiplier to 1 on both cars, so it still checks that height alone changes nothing. That is the only change to an existing driving test.
  - Results: GUT suite 1236/1236, `tools` 439 OK, `game/tools` 388 OK (1 skipped).
- **Recordings:**
  - New `art-archive/T-219/screenshots/air_360_run.gif`: a real run on the elevation map. The car drives off a height-6 rooftop's side with W and turns with A for the whole fall (50 steps, about 470 degrees), its round shadow on the street. FULL 360! +0.25 pops mid-air, then it lands to AIR 360! +0.5 with LONG DRIFT! +0.05, Combo x1.8.
  - Popup: `air_360_run_popup.png`.
  - Fixtures: `air_trick_gif_360_run.tscn` is new. `air_trick_gif_180.tscn` now steers for only 22 air steps (`steer_steps`), so it still makes a 180. The staged fixtures now steer for 40 steps.
  - The old GIFs and popups are kept and were not re-recorded. `air_180_run.gif` shows the old ground-rate turn.
- **Refused:** a `sleep 240; cat ...` command to wait for a background test run (the harness blocks sleeps). I skipped it and waited for the run's notification instead.
- Documents affected: `docs/drifting.md` (Content, "Aerial tricks (task T-219)"), `game/README.md` ("Tricks").
- 2026-10-21, needs-playtest → in-progress: Board (2026-10-21): each spin pays once; turning in the air no longer counts towards the drift 360

**Tweak 2, 2026-10-21 (Driving & Drift Agent): each spin pays once.**
- **Built:** `car.gd` now calls `tricks.observe(...)` after the height step, not before it, and passes `height_model.airborne`. The detector still only reads the car. In `trick_detector.gd`, the drift 360 doesn't add the heading change of a step that ends in the air. Those are exactly the steps the aerial tricks count, so no step's turn counts for both. The extended and alternate drifts are unchanged.
- **A drift 360 already in progress at takeoff:**
  - It is kept as it is through the airtime: it neither grows nor resets, as long as the drift keys stay held (W, or S, with A or D; holding them in the air is still a drift).
  - From the landing step on, it carries on counting from where it was. For example, 50 ground steps, any airtime, then 44 ground steps make one FULL 360!.
  - Letting go of the drift keys in the air is a break, as on the ground, and starts it from zero.
  - The takeoff step itself ends in the air, so its turn goes to the air trick. The landing step ends on the ground, so its turn goes to the drift 360.
- **Tests:** `test_air_tricks.gd` now has 28 tests.
  - The drive off a height-6 rooftop with W+A gives AIR 360! and no FULL 360!.
  - The detector: 200 drift steps that end in the air give no FULL 360! but still give the extended drift.
  - The in-progress case: 50 ground + 30 air + 43 ground steps give nothing, and the 94th ground step gives FULL 360!.
  - The real car: a ground drift 360 still fires after 94 ground steps.
  - The real car: a staged 6-unit fall with W+A held pays only AIR 360!.
  - `test_tricks.gd` (the ground drift 360 and the other ground tricks) passes unchanged.
  - Results: GUT suite 1240/1240, `tools` 439 OK, `game/tools` 388 OK (1 skipped).
- **Recording:** new `art-archive/T-219/screenshots/air_360_run_pays_once.gif`, with its popup `air_360_run_pays_once_popup.png`; the older `air_360_run.gif` is kept. I looked at the frames. It is a real run on the elevation map: the car drives off a height-6 rooftop with W and turns with A for the whole fall (about 470 degrees). Nothing pops mid-air. It lands to AIR 360! +0.5 with LONG DRIFT! +0.05 under it, at Combo x1.55, and there is no FULL 360!. The LONG DRIFT! comes from the drift's seconds, which still count in the air.
- Documents affected: `docs/drifting.md` (Content, "Aerial tricks (task T-219)": the drift 360 bullet, and the recordings), `game/README.md` ("Tricks", "360").
- 2026-10-21, needs-playtest → in-progress: Board's playtest (2026-10-21): no drifting mid-air. Once airborne the car keeps its takeoff speed and direction; the keys only spin it (heading), they don't change its path. Otherwise happy with it.

**Tweak 3, 2026-10-21 (Driving & Drift Agent): no drifting in the air.**
- **Built:** in `car_model.gd`, `update_velocity()` returns early while `airborne` is set (it is set by `car.gd` from the height model before each step).
  - The velocity is left exactly as it was at takeoff: no speeding up, braking, steering of the path, grip or drift.
  - The keys only spin the body at the air turn rate (`air_turn_multiplier` 2.5, kept). A and D spin it; W and S alone do nothing.
  - `is_drifting` is false in the air and the drift amount fades at the exit rate.
  - The takeoff step is still a ground step. Wall bounces and enemy knockback still act in the air, as they are applied outside the driving model. Ground driving is unchanged.
- **Knock-on effects:** the car isn't drifting in the air, so the following are off in the air:
  - LONG DRIFT! (airtime is no drift time, as the line on master says)
  - drift likes
  - the drift sound
  - smoke and tyre marks (already off)
  - the exhaust flamethrower, which fires while drifting
  - A takeoff is now a break in the drift, so a drift 360 in progress starts again from zero after landing. This replaces tweak 2's "kept through the airtime".
- **Landing:** driving resumes on the step after the landing, from the heading the car landed with and the velocity it kept.
  - Landing straight on, it drives on.
  - Landing at an angle, the speed along the new nose becomes forward speed and the rest is a sideways slide that fades with normal grip (0.98 kept per step, about a third left after 1 s). In effect it lands into a drift-like slide.
  - With W held, a forward speed under cruise snaps up to cruise along the new nose.
  - Landing backwards with W held, it snaps to cruise forward along the new nose, a sudden turnaround.
  - A or D held with W or S on landing is a normal drift from that step.
- **Tests:**
  - `test_air_tricks.gd` now has 32 tests:
    - the velocity in the air stays the takeoff velocity with eight key combinations held, and the car is never drifting;
    - the heading spins at the air rate while the car flies straight on;
    - landing at 90 degrees keeps the velocity, then the slide fades;
    - no LONG DRIFT! or FULL 360! in a long fall with W+A;
    - a drift 360 in progress restarts after an airtime;
    - AIR 360! off a height-6 rooftop, both driven off and as a staged drop.
  - Existing tests changed:
    - `test_car_height.gd`, `test_flat_driving_unchanged_by_height`: it now compares the cars only until the car with height first leaves the ground.
    - `test_car_height_layers.gd` (the sample-map obstacle test, air case) and `test_elevation_edges.gd` (`test_no_step_ends_inside_the_platform_below_its_top`): they put a standing car in the air with W held and relied on W pushing it in the air. They now launch it at cruise speed along its heading.
  - The ground driving tests (`test_drift_model.gd`, `test_tricks.gd` and others) pass unchanged.
  - Results: GUT suite 1244/1244, `tools` 439 OK, `game/tools` 388 OK (1 skipped).
- **Recording:** new `art-archive/T-219/screenshots/air_360_run_straight.gif`, with its popup `air_360_run_straight_popup.png`; the older GIFs are kept. I looked at the frames. It is a real run on the elevation map: the car drives off a height-6 rooftop with W, then holds W and A for the whole fall. The camera follows the car, so the straight path shows as the street and boulders scrolling steadily one way while the car spins (about 470 degrees) over its shadow. It lands to AIR 360! +0.5 alone, at Combo x1.5, with no LONG DRIFT! and no FULL 360!.
- Documents affected: `docs/drifting.md` (Content: "What the car's height does", and "Aerial tricks (task T-219)" with its new "No drifting in the air" bullet, the drift 360 bullet and the recordings), `game/README.md` ("Tricks").

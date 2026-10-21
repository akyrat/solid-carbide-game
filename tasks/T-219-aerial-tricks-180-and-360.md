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
qa_rounds: 0
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

- [ ] Tests show a 180 turn during one airtime gives the 180 trick, and a full turn the 360 trick, the same for left and right turns; a smaller turn, or the same turn on the ground, gives neither (QA: pass; test_air_tricks.gd covers 180/360 both ways, smaller turns, ground turns, and GUT passes)
- [ ] Each aerial trick raises the combo through the existing combo data and shows its popup with T-218's text word for word (tests, and a screenshot of each popup in a run) (QA: pass; combo.json trick_add values and trick_popups.gd texts match T-218, tests pass, both popup PNGs show the texts; the 360 popup is from the staged drop)
- [ ] A GIF of each trick in a run on the elevation map is in `art-archive/T-219/screenshots/` (QA: pass; air_180_run.gif is a real run off a rooftop and shows the car in the air with its shadow; air_360_staged_drop.gif is staged, a 22-unit drop in a run, because no real jump is long enough, and says so honestly, the car is small but turns a full circle)
- [ ] The car's driving and air steering are unchanged (existing driving tests pass unchanged); the proposals are in the result notes and Drifting, Content (QA: pass; car.gd diff only adds a read-only observe_air call, no steering change, only test_ids changed in test_tricks.gd, proposals are in the result notes and docs/drifting.md)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT all passed, tools 414 OK, game/tools 388 OK (1 skipped))

The board's review: play a run and do both aerial tricks off the rooftops and ramps.
Board review files: the GIFs in `art-archive/T-219/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started: the air 180 and air 360, with AIR 180! and AIR 360!.

### 2026-10-21, In progress → In QA

Built: AIR 180! and AIR 360! with combo values. The air 180 works off a height-6 rooftop; the air 360 can't be reached on today's map (the longest airtime is 1.0 s, a 360 needs 1.9 s). Sent to QA.

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

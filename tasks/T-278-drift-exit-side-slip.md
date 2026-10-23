---
id: T-278
title: A little side slip out of a drift, to steady with counter-steer
status: in-progress
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/README.md, game/scripts/driving/, game/scenes/drift_prototype/]
files_expected_to_change: [game/scripts/driving/, game/scenes/drift_prototype/, game/tests/, docs/drifting.md, game/README.md, art-archive/T-278/screenshots/]
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

The board's decision (Drifting, Decisions, "A little side slip out of a drift", 2026-10-22), which the board calls insanely crucial to the game's feel and will playtest on its own: when a drift ends (the drift keys are released, or the drift breaks), the car keeps a **small** amount of its sideways slide for a short moment instead of snapping straight to its heading, so the player steadies it with a touch of counter-steer, as in Hotshot Racing and Mario Kart. Catching it well should feel satisfying; doing nothing should still settle on its own after a moment, never spin the car out. It is a tiny effect.

- Build it as tuning values in `game/scripts/driving/car_tuning.gd` (for example how much of the drift's sideways speed carries over, how fast it decays, and how much counter-steer cancels it; your design), each with a slider in the drift prototype's tuning panel so the board can feel and set them live. Propose small defaults and say why.
- It applies on the ground only (in the air the car keeps its takeoff path, Drifting, "No drifting in the air"). The drift itself, its tricks and payouts, and everything else about handling stay as they are. Find out first how the drift ends today in the driving model, and describe it and the change in the result notes in plain words.
- Built from `master` on its own, so the board plays it separately from every other change. The board may tune it with you directly in its playtest ("Quick tuning with an agent", `docs/working-with-the-board.md`).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a short GIF of drifts ending, with the slip caught by counter-steer and left alone, in the drift prototype and in a run.

## Acceptance criteria

- [ ] Tests show that after a drift ends the car keeps a small sideways speed that decays to none within the proposed time, that counter-steer cancels it faster, that it never turns into a spin-out with no input, and that it doesn't apply in the air (QA: pass / fail)
- [ ] The values are in `car_tuning.gd` with sliders in the drift prototype's tuning panel; drift tricks, payouts and the rest of the handling are unchanged (the existing driving tests pass unchanged) (QA: pass / fail)
- [ ] Drifting, Content, and `game/README.md` describe it in plain words with the defaults and reasons; the GIF is in `art-archive/T-278/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: drift in the prototype and in a run, steady the car out of each drift, and tune the sliders.
Board review files: the GIF in `art-archive/T-278/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: a little side slip out of a drift, to steady with counter-steer. Played on its own.

## Result notes

Written by the agent when it finishes.

**Driving & Drift Agent, 2026-10-23** (resumed after a usage-limit cut-off; nothing was lost, the work was uncommitted in this folder).

**How a drift ended before.** The car already slides a lot when a drift ends. Its sideways grip is the Unity value everywhere, 0.98 kept per step, drifting or not (the drift amount only drives the smoke and marks). So a held W + A drift leaves the car about 65 degrees sideways, and after letting go of A it straightens over a second or so as its path swings round onto its nose (30 degrees after about 1 s with W held). What stopped dead was the **turn**. The moment A or D was let go, the body went from turning at 191.9 degrees a second to not turning at all, in one step. Nothing carried on that the player had to catch. So I read the board's "keeps a little sideways momentum you catch with counter-steer" as the tail swinging out a bit more, as in Hotshot Racing and Mario Kart, not as a longer slide. The slide was already long.

**What I changed** (`car_model.gd`, `_exit_slip_turn` and `_start_exit_slip`). When a drift ends on the ground because A or D is let go, the body keeps turning the drift's way for a moment. It starts at a share of the turn rate and fades in a straight line to nothing. Holding the other key fades it 4 times faster, and steering its own way again ends it. It grows with the square of the drift angle at the end, full from 60 degrees, so quick steering touches barely slip. It only carries on a turn that was swinging the tail out, never one already straightening the car. Letting go of W while still steering (the alternate drift's switch) has no slip. It never applies in the air: it stops at takeoff, and there is none on landing. Speed, grip, the drift amount, the tricks and their payouts are untouched. The whole extra turn is the full slip x (time + one step) / 2, so it can never become a spin.

**Defaults** (`car_tuning.gd`, its own block after `wall_bounce`, apart from T-269's and T-275's lines; sliders in `SLIP_SETTINGS`, in the tuning panel's "Out of a drift: side slip" group right after the handling sliders; the readout shows the slip):
- Strength `exit_slip_turn` **0.35** of the turn rate (67 deg/s; slider 0 to 0.75; 0 = off). Small enough to read as a wobble, not a second turn.
- Length `exit_slip_seconds` **0.4 s** (slider 0.05 to 0.75). Long enough to notice and catch, short enough to settle almost at once if ignored. Together these give about **14 degrees** of extra turn after a full drift, a little over half of one of the sprite's 16 directions. At the sliders' ends it is at most 55 degrees, still no spin.
- Catch `exit_slip_catch` **4x** (slider 1 to 10): caught within 0.1 s (5 steps), so a tap is enough.
- Full at `exit_slip_full_angle` **60 degrees** (slider 10 to 90): a held drift settles at about 68, so every proper drift gets the full slip and small corrections don't.
- The Unity values set the strength to 0 (`UNITY`), so `reset_to_unity()` gives the Unity car exactly. That is why the existing Unity-number tests pass unchanged.

**Honest note for the playtest.** At these defaults the effect is subtle on screen. The car is already 65 degrees sideways, and 14 degrees more mostly shows as the tail kicking a touch further and the path curving a little more before it straightens. If the board wants it to read more, the strength and length sliders are the ones to try first (for example 0.5 and 0.5 s give about 25 degrees).

**Tests:** `game/tests/unit/test_drift_exit_slip.gd`, 17 tests. They check:
- the values and sliders, and that reset works
- with the slip off, the turn stops dead (the old behaviour)
- after a full drift, the full slip on the first step, gone within 0.4 s (20 steps)
- a little more sideways speed than before (more, but under 5 units/s more)
- the extra turn matches its formula (14.1 degrees)
- counter-steer catches it within 6 steps
- steering back the same way ends it
- no spin-out with no input, with W held and coasting, at the defaults and at the sliders' ends (W held: never past 90 degrees, straight after 5 s)
- small touches barely slip; it works the same out of a right drift
- releasing W while steering, and a straightening turn, give no slip
- none in the air, and a running slip stops at takeoff
- the panel's sliders, and the prototype car slipping

Results:
- Full GUT suite, after merging master (T-281): 1382/1382 passed, exit 0.
- `python -m unittest discover -s tools -p "test_*.py"`: 451 OK.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 395 OK, 1 skipped.

**GIFs and stills** (`art-archive/T-278/screenshots/`), from the fixtures `game/tests/fixtures/drift_exit_slip_gif.tscn` and `drift_exit_slip_gif_run.tscn`. Each GIF shows three drifts: one with the slip off, one left alone, one caught with a touch of counter-steer. A caption (a recording aid, not game text) shows the slip in deg/s and the drift angle.
- `drift_exit_slip_prototype.gif`: the drift prototype, 4.5 MB.
- `drift_exit_slip_run.gif`: a run, on the street at (0, 10) facing east, where the drive hits nothing; 8 MB.
- Stills: `prototype_slip_off_released.png`, `prototype_slip_left_alone.png`, `run_slip_caught.png`.

I looked at frames of both GIFs. In the run, the car hops a curb once, so an airtime popup shows; that is not part of the slip.

**Refusal:** the permission system refused one command, `rm -rf` of my own scratchpad frame folders, because the path was built from shell variables. I did not get around it. I recorded into new folders instead, and the old frame folders are still in the scratchpad.

**Documents affected:** `docs/drifting.md` (Content: "Side slip out of a drift (task T-278)", and the tuning panel bullet), `game/README.md` ("Side slip out of a drift (T-278)", and the tuning panel paragraph).

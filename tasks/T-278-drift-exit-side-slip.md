---
id: T-278
title: A little side slip out of a drift, to steady with counter-steer
status: open
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

## Result notes

Written by the agent when it finishes.

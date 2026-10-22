---
id: T-249
title: The drift trail changes and gains effects with the hype level
status: in-qa
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/README.md, game/scripts/driving/drift_marks.gd, game/scenes/driving/drift_marks.tscn, tasks/T-117-drift-marks.md, tasks/T-131-combo-heat-levels.md]
files_expected_to_change: [game/scripts/driving/, game/scenes/driving/, game/tools/, game/art/effects/, game/tests/unit/, game/README.md, docs/visual-style.md, art-archive/T-249/screenshots/]
model: sonnet
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

The board's decision (Visual style, Decisions, "Hype drift trail", 2026-10-22): the drift marks (T-117, T-118) change and gain effects with the hype level, on the same combo heat steps as the HUD's combo counter and the trick popups (x2, x3, x4 and up; HUD and menus, Decisions; read the thresholds from the one place the code keeps them, don't copy the numbers). Below x2 the marks stay as they are today. Each step looks hotter than the one before. The effects are your proposal for the playtest: for example a coloured glow in the marks, sparks off the tyres, a flame trail at the top step. Keep them in the combo heat's colours (yellows, oranges, white-hot), drawn in code or by a script-made texture (no PixelLab), hard pixel edges, no semi-transparent pixels inside a sprite, never Redgull red. A mark keeps the look of the step it was laid at, so the trail shows how hot the drift was. Keep the look's settings in the drift marks' scene, as T-117 does, so the board can retune them. The drift prototype has no combo and keeps the plain marks.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the trail at each of the four steps, and a short GIF of a drift whose trail heats up as the combo climbs.

## Acceptance criteria

- [ ] Tests show the marks take the step of the combo's multiplier when they are laid (plain below x2, then steps 1, 2 and 3), using the combo heat's own thresholds, and keep it afterwards (QA: pass; test_drift_marks_hype.gd covers it, step = ComboHeat.step_for, no copied numbers)
- [ ] The drift prototype's marks are unchanged, and the drift marks' existing tests pass (QA: pass; prototype never calls set_multiplier, test_the_drift_prototype_keeps_the_plain_marks passes, full GUT green)
- [ ] Screenshots of the four steps and a GIF of a trail heating up are in `art-archive/T-249/screenshots/`; no Redgull red (QA: pass; 4 PNGs and GIF present, steps visibly hotter, 0 pixels of 135,17,27)
- [ ] `game/README.md`, "Drift marks", and Visual style describe each step's look; the full GUT suite and all Python tool tests pass (QA: pass; README and visual-style updated; GUT all passed, tools 439 OK, game/tools 393 OK skipped 1)

The board's review: build a combo while drifting and watch the trail heat up.
Board review files: the screenshots and GIF in `art-archive/T-249/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the drift trail heats up with the combo, effects proposed by the agent.

### 2026-10-22, In progress → In QA

Built: the drift marks glow yellow at x2, orange with a yellow core at x3, and white-hot with sparks and flames from x4. Sent to QA.

## Result notes

Written by the agent when it finishes.

Built by the Driving & Drift Agent (2026-10-22). Proposal for the board's playtest; all drawn in code, no PixelLab, no red.

- `drift_marks.gd`: `set_multiplier(m)` sets `heat_step = ComboHeat.step_for(m)` (thresholds read from `ComboHeat.THRESHOLDS`, none copied). Each piece takes the step current when it is started and keeps it; the run connects it to `RunState.combo_changed` (3 lines in `run.gd`). The drift prototype never calls it, so its marks stay plain. New `drift_heat_sparks.gd` draws the sparks and flames (opaque pixel squares that shrink and pop out).
- The look of each step is in `drift_marks.tscn` (`heat_looks`, `flicker_frame`):

| Step | Combo | Glow behind marks | Core line | Sparks per tyre per second | Flames |
| --- | --- | --- | --- | --- | --- |
| 1 | x2 | yellow, 0.4 units, steady | none | 14 yellow | none |
| 2 | x3 | orange, 0.5 units, flickers between two oranges | yellow, 0.08 units | 28 orange and yellow | none |
| 3 | x4+ | 0.65 units, flickers orange, light orange, yellow | white-hot, 0.12 units | 48 white, yellow, orange | 26 per second, 9 px squares rising, orange to yellow to white-hot |

- Tests: new `tests/unit/test_drift_marks_hype.gd` (11 tests). Full GUT suite 1298/1298 pass; `python -m unittest discover -s tools` 439 OK; `-s game/tools` 393 OK (1 skipped, as before).
- Screenshots and GIF in `art-archive/T-249/screenshots/`: `hype_plain_x1.png`, `hype_step1_x2.png`, `hype_step2_x3.png`, `hype_step3_x4.png`, `hype_trail_climb.gif`. Fixtures: `tests/fixtures/drift_marks_hype_*.tscn`. Each step looks clearly hotter; sparks are small, flames show best at x4.
- Docs updated: `game/README.md` (Drift marks, "Hype look"), `docs/visual-style.md` (Hype drift trail).
- Refusal: the hook refused my first attempt to write these notes with inline `python -` (it names task files). I did not retry another way; the Project Lead then allowed Edit on this section.

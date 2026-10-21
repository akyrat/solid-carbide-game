---
id: T-217
title: GIFs of the game's current state, for a README section
status: done
from: project-lead
to: game-loop
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [README.md]
files_to_read_first: [tasks/README.md, README.md, game/README.md, docs/level-design.md, docs/enemies.md]
files_expected_to_change: [art-archive/T-217/, game/tests/fixtures/, game/tools/, README.md]
model: sonnet
qa_rounds: 1
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

The board wants the repository's front page to show where the game is today (2026-10-21). Record three short GIFs from the real game on master (the run on the elevation map, with the final car, kaiju, flames and meteor effects), and add a section to the root `README.md`, "Current state of the game", that shows them with one line each:

1. **The car drifting while enemies chase it** on the street.
2. **The car jumping off a tall platform while drifting** (off a height-6 rooftop or its ramp, landing below).
3. **The kaiju chasing the car and throwing down meteors** (warning circles, meteors with their tails, impacts, boulders).

Each GIF is a few seconds long, small enough for a README (aim for under 5 MB each), and shows the game as a player sees it, with the HUD. Drive the car by script in test fixtures (as T-069, T-070 and T-102 did; `game/tools/make_turn_gif.py` and `record_meteor_fx.sh` are examples), and use the existing playtest switches to bring the kaiju in early. Save the GIFs in `art-archive/T-217/screenshots/` and link them from the README section with relative paths. Don't change any game behaviour.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] Three GIFs in `art-archive/T-217/screenshots/` show, in the real game with the HUD: the car drifting with enemies chasing it; the car jumping off a tall platform while drifting; the kaiju chasing the car while meteors fall (QA: pass; real game with HUD in all three, jump and kaiju clear. GIF 1 is open gravel with few small minions, but they gather and chase the car in the later frames, so it just meets the criterion; weakest of the three)
- [ ] Each GIF is under 5 MB and a few seconds long (QA: pass; 4.3, 2.7 and 3.9 MB; 3.6, 3.6 and 3.3 s)
- [ ] The root `README.md` has a "Current state of the game" section showing the three GIFs, each with one line, by relative path (QA: pass; section before Layout, three images with one line each, paths resolve)
- [ ] No game behaviour changed: only fixtures, recording tools and docs; the full GUT suite and all Python tool tests pass (QA: pass; diff is README, GIFs, fixture and recording tools only; GUT 1212/1212, tools 414 OK, game/tools 387 OK with 1 skipped)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started: three GIFs of the game today and a README section.

### 2026-10-21, In progress → In QA

Three GIFs and the README section are in. Sent to QA.

### 2026-10-21, In QA → Done

QA passed all 4. Merged: the README shows the three GIFs.

## Result notes

Written by the agent when it finishes.

Done. Three GIFs recorded from the real game (menu, Start, the run on the elevation map, HUD on) by one scripted fixture, `game/tests/fixtures/readme_gif_demo.gd` (mode from the env var `README_GIF`: street, jump, kaiju), with `bash game/tools/record_readme_gif.sh <mode> <out.gif> [seconds] [skip]` (Godot `--write-movie`, 30 fps, then `frames_to_gif.py`). No game behaviour changed: the fixture only scripts the car's inputs, keeps its health full, and fixes the camera zoom (10 / 13 / 16) so it does not depend on the camera options saved on this machine. `game/tools/frames_to_gif.py` got optional `--first`, `--last`, `--colors` and `--shared` (one palette for the whole GIF); defaults unchanged. The GIFs are 576 x 324 (half the game's 1152 x 648 window, nearest-neighbour), 15 fps, full frame so the whole HUD shows. Frames were looked at, as contact sheets.

In `art-archive/T-217/screenshots/`:
- `drift_with_chasers.gif`: 4.3 MB, 60 frames, 4.0 s. The car drifts figure-eight loops with tyre smoke and skid marks while the green minions gather and chase it; a coin is picked up at the end. Honest notes: it is on the open gravel in the middle of the map, not on an asphalt street (the streets have boulders in the middle, which stopped the scripted car); the minions are small at this zoom and only about 5 to 10 are on screen, so "chased" is readable but not dramatic.
- `drifting_jump.gif`: 2.7 MB, 60 frames, 4.0 s. The car builds speed on the height-6 rooftop, kicks into a drift, goes off the rooftop's east edge still drifting (about 2 s in the air, its round shadow on the street below), and lands on the street with smoke and skid marks. Shows what the task asks.
- `kaiju_meteors.gif`: 3.9 MB, 55 frames, 3.7 s. The kaiju (brought in at once with 60.5 s left on the clock) walks after the car with its bar above it; orange warning circles appear, three meteors fall with their purple tails, land with dust and purple rings, and leave boulders; the car's health bar dips once. Shows what the task asks. A flamethrower is not shown (not part of the task).

All three are under 5 MB. README: a "Current state of the game" section before "Layout", with the three GIFs by relative path and one line each.

Tests: `bash game/tools/run_tests.sh` passed (All tests passed); `python -m unittest discover -s tools -p "test_*.py"` OK; `python -m unittest discover -s game/tools -p "test_*.py"` OK (387 tests, 1 skipped). No command was refused, except one compound shell command my own variable use triggered the status-script guard; I reran it as plain commands. Documents affected: README.md.
- 2026-10-21, in-qa → done: QA passed all 4; README and GIFs only, merged straight after QA

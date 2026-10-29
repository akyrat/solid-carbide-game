---
id: T-372
title: The board's level from the level creator becomes the game's map
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/elevation-sample-map.md, game/scripts/game/game_flow.gd]
files_expected_to_change: [game/data/level/, game/scripts/game/, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

The board's decision (Level design, Decisions, "The board's own level becomes the game's map", 2026-10-29): the board is building a level by hand in the level creator and will hand it over; it becomes the map the game plays from the main menu's Start, in place of `data/level/elevation_sample_map.json`.

**Wait for the board's file.** The level is saved in the main checkout's `game/data/levels/` (untracked, never committed as it is: the board's working folder). The Project Lead writes the file's name in this ticket's Updates when the board hands it over; don't start before that.

Then: copy the board's level file into the game's own data (`game/data/level/`, a new name of your choice, e.g. `board_map_01.json`; the original in `game/data/levels/` stays untouched and uncommitted) and make Start play it (`GameFlow`, the layout path the run uses). Check it: `python game/tools/check_level.py` and `python game/tools/check_height_data.py` pass, the run builds its buildings, rooftops, ramps and obstacles, the enemies find their way on it (the run's navigation), the kaiju and gift packs have somewhere to land, and the car starts on a road. Anything the level is missing for a full run (for example no space for the kaiju) is reported to the Project Lead in the result notes, not invented. Keep the elevation sample map in the repo (tests and the creator use it). The level creator keeps playing its own levels as before.

The board's review: press Start and play a run on your level.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Start on the main menu plays the board's level (a copy in game/data/level/), and the board's original file in game/data/levels/ is unchanged and not committed (test for the layout path; git status). (QA: pass / fail)
- [ ] The level passes `python game/tools/check_level.py` and `python game/tools/check_height_data.py`, with the output in the result notes. (QA: pass / fail)
- [ ] A scripted run on it builds the map, spawns minions that reach the car, and the kaiju and gift packs land (tests), or the result notes list what the level lacks. (QA: pass / fail)
- [ ] Level design, Content and game/docs/level/ say which file the game plays. (QA: pass / fail)
- [ ] Screenshots of a run on the level are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-439
title: The kaiju alert signs move onto Kaiju City
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-372]
documents_affected: [docs/level-design.md, game/docs/level/mvp-map.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, tasks/T-372-board-level-becomes-the-game-map.md, tasks/T-130-kaiju-alert-banners-art.md, game/docs/level/mvp-map.md, game/data/level/kaiju_signs.json, game/scripts/level/kaiju_signs.gd, game/tests/unit/test_kaiju_signs.gd]
files_expected_to_change: [game/data/level/kaiju_signs.json, game/scripts/level/kaiju_signs.gd, game/tests/unit/test_kaiju_signs.gd, game/docs/level/mvp-map.md, docs/level-design.md]
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

The board, 2026-10-31 (docs/level-design.md, Decisions, "The kaiju alert signs move onto Kaiju City"): since T-372 Kaiju City is the game's map, but the kaiju alert signs (T-130, `game/data/level/kaiju_signs.json`) are still placed for the old sample map's 4 x 4 block grid. On Kaiju City the 2 standing pavement signs are drawn at (-66.75, 41.25) and (95.25, 95.25), which are on no block, and the 4 hanging banners find no matching skyscraper and are not drawn at all (T-372's result notes, level gap 3).

Move all 6 onto Kaiju City: the 2 standing signs on pavement beside roads the player drives, and the 4 banners hanging on visible walls of 4 different skyscrapers on this map, keeping each one's design (head or body) and the T-130 rules for how a banner hangs, fades with its building and sits in depth. You propose the spots, for the board's playtest; spread them over the map so the player meets them while driving. If the sign data can't address Kaiju City's buildings in its current form ([column, row] blocks and slots), change the data format and kaiju_signs.gd so it can, keeping it a small data file that is edited to move, add or remove signs with no code change. No new art: the existing sprites (`game/art/banners/`) are reused, 0 PixelLab calls.

Never write, move or commit anything in game/data/levels/ (the board's level files, kaiju_city.json above all). Read them only.

The board's review: drive Kaiju City and look at the 6 signs: are they on the map, in good spots, drawn right against their buildings?

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test loads the game's map (Kaiju City) and asserts all 6 alert signs are built: 4 banners, each on a different skyscraper of this map, and 2 standing signs, each on pavement (not on a road, a building or off the map). (QA: pass / fail)
- [ ] A test asserts each banner is a child of its skyscraper's art, so it fades with that building, as in T-130. (QA: pass / fail)
- [ ] Each sign keeps its design (head or body) from today's kaiju_signs.json (test or diff in the result notes). (QA: pass / fail)
- [ ] kaiju_signs.json is still the one place signs are moved, added or removed with no code change, and game/docs/level/mvp-map.md describes its format. (QA: pass / fail)
- [ ] Screenshots of each of the 6 signs in place on Kaiju City are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed, and 0 PixelLab calls are made. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-439
title: The kaiju alert signs move onto Kaiju City
status: cancelled
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

The board, 2026-10-31 (docs/level-design.md, Decisions, "The kaiju alert signs move onto Kaiju City"): since T-372 Kaiju City is the game's map, but the kaiju alert signs (T-130, `game/data/level/kaiju_signs.json`) are still placed for the old sample map's 4 x 4 block grid. On Kaiju City the 2 standing pavement signs are drawn at (-66.75, 41.25) and (95.25, 95.25), which are on no block, and the 4 hanging banners find no matching skyscraper and are not drawn at all (T-372's result notes, level gap 3).

Move all 6 onto Kaiju City: the 2 standing signs on pavement beside roads the player drives, and the 4 banners hanging on visible walls of 4 different skyscrapers on this map, keeping each one's design (head or body) and the T-130 rules for how a banner hangs, fades with its building and sits in depth. You propose the spots, for the board's playtest; spread them over the map so the player meets them while driving. If the sign data can't address Kaiju City's buildings in its current form ([column, row] blocks and slots), change the data format and kaiju_signs.gd so it can, keeping it a small data file that is edited to move, add or remove signs with no code change. No new art: the existing sprites (`game/art/banners/`) are reused, 0 PixelLab calls.

Never write, move or commit anything in game/data/levels/ (the board's level files, kaiju_city.json above all). Read them only.

The board's review: drive Kaiju City and look at the 6 signs: are they on the map, in good spots, drawn right against their buildings?

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test loads the game's map (Kaiju City) and asserts all 6 alert signs are built: 4 banners, each on a different skyscraper of this map, and 2 standing signs, each on pavement (not on a road, a building or off the map). (QA: pass - test_kaiju_signs.gd builds 6 signs on Kaiju City: 4 banners on 4 different skyscrapers, 2 standing signs. Ground point: kaiju_city_map.json's legend has only building, gravel and road, no pavement tile; gravel is the walkable ground beside roads, so the signs on gravel, off roads/buildings/props, on the map and within 3 units of a road meet the criterion's intent.)
- [ ] A test asserts each banner is a child of its skyscraper's art, so it fades with that building, as in T-130. (QA: pass - banners are children of their slot's art; fade tested at 0.15.)
- [ ] Each sign keeps its design (head or body) from today's kaiju_signs.json (test or diff in the result notes). (QA: pass - head, body, body, head / body, head match the old order, tested.)
- [ ] kaiju_signs.json is still the one place signs are moved, added or removed with no code change, and game/docs/level/mvp-map.md describes its format. (QA: pass - kaiju_signs.json is {note, map, signs}, format described in game/docs/level/mvp-map.md, 'Alert signs'.)
- [ ] Screenshots of each of the 6 signs in place on Kaiju City are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass - 6 screenshots in art-archive/T-439/screenshots/, listed in the notes.)
- [ ] Nothing under game/data/levels/ is changed or committed, and 0 PixelLab calls are made. (QA: pass - the branch diff has nothing under game/data/levels/; no PixelLab calls.)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass - qa_check: all 3 test sets pass; counts in the notes 767 / 585 / 2313.)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Started: the Level/Challenge Design Agent builds it in C:\solid-carbide-worktrees\T-439.

### 2026-10-31, Needs playtest

QA passed 7/7. Ready for your playtest: open C:\solid-carbide-worktrees\T-439\game\project.godot and drive Kaiju City to the 6 signs. The 2 standing signs are on gravel: Kaiju City has no pavement.

### 2026-10-31, Needs playtest → Cancelled

Cancelled on your call: signs become creator pieces you place; the fixed list is retired. Branch kept.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

- 2026-10-31, Level/Challenge Design Agent, done (to QA):
  - **Format change:** the old `[column, row]` block and slot addressing can't name Kaiju City's buildings, so `game/data/level/kaiju_signs.json` is now `{note, map, signs}`: `map` = the layout file the signs belong to (no sign is built on any other map: the MVP layout, the sample map, creator levels); a banner names its skyscraper by its level entry's `building: [x, y]`; a standing sign by `at: [x, y]`. Still one small data file, no code change to move, add or remove. `game/scripts/level/kaiju_signs.gd` follows (block and slot code removed; a pavement sign's z is the slot behind it with the largest front corner x + y, plus 1). Format documented in `game/docs/level/mvp-map.md` ("Alert signs").
  - **The spots (my proposal for the playtest), designs kept in the old order (banners head, body, body, head; signs body, head):**
    - banner_north_west_east: skyscraper (-120, -60), east wall, head.
    - banner_south_west_east: skyscraper (-120, 60), east wall, body.
    - banner_start_south: skyscraper (-22, 8) just north of the spawn (1, 1), south wall, `along` 7 so it clears roof-1 beside it, body.
    - banner_south_east: skyscraper (54, 108), east wall, head.
    - sign_north_east_road: (22.5, -60) on gravel east of the long north-south road, body.
    - sign_south_gravel: (30.5, 60.5) on gravel between two roads in the south-east, head.
    - Left out: the north-west top-row skyscrapers (e.g. (-72, -120)): rooftops (roof-3, roof-6, ramp-13) stand against their walls and cover them (first try, seen in a screenshot). Kaiju City has no skyscrapers in the north-east or east, so the banners sit west, centre and south; the two signs cover the north-east and south-east.
  - **Tests:** `game/tests/unit/test_kaiju_signs.gd` now runs on Kaiju City (14 tests): 6 signs (4 banners and 2 standing), the 4 banners on 4 different skyscrapers of the level file (asset skyscraper-N, height >= 20), banners are children of their slot's art and fade with it (the slot goes to 0.15 with the car behind), designs match the old file (head, body, body, head / body, head), each standing sign on gravel (not road), clear of every building, rooftop, ramp and prop, on the map and within 3 units of a road, depth order, no collisions, flat view hides them, other maps (sample, MVP layout) get no signs. `test_game_map.gd`: the run from Start has 6 signs. `test_creator_banners.gd`: dropped its 4 and 2 sign count on the old MVP layout (signs are tested in test_kaiju_signs.gd).
  - **Screenshots** (`art-archive/T-439/screenshots/`, fixtures `game/tests/fixtures/alert_city_*.tscn` with `alert_city_demo.gd`, a run from Start with the car parked in front): `banner_north.png`, `banner_west.png`, `banner_start.png`, `banner_southeast.png`, `sign_northeast.png`, `sign_south.png`. The old `alert_banner_*` and `alert_sign_beside` fixtures were made for the sample map's blocks and now show no sign (left as they are).
  - **Test sets:** game/tools 767 OK (1 skipped); tools 585 OK; GUT TESTS PASSED, 189 scripts, 2313/2313, 1271487 asserts, 773 s (`GUT_TIME_LIMIT=1500`).
  - **0 PixelLab calls; nothing under game/data/levels/ read for writing, changed or committed; game/data/level/kaiju_city_map.json unchanged.**
  - **Documents affected:** `game/docs/level/mvp-map.md` (format and spots), `docs/level-design.md` (the Findings line about the signs now says they moved).
- 2026-10-31, in-progress → in-qa: 6 signs on Kaiju City (4 banners on 4 skyscrapers, 2 on gravel beside roads); tests 767/585/2313 pass; screenshots in art-archive/T-439/screenshots
- 2026-10-31, in-qa → needs-playtest: QA passed
- 2026-10-31, needs-playtest → cancelled: The board, 2026-10-31: cancelled. Signs become level creator pieces the board places itself (ticket to follow); the fixed sign list is retired. Branch kept as reference.

---
id: T-372
title: The board's level from the level creator becomes the game's map
status: in-progress
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

### 2026-10-30, Open → In progress

Your level kaiju_city.json is going into the game: the Level/Challenge agent copies it into the game's own data and makes Start play it. Your original stays untouched.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

- 2026-10-30, open → in-progress: The board handed over its level: game/data/levels/kaiju_city.json in the main checkout (C:\solid-carbide-game), finished 2026-10-30.
- 2026-10-30, Level/Challenge Design Agent, done (to QA):
  - **The copy:** `game/data/level/kaiju_city_map.json`, copied once with `cp -n` from `C:\solid-carbide-game\game\data\levels\kaiju_city.json`. It is byte for byte the same file (sha256 `169e1b24681d9f3816b8e7e2c216e05befd9c75b9810103090ffd5312d10ca69` for both). The original was only read: it was not written, moved or committed, and no `game/data/levels/` folder exists in this worktree. The copy's content is unchanged (no fixes).
  - **Start plays it:** `GameFlow.GAME_MAP_PATH` = `res://data/level/kaiju_city_map.json` (`game/scripts/game/game_flow.gd`). `start_run()` (main menu Start, tutorial Start, pause Restart) passes it to `add_run`. No format change was needed: the run already reads creator levels (T-230, T-239, T-280, T-391). `run.gd`'s default stays `elevation_sample_map.json`, so the tests, the F6 run scene and the creator are unchanged. The creator's Play still plays its own levels.
  - **Checks** (from the repo root): `python game/tools/check_level.py game/data/level/kaiju_city_map.json` printed `OK` (exit 0). `python game/tools/check_height_data.py game/data/level/kaiju_city_map.json` printed `OK` (exit 0). Since the file has a spawn point, check_level also checks it: (1, 1), heading 270, on a road at street level.
  - **Tests:** a new file, `game/tests/unit/game/test_game_map.gd` (12 tests), checks that:
    - Start and Restart play the file, and the sample map is still the run's default.
    - The map holds the file's 42 buildings, 13 rooftops, 28 ramps, 82 props and 9 boulders, and draws the file's own ground.
    - The car starts on the spawn point, on a road.
    - Minions spawn and reach the parked car (13 spawned, 10 reached it in 30 s).
    - Scripted chase: the car is parked on the spawn point and then on each rooftop's centre, with 12 minions on the nearest street spots. Minions reach the car at every stop (7 to 11 of 12) except roof-13 (0 of 12, see finding 1 below).
    - The kaiju arrives at boss time on open street and walks to the car, and its meteors find landing spots.
    - Gift packs land on open road.
    - A report test lists where minions can't spawn.
    - Three existing tests changed for the new behaviour: `test_creator_end_to_end.gd` (`test_the_main_menu_run_uses_the_game_map`), `test_play_level.gd` (`test_a_run_from_the_main_menu_plays_the_game_map`) and `test_screen_flow.gd` (`test_start_begins_a_fresh_run`: the car now starts on the level's spawn point).
  - **What the level lacks or does oddly, for the Project Lead (reported, not changed):**
    1. **roof-13** (height 6, x -60..-12, y -46..-20) has no ramp up to it. Ramps 18 to 22 and ramp 25 all sit on top of it and climb from 6 to 8. The car can only reach it from the air, and minions can't follow the car there (0 of 12 reached it in 40 s).
    2. **No minions spawn round some rooftops.** Minions spawn only on the street, on a ring just beyond the screen's edge. With the car on roof-1 (west of the centre) or in the north-west rooftop cluster (roof-3, roof-6, roof-7, roof-10 and nearby places), that ring lies wholly on rooftops and buildings, so no new minions come until the car gets near a street. This happened at 7 of the 214 car places tried. The rooftop screenshot fixture still had 0 minions after 15 s.
    3. **Kaiju alert signs.** The game's two standing kaiju alert signs (T-130, `data/level/kaiju_signs.json`) are positioned for the elevation sample map's blocks. On this map they are drawn at those same places, (-66.75, 41.25) beside roof-11 and (95.25, 95.25), which aren't part of any block here. The hanging banners find no matching skyscraper and are not drawn. Whether to keep, move or turn off the signs on this map is the board's call.
    - The kaiju, its meteors and the gift packs all have room to land near the spawn point. The navigation finds paths onto every other rooftop.
  - **Proposals for the playtest:** the file name `kaiju_city_map.json`. The car's start is the level's own spawn point, as the board placed it (not changed).
  - **Screenshots** in `art-archive/T-372/screenshots/`, taken from `game/tests/fixtures/game_map_run_{start,wide,rooftop,kaiju,gift}.tscn` (a run started from Start, with the car parked):
    - `start.png`: the spawn point, with minions at the car.
    - `wide.png`: the widest zoom.
    - `rooftop.png`: the car on roof-1 with no minions (finding 2).
    - `kaiju.png`: the kaiju just arrived beside the car.
    - `gift.png`: the helicopter and a landed gift pack.
  - **Test sets:**
    - `python -m unittest discover -s game/tools -p "test_*.py"`: 752 tests OK (1 skipped).
    - `python -m unittest discover -s tools -p "test_*.py"`: 582 tests OK.
    - `bash game/tools/run_tests.sh`: TESTS PASSED, 179 scripts, 2201 tests, 2201 passing, 1264783 asserts, 889 s.
    - The suite is now close to the script's default 900 s time limit (on a busy machine). One run hit the limit and was stopped (exit 124), so the passing run used the script's documented override, `GUT_TIME_LIMIT=1500`. `test_game_map.gd` adds about 60 s, mostly the scripted chase. The Project Lead may want to raise the default.
  - **Documents affected:**
    - `docs/level-design.md`: a new Content section, "The game's map", and the Decision's last sentence now names the file.
    - `game/docs/level/game-map.md` (new).
    - `game/docs/level/level-creator.md`.
    - `game/docs/game-loop/the-run.md`.
    - `game/README.md` (index).

---
id: T-400
title: Level creator: a small jump ramp, one tile long and about 2 units high
status: in-qa
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/, game/scripts/level/, game/tests/unit/level_creator/test_creator_ramps.gd]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/data/level/, game/tools/check_level.py, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

The board's decision (Level design, Decisions, "A small jump ramp", 2026-10-30). The board: "now we have from level 0 to 3, 3 to 6, and 0 to 6 ... a ramp spans 3 blocks in length. I want a ramp that is only 1 square, and that goes up to, let's say, 2 units high, so I can do small jumps, like a small ramp."

Add it as another ramp height step (or ramp kind, whichever fits the creator's keys better; say which), placed, turned in all four directions and put on the ground or on a rooftop like the other ramps, drawn with the ramps' existing textures (no new art). Proposals for the playtest, written in the result notes: one tile long, rising 2 units; its tall end open, so the car drives up and flies off (a closed wall there would stop it) and the jump counts for airtime and the air tricks like a ramp hop; how it shows its slope (today's arrows). Enemies path round or over it as the drivability check decides. Saved levels keep it, earlier levels open unchanged, `check_level.py` accepts it, and the game's own map is unchanged.

Other agents are changing the creator at the same time (T-393 object heights, T-394 obstacle pairs): keep your changes to the ramp code. The strip label for the new step follows the existing ramps' format (numbers only, for example 0 to 2); if it needs a new word, stop and tell the Project Lead (a text ticket comes first). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

The board's review: place the small ramp on the ground and on a rooftop in each direction, press Play and jump off it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The creator places the small ramp in all four directions, on the ground and on a rooftop, one tile long and 2 units high, or as the result notes propose (tests). (QA: pass)
- [ ] In a run the car drives up it and leaves the ground off its top, and a jump long enough counts for airtime as a ramp hop does (tests). (QA: pass)
- [ ] The small ramp saves and reopens, an earlier level opens unchanged, check_level.py accepts it, and the game's own map builds as before (tests). (QA: pass)
- [ ] Level design, Content and game/docs/level/ describe the piece, its keys and the proposals. (QA: pass; qa_check's documents line flagged game/docs/level/ but level-creator.md and level-creator-pieces.md did change on the branch; the car_height.gd change is described in the result notes and docs)
- [ ] Screenshots of the small ramp in each direction in the editor, and a GIF of jumping off it in a run, are in `art-archive/<id>/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; all three sets passed in qa_check, car height tests included)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the level agent builds the small jump ramp.

### 2026-10-30, In progress → In QA

Small jump ramp built: Ramp 0 to 2 / 3 to 5 / 6 to 8 (key H), 4 units long, top open so the car flies off; all three test sets pass, screenshots and GIF in art-archive/T-400.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Level/Challenge Design Agent, 2026-10-30: done, to QA.**

What was built (how it works in detail: `game/docs/level/level-creator-pieces.md`, "The small jump ramp (T-400)"):

- **Height steps, not a new kind.** The small ramp is three more height steps of the Ramp family, after 0 to 6: `ramp-0-2` (street), `ramp-3-5` (on a 3) and `ramp-6-8` (on a 6). Key H steps 0-3, 3-6, 0-6, 0-2, 3-5, 6-8; R turns it to climb north, east, south or west; dragging sets its width, as for the other ramps. Height steps fit the creator's keys best: "raised like the other ramps" is already done with height steps (3 to 6 is the ramp for a rooftop at 3), and the height data keeps each ramp's foot and top as plain numbers. Top bar labels follow the existing format, numbers only: "Ramp 0 to 2", "Ramp 3 to 5", "Ramp 6 to 8" (`creator_texts.json`, no new word).
- **Catalogue and icons:** `build_creator_assets.py` (`SMALL_RAMPS`, `SMALL_RAMP_LENGTH`, `HEIGHT_FAMILIES`) and `build_creator_piece_art.py` (`ICONS`). The three panel icons are made from the existing ramp textures (no PixelLab, no new art); the rebuild left every existing texture and icon byte for byte the same.
- **Data:** a placed small ramp writes `"jump": true` and climbs to no rooftop (`platform` ""). `check_height_data.py`, which `check_level.py` runs, accepts a jump ramp with no platform when its top is above its bottom. Its foot must still match the ground under it, and the overlap rules are unchanged. A ramp without the key still needs its rooftop.
- **The jump (a change in `game/scripts/driving/car_height.gd`, the Driving & Drift Agent's file; the Project Lead may want them to look at it):** before, leaving a ramp over its top end onto lower ground counted as falling off an edge, with no upward speed, so a free-standing ramp only dropped the car. Now, when the car is climbing at `RAMP_TAKEOFF_MIN_SPEED` (4 units/s) or more, it takes off along the slope with the ramp's own vertical speed, the same rule as at a ramp's top onto its rooftop (`took_off(true, vz)`). Off a ramp's side, or slower, it still just falls. Only ramps with nothing at their top end have this drop, so the game's own map drives exactly as before (all its tests pass unchanged).

Proposals for the playtest (also in Level design, Content, "Level creator: the small jump ramp"):

- One tile long = **4 units** (the board's "a ramp spans 3 blocks" for a 12-unit ramp), **2 units high** from what it stands on, default width 10 (at least 4). Its slope (1 in 2) is twice a 0 to 3 ramp's, so the jump is lively: after a 22-unit run-up from a standstill the car spends **1.58 s in the air** and rises to **4.73 units** (2.7 over the lip). The airtime trick pays from 0.3 s, so every jump off it at take-off speed pays. If it feels too big, the cheapest tweak is the length (`SMALL_RAMP_LENGTH`, for example 6 units for a gentler slope) and a catalogue rebuild.
- **Its tall end is open:** nothing stands above the lip, so the car flies off it. The face under the lip is drawn as the ramp's back, in the ramp side's texture as on T-264's closed ramps, so it doesn't look hollow. From behind it is a 2-unit step the car can't climb, like any raised side (tested).
- **Its slope shows with today's arrows,** up by default, turned with key A.
- **Enemies** treat it as any ramp: they walk up from its foot and drop off its top or sides, or go round it (enemy navigation builds and finds a path past it; tested).
- A Ramp 0 to 2 placed on a rooftop (instead of the 3 to 5) starts at 0 inside the rooftop, the same as a 0 to 3 placed there today. `check_level.py` reports that as a bottom_height problem, as it does for the other ramps.

Tests (all run in the foreground in the worktree):

- New: `game/tests/unit/level_creator/test_creator_jump_ramps.gd` (13 tests: H steps and labels; placed in all four directions on the street, on a 3 and on a 6, 4 x 10 or 10 x 4 and 2 high; no drawn face above the lip, arrows up the slope; saved, reopened, and `check_level.py` run on the saved file; an earlier level opens unchanged; the car drives up and flies off in all four directions and the airtime pays; a wall from behind; a jump off a 3 to 5 on a rooftop; an enemy path; a run on the level has the jump ramps under the car; the game's map has none). Added to: `test_car_height.gd` (open-top takeoff, side and slow cases), `tools/test_check_height_data.py` and `tools/test_check_level.py` (jump ramps), `tools/test_build_creator_assets.py`. Updated pinned counts: `test_creator_assets.gd`, `test_creator_families.gd` (H now goes round six steps).
- `python -m unittest discover -s game/tools -p "test_*.py"`: **674 tests, OK (1 skipped)**.
- `python -m unittest discover -s tools -p "test_*.py"`: **576 tests, OK**.
- `bash game/tools/run_tests.sh`: **1954/1954 passing, TESTS PASSED** (1,247,216 asserts). One earlier full run had `test_wreck.gd`'s run test fail once. It passed alone 3 times in a row and in the final full run. It drives the game's own map with minions, not a small ramp, so it looks like a flake under load.

Screenshots and GIF (`art-archive/T-400/screenshots/`):

- `editor_street.png`: Ramp 0 to 2 climbing north, east, south and west (top bar: "Ramp 0 to 2", "Climbs north").
- `editor_roof3.png`: Ramp 3 to 5 in four directions on a height 3 rooftop.
- `editor_roof6.png`: Ramp 6 to 8 in four directions on a height 6 rooftop.
- `jump_drive.gif` (and its last frame `drive_end.png`): a run on that level, with the car jumping off a 0 to 2 northwards, a 0 to 2 southwards, a 3 to 5 on the 3, and a 6 to 8 on the 6 and then off the 6's edge, with the airtime counter showing.
- Fixtures: `game/tests/fixtures/level_creator_jump_ramps_level.gd`, `level_creator_jump_ramps_demo.gd` with `level_creator_jump_ramps_street.tscn`, `_roof3.tscn` and `_roof6.tscn`, and `level_creator_jump_ramps_drive.gd` / `.tscn` (GIF frames, then `game/tools/frames_to_gif.py`).

The board's levels in `C:\solid-carbide-game\game\data\levels\` were neither read nor written. The game's own map (`elevation_sample_map.json`) is unchanged.

Not done (a safety check refused it): while building the icons, a path mix-up made Python write 13 PNGs into `C:\c\Users\andre\AppData\Local\Temp\claude\C--solid-carbide-game\0a239fb3-1579-4ac6-90b2-13f2ab42e3c7\scratchpad\icons\` instead of the scratchpad. The `C:\c` folder already existed with another session's files. Removing it was refused, so I left it alone. Only that `icons` folder is mine, and the board can delete it.

Documents affected: `docs/level-design.md` (Content, "Level creator: the small jump ramp"), `game/docs/level/level-creator-pieces.md` ("The small jump ramp (T-400)"), `game/docs/level/level-creator.md` (key H).

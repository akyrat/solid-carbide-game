---
id: T-280
title: "Level creator: a spawn point every level has, always visible and movable"
status: done
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-279]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/scripts/level_creator/, game/scripts/run/run.gd, game/tools/check_level.py, tasks/T-239-level-creator-play-a-listed-level.md, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/run/, game/tools/check_level.py, game/tests/, game/README.md, docs/level-design.md, art-archive/T-280/screenshots/]
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

The board's decision (Level design, Decisions, "The car's spawn point", 2026-10-22). Today a custom level's run starts the car at the map's centre. Give every level a **spawn point**:

- **Always there, always visible:** a marker on the map (drawn in code, clearly readable over any ground, for example a car silhouette or arrow with T-279's label; your proposal, never Redgull red) shows from the moment a level opens in the editor, above the pieces so it's never hidden. A new level puts it at the map's centre; a level saved before this ticket opens with it there too.
- **Movable:** drag it (or select it and click where it should go) anywhere the car can stand: on the street, a rooftop or a ramp, at that surface's height, snapped to the grid; never inside a building, an obstacle or off the map (refused with T-279's message, and the marker stays where it was). Turning it (R while selected) sets the car's starting heading (a proposal; four or eight headings).
- **Never deleted:** Delete on it shows T-279's message and keeps it; a level always has exactly one.
- **Saved and used:** saved in the level file; a run started from the creator starts the car there, at that height and heading. `check_level.py` refuses a level whose spawn point is missing or not where a car can stand. The game's own map is unchanged.

Built on T-262's branch once it passes QA (the Project Lead makes your folder), with T-279's labels. End with screenshots of a new level with its spawn point, the point moved onto a rooftop, and a short GIF of a run starting there.

## Acceptance criteria

- [ ] Tests show a new level and an old level open with a visible spawn point at the centre, it can be moved and turned, it can't be deleted, and it is refused inside a building, an obstacle or off the map (QA: pass; 23 new GUT tests cover new/old level at centre, move, 8-heading turn, no delete, refusals; all pass)
- [ ] Tests show the spawn point saves and reopens, and a run from the creator starts the car at its place, height and heading; `check_level.py` refuses a level without a valid one (QA: pass; save/reopen, run start place/height/heading, check_level refusals tested and pass)
- [ ] Labels from `creator_texts.json`; no Redgull red; the game's own map unchanged (QA: pass; labels from creator_texts.json, marker green, no Redgull red, game/data/level unchanged vs T-272)
- [ ] Screenshots and the GIF are in `art-archive/T-280/screenshots/`; `game/README.md` describes it; the full GUT suite and all Python tool tests pass (QA: pass; screenshots and GIF present, README and level-design updated; GUT 1616/1616 (first run hit the known exit 139 flake, rerun clean), game/tools 502 OK, tools 451 OK)

The board's review: open a level, move the spawn point onto a rooftop, and play from there.
Board review files: the screenshots and GIF in `art-archive/T-280/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-23, Blocked → In progress

Started on T-272's branch: a spawn point every level has, always visible and movable.

### 2026-10-23, In progress → In QA

Spawn point built: drag to move, R turns (8 headings), can't delete, run starts there. Click-to-place not built, drag only. Sent to QA.

### 2026-10-23, Needs playtest

QA passed all 4. Ready to play in the creator build: drag the Start marker onto a rooftop, R to turn it, then play.

## Result notes

**Built (Level/Challenge Agent).** Every level has one spawn point, always drawn, movable, turnable, never deleted, saved, and used by a run.

- **Data** (`scripts/level/level_spawn.gd`, `LevelSpawn`, one place for the rules): the level file's `spawn` is `{x, y, heading}`: a 2 x 2 cell's middle (units) and a heading in degrees (the car model's rotation; 270 is the run's own start). No height is stored: the car stands on the ground there. Where a car can stand: inside the map and 1 unit clear of every building, prop and boulder (the cell beside one is fine); rooftops and ramps are fine.
- **Editor** (`editor.gd`, `level_document.gd`): `ensure_spawn` on open and on save, so a new level and an old one open with it at the centre cell. Marker (`_Overlay._draw_spawn`): a green arrow on its cell turned to the heading, label `spawn_label`, dark outline, lifted to the surface height, at z 4000 above the pieces; yellow outline when selected. Drag it (`begin_spawn_drag`, ghost in grey when refused, drop snaps to a cell middle). Refused with `spawn_blocked` in a building, on an obstacle or off the map; it stays. R with it selected turns it round eight headings. Del shows `spawn_no_delete`. A click selects it and shows `spawn_hint`. Hint line is `controls_hint_spawn`.
- **Run** (`run.gd`): the car starts at the layout's `spawn` (place, heading, and the ground's height there); the game's own map has none and starts as before. **Level check** (`check_level.py`, `check_spawn`): refuses a level without a valid spawn point (missing, bad heading, off the map, on a building, prop or boulder); the game's own map files in `game/data/level/` are exempt.
- **Proposals and things to know for the playtest:** (1) eight headings, 1 unit clearance, green marker colours; (2) "select it and click where it should go" is NOT built: a click only selects, a drag moves (say if you want click-to-place too); (3) a piece placed over the start is refused (undone) with `spawn_blocked`, whose wording ("Can't start here") is a little off for that case; I wrote no text of my own; (4) the old tests that placed pieces at the map centre now start with the spawn moved out of the way (`level_data.spawn` at 111, 111); five hint assertions moved to `controls_hint_spawn`; (5) opening the game's map in the creator adds a spawn in memory only (a save writes it into the new level file, not the game's map).
- **Tests:** new `tests/unit/level_creator/test_creator_spawn.gd` (23: new and old level open with it at the centre, label and hint line, drawing while dragged, select, drag, mouse events, onto a rooftop and a ramp, refusals in a building, on obstacles and off the map, next to a building allowed, R through eight headings, Del, a piece over it refused, saved/reopened/checked, check_level refuses a missing or bad one, a run starts the car at its place, height 3 and heading, an old level starts at the centre, the game's own map unchanged, no red). `TestSpawn` (6) in `tools/test_check_level.py`; `small_level()` now has a spawn. 18 older tests changed as listed above. Full GUT suite: 1616 passing, TESTS PASSED (first run before the test fixes had 18 failures, all in level_creator, all fixed). Python: `game/tools` 502 OK (1 skipped), `tools` 451 OK.
- **Screenshots and GIF** (`art-archive/T-280/screenshots/`, I looked at all of them): `editor_new.png` (a new level, the marker at the centre of a crossroads, label "Start"); `editor_roof.png` (moved onto a rooftop beside a ramp, turned to face it, selected, top bar shows the hint); `editor_refused.png` (a building dropped on, "Can't start here: it's blocked.", the point stays); `editor_drag.png` (mid-drag ghost); `run_from_spawn.gif` (a run on that level: the car starts on the rooftop facing the ramp and drives down it) and `drive_end.png`. Fixtures: `tests/fixtures/level_creator_spawn_demo.tscn` (`T280_SHOT`) and `level_creator_spawn_drive.tscn`.
- **Documents affected:** `docs/level-design.md` (Content, "Level creator: the spawn point", with the screenshots), `game/README.md` ("Level creator", "The spawn point (T-280)").

No refusals.
- 2026-10-23, in-progress → in-qa: Built: spawn point (8 headings, drag to move, refused in buildings/obstacles/off map, can't delete, saved, run starts there). Click-to-place not built (drag only).
- 2026-10-23, in-qa → needs-playtest: QA round 1: all pass. 18 older test changes keep intent. Click-to-place not built (drag only).
- 2026-10-27, needs-playtest → done: The board's playtest of the creator build (playtest/creator-set, 2026-10-28): every check ticked on the playtest page, everything works fine.

---
id: T-560
title: The practice playground level
status: in-progress
from: project-lead
to: level-challenge
lead: Rails
epic: level-challenges
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/drifting.md, game/scripts/driving/ground_grid.gd, game/docs/level/game-map.md]
files_expected_to_change: [game/data/level/, game/scenes/, game/scripts/level/, game/tests/, game/docs/level/, docs/level-design.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build Level design, Decisions, "The practice playground": a small level the tutorial's practice windows load (T-561), on the drift prototype's dark purple grid ground (ground_grid.gd's colours, or close to them), with an open area for drifts and alt drifts, a ramp (a jump ramp or a ramp onto a rooftop) fast enough for an AIR 360!, and two or three rails reachable from the ramp. It is a level file in the same format the game loads (game/data/level/, with the same checks: check_level.py, check_height_data.py), so the board can open and edit it in the level creator later. Give a start point per trick slide (drift, alt drift, air spin, grind), chosen so the trick is easy to try at once. Check the contrast: the car, its drift smoke and effects, the rails, the ramp and the HUD (the notebook) must stand out clearly against the ground; adjust the ground's colours if needed and say what you chose. Keep it small so it loads fast.

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The playground level file loads in the game and passes check_level.py and check_height_data.py (output in the result notes). (QA: pass / fail)
- [ ] It has an open drift area, a ramp from which the car reaches an AIR 360! at full speed, and rails reachable from the ramp (tests). (QA: pass / fail)
- [ ] It names a start point for each of the four trick slides (test). (QA: pass / fail)
- [ ] Screenshots show the car drifting, on the ramp and on a rail on it, and the result notes say how the contrast was checked. (QA: pass / fail)
- [ ] docs/level-design.md Content and game/docs/level/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: a small practice playground on the dark purple grid, with a ramp and rails.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

T-560 done by level-challenge.

**For T-561:** level file `res://data/level/practice_playground.json` (made by `python game/tools/build_practice_playground.py`). Start point ids: `drift`, `alt_drift`, `air_spin`, `grind` (all heading 0, east); `spawn` = drift. Load: `GameFlow.add_run(parent, progress, "res://data/level/practice_playground.json", null, "air_spin")` (new 5th parameter; `run.start_point_id` can be set before the run enters the tree). Helper: `LevelStartPoints` (ids, of, with_spawn).

**What was built**
- Level: 120x72 units, 1 rooftop (height 3), ramp-1 (0-3, 12 long) onto it, ramp-2 (3-5 jump ramp, 4 long) on it, rails rail-1 (y0, x16-34), rail-2 (y0, x38-52), rail-3 (y3.5, x38-56), all z=1. Open drift area in the west half. Creator-catalogue pieces only.
- New optional level keys: `ground_style` (grid ground, `scripts/level/grid_ground.gd`, drawn by mvp_map.gd; ground tiles hidden when set; Kaiju City unchanged) and `start_points` (`scripts/level/start_points.gd`; run.gd `start_point_id`; GameFlow.add_run param). check_level.py checks start_points (unit test added).
- Numbers (proposals): full speed 16.5 at the jump ramp top, airtime 1.82 s, AIR 360 paid with 0.3 s spare; rail-1 for a slow car, rail-2 at full speed, rail-3 a lane over.

**Checks (output):** `check_level.py` OK, `check_height_data.py` OK on practice_playground.json.

**Tests:** new `game/tests/unit/level/test_practice_playground.gd` (9 tests, scripted drives with the real car: air_three_sixty paid from air_spin; rails caught from the ramp; start points start the car). Python `unittest discover -s game/tools`: 1043 tests OK (4 skipped). Full GUT run: 261 scripts, 2981 tests, 2980 passing, 0 failing, 1 risky/pending (TESTS PASSED).

**Contrast (checked from the screenshot's pixels, WCAG ratio vs ground 18/18/36):** drift smoke 2.1 edge / 15 core; rail bars 14; ramp concrete 3.6; HUD notebook paper 15, green clock 10; car has bright stripes/outline (dark green body 1.1, reads by its light parts). Ground kept as the drift prototype's (ground_grid.gd colours). Weak: tyre marks (dark) ~1.06, nearly invisible. Lightening the ground to ~60/56/96 gives 1.8 but hurts smoke edges (1.2) and ramp (2.1). Left as an open question in docs/level-design.md for the board; proposed keep.

**Screenshots** (`art-archive/T-560/screenshots/`): drift.png (drifting with smoke), ramp.png (car on the rooftop jump ramp), air.png (in the air), rail.png (grinding, sparks, facing arrow), overview.png. Scene: `game/tools/shots/practice_playground_shots.tscn` (T560_MODE).

**Documents affected:** docs/level-design.md (Content, "The practice playground (task T-560)", one open question), game/docs/level/practice-playground.md (new), game/README.md index. Long GDD and fingerprint not regenerated (Project Lead).

Notes: new .gd.uid files for my two scripts were left untracked like the repo's other uid files; I did not touch game/data/levels/.

Follow-up (the board: contrast of the car and its effects): the tyre marks were nearly invisible on the prototype ground (1.06). Chose the smallest change: the playground level lightens its own ground_style colours (ground 59/54/94, lines 76/71/122 and 115/105/173), nothing else changes (marks, main map untouched). The marks now read clearly (about 1.7; screenshot art-archive/T-560/screenshots/drift.png); smoke edges and ramp lose some contrast (about 1.3 and 2.1), smoke core, rails and notebook stay about 8 to 9. Screenshots retaken; docs/level-design.md (Content, open question) and game/docs/level/practice-playground.md updated; test_practice_playground 9/9, check_level OK.

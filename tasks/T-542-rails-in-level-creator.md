---
id: T-542
title: Rails in the level creator
status: done
from: project-lead
to: level-challenge
lead: Rails
epic: level-challenges
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-541]
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/level_creator/]
files_expected_to_change: [game/scripts/level_creator/, game/scenes/level_creator/, game/tests/, game/docs/level/, docs/level-design.md]
model: sonnet
qa_rounds: 2
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

Build Level design, Decisions, "Rails", the creator's side: a rail piece in the level creator, placed like the other pieces (position, direction, length and height as T-541's format allows), drawn with T-541's placeholder, saved to and loaded from the level file in T-541's format, and playable when the level is played as a full run. Work on top of T-541's branch. The creator is the board's tool, so its labels follow the creator's existing style.

The board's review: play it from C:\solid-carbide-worktrees\T-542\game\project.godot before merging (open the level creator, place rails on the ground, on ramps and on platforms, play the level).

Round 2, the board's feedback after playing it (2026-11-06): (a) rails look horrible on a ramp or a platform: a rail on raised ground or a ramp must sit at that ground's height and draw in the right depth order, like other pieces on that ground; (b) snapping onto a rail from a platform is very hard, while it works well on the ground: snapping must be as easy from a platform or ramp as from the street (the lock-on must use the car's and the rail's real heights); (c) the board wants long rails that curve round corners. For now corners are angled rail pieces joined end to end: the car stays on the rail through a joint already, but loses a lot of speed there. A joint between connected rail pieces must cost no speed (the car carries its speed along the new piece's direction). This touches T-541's grind and rail drawing code (merged in master); document every change in docs/drifting.md and docs/level-design.md Content.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The creator can place, move, rotate, resize and delete a rail (tests where the creator has tests, otherwise a scripted check named in the result notes). (QA: pass)
- [ ] A saved level with rails loads back the same rails, and playing it as a full run has grindable rails (test). (QA: pass)
- [ ] docs/level-design.md Content describes the rail piece in the creator. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Screenshots in art-archive/T-542/screenshots/ show rails placed in the creator and the same level in a run. (QA: pass)
- [ ] A rail on a ramp and a rail on a platform sit at that ground's height and draw in the right depth order: screenshots in art-archive/T-542/screenshots/ show both in the creator and in a run, and QA opens and looks at them (beyond the script checks), saying in its report what it saw. (QA: pass)
- [ ] A car on a platform snaps onto a rail at the platform's height as easily as on the street (same lock-on distance and angle; test). (QA: pass)
- [ ] Driving through a joint between two connected rail pieces at an angle (for example 30 degrees) keeps the car's speed: no more loss than on a straight rail of the same length (test with the numbers in the result notes). (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-06, Blocked → In progress

Started now that the rail grind (T-541) is in master: the agent is working in C:\solid-carbide-worktrees\T-542.

### 2026-11-06, In progress → In QA

Built: a Rail piece in the level creator (lay, move, resize, turn, height, delete), saved in T-541's format and grindable in a run. QA next.

### 2026-11-06, In QA → In progress

Back with the agent: rails drawn properly on ramps and platforms, easy snapping from a platform, no speed loss at angled joints. QA will check screenshots of rails on ramps and platforms.

### 2026-11-06, In progress → In QA

Round 2 built: rails sit on ramps and rooftops with shadows, snapping from a platform matches the street, angled joints keep all speed. QA round 2 next, with a visual check of the screenshots.

### 2026-11-06, In QA → Needs playtest

QA round 2 passed all 8 criteria. Play it from C:\solid-carbide-worktrees\T-542\game\project.godot (creator: rails on ramps and platforms, then a run).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

T-542 done by the level-challenge agent (on master, which has T-541).

What was built: the Rail piece of the level creator (Levels group, button "Rail"). Lay with a drag (or a click: 12 units in the picked direction, R turns 45 degrees); H steps heights auto / 1 / 3.1 / 6.1 (auto = just above the street or rooftop under each end). Select by clicking the bar; drag an end (resize/turn), drag the bar (move), R turns 45 degrees round the middle, [ ] shorten/lengthen, H height, Del deletes, Esc cancels a drag. Drawn with T-541's RailDrawing (same callables as the run), saved/loaded in the "rails" list (T-541 format), grindable in a run on the saved file.
Files: game/scripts/level_creator/rail_piece.gd (new), editor.gd, level_document.gd (place_rail, set_rail, rail_problem, rails), game/tools/build_creator_assets.py + regenerated data/level/creator_assets.json, creator_texts.json (piece_rail, rail_*), art/creator_pieces/icon_rail.png (button picture, made with a script, no PixelLab), tests, game/tools/shots/ (screenshot scene).
Proposals for the playtest (all in rail_piece.gd / build_creator_assets.py): snap 0.5 unit; default click length 12; turn step 45 degrees; length step 1; heights auto/1/3.1/6.1; auto = 1.0 over the street, surface+0.1 over rooftops/ramps; grab radius 12 px (ends), 8 px (bar); ends must be inside the map.
Docs: docs/level-design.md Content "Rails in the level creator (task T-542)"; game/docs/level/level-creator-pieces.md "Rails (T-542)".
Tests: new game/tests/unit/level_creator/test_creator_rails.gd (24 tests: panel, heights, laying by drag/click/mouse events, auto height on a rooftop, refusals, select/move/resize/turn/height/delete/Esc, drawing, save+reload+check_level.py, run with rails and a car locking onto the creator-laid rail). Updated test_creator_families.gd, test_creator_assets.gd, tools/test_build_creator_assets.py for the new family. Ran: godot level_creator + run dirs 66 scripts, 801 tests, all pass; test_creator_assets 8/8; test_rail_grind 27/27; python test_build_creator_assets 27 OK. Full three sets not run (QA does).
Test levels only under the test folder/user://; nothing written to game/data/levels/.
Screenshots (art-archive/T-542/screenshots/): creator_rails_placed.png (rails, one selected with handles), creator_laying_a_rail.png (Rail picked, a rail being dragged), run_on_the_creator_level.png (the same level in a run, car grinding). Regenerate: T542_MODE=creator|laying|run bash game/tools/screenshot.sh res://tools/shots/rails_creator_shots.tscn <out.png> 40.
Notes: Godot's untracked .uid files left uncommitted. The 5 rails of the game's map can now be edited by opening a copy in the creator.

QA round 1 stopped early for the board's playtest. Criteria 1 and 3 pass (creator piece and docs section present). 2 fails: snapping onto a rail from a platform is very hard, angled joints cost a lot of speed. 4 fails: full run not finished. 5 fails: rails look horrible on ramps and platforms, no screenshots show them there. Paperwork note: review line names the playtest-grind-rails folder; use this ticket's folder.
- 2026-11-06, in-qa → in-progress: The board played the rails in the creator: rails look horrible on a ramp or a platform; snapping onto a rail from a platform is very hard (fine on the ground); passing a joint between angled rail pieces costs a lot of speed and should cost none (the board wants long rails that curve round corners). QA must take and look at screenshots of rails on ramps and platforms.

ROUND 2 (Driving & Drift Agent). (a) Rails on ramps and platforms: the creator's auto height is now 1 unit over the ground under each end (street, rooftop, ramp, ramp foot), was 0.1 over rooftops/ramps and 1 over the street (so a rail on a ramp floated at the foot and lay flat at the top). Rail pieces over a rooftop or ramp draw their own shadow on that surface (the street shadow was hidden under rooftops), the street shadow is laid in runs over street only (rail_drawing.gd). Depth order is the existing z_for rule; test asserts pieces on a ramp sit over the ramp's own z. rail_point_at in the creator now settles an end on the highest ground it can be on (7/4/1 start heights) so rails can be laid on a rooftop where the street was also under the mouse. (b) Snapping from a platform: the lock-on already used real heights; the cause was the bar 0.1 over a rooftop being in reach for only ~0.14 s of a Jump's arc (street: whole arc, bar 1 over). Fixes: auto rails 1 over the ground, and catch_above 0.5 -> 1.0 (data/rail_grind.json) so a 3.1 bar on a 3 rooftop is caught along the arc too. Test: a first-tier hop catchable 21 steps from street, 3 and 6 rooftops (bar 1 over); 24 steps with the bar 0.1 over a 3 rooftop; same distance/angle acceptance on a platform. (c) Joints: RailGrind.joint_at_end/_cross_joint: past a rail's end, a connected rail (an end within join_distance 1.0 units flat, join_height 0.6 units in height, way on turning travel by at most join_max_angle_deg 100) takes the car with its whole speed along the new direction, rest of the step carried over, one grind (seconds and length add up, one GRIND!). Smallest turn wins at a fork. Test numbers: after 15 units from 11 u/s, straight 9.5333, 30 degree joint 9.5333, 90 degree equal. Proposals for the playtest (all in data/rail_grind.json): catch_above 1.0, join_distance 1.0, join_height 0.6, join_max_angle_deg 100. Tests: new game/tests/unit/test_rail_joints_and_heights.gd 14/14; test_rail_grind 27/27; test_run_rails 5/5; level_creator dir 26 scripts 331 tests all pass (test_creator_rails 26, 3 updated for the new auto height, 2 new for ramp/rooftop); run dir 40 scripts 472 tests, 471 pass: the 1 failure is test_perf_recorder 'no folder written' (a game/perf folder already on disk, not from this change). Full three sets not run (QA does). Screenshots art-archive/T-542/screenshots/: creator_rail_on_ramp, creator_rail_on_platform, run_rail_on_ramp (car grinding it), run_rail_on_platform (car grinding it), and before_* of the old look; I looked at all of them: bars sit on posts over the surface with a shadow, in the right depth order, the car on top. Regenerate: T542_MODE=raised|raised_run [T542_VIEW=platform] bash game/tools/screenshot.sh res://tools/shots/rails_creator_shots.tscn out.png 30. Docs: docs/drifting.md (Rails on raised ground and joints), docs/level-design.md Content, game/docs/driving/rail-grind.md, game/docs/level/level-creator-pieces.md. Nothing written to game/data/levels/.

QA round 2: all 8 criteria pass. qa_check: tests 2 sets passed (tools set skipped), documents ok, 10 screenshots; test_perf_recorder did not fail in QA's run. Screenshots seen: the rail on the platform (run and creator) is a thin white bar on posts a little above the rooftop surface with a shadow on it, drawn over the surface and under the car; the car sits on it. On the ramp (run and creator) the bar runs along the ramp slope on thin posts with a dark shadow on the ramp, in the right depth order, car on top. Weak point for the board: on the ramp the bar lies right beside the white centre lane line, so it reads mainly through its posts and shadow, not strongly against the markings. Untracked game/data/levels/new_level.json in the folder was not committed.
- 2026-11-06, needs-playtest → done: The board played round 2: lgtm.

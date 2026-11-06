---
id: T-542
title: Rails in the level creator
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
depends_on: [T-541]
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/level_creator/]
files_expected_to_change: [game/scripts/level_creator/, game/scenes/level_creator/, game/tests/, game/docs/level/, docs/level-design.md]
model: opus
qa_rounds: 1
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
- [ ] A saved level with rails loads back the same rails, and playing it as a full run has grindable rails (test). (QA: fail: code - the board: snapping onto a rail from a platform is very hard; angled joints cost a lot of speed)
- [ ] docs/level-design.md Content describes the rail piece in the creator. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: fail: code - full run not finished, round stopped for the board's feedback)
- [ ] Screenshots in art-archive/T-542/screenshots/ show rails placed in the creator and the same level in a run. (QA: fail: code - the board: rails look horrible on ramps and platforms; no screenshots show them there)
- [ ] A rail on a ramp and a rail on a platform sit at that ground's height and draw in the right depth order: screenshots in art-archive/T-542/screenshots/ show both in the creator and in a run, and QA opens and looks at them (beyond the script checks), saying in its report what it saw. (QA: pass / fail)
- [ ] A car on a platform snaps onto a rail at the platform's height as easily as on the street (same lock-on distance and angle; test). (QA: pass / fail)
- [ ] Driving through a joint between two connected rail pieces at an angle (for example 30 degrees) keeps the car's speed: no more loss than on a straight rail of the same length (test with the numbers in the result notes). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-06, Blocked → In progress

Started now that the rail grind (T-541) is in master: the agent is working in C:\solid-carbide-worktrees\T-542.

### 2026-11-06, In progress → In QA

Built: a Rail piece in the level creator (lay, move, resize, turn, height, delete), saved in T-541's format and grindable in a run. QA next.

### 2026-11-06, In QA → In progress

Back with the agent: rails drawn properly on ramps and platforms, easy snapping from a platform, no speed loss at angled joints. QA will check screenshots of rails on ramps and platforms.

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

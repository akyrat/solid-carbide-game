---
id: T-390
title: The chosen trick illustrations in slide 2 and the pause trick list, placeholders retired
status: needs-playtest
from: project-lead
to: ui
lead: Goal-G-007
epic: hud-menus
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: yes
depends_on: [T-385, T-386]
documents_affected: [game/docs/hud-and-menus/tutorial-slides.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/menu/trick_list.gd, game/tests/unit/test_trick_list.gd, game/docs/setup/screenshots.md]
files_expected_to_change: [game/scripts/menu/trick_list.gd, game/tests/unit/test_trick_list.gd, game/docs/hud-and-menus/tutorial-slides.md]
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

Goal step 4 of the last MVP round (board, 2026-10-29): slide 2 and the pause screen's trick list show the seven illustrations the comparison ticket copied into game/art/tutorial/tricks/, with no placeholder left. Check each trick's texture loads from its file, draw them with nearest filtering at a whole-number scale (hard pixel edges), and remove the placeholder drawing code or leave it unused, documenting the files it drew for in game/docs/hud-and-menus/tutorial-slides.md. Screenshots of slide 2 and the open pause panel.

The board's review: Check the trick illustrations on slide 2 and in the pause screen's trick list.

## Acceptance criteria

- [ ] Slide 2 and the pause trick list panel both show the seven PNGs from game/art/tutorial/tricks/ with no placeholder drawn; a test checks each trick's texture is loaded from its file. (QA: pass)
- [ ] The illustrations use nearest filtering and a whole-number scale; a test checks the filter and scale. (QA: pass)
- [ ] The placeholder drawing code is removed or no longer reached, and game/docs/hud-and-menus/tutorial-slides.md documents the illustration files. (QA: pass)
- [ ] Screenshots of slide 2 and the open pause trick list panel are saved in art-archive/<task id>/screenshots/. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Blocked → In progress

Goal runner (G-007): started, in C:\solid-carbide-worktrees\T-390.

### 2026-10-30, In progress → In QA

Goal runner (G-007): the agent is done; QA is checking it.

### 2026-10-30, In QA → Needs playtest

Goal runner (G-007): QA passed; merged into playtest/G-007.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (UI Agent, sonnet). No PixelLab generations used.

- `game/scripts/menu/trick_list.gd`: the placeholder (`_make_placeholder`, `PLACEHOLDER_BG/FG`, `is_placeholder`) is deleted. Each trick loads `res://art/tutorial/tricks/<id>.png`; `is_loaded(id)` says so; a missing file leaves the picture empty and logs a warning. Nearest filter on the list and each picture, scale 3 (192 x 144), unchanged. Slide 2 and the pause panel share this one scene, so both show the seven PNGs.
- `game/tests/unit/test_trick_list.gd`: new test for all seven textures loaded from their files (and size 64 x 48), a test that the placeholder methods are gone, and the filter and scale test now covers every trick. Missing-file test now expects an empty picture.
- `game/docs/hud-and-menus/tutorial-slides.md`: placeholder section replaced by the list of the seven files shown.
- `game/tests/fixtures/pause_trick_list_demo.gd`: was broken since T-389 (Start opens the slides); now calls `game.start_run()`.
- Tests: GUT 162 scripts, 1974 tests, 1974 passing; `python -m unittest discover -s tools` 573 OK; `game/tools` Python tests OK.
- Screenshots: `art-archive/T-390/screenshots/slide2.png`, `art-archive/T-390/screenshots/pause_trick_list.png`.
- Refusals: a heredoc python script I tried was refused; I did the edits with the edit tool instead.

### QA round 1
All five criteria pass. GUT 162 scripts / 1974 tests / 1974 passing; `python -m unittest discover -s tools` 573 OK; `game/tools` 675 OK (1 skipped). Tests test_every_trick_texture_loads_from_its_file, test_no_placeholder_code_left and test_illustration_is_drawn_nearest_at_a_whole_scale exist; the placeholder code is gone from trick_list.gd; both screenshots exist in art-archive/T-390/screenshots/ and the seven PNGs are in game/art/tutorial/tricks/. Refused: `python tools/qa_check.py T-390 --no-marks` (needs approval), so I ran the test sets and checks by hand.
- 2026-10-30, in-qa → needs-playtest: QA passed every criterion (goal G-007).

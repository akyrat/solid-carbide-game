---
id: T-431
title: The HUD scales with the window, and a HUD size slider on the pause screen
status: open
from: project-lead
to: ui
lead: Goal-G-008
epic: hud-menus
milestone: mvp
goal: G-008
user_facing_text: yes
changes_visuals: yes
depends_on: [T-426, T-427, T-429]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/pause-screen.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/pause-screen.md, game/data/pause_text.json, game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, game/project.godot]
files_expected_to_change: [game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, game/project.godot, game/tests/unit/hud/test_hud_scaling.gd, game/tests/unit/test_hud_size_slider.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/pause-screen.md]
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

Goal G-008, 'The HUD scales with the window, and a HUD size slider' (HUD and menus, Decisions). Make every HUD piece keep its corner or edge and a size in proportion to the window at any window size and resolution, ultrawide included, with pixel art kept crisp (whole-number scales or nearest filtering) and the world camera's zoom untouched. Add a HUD size slider to the pause screen, laid out like the other sliders, whose label (and value format, if any) is read from game/data/pause_text.json, written by D1: no text in code. Moving it changes the HUD's scale at once while paused; it is saved in GameSettings on release only, following the pattern D2 set, and applied at the next start. Take the range and default from HUD and menus; if the doc leaves them open, propose them and write them in the docs as a proposal for the playtest. Document the scaling rule, the slider's range and default, and which screens it covers.

The board's review: Play a run in a small window, at full screen and on the ultrawide; move the HUD size slider on the pause screen to both ends.

## Acceptance criteria

- [ ] Headless tests at 1152 x 648, 1920 x 1080, 2560 x 1440, 3440 x 1440 and 960 x 540 check that every HUD piece keeps its corner or edge, has a size in proportion to the window, overlaps no other piece and is fully on screen. (QA: pass / fail)
- [ ] Tests show the HUD's scale is a whole number or its textures use nearest filtering, and the world camera's zoom is the same with and without the HUD's scaling. (QA: pass / fail)
- [ ] The pause screen has a HUD size slider laid out like the other sliders, its label read from game/data/pause_text.json (a test checks the label equals the file's text, and grep finds no literal of it in the scripts). (QA: pass / fail)
- [ ] Tests show moving the slider changes the HUD's scale at once while paused, saves to GameSettings only when the drag ends, and the saved value is applied at the next start. (QA: pass / fail)
- [ ] Screenshots at the five window sizes, and with the slider at both ends, are in art-archive/<id>/screenshots/. (QA: pass / fail)
- [ ] docs/hud-and-menus.md, Content and game/docs/hud-and-menus/hud.md and pause-screen.md describe the scaling rule, the slider's range and default, and which screens it covers. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

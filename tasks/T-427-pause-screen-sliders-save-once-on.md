---
id: T-427
title: Pause screen sliders save once, on release
status: in-progress
from: project-lead
to: ui
lead: Goal-G-008
epic: audit
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, game/tests/unit/test_pause_screen.gd, game/tests/unit/test_music_volume_slider.gd, game/tests/unit/test_sfx_volume.gd]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, game/tests/unit/test_pause_slider_saves.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
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

From the audit epic (formerly T-421, now part of goal G-008): the pause screen's zoom, SFX volume and music volume sliders call GameSettings' save on every value_changed, so a drag writes the settings file dozens of times. Keep applying the value live on value_changed (zoom changes the view, volume changes the bus at once), but save only when the drag ends (drag_ended with value_changed true), plus once when the pause screen closes (Escape, Restart, Exit), so a keyboard or click change is not lost. The SFX slider is hidden for the MVP (T-389) but keeps the same pattern. Write the rule into HUD and menus, Content, 'Pause screen', and game/docs/hud-and-menus/pause-screen.md, so the HUD size slider can follow it.

## Acceptance criteria

- [ ] A headless GUT test drags each of the zoom, SFX volume and music volume sliders through 20 values and counts the settings file writes: at most one per drag, made when the drag ends. (QA: pass / fail)
- [ ] Tests show the value is still applied live during the drag: the camera zoom and the SFX and Music bus volumes change on each value, before the drag ends. (QA: pass / fail)
- [ ] Tests show that closing the pause screen with Escape, Restart and Exit saves the current slider values. (QA: pass / fail)
- [ ] docs/hud-and-menus.md and game/docs/hud-and-menus/pause-screen.md state that the pause sliders save on release and on close. (QA: pass / fail)
- [ ] All three test sets pass (GUT, python -m unittest discover -s game/tools -p "test_*.py", and the tools tests), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-427.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

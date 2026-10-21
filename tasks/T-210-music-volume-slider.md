---
id: T-210
title: "The pause screen's music volume slider"
status: in-qa
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-208, T-209]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/README.md, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, tasks/T-208-text-music-volume-label.md, tasks/T-209-music-the-boards-two-tracks.md]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/scenes/, game/tests/unit/, game/README.md, docs/hud-and-menus.md, art-archive/T-210/screenshots/]
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

Add the music volume slider to the pause screen (HUD and menus, Decisions, 2026-10-20). Put it on its own row directly under the SFX volume slider, laid out exactly like it (label, slider of the same width, the value as a number at the right end), from 0 to 100. Its label is T-208's text, word for word, from HUD and menus, Content. It starts from T-209's saved music setting, changes the music's volume at once while the game is paused (the music keeps playing under the pause screen), and is saved between sessions. The pause strip stays as compact as the docs ask, below the HUD timer. Start from a branch that has both T-208 and T-209 merged.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] The pause screen shows the slider under "SFX volume", with T-208's label word for word, laid out like the SFX volume slider (screenshot) (QA: pass. Row directly under "SFX volume", same label column, slider width and right-end number.)
- [ ] Moving it changes the music's volume at once and not the sound effects', and the value is saved and loaded between sessions (tests) (QA: pass. test_music_volume_slider.gd covers applies at once, SFX bus untouched, saved and loaded; passes in the full suite.)
- [ ] The pause strip still sits below the HUD timer without overlapping it (screenshot) (QA: pass. Strip starts at y 92, timer ends about y 78, no overlap. The loosened limits (0.30 to 0.35, 0.45 to 0.5, y 300 to 340) stay within the "compact strip, only as tall as its content, below the timer" decision: one extra row (about 29 px), tests still assert content height and no overlap. Strip ends at about 322 of 648 with the dynamic-camera buttons, just under the new half-screen cap, so another row would not fit.)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass. GUT 1141/1141; tools unittest OK; game/tools 355 OK, 1 skipped.)

The board's review: pause during a run and move the music volume slider.
Board review files: the pause screen in a run.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started: the Music volume slider under SFX volume on the pause screen.

### 2026-10-21, In progress → In QA

Built: "Music volume" slider under SFX volume, saved, music only. Sent to QA.

## Result notes

Built: a "Music volume" slider (T-208's label) on its own row `MusicRow` directly under the SFX row in `game/scripts/ui/pause_screen.gd`, laid out like it (label of `LABEL_WIDTH`, same-width slider, number at the right end), 0 to 100. It starts from `GameSettings.load_music_volume()`, and each move saves (`save_music_volume`) and applies (`apply_music_volume`) to the Music bus at once, never the SFX bus. The music is not paused by the pause screen (T-209 plays it on the Music bus).

Proposals and notes:
- The strip is one row taller (about 29 px). Its test budgets were raised to fit: thin band below 0.35 of the screen height (was 0.30), ends above half the screen (was 0.45), and above y 340 with the dynamic-camera buttons (was 300). The strip still starts at `STRIP_TOP` 92, below the HUD timer. The board may want a tighter strip later.
- Tests: `game/tests/unit/test_music_volume_slider.gd` (label, range, start from saved value, applies at once, SFX untouched, saved, layout under SFX). Full GUT suite 1141/1141 pass; `python -m unittest discover -s tools` 414 OK; `-s game/tools` 355 OK (1 skipped).
- Ran Godot with GODOT_BIN read from the main checkout's .env (the worktree has no .env); no command was refused.
- Long GDD regeneration not run (done at merge by the Project Lead); docs/hud-and-menus.md and game/README.md updated.

Screenshots: `art-archive/T-210/screenshots/pause_music_slider.png` (paused run from the menu: "Music volume" row under "SFX volume", strip below the HUD timer; the board's saved settings had the dynamic camera on, so the tuning buttons show).

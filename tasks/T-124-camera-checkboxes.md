---
id: T-124
title: Pause screen: checkboxes for camera smoothing and the dynamic camera, and min/max buttons
status: in-progress
from: project-lead
to: ui
lead:
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, game/README.md, tasks/T-123-camera-options.md, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd]
files_expected_to_change: [game/scripts/ui/pause_screen.gd (and its scene), its tests, game/README.md, docs/hud-and-menus.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The pause screen (Escape) gets the board's two camera options and, for now, two tuning buttons (HUD and menus, Decisions, 2026-10-13). T-123 builds what they switch.

**Branch:** create your branch `task/T-124-camera-checkboxes` from T-123's branch (`task/T-123-camera-options`), not from master, in your own folder `C:\solid-carbide-worktrees\T-124`, once T-123 is in QA or later. The board playtests both from your folder. T-123 merges first, then this task.

1. **Two checkboxes** under the camera zoom slider: "Camera smoothing" and "Dynamic camera" (the board's own names for them, used as written; the two temporary tuning buttons below are labelled plainly as a tool for the board, not as game text). Their state comes from and goes to T-123's saved settings, and changing one applies at once.
2. **Two tuning buttons for the board**, shown while "Dynamic camera" is on: "Set min zoom" and "Set max zoom". Each stores the zoom slider's current value as the dynamic camera's min or max (T-123's API). Next to them, show the stored min and max as numbers so the board can see what it saved. While the game is paused, moving the slider still previews that zoom, so the board can pick a value, press a button, and resume to try it. These buttons are a temporary tuning tool: they are removed once the board has settled the values (a later task).
3. The strip stays compact and clear of the HUD timer and the HUD (HUD and menus, Decisions); the checkboxes and buttons work with mouse and keyboard.
4. Update HUD and menus, Content (the pause screen) and game/README.md.

## Acceptance criteria

- [ ] GUT tests show both checkboxes are on the pause screen, start from the saved settings, and switch the options on and off at once (QA: pass / fail)
- [ ] GUT tests show "Set min zoom" and "Set max zoom" appear only while the dynamic camera is on, store the slider's current value through T-123's API, and that the shown numbers update (QA: pass / fail)
- [ ] A screenshot of the pause screen in a run, with the dynamic camera on, shows the slider, both checkboxes, both buttons and the stored values, clear of the HUD (QA: pass / fail)
- [ ] HUD and menus, Content, and game/README.md describe the new controls (QA: pass / fail)
- [ ] T-123's tests, the pause screen and screen flow tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the run with both options, tune the dynamic camera's min and max with the buttons, and judge the feel (together with T-123).

## Result notes

- 2026-10-13, open → blocked: starts once T-123 is in QA; builds on T-123's branch
- 2026-10-13, blocked → open: T-123 is in QA; T-124 builds on its branch

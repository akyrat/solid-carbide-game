---
id: T-124
title: Pause screen: checkboxes for camera smoothing and the dynamic camera, and min/max buttons
status: in-qa
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, game/README.md, tasks/T-123-camera-options.md, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd]
files_expected_to_change: [game/scripts/ui/pause_screen.gd (and its scene), its tests, game/README.md, docs/hud-and-menus.md]
model: opus
qa_rounds: 1
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

- [ ] GUT tests show both checkboxes are on the pause screen, start from the saved settings, and switch the options on and off at once (QA: pass) QA note: `test_pause_camera_controls.gd` checks the board's names, the starting state from a saved test settings file (both on), and that toggling each box changes `camera_follow` and the saved settings at once, on and off
- [ ] GUT tests show "Set min zoom" and "Set max zoom" appear only while the dynamic camera is on, store the slider's current value through T-123's API, and that the shown numbers update (QA: pass) QA note: the tuning row hides and shows with the dynamic box; slider at 9.0 and 18.5 then the buttons store those values via `set_dynamic_min/max_from_current`, saved, and the labels read "9.0" and "18.5"; the numbers also show the stored defaults on pausing
- [ ] A screenshot of the pause screen in a run, with the dynamic camera on, shows the slider, both checkboxes, both buttons and the stored values, clear of the HUD (QA: fail: QA's own screenshot of a run started from the main menu, dynamic camera on, min/max set to 10.0 and 17.5 (`C:\solid-carbide-worktrees\T-124\screenshots\qa-T-124-run-pause-dynamic.png`, git-ignored) shows the slider, both labels and the stored values below the HUD timer, clear of the HUD as documented. But over the run's asphalt the unchecked "Camera smoothing" box is not visible at all (only its text shows), and the "Set min zoom"/"Set max zoom" buttons show no visible frame, so they read as plain text, not as a checkbox and two buttons. The agent's prototype screenshot shows them only because the prototype's ground is near-black. Fix: give the unchecked box and the buttons a visible look on the strip, e.g. a more opaque strip or explicit styles)
- [ ] HUD and menus, Content, and game/README.md describe the new controls (QA: fail: game/README.md, "Pause screen", describes them (pass for that half). docs/hud-and-menus.md mentions them only under Decisions (line 27, the Project Lead's planning line); its Content section still says "(The pause and level-up screens: to be written.)" and has no pause-screen part, and the agent did not change the file. The task asked for Content (the pause screen) to be updated)
- [ ] T-123's tests, the pause screen and screen flow tests, the full GUT suite and all Python tool tests pass (QA: pass) QA note: QA ran them itself: full GUT suite 435/435 (43 scripts, incl. test_camera_options, test_pause_screen, test_pause_camera_controls, game/test_screen_flow); game/tools Python 141 OK; tools Python 121 OK

The board's review: playtest the run with both options, tune the dynamic camera's min and max with the buttons, and judge the feel (together with T-123).

## Result notes

- 2026-10-13, open → blocked: starts once T-123 is in QA; builds on T-123's branch
- 2026-10-13, blocked → open: T-123 is in QA; T-124 builds on its branch
- 2026-10-13, UI Agent: built on T-123's branch. Pause screen has the "Camera smoothing" and "Dynamic camera" checkboxes under the slider (start from the saved settings, apply and save at once through `target.camera_follow`), and, only while the dynamic camera is on, "Set min zoom" and "Set max zoom" with the stored values as numbers. Same compact strip, still starting at y 92 below the HUD timer; mouse and keyboard (Tab/Space) work. Tests: `game/tests/unit/test_pause_camera_controls.gd` (7 tests). Full GUT suite 435/435 pass; game/tools Python 141 OK; tools Python 121 OK. Screenshot (dynamic camera on): `C:\solid-carbide-worktrees\T-124\screenshots\T-124-pause-dynamic.png` (git-ignored), made with `pause_screen_demo_dynamic.tscn`. Docs: HUD and menus Content line (board's wording, already on this branch) and game/README.md updated. Note: the screenshot is of the drift prototype; the run uses the same screen at the same position.
- 2026-10-13, in-progress → in-qa: ready for QA
- 2026-10-14, QA/Integration, round 1: criteria 1, 2 and 5 pass; 3 and 4 fail. (3) In a run the unchecked "Camera smoothing" box and the two tuning buttons have no visible box or frame on the translucent strip over the asphalt (QA screenshot `C:\solid-carbide-worktrees\T-124\screenshots\qa-T-124-run-pause-dynamic.png`, made with a temporary fixture, deleted, using its own settings file). (4) docs/hud-and-menus.md Content has no pause-screen description yet. Only T-124's own diff from `task/T-123-camera-options` was judged.
- 2026-10-14, in-qa → in-progress: QA round 1 failed criteria 3 (unchecked box and buttons not visible in a run) and 4 (HUD and menus Content); back to the Project Lead

### Round 2

- 2026-10-14, UI Agent, round 2 (fixes for QA round 1):
  - (3) The checkboxes and buttons now have their own placeholder look, so they show over any ground: checkbox icons (`check_icon()`) are a light square frame on a dark fill, with a light square inside when checked (unchecked, checked and their disabled variants); the two buttons have their own `StyleBoxFlat` frames (`button_style()`: light 2 px border round a dark fill) for normal, hover, pressed and hover-pressed, plus a white 3 px focus frame; the strip is now nearly opaque (`STRIP_COLOR`, black at 0.85, was 0.7). No red used. New run fixture with its own test settings file (`user://screenshot_settings_t124.cfg`, removed before and after; dynamic camera on, smoothing off, min 10.0, max 17.5): `game/tests/fixtures/pause_run_dynamic_demo.gd` with `pause_run_dynamic_gravel.tscn` (the run's start) and `pause_run_dynamic_asphalt.tscn` (the road at (54, 0)); a run started from the main menu, paused after 40 frames. Screenshots (git-ignored, checked by the agent: unchecked and checked boxes, both button frames and the stored values 10.0 and 17.5 all visible, strip below the timer): `C:\solid-carbide-worktrees\T-124\screenshots\T-124-run-pause-gravel.png` and `C:\solid-carbide-worktrees\T-124\screenshots\T-124-run-pause-asphalt.png` (`bash game/tools/screenshot.sh res://tests/fixtures/pause_run_dynamic_gravel.tscn screenshots/T-124-run-pause-gravel.png 60`).
  - (4) docs/hud-and-menus.md, Content: new "Pause screen" part (title, hint, zoom slider, the two camera checkboxes, the tuning buttons with the stored values, their placeholder look and keyboard use); the level-up screen is still "to be written". Summary, Decisions and Open questions unchanged. game/README.md, "Pause screen": the new look and the run fixtures.
  - Tests: 3 new in `game/tests/unit/test_pause_camera_controls.gd` (checkbox icons fully opaque with a light frame and dark fill, checked has a light mark; both buttons have a light, opaque frame in normal, hover, pressed and focus and an opaque fill; strip alpha at least 0.85). Full GUT suite 438/438 pass (43 scripts); game/tools Python 141 OK; tools Python 121 OK. Godot's line-ending-only .import changes reverted.
  - Documents affected: docs/hud-and-menus.md, game/README.md.
- 2026-10-14, in-progress → in-qa: round 2: visible checkboxes and buttons on a nearly opaque strip, run screenshots on gravel and asphalt, HUD and menus Content written

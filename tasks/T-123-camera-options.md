---
id: T-123
title: Camera options: smoothing and the dynamic camera (zoom follows speed)
status: in-progress
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, game/README.md, game/scripts/ui/game_settings.gd, game/scripts/ui/pause_screen.gd, game/scripts/run/run.gd, game/scripts/driving/drift_prototype.gd]
files_expected_to_change: [game/scripts/ui/game_settings.gd, the run's and the drift prototype's camera code (or a new camera script), their tests, game/README.md, docs/drifting.md]
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

The board wants to try two camera options (Drifting, Decisions, 2026-10-13), each switched on and off by a checkbox on the pause screen (T-124 adds the checkboxes; this task builds what they switch). Both are off by default, so the camera stays as it is now (exactly on the car, no smoothing) unless the player turns them on.

1. **Camera smoothing:** when on, the camera follows the car with a short smooth lag instead of sitting exactly on it. Propose the amount (for example Godot's position smoothing with a speed you pick) and keep it in one tunable place.
2. **Dynamic camera:** when on, the zoom follows the car's speed between a **min** and a **max** zoom: at very low speed the camera is zoomed in to the min; at 100% of the car's top forward speed it is zoomed out to the max; linear in between (a curve is fine if you say why). The zoom moves there smoothly with a short delay, never jumping (for example easing toward the target over about half a second to a second; propose the value). While it is on, it replaces the zoom slider's fixed zoom.
3. **The min and max are the board's to tune** in playtests: store them, with both checkbox states, in the saved settings (`game_settings.gd`, `user://settings.cfg`, next to the zoom), with proposed defaults within the slider's range (6 to 20; larger means more zoomed out), and give T-124 what it needs to set them: functions to set the min and the max from the current slider zoom, and to read them back. Also write the saved min and max to a small readable file or print them, so the Project Lead can copy the board's values into the game's defaults later.
4. Works in the run (including runs started from the main menu) and in the drift prototype; the pause screen's zoom slider keeps working when the dynamic camera is off.
5. Expose a clear API for T-124 (the checkbox states, set min, set max, read min and max) and describe it in game/README.md.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge: T-124 builds the pause screen controls on top of this task's branch, and the board playtests both together from T-124's folder.

## Acceptance criteria

- [ ] GUT tests show that with both options off the camera sits exactly on the car with the slider's zoom, as before (QA: pass / fail)
- [ ] GUT tests show smoothing on makes the camera lag behind a moving car and catch up when it stops (QA: pass / fail)
- [ ] GUT tests show the dynamic camera's target zoom is the min at standstill and the max at top forward speed, in between at half speed, and that the actual zoom eases toward the target rather than jumping (QA: pass / fail)
- [ ] GUT tests show both checkbox states, the min and the max are saved and loaded with the settings, and setting the min or max from the current zoom works (QA: pass / fail)
- [ ] docs/drifting.md (Content) and game/README.md describe both options, the defaults and the API (QA: pass / fail)
- [ ] The drift prototype, run and settings tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest both options from T-124's folder, tune the dynamic camera's min and max with T-124's buttons, and judge the feel.

## Result notes

Written by the agent when it finishes.

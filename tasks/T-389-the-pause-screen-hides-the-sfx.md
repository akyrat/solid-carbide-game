---
id: T-389
title: The pause screen hides the SFX volume slider for the MVP
status: needs-playtest
from: project-lead
to: ui
lead: Goal-G-007
epic: hud-menus
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: yes
depends_on: [T-388, T-386]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/pause-screen.md, game/docs/sound/sound-effects.md, game/scripts/ui/pause_screen.gd, game/tests/unit/test_pause_screen.gd, game/tests/unit/test_music_volume_slider.gd, game/docs/setup/screenshots.md]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/tests/unit/test_pause_screen.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md]
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

HUD and menus, Decisions, 'No sound effects in the MVP' (board, 2026-10-29): with every sound effect off (the switch from the SFX ticket), the pause screen hides its SFX volume slider row, and the strip's layout closes the gap. The music volume slider still shows and still changes the music. Keep the slider's code (hidden, not deleted), so it can come back with the sound effects. Take a pause screen screenshot.

The board's review: Pause a run and check the SFX slider is gone and the music slider still works.

## Acceptance criteria

- [ ] The SFX volume slider row is not visible in the pause screen, and the rows below it move up so no gap is left; a test checks the row is hidden and the layout. (QA: pass)
- [ ] The music volume slider still shows and moving it changes the music bus volume; a test covers it. (QA: pass)
- [ ] The SFX slider's code is still in pause_screen.gd (hidden, not deleted). (QA: pass)
- [ ] A pause screen screenshot is saved in art-archive/<task id>/screenshots/. (QA: pass)
- [ ] docs/hud-and-menus.md, Content, 'Pause screen' and the 'No sound effects in the MVP' decision note, and game/docs/hud-and-menus/pause-screen.md, record that the SFX are off and the slider hidden for the MVP. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Blocked → In progress

Goal runner (G-007): started, in C:\solid-carbide-worktrees\T-389.

### 2026-10-30, In progress → In QA

Goal runner (G-007): the agent is done; QA is checking it.

### 2026-10-30, In QA → Needs playtest

Goal runner (G-007): QA passed; merged into playtest/G-007.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (UI Agent).

- `game/scripts/ui/pause_screen.gd`: `_build_sfx_slider()` still builds the whole row (`SfxRow`, `sfx_slider`, `sfx_label`, saved value, bus apply), but sets `row.visible = GameSettings.sfx_enabled()` (the switch from T-388, off for the MVP). A hidden row takes no room in the strip's VBox, so the music row and the rows below move up. Music slider unchanged.
- Tests: new `test_sfx_row_hidden_with_the_switch_off_and_layout_closes_up` in `test_pause_screen.gd` (row hidden, music slider visible and directly under the zoom row with no gap, row back and music lower with the switch on). The existing music slider tests already run with the switch forced on and cover moving the slider changing the Music bus (`test_moving_it_changes_the_music_only_and_saves`); I did not add music-bus tests for the switch-off case beyond the visibility check. Two tests in `test_screen_flow.gd` that look at the SFX row now force the switch on (`sfx_enabled_override = 1`, reset in `after_each`).
- Fixture fix: `tests/fixtures/pause_from_menu_demo.gd` pressed the menu's Start, which now opens the tutorial slides, so it errored; it now calls `game.start_run()`. `pause_trick_list_demo.gd` has the same stale call (not touched, not in scope).
- Docs: `docs/hud-and-menus.md` (Content, new "SFX volume slider, hidden for the MVP" entry, and the 'No sound effects in the MVP' decision note marked done by T-389); `game/docs/hud-and-menus/pause-screen.md` (new T-389 entry).
- Test counts: GUT 1973/1973 passed; `game/tools` Python 675 tests OK (1 skipped); `tools` Python 573 tests OK.
- Screenshot: `art-archive/T-389/screenshots/pause.png` (pause screen: zoom and music rows only, no gap).
- Documents affected: docs/hud-and-menus.md, game/docs/hud-and-menus/pause-screen.md. No PixelLab generations; no refusals.

QA round 1 (QA agent): all six criteria pass. Re-ran GUT 1973/1973, game/tools Python 675 OK (1 skipped), tools Python 573 OK. Row hidden via `sfx_enabled()` in pause_screen.gd (code kept), screenshot and both docs present. `tools/qa_check.py` was refused (not pre-approved), so its paperwork lines were checked by hand.
- 2026-10-30, in-qa → needs-playtest: QA passed every criterion (goal G-007).

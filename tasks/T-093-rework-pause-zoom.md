---
id: T-093
title: Rework (T-015): zoom label, and see the zoom change while moving the slider
status: done
from: project-lead
to: ui
lead:
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-015]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, tasks/T-015-pause-on-escape.md, tasks/T-047-text-pause-screen.md, game/README.md, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [the pause screen scene and script, tests, game/README.md]
model: sonnet
qa_rounds: 2
---

<!--
status: needs-playtest | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's feedback after Playtest 1 (2026-10-11) on the pause screen built in T-015:

1. **Label:** the zoom slider's label is **Camera zoom level** (the board's own wording; T-047's board note). Replace "Camera zoom, for the fans".
2. **See the zoom change live:** while the board moves the slider on the pause screen, the game view behind must visibly zoom in and out at once. Today the change isn't visible while paused. Keep the game paused (nothing moves), but make sure the camera zoom updates immediately and the view behind the pause screen can be seen (for example by keeping the pause screen's backdrop see-through or to one side).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot of the paused run shows the label "Camera zoom level" and the map visible behind the pause screen (QA: pass / fail)
- [ ] A test moves the slider while paused and shows the camera's zoom changes at once, while the car and the clock stay paused (QA: pass / fail)
- [ ] Two screenshots at different slider values, both paused, show the view zoomed differently (QA: pass / fail)
- [ ] T-015's tests still pass (with the new label) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Done by the UI Agent. Changes:
- Label is now "Camera zoom level" (pause_screen.gd).
- Cause of the invisible zoom: the camera updates in the physics step (and with physics interpolation), which does not run while paused. While paused the pause screen now makes the camera update every frame (idle callback, interpolation off, always processing) and restores it on resume. Works for both the drift prototype and the run, as both use the pause screen's `target.camera`.
- Pause screen layout: the panel is a dark strip at the top and the dim over the map is light (0.2), so the map stays visible behind it.
- Tests: test_pause_screen.gd (label updated; new live-zoom test in the prototype) and tests/unit/game/test_screen_flow.gd (new test in a run started from the main menu: view scale changes at once, car and clock stay paused). Full GUT suite 225/225 passes; Python tool tests OK.
- Screenshots (not committed): pause_screen_demo.tscn, _in (slider 7) and _out (slider 19) fixtures; the two paused views differ clearly in zoom and the map is visible.
- Documents updated: docs/hud-and-menus.md, game/README.md.

### QA round 1

Checked by the QA/Integration Agent. Own screenshots (not committed) were taken in a run started from the main menu, paused, with the slider set to 7 and to 19.

- [x] Label "Camera zoom level" and the map visible behind the pause screen: PASS. `TEXT_ZOOM_LABEL` is exactly "Camera zoom level", and it shows in both screenshots. The map is visible below the top strip; the dim is light.
- [x] Test moves the slider while paused, zoom changes at once, car and clock stay paused: PASS. `test_the_zoom_slider_zooms_the_view_at_once_while_a_run_is_paused` (run from the main menu) and the prototype test pass; they check the drawn canvas scale, the car position and the clock.
- [x] Two screenshots at different slider values show different zoom: PASS. At 7 the view is close on the car; at 19 it is far out, with the map and its challenges visible.
- [x] T-015's tests still pass: PASS. test_pause_screen.gd passes with the new label. After resume, the camera's process mode, callback (physics) and physics interpolation mode were checked with a throwaway test (not committed) and are restored to their old values; the T-029 tests pass in the full suite.
- [x] Full GUT suite and Python tests: PASS. GUT 225/225 (TESTS PASSED), `game/tools` Python tests 62 OK, `tools` Python tests 75 OK.

Notes for the Project Lead (not failures): the HUD's run timer ("8:00") draws over the "Paused" title at the top of the screen, so the two overlap; there is no committed test for the camera being restored on resume.

### Rework after QA

The pause strip drew over the HUD run timer. The strip now keeps 100 px free above its content (`STRIP_TOP_MARGIN`), so the title sits below the timer. New tests in `tests/unit/game/test_screen_flow.gd`: the title does not overlap the timer, and the camera settings are restored on resume. Full GUT suite and Python tests pass.

### QA round 2

Checked by the QA/Integration Agent after commit 8b95b79. Own screenshots (not committed; throwaway fixture removed) of a run started from the main menu, then paused, at slider 19 (the saved default) and 7.

- [x] Label "Camera zoom level" and the map visible behind the pause screen: PASS. The label shows in the screenshots, the map and challenges are visible below the top strip, and the HUD timer "8:00" now sits above the "Paused" title with no overlap.
- [x] Test moves the slider while paused, zoom changes at once, car and clock stay paused: PASS. `test_the_zoom_slider_zooms_the_view_at_once_while_a_run_is_paused` and the prototype test pass in the full suite.
- [x] Two screenshots at different slider values show different zoom: PASS. At 7 the view is close on the car; at 19 it is zoomed out with the map visible.
- [x] T-015's tests still pass: PASS. test_pause_screen.gd passes; the new tests for the title not overlapping the timer and the camera settings restored on resume also pass.
- [x] Full GUT suite and Python tests: PASS. GUT 227/227 (TESTS PASSED), `game/tools` Python tests 62 OK, `tools` Python tests 75 OK.

All criteria pass; status set to needs-playtest.

### Board review

Merged on QA's pass (round 2), 2026-10-11, for the board's combined playtest.

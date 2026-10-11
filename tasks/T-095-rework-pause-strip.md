---
id: T-095
title: Rework (T-093): a compact pause strip
status: in-qa
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-093]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, tasks/T-093-rework-pause-zoom.md, game/README.md, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [the pause screen scene and script, tests, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's feedback after the combined playtest (2026-10-11): the pause screen's semi-transparent black strip now covers the whole top half of the screen. Make it compact: only as tall as its content ("Paused", the hint, and the "Camera zoom level" slider), placed just below the HUD timer so the two still don't overlap, with as much of the map visible as possible. Everything T-093 fixed must keep working (the live zoom while paused, the label, no overlap with the timer).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot of a paused run (started from the main menu) shows the strip covering only a thin band below the timer, with most of the map visible (QA: pass / fail)
- [ ] A test shows the strip's height is no more than its content needs (for example under a quarter of the screen height) and it doesn't overlap the timer (QA: pass / fail)
- [ ] T-093's and T-015's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Done by the UI Agent. The strip was tall because it reserved 100 px of empty space above its content for the timer. It now starts just below the timer (`STRIP_TOP` = 92 px) and is only as tall as its content (about 111 px of 648, 17%); title, hint and the zoom label, slider and value (now on one row) are tighter. The map is visible above and below it. Test `test_the_pause_strip_is_compact_and_below_the_timer` (test_screen_flow.gd): no overlap with the timer, under a quarter of the screen, height equals its content's minimum. Fixture `pause_from_menu_demo.tscn` for the screenshot of a paused run started from the main menu (own screenshot checked, not committed). Full GUT suite passes (TESTS PASSED), Python tool tests OK.
Documents updated: docs/hud-and-menus.md, game/README.md.

---
id: T-090
title: HUD: the run timer
status: needs-playtest
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-036, T-048]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-048-text-hud.md, game/README.md]
files_expected_to_change: [the HUD scene and script, the run scene, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 1
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

The first piece of the HUD (HUD and menus, Decisions), for the board's first playable build (2026-10-10): the run timer, counting down from 8:00 in minutes and seconds, shown during the run. The run (T-036) owns the time; the HUD only shows it (`time_left_changed`, `time_left_text()`). Kept plain for the MVP.

Build it as the HUD scene the rest of the HUD (T-049) will be added to, placed in the run scene. The timer is digits only and needs no text (T-048).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test changes the run's time left and shows the HUD shows it as M:SS, from 8:00 down to 0:00 (QA: pass / fail)
- [ ] A screenshot of the run shows the timer (QA: pass / fail)
- [ ] A test shows the timer stops while the game is paused (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes the HUD in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Built (UI Agent): the HUD scene `game/scenes/hud/hud.tscn` with `game/scripts/hud/hud.gd` (`Hud`, a CanvasLayer), added by `run.gd` and bound to the run state (`run.hud`). It shows only the timer, M:SS in big cyan digits at the top centre, following `time_left_changed` and `time_left_text()`. Because the run scene creates it, the timer shows in every run, also one started from the main menu (T-055); a test covers that path.

Tests (`game/tests/unit/hud/test_hud_timer.gd`): starts at 8:00; the label follows time left from 8:00 to 0:00; resets on a fresh run; stops while paused; shows in a run started through the screen flow. Full GUT suite: 198 passing, TESTS PASSED. Python tool tests: 62 OK. Screenshot: `screenshots/run_timer.png` (git-ignored) shows 8:00 at the top.

Documents updated: `docs/hud-and-menus.md` (new "The HUD" in Content only), `game/README.md` ("The run": the HUD paragraph). The master merge (T-055) was clean.

### QA round 1

All criteria pass.

- [x] Test shows M:SS from 8:00 down to 0:00: PASS. `test_timer_follows_the_run_from_8_00_to_0_00` steps time left through 8:00, 7:00, 6:59, 1:01, 1:00, 0:09, 0:01, 0:00 and the label matches `time_left_text()`; the start state and a fresh run both show 8:00.
- [x] Screenshot of the run shows the timer: PASS. QA's own screenshot: launched the project's main scene (`game.tscn`, the main menu), sent a real Enter key press to the focused Start button, and captured the run after 200 frames (`screenshots/qa_run_timer.png`, git-ignored). It shows big cyan "8:00" at the top centre over the map and car; the run was present, the menu gone, and the label read 8:00 (about 0.8 s of run time had elapsed).
- [x] Timer stops while paused: PASS. `test_timer_stops_while_paused` shows the clock runs unpaused, then after pausing for 30 frames neither time left nor the label moves, and it runs again on unpause.
- [x] `docs/hud-and-menus.md`: PASS. `git diff master...HEAD` adds only a "The HUD" subsection under Content (4 lines); Summary, Decisions and Open questions are unchanged. `game/README.md` is also updated.
- [x] Full GUT suite and Python tests: PASS. GUT: 198 of 198 passing, TESTS PASSED. Python: `game/tools` 62 OK, `tools` 75 OK.

Note: the working tree shows modified `addons/gut/fonts/*.import` files after Godot's import; QA did not commit them.

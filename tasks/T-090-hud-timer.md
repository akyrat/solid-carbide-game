---
id: T-090
title: HUD: the run timer
status: in-qa
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

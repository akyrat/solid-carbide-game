---
id: T-054
title: The main menu: title, Start, Garage, Exit
status: in-qa
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-053]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-053-text-main-menu.md, game/README.md]
files_expected_to_change: [the main menu scene and script, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-qa | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-053 (the button text) is done.**

Build the main menu (HUD and menus and Game loop architecture, Decisions), kept plain for the MVP:
- The title "SOLID CARBIDE" in big letters, with a discreet "(work in progress)" under it.
- Three buttons, with T-053's text: Start, Garage and Exit. Each sends a signal; what happens next is the screen flow (T-055).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot shows the title, the "(work in progress)" line and the three buttons (QA: pass / fail)
- [ ] A test shows the button labels are exactly T-053's text (QA: pass / fail)
- [ ] A test presses each button and shows its signal fires (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes the menu in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Built the main menu: `game/scenes/menu/main_menu.tscn` and `game/scripts/menu/main_menu.gd`. A dark background, "SOLID CARBIDE" in big cyan letters, a small grey "(work in progress)" under it, and three buttons with the approved text (Start, Garage, Exit). Each button emits `start_pressed`, `garage_pressed` or `exit_pressed`. The project's main scene is unchanged.

- Tests: `game/tests/unit/test_main_menu.gd` (5 tests: title and subtitle, exact button text, each signal). Full GUT suite: 105 of 105 pass.
- Python tool tests: 3 of 51 fail in `test_build_mvp_map.py` (KeyError 'boulders'). They fail the same way on `master` without this task's changes, so they are not caused by it.
- Screenshot: `screenshots/main_menu.png` (git-ignored) shows the title, the work-in-progress line and the three buttons.
- Documents updated: `docs/hud-and-menus.md` (Content only), `game/README.md` (Main menu).

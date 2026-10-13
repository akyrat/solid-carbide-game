---
id: T-116
title: HUD: hide the combo counter when there is no combo
status: done
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, tasks/T-083-hud-combo-and-trick-popups.md, tasks/T-113-hud-vertical-health-and-likes-bars.md, game/README.md]
files_expected_to_change: [game/scripts/hud/hud.gd, the HUD's tests, game/README.md, docs/hud-and-menus.md]
model: sonnet
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

The board's decision (HUD and menus, Decisions, 2026-10-13): when the combo multiplier is at "no combo" (x1.0), the combo counter is hidden. It shows again as soon as a trick raises the multiplier, and hides again once the combo has drained back to x1.0 (T-081's drain). It also starts hidden in a new run.

**Branch:** build this on top of T-113, which is waiting for the board's playtest and moved the combo counter to above the likes bar. Create your branch `task/T-116-hide-combo-at-no-combo` from `task/T-113-hud-vertical-bars` (not from master), in your own folder `C:\solid-carbide-worktrees\T-116`, so the board playtests both changes together from your folder. T-113 is merged first, then this task.

1. Hide the counter when the multiplier is at the "no combo" value (read it from the combo data, not a hard-coded 1.0); show it when it is above.
2. Hiding must not move anything else on the HUD (the likes row and bar stay where they are).
3. Update HUD and menus, Content, "The HUD", and game/README.md.

## Acceptance criteria

- [x] GUT tests show the combo counter is hidden at the start of a run and whenever the multiplier is at "no combo", shown with the right text after a trick, and hidden again once the combo has drained back (QA: pass)
- [x] GUT tests show the other HUD elements keep their positions whether the counter is shown or hidden, and T-113's layout tests still pass (QA: pass)
- [x] Two screenshots of a run started from the main menu show the counter hidden with no combo and shown with a combo (QA: pass)
- [x] HUD and menus, Content, "The HUD", and game/README.md say the counter is hidden at no combo (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest a run (together with T-113's layout) and judge the counter appearing and disappearing.

## Result notes

UI Agent, 2026-10-13. Branch `task/T-116-hide-combo-at-no-combo`, made from `task/T-113-hud-vertical-bars` (T-113's layout included), folder `C:\solid-carbide-worktrees\T-116`.

**What was built**
- `game/scripts/hud/hud.gd`: the combo counter starts hidden, and on every `combo_changed` its text is updated and it is shown only when `Hud.show_combo(multiplier)` is true: the multiplier is above "no combo", read from combo.json's `start_multiplier` through `ComboData` (not a hard-coded 1.0). The comparison is at the two decimals the counter shows, so a combo that would read "x1.0" stays hidden. Only `visible` changes; every HUD element keeps its own fixed place, so nothing else moves, and the counter always appears in the same place (centred above the likes row).
- New tests `game/tests/unit/hud/test_hud_combo_hidden.gd` (9 tests): the no-combo value comes from the combo data; hidden at the start of a run; shown after a trick with the right text ("Combo x1.5", "Combo x1.55", and "Combo x1.05" after the smallest trick); still shown while draining, hidden once drained back to the start value, shown again by the next trick; shown after a collision that leaves it above no combo; hidden again in a new run; the health bar, its label, the likes bar, likes row, heart, "Likes", "Hype Lv", timer and coins keep exactly the same rectangles with the counter shown and hidden; and the same in a run started from the main menu.
- New screenshot fixture `game/tests/fixtures/hud_no_combo_from_menu_demo.tscn` (a run from the main menu with damage, likes and coins but no trick).

**Screenshots** (git-ignored, in this folder): `C:\solid-carbide-worktrees\T-116\screenshots\t116_no_combo.png` (no combo: no counter above the likes row) and `C:\solid-carbide-worktrees\T-116\screenshots\t116_combo.png` (combo x1.75: the counter shows above the likes row, the row and bar in the same place). To retake them, from the folder: `bash game/tools/screenshot.sh res://tests/fixtures/hud_no_combo_from_menu_demo.tscn screenshots/t116_no_combo.png 30` and `bash game/tools/screenshot.sh res://tests/fixtures/hud_from_menu_demo.tscn screenshots/t116_combo.png 30`.

**Tests:** full GUT suite 339/339 passing (`bash game/tools/run_tests.sh`), including T-113's layout tests and the existing combo tests; Python tool tests: `game/tools` 125 passed, `tools` 115 passed.

**Documents affected (updated):** `docs/hud-and-menus.md` (Content, "The HUD": the counter is hidden at no combo; Decisions: master's line "The combo counter is hidden when there is no combo ..." taken word for word for a clean merge) and `game/README.md` (the HUD section: `show_combo`, the new test file and the no-combo screenshot fixture). Godot's line-ending-only `.import` changes were not committed.

**QA round 1** (QA/Integration Agent, 2026-10-13), judging only T-116's diff from `task/T-113-hud-vertical-bars`:
1. Pass. `test_hud_combo_hidden.gd` reads "no combo" from `ComboData.start_multiplier()` (and `show_combo` reads it from combo data, not a hard-coded 1.0), checks hidden at run start, shown with "Combo x1.5", "x1.55" and "x1.05" after tricks, still shown mid-drain ("x1.25"), hidden once `state.combo` equals the start value, shown again by the next trick, and hidden after `start_run()`.
2. Pass. `test_hiding_moves_nothing_else` compares the global rects of the health bar, "Car Health", likes bar, likes row, heart, "Likes", "Hype Lv", timer and coins with the counter hidden, shown and hidden again; `test_hud_layout.gd` (T-113) passes.
3. Pass. `screenshots/t116_no_combo.png` (from the main menu, no counter above the likes row) and `screenshots/t116_combo.png` ("Combo x1.75" above the row); the likes row and bar are in the same place in both.
4. Pass. HUD and menus, Content, "The HUD" and `game/README.md` say the counter is hidden at no combo; the Decisions section is identical to master's.
5. Pass. GUT 339/339 (36 scripts), `game/tools` 125 passed, `tools` 115 passed, run by QA.
- 2026-10-13, needs-playtest → done: LGTM (board playtest, 2026-10-13)

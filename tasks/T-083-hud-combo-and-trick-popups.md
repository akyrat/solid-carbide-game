---
id: T-083
title: HUD: the combo counter, and the combo amount on trick popups
status: done
from: project-lead
to: ui
lead:
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-081, T-091, T-049]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-081-combo.md, tasks/T-082-text-combo.md, tasks/T-049-hud-run-values.md, game/README.md]
files_expected_to_change: [the HUD scene and script, the popup scene, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-081 (the combo), T-091 (the trick popups) and T-049 (the HUD) are done.** T-082's text is done.

As HUD and menus, Decisions describes:
1. **Combo counter** next to the likes bar, showing the current multiplier with T-082's label.
2. **What each trick added:** T-091's trick popups gain the amount the trick added to the multiplier, from T-081's signal, with T-082's `combo.added` text. Placeholder comic styling for now (a bold font and a simple shape behind it); the final comic look is T-084's art.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test changes the multiplier and shows the counter shows it, with T-082's label (QA: pass)
- [x] A test sends each of T-081's trick signals and shows the popup also shows the amount added, in T-082's `combo.added` text (QA: pass)
- [x] Screenshots show the counter and a popup for each trick (QA: pass)
- [x] `docs/hud-and-menus.md` describes both in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

UI Agent, built on branch task/T-083-hud-combo.

- Combo counter: `combo_label` in `game/scripts/hud/hud.gd`, to the right of the likes row, showing "Combo x{multiplier}" (T-082 text) from the run state's `combo_changed` (`Hud.combo_text()`, up to two decimals, e.g. "Combo x1.0", "Combo x2.5", "Combo x3.05"). Placeholder look: bold pink, dark outline, not red; clear of the timer, coins and health bar.
- Trick popups: `TrickPopups.bind_combo()` (run binds it) shows each trick from `combo_trick` as "NAME +amount" in T-082's `combo.added` text (`trick_text()`): "LONG DRIFT! +0.05", "FULL 360! +0.25", "ALT DRIFT! +0.5". At the cap (`added` 0) only the name shows, no "+0". Once bound, the car's own `trick` signal no longer makes a popup (so no double popups); the drift prototype is unchanged (names only).
- Tests: new `game/tests/unit/hud/test_hud_combo.gd` (7 tests); two assertions in `test_trick_popups.gd` updated for the amount. Full GUT suite 284/284 and Python tool tests 67/67 pass.
- Screenshot fixture `game/tests/fixtures/combo_demo.tscn`; I looked at `screenshots/combo.png` (a run from the main menu, combo x3.05, one popup per trick): counter and popups readable, nothing overlaps the timer, coins or health bar.
- Docs: `docs/hud-and-menus.md` (Content only), `game/README.md`.

### QA round 1

QA/Integration Agent, on branch task/T-083-hud-combo at 54b13fb.

- Criterion 1, the counter shows the multiplier with T-082's label: pass. `test_hud_combo.gd` raises the multiplier through real `add_trick` calls and checks "Combo x1.0", "x1.5", "x1.75", "x1.8", a collision, and "x6.0" at the cap. The template is exactly T-082's `Combo x{multiplier}`.
- Criterion 2, each trick signal's popup shows the amount in T-082's `combo.added` text: pass. The test emits each of the car's three trick signals in a run and gets exactly one popup each: "LONG DRIFT! +0.05", "FULL 360! +0.25", "ALT DRIFT! +0.5". At the cap only the name shows. `+{amount}` and the three names match T-082 exactly.
- Criterion 3, screenshots of the counter and a popup for each trick: pass. I took my own screenshot of `combo_demo.tscn`, a run started from the main menu (game.tscn): "Combo x3.05" sits right of the likes row, and there is one popup per trick with its amount. Nothing overlaps the timer, the health bar, the likes row or the coins. The counter is pink, and the HUD heart is the only red. I also took a paused screenshot. The pause strip (STRIP_TOP 92, from T-093/T-095) draws over the lower half of the counter, the same way it already covers the likes row and likes bar on master. Nothing draws over the strip's own text, and the pause screen still reads. This is a note for the Project Lead, not a failure.
- Criterion 4, `docs/hud-and-menus.md` changes only Content: pass. `git diff master...HEAD` changes two lines, 35 and 43, both inside "## Content" (lines 25 to 46). Summary, Decisions and Open questions are unchanged.
- Criterion 5, the full GUT suite and all Python tool tests pass: pass. GUT: 284/284, TESTS PASSED, exit 0. `python -m unittest discover -s tools`: 75 OK. `-s game/tools`: 67 OK.

Extra checks:
- A temporary test, not committed, started a run from the main menu with game.tscn and drove the real car with scripted input, which gave real extended-drift and 360 tricks. Each `combo_trick` gave exactly one popup with the right amount, and the counter matched the multiplier. `damage_car` and `collision` lowered the multiplier and the counter followed. All of this still held after the run ended, the menu came back and a new run started, and again after `start_run()` inside the same run.
- The two changed assertions in `test_trick_popups.gd` are sound. One loosens an exact-name check to "the name comes first", and the exact amounts are covered in `test_hud_combo.gd`. The other updates the second-run check to the new text "FULL 360! +0.25". The drift prototype is unaffected: the temporary test drove its car and saw names only ("LONG DRIFT!", "FULL 360!"), with no amounts, because the prototype never calls `bind_combo`.

### Board review

Merged on QA's pass, 2026-10-11.

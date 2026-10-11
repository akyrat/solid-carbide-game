---
id: T-083
title: HUD: the combo counter, and the combo amount on trick popups
status: in-qa
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-081, T-091, T-049]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-081-combo.md, tasks/T-082-text-combo.md, tasks/T-049-hud-run-values.md, game/README.md]
files_expected_to_change: [the HUD scene and script, the popup scene, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 0
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

- [ ] A test changes the multiplier and shows the counter shows it, with T-082's label (QA: pass / fail)
- [ ] A test sends each of T-081's trick signals and shows the popup also shows the amount added, in T-082's `combo.added` text (QA: pass / fail)
- [ ] Screenshots show the counter and a popup for each trick (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes both in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

UI Agent, built on branch task/T-083-hud-combo.

- Combo counter: `combo_label` in `game/scripts/hud/hud.gd`, to the right of the likes row, showing "Combo x{multiplier}" (T-082 text) from the run state's `combo_changed` (`Hud.combo_text()`, up to two decimals, e.g. "Combo x1.0", "Combo x2.5", "Combo x3.05"). Placeholder look: bold pink, dark outline, not red; clear of the timer, coins and health bar.
- Trick popups: `TrickPopups.bind_combo()` (run binds it) shows each trick from `combo_trick` as "NAME +amount" in T-082's `combo.added` text (`trick_text()`): "LONG DRIFT! +0.05", "FULL 360! +0.25", "ALT DRIFT! +0.5". At the cap (`added` 0) only the name shows, no "+0". Once bound, the car's own `trick` signal no longer makes a popup (so no double popups); the drift prototype is unchanged (names only).
- Tests: new `game/tests/unit/hud/test_hud_combo.gd` (7 tests); two assertions in `test_trick_popups.gd` updated for the amount. Full GUT suite 284/284 and Python tool tests 67/67 pass.
- Screenshot fixture `game/tests/fixtures/combo_demo.tscn`; I looked at `screenshots/combo.png` (a run from the main menu, combo x3.05, one popup per trick): counter and popups readable, nothing overlaps the timer, coins or health bar.
- Docs: `docs/hud-and-menus.md` (Content only), `game/README.md`.

---
id: T-115
title: The likes bar drains when the combo has drained
status: done
from: project-lead
to: game-loop
lead:
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-114]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, tasks/T-037-likes-and-levels.md, tasks/T-081-combo.md, tasks/T-114-likes-drain-data.md, game/README.md]
files_expected_to_change: [the run's scripts, their tests, game/README.md, docs/game-loop-architecture.md]
model: opus
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

The board's decision for the MVP (Game loop architecture, Decisions, "Likes drain", 2026-10-13): when the player stops doing tricks, the likes bar slowly empties, but never below the start of the current level, so the player never loses a level.

1. **When:** the drain runs while the combo is fully drained (the run's combo multiplier is at "no combo", after its own 2-second wait and drain, T-081), plus any extra wait T-114 provides. Any trick raises the combo and stops it; it starts again once the combo has drained again.
2. **How much:** at T-114's speed, read from `run_data.gd`. XP in the current level goes down toward 0 and stops there: the level never goes down. At the top level (bar full and stopped), decide whether the drain applies and write it in the result notes; the simplest is that it does not.
3. **HUD:** the HUD already follows the run's XP signal; make sure the drain sends it, so the likes bar visibly empties. No HUD layout changes (T-113 owns the layout).
4. No drain while the run is paused (the level-up screen, the pause screen) or after the run has ended.
5. Update Game loop architecture, Content, "Likes and levels", and game/README.md.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] GUT tests show: with the combo above "no combo", XP does not drain; once the combo is back to "no combo", XP goes down at T-114's speed; a trick stops the drain (QA: pass)
- [x] GUT tests show XP never goes below 0 within the current level and the level never goes down, including when the drain runs for a long time (QA: pass)
- [x] GUT tests show no drain while the run is paused or after it has ended, and that the HUD's XP signal fires as XP drains (QA: pass)
- [x] Two screenshots a few seconds apart in a run show the likes bar emptying with no tricks, and stopping at empty with the level unchanged (QA: pass)
- [x] Game loop architecture and game/README.md describe the drain (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest a run and judge how the drain feels (speed, when it starts).

## Result notes

- 2026-10-13, open → blocked: waits for T-114

**Game Loop Agent, 2026-10-13.** Branch `task/T-115-likes-drain`, folder `C:\solid-carbide-worktrees\T-115`.

What was built (`game/scripts/run/run_state.gd`):
- `_drain_likes(seconds)`, called from `advance()` right after the combo's own drain. While the combo is at "no combo" (`has_no_combo()`: `combo` at combo.json's `start_multiplier`), it counts `likes_drain_idle`; once that passes `RunData.likes_drain_extra_wait_seconds()` (0 now), XP goes down by `RunData.likes_drain_xp_per_second(level)` per second (T-114's numbers, read, not copied), clamped at 0. The level is never touched, so it never goes down. The wait is split exactly across frames, so the speed does not depend on the frame size.
- Any trick raises the combo above "no combo", which stops the drain and resets `likes_drain_idle`; it starts again once the combo has drained again. A new run resets it.
- No drain while paused (it runs inside `advance()`, which runs from the pausable `_process`), after the run ends (`advance()` stops when `running` is false), or while a level-up weapon choice is waiting (an explicit check too, for when `advance()` is called by hand).
- Each frame it takes XP away it sends `xp_changed(xp, xp_needed, level)`, which the HUD already follows, so the likes bar visibly empties. No signal once the bar is empty. No HUD changes.
- `is_likes_draining()` says whether it is draining right now, for tests and readouts.

**Top level decision:** the drain does not apply at the top level. There XP is always 0 and the HUD shows the bar full, so there is nothing to drain; `likes_drain_xp_per_second(max_level)` is 0 too (T-114).

Note for the playtest: the HUD's likes bar has a step of 1 (whole likes), so at level 1's 2 likes per second it moves one like every half second; on a 100-like bar this reads as a slow, steady empty. If the board wants it smoother, that is a HUD task (step 0), not this one.

Tests: `game/tests/unit/run/test_run_likes_drain.gd`, 19 tests: no drain while the combo is above "no combo" (through its wait and most of its drain); the drain starts once the combo is gone; the speed at level 1 and at level 4 matches `likes_drain_xp_per_second`; the speed is the same with big frames; a trick stops it until the combo has drained again; XP stops at 0 with the level unchanged; a 400-second drain at level 6 never goes below 0, never changes the level and fires no `level_up`; `xp_changed` fires with falling values and the level's bar, and stops once empty; no drain after a win, after the clock runs out, while the tree is paused (real frames), while a weapon choice waits, at the top level; the extra wait (a test RunData with 1.5 s) delays it and restarts after a trick; switched off means no drain; a new run resets the wait; and in a real run scene the HUD's likes bar goes down with the run's XP.

Results, in the task folder: full GUT suite 345/345 passing (35 scripts, `TESTS PASSED`, exit 0); `game/tools` Python tests 125 OK; `tools` Python tests 115 OK. Godot's line-ending-only `.import` changes were reverted, not committed (`project.godot` was not touched).

Screenshots (git-ignored, in the task folder), from the new fixture `res://tests/fixtures/likes_drain_demo.tscn` (a run from the main menu, level 2 with a fifth of its bar, then no input; it prints time, XP and level every half second):
- `screenshots/T-115-likes-drain-1-emptying.png` (600 frames, about 2.6 s in, clock 7:58): the bar at about 15% (18.7 of 125), Hype Lv 2, Combo x1.0.
- `screenshots/T-115-likes-drain-2-empty.png` (3500 frames, about 14.6 s in, clock 7:46): the bar empty (0 of 125, since about 10 s in), still Hype Lv 2.

Documents affected: `docs/game-loop-architecture.md` (Content, "Likes and levels": the likes drain bullet), `game/README.md` (The run: the likes drain paragraph and table, `xp_changed`, the tests line).

**QA/Integration Agent, round 1, 2026-10-13.** All six criteria pass.
1. Pass. `_drain_likes()` resets `likes_drain_idle` and returns while `has_no_combo()` is false; `test_no_drain_while_the_combo_is_above_no_combo` (XP unchanged through the combo's wait and most of its drain), `test_drain_starts_once_the_combo_is_gone`, `test_drain_speed_is_t114s_speed_at_level_1` / `_follows_the_level` / `_does_not_depend_on_frame_size` (rate read from `RunData.likes_drain_xp_per_second`) and `test_a_trick_stops_the_drain` show it.
2. Pass. XP is clamped with `maxf(..., 0.0)` and `level` is never written by the drain; `test_xp_never_goes_below_zero_and_the_level_stays` and `test_a_long_drain_never_goes_below_the_level` (400 s at level 6, every `xp_changed` at or above 0 and at level 6, no `level_up`).
3. Pass. `test_no_drain_while_the_tree_is_paused` (real frames), `test_no_drain_while_a_weapon_choice_waits`, `test_no_drain_after_the_run_ends`, `test_no_drain_after_the_clock_runs_out`; `test_the_drain_sends_xp_changed_as_it_drains` (falling values, the level's bar, stops once empty) and `test_the_hud_likes_bar_empties_in_a_run` (real run scene, HUD bar follows XP).
4. Pass. `screenshots/T-115-likes-drain-1-emptying.png` (7:58, bar about 15%, Hype Lv 2, Combo x1.0) and `-2-empty.png` (7:46, bar empty, still Hype Lv 2).
5. Pass. Game loop architecture, Content, "Likes and levels" has the "Likes drain" bullet; game/README.md has the drain paragraph, its table, the `xp_changed` row and the tests line. The worktree's Decisions section is identical to master's.
6. Pass. Run by QA in the task folder: GUT 345/345 (35 scripts, `TESTS PASSED`, exit 0; `test_run_likes_drain.gd` 19/19), `game/tools` Python 125 OK, `tools` Python 115 OK. No `.import` changes left in the working tree.
- 2026-10-13, needs-playtest → done: LGTM (board playtest, 2026-10-13)

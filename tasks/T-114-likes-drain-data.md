---
id: T-114
title: Data: how fast the likes bar drains
status: done
from: project-lead
to: game-data
lead:
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/data/run.json, game/data/combo.json, tasks/T-038-run-and-likes-data.md, tasks/T-080-combo-data.md, game/README.md]
files_expected_to_change: [game/data/run.json, game/scripts/data/run_data.gd, its tests, game/README.md]
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

The board decided the likes drain for the MVP (Game loop architecture, Decisions, "Likes drain", 2026-10-13): once the combo has fully drained (the multiplier is back to "no combo"), the likes bar slowly empties, but never below the start of the current level. A trick stops it, since it raises the combo again. T-115 builds the behaviour; this task adds the numbers it reads.

1. Add the drain numbers to `game/data/run.json` and expose them through `game/scripts/data/run_data.gd`, the way the other run numbers are read. At least: whether the drain is on, and how fast it drains. Propose whether the speed is a flat XP per second or a share of the current level's bar per second, and a starting value that feels slow (the board said "slowly"); for comparison, a drift second gives 10 XP and level 1 needs 100. Write the reasoning in the result notes and in the file's `_comment`.
2. If you think a short extra wait after the combo has drained is needed, propose it as a separate number, defaulting to 0 (the board's rule is that it starts when the combo has drained).
3. Write tests for the new values and their defaults.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] `game/data/run.json` has the drain numbers, and `run_data.gd` returns them; a GUT test checks they load and have sensible values (on by default, speed above 0) (QA: pass)
- [x] The result notes and the JSON `_comment` give the proposed speed and why it is "slow" compared with the drift XP (QA: pass)
- [x] game/README.md lists the new numbers where the run numbers are described (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

**Game Data Agent, 2026-10-13.** Branch `task/T-114-likes-drain-data`, folder `C:\solid-carbide-worktrees\T-114`.

What was added:
- `game/data/run.json`: a `likes_drain` block with `enabled: true`, `bar_share_per_second: 0.02`, `extra_wait_seconds: 0.0`, and a `_comment` giving the reasoning.
- `game/scripts/data/run_data.gd`: `likes_drain_enabled()`, `likes_drain_bar_share_per_second()`, `likes_drain_extra_wait_seconds()`, and a helper `likes_drain_xp_per_second(level)` = share x that level's `xp_needed` (0 when the drain is off or at max level), so T-115 does not redo the sum.
- `game/tests/unit/test_run_data.gd`: three tests (loads and on by default, speed above 0 and below a whole bar, extra wait 0; slow next to drifting; scales with the level's bar, 0 at max level, 2 XP/s at level 1).
- `game/README.md`: the new readers listed under "Typed readers" with the run numbers.

Proposed speed and why:
- **A share of the current level's bar per second, not flat XP.** The bar grows 9x from level 1 (100) to level 11 (931). A flat amount slow enough at level 1 would be meaningless at level 11 (2 XP/s takes 465 s to empty that bar); one that matters at level 11 would wipe level 1 in seconds. A share keeps "slowly" the same at every level.
- **0.02 per second: a full bar takes 50 s to empty.** At level 1 that is 2 XP/s, a fifth of the 10 XP a drift second gives, so one second of drifting wins back five seconds of draining. In practice the player only loses progress made inside the current level, never a level.
- Note for the playtest: because drifting XP is flat and the drain is a share, at high levels the drain per second can exceed a drift second (level 11: 18.6 XP/s vs 10). It only runs while there is no combo, and a drift longer than 1 s is a trick that stops it, so it should not punish drifting; if it feels harsh late in the run, lowering the share (e.g. 0.01, 100 s per bar) is a one-number change.
- **Extra wait: 0** (board's rule). The combo's own 2 s wait plus its drain (0.5 per second, up to 10 s from the 6x cap) already gives a buffer before the likes start draining. The number is there if the board wants a pause.

Tests (run in the task folder): full GUT suite 326/326 passing (34 scripts); `game/tools` Python tests 125 OK; `tools` Python tests 115 OK. Godot's line-ending-only `.import` changes were reverted, not committed.

Documents affected: `game/README.md` (updated).

**QA/Integration Agent, round 1, 2026-10-13.** Checked in `C:\solid-carbide-worktrees\T-114` on `task/T-114-likes-drain-data`.
- Criterion 1, pass: `run.json` has a `likes_drain` block (`enabled: true`, `bar_share_per_second: 0.02`, `extra_wait_seconds: 0.0`). `RunData` reads each one with `likes_drain_enabled()`, `likes_drain_bar_share_per_second()` and `likes_drain_extra_wait_seconds()`, plus `likes_drain_xp_per_second(level)`. In `test_run_data.gd`, `test_likes_drain_loads_with_sensible_values` checks that the file loads, the drain is on, the share is above 0 and below 1, and the wait is 0. Two more tests check that the drain is slow next to drifting and that it scales with each level's bar: 2 XP/s at level 1, and 0 at max level 12, where `xp_needed` is 0.
- Criterion 2, pass: the result notes and the `_comment` both propose a share of the bar per second, not a flat amount. At 0.02 a full bar takes 50 s to empty. At level 1 that is 2 XP/s, a fifth of a drift second's 10 XP. They also say why a flat amount would be wrong across the 100 to 931 XP bars. The result notes also flag that late in the run the drain per second can be larger than what a drift second gives, which is worth watching in the playtest.
- Criterion 3, pass: the "Typed readers" line in `game/README.md` lists all four new readers next to the run numbers, with the proposed value.
- Criterion 4, pass: the full GUT suite passed with 326 of 326 tests in 34 scripts (`TESTS PASSED`, exit code 0), including the 3 new tests. The `game/tools` Python tests ran 125, all OK. The `tools` Python tests ran 115, all OK. The `.import` files Godot touched differ only in line endings and were left uncommitted.


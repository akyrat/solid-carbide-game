---
id: T-120
title: Data: the likes bar drains four times faster
status: in-progress
from: project-lead
to: game-data
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/data/run.json, tasks/T-114-likes-drain-data.md, tasks/T-115-likes-drain.md, game/README.md]
files_expected_to_change: [game/data/run.json, the run data and likes drain tests, game/README.md]
model: sonnet
qa_rounds: 0
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

The board wants the likes drain four times faster (2026-10-13): `likes_drain.bar_share_per_second` in `game/data/run.json` goes from 0.02 to **0.08** (8% of the current level's bar per second, so a full bar empties in 12.5 seconds; 8 likes a second at level 1). Nothing else about the drain changes (when it starts, the floor at the start of the level, no drain while paused).

1. Change the number and the `_comment` (it says the drain is slow next to drifting; say instead it is the board's playtest value).
2. Update the tests that pinned the old speed: T-114's tests in `game/tests/unit/test_run_data.gd` ("slow next to drifting", "a full bar takes at least 30 s", "2 XP/s at level 1") and any of T-115's tests in `game/tests/unit/run/test_run_likes_drain.gd` that assume 0.02. Tests should read the speed from the data where they can, and check the new value (0.08, a full bar in 12.5 s, 8 likes a second at level 1) where they pin it.
3. Update game/README.md where it gives the drain speed.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] `game/data/run.json` has `bar_share_per_second` 0.08 and nothing else in `likes_drain` changed; the `_comment` matches (QA: pass / fail)
- [ ] A GUT test checks the new speed (8 likes a second at level 1, a full bar in 12.5 s), and T-115's drain tests (when it starts, the floor, no drain while paused) still pass (QA: pass / fail)
- [ ] game/README.md gives the new speed (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Game Data Agent, 2026-10-13. Commit 847d0f2 on `task/T-120-likes-drain-faster`.

- `game/data/run.json`: `likes_drain.bar_share_per_second` 0.02 -> **0.08**. `enabled` (true) and `extra_wait_seconds` (0.0) are unchanged. The `_comment` now gives 0.08 as the board's playtest value (2026-10-13, four times the first proposal of 0.02): a full bar empties in 12.5 s, 8 likes a second at level 1. "Proposed numbers" is gone.
- `game/tests/unit/test_run_data.gd`: `test_likes_drain_is_slow_next_to_drifting` (below half a drift second's XP, at least 30 s per bar) is replaced by `test_likes_drain_is_the_boards_playtest_speed`, which pins 0.08, a full bar in 12.5 s and 8 likes a second at level 1. In `test_likes_drain_scales_with_the_level_bar`, the pinned "2 XP/s at level 1" now reads the speed from the data.
- `game/tests/unit/run/test_run_likes_drain.gd` (T-115) needed no change. Every test there reads the speed through `RunData.likes_drain_xp_per_second()`. I checked each timed case at 0.08 (for example 50 XP at level 1 over 5 s leaves 10 XP; a 3 XP bar still sends more than 10 `xp_changed` signals before it empties). They all pass unchanged: when it starts, the floor, no drain while paused or while a choice waits, and the rest.
- `game/README.md`: the RunData reader line now gives 0.08 (a full bar in 12.5 s, 8 likes a second at level 1). The `likes_drain_demo` screenshot command for "the bar emptying" moves from frame 600 to frame 90, because at the new speed the demo's fifth of level 2's bar (25 likes) is gone in about 2.5 s. I did not take that screenshot.
- Tests: the full GUT suite passes (`bash game/tools/run_tests.sh`: 41 scripts, 408 of 408 tests, TESTS PASSED). Python tool tests: `game/tools` ran 141 tests, OK; `tools` exited 0, OK. Godot's line-ending-only `.import` changes were reverted and not committed. `project.godot` was not touched.
- Documents affected: `game/README.md` (updated). The Game loop architecture doc gives no drain number, so it needs no change.


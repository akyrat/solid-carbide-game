---
id: T-085
title: The combo raises minion spawning (can be switched off)
status: in-qa
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-044, T-081, T-080]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, tasks/T-044-minions.md, tasks/T-081-combo.md, tasks/T-080-combo-data.md, game/README.md]
files_expected_to_change: [the enemy code, tests, docs/enemies.md, game/README.md]
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

**Blocked until T-044 (minion spawning), T-081 (the combo) and T-080 (the numbers) are done.**

Enemies, Decisions: the higher the combo, the more minions spawn, on top of the slow growth over the run. Use T-081's current multiplier and T-080's numbers. Add an on/off switch (a setting the board can flip for playtests, documented in `game/README.md`), because the board will judge whether to keep it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test with a high combo shows more minions spawn than with no combo, by the data's amount (QA: pass / fail)
- [ ] A test with the switch off shows the combo makes no difference to spawning (QA: pass / fail)
- [ ] `game/README.md` says how to switch it, and `docs/enemies.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it; more minions with a combo is something the player meets).

## Result notes

**Built:** `game/scripts/enemies/minion_spawner.gd`: `minions_wanted_now()` sets `spawn_multiplier` from `RunState.combo_spawn_multiplier()` (`ComboData.spawn_multiplier(combo)`) on every call, so the count follows the combo live; no data numbers changed.

**The switch:** `run.minions.combo_raises_spawning` (default `true`). False keeps the multiplier at 1.0. To flip it for a playtest, change the default on that line in `minion_spawner.gd`. Documented in `game/README.md` (Minions) and `docs/enemies.md` (Content, "The combo raises spawning"); Summary, Decisions and Open questions untouched.

**Tests:** `game/tests/unit/enemies/test_minions.gd`: no combo = no extra; max combo wants `minions_wanted(t, mult)` (more than base) and that many really spawn; switch off = combo changes nothing; on by default. The old hook test (which asserted the T-044 placeholder state) was replaced. Full GUT suite: TESTS PASSED. All Python tests (game/tools and tools, 33 files): passed.

**For the playtest:** build up a combo (drifting tricks) and watch the crowd grow towards about 1.75x (max in `data/combo.json`); note that a minion's contact hit cuts the combo, so the extra minions also push it back down. Compare with the switch off.

## QA round 1 (QA/Integration Agent)

- Criterion 1 (high combo spawns more, by the data's amount): PASS. `test_a_high_combo_wants_more_minions_by_the_data_amount` checks wanted == `minions_wanted(t, ComboData.spawn_multiplier(max))`, greater than base, and that many really spawn.
- Criterion 2 (switch off, no difference): PASS. `test_with_the_switch_off_the_combo_changes_nothing`; also `test_no_combo_means_no_extra_spawning` and `test_the_switch_is_on_by_default`.
- Criterion 3 (docs): PASS. `game/README.md` says how to flip it; `docs/enemies.md` diff is one added line in Content only (no Summary, Decisions or Open questions change; no data numbers changed; `data/*.json` untouched). No debug input or player-facing text in the diff. Note: the old Content line "has a hook in place but is not wired yet" (Spawning bullet) is now stale, a minor doc point for the Project Lead, not a criterion failure.
- Criterion 4 (all tests): PASS. Full GUT suite: 582 passing, all tests passed. All Python tests in game/tools and tools passed.
- T-044 test check: the only T-044 test removed is `test_combo_hook_multiplies_minions_wanted` (asserted multiplier stays 1.0 and a manual 1.5); replaced by the four new tests above. Nothing else removed or weakened.

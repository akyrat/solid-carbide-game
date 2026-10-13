---
id: T-119
title: Data: the kaiju drops a few coins when defeated
status: done
from: project-lead
to: game-data
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/garage-design.md, game/data/enemies.json, tasks/T-039-enemy-data.md, game/README.md]
files_expected_to_change: [game/data/enemies.json, game/scripts/data/enemy_data.gd, its tests, game/README.md]
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

The board's decision (Enemies, Decisions, 2026-10-13): when the kaiju is defeated it always drops a few coins (100% chance). T-039 proposed that the kaiju drops none; change that.

1. Add the kaiju's coin drop to `game/data/enemies.json`: a 100% chance (or simply "always") and a small number of coins. "A few" is the board's word: propose the number, in the same range as a handful of minion drops (a minion drop is 2 coins), and explain it against the roughly 250 coins a run that the garage prices assume.
2. Expose it through `enemy_data.gd`, the way the other enemy numbers are read.
3. Update the `_comment` and T-039's reasoning where it said the kaiju drops none (in the JSON comment and game/README.md; leave T-039's finished task file as history).
4. Tests: the kaiju's drop chance is 1 and its coin count is above 0 and small.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] `game/data/enemies.json` gives the kaiju a 100% coin drop of a few coins, read through `enemy_data.gd`, and a GUT test checks the chance is 1 and the count is above 0 (QA: pass)
- [x] The result notes explain the number of coins; nothing in the JSON comment or game/README.md still says the kaiju drops no coins (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

Game Data Agent, 2026-10-13. Branch `task/T-119-kaiju-coins-data`, folder `C:\solid-carbide-worktrees\T-119`.

**What changed**
- `game/data/enemies.json`: new section `kaiju_coins` with `drop_chance` 1.0 (always) and `coins_per_drop` 10, with its own `_comment` (the board's decision, and that the coins are added as the run ends, without a pickup). The top `_comment` now lists the kaiju's coins and points here for the reason. The `coins` section (minions) is unchanged.
- `game/scripts/data/enemy_data.gd`: `kaiju_coins()` (the section as floats, like the other sections) and `kaiju_coins_on_defeat() -> int` (whole coins the defeated kaiju adds: drop chance times coins per drop, rounded; 10 with the current data).
- `game/tests/unit/test_enemy_data.gd`: `kaiju_coins()` added to the key and positive-value checks, and a new `test_kaiju_always_drops_a_few_coins`: drop chance is 1, the count is 10 and above 0, at least two minion drops, at most ten minion drops, and under a tenth of an average run's 250 coins.
- `game/README.md`, Enemies (T-039) entry: documents `kaiju_coins`, `kaiju_coins()` and `kaiju_coins_on_defeat()`.

Neither the JSON comment nor game/README.md said in words that the kaiju drops no coins; the "drops none" reasoning was only in T-039's result notes (Coins), which stay as history. The data simply had no kaiju drop; it has one now.

**The number: 10 coins**
- "A few", in the board's words, sized as a handful of minion drops: a minion drop is 2 coins, so 10 coins is 5 minion drops.
- Against the economy: the garage prices assume about 250 coins per average run (T-039: about 250 to 300 kills at 1.2 coins per kill). 10 coins is 4% of that, so it does not shift the garage's pacing; the cheapest garage level costs 40 (acceleration level 1), so it is a quarter of one cheap level.
- It only comes in a won run (the kaiju's death ends the run), so it reads as a small reward for winning on top of the run's coins, not a second income source. Bigger (say 25 to 50, 10 to 20% of a run) would start to make winning matter for the economy, which is a balance choice for the board, not "a few".
- Proposed number; the board judges it in playtests. It is one value in enemies.json (`kaiju_coins.coins_per_drop`) to change.

**For the Enemy Behavior / Game Loop work that uses it:** when the kaiju dies, add `EnemyData.new().kaiju_coins_on_defeat()` to the run's coins (`add_coins`) before `kaiju_killed()` ends the run, since `add_coins` is ignored once the run is over (Enemies, Decisions: added as the run ends, without being picked up). Nothing in the game calls it yet; this task is data only.

**Tests** (run in the task folder): full GUT suite 393/393 passing (40 scripts, `bash game/tools/run_tests.sh`, TESTS PASSED); Python tool tests `game/tools` 141 passed, `tools` 115 passed. Godot's line-ending-only `.import` changes from the test run were left out of the commit (project.godot was not touched).

**Documents affected:** game/README.md (updated). No game area doc changed: Enemies, Decisions already records the board's decision.

**QA round 1** (QA/Integration Agent, 2026-10-13, in `C:\solid-carbide-worktrees\T-119`):
- Criterion 1, pass. `enemies.json` has a new `kaiju_coins` section with `drop_chance` 1.0 and `coins_per_drop` 10. `EnemyData.kaiju_coins()` reads it through the same `_section()` helper as the other sections, and `kaiju_coins_on_defeat()` returns `roundi(chance * count)` = 10. GUT `test_kaiju_always_drops_a_few_coins` asserts chance == 1.0, count 10, `assert_gt(..., 0)`, and that it is between 2 and 10 minion drops and under 25 coins. It ran and passed. The new section is also in the key and positive-value checks.
- Criterion 2, pass. The result notes explain 10 coins: 5 minion drops, 4% of the roughly 250 coins in a run, a quarter of the cheapest garage level (40), and only in a won run. A search of `enemies.json` and `game/README.md` for "no coin", "drops none", "no drop" and "0 coins" finds nothing about the kaiju. The only hit is `start_run()` resetting coins to 0, which is unrelated. Both now describe `kaiju_coins`. T-039's task file is unchanged, as history.
- Criterion 3, pass. Full GUT suite: 393/393 passing across 40 scripts (TESTS PASSED). The one warning ("Ignoring Inner Class TestRoom") is unrelated and was already there. Python: `game/tools` 141 passed, `tools` 115 passed.
- Godot's line-ending-only `.import` changes from the test run were left uncommitted.

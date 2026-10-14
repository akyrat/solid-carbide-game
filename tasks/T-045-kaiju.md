---
id: T-045
title: The kaiju: arrives at the boss time, can be damaged at any time, its death wins the run
status: in-qa
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-036, T-039, T-044, T-119]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-039-enemy-data.md, tasks/T-044-minions.md, game/README.md]
files_expected_to_change: [the enemy code and scenes, tests, docs/enemies.md, game/README.md]
model: opus
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

**Blocked until T-036 (the run), T-039 (the numbers) and T-044 (the enemies' damage function) are done.**

Build the kaiju as Enemies, Decisions describes it, with T-039's numbers:
1. **Arrival:** on the run's "boss time" signal (T-036) the kaiju appears just off-screen and walks slowly towards the car.
2. **Contact damage and knockback**, like the minions.
3. **Damage:** weapons can damage the kaiju at any time, through the same damage function as the minions (T-044). It has no shield and no vulnerability windows (Enemies, Decisions, 2026-10-11).
4. **Health:** the kaiju's health is readable for the HUD, with a signal when it changes.
5. **Death:** at 0 health it dies and calls the run's kaiju-killed function (T-036), which ends the run as a win.

Its meteor attack is T-046. The kaiju itself is a placeholder for now: a large shape several times the car's size. The final kaiju art comes from a separate art task.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

**Kaiju coins (board, 2026-10-13):** when the kaiju is defeated it always drops a few coins (Enemies, Decisions; the number from T-119 in `enemies.json`). Its death ends the run straight away, so add its coins to the run's coins before the "run ended" signal, so they count in the coins saved.

## Acceptance criteria

- [ ] A test fires the "boss time" signal and shows the kaiju appears and moves towards the car (QA: pass / fail)
- [ ] A test shows weapon damage lowers the kaiju's health as soon as it has appeared, and the health signal fires (QA: pass / fail)
- [ ] A test damages the kaiju to 0 and shows the run's kaiju-killed function is called once (QA: pass / fail)
- [ ] A test shows contact with the car damages it and knocks it back (QA: pass / fail)
- [ ] A screenshot shows the placeholder kaiju (QA: pass / fail)
- [ ] `docs/enemies.md` describes the built kaiju in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

**Enemy Behavior Agent, 2026-10-14.**

**What I built** (all in `game/scripts/enemies/`, details in `game/README.md`, "The kaiju"):
- `kaiju.gd`: the kaiju body, built like a minion so the weapons treat both the same: a `CharacterBody2D` on layer 3 (`enemies`), mask 1 (obstacles), in the groups `enemies` and `kaiju`, with the same `take_damage(amount)`, `position_units()`, `health`, `max_health` and `is_dead()`. It walks straight at the car at the data's 3 units/s and slides along/round buildings and boulders (the minion's rule); contact damage 20 once a second with a 16 units/s knockback away from it (the minion's contact code); a `health_changed` signal on every hit; `died` once at 0.
- `kaiju_boss.gd` (`run.kaiju_boss`, child `Kaiju` of the run): makes the kaiju appear on the run's `boss_time`, once per run, at a random point just off-screen (its whole drawing out of view), on the map and clear of buildings and boulders; steps it once per physics step (pausable; nothing after the run ends); removes it on a new run. On death it adds the kaiju's 10 coins (`EnemyData.kaiju_coins_on_defeat()`) through `RunState.add_coins()` and **then** calls `RunState.kaiju_killed()`, so `run_ended("win", coins)` includes them. For the HUD it relays `kaiju_appeared`, `kaiju_health_changed(health, max_health)` (once on arrival, then each hit) and `kaiju_defeated(coins)`, plus `kaiju_health()` / `kaiju_max_health()`.
- `kaiju_sprite.gd`: the placeholder, a dark slate green Godzilla-style figure drawn in code (lighter belly, pale cyan back plates, yellow eyes; no Redgull red), 4 units across on the ground and 7 units tall, facing the way it walks, stomping. It draws into the minions' Y-sorted `Enemies` node and joins the buildings' depth order through `enemy_depth.gd`.
- `game/scripts/run/run.gd`: 9 added lines only (preload, `kaiju_boss` var, create and bind it after the minions). No minion file and no `run_state.gd` changed. No balancing number changed.

**Playtest switch** (not a key, not player-facing): `game/data/playtest.json`, `"kaiju_early_arrival": { "enabled": true, "after_seconds": 30 }`. On this branch it is **on**: the kaiju arrives 30 s into the run. **To switch it back, set `"enabled": false`** (the kaiju then arrives at the boss time, 7 minutes in). Only the kaiju's arrival moves; the clock, the minions' growth and the `boss_time` signal are unchanged, and a later `boss_time` brings no second kaiju. It must be off before the MVP ships.

**Tests:** `game/tests/unit/enemies/test_kaiju.gd`, 19 tests: boss time bringing it just off-screen and walking towards the car (criterion 1); weapon damage through `take_damage()` lowering its health right after it appears, with both health signals, and a physics query on mask 4 finding its body (criterion 2); damage to 0 calling `kaiju_killed()` exactly once, with its coins added before the run ends (criterion 3, two tests: one on the real run state, one with a counting stand-in); contact damage at the data's rate and knockback away from it, the car moving away (criterion 4); plus walking round a building, no damage without touching, pause, after the run ends, a new run, collision layers, draw order, size and no red, the playtest switch and its file.
- Full GUT suite (`bash game/tools/run_tests.sh`): **598/598 passed**, TESTS PASSED (with the switch on).
- Python tool tests: `game/tools` **241 OK** (1 skipped); `tools` **130 OK**.

**Screenshot:** `screenshots/kaiju.png` (git-ignored; copy committed at `art-archive/T-045/screenshots/kaiju.png`), from `bash game/tools/screenshot.sh res://tests/fixtures/kaiju_demo.tscn screenshots/kaiju.png 20`: the placeholder kaiju beside the car in the gravel square, with four minions for scale, in a run started from the main menu.

**Docs:** `docs/enemies.md` (Content: new "The kaiju (built in task T-045)"; Summary, Decisions and Open questions untouched), `game/README.md` (new "The kaiju" section; small pointers in the folder table, Game data and Minions' damage section).

**For the board's playtest:** press Start and wait 30 s; the kaiju walks in from a screen edge at half a minion's speed. Look at: its size on screen (4 x 7 units, about 4 car widths across; I made it smaller than my first try, which hid its head off the top of the screen when it reached the car); its look as a placeholder; how it chases you through the streets (it walks round buildings like the minions, it does not walk through them); and the contact hit (20 health and a strong knockback). There are no weapons yet, so it cannot be killed in play; that is covered by the tests.

**Open questions for the board:**
- Should the kaiju walk round buildings (as built, like the minions) or straight through them, being a giant? Not decided in the docs; I kept the minions' rule.
- Its placeholder size (4 units across, 7 tall) is mine; the final art task will settle it.

Board review files: screenshots/kaiju.png, art-archive/T-045/screenshots/kaiju.png, game/data/playtest.json

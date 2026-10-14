---
id: T-045
title: The kaiju: arrives at the boss time, can be damaged at any time, its death wins the run
status: needs-playtest
from: project-lead
to: enemy-behavior
lead: Enemies
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-036, T-039, T-044, T-119]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-039-enemy-data.md, tasks/T-044-minions.md, game/README.md]
files_expected_to_change: [the enemy code and scenes, tests, docs/enemies.md, game/README.md]
model: opus
qa_rounds: 3
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

~~**Dev timer setting (board, 2026-10-14):** add a setting where the board sets the run timer's minutes and seconds (the time on the clock when a run starts), so it can fast-forward to the boss. It goes with the other playtest settings in `game/data/playtest.json`. Settings like these will go under an internal dev flag that players never see (HUD and menus, Decisions); no player-facing UI. Replace the `kaiju_early_arrival` switch with it, so there's one way to reach the boss early: the kaiju keeps arriving on the run's normal boss-time signal. Default it in this branch to 1:30 on the clock (30 s before the boss), and say in the result notes how to set it back to the normal 8:00.~~ **Superseded (board, 2026-10-14):** no timer setting; runs always start at 8:00. For the board's playtest the kaiju arrives 30 s into the run (the `kaiju_early_arrival` switch in `game/data/playtest.json`, beside T-042's `flamethrower_at_start`); it is set back to 7 minutes right before merging. Merge master first, so the gun and the flamethrower can kill the kaiju in the playtest build; the flamethrower counts any overlap with the kaiju's body as a hit (`hit_radius_units()`).

## Acceptance criteria

- [x] A test fires the "boss time" signal and shows the kaiju appears and moves towards the car (QA: pass) (round 3)
- [x] A test shows weapon damage lowers the kaiju's health as soon as it has appeared, and the health signal fires (QA: pass) (round 3)
- [x] A test damages the kaiju to 0 and shows the run's kaiju-killed function is called once (QA: pass) (round 3)
- [x] A test shows contact with the car damages it and knocks it back (QA: pass) (round 3)
- [x] A screenshot shows the placeholder kaiju (QA: pass) (round 3)
- [x] `docs/enemies.md` describes the built kaiju in Content, without changing Summary, Decisions or Open questions (QA: pass) (round 3)
- [x] The full GUT suite and all Python tool tests pass (QA: pass) (round 3)
- Superseded (board, 2026-10-14, no timer setting): ~~A test sets the dev timer setting (minutes and seconds) and shows a run started from the main menu starts with that time on the clock, and the kaiju arrives when the clock reaches the boss time~~ (round 2 QA: pass; round 3 QA: superseded)
- Superseded (board, 2026-10-14, no timer setting): ~~`game/README.md` says how to set the dev timer setting; it is in the dev settings file, not visible to the player~~ (round 2 QA: fail; round 3 QA: superseded)
- [x] (added 2026-10-14, after the board's change) `game/README.md` has exactly one kaiju section, with no copied Minions text, describing the 30 s playtest switch and how to turn it off (QA: pass) (round 3)
- [x] (added 2026-10-14) With master's gun and flamethrower, a test or a run shows both weapons damage the kaiju (the flames on any overlap with its body) and killing it wins the run (QA: pass) (round 3)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

**Enemy Behavior Agent, 2026-10-14.**

**What I built** (all in `game/scripts/enemies/`, details in `game/README.md`, "The kaiju"):
- `kaiju.gd`: the kaiju body, built like a minion so the weapons treat both the same: a `CharacterBody2D` on layer 3 (`enemies`), mask 1 (obstacles), in the groups `enemies` and `kaiju`, with the same `take_damage(amount)`, `position_units()`, `health`, `max_health` and `is_dead()`. It walks straight at the car at the data's 3 units/s and slides along/round buildings and boulders (the minion's rule); contact damage 20 once a second with a 16 units/s knockback away from it (the minion's contact code); a `health_changed` signal on every hit; `died` once at 0.
- `kaiju_boss.gd` (`run.kaiju_boss`, child `Kaiju` of the run): makes the kaiju appear on the run's `boss_time`, once per run, at a random point just off-screen (its whole drawing out of view), on the map and clear of buildings and boulders; steps it once per physics step (pausable; nothing after the run ends); removes it on a new run. On death it adds the kaiju's 10 coins (`EnemyData.kaiju_coins_on_defeat()`) through `RunState.add_coins()` and **then** calls `RunState.kaiju_killed()`, so `run_ended("win", coins)` includes them. For the HUD it relays `kaiju_appeared`, `kaiju_health_changed(health, max_health)` (once on arrival, then each hit) and `kaiju_defeated(coins)`, plus `kaiju_health()` / `kaiju_max_health()`.
- `kaiju_sprite.gd`: the placeholder, a dark slate green Godzilla-style figure drawn in code (lighter belly, pale cyan back plates, yellow eyes; no Redgull red), 4 units across on the ground and 7 units tall, facing the way it walks, stomping. It draws into the minions' Y-sorted `Enemies` node and joins the buildings' depth order through `enemy_depth.gd`.
- `game/scripts/run/run.gd`: 9 added lines only (preload, `kaiju_boss` var, create and bind it after the minions). No minion file and no `run_state.gd` changed. No balancing number changed.

**Playtest switch** (replaced in round 2 by the dev timer, then brought back in round 3, below) (not a key, not player-facing): `game/data/playtest.json`, `"kaiju_early_arrival": { "enabled": true, "after_seconds": 30 }`. On this branch it is **on**: the kaiju arrives 30 s into the run. **To switch it back, set `"enabled": false`** (the kaiju then arrives at the boss time, 7 minutes in). Only the kaiju's arrival moves; the clock, the minions' growth and the `boss_time` signal are unchanged, and a later `boss_time` brings no second kaiju. It must be off before the MVP ships.

**Tests:** `game/tests/unit/enemies/test_kaiju.gd`, 19 tests: boss time bringing it just off-screen and walking towards the car (criterion 1); weapon damage through `take_damage()` lowering its health right after it appears, with both health signals, and a physics query on mask 4 finding its body (criterion 2); damage to 0 calling `kaiju_killed()` exactly once, with its coins added before the run ends (criterion 3, two tests: one on the real run state, one with a counting stand-in); contact damage at the data's rate and knockback away from it, the car moving away (criterion 4); plus walking round a building, no damage without touching, pause, after the run ends, a new run, collision layers, draw order, size and no red, the playtest switch and its file.
- Full GUT suite (`bash game/tools/run_tests.sh`): **598/598 passed**, TESTS PASSED (with the switch on).
- Python tool tests: `game/tools` **241 OK** (1 skipped); `tools` **130 OK**.

**Screenshot:** `screenshots/kaiju.png` (git-ignored; copy committed at `art-archive/T-045/screenshots/kaiju.png`), from `bash game/tools/screenshot.sh res://tests/fixtures/kaiju_demo.tscn screenshots/kaiju.png 20`: the placeholder kaiju beside the car in the gravel square, with four minions for scale, in a run started from the main menu.

**Docs:** `docs/enemies.md` (Content: new "The kaiju (built in task T-045)"; Summary, Decisions and Open questions untouched), `game/README.md` (new "The kaiju" section; small pointers in the folder table, Game data and Minions' damage section).

**For the board's playtest:** press Start and wait 30 s; the kaiju walks in from a screen edge at half a minion's speed. Look at: its size on screen (4 x 7 units, about 4 car widths across; I made it smaller than my first try, which hid its head off the top of the screen when it reached the car); its look as a placeholder; how it chases you through the streets (it walks round buildings like the minions, it does not walk through them); and the contact hit (20 health and a strong knockback). There are no weapons yet, so it cannot be killed in play; that is covered by the tests.

**Open questions for the board:**
- Should the kaiju walk round buildings (as built, like the minions) or straight through them, being a giant? Not decided in the docs; I kept the minions' rule.
- Its placeholder size (4 units across, 7 tall) is mine; the final art task will settle it.

**QA (QA/Integration Agent, 2026-10-14, round 1): all 7 criteria pass.**
- Boss time: `test_boss_time_makes_the_kaiju_appear_off_screen_and_walk_towards_the_car` (plus `test_kaiju_walks_straight_at_the_car_in_the_open`, `test_kaiju_walks_round_a_building`). Pass.
- Damage and health signal: `test_weapon_damage_lowers_health_as_soon_as_it_appears_and_sends_health` (and `test_projectile_area_on_the_enemies_mask_finds_the_kaiju`). Pass.
- Death: `test_killing_the_kaiju_adds_its_coins_and_calls_kaiju_killed_once` (run ends once as "win", `run_ended` coins = earlier coins + 10) and `test_kaiju_killed_called_exactly_once_on_the_state` (counting stand-in, coins added before the call). Code check: `kaiju_boss.gd` `_on_kaiju_died()` calls `state.add_coins(n)` before `state.kaiju_killed()`, so the kaiju's coins are in `run_ended`. Pass.
- Contact: `test_contact_damages_the_car_and_knocks_it_back`, `test_contact_through_the_boss_step`, `test_no_damage_without_touching`. Pass.
- Screenshot `art-archive/T-045/screenshots/kaiju.png`: the placeholder kaiju (upright, tail-dragging dark slate green reptile, lighter belly, pale cyan back plates, yellow eye, ground shadow) next to the car and four minions; no Redgull red on it (the only red is the HUD likes heart, board-approved). Likeness: it reads as a generic large upright reptile monster drawn in flat code shapes (blocky beak-like snout, plain rectangular legs, no detailed face or skin), in the "Godzilla-style, not Godzilla" sense Visual style asks for; it is not an exact copy. Note for the board: the upright pose plus jagged pale cyan back plates is the most Godzilla-like part of the silhouette; whether that is too close is the board's call in the playtest. Pass.
- `docs/enemies.md`: the diff against master only adds "### The kaiju (built in task T-045)" in Content; Summary, Decisions and Open questions unchanged. Pass.
- Tests, run by QA in this folder: GUT 598/598 passed with the playtest switch on, and 598/598 with it off (then restored to on); Python `game/tools` 241 OK (1 skipped), `tools` 130 OK. Pass.
- Other checks: `game/data/enemies.json` and every other balancing file unchanged against master (only `game/data/playtest.json` is new); the kaiju's stats are read from `enemies.json`, none hard-coded. No input handling or debug key and no player-facing text in the kaiju scripts or the `run.gd` change. The playtest switch is documented in `game/README.md` ("Game data" and "The kaiju"), and `test_playtest_switch_reads_the_settings_file` reads the expected value from the file, so no test depends on it being on. No stray screenshot copy tracked outside `art-archive/` (`screenshots/` is git-ignored); Godot `.import` line-ending noise left uncommitted.

**Enemy Behavior Agent, 2026-10-14, round 2 (the board's additions: dev timer, kaiju hit radius).** *Superseded in round 3 (board, 2026-10-14): the dev timer is dropped; the kaiju hit radius stays.*

**Dev timer setting** (replaces `kaiju_early_arrival`, which is gone): `game/data/playtest.json`, key `"run_timer_start": { "enabled": true, "minutes": 1, "seconds": 30 }`. The file is a dictionary of independent keys, so T-042's `flamethrower_at_start` can sit beside it; a test reads a file with both. With `enabled` true, every run starts with that time on the clock: from the main menu, a new run, or `run.tscn` on its own. It is a dev setting only, with no UI and no player-facing text. **This branch defaults to 1:30, 30 s before the boss. To set it back to normal 8:00 runs, set `"enabled": false`.** 0:00, a missing file or key, or anything over 8:00 also gives 8:00. The kaiju now arrives only on the run's normal `boss_time` signal, at 1:00 left.
- How it is built: `game/scripts/run/dev_settings.gd` reads the setting (`run_start_time_left()`). `run.gd` passes it to `RunState.start_time_left` before each `start_run()`. In `run_state.gd`, `start_run()` uses `start_time_left` (default 8:00) in place of the fixed 8:00. That is the only change there.
- **What "fast-forwarded" means:** the run behaves as if the missing time had already passed. `time_elapsed()` still counts from 8:00, so a run started at 1:30 is 6:30 (390 s) in.
  - `boss_time` fires at 1:00 left as usual. If the start is under 1:00, it fires on the first tick.
  - The clock still ends the run at 0:00.
  - **Minion numbers:** the spawner keeps the number a normal run has at that moment, `minions_wanted(390)` = 19 at 1:30, rather than 12 at the start. They still come in one every half second from the screen's edges, so the full 19 builds up over the first few seconds, and they grow to 20 at 1:00.
  - Everything counted from the run's start rather than the clock starts fresh, as in any run: health, coins, likes and level (level 1), the combo and the likes drain. The likes drain and the combo depend only on time passing, not on the clock's value, so they are unaffected.
  - Nothing else reads the run's time: I checked every `time_elapsed`/`time_left` user.
- **Tests stay independent of the file:** a GUT pre-run hook (`game/tests/pre_run_hook.gd`, set as `pre_run_script` in `game/.gutconfig.json`) switches all dev settings off before the suite runs (`DevSettings.enabled = false`). The existing tests that expect 8:00 therefore pass whatever the board sets. The dev timer tests turn it back on and use their own file. Other tasks' dev settings can use the same flag.

**Kaiju hit radius** (board, 2026-10-14: the flamethrower counts any overlap with the kaiju's body): `kaiju.gd` now has `hit_radius_units()`, which returns `RADIUS_UNITS` (2.0 units, its collision circle and its drawn ground circle). This matches what T-041's targeting on master reads. The board also confirmed the kaiju walks round buildings as built, which answers my first open question.

**New tests** (in `game/tests/unit/enemies/test_kaiju.gd`, now 22 tests):
- `test_dev_timer_starts_a_run_from_the_main_menu_with_that_time_and_the_kaiju_at_boss_time` (new criterion 1). It sets 1:05 and starts a run from the main menu. The clock and HUD show 1:05, `time_elapsed()` is 415, and the minion count matches `minions_wanted(415)`. There is no kaiju or boss time at 1:00.1 left; boss time and the kaiju come at 1:00. A second run starts at 1:05 again.
- `test_dev_timer_off_missing_or_invalid_gives_8_00`
- `test_a_run_started_with_less_time_stays_consistent`: boss time fires once at 1:00, the run is lost at 0:00, a new run starts at the same time, and a start under 1:00 sends boss time on the first tick.
- `test_committed_playtest_file_has_the_dev_timer`
- `test_hit_radius_matches_its_body_on_the_ground`

**Test results:**
- Full GUT suite: **601/601 passed** with the setting on (1:30), and **601/601 passed** with it off (8:00, then restored to on).
- Python: `game/tools` **241 OK** (1 skipped), `tools` **130 OK**.

**Screenshot:** `screenshots/kaiju_dev_timer.png` (copy at `art-archive/T-045/screenshots/kaiju_dev_timer.png`): the kaiju fixture in a run from the main menu, showing 1:30 on the clock.

**Docs:**
- `game/README.md`, "The kaiju": the new "Dev timer: fast-forward to the boss" paragraph (how to set it, how to switch it back, what fast-forwarded means) and `hit_radius_units()`. Also a "Dev settings" bullet in "Game data" and one sentence in "The run".
- `docs/enemies.md`, Content: the dev timer bullet replaces the playtest switch bullet; also the flamethrower overlap rule and the board's confirmation of walking round buildings. Summary, Decisions and Open questions are untouched.

**For the board's playtest:** press Start; the clock shows 1:30, and the kaiju walks in from a screen edge when it reaches 1:00. The minions start at about 19 rather than 12.

Board review files: screenshots/kaiju.png, art-archive/T-045/screenshots/kaiju.png, game/data/playtest.json
- 2026-10-14, in-qa → needs-playtest: QA round 1: all 7 criteria pass.
- 2026-10-14, needs-playtest → in-progress: Board (2026-10-14): add a dev setting for the timer's minutes and seconds, to fast-forward to the boss

**QA (QA/Integration Agent, 2026-10-14, round 2): 8 of 9 criteria pass; criterion 9 (`game/README.md`) fails.**
- Boss time (1): `test_boss_time_makes_the_kaiju_appear_off_screen_and_walk_towards_the_car` still passes. Pass.
- Damage and health signal (2): `test_weapon_damage_lowers_health_as_soon_as_it_appears_and_sends_health` still passes. Pass.
- Death (3): both kaiju-killed tests pass; `_on_kaiju_died()` still adds the coins before `kaiju_killed()`. Pass.
- Contact (4): the contact tests pass. Pass.
- Screenshot (5): `art-archive/T-045/screenshots/kaiju.png` unchanged since round 1; the new `kaiju_dev_timer.png` shows the same placeholder kaiju with 1:30 on the HUD clock. Pass.
- `docs/enemies.md` (6): the diff against master only adds "### The kaiju (built in task T-045)" in Content (now with the dev timer bullet, the flamethrower overlap rule and the board's walking-round-buildings confirmation). Summary, Decisions, Open questions and References are unchanged. Pass.
- Full GUT suite and Python tool tests (7): GUT **601/601** with the dev timer on (1:30) and **601/601** with it off (`enabled: false`), then restored to on (the file is unchanged against the branch). 56 scripts and 601 tests ran, which matches the 56 `test_*.gd` files and 601 `func test_` in `game/tests`, so nothing was skipped. The first run with it on had 1 failure, in `test_camera_options.gd::test_a_run_from_the_main_menu_uses_the_saved_options` (zoom 11 instead of 9). It passed on the rerun and in the run with the setting off. That test writes the shared `user://test_settings_t123.cfg`, and `user://` is shared by every worktree of the project, so other agents running tests in their folders at the same time can overwrite it. It is not related to T-045 (no camera or settings file changed). Python: `game/tools` 241 OK (1 skipped), `tools` 130 OK. Pass.
- Dev timer test (8): `test_dev_timer_starts_a_run_from_the_main_menu_with_that_time_and_the_kaiju_at_boss_time` (1:05 from the main menu: clock and HUD 1:05, elapsed 415, minions wanted = `minions_wanted(415)`, no boss or kaiju at 1:00.1, both at 1:00, a second run at 1:05 again), plus the off/missing/invalid test, the under-1:00 test and the committed-file test. QA also ran a temporary GUT script (deleted afterwards, not committed) on the **committed** `playtest.json` in real time from the main menu. The clock and HUD showed **1:30**, `time_elapsed()` was 390, and the spawner wanted **19** (= `minions_wanted(390)`; 12 at a normal start). After 12 s (1:18) there were 20 live minions and no kaiju, and a normal 8:00 run advanced to the same clock (1:18) wants the same 20. At **1:00** `boss_time` had fired and the kaiju was there. Pass.
- `game/README.md` (9): **Fail.** The new "Dev timer: fast-forward to the boss" paragraph is correct (how to set it, how to set it back to 8:00, a dev settings file with no UI, and the "Dev settings" bullet in "Game data"). But the round 2 edit left the file broken:
  - `## The kaiju` now appears **twice** (lines 743 and 791).
  - Between the two, lines 757-789 are a copy of the Minions section, from its "How it is built" to its "Tests".
  - The second `## The kaiju` (line 791 on) still has the old "**Playtest switch: early arrival.**" paragraph (lines 797-803). It tells the reader to set `"kaiju_early_arrival": { "enabled": true, "after_seconds": 30 }` and names `read_early_arrival_seconds()` in `kaiju_boss.gd`, but both were removed in this round. The kaiju's real "How it is built", "Damaging the kaiju" and "Health, for the HUD" text is only in this second copy.
  - So the README gives two different ways to reach the boss early, and one of them no longer exists.
  - Fix (docs only): delete lines 757-790 (the duplicated Minions text and the first section's end) or merge the two kaiju sections into one, and remove the "Playtest switch: early arrival" paragraph and its code block.
- Other checks (all fine):
  - Pre-run hook: `game/tests/pre_run_hook.gd` only sets `DevSettings.enabled = false`. `.gutconfig.json` only adds `pre_run_script`; dirs, prefix and suffix are unchanged. No test is skipped or hidden.
  - `run_state.gd`: the only changes are the new `start_time_left` var (default `RUN_SECONDS`) and `time_left = clampf(start_time_left, 0.001, RUN_SECONDS)` in `start_run()`. `run.gd` sets it from `DevSettings.run_start_time_left()` before `state.start_run()`.
  - No player-facing UI or text for the setting: no scene, HUD or menu file changed, and only `run.gd` and `run_state.gd` refer to the dev settings.
  - Data: `game/data/playtest.json` is the only file in `game/data` that differs from master, so no balancing number changed.
  - Early-arrival code: none left in the code (`kaiju_boss.gd` has no early-arrival code); the only mentions are the stale README text above and the test asserting the key is gone.
  - `kaiju.gd` `hit_radius_units()` returns `RADIUS_UNITS` (2.0), the name master's `weapons.gd` reads.
  - Godot `.import` line-ending noise and the git-ignored `screenshots/` left uncommitted.
- 2026-10-14, in-qa → flagged-for-review: QA round 2: 8 of 9 criteria pass; criterion 9 fails (game/README.md has the kaiju section twice, a copied Minions block, and still documents the removed kaiju_early_arrival switch). Docs-only fix.
- 2026-10-14, flagged-for-review → in-progress: Board (2026-10-14): drop the dev timer setting; for the playtest the kaiju arrives at 30 s; after the board's playtest approval, set back to 7 minutes right before merging

**Enemy Behavior Agent, 2026-10-14, round 3 (the board's change: no dev timer; the kaiju at 30 s; master merged).**

**Master merged in** (commit 71f911c), bringing T-041's starting gun and T-042's flamethrower. The conflicts were in `run.gd` (the kaiju and the weapon rack are both kept), `game/data/playtest.json`, `game/README.md` and this task's header.

**Dev timer dropped:**
- `run_timer_start`, `RunState.start_time_left` and `game/scripts/run/dev_settings.gd` are gone.
- The GUT pre-run hook (`game/tests/pre_run_hook.gd` and its `.gutconfig.json` entry) is gone too.
- `game/scripts/run/run_state.gd` and `game/.gutconfig.json` are back to master's, so runs always start at 8:00.
- The round 2 notes above are superseded.

**Kaiju at 30 s for the playtest** (round 1's switch, brought back): `game/data/playtest.json` now holds both keys:
- `"flamethrower_at_start": true` (T-042's, kept as on master).
- `"kaiju_early_arrival": { "enabled": true, "after_seconds": 30 }`.

The kaiju arrives 30 s into the run instead of at 7:00. **Right before merging, set `"enabled": false` in `kaiju_early_arrival`**, and the kaiju then arrives at the boss time (7 minutes in). Only the kaiju's arrival moves. A later boss time brings no second kaiju, and a new run brings it again at 30 s.

**Tests stay independent of the file without the hook.** I followed T-042's pattern: `kaiju_boss.gd` has a static `playtest_override` (-1 = off, seconds = on, -2 = read the file). `test_kaiju.gd` sets it to off, and also sets the flamethrower's own override to off, before making each run. The flamethrower's switch already works this way on master, so the hook wasn't needed for either key and I did not route the flamethrower through anything new.

**The weapons hit the kaiju** (checked with master's real weapons, not stand-ins):
- `test_starting_gun_hits_the_kaiju`: the rack's gun fires at the kaiju 5 units from the car and lowers its health in whole bullets of the gun's damage.
- `test_flames_burn_the_kaiju_on_any_overlap_with_its_body`: the kaiju's centre is 1.5 units past the flames' far edge, so only its body (radius 2, from `hit_radius_units()`) reaches into them. The flamethrower counts it inside and burns it.
- `test_killing_the_kaiju_with_the_gun_wins_the_run`: the gun kills a kaiju at 1 health, the run ends as a win, and the run's coins include the kaiju's 10.

Other new tests:
- `test_playtest_switch_brings_the_arrival_forward`: it arrives at 30 s, not before, once, and again in a new run.
- `test_playtest_switch_reads_its_key_beside_other_keys`: on, off, missing key, missing file, and the override.
- `test_committed_playtest_file_keeps_both_switches`.

`test_kaiju.gd` now has 24 tests.

**game/README.md fixed:** it has one "The kaiju" section, appended after master's sections, with no copied Minions text. It documents the 30 s switch and how to switch it back, `hit_radius_units()` and how the gun and the flamethrower use it, and the tests. It also has pointers in the folder table, the Minions damage paragraph, the Weapons "Targets" line and a "Playtest switches" bullet in "Game data".

**docs/enemies.md** (Content only): the dev timer bullet is replaced by the 30 s playtest switch bullet. The flamethrower overlap rule and the board's confirmation that the kaiju walks round buildings stay. Summary, Decisions and Open questions are untouched.

**Acceptance criteria:**
- The two dev timer criteria are marked superseded (not deleted).
- I reset criteria 1-7 to unchecked so QA rechecks them after the merge.
- There is no criterion yet for the README fix or for the weapons hitting the kaiju; the tests above cover the weapons.

**Test results:**
- Full GUT suite: **650/650 passed** with both switches on (kaiju at 30 s, flamethrower at start). It also passed **650/650** with the kaiju switch off; the file was then restored to on.
- Python: `game/tools` **241 OK** (1 skipped), `tools` **171 OK**.

**Screenshot:** `screenshots/kaiju.png`, retaken after the merge; it is unchanged (copy at `art-archive/T-045/screenshots/kaiju.png`). `kaiju_dev_timer.png` is from round 2 and is only kept as a record.

**For the board's playtest:** press Start. The kaiju walks in from a screen edge at 0:30 into the run (7:30 on the clock).
- The starting gun fires at it when it is in range, and the flamethrower burns it while you drift with it behind the car; any overlap with its body counts.
- It hits the car on contact with a strong knockback.
- At 500 health it takes a while to kill. Killing it wins the run, with its 10 coins.

**QA (QA/Integration Agent, 2026-10-15, round 3, the extra round the board ordered): all 9 criteria that apply pass; the 2 dev timer criteria are superseded.**
- Boss time (1): `test_boss_time_makes_the_kaiju_appear_off_screen_and_walk_towards_the_car` passes after the merge. Pass.
- Damage and health signal (2): `test_weapon_damage_lowers_health_as_soon_as_it_appears_and_sends_health` passes. Pass.
- Death (3): `test_killing_the_kaiju_adds_its_coins_and_calls_kaiju_killed_once` and `test_kaiju_killed_called_exactly_once_on_the_state` pass. `_on_kaiju_died()` still adds the coins before `kaiju_killed()`. Pass.
- Contact (4): `test_contact_damages_the_car_and_knocks_it_back` and `test_contact_through_the_boss_step` pass. Pass.
- Screenshot (5): `art-archive/T-045/screenshots/kaiju.png` (same as `screenshots/kaiju.png`, git-ignored) shows the placeholder kaiju beside the car and four minions; no Redgull red on it. Pass.
- `docs/enemies.md` (6): the diff against master only adds "### The kaiju (built in task T-045)" in Content, now with the 30 s playtest switch bullet; there is no dev timer text. Summary, Decisions and Open questions are unchanged. Pass.
- Full GUT suite and Python tool tests (7): GUT **650/650** with both playtest switches on, and **650/650** with `kaiju_early_arrival.enabled` false. The file was then restored to on, and `git status` shows it unchanged. 58 scripts ran; 650 = master's 626 `func test_` + `test_kaiju.gd`'s 24, so none were skipped. No camera or settings flake this round. Python: `game/tools` **241 OK** (1 skipped), `tools` **171 OK**. Pass.
- Dev timer criteria: superseded by the board (2026-10-14); not checked.
- `game/README.md` (new criterion, README): exactly one `## The kaiju` heading and no duplicated headings anywhere in the file. No copied Minions text: the diff against master is the new kaiju section plus four one-line pointers (the folder table, the Minions damage paragraph, Weapons "Targets", and the "Playtest switches" bullet in Game data). It documents `kaiju_early_arrival` (30 s) and how to turn it off (`"enabled": false`, back to 7 minutes in). `KaijuBoss.read_early_arrival_seconds()`, which it names, exists in `kaiju_boss.gd`. There is no dev timer, `run_timer_start` or `DevSettings` text. Pass.
- Weapons on the kaiju (new criterion): `test_starting_gun_hits_the_kaiju`, `test_flames_burn_the_kaiju_on_any_overlap_with_its_body` (centre outside the flames, body overlapping) and `test_killing_the_kaiju_with_the_gun_wins_the_run` pass with master's real weapons. QA also ran a temporary GUT script, deleted afterwards and not committed. It started a real run from the main menu, with the **committed** `playtest.json` read from the file and the flamethrower owned at the start. Results:
  - The kaiju arrived at **30.03 s** elapsed (7:29.97 on the clock) and walked towards the car.
  - The starting gun damaged it on its own.
  - Its contact took **20** off the car. The minions were stopped after the kaiju arrived, so the damage was the kaiju's.
  - The flamethrower, stepped while the car drifted, burned it with its body behind the car (health 494 to 486).
  - Brought to 1 health, the gun killed it. `run_ended("win", 12)` fired once: the run's 2 coins + the kaiju's 10. The game then returned to the main menu.

  Pass.
- Other checks (all fine):
  - `game/scripts/run/run_state.gd` and `game/.gutconfig.json` are identical to master's.
  - `dev_settings.gd` and `pre_run_hook.gd` are gone. `DevSettings`, `start_time_left`, `run_timer_start` and `pre_run_script` appear nowhere in the game's code or tests (only in GUT's own addon). The one exception is a test asserting `run_timer_start` is absent from `playtest.json`.
  - Balancing: in `game/data` only `playtest.json` differs from master (the kaiju key added beside `flamethrower_at_start`, which is unchanged). The kaiju's stats are read from `enemies.json`; only placeholder sizes are in code.
  - No player-facing text or UI: no Label, text, input or scene/HUD/menu change in the kaiju scripts. The only file outside `scripts/enemies/` is `run.gd`, with 9 added lines.
  - No conflict markers in any tracked file.
  - Godot `.import` line-ending noise and the git-ignored `screenshots/` left uncommitted.
- 2026-10-15, in-qa → needs-playtest: QA round 3 (extra round, ordered by the board): all 9 applicable criteria pass; the 2 dev timer criteria are superseded.

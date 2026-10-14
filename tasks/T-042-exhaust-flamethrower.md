---
id: T-042
title: The exhaust flamethrower: fires only while drifting
status: in-qa
from: project-lead
to: weapon-behavior
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-022, T-040, T-036, T-044]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/weapons/unity-weapons-report.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, tasks/T-036-run-scene-and-state.md, tasks/T-044-minions.md, tasks/T-041-starting-gun.md, game/README.md]
files_expected_to_change: [the weapon code and scenes, tests, docs/weapons.md, game/README.md]
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

**Blocked until T-022 (the report), T-040 (the numbers), T-036 (the run) and T-044 (the minions) are done.**

Build the exhaust flamethrower as Weapons, Decisions describes it, copying the Unity prototype's flame shape and trigger from T-022's report:
- Flames come out of the car's exhaust, only while the car is drifting (the car's drift state from T-012).
- The flames damage enemies they touch, through T-044's damage function, as the data describes.
- The player doesn't start with it; it is gained at a level-up (T-043).
- Its upgrade tiers (T-040's data) can be applied from code.
- It resets at the start of every run.

The flames are placeholders for now. The final flame art comes from a separate art task and replaces them.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test shows the flames are active only while the car is drifting, and stop when it stops drifting (QA: pass)
- [x] A test shows an enemy inside the flames takes damage as the data describes, and one outside does not (QA: pass)
- [x] A test applies each upgrade tier and shows the changed values take effect (QA: pass)
- [x] A test shows a new run starts without the flamethrower (QA: pass)
- [x] A screenshot shows placeholder flames behind the drifting car (QA: pass)
- [x] `docs/weapons.md` describes the built flamethrower in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

**Weapon Behavior Agent, 2026-10-14.**

**What I built.** The exhaust flamethrower as Weapons, Decisions and the Unity weapons report (section 3) describe it, with the board's fixes (damage not rounded, area the same size in every direction). Every number comes from `game/data/weapons.json` through `WeaponData.flame_at(tier)`; no balancing number was changed.
- `game/scripts/weapons/flamethrower/exhaust_flamethrower.gd` (class `ExhaustFlamethrower`): the whole weapon, one self-contained node. On while the car's drift state (`CarModel.is_drifting`) is on at `min_speed` (0.85) or faster, plus the 0.2 s linger, or always from tier 8. Area: a rectangle behind the car (0.175 behind the centre, full size 2.625 x 3.25), starting each drift at half size and reaching full size after 1 s. An enemy inside (its centre) takes 2 on entering (with the 0.38 s orange burn flash on its `sprite`) and 2 every 0.2 s. Tiers 1 to 8 with `set_tier()` / `upgrade()`; tier 7 multiplies the car's `tuning.turn_speed` by 1.2.
- `game/scenes/weapons/flamethrower/exhaust_flame.tscn`: the placeholder flame, a `CPUParticles2D` with the Unity prefab's tuning, stepped orange-yellow colours (no fade, no Redgull red), drawn just under the car in the run's `View`, from 0.42 units behind the car's centre, scaled with the area.
- Targets: every node in the group `enemies` with `take_damage()` and not `is_dead()`, so the kaiju (T-045) is found as soon as it joins that group. Not `run.minions` alone. No physics bodies, so no collision layer was added.

**How it attaches (for fitting into T-041's plumbing).** It touches `run.gd` in three lines only: a preload (`ExhaustFlamethrowerScript`) and, in `start_run()` after `state.start_run()`, `ExhaustFlamethrowerScript.give_if_playtest_switch(self)`. Nothing in the car was changed. The API:
- `ExhaustFlamethrower.attach_to_run(run)`: adds a node named `ExhaustFlamethrower` under the run at tier 1 (or returns the existing one), binds it to `run.car` (it steps on the car's `stepped` signal, so it stops while paused), puts its drawing under `run.view_root` just before `run.car_sprite`, and listens to `run.world_rebuilt`.
- `ExhaustFlamethrower.find_on(run)`, `ExhaustFlamethrower.detach_from(run)` / `flame.detach()`, `flame.set_tier(t)`, `flame.upgrade()` (false at tier 8), `flame.is_max_tier()`, signal `enemy_hit(enemy, amount)`.
- A new run (`run.world_rebuilt`) detaches it, so every run starts without it (and the new car has its normal turn speed).
- When T-041's weapon plumbing and T-043's level-up exist: the plumbing calls `attach_to_run(run)` when the player picks it and `find_on(run).upgrade()` for each tier, and the `give_if_playtest_switch` line comes out of `run.gd`. Whichever of T-041 and T-042 merges second fits it in. Written up in `game/README.md`, "The exhaust flamethrower".

**Playtest switch.** `game/data/playtest.json`, `"flamethrower_at_start": true` (on in this branch). True gives the car the flamethrower at tier 1 at the start of every run; set it to `false` for the game's rule (no flamethrower at the start). Not a key, no player-facing text. Tests override it with `ExhaustFlamethrower.playtest_override` (0 off, 1 on, -1 the file). It should be switched off, or the line removed, once T-043 offers the flamethrower at a level-up.

**Tests.** `game/tests/unit/weapons/test_exhaust_flamethrower.gd` (22 tests; test enemy `game/tests/fixtures/weapons/fake_enemy.gd`):
- Criterion 1: `test_flames_on_only_while_drifting_and_off_after_the_linger` (real driving: off driving straight, on from the first drifting step, on through the 0.2 s linger, then off and staying off; the drawing emits only while on), plus standing still and below the minimum speed.
- Criterion 2: `test_enemy_inside_takes_the_datas_damage_and_one_outside_does_not` (inside: 2 on entering then 2 per 0.2 s, 6 hits in 1 s; in front, beside and past the far edge: none), plus `test_flame_kills_a_real_minion` (a T-044 minion through `take_damage`), the ramp, the same size facing diagonally, the burn flash, nothing while paused.
- Criterion 3: `test_each_tier_sets_the_datas_values` (every tier 1 to 8 equals `flame_at`), `test_size_tiers_reach_further` (2, 4, 6), `test_tier_3_hotter_flame_deals_more_damage` (2.4), `test_tier_5_burn_flash_lasts_longer`, `test_tier_7_steering_makes_the_car_turn_faster`, `test_tier_8_always_on_without_drifting_at_full_size`.
- Criterion 4: `test_a_new_run_starts_without_the_flamethrower` (switch off: none in the new run, drawing gone, normal turn speed, drifting burns nothing), plus the switch giving a fresh tier 1 one when on.

Results: full GUT suite (`bash game/tools/run_tests.sh`) 601/601 passed, TESTS PASSED. Python: `game/tools` 241 tests OK (1 skipped, as on master), `tools` 130 tests OK.

**Screenshot (criterion 5).** `art-archive/T-042/screenshots/flamethrower.png` (placeholder flames behind the drifting car, a run started from the main menu) and `flamethrower_later.png` (later in the same drift, minions coming in). Remake: `bash game/tools/screenshot.sh res://tests/fixtures/weapons/flamethrower_demo.tscn screenshots/flamethrower.png 90`.

**Docs.** `docs/weapons.md`: new Content subsection "The exhaust flamethrower (built)"; Summary, Decisions and Open questions untouched. `game/README.md`: new section "The exhaust flamethrower".

**For the board's playtest.** Open `C:\solid-carbide-worktrees\T-042\game\project.godot`, press Start, and drift. Look at: when the flames come on and off (a quick tap of A while holding W lights them for the linger); the flame's reach and the half-size start of each drift; minions dying in it (2 hits kill a minion: about 0.2 s inside); the orange flash; the placeholder's look and density (Unity's 18 particles). Open questions for the board:
1. Unity switches the drift smoke off for the rest of the run once the flamethrower is picked up, so the two do not stack. Weapons, Decisions does not say, so I did not copy it: smoke and flames both show. Copy it?
2. An enemy is inside the flame only when its centre is (Unity's rule). That fits the minions; for the much bigger kaiju (T-045) it means only the flame reaching its centre burns it. Keep the centre rule for the kaiju too, or count any overlap with its body?

**QA (QA/Integration Agent, 2026-10-14, round 1): all 7 criteria pass.**
- 1, flames only while drifting: `test_flames_on_only_while_drifting_and_off_after_the_linger` drives the real car (straight: off; W+A: on from the first step; the 0.2 s linger; then off and staying off; drawing emits only while on), plus standing still and below the minimum speed. Pass.
- 2, damage inside, none outside: `test_enemy_inside_takes_the_datas_damage_and_one_outside_does_not` (2 on entering, 6 hits in 1 s, each the data's 2; in front, beside and past the far edge: none) and `test_flame_kills_a_real_minion`. QA also checked a real run started from the main menu (main scene, Start pressed, playtest switch read from the file, minions spawned by the run's own spawner, 25 s of scripted W+A drift, a scratch scene not committed): the flamethrower was attached after Start, 9 flame hits all landed on real minions from the `enemies` group and each lowered their health, 1 minion died from the flame, no other targets hit. Pass.
- 3, upgrade tiers: `test_each_tier_sets_the_datas_values` (tiers 1 to 8 equal `WeaponData.flame_at`, `upgrade()` false at 8) plus one test per effect (size at 2/4/6, damage 2.4 at 3, longer flash at 5, turn speed x1.2 at 7, always on at 8). Pass.
- 4, new run without it: `test_a_new_run_starts_without_the_flamethrower` (switch off: none found, drawing gone, normal turn speed, drifting burns nothing). Pass.
- 5, screenshot: `art-archive/T-042/screenshots/flamethrower.png` and `flamethrower_later.png` show orange-yellow placeholder squares at the rear of the drifting car, in a run with the HUD; no Redgull red (the scene's colour ramp is cream, yellow, orange, brown-orange; `test_placeholder_colours_are_not_redgull_red` checks it too). Pass.
- 6, docs: `docs/weapons.md` gains only the subsection "The exhaust flamethrower (built)" inside Content; Summary, Decisions and Open questions untouched. `game/data/weapons.json` is identical to master (no balancing number changed; the only data change is the new `playtest.json`). No debug key, no input handling and no player-facing text in the new code or scenes. The playtest switch is documented in `game/README.md` ("Playtest switch") and in the file's own `_comment`. Pass.
- 7, tests, run by QA in this folder: GUT 601 of 601 pass (56 scripts, `TESTS PASSED`, exit 0); `game/tools` Python 241 OK (1 skipped); `tools` Python 130 OK. QA also ran the full GUT suite with `flamethrower_at_start` set to false (then restored to true): 601 of 601 pass, so the tests do not depend on the switch's value. Pass.
- Note for the Project Lead (not a failure): GUT lists `ExhaustFlamethrower` nodes and `ExhaustFlame` drawings among its orphan reports: in the flamethrower's own test file whatever the switch says, and with the switch on also in the other run tests (state, timer, level-up, second run), next to the map and car orphans those tests already report. Tests still pass; worth tidying when the weapon plumbing (T-041/T-043) takes over attaching.

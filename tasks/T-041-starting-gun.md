---
id: T-041
title: The starting gun: aims itself and fires at enemies in range
status: in-qa
from: project-lead
to: weapon-behavior
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-022, T-040, T-036, T-044]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/weapons/unity-weapons-report.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-044-minions.md, game/README.md]
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

**Blocked until T-022 (the report), T-040 (the numbers), T-036 (the run) and T-044 (the minions it shoots at) are done.**

Build the starting gun as Weapons, Decisions describes it, copying the Unity prototype's behaviour from T-022's report:
- The car starts every run with it. There is no visible weapon on the car, only the bullets it fires.
- It fires only when an enemy is within range, aims by itself, and fires at set intervals.
- Bullets damage enemies through the damage function T-044 defines.
- Its upgrade tiers (T-040's data) can be applied from code. Offering them at a level-up is T-043.
- Weapons reset at the start of every run: a new run starts with the base gun.

The bullets are placeholders for now (a simple shape in the palette). The final bullet art comes from a separate art task and replaces them.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test with no enemy in range shows the gun never fires, and with an enemy in range it fires at the interval in T-040's data (QA: pass / fail)
- [ ] A test shows bullets go for the target the report's targeting rule picks (the rule is named in the result notes) and damage it by the data's amount (QA: pass / fail)
- [ ] A test applies each upgrade tier and shows the changed values take effect (QA: pass / fail)
- [ ] A test shows a new run starts with the base gun and no upgrades (QA: pass / fail)
- [ ] A screenshot shows the car firing placeholder bullets at a minion (QA: pass / fail)
- [ ] `docs/weapons.md` describes the built gun in Content, and `game/README.md` says how weapons plug into the run, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

**Weapon Behavior Agent, 2026-10-14.** Branch `task/T-041-starting-gun`, folder `C:\solid-carbide-worktrees\T-041`.

**What I built** (all under `game/scripts/weapons/`, plus 9 added lines in `game/scripts/run/run.gd`, its only change outside that folder):

- `weapons.gd`: the weapon rack, `run.weapons` (child `Weapons`). It holds one node per weapon (`WEAPON_SCRIPTS`), steps the projectiles and then the owned weapons once per physics step (pausable; nothing after the run ends), and on every new run (`run.world_rebuilt`) removes all bullets and resets the weapons: the gun at tier 1, nothing else. It finds targets, gives a weapon the car, the state, and a draw root for projectiles (`WeaponShots`, just before the car's `View`).
- `weapon.gd`: the base every weapon extends: `weapon_id`, `starts_owned`, `tier` (0 = not owned, 1 to 8), `set_tier()`, `upgrade()`, `reset_for_run()`, `apply_tier()`, `step(dt)`.
- `starting_gun.gd`: the gun. It checks for targets once per fire interval, fires volleys, and reads every number from `WeaponData.gun_at(tier)`.
- `bullet.gd`: the bullet, with placeholder art drawn in code: a small cyan dot with a white core and a dark outline, no Redgull red.
- **How T-042 fits in:** a new script extending `weapon.gd`, plus one line in `WEAPON_SCRIPTS`. Everything is written up in `game/README.md`, "Weapons".

**Targeting rule:** the Unity prototype's (report, section 2), **closest first**. At each check the gun takes every living enemy whose centre is within range of the car's centre and sorts them by distance. Bullet 1 goes to the closest, bullet 2 to the second closest, and so on, going round again from the closest when there are more bullets than enemies. Each bullet leaves the car's centre aimed at its target's centre at that moment, with no leading.

**Targets:** every node in the group `enemies` in the run that has `take_damage()` and is not dead. That covers the minions now and the kaiju once it joins that group with `take_damage()` and `position_units()`; `hit_radius_units()` is optional, for a body that is not a circle. The test's kaiju stand-in shows this works. Nothing reads `run.minions` or uses collision layers. Meteors have no `take_damage()`, so the gun never targets them.

**Choices the documents don't settle (for QA and the board to know):**
- A bullet starts moving on the physics step after it is fired, as in the prototype.
- A bullet hits each enemy at most once. When it touches several enemies in one step, it hits the closest first.
- A target that dies before its turn in a volley is still aimed at where it was last seen.
- The bullet is drawn 0.5 units above the ground. When it is level with the car in the depth order, the car is drawn over it, so a bullet seems to come out from under the car.

**Tests:** `game/tests/unit/weapons/test_starting_gun.gd` (21 tests). They cover each criterion:
- **Criterion 1:** `test_never_fires_without_an_enemy_in_range`, `test_fires_at_the_data_interval_with_an_enemy_in_range` (1.26 s) and `test_checks_only_once_per_interval`.
- **Criterion 2:** `test_bullet_goes_for_the_closest_enemy_and_damages_it_by_the_data_amount` (2), `test_volley_goes_round_the_enemies_closest_first` and `test_bullets_kill_a_minion_through_take_damage`.
- **Criterion 3:** `test_every_tier_applies_the_data_values`, `test_upgrade_steps_through_the_tiers`, `test_tier_2_and_6_fire_more_bullets`, `test_fire_rate_tiers_shorten_the_interval`, `test_reach_tier_widens_the_range` and `test_pierce_tier_hits_two_enemies_in_line`.
- **Criterion 4:** `test_new_run_starts_with_the_base_gun` and `test_new_run_from_the_main_menu_starts_with_the_base_gun`.
- **Also:** pause and the end of the run, the kaiju stand-in, a missed bullet removed past the range, and no Redgull red.

**Results:**
- Full GUT suite (`bash game/tools/run_tests.sh`): 56 scripts, 600/600 tests passed, `TESTS PASSED`.
- Python tool tests: `game/tools`, 241 ran, OK (1 skipped); `tools`, 130 ran, OK.

**Screenshots** (copies in git: `art-archive/T-041/screenshots/starting_gun.png` and `starting_gun_tier2.png`; originals in `screenshots/`, git-ignored):
- `bash game/tools/screenshot.sh res://tests/fixtures/starting_gun_demo.tscn screenshots/starting_gun.png 16`: the base gun's cyan bullet on its way to the closest minion.
- `bash game/tools/screenshot.sh res://tests/fixtures/starting_gun_tier2_demo.tscn screenshots/starting_gun_tier2.png 34`: the gun at tier 2, two of its three bullets flying to two minions.
- Both fixtures (`game/tests/fixtures/starting_gun_demo.gd`) start a run from the main menu, place four minions that stand still, and set the gun's clock so it fires on the first step.

**Numbers:** no data file was changed. No debug or cheat input was added.

**What the board should look at in the playtest:** start the game and press Start, then drive near the minions.
- The gun fires on its own at the closest minion within 12 units, one bullet every 1.26 s, and a minion dies after 2 hits and may drop coins.
- Check that the bullets read well. They are small: the drawn size is the prototype's 0.32 units, a few pixels at the default zoom.
- Check whether the up-to-1.26 s wait before the first shot at a minion that has just come into range feels right (copied from the prototype, Weapons, Decisions).
- Check how bullets come out from under the car.
- Upgrades can't be picked in a run yet (T-043/T-052), so the tiers are checked by the tests only.

**Documents affected:** `docs/weapons.md`: Content only (new "The starting gun (built in task T-041)"; Summary, Decisions and Open questions unchanged). `game/README.md`: a new "Weapons" section, with one line each in "Folder layout" and "Collision layers".

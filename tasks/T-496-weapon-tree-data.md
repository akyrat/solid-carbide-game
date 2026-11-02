---
id: T-496
title: Weapon data for the board's upgrade trees
status: in-progress
from: project-lead
to: game-data
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/data/weapons.json, game/scripts/data/weapon_data.gd, game/scripts/weapons/starting_gun.gd, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/data/weapons.json, game/scripts/data/weapon_data.gd, game/scripts/weapons/level_up_offers.gd, game/tests/unit/, docs/weapons.md, game/docs/weapons/]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-02 (docs/weapons.md, Decisions, "The board's own upgrade trees"): put the board's tier lists into game/data/weapons.json for the gun, Hot Take Exhaust, Hot Drop, Bricks tiers 2 to 7 and Wiper Blade tiers 2 to 7, in the board's order, with the board's numbers. All of these use effects the game already understands for that weapon (data only). Bricks tier 8 (T-498) and Wiper Blade tier 8 (T-499) need new code and are added by those tasks; leave them out here, so Bricks and Wiper end at tier 7 until then (check the level-up offers stop at a weapon's last tier and don't break on a 7-tier weapon). The gun drops to 8 tiers (its own max_tier 8) and its targets stay 1 all run: no set_targets tier remains. The gun's single-target stream (each bullet, as it leaves, aims at its target if it is alive, otherwise at the closest living enemy) is already built (T-408) and is what the board wants; check it still holds with more bullets and the x4 fire rate. Update every _comment in weapons.json and every place in docs/weapons.md (Content) and game/docs/weapons/ that states the old tiers or numbers, and the tests that pin old tier values. Never write, move or commit anything in game/data/levels/. SFX stay off.

The board's review: play the new weapon trees in one build with T-495 to T-499 together (levelling each weapon to tier 8 with the playtest switches), from this ticket's folder, before merging.

Built on T-495's branch: the card text it needs is already here, and depends_on is cleared so it can start while T-495 waits for QA. T-495 and T-496 go to QA together once this is done, because T-495's level-up screen test expects the old 11 gun tiers until this task's data lands.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] weapons.json tiers match the Decisions entry for gun (tiers 2 to 8), flamethrower (2 to 8), molotov (2 to 8), bricks (2 to 7) and wiper (2 to 7): effect and value per tier, checked by a unit test. (QA: pass; data matches the Decisions entry, test_tiers_match_the_boards_trees passes)
- [ ] The gun's max_tier is 8 and no gun tier uses set_targets; a unit test shows a gun at tier 8 aims at one target at a time, and a bullet whose target died before it left aims at the closest living enemy. (QA: pass; max_tier 8, no set_targets; both starting_gun tests pass)
- [ ] A unit test shows the level-up offers never offer bricks or wiper past their last tier. (QA: pass; test_bricks_and_wiper_are_never_offered_past_their_last_tier)
- [ ] Neon Underglow's block in weapons.json is unchanged. (QA: pass; identical to master's block)
- [ ] docs/weapons.md Content and game/docs/weapons/ no longer state the removed tiers (Multi-Target Mode, turn speed, the molotov damage and fire-duration tiers, the wiper damage tiers). (QA: pass; Content and game/docs/weapons/ are updated. The T-412 card-text list in docs/weapons.md still lists the old gun tiers 6 to 11 but is labelled as gone since T-495/T-496: Project Lead may tidy it)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: fail: code - Godot set 2613 of 2615 pass; 2 red, each rerun alone with the same result: tests/unit/weapons/test_size_grow.gd test_every_size_tier_in_the_data_grows_to_its_size still pins the old wiper tiers (tier 5 keeps size, 6 grows, 7 keeps size; data now 5 grows, 6 no, 7 grows), and tests/unit/test_enemy_data.gd test_kaiju_time_to_kill_matches_result_notes pins old gun-tier kill times (gun 6/8/11 cases). Python game/tools set: 904 of 905 pass, the red one is test_check_level_up_texts.test_the_real_files_match_t171s_table_with_t301s_texts, comparing level_up_texts.gd to an old table, 20 diffs from T-495's new texts (e.g. molotov tier4 'Another one' vs 'Spicier Fire'))
- [ ] Screenshots of the level-up screen offering a changed card for at least three weapons, under art-archive/T-NNN/screenshots/. (QA: pass; 3 screenshots, cards for gun, molotov, flamethrower, wiper, bricks)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, In progress → In QA

Weapon data in; bricks and wiper stop at tier 7 until T-498/T-499.

### 2026-11-02, In QA → In progress

QA failed: stale tests pin old tier values (Godot test_size_grow, test_enemy_data; python test_check_level_up_texts). Data and docs pass.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done by the Game Data Agent (2026-11-02). Code, data, docs, tests and screenshots committed in 4396fe64.

- game/data/weapons.json: gun tiers 2 to 8 (+1 bullet, +1, x1.2 rate, x1.2, +1 bullet, x1.2, x4), flamethrower 2 to 8 (size x1.2, damage x1.2, size x1.3, +1 s burn, size x1.3, +1 s burn, always on), molotov 2 to 8 (radius x1.2, interval x0.8, +1, +1, interval x0.7, radius x1.3, +1), bricks 2 to 7 (radius x1.4, damage x1.5, knockback x1.5, radius x1.5, damage x1.5, knockback x1.5), wiper 2 to 7 (length x1.2, sweep x1.25, knockback x1.5, length x1.3, sweep x1.3, length x1.3). Gun max_tier 8, no set_targets tier. Neon Underglow untouched (a unit test pins it). All _comment fields updated.
- Bricks and the wiper each got their own `max_tier: 7`, so the level-up offers stop there until T-498 and T-499 add tier 8 and raise it to 8.
- Data only for the numbers: every effect already existed in WeaponData. "+1 s burn" uses `add_burn_flash_seconds` (T-497 makes it afterburn). The flame turn-speed effect and the gun's set_targets stay in the code, unused by any tier.
- Single-target stream: no code change. At tier 8 (4 bullets, a volley every 0.234 s) each bullet re-aims at the closest living enemy if its target died. Tests: test_no_gun_tier_sets_targets_and_tier_8_aims_at_one_at_a_time, test_tier_8_a_dead_target_hands_the_next_bullet_to_the_closest_living.
- Offers stop at each weapon's last tier: new test that bricks and wiper are never offered past tier 7.
- Bricks wave art: new radii 4.0, 5.6, 8.4 needed sheets; built with the free script `python game/tools/build_bricks_wave.py build` (no PixelLab): bricks_wave_r5_6 and bricks_wave_r8_4 added. Old r4_8, r6_0, r7_8 kept, unused. T-498's tier 8 needs its own sheet from the same script.
- Note for the playtest: Bricks tier 7 radius is 8.4 units (old tier 8 was 7.8).
- Tests changed: test_weapon_data, test_starting_gun, test_level_up_offers, test_level_up_screen (T-495's count now 7+3*8+2*7), test_bricks, test_windshield_wiper, tools/test_build_bricks_wave.py. Run in the foreground, all passing: test_weapon_data, test_starting_gun, test_level_up_offers, test_level_up_screen, test_molotovs, test_windshield_wiper, test_bricks, test_exhaust_flamethrower, test_all_weapons_run, test_weapon_levels, test_damage_bonus, test_neon_underglow, test_weapons_wreck, test_weapon_art; python test_build_bricks_wave (10 ok). Full set not run (QA).
- Docs: docs/weapons.md (gun, flamethrower with "+1 s burn", molotov, wiper, bricks, offers, size-grow list; old Decisions marked superseded), game/docs/weapons/{starting-gun,flamethrower,bricks}.md, game/docs/data/game-data.md. Long GDD to regenerate at merge.
- Screenshots: art-archive/T-496/screenshots/level_up_a.png (gun Exposure for Everyone + molotov Quick Fire), level_up_b.png (flamethrower + wiper), level_up_c.png (bricks + molotov), from fixtures tests/fixtures/level_up_t496_{a,b,c}.tscn.
- Refusals: a hook refused inline python on the task file and the Edit of the task file was denied; I stopped and wrote these notes through task_notes.py as instructed.

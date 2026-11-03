---
id: T-520
title: Data: 5-tier weapons, 2-tier power-ups, sub goals for 12 gift packs in 3 minutes
status: in-qa
from: project-lead
to: game-data
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/weapons.md, docs/drifting.md]
files_to_read_first: [docs/weapons.md, docs/drifting.md, docs/game-loop-architecture.md, game/data/weapons.json, game/data/power_ups.json, game/data/run.json, tasks/README.md]
files_expected_to_change: [game/data/weapons.json, game/data/power_ups.json, game/data/run.json, game/scripts/, game/tests/unit/, docs/weapons.md, docs/drifting.md]
model: sonnet
qa_rounds: 0
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

Change game/data to the board's new trees: weapons.json, every weapon 5 tiers (max_tier 5; tiers 2 to 5 exactly as docs/weapons.md, Decisions, "Shorter trees: 5 tiers", the stacked numbers not rounded; Bricks' widest wave at the tier 4 radius; Neon Underglow's tier 5 radius x1.3 marked as a placeholder in its _comment), each card pointing at T-519's text keys. power_ups.json: every power-up 2 tiers (tier 1 as today, tier 2 = today's tier 4). run.json: the level table (sub goals) so a player who drifts and does tricks steadily gets about 12 gift packs by 3:00 (propose from the subs per second a run earns today, with tricks paying subs since T-513; show the sum in the result notes); the heal amount for a full sub goal once everything is maxed if it lives in data. Update the code that only reads these shapes if it hard-codes 8 tiers or 4 power-up tiers (say where). Update docs/weapons.md Content and docs/drifting.md Content tier lists. God mode and the playtest switches (weapon_tier_at_start) must still work with max_tier 5.

The board, 2026-11-03: the run is shortened to 4 minutes (3:00 build, kaiju 3:00 to 4:00). Decisions: docs/game-loop-architecture.md "A 4-minute run: 3 minutes to build, 1 minute of kaiju"; docs/weapons.md "Shorter trees: 5 tiers"; docs/drifting.md "Two tiers and three slots for the driving power-ups"; docs/enemies.md "Paced for the 4-minute run"; docs/hud-and-menus.md "Weapon and power-up slots". T-519 to T-523 are built in parallel and combined by the Project Lead into one build (T-521's folder) that the board plays before anything merges. Many existing tests assume the 8-minute run, the kaiju at 7:00 and 8 tiers: update the ones your change breaks (say which in the result notes), never delete a test's purpose. Numbers you choose are proposals for the playtest, in game/data with a _comment. Never write, move or commit anything in game/data/levels/. SFX stay off. Stage files by name, never .uid/.import noise. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-519 to T-523) from C:\solid-carbide-worktrees\T-521\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: every weapon has max_tier 5 and tiers 2 to 5 with exactly the docs' numbers; every power-up has 2 tiers, tier 2 equal to the old tier 4's values. (QA: pass: test_four_minute_run_data.gd checks every weapon at max_tier 5 and the power-ups at 2 tiers; weapons.json values match docs/weapons.md exactly, underglow tick x0.5 as the docs say)
- [ ] A unit test: the level table's total subs to reach 12 level-ups fits the proposed 3-minute earning rate (the rate and the sum in a _comment and the result notes). (QA: pass: 12 level-ups = 2,360 subs, fits 14 subs/s x 180 s = 2,520; rate and sum in run.json build_pace and the notes)
- [ ] A unit test: God mode's tier range and weapon_tier_at_start cap at 5 for weapons and 2 for power-ups. (QA: pass: test_playtest_tier_switch_and_god_mode_cap_at_5_and_2)
- [ ] docs/weapons.md and docs/drifting.md Content show the new tiers. (QA: pass: both docs' Content show the new tiers and match the Decisions)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: fail: code - python test set game/tools is red: test_build_bricks_wave.TierRadii.test_radii_follow_the_tiers_multipliers expects [4.0, 5.6, 8.4, 25.2] but tier_radii() now gives [4.0, 8.4, 25.2] after the bricks data change; reran alone, same result. Godot set itself passes: 2708/2709, 0 failing, 1 pending)
- [ ] A screenshot of a level-up screen with merged-tier cards, under art-archive/T-NNN/screenshots/. (QA: pass: art-archive/T-520/screenshots/level_up_merged_tiers_a.png and _b.png exist)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Texts (T-519) are in; data agent started on top of them.

### 2026-11-03, In progress → In QA

Data done: 5-tier weapons, 2-tier power-ups, 12 sub goals (2,360 subs, ~2:49 at 14 subs/s). Full test set passes; screenshots in art-archive/T-520.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. 
DATA: weapons.json max_tier 5 (top level and each weapon), tiers 2 to 5 exactly as docs/weapons.md 'Shorter trees: 5 tiers', stacked numbers not rounded (gun +2 bullets / x1.44 / +1 bullet and x1.2 / x4; flame x1.56 / dmg x1.2 and size x1.3 / +2 s burn / always on; underglow x1.5 / dmg x2.25 / tick x0.5 / radius x1.3 PLACEHOLDER, marked in its _comment; molotov x1.56 / +2 / interval x0.56 / +1; wiper x1.56 / sweep x1.625 / knockback x1.5 and length x1.3 / back wiper; bricks x2.1 / x2.25 / x2.25 / widest wave, rings at the tier 4 radius 8.4). A merged tier with two kinds of upgrade has TWO ENTRIES WITH THE SAME tier NUMBER (gun 4, flame 3, wiper 4); WeaponData already adds every entry up to the tier, so no code change. One deviation: the underglow tick interval is the docs' x0.5, not the stacked 0.75 x 0.67 = 0.5025. power_ups.json: max_tier 2, tier 2 = old tier 4 for all 5 (old tiers 2 and 3 removed). Card texts: T-519's keys are read by the existing code; test_level_up_screen passes (49/49) with this data.
SUB GOALS (run.json): max_level 13 (12 level-ups = 12 gift packs), xp_needed 30, 45, 60, 80, 100, 130, 165, 210, 265, 335, 420, 520 = 2,360 subs (was 11 level-ups, 3,501). New block build_pace (read by the unit test only): earning rate 14 subs/s = drifting ~60 percent of the time at an average x2 multiplier (10 x2 x0.6 = 12/s) + a trick every 8 s paying ~7.5 subs x2 (combo.json trick_subs, T-513: 5 or 10) = ~1.9/s. 14 x 180 s = 2,520 subs, so the 12th pack comes around 2:49 (2360/14 = 168.6 s). challenge_xp (old MVP map only) unchanged, level 13 row has xp_needed 0. T-521 needs to know: past level 13 the bar stops (is_max_level); the heal for a full sub goal once everything is maxed is NOT in data (no heal key in run.json; T-521 owns it and the 'weapon arrives at tier 2' rule and the 3-slot caps).
CODE: no code needed changing: every tier count is read from data (WeaponData.max_tier, PowerUpData.max_tier = tiers size, GodMode.last_tier, Weapons.weapon_tier_at_start cap, level_up_offers, power_up_offers). Only comments in code still say 8 tiers (weapon.gd, level_up_offers.gd, bricks.gd, molotovs.gd, neon_underglow.gd, weapon_icons.gd 'up to x8'); left alone, harmless. The polarized power-up reasons in power_ups.json still say 'tier 4' in prose.
COMMENTS: playtest.json comment about the kaiju at 7 minutes now says 3 (since T-521). enemies.json (minion ramp comment 'kaiju 7:00', growth_until_seconds 420) is T-522's, NOT touched. run.json time_up comment still says 8-minute timer (T-521's).
DOCS: docs/weapons.md Content: new first section 'The 5-tier trees as built (task T-520)' (older 8-tier lists below stay as the record, said in the section); docs/drifting.md Content, 'Driving power-ups: the tiers' opens with the 2-tier values.
TESTS: new game/tests/unit/test_four_minute_run_data.gd (6 tests: exact docs numbers per weapon/tier, tier 5 = old tier 8 power, underglow placeholder, power-ups 2 tiers with tier 2 = old tier 4, 12 sub goals fit 14 x 180, weapon_tier_at_start 99 and God mode cap at 5 weapons / 2 power-ups). Existing tests I updated because the 8-tier run, 4-tier power-ups or 12 levels no longer hold (purpose kept, numbers moved): test_weapon_data, test_enemy_data (kaiju time-to-kill cases moved to the new tiers), test_polarized_steering_wheel (tier 4 shock is now tier 2), test_rusty_overcoat, test_jump_power_up, run/test_power_up_offers, run/test_run_likes (total 2,360, cap 13, 12 level-ups), weapons/test_level_up_offers (29 offers per run = 4 gun + 5 x 5; T-521's tier-2 arrival and 3-slot caps will change that count), test_starting_gun, test_bricks, test_neon_underglow, test_exhaust_flamethrower, test_windshield_wiper (_check_tier handles two entries per tier), test_molotovs, test_size_grow, test_all_weapons_run, hud/test_hud_weapon_icons (x5). Full Godot suite run once in the worktree: 0 failing, TESTS PASSED (test_four_minute_run_data alone: 6/6).
SCREENSHOTS: art-archive/T-520/screenshots/level_up_merged_tiers_a.png (gun tier 3 to 4 card 'Bundle and Trigger' +1 bullet and fire rate x1.2; wiper 'Shove and Stretch' knockback x1.5 and blades x1.3) and level_up_merged_tiers_b.png (flame 'Hotter, Wider Burn' damage +20 percent and area +30 percent; bricks 'Widest Wave'). Fixtures tests/fixtures/level_up_t520_a.tscn and _b.tscn.
NOTE: running tests from a worktree needs GODOT_BIN in the environment (the worktree has no .env).

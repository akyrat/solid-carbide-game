---
id: T-521
title: The 4-minute run: kaiju at 3:00, 3 weapon and 3 power-up slots, new weapons at tier 2, the heal
status: in-qa
from: project-lead
to: game-loop
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [docs/game-loop-architecture.md, docs/weapons.md, docs/drifting.md, tasks/README.md]
files_expected_to_change: [game/scripts/, game/data/, game/tests/unit/, game/docs/, docs/game-loop-architecture.md]
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

Build the run rules of docs/game-loop-architecture.md, Decisions, "A 4-minute run": the kaiju arrives at 3:00 (the boss time signal) and the run ends at 4:00; the clock's colour switch points and anything else timed to 8:00/7:00 in the run follow (say what). The player owns at most 3 weapons (the gun counts): once 3 are owned, the level-up offers only upgrades of those 3; a weapon picked for the first time arrives at tier 2 (its tier 1 and 2 applied in order). Once all 3 owned weapons are at their last tier, a full sub goal heals the car (amount: your proposal, in data) and shows T-519's heal message, with no level-up screen. At most 3 driving power-ups: once 3 are owned, missions offer only upgrades of those 3 (and nothing new once all 3 are maxed: say what a mission gift does then, a proposal). Pace the missions for the 3-minute build (how many, how fast: proposals). Read max tiers from data (T-520 changes them to 5 and 2 in parallel; don't hard-code). T-520 and T-522 and T-523 are built in parallel; the Project Lead combines them in this ticket's folder for the board's playtest. Update docs/game-loop-architecture.md Content.

The board, 2026-11-03: the run is shortened to 4 minutes (3:00 build, kaiju 3:00 to 4:00). Decisions: docs/game-loop-architecture.md "A 4-minute run: 3 minutes to build, 1 minute of kaiju"; docs/weapons.md "Shorter trees: 5 tiers"; docs/drifting.md "Two tiers and three slots for the driving power-ups"; docs/enemies.md "Paced for the 4-minute run"; docs/hud-and-menus.md "Weapon and power-up slots". T-519 to T-523 are built in parallel and combined by the Project Lead into one build (T-521's folder) that the board plays before anything merges. Many existing tests assume the 8-minute run, the kaiju at 7:00 and 8 tiers: update the ones your change breaks (say which in the result notes), never delete a test's purpose. Numbers you choose are proposals for the playtest, in game/data with a _comment. Never write, move or commit anything in game/data/levels/. SFX stay off. Stage files by name, never .uid/.import noise. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-519 to T-523) from C:\solid-carbide-worktrees\T-521\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: the kaiju arrives at 3:00 and the run ends at 4:00 (win and loss as before). (QA: pass: test_four_minute_run.gd test_the_run_is_four_minutes_and_the_kaiju_comes_at_three and test_killing_the_kaiju_in_its_minute_still_wins; green)
- [ ] A unit test: with 3 weapons owned, level-up offers contain only upgrades of those 3; a weapon picked for the first time is at tier 2. (QA: pass: test_with_three_weapons_the_offers_are_only_their_upgrades and test_a_weapon_picked_for_the_first_time_is_at_tier_2; green)
- [ ] A unit test: with all 3 owned weapons at their last tier, a full sub goal heals the car, shows the heal message key and opens no level-up screen. (QA: pass: test_all_three_maxed_means_a_full_sub_goal_heals_and_opens_no_screen checks the heal, the heal.popup text and no level-up screen; green)
- [ ] A unit test: with 3 power-ups owned, mission gifts offer only those 3; the behaviour once all are maxed is tested as proposed. (QA: pass: test_with_three_power_ups_the_gifts_offer_only_those and test_once_all_three_are_maxed_the_gift_is_skipped; green)
- [ ] Max tiers are read from data, not hard-coded (test with a data file of other max tiers, or a grep in the result notes). (QA: pass: test_power_up_max_tiers_are_read_from_the_data_file and test_the_weapons_last_tier_is_the_datas; max_tier read from data)
- [ ] docs/game-loop-architecture.md Content describes the 4-minute run and the caps. (QA: pass: Content section 'The 4-minute run's caps and the heal (T-521)' and Decisions describe 4:00, kaiju at 3:00, caps 3/3)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass: qa_check on the combined result: game/tools set and full Godot set pass; tools set skipped (nothing under tools/ changed))
- [ ] Screenshots: the kaiju arriving at 3:00, a level-up with 3 weapons owned, and the heal message, under art-archive/T-NNN/screenshots/. (QA: pass: art-archive/T-521/screenshots has kaiju, levelup (3 weapons), heal and combined_* images)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Texts (T-519) are in; game-loop agent started on top of them.

### 2026-11-03, In progress → In QA

Built: kaiju 3:00, end 4:00, 3-weapon and 3-power-up caps, tier-2 first pick, heal with message once all maxed, clock/timeline/missions paced. Tests pass; screenshots in art-archive/T-521.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. RULES: kaiju at 3:00 and end at 4:00 (RunState.RUN_SECONDS 240, BOSS_TIME_LEFT 60). Caps and heal in NEW game/data/slots.json (SlotRules): max_weapons 3, max_power_ups 3, first_pick_tier 2, heal_hearts 2 (proposal). Weapons.slots_full/all_owned_maxed/pick; LevelUpOffers offers no get_* when 3 owned and applies picks with pick() (new weapon at tier 2, tiers applied in order); PowerUpOffers offers only owned ones once 3 owned. HEAL: RunState._gain_xp calls heal_for_sub_goal() when sub_goal_heals() (3 owned, all at last tier): no helicopter (GiftDrops), no choice screen, signal sub_goal_healed; TrickPopups shows screen_texts heal.popup; not while wrecked. All-maxed power-ups: gift skipped (power_ups.json offer_when_exhausted skip_gift, proposal). MAX TIERS from data only (Weapon.max_tier -> weapons.json, PowerUpData.max_tier); grep: no tier number in the new code; test with a 1-tier power_ups file. TIMED TO 8:00/7:00 AND NOW FOLLOWING: clock label (reads RUN_SECONDS), clock colour steps (hud.json timer_clock.steps: green >2:00 left, yellow >1:00, orange >0:20, red; proposals), tutorial slide 4 timeline (RUN_MINUTES 4, labels 4:00/2:00/1:00, kaiju zone the last quarter, gift packs moved), missions (missions.json: 12 missions not 30, goal ranges 6-8:1, 9-11:2, 12:3, growth x2.5; proposals). Comments fixed in run_state/run/kaiju_boss. NOT MINE/LEFT: run.json time_up _comment still says 8-minute (T-520 owns run.json, comment only); enemies.json/test_minions (7:00, 420) are T-522 and fail now (test_spawn_interval_at_the_start_at_7_minutes_and_between). NOTE FOR THE MERGE: T-520 says 12 sub goals (12 packs) = exactly the 12 picks that max 3 weapons (4 gun + 4+4). weapons/test_level_up_offers.gd and run/test_power_up_offers.gd were edited by both T-520 and me: expect a conflict; mine lifts the cap in before_each (rack.slot_rules._data max_weapons 99), counts picks as sum(max_tier-1) over 6 weapons, new weapons at tier 2, and reads last tiers from data. DOCS: docs/game-loop-architecture.md (new Content section 'The 4-minute run's caps and the heal (T-521)', 8:00/7:00/30 missions fixed), game/docs/game-loop/the-run.md (new section). TESTS: new tests/unit/run/test_four_minute_run.gd 18/18. Updated (clock, 7:00 to 3:00, 30 missions to data total, tier 1 to 2): test_run_state, test_hud_timer, test_hud_timer_clock, test_hud_style, test_tutorial_slides, test_missions, test_power_up_offers (polarized as gift while 2 owned, last tier from data), test_run_likes_drain (400 s to 200 s), test_kaiju, test_level_up_offers, test_game_map, test_pause_restart_exit, test_screen_flow, test_tutorial_flow, test_run_scene, level_creator end_to_end/families/play_level/road_brush (8:00 to 4:00). Ran dirs run, hud, game, weapons, enemies, level_creator on today's (8-tier) data: all pass except test_minions (T-522); then re-ran the touched files: all pass. NOT run with T-520's data merged. SCREENSHOTS art-archive/T-521/screenshots/: kaiju.png (clock 1:00 left in orange; the kaiju walks in from off screen so is not in frame), levelup.png (3 weapons owned: only 2 upgrade cards), heal.png (heal message above the car, hearts 4 of 5 after a 3-heart hit). Fixtures tests/fixtures/four_minute_demo.gd and four_minute_*.tscn. Proposals for the playtest: heal 2 hearts, the colour steps, 12 missions.

COMBINED BUILD (Project Lead's request): merged T-520 (conflicts in test_power_up_offers and test_level_up_offers: kept T-521's data-driven versions, plus T-520's tier 5 bricks radius/rings asserts), T-522 (conflicts in kaiju_boss, test_kaiju, test_enemy_data: took T-522's; re-applied advance(150) in test_kaiju), T-523 (clean), master (docs/game-loop-architecture.md: took master's line). Merged one by one (octopus refused). Full Godot set on the result: 17 failures, all mine to fix and fixed: test_level_up_screen (3-weapon cap lifted in before_each; first pick tier 2), test_gift_drops (new weapon tier 2), test_mission_data (12 missions); re-run: 49, 56 and 5 pass. test_minions was green via T-522. Python game/tools set: 977 tests, 1 failure test_build_bricks_wave.TierRadii (T-520's, being fixed there; re-merge T-520 afterwards). The tools/ Python set and a full Godot re-run after these test fixes were not re-run. SCREENSHOTS art-archive/T-521/screenshots/combined_*.png (levelup = 5-tier weapon card, newweapon = get card at tier 2 beside an upgrade, slots = 3 weapon and 3 power-up grids with pips, heal = popup, kaiju) and copies in art-archive/T-519/screenshots/ (level_up_card_5_tier, level_up_new_weapon_tier2, heal_popup); the clock reads 4:00 in combined_slots and combined_heal.

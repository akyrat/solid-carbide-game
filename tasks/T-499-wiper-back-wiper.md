---
id: T-499
title: Wiper Blade tier 8: a back wiper
status: in-qa
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/windshield_wiper.gd, game/data/weapons.json]
files_expected_to_change: [game/data/weapons.json, game/scripts/weapons/windshield_wiper.gd, game/scripts/data/weapon_data.gd, game/tests/unit/, docs/weapons.md, game/docs/weapons/]
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

The board, 2026-11-02 (docs/weapons.md, Decisions, "The board's own upgrade trees"): Wiper Blade tier 8 (Back Wiper) adds a second wiper at the back of the car: an exact copy of the front one with all its upgrades (length, sweep speed, knockback, damage), sweeping behind the car, mirrored, with the same blade art. Each wiper hits on its own (its own hit cooldown per enemy). Add the tier to weapons.json (a new effect for this tier, your choice of name) and describe it in docs/weapons.md Content (the windshield wiper) and game/docs/weapons/. Never write, move or commit anything in game/data/levels/. SFX stay off.

The board's review: play the new weapon trees in one build with T-495 to T-499 together (levelling each weapon to tier 8 with the playtest switches), from this ticket's folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] weapons.json wiper has tier 8 with the new effect, and the wiper reaches tier 8 in the level-up offers; the tier 8 card is T-495's text. (QA: pass; max_tier 8, tier 8 add_back_wiper, offers use max_tier)
- [ ] A unit test: below tier 8 there is one wiper; at tier 8 there are two, the second behind the car, with the same length, sweep speed, damage and knockback as the front one. (QA: pass; test_one_wiper_below_tier_8_and_two_at_tier_8)
- [ ] A unit test: an enemy behind the car is hit by the back wiper at tier 8 and not below it. (QA: pass; test_back_wiper_hits_an_enemy_behind_only_at_tier_8)
- [ ] The back wiper uses the same blade art, mirrored (screenshot). (QA: pass; both_wipers_75/90 show a wiper in front and one behind with the same blade art; test_back_wiper_draws_with_the_same_art)
- [ ] docs/weapons.md (the windshield wiper) describes tier 8. (QA: pass; Content paragraph and Tiers describe it)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: fail: code - game/tests/unit/test_level_up_screen.gd line 581 still pins 7 + 3*8 + 2*7 = 45 choices; with wiper tier 8 it is 46, so test_every_choice_and_tier_the_offers_can_produce_has_text is red, a stale pin this ticket caused. The other reds are the 2 known T-496 pins (test_check_level_up_texts, test_kaiju_time_to_kill_matches_result_notes); test_size_grow passes. Godot 2617/2619, game/tools 1 fail)
- [ ] Screenshots of the car with both wipers mid-sweep, under art-archive/T-NNN/screenshots/. (QA: pass; both_wipers_60/75/90)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-495 and T-496 (built on their branch).

### 2026-11-02, In progress → In QA

Back wiper built (tier 8, mirrored, own hit cooldown); tests and screenshots in; ready for QA.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

T-499 done (Weapon Behavior Agent).
- weapons.json wiper: max_tier 8, tier 8 effect `add_back_wiper`. wiper_at(8)["back_wiper"] is true; offers reach tier 8 (level_up_offers uses each weapon's max_tier).
- windshield_wiper.gd: the front wiper makes a second instance of the same script (`back_wiper`, `is_back`) at tier 8 with the same tier and stats, steps it, re-emits its enemy_hit. Back one: forward() reversed (pivot on the tail, arm behind the car), turn_sign() -1 (mirror image across the cross axis), own last_hit/pass_index/drawing, same sheet art. Gone below tier 8 / new run.
- Tests: 4 new in test_windshield_wiper.gd (one vs two wipers with equal stats; enemy behind hit only at tier 8; own hit cooldown and mirrored; same art). Updated for wiper max 8: test_weapon_data, test_level_up_offers (46 level-ups per run), test_size_grow (wiper size tiers 2,5,7: stale from T-496, fixed). Ran only: test_windshield_wiper, test_weapon_data, test_level_up_offers, test_weapons_wreck, test_weapon_levels, test_size_grow, test_weapon_art: all pass.
- Docs: docs/weapons.md (Content wiper paragraph, built-wiper Tiers bullet, level-up offers), game/docs/weapons/windshield-wiper.md.
- Screenshots: art-archive/T-499/screenshots/both_wipers_60/75/90.png (the others, _130 to _300, are from failed fixture attempts: tutorial/menu runs with no wiper; ignore). Fixture tests/fixtures/weapons/wiper_back_demo.tscn.
- Proposal for playtest: "mirrored" = mirror image across the car's cross axis (the arms form a V, sweeping opposite ways), not a 180-degree turn of the front one. If the board wants both to sweep the same rotational way, remove turn_sign().
- Could not rm the stale screenshots (safety check refused rm on art-archive/T-499/screenshots/*); left for you to delete if wanted.

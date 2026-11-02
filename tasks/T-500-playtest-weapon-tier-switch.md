---
id: T-500
title: Playtest switch: start a run with every weapon at a chosen tier
status: done
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, game/data/playtest.json, game/scripts/weapons/weapons.gd, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/data/playtest.json, game/scripts/weapons/weapons.gd, game/tests/unit/, game/docs/weapons/]
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

So the board can play the new weapon trees (T-495 to T-499) at their top tiers without a long run, add one playtest switch to game/data/playtest.json: `weapon_tier_at_start` (an integer, default 0 = off, the game's rule). When it is 1 or more and `all_weapons_at_start` is true, every weapon starts the run at that tier, capped at each weapon's own last tier (max_tier), with every tier's effects applied as if levelled up in order. With it at 0, nothing changes. Never visible to players; the level-up offers then offer only what is left (nothing for a weapon at its last tier). Document the key in playtest.json's _comment like the others, and in game/docs/weapons/ where all_weapons_at_start is described. Leave the switch off (0) and all_weapons_at_start false in the committed file. Built from master, so it works with today's tiers and the new trees alike. Never write, move or commit anything in game/data/levels/. SFX stay off.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/playtest.json has weapon_tier_at_start: 0 and its _comment describes it; all_weapons_at_start stays false. (QA: pass; verified in the file)
- [ ] A unit test: with all_weapons_at_start true and weapon_tier_at_start 8, every weapon starts the run at min(8, its max_tier) with the same stats as levelling it up tier by tier. (QA: pass; test_tier_8_puts_every_weapon_at_min_8_and_its_max_tier)
- [ ] A unit test: with weapon_tier_at_start 0, a run starts as before (gun at tier 1 only). (QA: pass; test_tier_0_starts_as_before_gun_at_tier_1_only)
- [ ] A unit test: the level-up offers never offer a weapon already at its last tier. (QA: pass; test_offers_never_offer_a_weapon_at_its_last_tier)
- [ ] The Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass; qa_check test sets passed)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: a playtest-only switch to start every weapon at tier 8, so the board can play the new trees.

### 2026-11-02, In progress → In QA

weapon_tier_at_start added (0 = off); tests pass.

### 2026-11-02, In QA → Done

QA passed all 5 criteria; tests green. No board review line, so done.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Added `weapon_tier_at_start` (int, 0 = off) to game/data/playtest.json (_comment updated; all_weapons_at_start stays false). weapons.gd: static `weapon_tier_at_start()` plus `weapon_tier_override` for tests; in reset_for_run(), when all_weapons_at_start is on and the tier is above 1, every weapon is upgraded in order until min(tier, max_tier()) (max read from each weapon, nothing hard-coded). Documented in game/docs/weapons/shared.md. New test file game/tests/unit/weapons/test_weapon_tier_at_start.gd (8 tests: tier 8 equals levelling in order with same stats, cap, tier 2, switch alone does nothing, tier 0 as before, offers never offer a last-tier weapon, committed file off). Ran test_weapon_tier_at_start.gd (8/8) and test_level_up_offers.gd (30/30) with -gselect. No SFX or levels changes.

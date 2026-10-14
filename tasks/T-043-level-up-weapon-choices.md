---
id: T-043
title: Level-up offers: the 2 choices, and applying the one taken
status: done
from: project-lead
to: weapon-behavior
lead: Weapons
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-037, T-041, T-042]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/game-loop-architecture.md, tasks/T-037-likes-and-levels.md, tasks/T-041-starting-gun.md, tasks/T-042-exhaust-flamethrower.md, game/README.md]
files_expected_to_change: [the weapon code, tests, docs/weapons.md, game/README.md]
model: sonnet
qa_rounds: 1
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

**Blocked until T-037 (levels), T-041 (the gun) and T-042 (the flamethrower) are done.**

Weapons, Decisions describes the MVP level-up flow: each level-up offers 2 choices and the player takes 1. The first offer is "get the flamethrower" or "upgrade the gun"; after that, "upgrade the gun" or "upgrade the flamethrower".

Build the logic:
1. On T-037's "level up" signal, work out the 2 choices for the current state and make them available to the level-up screen (a later UI task). Each choice has an id, so the screen can show its text.
2. A function the screen calls with the chosen id. It applies the choice (gives the flamethrower, or the weapon's next upgrade tier), then calls T-037's "choice made" function so the run resumes.
3. A weapon at its last tier isn't offered. If nothing can be offered, skip the choice and resume the run; the docs don't cover this case, so say what you did in the result notes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test shows the first level-up offers exactly "get the flamethrower" and "upgrade the gun" (QA: pass)
- [x] A test takes the flamethrower and shows later level-ups offer "upgrade the gun" and "upgrade the flamethrower" (QA: pass)
- [x] A test takes each choice and shows it is applied and the run resumes (QA: pass)
- [x] A test shows a weapon at its last tier is not offered (QA: pass)
- [x] `game/README.md` documents the choice ids and functions for the UI Agent, and `docs/weapons.md` describes the flow in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

Built the level-up offers (Weapon Behavior Agent).

- Code: `game/scripts/weapons/level_up_offers.gd`, created by the rack (`weapons.gd` `bind()`) as `run.weapons.offers`. It listens to `RunState.level_up_choice_started`, works out the offers (`compute_offers()`), stores them in `current_offers` and emits `offers_ready(level, offers)`. `choose(id) -> bool` applies the choice through `rack.upgrade()`, emits `offer_taken(id)` and calls `state.choice_made()`. `run.gd` and `run_state.gd` unchanged.
- Choice ids: `upgrade_gun`, `get_flamethrower`, `upgrade_flamethrower`. Order: the gun's first.
- Playtest switch: `flamethrower_at_start` still works. A run that starts with the flamethrower owned offers `upgrade_gun` and `upgrade_flamethrower` from the first level-up (tested). I only reworded the switch's comment in `weapons.gd`.
- Docs did not cover (simplest choice taken): (1) only one weapon left to offer: that one choice alone is offered; (2) nothing to offer: the choice is skipped by calling `state.choice_made()` at once, no `offers_ready`, so the screen never opens; (3) several levels at once: choices come one after another (T-037's queue); (4) an id not on offer is refused (false, nothing changes).
- Offers only happen when `state.pause_on_level_up` is on (T-037/T-052); with it off, levels still rise with no choice.
- Docs: `docs/weapons.md` Content gets "The level-up offers" and two stale "not built yet" lines are updated (Summary, Decisions, Open questions untouched); `game/README.md` gets "The level-up offers" for the UI Agent.
- Tests: `game/tests/unit/weapons/test_level_up_offers.gd` (10 tests). Full GUT suite: 636 tests, all pass. Python tool tests: exit 0.


### QA round 1 (QA/Integration)

All 6 criteria pass. Evidence: tests test_first_level_up_offers_flamethrower_and_gun_upgrade, test_after_taking_the_flamethrower_offers_both_upgrades, test_taking_each_choice_applies_it_and_resumes, test_a_weapon_at_its_last_tier_is_not_offered; GUT 636/636; game/tools Python 241 OK (1 skipped); tools Python 171 OK. Ran the T-043 tests, the full GUT suite (636 tests) and both Python test sets in this folder. Docs diff checked: only Content and stale 'not built yet' lines changed.

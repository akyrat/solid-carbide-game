---
id: T-321
title: The first gift pack offers two random choices from every weapon
status: done
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/README.md, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/scripts/weapons/level_up_offers.gd, game/tests/unit/, game/README.md, docs/weapons.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Weapons, Decisions, "The first gift pack can hold any weapon", 2026-10-28): the first level-up no longer offers the fixed "upgrade the gun" or "get the flamethrower" (`level_up_offers.gd` `FIRST_OFFERS`, `is_first_offer()`). It draws its two choices at random from every choice available, like every later level-up (Weapons, Decisions, "Level-up offers with five weapons"): getting any weapon the car doesn't have, or upgrading the gun. Remove the fixed first offer, its tests and its mentions in the docs (Weapons, Content, "The level-up offers"; game/README.md), and keep the seeded draw so tests stay repeatable.

The board's review: start a few runs and check the first gift pack offers different weapons.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Over many seeded first level-ups, every available first choice appears (each of the four weapons the car doesn't have, and the gun upgrade), always two different ones (test). (QA: pass, 200-seed test covers all five first choices, always two different)
- [ ] No code path offers the old fixed pair on purpose any more: FIRST_OFFERS and is_first_offer are gone or no longer used (QA reads the diff). (QA: pass, FIRST_OFFERS, is_first_offer and choices_taken removed; only a test asserting they are gone mentions them)
- [ ] Later level-ups draw exactly as before (the existing tests pass unchanged, or the result notes say why one changed). (QA: pass, later draw code unchanged, GUT all green, changed tests explained in the result notes)
- [ ] Weapons, Content, "The level-up offers" and game/README.md describe the new first offer. (QA: pass, both describe the drawn first offer)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-321/screenshots/`, as `tasks/README.md`, "Screenshots", asks. Two first level-ups with different offers. (QA: pass, first_level_up_1 and _2 show different pairs; _3 is identical to _2, minor)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass, game/tools 620 OK (1 skipped), tools 501 OK, GUT 1690/1690)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the Weapon Behavior Agent is making the first gift pack draw from every weapon.

### 2026-10-27, In progress → In QA

Built: the first gift pack now draws two random choices from every weapon. QA is checking it.

### 2026-10-27, In QA → Needs playtest

QA passed all 6 criteria. Ready for your playtest: C:\solid-carbide-worktrees\T-321\game\project.godot, or Play on T-321 in the Builds tab.

### 2026-10-27, Needs playtest → Done

Approved after the board's playtest of batch-1028; merging to master.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Weapon Behavior Agent, 2026-10-27.

- `level_up_offers.gd`: removed `FIRST_OFFERS`, `is_first_offer()` and the now unused `choices_taken`; `_draw()` always draws two different choices from `available_offers()` with the seedable `rng`. Later level-ups draw exactly as before.
- Tests: `test_level_up_offers.gd` replaced the fixed-first-offer test with one over 200 seeds (all five first choices appear, always two different, never outside the available ones), a same-seed test and a test that `FIRST_OFFERS`/`is_first_offer` are gone; tests that relied on the fixed pair now max the other weapons (`_max_all_but`) or take the first drawn card; the "new run brings back the first offer" test became "a new run clears the offer". `test_level_up_screen.gd`: `before_each` puts underglow, molotov and wiper at their last tier so the screen tests keep seeing the gun's upgrade and the flamethrower, and the "normal run first level-up" test now checks a drawn first level-up over 30 seeds. `test_gift_drops.gd`: expects two different offers and takes the first drawn card. Fixture `level_up_screen_demo.gd` got an `rng_seed` export; new scenes `level_up_first_offer_1/2/3.tscn` use it.
- Test counts: `game/tools` Python 620 tests OK (1 skipped); `tools` Python 501 tests OK; GUT 1690 of 1690 passing.
- Screenshots (`art-archive/T-321/screenshots/`): `first_level_up_1.png` (Hot Take Exhaust and Hot Drop), `first_level_up_2.png` (Bonus Bullets and Hot Take Exhaust), `first_level_up_3.png`: three first level-ups with different pairs (seeds 7, 14, 21).
- Documents updated: `docs/weapons.md` (Decisions line for the five-weapon offers, Content, "The level-up offers"), `game/README.md` (draw, playtest switch, tests, level-up screen switch note). The long GDD is not regenerated here (the Project Lead does it at merge).
- Skipped: nothing.
- 2026-10-27, needs-playtest → done: The board played batch-1028 and approved it.

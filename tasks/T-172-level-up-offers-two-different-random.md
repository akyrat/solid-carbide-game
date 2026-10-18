---
id: T-172
title: Level-up offers: two different random choices from all five weapons
status: open
from: project-lead
to: weapon-behavior
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: yes
depends_on: [T-168, T-169, T-170]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/weapons/level_up_offers.gd, game/scripts/weapons/weapons.gd, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd, game/data/playtest.json, game/tests/unit/weapons/test_level_up_offers.gd, game/README.md]
files_expected_to_change: [game/scripts/weapons/level_up_offers.gd, game/scripts/weapons/weapons.gd, game/data/playtest.json, game/tests/unit/weapons/test_level_up_offers.gd, docs/weapons.md, game/README.md]
model: opus
qa_rounds: 0
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

With five weapons each level-up still offers 2 choices, now two different ones drawn at random from every choice available: getting a weapon the car doesn't have, or the next tier of one it has (docs/weapons.md, Decisions, 2026-10-18). The first level-up of a normal run still offers exactly 'upgrade the gun' and 'get the flamethrower'. Extend `level_up_offers.gd` with ids `get_underglow`/`upgrade_underglow`, `get_molotov`/`upgrade_molotov`, `get_wiper`/`upgrade_wiper` next to the existing ones, draw the two at random with a generator tests can seed, never offer a weapon at tier 8, show one choice when only one is left and skip the choice when none is left (as today). `choose(id)` applies the new ids through the rack. Keep the `flamethrower_at_start` playtest switch working. Add one playtest switch in `data/playtest.json`, `all_weapons_at_start` (false by default, never visible to players, docs/hud-and-menus.md, Decisions, the dev flag), that gives all five weapons at the start of a run, for the integration check and the board's playtest.

The board's review: Level up several times in a run from the task folder and see two different random weapon choices each time.

## Acceptance criteria

- [ ] A test shows the first level-up of a normal run offers exactly `upgrade_gun` and `get_flamethrower`. (QA: pass / fail)
- [ ] Seeded tests over many later level-ups show: two different ids each time, every id drawn is available (a get for a weapon not owned, an upgrade for one owned below tier 8), and over the seeds every available id is offered at least once. (QA: pass / fail)
- [ ] Tests show one choice when only one is left, the choice skipped (run resumes, no offers_ready) when none is left, and the `flamethrower_at_start` switch still gives the flamethrower and leads to its upgrades being offered. (QA: pass / fail)
- [ ] Tests show taking each of the six new ids applies the weapon or its next tier and resumes the run, and `all_weapons_at_start` (false in the committed playtest.json) gives all five weapons at tier 1 when set to true. (QA: pass / fail)
- [ ] `docs/weapons.md` Content 'The level-up offers' and `game/README.md` 'The level-up offers' describe the random draw, the new ids and the switch; the game's test set passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

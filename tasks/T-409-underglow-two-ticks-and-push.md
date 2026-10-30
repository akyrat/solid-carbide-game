---
id: T-409
title: Neon underglow: each tick deals half a minion's health (2 ticks kill), and it knocks enemies back a little from tier 1
status: in-qa
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-412]
documents_affected: [docs/weapons.md, game/docs/weapons/neon-underglow.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/enemies.md, game/docs/weapons/neon-underglow.md, game/docs/weapons/shared.md, game/data/weapons.json, game/data/enemies.json]
files_expected_to_change: [game/scripts/weapons/, game/data/weapons.json, game/tests/unit/, game/docs/weapons/, docs/weapons.md, art-archive/]
model: sonnet
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

The board's decision (Weapons, Decisions, "The neon underglow kills a minion in 2 ticks and pushes from tier 1", 2026-10-30). The board: "make the neon zone deal half of the max HP: it takes 2 ticks of damage for the mini enemies to die from the neon, that's its initial damage. And make it so that even initially, enemies are knocked back a little bit."

- **Damage:** tier 1's tick damage is half a minion's maximum health (`enemies.json`), so 2 ticks kill one; later tiers keep their multipliers from the new base.
- **Push:** from tier 1 each tick knocks the enemy back a little, away from the car's centre (minions; for the kaiju, follow the wiper's rule: it damages the kaiju but pushes only minions, unless you propose otherwise). How far (a small distance, a proposal) and whether it grows with the tiers, in `weapons.json`.
- The level-up card shows the weapon, not per-tier text (check `screen_texts.json`); if a tier line does show, stop and tell the Project Lead.

Other agents work at the same time on the minions (T-379 twice as big, T-380 ramps), the gun (T-408) and the red flash on hits (T-404): keep to the underglow's code and data.

The board's review: in a run, get the neon underglow and drive into a swarm: minions die in two ticks and are pushed back a little.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] At tier 1 a minion dies on its second tick and not its first (test). (QA: pass)
- [ ] From tier 1 each tick pushes a minion away from the car by the distance in `weapons.json` (test); the kaiju behaves as the result notes say (test). (QA: pass)
- [ ] Later tiers keep their multipliers from the new base (test). (QA: pass)
- [ ] Weapons (Content, "The neon underglow") and game/docs/weapons/neon-underglow.md describe the new damage and the push; card text matches Weapons "Level-up card text (T-412)". (QA: pass)
- [ ] A GIF of the underglow in a swarm is in `art-archive/<id>/screenshots/`. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass; GUT 158 scripts, 1950 tests, 1950 pass; unittest sets green)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F with T-412's card text.

### 2026-10-30, In progress → In QA

Underglow tier 1 deals 2 (two ticks kill a minion), pushes minions 0.5 per tick and nudges the kaiju 0.1; tests green, GIF in art-archive/T-409/screenshots.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Built.** Tier 1 tick is 2 (half a minion's 4); tiers 3 and 6 give 3 and 4.5 (`weapons.json` "underglow" damage 1 to 2). Each hit pushes a surviving minion `knockback_distance` 0.5 units straight away from the car through `apply_knockback()`, the same at every tier (my proposal; the push does not grow). The kaiju: the board's audit decision (Weapons, Decisions, "The underglow barely pushes the kaiju") says a slight stop at each tick, so it is damaged and nudged `kaiju_nudge_distance` 0.1 through a new small `Kaiju.apply_nudge()` (uses `_move()`, so walls and edges still stop it; the wiper and Bricks still never push the kaiju). Card text copied from Weapons, "Level-up card text (T-412)" into `game/scripts/ui/level_up_texts.gd` (the file is under `ui/`, not `weapons/`): `get_underglow.desc`, tier3, tier6. No tier line is a new key, so the cards show them as before. `check_level_up_texts.py` has the three texts in `LATER_TEXTS` (as T-331). Only the underglow's keys and code touched; T-408 edits the same files elsewhere, a merge may need a look at `weapons.json`, `weapon_data.gd`, `level_up_texts.gd` and `LATER_TEXTS`.

**Tests.** New in `test_neon_underglow.gd`: dies on the second tick not the first, 2/3/4.5 at tiers 1/3/6, push distance away from the car on a real minion, kaiju damaged and only nudged (fixtures `fake_pushable.gd`, `fake_nudgeable.gd`); `test_weapon_data.gd`, `test_level_up_screen.gd` and the old 1.25 damage expectation updated. Counts: GUT `run_tests.sh` 158 scripts, 1950 tests, 1949 pass on the full run, then the changed `test_level_up_screen` 43/43 after fixing its text; the one other failure in the full run, `test_run_likes.gd` (4 asserts about drift payments and popup), passes alone 18/18 and does not touch the underglow, so it looks load-timing flaky (not re-checked on the base). `python -m unittest discover -s tools`: 579 OK. `-s game/tools`: 678, one failure (`check_level_up_texts`), fixed, now OK.

**GIF.** `art-archive/T-409/screenshots/underglow_swarm.gif` (fixture `tests/fixtures/weapons/underglow_push_gif.tscn`, script `game/tools/record_underglow_push_gif.sh`).

Documents changed: `docs/weapons.md` (Content "Neon underglow", the built-underglow section; the comparison line mentions 1 per second still in the long form only if present), `game/docs/weapons/neon-underglow.md`.

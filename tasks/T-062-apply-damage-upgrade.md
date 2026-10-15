---
id: T-062
title: Garage upgrade: damage bonus applied to the weapons
status: done
from: project-lead
to: weapon-behavior
lead: Weapons
epic: garage
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-057, T-041, T-042]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, docs/weapons.md, tasks/T-057-save-and-buy.md, tasks/T-041-starting-gun.md, tasks/T-042-exhaust-flamethrower.md, game/README.md]
files_expected_to_change: [the weapon code, tests, game/README.md]
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

**Blocked until T-057 (the saved upgrade levels), T-041 (the gun) and T-042 (the flamethrower) are done.**

At the start of every run, the damage bonus upgrade's current level (T-056's data, read through T-057) adds its percentage to the damage of the car's weapons: the gun and the flamethrower (Garage design, Decisions). It stacks with the weapons' own upgrade tiers; say how in the result notes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test at level 0 shows weapon damage is unchanged (QA: pass)
- [x] A test at a higher level shows both weapons' damage goes up by the data's percentage (QA: pass)
- [x] `game/README.md` says how the bonus reaches the weapons, and `docs/weapons.md` mentions it in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Updates

### 2026-10-15, Done

The garage damage bonus now reaches both weapons at the start of a run: gun and flamethrower damage are multiplied by 1 + bonus/100 on top of their tiers. Level 0 changes nothing and no level can be bought until the garage screen (T-058) merges, so it merged after QA (round 1, all 4 pass); the board feels it in the unified playtest build.

## Result notes

The run start (GameFlow.start_run) reads PlayerProgress.current_value("damage_bonus") and gives it to the weapon rack (set_damage_bonus). Both weapons multiply each tier's damage by 1 + percent/100 in apply_tier (boosted_damage in weapon.gd). Stacking: multiplicative with the weapon's own tier damage; the bonus is kept across weapon resets and re-applied to owned weapons when set. The flame's damage comes from the data's flamethrower value (2, equal to the gun's), boosted by the same factor. Tests: tests/unit/weapons/test_damage_bonus.gd (level 0 unchanged, higher level both weapons, stacking with tiers and a new run). Full GUT 683/683 pass, both Python sets OK. Docs: game/README.md, docs/weapons.md (Content only).
- 2026-10-15, in-qa → done: QA pass: L0 unchanged and level-up both weapons tested; no compounding (apply_tier rebuilds stats from fresh data dicts, bonus set not added; re-set and new run give same values); docs ok; GUT 683/683, Python OK

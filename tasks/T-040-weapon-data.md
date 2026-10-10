---
id: T-040
title: Weapon numbers: the gun, the flamethrower and their upgrade tiers
status: in-qa
from: project-lead
to: game-data
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-022, T-038]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/weapons/unity-weapons-report.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [JSON data under game/data/, tests, docs/weapons.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-qa | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-022 (the Unity weapons report) and T-038 (the data convention) are done.**

Weapons, Decisions says both MVP weapons and their upgrades copy the Unity prototype: the same tiers and what each tier changes. The Game Data Agent works out how upgrades scale from level to level, starting from the Unity values.

Write as JSON under `game/data/`:
- **The starting gun:** damage, range, fire interval, bullet speed, and anything else the report lists.
- **The exhaust flamethrower:** damage, the flame's size and shape values, how damage is applied over time, and anything else the report lists.
- **Each weapon's upgrade tiers:** what each tier changes, with its values.

Use the report's values where it gives them, and say in the result notes where you scaled or filled in.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data is valid JSON under `game/data/`, and a test loads it through T-038's loader (QA: pass / fail)
- [ ] A test compares the base values and tier changes with the report's tables and shows they match, except where the result notes explain a difference (QA: pass / fail)
- [ ] `docs/weapons.md` points to the data in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the Game Data Agent.

**Produced:** `game/data/weapons.json` (gun and flamethrower: base values and 7 tiers each); reader `game/scripts/data/weapon_data.gd`; tests `game/tests/unit/test_weapon_data.gd`; one line in References of `docs/weapons.md`; "Weapons (T-040)" in `game/README.md` (Game data). GUT: 109 of 109 pass.

**Values copied from the report, with the board's decisions applied:**
- Gun: damage 2, range 12, base interval 1.2 s + 0.06 s extra (1.26 s), 1 bullet, 0.05 s between bullets, speed 15, hit radius 1. Tiers: +2 bullets, fire rate x1.2 (three times), range x1.5, +2 bullets, pierce 1. The test checks every tier against the report's table (bullets, interval, range, pierce).
- Flamethrower: damage 2 (the gun's, as decided), tick 0.2 s, min speed 0.85, linger 0.2 s, starts at half size and reaches full size in 1 s, burn flash 0.38 s. Tiers: size x1.2, damage x1.2, size x1.2, flash +0.5 s, size x1.3, car turn speed x1.2 (compounding), always on. The test checks size, area, flash and turn per tier against the report's table.
- Board's fixes: flame damage is never rounded, so tier 3 gives 2.4 (the report's rounding gave no change); the flame's car half-size is fixed at 0.5, so the area is 2.625 x 3.25 at full size in every direction (the report's 0.5 to 0.707 depended on heading); `missed_bullet_max_travel` is "range" (12, or 18 after the Reach tier), so a missed bullet is removed past the gun's range.
- Copied quirks are in the data as they are: hit radius 1 (drawn size 0.32 is in the file as `bullet_drawn_size`), targets checked once per interval, no knockback field at all, flame steering compounding, tier 5 only changes the flash, reversing counts as drifting (the drift rule is the car's, not in this file).

**Filled in or interpreted (no report value):**
- The report gives no per-level upgrade scaling beyond the tiers, so none was invented: the Unity multipliers are the tier values, as Weapons, Decisions says (the same tiers, copied).
- Tiers are stored as `effect` plus `value`, and `weapon_data.gd` adds them up. The report's card names and descriptions are player-facing text and are not in the data (no text task for this ticket); the UI's text task will cover them.
- Flame damage is stored as its own 2 (equal to the gun's, as decided) rather than linked to the gun, because the gun has no damage tiers in the MVP.
- `missed_bullet_max_travel` uses the range as the removal distance (the board said "past the gun's range"). Pierce is `piercing_hits`-style: tier 8 `pierce` value 1 means one extra enemy; the report's 36-unit pierce travel limit is replaced by the same range rule.
- The drift ramp, linger, tick and tint values come straight from the report; the particle settings (art side) are not stored.

**Python tool tests:** 51 run, 1 failure and 2 errors, all in `test_build_mvp_map.py` (`KeyError: 'boulders'`). They fail the same way on `master` in `C:\solid-carbide-game` with no change from this task, so this is not caused by T-040; the Project Lead should look at it. No files changed outside the list above.

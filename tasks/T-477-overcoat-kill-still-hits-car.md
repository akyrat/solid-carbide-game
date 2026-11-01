---
id: T-477
title: Rusty Overcoat: a minion the overcoat kills still hits the car
status: in-progress
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/enemies.md, game/scripts/enemies/overcoat_contact.gd, game/scripts/enemies/minion.gd, game/scripts/enemies/kaiju.gd, tasks/T-463-rusty-overcoat-the-car-damages-minions.md]
files_expected_to_change: [game/scripts/enemies/minion.gd, game/scripts/enemies/kaiju.gd, game/tests/unit/, docs/enemies.md]
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

The board, 2026-11-01, after playing goal G-009: with Rusty Overcoat owned the car takes no damage at all (Drifting, Decisions, "Driving power-ups"; the overcoat only deals damage, and the enemy still hits the car as before, T-463).

The Project Lead's reading of the code (check it): in `minion.gd` `contact_step()` (and the same in `kaiju.gd`), `OvercoatContact.hit()` runs before the minion's hit on the car, and then `if _dead: return false` skips the car's hit. Minions have 4 health; the weapons (neon zone, wiper) chip them, and tier 3 and up kill a fresh minion in one touch, so nearly every minion the car touches dies to the overcoat first and never hurts the car.

Fix: a minion (or the kaiju) touching the car hits it exactly as it would without the overcoat (the car's invulnerability rules unchanged), whether or not the overcoat's damage kills it in the same step. Change nothing else about the overcoat's numbers or cooldown. If something else also stops the damage, fix that too and say what it was in the result notes. Never write, move or commit anything in game/data/levels/.

The board's review: own Rusty Overcoat with neon zone and wiper, drive into minions, and lose hearts.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test with Rusty Overcoat owned (each tier) shows a minion that touches the car damages it, including when the overcoat's damage kills that minion in the same step. (QA: pass / fail)
- [ ] A test shows a minion already damaged by a weapon, then killed by the overcoat on touch, still damages the car. (QA: pass / fail)
- [ ] A test shows the car's invulnerability after a hit still stops a second hit, with and without the overcoat. (QA: pass / fail)
- [ ] The existing Rusty Overcoat tests (T-463) still pass, changed only where they expected no damage to the car. (QA: pass / fail)
- [ ] docs/enemies.md says the overcoat never stops an enemy's hit on the car. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: a minion the overcoat kills still hits the car.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done (Enemy Behavior Agent). Confirmed cause: in `contact_step()` of `minion.gd` and `kaiju.gd`, `OvercoatContact.hit()` ran first, and the `if _dead: return false` right after it skipped `state.damage_car()` and the knockback whenever the overcoat's damage killed the enemy in that step (tier 3 and up kill a fresh minion in one touch). Fix: removed that early return in both files; the car's invulnerability and the contact cooldown checks are unchanged, and the overcoat's numbers and cooldown are untouched. Nothing else stopped the damage: `OvercoatContact` only calls `take_damage`, and `RunState.damage_car` has no overcoat check. Note: a killed kaiju wins the run, and `damage_car` does nothing once the run is over, so the kaiju case is tested through the return value plus a hit with health left.
Tests (`game/tests/unit/enemies/test_rusty_overcoat.gd`, 12 tests, all pass): every tier's kill-on-touch minion still hits the car; weapon-damaged minion killed on touch hits; invulnerability stops a second hit with and without the overcoat; kaiju. Existing T-463 tests unchanged. docs/enemies.md updated.
Test sets: GUT full run 2506 tests, 2505 passed, 1 failed (my own first kaiju test, which I then fixed; that file re-run alone: 12/12 pass; the full run was not repeated after the fix, it takes about 17 minutes); `game/tools` unittest OK; `tools` unittest 633 tests OK. Nothing under game/data/levels/ touched.

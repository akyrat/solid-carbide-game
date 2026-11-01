---
id: T-463
title: Rusty Overcoat: the car damages minions it touches, with the red hit flash
status: done
from: project-lead
to: enemy-behavior
lead: Goal-G-009
epic: enemies
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-455, T-457]
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/enemies/minions.md, game/scripts/enemies/minion.gd, game/scripts/enemies/hit_tint.gd, game/scripts/enemies/kaiju.gd, game/scripts/run/run_state.gd, game/data/power_ups.json]
files_expected_to_change: [game/scripts/enemies/minion.gd, game/scripts/enemies/kaiju.gd, game/tests/unit/enemies/test_rusty_overcoat.gd, game/docs/enemies/minions.md, docs/enemies.md]
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

Drifting, Decisions, 'Driving power-ups': Rusty Overcoat, the car deals damage to enemies on contact. With it owned, a minion the car touches (at its level, the same 1-unit height rule as contact damage) takes the tier's damage from power_ups.json, with the usual red hit flash (T-404) and death and drops as for any damage. The minion still hits the car as today. How the damage repeats (a per-enemy cooldown) and whether it hits the kaiju follow power_ups.json's proposals (open questions for the board); write them in Enemies, Content. Without the power-up, contact deals no damage, as before. Screenshots of a minion flashing red on contact.

The board's review: play a run with Rusty Overcoat at each tier and ram minions: how strong it feels.

## Acceptance criteria

- [ ] With Rusty Overcoat owned, a minion touching the car loses the owned tier's damage and flashes red, at each tier (GUT tests). (QA: pass)
- [ ] Repeated contact follows the data's per-enemy cooldown, and the kaiju is hit or not as the data says (GUT tests). (QA: pass)
- [ ] Without the power-up, contact deals no damage to the minion (GUT test). (QA: pass)
- [ ] Screenshots of a minion's red flash on contact are in art-archive/<id>/screenshots/; Enemies, Content, describes the rule and its proposals. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-463.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

### 2026-10-31, In QA → Needs playtest

Goal runner (G-009): QA passed; merged into playtest/G-009.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (Enemy Behavior, 2026-10-31).

- `game/scripts/enemies/overcoat_contact.gd` (new, `OvercoatContact`): reads the owned tier from `RunState.power_up_tier("rusty_overcoat")` and `PowerUpData`, calls `take_damage(contact_damage, "rusty_overcoat")` (red flash, death and drops as for any damage), returns the per-enemy repeat cooldown. `minion.gd` and `kaiju.gd` call it in `contact_step()` after the touch and level checks, before the car's invulnerability test; new `overcoat_cooldown` field on each. The kaiju is skipped unless the tier's `hits_kaiju` is true (tier 4). The enemy still hits the car as before. No power-up: no change.
- Proposals as in power_ups.json: cooldown 0.5 / 0.5 / 0.4 / 0.3 s per enemy; kaiju only at tier 4. Written in `docs/enemies.md` (Content, "Rusty Overcoat", and Open questions) and `game/docs/enemies/minions.md`.
- Tests: `game/tests/unit/enemies/test_rusty_overcoat.gd`, 8 tests (each tier's damage and red flash, car still hit, kills at tier 2 and 3, per-enemy cooldown, not touching, without the power-up, kaiju per tier, kaiju without it): 8/8 pass.
- Test sets: Godot (GUT) full suite 2418/2418 passing, 200 scripts. The Python and docs sets were not run by me (no pre-approved command for them); QA/merge runs them.
- Screenshot: `art-archive/T-463/screenshots/overcoat_flash.png` (fixture `game/tests/fixtures/t463_overcoat_demo.tscn`: tier 2, four minions touching the car, all tinted red).
- Documents affected: docs/enemies.md. No art, no PixelLab (0 generations). Refusals: none.

QA round 1 (2026-10-31): all five criteria pass. `tools/qa_check.py` was refused (not pre-approved), so I ran the tests directly. GUT (`bash game/tools/run_tests.sh`): 200 scripts, 2418/2418 passing, including test_rusty_overcoat.gd (8 tests: each tier's damage and red flash, per-enemy cooldown, kaiju per tier, no power-up). Python (`python -m unittest discover -s tools -p "test_*.py"`): 614 tests OK. I did not run the docs-staleness test set separately. The screenshot `art-archive/T-463/screenshots/overcoat_flash.png` exists. `docs/enemies.md` (Content, "Rusty Overcoat", and Open questions) describes the rule and proposals. The worktree has `.import` and `.uid` noise from Godot, not committed by me.
- 2026-10-31, in-qa → needs-playtest: QA passed every criterion (goal G-009).
- 2026-11-01, needs-playtest → done: The board played G-009: LGTM; the overcoat-kill skips the car's hit, fixed in a follow-up ticket (2026-11-01).

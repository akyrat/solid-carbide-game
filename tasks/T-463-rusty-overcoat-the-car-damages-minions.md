---
id: T-463
title: Rusty Overcoat: the car damages minions it touches, with the red hit flash
status: blocked
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

Drifting, Decisions, 'Driving power-ups': Rusty Overcoat, the car deals damage to enemies on contact. With it owned, a minion the car touches (at its level, the same 1-unit height rule as contact damage) takes the tier's damage from power_ups.json, with the usual red hit flash (T-404) and death and drops as for any damage. The minion still hits the car as today. How the damage repeats (a per-enemy cooldown) and whether it hits the kaiju follow power_ups.json's proposals (open questions for the board); write them in Enemies, Content. Without the power-up, contact deals no damage, as before. Screenshots of a minion flashing red on contact.

The board's review: play a run with Rusty Overcoat at each tier and ram minions: how strong it feels.

## Acceptance criteria

- [ ] With Rusty Overcoat owned, a minion touching the car loses the owned tier's damage and flashes red, at each tier (GUT tests). (QA: pass / fail)
- [ ] Repeated contact follows the data's per-enemy cooldown, and the kaiju is hit or not as the data says (GUT tests). (QA: pass / fail)
- [ ] Without the power-up, contact deals no damage to the minion (GUT test). (QA: pass / fail)
- [ ] Screenshots of a minion's red flash on contact are in art-archive/<id>/screenshots/; Enemies, Content, describes the rule and its proposals. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

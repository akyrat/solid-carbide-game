---
id: T-460
title: Rev Charge: hold W and S to charge a boost that fires when S is released, with a placeholder charge and boost effect
status: in-progress
from: project-lead
to: driving-drift
lead: Goal-G-009
epic: driving
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-455, T-457]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/drift.md, game/docs/driving/effects.md, game/scripts/driving/car.gd, game/scripts/driving/car_model.gd, game/scripts/driving/boost_effect.gd, game/scripts/run/run_state.gd, game/data/power_ups.json]
files_expected_to_change: [game/scripts/driving/rev_charge.gd, game/scripts/driving/rev_charge_effect.gd, game/scripts/driving/car.gd, game/tests/unit/test_rev_charge.gd, game/tests/fixtures/rev_charge_demo.gd, game/tests/fixtures/rev_charge_demo.tscn, game/docs/driving/drift.md, docs/drifting.md]
model: opus
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

Drifting, Decisions, 'Driving power-ups': Rev Charge. With the power-up owned (RunState.power_up_tier('rev_charge') > 0), holding W and S at the same time charges a powerful boost, which fires when S is released. Charge time and boost strength come from the owned tier in power_ups.json. Without it, W+S behaves exactly as today (W wins over S). Decide, as proposals, what the car does while charging (held in place or slowing), whether a partial charge fires a partial boost, and how it meets drifting, the air and the wreck; write them in Drifting, Content.

A visible effect plays while charging and while boosting: a placeholder drawn in code (for example a growing glow at the rear and speed lines on release; it may reuse the cruise boost effect), replaced later by the art ticket.

Screenshots or a short GIF of a charge and its release.

The board's review: play a run with Rev Charge granted at each tier: how charging and releasing feels, and the placeholder effect.

## Acceptance criteria

- [ ] With Rev Charge owned, holding W+S charges, and releasing S fires a boost that raises the car's speed; the charge time and boost strength match the owned tier's numbers, and a higher tier gives a stronger or faster charge (GUT tests). (QA: pass / fail)
- [ ] Without the power-up, W+S gives the same speed and state as before over the same steps (GUT test). (QA: pass / fail)
- [ ] A placeholder effect is visible while charging and while boosting, and stops after (GUT test of its visibility; screenshots or a GIF in art-archive/<id>/screenshots/). (QA: pass / fail)
- [ ] Drifting, Content, describes Rev Charge's behaviour and the proposals. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-460.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

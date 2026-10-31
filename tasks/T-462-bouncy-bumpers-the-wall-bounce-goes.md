---
id: T-462
title: Bouncy Bumpers: the wall bounce goes further, tier by tier
status: in-progress
from: project-lead
to: driving-drift
lead: Goal-G-009
epic: driving
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-455, T-457]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/collisions.md, game/scripts/driving/car.gd, game/tests/unit/test_wall_bounce.gd, game/scripts/run/run_state.gd, game/data/power_ups.json]
files_expected_to_change: [game/scripts/driving/car.gd, game/tests/unit/test_bouncy_bumpers.gd, game/docs/driving/collisions.md, docs/drifting.md]
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

Drifting, Decisions, 'Driving power-ups': Bouncy Bumpers. With it owned, the wall bounce from T-435 (walls, buildings, raised sides, map edges, boulders) sends the car further by the owned tier's factor in power_ups.json, the bounce's maximum scaled the same way (proposal; document it). Without it, the bounce is unchanged. A plot of bounce distance per tier as the screenshot.

The board's review: play a run with Bouncy Bumpers at each tier and crash into walls: does the bigger bounce feel good.

## Acceptance criteria

- [ ] GUT tests measure the bounce distance off a wall from the same hit with no power-up and at each tier: no power-up equals today's bounce, and the distance grows tier by tier by the data's factors. (QA: pass / fail)
- [ ] A plot of bounce distance per tier is in art-archive/<id>/screenshots/; Drifting, Content, describes the scaling. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-462.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

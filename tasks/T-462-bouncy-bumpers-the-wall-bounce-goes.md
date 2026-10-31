---
id: T-462
title: Bouncy Bumpers: the wall bounce goes further, tier by tier
status: in-qa
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

- [ ] GUT tests measure the bounce distance off a wall from the same hit with no power-up and at each tier: no power-up equals today's bounce, and the distance grows tier by tier by the data's factors. (QA: pass)
- [ ] A plot of bounce distance per tier is in art-archive/<id>/screenshots/; Drifting, Content, describes the scaling. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-462.

### 2026-10-31, In progress → In QA

Goal runner (G-009): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Driving & Drift Agent, 2026-10-31.

**What changed**
- `game/scripts/driving/car.gd`: `set_bouncy_bumpers_tier(tier)` reads `bounce_distance_multiplier` from `power_ups.json` (tier 0 = 1.0). `_reflect()` scales the bounce speed, cap included, by `sqrt(multiplier)`, and the re-arm reach in `_update_bounce_rearm()` uses the same scaled bounce. Without the power-up the code path is numerically the old one.
- `game/scripts/run/run.gd`: `_apply_rev_charge_tier()` also gives the car the owned `bouncy_bumpers` tier (same place as Jump and Rev Charge).
- `game/tests/unit/test_bouncy_bumpers.gd` (3 tests): no power-up is repeatable and a reset to tier 0 restores 1.0; distance grows tier by tier and the ratio to the plain bounce matches the data factor within 12%; a hit over the cap also scales by the factor, and above the scaled cap every hit bounces the same.
- Docs: `docs/drifting.md` (Content, "Bouncy Bumpers (task T-462)", with the proposals), `game/docs/driving/collisions.md`.

**Proposals (for the playtest)**: the factor multiplies distance, so speed gets sqrt(factor) (distance goes with speed squared); the bounce's maximum scales the same way; everything else (drift ends on a hit, combo cut, W pull-back) is unchanged.

**Measured** (head-on, cruise speed 11, W held, units): none 0.869; tier 1 1.226 (x1.41); tier 2 1.585 (x1.82); tier 3 1.944 (x2.24); tier 4 2.305 (x2.65). Data: 1.4 / 1.8 / 2.2 / 2.6.

**Tests**
- Godot (full suite, run before a debug print was added to the new test): 199 scripts, 2410 tests, 2410 passing, 0 failing. The new file re-run alone after the print: 3/3.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 767 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 614 tests, OK.

**Screenshots**: `art-archive/T-462/screenshots/bounce_distance_per_tier.png`, a bar plot of the measured distance per tier against base x factor, drawn by `game/tools/plot_bouncy_bumpers.py` from the test's printed numbers.

**Documents affected**: `docs/drifting.md` (updated), `game/docs/driving/collisions.md` (updated). No PixelLab generations; no refusals.

**QA round 1 (QA/Integration Agent)**: all three criteria pass. Godot full suite via run_tests.sh: 199 scripts, 2410 passing, 0 failing (test_bouncy_bumpers.gd ran, tiers measured 1.226/1.585/1.944/2.305 vs base 0.869). game/tools unittest: 767 OK (1 skipped). tools unittest: 614 OK. Plot exists at art-archive/T-462/screenshots/bounce_distance_per_tier.png; docs/drifting.md describes the scaling. `python tools/qa_check.py` was refused (needs approval), so skipped.

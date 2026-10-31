---
id: T-461
title: Jump: Space makes a small hop on the car's real height, and its airtime counts for missions
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
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/tricks.md, game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/scripts/driving/trick_detector.gd, game/scripts/run/run_state.gd, game/scripts/run/missions.gd, game/data/power_ups.json]
files_expected_to_change: [game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/tests/unit/test_jump_power_up.gd, game/tests/fixtures/jump_power_up_demo.gd, game/tests/fixtures/jump_power_up_demo.tscn, game/docs/driving/tricks.md, docs/drifting.md]
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

Drifting, Decisions, 'Driving power-ups': Jump. With it owned, Space makes a small hop, using the car's existing height system (takeoff speed, gravity, landing, passing over obstacles at height, the airtime and air-spin tricks) with the tier's numbers from power_ups.json. Without it, Space keeps whatever it does today. Proposals to document in Drifting, Content: whether it works only on the ground (no double jump), any cooldown. Airtime from a hop counts for the airtime, AIR 180 and AIR 360 goals (board, 2026-10-31), through the existing trick events.

Screenshots or a short GIF of a hop.

The board's review: play a run with Jump at each tier: the hop's height and feel, and spinning in it.

## Acceptance criteria

- [ ] With Jump owned, Space on the ground lifts the car through the existing height path and it lands; the hop's peak height or airtime matches each tier's numbers (GUT tests per tier). (QA: pass / fail)
- [ ] Without the power-up, Space changes nothing in the car's height or speed (GUT test). (QA: pass / fail)
- [ ] A simulated hop with an air spin advances the tracker's airtime and AIR 180 goals (GUT test using the mission tracker). (QA: pass / fail)
- [ ] Screenshots or a GIF of a hop are in art-archive/<id>/screenshots/; Drifting, Content, describes the hop and its proposals. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Blocked → In progress

Goal runner (G-009): started, in C:\solid-carbide-worktrees\T-461.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

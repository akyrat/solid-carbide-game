---
id: T-502
title: Driving power-up: the Polarized Steering Wheel
status: open
from: project-lead
to: driving-drift
lead: Greenbull
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-501]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/data/power_ups.json, game/scripts/data/power_up_data.gd, game/scripts/weapons/bricks.gd]
files_expected_to_change: [game/data/power_ups.json, game/scripts/, game/art/power_ups/, game/tests/unit/, docs/drifting.md, game/docs/]
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

The board, 2026-11-02 (docs/drifting.md, Decisions, "Rusty Paintjob and the Polarized Steering Wheel"): a fifth driving power-up, a mission gift like the others. When the player stops accelerating, steers, then accelerates again in a direction different from the one the car is moving in, the car gets a short speed burst. The condition is close to the cruise boost's (the motion lines when W brings the car up to cruise speed; Drifting, Decisions). Tiers 1 to 3 only make the burst bigger. Tier 4 makes it a little bigger again and also sets off an impact shock at the car: Bricks' normal wave (the tier 1 wave: radius 4, damage 6, minions pushed 4, the kaiju damaged and never pushed; reuse Bricks' code and its r4 wave sheet), whether or not the car owns Bricks.

Your proposals for the playtest (write them in power_ups.json with reasons, like the other power-ups): the angle between where the car faces and where it moves when W is pressed again (start at 60 degrees), how long the coast may last before it no longer counts, the burst per tier (about +20 / +30 / +40 / +45% speed for about half a second), and no cooldown between bursts. Show the burst with the cruise boost's motion lines or a stronger version of them. Its icon until T-503's art: a placeholder drawn by a script (a simple wheel), never PixelLab. Its texts come from T-501 (read its result notes for the keys). Add it to the power-up pool and the gift pack, the trick list or tutorial only if the other power-ups appear there. Update Drifting (Content, the power-ups) and game/docs/. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] power_ups.json has polarized_steering_wheel (or a similar id) with 4 tiers, each with its burst numbers and reasons, and tier 4 with the shock. (QA: pass / fail)
- [ ] A unit test: letting go of W, steering, then pressing W again with the car facing at least the threshold angle away from its movement gives a burst; pressing W again with the car facing roughly where it moves gives none; holding W throughout gives none. (QA: pass / fail)
- [ ] A unit test: the burst grows from tier 1 to 4 as in the data. (QA: pass / fail)
- [ ] A unit test: at tier 4 a burst sets off one wave (radius 4, damage 6) that damages minions in reach and pushes them, damages the kaiju without pushing it, with or without Bricks owned; below tier 4 no wave. (QA: pass / fail)
- [ ] The power-up appears in the mission gift offers like the others (unit test) and uses T-501's texts (no placeholder text). (QA: pass / fail)
- [ ] docs/drifting.md (Content) describes it with its numbers. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots of the burst and of the tier 4 shock, and of the power-up overlay showing it, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

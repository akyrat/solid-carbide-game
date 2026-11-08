---
id: T-590
title: A charged jump, for a playtest
status: open
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/data/power_ups.json, game/data/rail_grind.json, game/scripts/driving/, tasks/T-578-rail-launch-keeps-speed.md]
files_expected_to_change: [game/data/, game/scripts/driving/, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "A charged jump, for a playtest": with the Jump power-up owned and the car on the ground, holding Space charges the jump, linearly up to +50% takeoff (the jump's speed/height, as the grind launch's boost is applied) over 3 seconds, and the car jumps on release with the charge it reached. Space in the air is unchanged (tilt and grind). A tap jumps as today (no charge). Without Jump, Space on the ground does what it does today. A small script-drawn cue near the car shows the charge filling (a proposal; no text). Numbers in data with reasons. This is its own playtest: it stays on its own branch and nothing else is merged into it.

The board's review: play it from C:\solid-carbide-worktrees\T-589\game\project.godot: god mode (N in a run) or the result notes' way to get Jump, then tap, half-charge and full-charge jumps, and a grind to compare with the launch.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With Jump owned, holding Space on the ground for 0, 1.5 and 3+ s gives takeoff x1, x1.25 and x1.5, jumping on release (tests). (QA: pass / fail)
- [ ] Space in the air still tilts and grinds as before, and without Jump the ground Space is unchanged (the existing tests pass). (QA: pass / fail)
- [ ] The charge cue shows while charging and is gone after the jump (a test or screenshot). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-589/screenshots/ shows a tap and a full charge side by side or one after the other. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

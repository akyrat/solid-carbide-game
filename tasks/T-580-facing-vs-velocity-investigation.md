---
id: T-580
title: Investigate: the car points one way but moves another at some angles
status: open
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/, game/scripts/driving/car.gd, game/scripts/driving/car_tuning.gd, game/scripts/driving/car_sprite.gd]
files_expected_to_change: [game/tests/, game/tools/, art-archive/T-580/, docs/drifting.md]
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

An investigation, not a fix: change no gameplay code. The board's report, word for word: "today at certain angles the car is pointing towards a direction, but it's not actually moving towards that direction. And I think it has something to do with like how the acceleration when going in a different direction than that of the existing coasting speed is added on top of that. It feels like sometimes I'm going, for example, diagonally, and the car is just sitting at like the wrong angle than it should have. Can you confirm if this actually could exist from the code, and then if you can through screenshots?"

(1) From the code, explain how the car's heading, its velocity and the drawn sprite direction relate: how throttle adds to existing velocity in another direction, how grip pulls velocity toward the heading (outside a drift), and how the heading is turned into one of the sprite's 32 directions (and the isometric projection). Name every place where the drawn direction and the actual direction of travel can differ, and by how much: for example a slow grip that leaves sideways velocity after a turn, acceleration added to a coasting velocity, the snapping to 32 sprite directions, the isometric screen angle versus the world angle, a drift's intended slip. Say which of these match the board's description (diagonals especially) and which are intended (drifting).
(2) Measure it: a test or a scripted drive that logs heading, velocity direction and the sprite's drawn direction over time for a few cases (coasting along one diagonal then throttling toward another; turning onto a diagonal; straight along each of the 8 main directions), with the angle between where the car points and where it goes, on screen and in the world.
(3) Show it: screenshots or a GIF with an overlay drawn only in the fixture (an arrow for the facing and one for the actual movement) in art-archive/T-580/screenshots/, for the cases where they differ most.
(4) Conclude in the result notes: does the issue exist, which cause(s), how big, and the options to fix each (no fix built here). Add a short Content note in docs/drifting.md with the findings.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes explain from the code every way the drawn direction and the travel direction can differ, with sizes, and say which match the board's description. (QA: pass / fail)
- [ ] A test or scripted drive measures the angle between facing and travel for the listed cases, and its numbers are in the result notes (it passes). (QA: pass / fail)
- [ ] Screenshots or a GIF with facing and travel arrows are in art-archive/T-580/screenshots/. (QA: pass / fail)
- [ ] No gameplay code is changed (diff). (QA: pass / fail)
- [ ] docs/drifting.md Content has the findings. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

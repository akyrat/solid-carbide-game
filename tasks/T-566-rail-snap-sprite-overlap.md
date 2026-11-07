---
id: T-566
title: Snap to a rail when the car's sprite crosses the rail's sprite, whatever the height
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
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/rail-grind.md, tasks/T-551-grind-overhaul-driving.md]
files_expected_to_change: [game/scripts/driving/, game/data/rail_grind.json, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "A grind starts when the car's drawing crosses the rail's": while Space is held in the air, the car snaps onto a rail as soon as the car's sprite as drawn on screen (its drawn rectangle or pixels, lifted by its height, as the player sees it) crosses the rail's drawn sprite, whatever the car's height above or below the rail; it then grinds at the rail's height as today. This replaces the catch reach (2.5) and any height window. Propose how the overlap is measured (bounding boxes or a tighter shape) so it matches what the player sees without catching rails the car only seems near, and what happens if two rails overlap the car (the nearest on screen). The rest of the grind overhaul stays (Space held to grind, release to launch, landing boost). Update the GRIND! practice slide's checks if they assumed the old reach.

The board's review: play it from C:\solid-carbide-worktrees\T-566\game\project.godot on the Kaiju City map (and the tutorial's grind slide once it is in the combined build), hold Space in the air and cross a rail's drawing at different heights.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Holding Space in the air, the car snaps onto a rail when its drawn sprite crosses the rail's drawn sprite, also when the car is well above or below the rail's height (tests at several heights). (QA: pass / fail)
- [ ] Without Space held, or with the sprites not crossing, it does not snap (tests). (QA: pass / fail)
- [ ] The rest of the grind (release to launch, landing boost) works as before (the existing tests pass). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe the rule and the overlap measure, with reasons. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-566/screenshots/ shows a snap from well above a rail and one from below. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

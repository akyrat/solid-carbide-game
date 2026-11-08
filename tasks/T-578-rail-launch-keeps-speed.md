---
id: T-578
title: The launch off a rail keeps the grind's speed
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
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/rail-grind.md, game/data/rail_grind.json, tasks/T-551-grind-overhaul-driving.md, tasks/T-566-rail-snap-sprite-overlap.md]
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

Build Drifting, Decisions, "The launch off a rail keeps the grind's speed": letting go of Space while grinding launches the car where it faces (as now, backwards too) at the speed it was grinding at that moment, instead of the set jump_speed 6. The upward takeoff (launch_takeoff_speed, the Jump tier 2 takeoff) is unchanged. Propose what a very slow grind does (a floor speed, or none) with its reason. Check what depends on the old 6: the square-on start speed (square_start_speed is 6 "so a launch that crosses the next rail square-on rides it at the speed it left the last one"), the jump pair's 3.5 units in the practice playground and the tutorial's grind slide drive tests, the facing arrow; keep them working or update them and say what you changed. jump_speed stays only if something still uses it.

The board's review: play it from C:\solid-carbide-worktrees\T-578\game\project.godot on Kaiju City: grind slow and fast and let go of Space; also the tutorial's grind slide.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Letting go of Space launches the car where it faces at its grinding speed at that moment, tested at a slow, a middle and a fast grind speed (tests). (QA: pass / fail)
- [ ] The takeoff height and the rest of the grind (snap, landing boost, rail ends) work as before (the existing tests pass, updated where they assumed 6). (QA: pass / fail)
- [ ] The tutorial's grind slide and the practice playground's rail drives still pass (tests). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/rail-grind.md describe it with reasons. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-578/screenshots/ shows a slow and a fast launch. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

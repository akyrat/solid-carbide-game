---
id: T-600
title: Slide marks, and tire marks that fade in half the time
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
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, game/scripts/driving/drift_marks.gd]
files_expected_to_change: [game/scripts/driving/, game/data/, game/tests/, game/docs/driving/]
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

Build Visual style, Decisions, "Slide marks, and tire marks that fade faster". With drift_marks.gd as the starting point: when the car has sideways speed but is not accelerating (W not held, not drifting; for example sliding out of a drift or a turn), it leaves tire marks slightly lighter than the drift marks, from both the front and the back wheels. Drift marks stay as they are. Every tire mark (drift and slide) stays on the map for half the time drift marks stay today, fading the same way. Proposals with reasons in data: how much lighter, the sideways speed that starts and stops a slide mark (so a straight coast leaves none), and whether a slide mark joins a drift mark seamlessly. Works in a run and in the tutorial's practice window. Keep the cost of the marks (count and drawing) no higher than today's drift marks per second of marking; say how you checked.

The board's review: play it from C:\solid-carbide-worktrees\T-600\game\project.godot: drift, then let go of W and slide; turn and coast; watch the marks fade.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Sliding sideways without W (not drifting) leaves lighter marks from the front and back wheels; a straight coast leaves none (tests). (QA: pass / fail)
- [ ] Drift marks are unchanged in look (the existing tests pass). (QA: pass / fail)
- [ ] Every tire mark lasts half as long as drift marks did before (a test with the numbers). (QA: pass / fail)
- [ ] The marks' per-second cost is no higher than before, with how it was checked in the result notes. (QA: pass / fail)
- [ ] docs/visual-style.md Content and game/docs/driving/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots or a GIF in art-archive/T-600/screenshots/ show a drift into a slide with both kinds of marks, taken with bash game/tools/screenshot.sh. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

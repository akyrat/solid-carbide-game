---
id: T-595
title: Fix: the jump effect draws over the car
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
files_to_read_first: [tasks/README.md, docs/visual-style.md, game/scripts/driving/jump_effect.gd, art-archive/T-590/screenshots/tweak1_tap_vs_charge_closeup.png]
files_expected_to_change: [game/scripts/driving/, game/tests/, game/docs/driving/]
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

Build Visual style, Decisions, "The jump effect sits behind the car". The board saw in T-590's screenshot (art-archive/T-590/screenshots/tweak1_tap_vs_charge_closeup.png) that the jump cloud covers the car. Make every jump effect (the dash cloud and the other Cosmetics choices: spring, jet, stunt sparks, shockwave ring) draw behind the car at every car facing and height, in a run and in the tutorial's practice window, including the bigger charged-jump effect. Keep the effect's position and look otherwise unchanged.

The board's review: play it from C:\solid-carbide-worktrees\T-595\game\project.godot: jump with a tap and a full charge, with two or three different jump effects.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every jump effect draws behind the car (a test on draw order or z, for each effect). (QA: pass / fail)
- [ ] Its position and look are otherwise unchanged (the existing jump effect tests pass). (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-595/screenshots/ show a tap and a full charge with the cloud behind the car, before and after. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

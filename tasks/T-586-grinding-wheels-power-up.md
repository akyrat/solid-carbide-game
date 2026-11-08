---
id: T-586
title: Grinding Wheels: a power-up that heats the grind sparks and boosts the launch
status: open
from: project-lead
to: driving-drift
lead: Rails
epic: power-ups
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-585]
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, game/data/power_ups.json, game/data/rail_grind.json, game/scripts/driving/rail_grind.gd, game/scripts/driving/rail_sparks.gd, tasks/T-578-rail-launch-keeps-speed.md]
files_expected_to_change: [game/data/power_ups.json, game/data/, game/scripts/driving/, game/scripts/run/, game/art/power_ups/, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "Grinding Wheels, a driving power-up", on top of T-578 (the launch keeps the grind's speed, floor 6; on master). Add `grinding_wheels` to game/data/power_ups.json like the others (one tier; texts from T-585; icon path game/art/power_ups/grinding_wheels.png with a script-drawn placeholder until T-587's art), so it is offered in mission gifts and counts against the driving power-up cap like the others. While grinding with it owned: a stack builds each full second of the grind, up to 3; the grind sparks (rail_sparks.gd) are yellow, then orange after 1 s, then red after 2 s, fading between; letting go of Space launches at the grind speed times (1 + 0.33 per stack), so 2x at 3 stacks (numbers in data with reasons; proposals). Stacks reset at each new grind; without the power-up the sparks and the launch are as today. Check the launch floor (6) applies before the boost, and say how the boost and the floor combine.

The board's review: play it from C:\solid-carbide-worktrees\T-586\game\project.godot: god mode (N in a run) or the result notes' way to get the power-up, then grind 1, 2 and 3+ seconds and launch.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Grinding Wheels is in power_ups.json and can be offered and taken like the other driving power-ups (tests). (QA: pass / fail)
- [ ] With it, stacks build one per second up to 3, the sparks go yellow, orange, red, and the launch speed is the grind speed times 1, 1.33, 1.67, 2 by stacks (tests); stacks reset on a new grind. (QA: pass / fail)
- [ ] Without it, sparks and launch are unchanged (the existing tests pass). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-586/screenshots/ shows the sparks changing colour over a 3-second grind and the launch. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

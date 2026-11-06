---
id: T-548
title: Grind: a speed boost on every rail landing; Jump off a rail goes where the car faces
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
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/]
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

Build Drifting, Decisions, "A speed boost on landing on a rail" and "Jumping off a rail goes where the car faces" (the board, 2026-11-06), in the rail grind (T-541, T-542; game/data/rail_grind.json). (1) Every time the car lands on a rail and starts grinding, it gets a set speed boost along the rail (propose: a speed it is raised to, or an amount added, and say which), which then declines over the grind (propose the rate or curve). Every landing boosts again; a joint between connected pieces is not a new landing. (2) Jump while grinding sends the car off in the direction it faces, whatever its direction of travel, even backwards, at a set launch speed (propose it, "a bit"); momentum along the rail is not kept. This replaces the 15-degree diagonal hop. The rail-jump's no-cooldown rule (T-541's second tweak) stays. All numbers in game/data/rail_grind.json with their reasons, because the board will tune them by playing.

The board's review: play it from C:\solid-carbide-worktrees\T-548\game\project.godot on the board's new map once T-547 is merged into master (or on any level with rails) and say what to change.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels; reading is fine where the ticket says so). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Landing on a rail raises the car's speed along it by the data's boost, and the speed then declines by the data's rate; a second landing boosts again; passing a joint does not (tests). (QA: pass / fail)
- [ ] Jump while grinding launches the car along its facing at the data's speed, also when the car faces against its travel (test with the car turned 180 degrees). (QA: pass / fail)
- [ ] The rail jump still ignores the Jump cooldown (the existing test still passes). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe both, with each proposed number and its reason. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] GIFs in art-archive/T-548/screenshots/ show a landing boost and a jump off a rail in the facing direction, one of them backwards. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

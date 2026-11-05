---
id: T-538
title: No frame drops with many minions alive
status: open
from: project-lead
to: enemy-behavior
lead: Rails
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/docs/game-loop/perf-recorder.md, game/docs/enemies/]
files_expected_to_change: [game/scripts/enemies/, game/data/enemies.json, game/tests/, game/tools/, game/docs/enemies/, docs/enemies.md]
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

Build Enemies, Decisions, "No slowdown from many minions". Write a repeatable stress measurement first (a script or test scene that spawns a run's worth of minions that are never killed, for example 100, 200 and 400, and reports the physics and process frame time; use the perf recorder's tools where they fit). Find what costs the most per minion (navigation, depth sorting, height lookups, collisions, the green spill and corpses from T-531) and make it cheaper without changing how minions behave. Only if that isn't enough, propose a cap on minions alive (in game/data/enemies.json, with what happens at the cap) and say so in the result notes. Record the before and after numbers.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging, letting minions pile up.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The stress measurement exists, is documented in game/docs/enemies/, and the result notes give before and after frame times at each minion count. (QA: pass / fail)
- [ ] With 200 minions alive the measured average frame time is under 16.6 ms, or the result notes explain why not and what the proposed cap gives. (QA: pass / fail)
- [ ] Existing minion behaviour tests still pass unchanged (QA's full run). (QA: pass / fail)
- [ ] docs/enemies.md Content describes the change and any cap. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A plot or screenshot in art-archive/T-538/screenshots/ shows frame time against minion count before and after. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

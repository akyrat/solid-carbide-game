---
id: T-530
title: Handbrake on Space: drift steering while held, calmer steering and a higher top speed when not; Jump on Left Shift
status: open
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-529]
documents_affected: [docs/drifting.md]
files_to_read_first: [docs/drifting.md, game/docs/driving/drift.md, game/project.godot, tasks/README.md]
files_expected_to_change: [game/project.godot, game/scripts/driving/, game/data/, game/tests/, game/docs/driving/drift.md, docs/drifting.md]
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

Build docs/drifting.md, Decisions, "A handbrake on Space, for a playtest". Input (game/project.godot input map): a new action `car_handbrake` on Space; `car_jump` moves from Space to Left Shift. Check nothing else in a run used Space (menus keep Space for pressing buttons, that is fine; a run must not do both). Handling: while `car_handbrake` is held the car drives exactly as today (steering, drift, everything). While it is not held the car has lower steering sensitivity and a higher top speed. Put the numbers in the car's tuning data next to today's (your proposals for the playtest, each with a reason): the steering multiplier without the handbrake, the top speed multiplier without it, and how the car passes between the two (at once or eased over a short time). Decide and note what pressing the handbrake at high speed does (it may simply switch to today's handling, letting the higher speed bleed off as today's drag does). The tutorial clips' key pad (game/scripts/menu/key_pad.gd) and any other place that shows the Jump key: list them in the result notes; change a drawn key only where it shows Space for Jump. Keep the Drift Guide, the cruise boost, Rev Charge, the Polarized Steering Wheel and the other power-ups working: say in the result notes how each behaves with and without the handbrake. Make it easy to switch off (one tuning value or constant that restores today's handling with no handbrake), so the board can compare. Document in game/docs/driving/drift.md and docs/drifting.md Content. Screenshots: the car turning with and without the handbrake (or a trace of both turning circles).

The board, 2026-11-03: docs/drifting.md, Decisions, "A handbrake on Space, for a playtest". The board tries it in one build (T-530's folder) before deciding; nothing merges or reaches itch.io before that. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). Godot: the worktree has no .env; give GODOT_BIN from C:\solid-carbide-game\.env (CR and quotes stripped) to one command at a time, no `export VAR=$(...)`, never copy .env; don't leave Godot processes running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-529, T-530) from C:\solid-carbide-worktrees\T-530\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Space is car_handbrake and Left Shift is car_jump in the input map; Jump fires on Left Shift and not on Space (test). (QA: pass / fail)
- [ ] With the handbrake held the car's steering and top speed equal today's (test against today's numbers). (QA: pass / fail)
- [ ] Without it the steering is less sensitive and the top speed higher, by the tuning data's values (test). (QA: pass / fail)
- [ ] One value switches back to today's handling with no handbrake (test). (QA: pass / fail)
- [ ] The result notes list how each speed power-up and the Drift Guide behave with and without the handbrake, and every place that shows the Jump key. (QA: pass / fail)
- [ ] game/docs/driving/drift.md and docs/drifting.md Content describe it. (QA: pass / fail)
- [ ] The Godot test set passes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-530/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

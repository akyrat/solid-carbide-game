---
id: T-606
title: The notebook pulses on mission progress
status: open
from: project-lead
to: ui
lead: Rails
epic: hud
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/hud/mission_page.gd, tasks/T-563-notebook-trick-splash.md]
files_expected_to_change: [game/scripts/hud/, game/data/, game/tests/, game/docs/]
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

Build HUD and menus, Decisions, "The notebook pulses on mission progress". Whenever any goal of a mission in the notebook makes progress (a count going up, a running total such as airtime or drift seconds growing, a goal ticked), the notebook page pulses discreetly: it scales up a little and back, around its own centre, without moving the HUD layout (the layout editor's piece keeps its place and size). Propose the size (a few percent), the duration and how it behaves when progress keeps coming (a running total grows every frame: pulse once when it starts growing and then at most every so often, or similar; say what you chose and why) in data with reasons. It works alongside T-563's falling trick box (the pulse can come when the box lands, or straight away for goals without a box; say which). In a run and in the tutorial's practice window. No text.

The board's review: play it from C:\solid-carbide-worktrees\T-606\game\project.godot: do tricks that count for the mission, hold a drift on the drift goal, watch the notebook pulse.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The notebook pulses on each progress of a count goal and on a goal being ticked (tests). (QA: pass / fail)
- [ ] A running total goal pulses within the proposed limit, not every frame (a test). (QA: pass / fail)
- [ ] The HUD layout does not move: the notebook piece keeps its position and size outside the pulse (a test). (QA: pass / fail)
- [ ] Works in a run and in the tutorial's practice window (tests). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content describes it, with the numbers. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-606/screenshots/ shows a pulse, taken with bash game/tools/screenshot.sh frames. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

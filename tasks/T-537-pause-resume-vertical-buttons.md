---
id: T-537
title: Pause screen: a Resume button, buttons stacked vertically and reordered
status: blocked
from: project-lead
to: ui
lead: Rails
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-533]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/scenes/, game/data/pause_text.json, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "Resume on the pause screen, buttons stacked". Add a Resume button (the shared button style; label exactly T-533's text, in game/data/pause_text.json) that does what Escape does. Stack the pause screen's buttons vertically, one under the other, in a sensible order with Resume first; propose the order (for example Resume, Trick list, Edit HUD layout, Restart, Exit) and give the reason in the result notes. The screen must still scale with the window and fit at 1280x720 and at the smallest supported size; keyboard navigation must reach every button in the new order. Keep the God mode entry working.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Pressing Resume closes the pause screen and the run carries on, as Escape does (test). (QA: pass / fail)
- [ ] The buttons are in one vertical column, in the order given in the result notes, with Resume first, and keyboard navigation follows that order (test). (QA: pass / fail)
- [ ] The whole pause screen stays inside the window at 1280x720 (test or screenshot). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content describes the new layout. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-537/screenshots/ show the new pause screen at 1280x720 and at a large window. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

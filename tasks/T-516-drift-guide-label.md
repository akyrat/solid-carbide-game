---
id: T-516
title: Drift Guide checkbox label
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, tasks/T-506-rain-toggle-text.md, tasks/README.md]
files_expected_to_change: [game/data/pause_text.json, game/tools/text_inventory.py, game/tests/, docs/hud-and-menus.md]
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

Write the pause screen's checkbox label for the Drift Guide, in pause_text.json next to rain_label (key drift_guide_label). The board named it "Drift Guide": use exactly that text unless the style loop finds a real problem (then say so, keep the board's words as the value). List it in docs/hud-and-menus.md Content with where it appears.

The board, 2026-11-02: docs/drifting.md, Decisions, "The Drift Guide", and docs/hud-and-menus.md, Decisions, "A Drift Guide checkbox". The board plays T-516..T-518 together in one playtest build before anything merges or reaches itch.io. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build (T-516, T-517, T-518) from the Project Lead's combined folder (C:\solid-carbide-worktrees\T-518\game\project.godot), before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] pause_text.json has drift_guide_label with the value "Drift Guide" (test). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists it with where it appears. (QA: pass / fail)
- [ ] The text inventory and the tests that read pause_text.json pass (the agent runs the ones it touched). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

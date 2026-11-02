---
id: T-518
title: Drift Guide checkbox in the pause settings
status: open
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-516, T-517]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, tasks/T-508-rain-settings-toggle.md, tasks/README.md]
files_expected_to_change: [game/scripts/, game/tests/unit/, docs/hud-and-menus.md]
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

Add the Drift Guide checkbox to the pause screen's settings (docs/hud-and-menus.md, Decisions, "A Drift Guide checkbox"), next to the Rain checkbox (T-508), with T-516's label (drift_guide_label), showing the saved drift_guide_enabled (off by default, T-517), switching the guide at once through T-517's function and saving the choice. Mouse and keyboard work like the other checkboxes; the strip still fits (say if the row needs to wrap). This ticket's branch is built on T-517's and T-516's branches so the board plays one build. Update docs/hud-and-menus.md Content (the pause screen).

The board, 2026-11-02: docs/drifting.md, Decisions, "The Drift Guide", and docs/hud-and-menus.md, Decisions, "A Drift Guide checkbox". The board plays T-516..T-518 together in one playtest build before anything merges or reaches itch.io. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build (T-516, T-517, T-518) from the Project Lead's combined folder (C:\solid-carbide-worktrees\T-518\game\project.godot), before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: the checkbox starts unticked for a new player and shows a saved true as ticked. (QA: pass / fail)
- [ ] A unit test: ticking it turns the guide on at once and saves it; unticking turns it off. (QA: pass / fail)
- [ ] Its label comes from drift_guide_label, not hard-coded (test). (QA: pass / fail)
- [ ] Keyboard navigation reaches it like the other checkboxes (test). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content describes the checkbox. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] A screenshot of the pause screen with the checkbox, and of a drift with the guide on, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

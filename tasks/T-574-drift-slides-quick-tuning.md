---
id: T-574
title: Quick tuning: the drift tutorial slides, with the board
status: open
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/menu/tutorial_slides.gd, tasks/T-561-practice-session.md, tasks/T-562-interactive-tutorial-slides.md, tasks/T-565-drift-seconds-running-totals.md]
files_expected_to_change: [game/scripts/menu/, game/scripts/run/, game/scripts/hud/, game/scenes/, game/data/, game/tests/, game/docs/, docs/hud-and-menus.md]
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

Quick tuning with the board (docs/working-with-the-board.md, "How the board builds the game", quick tuning): the board works at a game designer's level on the tutorial's drift slides (the drift and the alt drift practice), changing both the slides' layout and how the practice plays. The Project Lead passes on the board's tweaks word for word; each tweak goes in straight away in this folder so the board plays it at once, and each is written in the result notes. The board decided there is no QA round for this ticket (board, 2026-11-08): when the board says it is done, it goes to the board's review and then merges. Keep the existing tests passing and add or update tests for what you change; the merge runs the full test sets. New player-facing text follows the board's own wording when it gives one; otherwise propose it and say so. Record each settled tweak as a decision in docs/hud-and-menus.md (or the doc it belongs to) when the board says it is done.

The board's review: play it from C:\solid-carbide-worktrees\T-574\game\project.godot after each tweak.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."`, one entry per tweak, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each of the board's tweaks is in and written in the result notes. (QA: pass / fail)
- [ ] The test sets pass at the merge. (QA: pass / fail)
- [ ] The docs describe the settled result. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

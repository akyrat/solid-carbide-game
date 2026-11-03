---
id: T-529
title: Jump key texts: Space becomes Left Shift
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/drifting.md, docs/hud-and-menus.md, game/data/screen_texts.json, tasks/README.md]
files_expected_to_change: [game/data/screen_texts.json, game/tests/, game/tools/, docs/hud-and-menus.md]
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

The Jump power-up moves from Space to Left Shift (Space becomes the handbrake). Change only the key name in the texts that name Space for Jump, keeping the board's words otherwise: game/data/screen_texts.json power_ups.descriptions.jump "Press Space to Jump." -> "Press Shift to Jump." and power_ups.descriptions_last_tier.jump "Press Space to Jump higher." -> "Press Shift to Jump higher.". Search every other player-facing text (text inventory, tutorial texts, pause and trick list texts) for a key name that names Space for Jump, and list any you find in the result notes with the same change. Don't add new texts (no handbrake label): if you think one is needed for the playtest, note it in the result notes and the Project Lead asks the board. Update docs/hud-and-menus.md Content.

The board, 2026-11-03: docs/drifting.md, Decisions, "A handbrake on Space, for a playtest". The board tries it in one build (T-530's folder) before deciding; nothing merges or reaches itch.io before that. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). Godot: the worktree has no .env; give GODOT_BIN from C:\solid-carbide-game\.env (CR and quotes stripped) to one command at a time, no `export VAR=$(...)`, never copy .env; don't leave Godot processes running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play the one combined build (T-529, T-530) from C:\solid-carbide-worktrees\T-530\game\project.godot before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Both Jump card texts read exactly as above (test). (QA: pass / fail)
- [ ] No player-facing text names Space for Jump any more (the result notes list what was searched and found). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content matches. (QA: pass / fail)
- [ ] The text inventory and the touched text tests pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-532
title: Minion death animation through PixelLab: a sample direction first
status: in-progress
from: project-lead
to: asset-generation
lead: Rails
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [docs/visual-style.md, docs/working-with-the-board.md, tasks/README.md, game/art/minion/]
files_expected_to_change: [art-archive/T-532/, docs/visual-style.md]
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

Make the minion's death animation through PixelLab (docs/visual-style.md, Decisions, "The minion's death animation and green spill"). The board's go covers the SAMPLE only: one direction (your choice, say which), through the style loop, at most 4 generations in all (1 plus up to 3 refines). Start from the minion as it is now (the approved mini-kaiju lizard, its walk and fall sheets in game/art/minion/, with the bolder outlines of T-340) so it matches: same size, palette and outline; how many frames is your proposal (about 6 to 8). No blood in the frames (the green liquid is drawn in code by T-531). Write your planned calls and their cost in the result notes before calling; use a 600 s HTTP timeout. Put everything generated in art-archive/T-532/ and only the board-approved sheet later in game/art/minion/ (never delete generated art). Show the sample as an enlarged strip on dark and light backgrounds in art-archive/T-532/screenshots/. Stop after the sample: the full set (the other 4 drawn directions, mirrored to 8) and the swap into the game come after the board approves it, using the frame layout T-531 documents.

The board, 2026-11-03: docs/enemies.md, Decisions, "Minion deaths: an animation, a green spill, corpses that can be knocked about", and docs/visual-style.md, Decisions, "The minion's death animation and green spill". The board plays the functional build (T-531, code placeholder animation) and reviews the art sample (T-532) before anything merges or reaches itch.io. No new player-facing text. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). Godot: the worktree has no .env; give GODOT_BIN from C:\solid-carbide-game\.env (CR and quotes stripped) to one command at a time, with no `export VAR=$(...)` and no `timeout` wrapper, never copy .env; don't leave Godot processes running (if one hangs, tell the Project Lead, don't kill it). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: the sample strip in art-archive/T-532/screenshots/ (added by the Project Lead, 2026-11-03: every art task waits for the board).

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] One sample death animation direction generated through the style loop, at most 4 generations, the calls and cost written in the result notes. (QA: pass / fail)
- [ ] The Style review section shows the loop's scores; the sample matches the minion's size, palette and outline. (QA: pass / fail)
- [ ] Every generated file is kept in art-archive/T-532/. (QA: pass / fail)
- [ ] An enlarged strip on dark and light backgrounds is in art-archive/T-532/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Asset agent: PixelLab sample of the death animation, one direction, up to 4 generations (board's go).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Plan (before any PixelLab call): sample direction SE. Style loop run: python tools/style_loop/run.py art --task T-532 --brief art-archive/T-532/brief.md --out art-archive/T-532/minion_death_se.png --size 48x48 --frames 8 --max-colors 32 --allow-red 147,93,93. Planned PixelLab calls: /animate-with-text-v3 (first_frame = minion_se frame 0, 8 frames, 48x48, no_background, 600 s HTTP timeout), 1 generation each (as in T-068: usage 1.0 generation). At most 4 calls in all (version 1 plus up to 3 refines), free script fixes first. Everything kept in art-archive/T-532/.

Run 1 of the style loop (2026-11-03) stopped before any PixelLab call: the loop's headless generator agent wrote its request builder art-archive/T-532/build_req.py but the permission system refused 'python art-archive/T-532/build_req.py' (only python game/tools/*, tools/style_loop/run.py and a few more are pre-approved in .claude/settings.json). 0 of 4 generations spent, no cost. Not worked around. Needs the board/Project Lead: either approve the script run, or allow moving the builder into game/tools/ (an approved path), then rerun the same loop command.

2026-11-06 (board's decision): request builder moved to game/tools/pixellab_animate_req.py (generic: --first-frame, --out, --seed, --frames, --action/--action-file); old copy kept as art-archive/T-532/build_req_old_refused.py; brief.md names the new path. Planned: rerun 'python tools/style_loop/run.py art --task T-532 --brief art-archive/T-532/brief.md --out art-archive/T-532/minion_death_se.png --size 48x48 --frames 8 --max-colors 32 --allow-red 147,93,93'; /animate-with-text-v3, 1 generation per call (about 1.0 generation each), at most 4 calls, 600 s HTTP timeout.

2026-11-06, run 2, version 1: request built with the approved script (art-archive/T-532/req_v1.json, seed 1). The send stopped before any PixelLab call: pixellab_client.py passed the style loop gate but exited with "PIXELLAB_API_KEY is not set" because this worktree (C:\solid-carbide-worktrees\T-532) has no .env. Checking for the main checkout's .env needed approval, so I didn't work around it and didn't copy any secret. 0 of 4 generations spent, no cost. No v1.png was made. Needs the board/Project Lead: give this worktree the key (a .env at its root, or PIXELLAB_API_KEY in the loop's environment), then run the same loop command again.

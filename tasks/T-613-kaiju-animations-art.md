---
id: T-613
title: Art for the kaiju's walk, windup and death animations
status: open
from: project-lead
to: asset-generation
lead: Polish
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-612]
documents_affected: [docs/visual-style.md, docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/enemies.md, game/docs/enemies/kaiju.md, tasks/T-612-kaiju-animations.md, tasks/T-544-minion-death-art-full-set.md]
files_expected_to_change: [game/art/kaiju/, game/art/pixellab-generation-log.jsonl, art-archive/T-613/, game/data/enemies.json, game/tests/, game/docs/, docs/visual-style.md, docs/enemies.md]
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

Make the final art for Visual style, Decisions, "The kaiju's animations" (board, 2026-11-09) and swap it in for T-612's placeholder frames.

Three animations (walk cycle, meteor windup, death), each in the kaiju's five drawn directions (e, n, ne, s, se; the others are mirrored by the game): 15 animations. Generate them through PixelLab from the kaiju's current sprites (`game/art/kaiju/`) so it stays the same monster, in the frame format T-612 wrote in `game/docs/enemies/kaiju.md` (files, frame size, anchor); frame counts and speeds are numbers in `game/data/enemies.json` that you may change to fit the art.

PixelLab: the board gave its go for the full set, with no sample review (2026-11-09). Every animation goes through the style loop (tasks/README.md, "The style loop"): at most 3 refines each, so at most 4 generations per animation and at most 60 for the ticket. Nothing beyond that without the board's say-so. Write your planned calls and their cost in the result notes before the first call. Free script fixes (cropping, aligning, palette, mirroring) come before paid generations. Use a 600 s HTTP timeout: timed-out calls are still charged. An animation that stays below 8 after its refines keeps its best version and is listed in the result notes for the board.

Never delete art: the game-ready frames go in `game/art/kaiju/`, every raw generation in `art-archive/T-613/`, and T-612's placeholder frames move to `art-archive/T-613/` when yours replace them. The five still sprites stay. Add a section to Visual style, Content, on the set, and point Enemies, Content, "The kaiju", Look, at it.

The board's review: play it from C:\solid-carbide-worktrees\T-613\game\project.godot: reach the kaiju, watch it walk, wind up before its meteors and die, with the final art; the contact sheets and recordings are in art-archive/T-613/screenshots/.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes list the planned PixelLab calls and their cost, written before the first call, and the calls made: at most 4 generations per animation and at most 60 in all, each with a line in `game/art/pixellab-generation-log.jsonl`. (QA: pass / fail)
- [ ] Each of the 15 animations (walk, windup, death in e, n, ne, s, se) has an entry in the ticket's Style review with its score; any below 8 after its refines is listed in the result notes. (QA: pass / fail)
- [ ] The frames in `game/art/kaiju/` match the frame format in `game/docs/enemies/kaiju.md` (a test or a script check of file names, frame size and counts against `game/data/enemies.json`), and the game's kaiju tests pass with them. (QA: pass / fail)
- [ ] In the game the kaiju shows the final art for all three animations and no placeholder frame: recordings (one GIF each of the walk, the windup and the death, in the game) in art-archive/T-613/screenshots/. (QA: pass / fail)
- [ ] Contact sheets in art-archive/T-613/screenshots/: for each animation, its frames in the five directions beside the current still sprite, enlarged nearest-neighbour, on a dark and a light background. (QA: pass / fail)
- [ ] No art was deleted: every raw generation and T-612's placeholder frames are in art-archive/T-613/, and the five still sprites are still in `game/art/kaiju/`. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Every document in documents_affected is updated, and the proposals made for the playtest are listed in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

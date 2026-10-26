---
id: T-300
title: Greenbull's approved emblem and wordmark copied into game/art/logo, with their records
status: blocked
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-298, T-299]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/working-with-the-board.md, tasks/T-294-art-greenbull-emblem.md, tasks/T-295-art-greenbull-wordmark.md, art-archive/T-294/, art-archive/T-295/, game/art/logo/]
files_expected_to_change: [game/art/logo/greenbull_emblem_128.png, game/art/logo/greenbull_emblem_64.png, game/art/logo/greenbull_emblem_32.png, game/art/logo/greenbull_wordmark.png, game/art/logo/, docs/visual-style.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Greenbull's emblem (T-294, run 2) and wordmark (T-295, run 1) are approved by the board and merged. The game needs them in game/art/logo/ so the level-up screen, the gift pack and the helicopter tickets of this goal can stamp them on their art. Copy, don't remake: copy art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and art-archive/T-295/greenbull_wordmark.png into game/art/logo/ byte for byte, each with a json record beside it naming its source file, ticket and run, in the same form as the other records in game/art. No PixelLab call.

This is the art that plugs into D1's Greenbull logo check and D2's Greenbull flag in the style loop. Because every art ticket goes through the style loop (tasks/README.md, 'The style loop'; T-292), run tools/style_loop/run.py art once per file with --greenbull and a brief that tells the generator to copy the approved file unchanged (no generation, no edit); the kept version must be the byte-identical copy, and the round goes in this ticket's Style review. If the loop's evaluator scores a copy below 8, don't refine it into something else: keep the approved file and note it for the board.

The old Redgull logo files (redgull_logo_128.png, _64.png, _32.png and their records) are not deleted: either leave them in game/art/logo/ or move them with git mv into art-archive/<this ticket>/ with their records, and say which in the result notes. Nothing in the game loads them directly (only build scripts do, and those are rebuilt by later tickets), so whichever you choose, the game's tests must still pass. Update Visual style, Decisions, 'Greenbull's look', with one line saying where the game-ready logo files are. Screenshots: the four files enlarged (nearest-neighbour) on a dark and a light background, in art-archive/<this ticket>/screenshots/.

The board's review: open the four files in game/art/logo/ (and the screenshots) and confirm they are the approved emblem (T-294, run 2) and wordmark (T-295, run 1), unchanged; they are seen in the game on the level-up screen, the gift pack and the helicopter in this goal's playtest.

## Acceptance criteria

- [ ] game/art/logo/greenbull_emblem_128.png, greenbull_emblem_64.png, greenbull_emblem_32.png and greenbull_wordmark.png exist and are byte-identical to art-archive/T-294/greenbull_emblem_128.png, _64.png, _32.png and art-archive/T-295/greenbull_wordmark.png (same SHA-256, listed in the result notes). (QA: pass / fail)
- [ ] Each of the four files has a json record beside it naming its source file, its ticket (T-294 or T-295) and its run (run 2 or run 1). (QA: pass / fail)
- [ ] The redgull_logo_128.png, _64.png and _32.png files and their records still exist, either in game/art/logo/ or moved with git mv into art-archive/<this ticket>/ (git log --follow shows the move); none is deleted. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py art <file> --greenbull` and D1's logo check pass on each of the four copies (output in the result notes). (QA: pass / fail)
- [ ] The ticket's Style review has one style loop round per file, each keeping the byte-identical copy. (QA: pass / fail)
- [ ] No PixelLab call is made: the result notes say so, and the PixelLab generation log has no entry for this ticket. (QA: pass / fail)
- [ ] Visual style, Decisions, 'Greenbull's look', says where the game-ready logo files are. (QA: pass / fail)
- [ ] The four files are shown enlarged on a dark and a light background in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

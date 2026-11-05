---
id: T-539
title: Paired meteors: drifting between a pair hurts the kaiju
status: open
from: project-lead
to: enemy-behavior
lead: Rails
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/enemies/kaiju_meteors.gd]
files_expected_to_change: [game/scripts/enemies/, game/data/enemies.json, game/data/meteor_fx.json, game/tests/, game/docs/enemies/, docs/enemies.md]
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

Build Enemies, Decisions, "Paired meteors hurt the kaiju". The kaiju's meteors land in pairs (propose the distance between the two, wide enough to drift through). After both have landed, a drifting car that crosses the segment between the two boulders hurts the kaiju (propose the damage next to the 1500 health and the 1-minute fight), and both boulders of that pair are destroyed at once (a short break-up effect). Show the link: for example a beam or energy line that runs from the pair to the kaiju with a hit flash on the kaiju; placeholder effect drawn in code, no generated art, no new text. Each pair pays once. Make it easy to see which two meteors are paired (for example a faint line between them). Keep the existing meteor rules (warning area, damage on landing, 10 s life) unless pairing needs a change; list any change.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging (the kaiju arrives at 3:00; God mode can help).

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Meteors land in pairs at the proposed distance (test). (QA: pass / fail)
- [ ] A drifting car crossing between a landed pair damages the kaiju by the data's amount and destroys both boulders; driving through without drifting does neither; a pair pays only once (tests). (QA: pass / fail)
- [ ] The link effect from the pair to the kaiju and the hit flash play (test that they are spawned). (QA: pass / fail)
- [ ] docs/enemies.md Content describes it with each proposed number. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF or frame strip in art-archive/T-539/screenshots/ shows a drift through a pair, the link and the kaiju getting hit. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

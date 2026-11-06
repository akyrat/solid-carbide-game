---
id: T-546
title: No rails on the default map: remove T-541's playtest rails
status: open
from: project-lead
to: level-challenge
lead: Rails
epic: level-challenges
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/data/level/kaiju_city_map.json]
files_expected_to_change: [game/data/level/kaiju_city_map.json, game/tests/, docs/level-design.md]
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

Build Level design, Decisions, "Rails" (the board, 2026-11-06): the game's default map has no rails; the board places them itself in the level creator later. T-541 put 5 rails on game/data/level/kaiju_city_map.json for its playtest; remove them all (the empty "rails" list may stay, if the loader expects it). Change nothing else on the map. Rails keep working from levels that have them (the creator's levels and tests). Update any test that expected rails on the default map, and say in docs/level-design.md Content that the default map has none.

The board's review: start a run from C:\solid-carbide-worktrees\T-546\game\project.godot and check that no rails are on the map.

Never write, move or commit anything in game/data/levels/ (the board's own levels). Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/level/kaiju_city_map.json has no rails and is otherwise unchanged (a diff of the file shows only the rails removed). (QA: pass / fail)
- [ ] A test checks that the default map loads with no rails, and the rail grind tests still pass on their own test rails. (QA: pass / fail)
- [ ] docs/level-design.md Content says the default map has no rails. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-546/screenshots/ shows the spot where the playtest rails were, now empty, in a run. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

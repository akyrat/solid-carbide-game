---
id: T-541
title: Rail grinding prototype: rails on the map, grind along them, jump between them
status: open
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-533]
documents_affected: [docs/drifting.md, docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/tricks.md]
files_expected_to_change: [game/scripts/driving/, game/scripts/level/, game/scenes/, game/data/combo.json, game/data/level/kaiju_city_map.json, game/tests/, game/docs/driving/, docs/drifting.md, docs/level-design.md]
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

Build Drifting, Decisions, "Rail grinding, a prototype", and Level design, Decisions, "Rails" (the map side; the level creator's piece is T-542). A rail is a map piece: a straight segment (propose whether curves or corners are needed for the prototype) at a height, stored in the level file so the creator can place it later; define the format and write it in docs/level-design.md Content. Placeholder art drawn in code (a metal bar with a shadow, at the right depth in the isometric view). Grinding: a car that lands on or drops onto a rail (within a proposed distance, moving roughly along it) locks on and slides along it, sparks, its speed along the rail kept and slowly lost (propose), steering doesn't leave the rail; it leaves at the rail's end, or with Jump (Left Shift, the Jump power-up) which hops off and can land on another rail. Grinding counts as a trick: T-533's popup text, paid when the grind ends by its length or time (propose), adds to the combo and pays subs. Start from the old wall grind's rules (Drifting, Content, "Trick prototype (reference)"; code on the branch hold/trick-prototype). For the playtest, put a handful of rails on the run's map where they connect parts of the map, including two close enough to jump between with the first Jump tier, and make the playtest build start runs with the Jump power-up (a playtest switch in data, off on master).

The board's review: play the grind prototype build from C:\solid-carbide-worktrees\playtest-grind-rails\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Rails load from the level file in the documented format and draw at the right depth (test plus screenshot). (QA: pass / fail)
- [ ] A car landing on a rail moving along it locks on, slides along it and leaves at its end; one landing across it doesn't lock on (tests). (QA: pass / fail)
- [ ] Jump while grinding hops off; landing on a second rail starts a new grind (test). (QA: pass / fail)
- [ ] Ending a grind pays the grind trick with T-533's text, adds to the combo and pays subs, with its numbers in game/data/combo.json (test). (QA: pass / fail)
- [ ] The playtest switch starts runs with the Jump power-up and is off in the committed default data on master (test). (QA: pass / fail)
- [ ] docs/drifting.md and docs/level-design.md Content describe the grind and the rail format, with each proposed number. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] GIFs in art-archive/T-541/screenshots/ show a car landing on a rail, grinding, and jumping to a second rail in a run. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

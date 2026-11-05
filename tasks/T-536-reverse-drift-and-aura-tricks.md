---
id: T-536
title: Two new tricks: the reverse drift and the aura
status: blocked
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
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/tricks.md]
files_expected_to_change: [game/scripts/driving/trick_detector.gd, game/data/combo.json, game/tests/, game/docs/driving/tricks.md, docs/drifting.md]
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

Build Drifting, Decisions, "A reverse drift trick" and "An aura trick", in the trick detector like the other tricks (paid with a popup, adds to the combo, pays subs, counts for the recap's tricks). Use exactly T-533's popup texts. Reverse drift: propose what counts (for example a drift while the car's velocity points backwards relative to its nose, for at least a minimum time) and its worth next to the existing tricks. Aura: the car stationary (propose a speed threshold) for 5 s, then one aura trick paid every full second while it stays still; moving resets the count; it doesn't pay during pause, the level-up screen, a wreck or the time-up screen. Both numbers live in game/data/combo.json. The trick list and tutorial are not changed in this ticket.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A reverse drift that meets the proposed rule pays the reverse drift trick once with T-533's popup text; a forward drift doesn't (tests). (QA: pass / fail)
- [ ] Staying still pays nothing for the first 5 s, then one aura trick each second; moving above the threshold resets it; nothing pays while paused or wrecked (tests). (QA: pass / fail)
- [ ] Both tricks add to the combo and pay subs like the other tricks, with their numbers in game/data/combo.json (test). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/tricks.md describe both, with each proposed number and its reason. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots or GIFs in art-archive/T-536/screenshots/ show each popup in a run. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

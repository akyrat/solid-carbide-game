---
id: T-559
title: Texts for the interactive tutorial slides
status: open
from: project-lead
to: narrative-theme
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/extended-narrative.md, game/data/tutorial_text.json, game/data/mission_text.json]
files_expected_to_change: [game/data/tutorial_text.json, docs/hud-and-menus.md]
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

Write, through the style loop, the texts of HUD and menus, Decisions, "Interactive tutorial slides", into game/data/tutorial_text.json (or the data file the notebook reads its goals from), each with a key and a _comment saying where it appears: (1) slide 1, the loop: a title and the short words of the chain do tricks, gain subs, get weapons, repeat, with the point that by the 4-minute mark the player is strong enough to take on the kaiju; (2) for each trick slide (drift, alt drift, air spins, grind): a title and a one-line instruction with the keys, in the voice of today's trick list recipes; (3) the notebook goal line for each ("x/3" style, like the missions' goals); (4) the success message shown over the practice window after the third success (one, or one per slide); (5) any hint the grind slide needs about the Jump gift offered at its start. Reuse today's last slide texts. Mark texts of the old slides 1 to 3 that are no longer shown as unused in their _comment, deleting nothing. List every key in the result notes for T-562.

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each text listed in the description exists with a key and a _comment, listed in the result notes with what it is for. (QA: pass / fail)
- [ ] Each text has a style loop score of 8 or more in the Style review, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists the new texts. (QA: pass / fail)
- [ ] The tests for the changed data pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-562
title: The interactive tutorial slides
status: open
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/menu/tutorial_slides.gd]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/tests/, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "Interactive tutorial slides", on today's tutorial_slides.gd. Six slides: (1) the loop, with the HUD's own icons as today's slide 2 chain does; (2 to 5) drift, alt drift, air spins, grind, each with its title, instruction and a practice window a bit bigger than today's clips, embedding T-561's practice scene set to that trick, with the success message over the window only after the third success; (6) today's last slide, the kaiju timeline, with Go live and Don't show again. The missions slide goes. **Keys:** on the trick slides A, D and Space drive the car, so they must not change slides or press buttons there (today they do); propose how the player moves between slides (the mouse on the arrows and Skip; say if any key still does) and how the practice window gets the keyboard. Practising is optional. Pause the practice when its slide isn't showing. All texts from T-559's keys (its result notes), no placeholder text. This ticket starts once T-559's texts have passed QA; T-560 and T-561 are merged into its branch when they pass QA (until then, build against their interfaces as described in their tickets).

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The tutorial shows the six slides in order with T-559's texts (test). (QA: pass / fail)
- [ ] Each trick slide embeds the practice scene set to its trick, and the success message appears over the window only after the third success (tests). (QA: pass / fail)
- [ ] On the trick slides, A, D and Space don't change slides or press buttons, and they drive the car (test). (QA: pass / fail)
- [ ] The arrows, Skip, Go live and Don't show again still work (tests). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content describes the slides and the keys. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-562/screenshots/ show each slide, a practice in progress and the success message. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

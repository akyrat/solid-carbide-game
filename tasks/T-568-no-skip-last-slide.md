---
id: T-568
title: No Skip button on the last tutorial slide
status: done
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/menu/tutorial_slides.gd]
files_expected_to_change: [game/scripts/menu/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 1
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

Build HUD and menus, Decisions, "No Skip on the last tutorial slide": the last slide (the kaiju timeline, with Go live and "Don't show again") shows no Skip button; every other slide keeps it. Going back from the last slide brings Skip back.

The board's review: play it from C:\solid-carbide-worktrees\T-568\game\project.godot: page through the slides to the last one and back.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The last slide has no Skip button; the other slides show it, also after going back from the last (tests). (QA: pass)
- [ ] Go live and "Don't show again" work as before (the existing tests pass). (QA: pass)
- [ ] docs/hud-and-menus.md Content and game/docs/hud-and-menus/tutorial-slides.md describe it. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Screenshots in art-archive/T-568/screenshots/ show the last slide without Skip and the slide before it with Skip. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: UI agent at work in its folder.

### 2026-11-07, In progress → In QA

Built: Skip hidden on the last slide, back when going back. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (5/5). Waiting for your playtest.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Skip is hidden on slide 6 (tutorial_slides.gd show_slide); back to slide 5 shows it again. New test test_the_last_slide_has_no_skip_and_going_back_brings_it_back; the Skip-from-every-slide test now covers slides 1-5. Tutorial tests: 58/58 pass (624 asserts). Docs: docs/hud-and-menus.md (slide 6 bullet), game/docs/hud-and-menus/tutorial-slides.md. Screenshots: art-archive/T-568/screenshots/last_slide_no_skip.png and slide5_with_skip.png.
- 2026-11-08, needs-playtest → done: Board: menu fixes build played, merge (2026-11-08)

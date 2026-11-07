---
id: T-563
title: A trick falls into the mission notebook with a splash
status: needs-playtest
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/scripts/hud/mission_page.gd]
files_expected_to_change: [game/scripts/hud/, game/tests/, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "A trick falls into the notebook": when a trick counts toward the current mission's goal (mission_page.gd), a small box with that trick's name (the trick's popup name, from the existing texts) appears above the notebook's top and falls into it, landing on the goal line with a little splash, then the count updates. Drawn in code in the notebook's pixel look (no PixelLab). Several tricks in a row queue or overlap without hiding the count (propose). It works the same in the practice windows (T-561 uses the same notebook). Propose the timing and the splash.

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A trick that counts toward a mission goal plays the falling box with the trick's name and the splash, then the count updates; a trick that doesn't count plays nothing (tests). (QA: pass: test_mission_page_fall covers a counting trick's box and delayed count, and a non-counting trick playing nothing)
- [ ] Quick tricks in a row don't hide the count or break the page (test). (QA: pass: queue and burst tests keep every count arriving)
- [ ] docs/hud-and-menus.md Content describes it. (QA: pass: Content paragraph at hud-and-menus.md line 146)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass: qa_check test sets pass; counts in result notes)
- [ ] A GIF in art-archive/T-563/screenshots/ shows it in a run. (QA: pass: GIF 87 frames at 1152x648; strip shows ALT DRIFT! box falling onto the goal line, splash of blue droplets, count 0/10 to 1/10)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: a trick's name box falls into the mission notebook with a splash.

### 2026-11-07, In progress → In QA

Built: a counting trick drops its name box into the notebook with a splash. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (5/5). Waits for you in the combined build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. A trick that counts toward a mission goal now drops a small paper box with its popup name into the notebook, with a splash, and the count updates on landing.

How: `RunMissions` gets a signal `trick_counted(mission, goal, trick_id)`, sent in `on_trick` just before that goal's progress (a trick that matches no open goal sends nothing). `MissionPage` (game/scripts/hud/mission_page.gd) listens, draws the box in an overlay child in code (paper box, ink border, comic font, popup text from `TrickPopups.TEXTS`, no PixelLab, no new text), and holds back the page's own updates (count, tick, next mission) until the box lands, in order. The same page is used by the tutorial practice windows, so they get it too.

Proposals for the playtest: fall 0.32 s (gravity ease), squash 0.07 s, splash 0.28 s (7 blue droplets fanning up), boxes start at least 0.14 s apart so quick tricks queue and each count arrives in order, at most 4 waiting (a bigger burst only updates the count), a mission-completing trick plays its box before the next page appears. Box lands over the goal's line.

Existing tests changed: test_hud_mission_page.gd now calls `finish_falls()` before checking counts (counts arrive after the box).

Tests run (foreground): test_mission_page_fall (new, 7/7), test_hud_mission_page 11/11, all `test_hud*` 210/210, test_tutorial_slides 26/26, test_missions* 20/20, test_missions_power_ups_run 4/4.

Docs: docs/hud-and-menus.md Content (new paragraph after the mission notebook page). Screenshots: art-archive/T-563/screenshots/notebook_fall.gif (a run: one alt drift, three quick ones, then a rail grind that counts for nothing, so nothing falls) and notebook_fall_strip.png (frames). Recorded with new `game/tools/record_notebook_fall_gif.sh` and fixture `game/tests/fixtures/notebook_fall_demo.tscn`.

Not committed: the many untracked `.uid` files Godot made.

Merge of task/T-562-interactive-tutorial-slides: one conflict in mission_page.gd (goal progress handler); resolved by keeping the deferred update and using T-561's line_text (goal_templates), so practice windows get the falling box too. test_practice_session now calls finish_falls() before reading the count (the count arrives on landing). Tests: test_practice_session 25/25, test_tutorial_slides 33/33, test_hud_mission_page 11/11, test_mission_page_fall 7/7.

test_tutorial_practice_real.gd now calls finish_falls() before reading the 3/3 count. test_tutorial_practice_real 6/6, test_tutorial_slides 33/33.

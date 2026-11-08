---
id: T-596
title: No popup for thread the needle (the trick still counts)
status: in-qa
from: project-lead
to: ui
lead: Rails
epic: hud
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/hud/trick_popups.gd, game/scripts/run/run_state.gd]
files_expected_to_change: [game/scripts/hud/, game/data/, game/tests/, game/docs/]
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

Build HUD and menus, Decisions, "No popup for thread the needle": threading the needle shows no trick popup (bubble) any more, in a run and in the tutorial's practice window. The trick still counts exactly as before: it raises the combo, counts for missions and the trick list, and the pair still flashes (T-451) and needle routes still advance (T-592). Prefer a data switch over deleting code, so it can come back. Other tricks' popups are unchanged.

The board's review: play it from C:\solid-carbide-worktrees\T-596\game\project.godot: thread a pair and a needle route on a level with pairs; the combo still rises with no bubble.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Threading the needle shows no popup (a test). (QA: pass / fail)
- [ ] It still raises the combo, counts for missions and routes, and flashes the pair (tests). (QA: pass / fail)
- [ ] Other tricks still show their popups (the existing tests pass). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content says so. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-596/screenshots/ shows a needle threaded with the combo up and no bubble. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, In progress → In QA

Needle bubble hidden by a data switch; the trick still counts and the pair flashes. QA now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Added data switch data/hud.json trick_popups.hidden=[thread_the_needle]; TrickPopups.is_hidden() checked in _on_combo_trick and _on_trick (run, practice window, prototype). Trick still counts (combo, missions, flash, routes untouched). Test updated + new test (hidden by data, other tricks still pop). Ran test_thread_the_needle, test_trick_popups, _heat, _prebuild, test_recap_screen, test_practice_session, test_bricks_perf: all pass. Screenshots: art-archive/T-596/screenshots/ (flash_030.png shows x1.48 combo, pair flashing, no bubble). Docs: docs/hud-and-menus.md Content, game/docs/hud-and-menus/popups.md.

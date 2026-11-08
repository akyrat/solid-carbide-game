---
id: T-592
title: Needle routes: thread-the-needle pairs played in order or at random
status: done
from: project-lead
to: level-challenge
lead: Rails
epic: level-creator
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-581-creator-free-placement.md, game/scenes/level_creator/, game/scripts/level_creator/, game/scripts/run/]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/run/, game/scripts/level/, game/data/, game/tests/, game/docs/level/, docs/level-design.md, game/tools/check_level.py]
model: opus
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

Build Level design, Decisions, "Needle routes". This branch starts from T-581's (free placement and moving pieces) with T-591's texts merged in; both wait for the board's playtest, so build on them (Project Lead, 2026-11-08: the texts are only seen in this build, so it doesn't wait for T-591 to be done). In the creator: a route tool (T-591's texts and key) where clicking pairs' dashed lines adds them to a route in click order; each route has an order switch (in order, cycling; or random) and a way to take a pair out; routes save in the level file (keep old levels loading; check_level.py accepts them). In a run: only each route's active pair pays thread the needle; it is drawn bright and the route's other pairs faint; threading it makes the next active (in order, wrapping; or a random other pair). Pairs in no route work as today, and so does the flash of T-451. Proposals with reasons in data: brightness levels; whether threading a waiting pair does anything (proposal: nothing). Never touch game/data/levels/: make your own test levels in game/tests/fixtures/.

The board's review: play it from C:\solid-carbide-worktrees\T-592: make a route in the level creator ("C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path C:\solid-carbide-worktrees\T-592\game res://scenes/level_creator/level_creator.tscn), test it, in order and random.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] In the creator, clicking pair lines with the route tool makes a route in click order, the order switch and taking a pair out work, and routes save and load (tests). (QA: pass)
- [ ] Levels without routes load and play as before (the existing tests pass) and check_level.py accepts a level with routes. (QA: pass)
- [ ] In a run, only the active pair pays; in order cycles back after the last; random never repeats the same pair twice in a row when the route has more than one (tests). (QA: pass)
- [ ] Active pairs draw bright and waiting ones faint (a test or screenshot). (QA: pass)
- [ ] docs/level-design.md Content and game/docs/level/ describe it. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Screenshots in art-archive/T-592/screenshots/ show a route in the creator and its active and waiting pairs in a run. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: needle routes, on top of free placement and the route texts.

### 2026-11-08, In progress → In QA

Needle routes built: N in the creator, click pair lines in order, In order or Random; in a run only the active pair pays, waiting pairs faint. QA next.

### 2026-11-08, In QA → Needs playtest

QA passed 7/7. Needle routes ready to play (includes T-581).

### 2026-11-08, Needs playtest

Board: lgtm. Merging T-581, T-591 and T-592 together after the current merge.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built needle routes (Level design, Content, 'Level creator: needle routes'; how it works: game/docs/level/level-creator-pieces.md, 'Needle routes (T-592)').
- Format: level file 'routes' [{id: route-N, order: in_order|random, pairs: [pair ids in click order]}], one place game/scripts/level/needle_routes.gd (NeedleRoutes). No 'routes' key when there are none, so old levels load and save unchanged. check_level.py check_routes accepts it (unique id, order, existing pair ids, a pair in one route at most).
- Creator (editor.gd, T-591's texts, key N): Route button/N turns the tool on (pair tool off); clicking pair lines adds them in click order (route_pair_added %d); right-click finishes the route (route_finished) and keeps the tool on, N/Esc finish it and turn it off; In order / Random switch; clicking a line of a route picks it and its route (later clicks add there), Remove from route takes it out; empty routes go; Unpair or deleting an obstacle takes its pair out of its route. Hint line now controls_hint_routes. Drawn: route lines in the route's colour (cyan, pink, amber, violet), numbered 1, 2, 3, 'Route: n pairs' above the first; route being changed thicker, picked pair thicker still.
- Run (thread_the_needle.gd): only each route's active pair pays; paying moves the route on (in order wraps; random picks a different pair). Markers: active bright, waiting faint, free pairs as before. T-451's flash unchanged (only a paying pair flashes).
Proposals (game/data/level/needle_routes.json, with reasons): active alpha 0.9 and 1.6x width; waiting alpha 0.12; free 0.35 (as before); threading a waiting pair does nothing (no trick, flash or advance); a random route starts at a random pair (in order at its first); a pair is in one route at most (clicking it while building another moves it); right-click keeps the tool on for the next route; editor route colours; obstacles of waiting pairs drawn as always.
Also fixed: test_creator_hints.gd failed on this branch (T-576's hint test met T-581's free placement: placed off the grid); its editor now holds Shift (snap_held), as T-581 did for the other grid tests.
Tests: new tests/unit/level_creator/test_creator_routes.gd (13 pass), tests/unit/run/test_needle_routes.gd (11 pass), tools/test_check_level.py TestCheckRoutes (59 pass in the file). Full Godot set (GUT_TIME_LIMIT=2400): 3190 tests, 3189 passing, 0 failing, 1 risky/pending, 251 s.
Screenshots: art-archive/T-592/screenshots/route_in_editor.png (a 3-pair random route being edited and a 1-pair route), run_before.png (first pair bright, other two faint), run_after.png (after threading it: second bright, first faint). Fixtures: tests/fixtures/t592_routes_demo.tscn, t592_routes_run_demo.tscn.
Documents affected: docs/level-design.md (Content), game/docs/level/level-creator-pieces.md, game/docs/level/level-creator.md.
- 2026-11-08, in-progress → in-qa: Text nit for the playtest: the route label says '1 pairs' for one pair (T-591's route_label).
- 2026-11-08, needs-playtest → done: Board: played T-592's build (which holds T-581 and T-591), lgtm (2026-11-08)

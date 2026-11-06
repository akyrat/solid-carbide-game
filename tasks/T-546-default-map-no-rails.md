---
id: T-546
title: No rails on the default map: remove T-541's playtest rails
status: needs-playtest
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

Build Level design, Decisions, "Rails" (the board, 2026-11-06): the game's default map has no rails; the board places them itself in the level creator later. T-541 put 5 rails on game/data/level/kaiju_city_map.json for its playtest; remove them all (the empty "rails" list may stay, if the loader expects it). Change nothing else on the map. Rails keep working from levels that have them (the creator's levels and tests). Update any test that expected rails on the default map, and say in docs/level-design.md Content that the default map has none.

The board's review: start a run from C:\solid-carbide-worktrees\T-546\game\project.godot and check that no rails are on the map.

Never write, move or commit anything in game/data/levels/ (the board's own levels). Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/level/kaiju_city_map.json has no rails and is otherwise unchanged (a diff of the file shows only the rails removed). (QA: pass)
- [ ] A test checks that the default map loads with no rails, and the rail grind tests still pass on their own test rails. (QA: pass)
- [ ] docs/level-design.md Content says the default map has no rails. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A screenshot in art-archive/T-546/screenshots/ shows the spot where the playtest rails were, now empty, in a run. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-06, Open → In progress

Started: removing T-541's 5 playtest rails from the default map. The agent is working in C:\solid-carbide-worktrees\T-546.

### 2026-11-06, In progress → In QA

Built: the default map's 5 rails are removed. QA is checking it.

### 2026-11-06, In QA → Needs playtest

QA passed: only the 5 rails removed from the default map, street empty in the screenshot.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Removed the 5 rails from game/data/level/kaiju_city_map.json (now an empty "rails": []; nothing else changed). test_rail_grind.gd: the two game-map rail tests became test_the_game_map_has_no_rails and a jump-pair-gap test on the test layout. test_run_rails.gd now runs on a user:// copy of the map with the five old rails added (GameFlow.add_run), so run, draw, grind and hop tests keep working. docs/level-design.md Content: the default map has no rails (lines for the map copy, its contents, and the rails list). Tests run (GUT, -gselect): test_run_rails 225 asserts pass, test_rail_grind 27 tests pass, test_game_map pass, test_tutorial_clips 7 pass. Screenshots in art-archive/T-546/screenshots/: default_map_no_rails_spawn.png (street where rail-3/4 were, empty), default_map_no_rails_roofs.png. Note: the T-543 tutorial clip fixture (tutorial_clip_rail_grind) and rail_grind_gif_demo drive onto rail-3 on the game map, so they now show no rail; they are fixtures, not tests, left unchanged. Untracked Godot .uid files and .import noise left uncommitted.

QA round: all 5 criteria pass. qa_check: tests (2 sets, tools set skipped: nothing under tools/ changed), documents, screenshots all PASS. Map diff: only the rails list removed (now "rails": []). Screenshot default_map_no_rails_spawn.png shows the empty street. T-543 grind clip fixtures (tutorial_clip_rail_grind, rail_grind_gif_demo) are fixtures under game/tests/fixtures, not referenced by any test in tests/unit or tests/integration; test_run_rails uses its own map copy with the old rails. No test depends on the default map's rails.

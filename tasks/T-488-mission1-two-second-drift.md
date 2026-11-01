---
id: T-488
title: The first mission is a 2-second drift instead of 4
status: done
from: project-lead
to: game-data
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/data/missions.json]
files_expected_to_change: [game/data/missions.json, game/tests/unit/]
model: sonnet
qa_rounds: 2
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

The board, 2026-11-01 (Game loop architecture, missions, already updated): mission 1 is one unbroken drift of 2 seconds, not 4. Change game/data/missions.json mission 1's amount to 2 (and its note). The notebook line is built from the amount by screen_texts.json's extended_drift pattern, so no text changes. Update any test that expects 4. Never write, move or commit anything in game/data/levels/.

The board's review: start a run and see the notebook's first mission ask for 2 seconds; a 2-second drift ticks it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/missions.json mission 1 asks for one unbroken drift of 2 seconds; a test shows a 2-second drift completes mission 1 and a shorter one does not. (QA: pass; missions.json mission 1 amount 2 and note; test_missions: 2.0 s completes, two 1 s drifts and 1.5+1.5 across a wall hit do not)
- [ ] The notebook's first line reads with 2 seconds (a test or a screenshot listed in the result notes). (QA: pass; test_hud_mission_page asserts 'Hold one drift for 2 seconds')
- [ ] The tests for the changed files pass (the agent, with -gselect), and QA's full run passes (tasks/README.md, "Which tests run when"), with the counts in the result notes. (QA: pass; round 2: the elevation-map test now starts at mission 5 with the same assertions; qa_check ran all 3 test sets, passed, GUT_TIME_LIMIT=1800)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass; branch diff touches only missions.json, 4 test files, the ticket)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Filed from the board's note: mission 1 becomes a 2-second drift. Game Data agent started.

### 2026-11-01, Needs playtest

QA round 2 passed. Ready to play: the first mission asks for a 2-second drift.

### 2026-11-01, Needs playtest

The board: LGTM. Merging, then pushing to itch.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Mission 1 amount and note now 2 seconds in game/data/missions.json. Tests updated: run/test_missions.gd (2.1 s completes; two 1 s drifts do not; 1.5 s + 1.5 s across a wall hit does not; 2 s completes), test_mission_data.gd, game/test_missions_power_ups_run.gd, hud/test_hud_mission_page.gd (notebook line reads 'Hold one drift for 2 seconds', built from the amount). Ran with -gselect: test_missions, test_mission_data, test_missions_power_ups_run, test_hud_mission_page, test_mission_texts, all passed. Nothing in game/data/levels touched.
- 2026-11-01, in-progress → in-qa: Mission 1 now 2 s; tests updated and passing
- 2026-11-01, in-qa → in-progress: QA fail: full Godot run hangs in tests/unit/run/test_run_elevation_map.gd test_the_run_goes_on_with_enemies_and_weapons (its 4 s scripted drift now completes mission 1 mid-test); same file passes on master in 40 s

QA round 1 fix: run/test_run_elevation_map.gd test_the_run_goes_on_with_enemies_and_weapons now starts at mission 5 (missions.current = 4 + _load_current) so its 4 s scripted drift no longer completes mission 1 and pauses the run on the power-up pick; same intent kept (run still going, enemies spawned). Grepped other run tests with long drifts: test_run_likes, test_run_likes_drain, test_wreck, test_wreck_decides_loss, test_run_combo need no change. -gselect passes: test_run_elevation_map 26/26, test_run_likes 37/37, test_run_likes_drain 19/19, test_wreck 37/37, test_wreck_decides_loss 14/14, test_run_combo 20/20, test_missions 20/20, test_mission_data 5/5, test_hud_mission_page 11/11. Screenshot of the notebook's first line (Hold one drift for 2 seconds): art-archive/T-488/screenshots/notebook_first_mission.png, made with the new fixture game/tests/fixtures/mission_page_demo_first.tscn. The doc docs/game-loop-architecture.md was already updated on master by the Project Lead.
- 2026-11-01, in-progress → in-qa: QA fixes: elevation-map run test, screenshot
- 2026-11-01, in-qa → needs-playtest: QA round 2 passed: all 4 criteria, 3 test sets green
- 2026-11-01, needs-playtest → done: 488 LGTM

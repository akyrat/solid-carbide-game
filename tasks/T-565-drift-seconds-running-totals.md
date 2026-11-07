---
id: T-565
title: The drift slide counts 3 s of drifting in total; total-time mission goals show their running total
status: done
from: project-lead
to: game-loop
lead: Rails
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, tasks/T-561-practice-session.md, tasks/T-563-notebook-trick-splash.md, game/scripts/hud/mission_page.gd]
files_expected_to_change: [game/scripts/run/, game/scripts/hud/, game/tests/, game/docs/game-loop/, docs/game-loop-architecture.md, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "The drift slide counts drift seconds" and Game loop architecture, Decisions, "Total-time mission goals show their running total". (1) Practice session (T-561): the drift slide's goal becomes 3 seconds of drifting in total, added up over all drifts (not one unbroken drift); the notebook shows the running total live as the player drifts, and the success signal fires when it reaches 3 s. The other trick slides keep counting 3 tricks. (2) In the run, a mission goal that adds time up (the airtime goal; any other total-time goal) shows its running total against its goal in the notebook, updating live as it grows (mission_page.gd and the run's progress signal). The unbroken drift goal is unchanged. Decide how T-563's falling name box behaves for time goals (propose: no box for each fraction of a second; for example a box when a drift or a landing adds its seconds) and say what you chose. Texts come from T-564's keys (merged into your branch when it passes QA); until then, a seam.

The board's review: in the combined build, play the drift slide (3 s in total) and a run's airtime mission.

A tweak to the interactive tutorial build after the board played it (branch playtest/interactive-tutorial, which has T-559 to T-563). Your branch starts from that build. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line. Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] On the drift slide, drifting adds up across drifts, the notebook shows the running total, and the success fires at 3 s in total (tests). (QA: pass)
- [ ] The other three trick slides still count 3 tricks (the existing tests pass). (QA: pass)
- [ ] In a run, the airtime goal shows its running total in the notebook, updating as airtime adds up (test); the unbroken drift goal is unchanged (test). (QA: pass)
- [ ] docs/game-loop-architecture.md and docs/hud-and-menus.md Content describe it. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A GIF in art-archive/T-565/screenshots/ shows the drift slide's total growing to 3 s and the run's airtime total growing. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: the drift slide counts 3 s of drifting in total; airtime goals show their running total.

### 2026-11-07, In progress → In QA

Built: the drift slide counts 3 s in total; airtime shows its running total (e.g. 2.7/3.0). QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (6/6). Into the tutorial build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (game-loop, 2026-11-07).

What changed:
- Drift slide (PracticeSession, game/scripts/run/practice_session.gd): the drift now counts seconds, not tricks. After each car step in which car.model.is_drifting is true (the flag the run's drift counter reads), add_drift_seconds(dt) adds that step's seconds to drift_seconds. The total is capped at DRIFT_SECONDS (3.0) and added up over all drifts, short drifts included. The notebook goal is {trick: drift_seconds, kind: seconds, amount: 3}. The session sends the new signal seconds_progress(done, goal) and sends completed() once the total reaches 3 s. LONG DRIFT! no longer counts on that slide (COUNTED.drift is empty). The other three slides are unchanged (still 3 tricks).
- Run (RunMissions, missions.gd): new is_running_total(trick, kind), true for a seconds goal other than extended_drift. New add_seconds(trick, seconds) adds time with no trick_counted, so no name box falls. The unbroken drift goal is untouched.
- Notebook (MissionPage, mission_page.gd): a running total's line fills {done} with the seconds so far, one decimal, cut down, so 2.96 reads 2.9 and the line never shows its goal early. {total}/{goal}/{seconds} are the amount. New goal_template(trick, kind), fill() and format_seconds(). The airtime already sends goal_progress on each landing, so its line now updates with each landing.

T-563's falling box with time goals (my choice, a proposal for the playtest): a trick that adds a lump of seconds drops its box as before (a landing: HANG TIME!), and the total updates when the box lands. Time added a little at a time (the drift slide, every physics step) drops no box, and the total grows live. The airtime total updates per landing, not live during the jump.

Seams for T-564 (no player text in code, fallbacks only to existing keys):
- PracticeSession.DRIFT_SECONDS_TEXT_KEYS = [tutorial, goal, drift_seconds]. While that key is missing, it falls back to T-559's tutorial.goal.drift (Drifts {done}/{total}, shown with seconds, e.g. Drifts 1.4/3).
- MissionPage.TOTAL_GOALS_KEY = goals_total, meaning screen_texts.json missions.goals_total.<trick>. While it is missing, the goal's usual line shows (Rack up {seconds} seconds of airtime, with no total), so the run's airtime total only becomes visible once T-564 is in.
At merge: if T-564's keys or placeholders differ (its round 1 used a {name} slot and the names goal_drift / goal_total_seconds), change those two constants, or add {name} to MissionPage.fill. Then re-record the GIF with bash game/tools/record_running_total_gif.sh art-archive/T-565/screenshots/running_totals.gif 16 2.

Tests: the new game/tests/unit/hud/test_mission_page_running_total.gd (8 tests: is_running_total, landings add up, add_seconds with no box and never on the unbroken drift, the airtime line follows the total with a stand-in template in the test, format, the unbroken drift line unchanged, count goals unchanged, the real file's line). Updated test_practice_session.gd: the drift counts no trick, adds seconds up and completes at 3 s, the other slides still count 3, real drifts add up live over two drifts, and the drift line shows the running total live. Also updated test_tutorial_practice_real.gd (the drift slide reaches 3 s in total) and test_hud_mission_page.gd (the seconds-format test now uses the unbroken drift). Selected runs: test_mission_page_running_total 8/8, test_practice_session 28/28, test_tutorial* 57/57. Full GUT run: 3037 tests, 3036 passing, 0 failing, 1 pending (pre-existing), exit 0. game/tools/test_text_inventory.py: 8 passed.

GIF: art-archive/T-565/screenshots/running_totals.gif (fixture tests/fixtures/running_total_demo.tscn, recorder game/tools/record_running_total_gif.sh). Part 1: the real car on the drift slide drifts, straightens, drifts again; the line goes 0.5, 1.5, 2.4 and stops at 3.0/3, ticked and crossed off. Part 2: a run with an airtime 3 s mission; three landings (0.9, 1.3, 0.5) drop HANG TIME! boxes and the line goes 0.9, 2.2, 2.7/3. Since T-564 is not in yet, part 2 uses a fixture-only stand-in line (the usual airtime line with {done}/{total} after it). Stills: drift_slide_3s_done.png, run_airtime_total.png. practice_session_demo.gd now uses add_drift_seconds.

Docs: docs/hud-and-menus.md (Content, The HUD: new paragraph 'Running totals in the notebook'; The interactive slides: the drift's 3 s), docs/game-loop-architecture.md (Content, Missions in the run: Running totals; The practice session: the drift counts 3 s), game/docs/game-loop/practice-session.md, game/docs/game-loop/the-run.md.

Update after T-564 was merged (2026-11-07): the seams now use T-564's keys. PracticeSession.DRIFT_SECONDS_TEXT_KEYS = tutorial.goal.drift (T-564 rewrote it in place: 'Drift seconds {done}/{total}'). MissionPage.TOTAL_GOALS_KEY = total_seconds (the one template '{name} seconds {done}/{total}'). New MissionPage.TOTAL_NAMES_KEY = total_seconds_names, which gives the {name} per trick (airtime: 'Airtime'); a seconds goal without a name keeps its usual missions.goals line. For a running total, {total} now shows one decimal too, as T-564's comments ask ('Airtime seconds 2.7/3.0', 'Drift seconds 3.0/3.0'). The fixture's stand-in line is gone. Tests for the changed code: test_mission_page_running_total 9/9 (now checks the real total_seconds line), test_practice_session 28/28, test_tutorial* 57/57, test_hud_mission_page 11/11, every mission* test passes (56). game/tools/test_text_inventory.py: 8 passed. The inventory finds no code text in mission_page.gd, practice_session.gd or missions.gd. GIF re-recorded with the real texts: art-archive/T-565/screenshots/running_totals.gif. The drift slide goes 1.5, 2.1, then 3.0/3.0, ticked; the run's airtime goes 0.9, 2.2, then 2.7/3.0. Stills updated: drift_slide_3s_done.png, run_airtime_total.png. Docs updated: hud-and-menus.md, game-loop-architecture.md, game/docs/game-loop/practice-session.md and the-run.md. A hook refused an 'rm -rf' of my own scratchpad frames folder (it guards tickets); I didn't retry it and recorded to a new folder instead.
- 2026-11-07, needs-playtest → done: Board: interactive tutorial build played, lgtm

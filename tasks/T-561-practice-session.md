---
id: T-561
title: The practice session: a small live run in a window, counting one trick
status: in-qa
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
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/drifting.md, game/docs/game-loop/the-run.md]
files_expected_to_change: [game/scripts/run/, game/scripts/game/, game/scenes/, game/tests/, game/docs/game-loop/, docs/game-loop-architecture.md]
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

Build the engine of the practice windows (HUD and menus, Decisions, "Interactive tutorial slides"): a self-contained practice scene the tutorial slide (T-562) embeds in a SubViewport. It loads the practice playground (T-560's level; until it is in, a stand-in on ground_grid.gd), puts the real car at the slide's start point, with the real driving, combo and trick signals, and no enemies, kaiju, clock, damage or gift packs. It is set up per slide with the trick to count: drift (a drift that pays LONG DRIFT!, so 1 s or more; propose), alt drift, air spin (AIR 180! or AIR 360!), grind (GRIND!). It counts successes, shows the goal in the real mission notebook inside the window ("x/3"), and signals the third success (the slide shows the success message over the window). For the grind slide, it starts by offering the Jump power-up gift (the real power-up gift overlay, in the window, one choice) and gives Jump when taken. The car resets to the start point if it leaves the area or on a key (propose). It reads input only while its window has focus, so the slide's other keys don't drive it. Text comes from T-559's keys. Make it testable headless.

The board's review: play the tutorial in the combined build (playtest/interactive-tutorial): press Start from the main menu.

Part of the interactive tutorial (board, 2026-11-07; HUD and menus, Decisions, "Interactive tutorial slides" and "A trick falls into the notebook"; Level design, Decisions, "The practice playground"; tickets T-559 to T-563). The board plays all of it at the end in one combined build (branch playtest/interactive-tutorial), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --append <file>` (write the file with the Write tool) or `--text`, and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The practice scene loads the playground (or the stand-in) with the real car and no enemies, clock or damage (test). (QA: pass)
- [ ] Set to each of the four tricks, it counts that trick and no other, and signals on the third (tests for each). (QA: pass)
- [ ] The notebook in the window shows the goal and its count (test). (QA: pass)
- [ ] The grind practice opens with the Jump gift and gives Jump when taken (test). (QA: pass)
- [ ] docs/game-loop-architecture.md Content and game/docs/game-loop/ describe it. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Screenshots in art-archive/T-561/screenshots/ show the scene with each trick's notebook goal. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: the practice session that runs the car in a window and counts one trick 3 times.

### 2026-11-07, In progress → In QA

Built: the practice session (24 tests). QA now.

### 2026-11-07, In QA → In progress

QA round 1: a hard-coded fallback goal text trips the text check. Back to the agent to read T-559's keys instead.

### 2026-11-07, In progress → In QA

Fixed: goal lines from the texts, running on the real playground (34 tests). QA round 2.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Game Loop Agent, 2026-11-07

**Built:** the practice session, `game/scenes/run/practice_session.tscn` (script `game/scripts/run/practice_session.gd`, class `PracticeSession`). It is a small live run for one tutorial practice window. It has the real car with its real driving, the combo (a `RunState` whose clock never runs), the trick popups, drift marks, smoke, rails and ramps. It counts one trick 3 times in the real notebook (`MissionPage`). The grind practice opens with the real power-up overlay, offering Jump alone. Nothing else is in it: no enemies, kaiju, clock, damage, gift packs, weapons, HUD or sounds. It pauses only itself (its `World` node), never the tree, so the slide around it keeps working.

**API for T-562 (the slide)**
- `setup(trick)`: the trick is `"drift"`, `"alt_drift"`, `"air_spin"` or `"grind"`, and the practice starts over. You can also set `session.trick` before adding it to the tree.
- `start()`, `pause()`, `is_running()`, `is_completed()`, `restart()` (start over from 0), `reset_car()` (only the car goes back to its start).
- `set_focused(on)`: the car reads keys only while focused, because it sets the car's `input_enabled`. The car reads `Input` actions directly, so the slide must call this. R (reset) and the overlay's keys come in as events through the SubViewportContainer.
- `take_gift()` takes the highlighted Jump card. The card's own click and Space or Enter also work when the window gets input.
- Signals: `trick_counted(trick_id, done)`, `progress(done, goal)`, `completed()` (on the third success, after its progress), `car_reset()`, `gift_opened()`, `gift_taken(id)`.
- How to use it: `game/docs/game-loop/practice-session.md`.

**Seams to point at the parallel tickets**
- **T-560, the playground.** `PracticeSession.PLAYGROUND_PATH` points to the stand-in `game/data/level/practice_stand_in.json`. The stand-in is a 100 x 100 square with one ramp to a short rooftop (the tutorial ramp clip's shape) and one rail at height 1. It has no painted ground, so the session draws `ground_grid.gd` with the edge outlined. It passes check_level.py (OK) and check_height_data.py (OK). Each trick's start point is read from the level's `"practice_starts": {drift, alt_drift, air_spin, grind}` (`{x, y, heading}`, the same form as `"spawn"`); a level without it falls back to its spawn. When T-560 merges, change the constant to T-560's file, and either T-560's level uses `practice_starts` or `start_point()` reads where T-560 put the starts. A level with a painted `"ground"` draws its own ground instead of the grid.
- **T-559, the texts.** `PracticeSession.GOAL_TEXT_KEYS` reads the notebook goal line from `game/data/tutorial_text.json`: `practice.goal_drift`, `practice.goal_alt_drift`, `practice.goal_air_spin` and `practice.goal_grind`, each a template with `{done}` and `{total}`. Change these to T-559's real keys. Until those keys exist, the line is the trick's existing name or names from `trick.*` followed by " {done}/{total}": "LONG DRIFT! 0/3", "ALT DRIFT! 0/3", "AIR 180! / AIR 360! 0/3", "GRIND! 0/3". No new wording was written.
- **T-563, the falling box.** It uses the same notebook. The goal's trick id is the car's own id (`extended_drift`, `alternate_drift`, `rail_grind`), except for air spins, which use `air_spin` because two tricks count. The `trick_counted` signal gives the actual trick id.

**Shared code changed (small, additive)**
- `missions.gd`: added `RunMissions.start_with(missions)`, a tracker with exactly the given mission.
- `mission_page.gd`: added `goal_templates` and `line_text()`, so one page can show its own goal lines. The run's page is unchanged. T-563 edits this file too; the two call sites of `goal_text` now call `line_text`.
- New `game/scripts/run/practice_offers.gd`: `PracticeOffers` is the real `PowerUpOffers`, except that it opens only through `offer_only(id)` and pauses only its session.

**Proposals for the playtest**
- What counts: a trick counts when it pays in the combo, which is when its popup shows.
  - Drift: LONG DRIFT!, one unbroken drift of at least 1 s (combo.json), counted when the drift ends.
  - Alt drift: ALT DRIFT!.
  - Air spin: AIR 180! or AIR 360!. One landing counts once, even a 540 that pays both.
  - Grind: GRIND!, a grind long enough to pay (0.3 s).
- After the third success the count stays at 3 and the player can keep driving.
- R puts the car back at its start while the window has focus. Leaving the playground (its rectangle plus 2 units) also resets the car, but the hard edges normally keep it in. The count stays after a reset.
- The Jump gift opens on the first `start()` after `setup` or `restart`. The overlay's header is the real gift's, "MISSION DONE: PIMP YOUR RIDE", which may read oddly in the tutorial. T-559 item 5 can add a hint, or the header can be swapped.
- The notebook sits at the window's top left and is drawn at 70% of the HUD's layout page, about 1.4 times the run's size for the window. At the HUD's own size it was tiny in a 704 x 440 window. The camera frames the car as the run does, scaled to the window's height.

**Tests (run by me, in the foreground, one at a time)**
- test_practice_session: 24/24 passed, 144 asserts. Covers each trick counting and no other, signalling on the third, the notebook line and count, the Jump gift, a real drift, a real hop onto the rail, a real ramp takeoff, pause, focus, R, and leaving the area.
- test_missions (selects 2 scripts): 20/20 passed, 219 asserts.
- test_hud_mission_page: 11/11 passed, 73 asserts.
- test_missions_power_ups_run: 4/4 passed, 47 asserts.
- test_power_up_offers: 16/16 passed, 1106 asserts.
- test_power_up_screen: 22/22 passed, 102 asserts.
- check_level.py and check_height_data.py on the stand-in: both OK.
- I did not run the full sets (QA's step).

**Screenshots** (`art-archive/T-561/screenshots/`, taken with `tests/fixtures/practice_session_demo.tscn` in a 704 x 440 window):
- practice_drift.png: drifting, "LONG DRIFT! 1/3".
- practice_alt_drift.png: "ALT DRIFT! 2/3".
- practice_air_spin.png and practice_air_spin_later.png: the car on the ramp, "AIR 180! / AIR 360! 1/3".
- practice_grind_gift.png: the Jump gift with one card over the window, "GRIND! 0/3".
- practice_grind.png: Jump taken, the car hopped onto the rail.
- practice_done.png: "LONG DRIFT! 3/3", ticked.

**Documents affected:** docs/game-loop-architecture.md (Content, "The practice session (task T-561)"), game/docs/game-loop/practice-session.md (new), game/README.md (index).

### Game Loop Agent, 2026-11-07, after QA round 1 (the failed text inventory test)

**Fixed:** the game no longer has any player text in its code. The hard-coded `GOAL_TEXT_FALLBACK`, and the fallback that built goal lines from trick names, are gone.
- `GOAL_TEXT_KEYS` now reads T-559's keys from `game/data/tutorial_text.json` (merged into this branch): `tutorial.goal.drift`, `tutorial.goal.altdrift`, `tutorial.goal.airspin` and `tutorial.goal.grind`, word for word ("Drifts {done}/{total}", "Alt drifts ...", "Air spins ...", "Rail grinds ...").
- If a key is missing, the game logs an error and shows an empty line.
- The inventory was not changed.

**Tests:**
- The tests no longer expect the old lines. They now check the goal lines against the data file (new test: `test_the_goal_lines_are_t559s_texts_word_for_word`).
- Results, run in the foreground, one at a time:
  - game/tools Python set: 1042 tests, OK (4 skipped), exit 0. This includes test_text_inventory.
  - test_practice_session: 24/24 passed, 149 asserts.

**Screenshots:** retaken in `art-archive/T-561/screenshots/` (same file names), so the notebook shows T-559's lines, for example "AIR SPINS 1/3".

**Still a seam:** T-560's playground (`PLAYGROUND_PATH` and the `practice_starts` key), as before.

**Docs:** `game/docs/game-loop/practice-session.md` now describes the wired T-559 keys.

**Still open for T-562:** `tutorial.success` ("Content secured!") and `tutorial.grind_hint` are T-562's to show. The session only sends `completed` and `gift_opened`.

### Game Loop Agent, 2026-11-07: T-560's playground wired

**Level:**
- `PLAYGROUND_PATH` now points to `res://data/level/practice_playground.json` (T-560, merged into this branch).
- The start points come from the level's `start_points`, read with `LevelStartPoints.of(layout, trick)`. The ids are `drift`, `alt_drift`, `air_spin` and `grind`; if one is missing, the car starts at the level's spawn.
- The level draws its own grid ground (`ground_style`), so the session's grid and edge drawing are removed.
- The stand-in `practice_stand_in.json` is removed, since nothing reads it now.

**All four tricks count on the real level:** each is driven with scripted keys from its own start point, as in T-560's drive.
- Drift: W + A, then let go, counts 1 LONG DRIFT!.
- Alt drift: forward drift, release, backward drift, counts 1 ALT DRIFT!.
- Air spin: W to the jump ramp, A in the air, counts exactly 1 (AIR 180! or AIR 360!) for the one landing.
- Grind: after taking the Jump gift, W to the ramp with Space held in the air. The car catches a rail, and the GRIND! counts 1 when it ends.

**Tests:**
- The tests now use the real level: area and rail counts come from the level, plus its grid style, its start points, and the spawn fallback.
- The stand-in hop and ramp tests are replaced by the four real-drive tests above.
- Results, run in the foreground, one at a time:
  - test_practice_session: 25/25 passed. Run together with T-560's test_practice_playground (selected by `test_practice_`): 34/34 passed, 208 asserts.
  - game/tools Python set: 1043 tests, OK (4 skipped).

**Screenshots:** retaken on the real playground in `art-archive/T-561/screenshots/` (same names). The fixture now steps the car itself, from each start point, and freezes it for the shot.
- practice_air_spin.png: the car in the air off the jump ramp, "AIR SPINS 1/3".
- practice_grind.png: the car on a rail with sparks.
- practice_air_spin_later.png is removed, since the main air-spin shot already shows the car in the air.

**Docs:** `game/docs/game-loop/practice-session.md` and docs/game-loop-architecture.md (Content) now name the real level and its start points.

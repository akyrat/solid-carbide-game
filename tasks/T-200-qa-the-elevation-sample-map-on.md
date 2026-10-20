---
id: T-200
title: QA: the elevation sample map on playtest/G-004, before the board's playtest
status: in-progress
from: project-lead
to: qa-integration
lead: Goal-G-004
epic: level-challenges
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: no
depends_on: [T-199]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, game/README.md]
files_expected_to_change: []
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Check the whole elevation sample map goal together on its build branch, playtest/G-004, before the board plays it. Run all three test sets. Start the game from the main menu headless (as the screen-flow tests do) and check a run still loads the MVP map (mvp_map.json) with its enemies and timer as before. Run the elevation sample map scene headless for 10 seconds. Run the scripted reachability drive and paste its log. Diff playtest/G-004 against master and check no trick code (no new trick types, airtime combos or arrow-key sequences) and no level-editor code was added, and mvp_map.json and elevation_test.json are unchanged. Check the long GDD was regenerated and the staleness check passes (the runner gives the result). Check the final screenshot set from D7 exists and shows what its notes say. Write the results in the result notes. Nothing to picture: say so in one line.

## Acceptance criteria

- [ ] On playtest/G-004 the GUT tests, the Python tool tests and the headless scene runs all pass (counts in the result notes). (QA: pass / fail)
- [ ] A run started from the main menu loads mvp_map.json and starts the run as before (test_screen_flow.gd and test_run_scene.gd pass). (QA: pass / fail)
- [ ] The elevation sample map scene runs headless for 10 seconds with no errors. (QA: pass / fail)
- [ ] The scripted reachability drive passes on playtest/G-004 (street to 3 to 6, then off 6, landing), and its log of maximum height and airtime is in the result notes. (QA: pass / fail)
- [ ] `git diff master...playtest/G-004 --stat` shows no trick or level-editor code added, and game/data/level/mvp_map.json and elevation_test.json unchanged. (QA: pass / fail)
- [ ] The long GDD is regenerated and the staleness check passes on the build (as given by the runner). (QA: pass / fail)
- [ ] The final screenshot set listed in D7's result notes exists at those paths and shows what the notes say. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-200.

## Result notes

**QA results (round 1, on playtest/G-004 at 738ba6d + T-200 start commit):**

1. Tests: pass. GUT 1119/1119 passed (92 scripts). Python `unittest discover game/tools`: 342 tests, OK (1 skipped). Headless scene run: pass (item 3). (A "SOME FRAMES FAIL" line in the Python output is a checker's own test fixture, not a failure.)
2. Main menu to run: pass. test_screen_flow.gd and test_run_scene.gd are in the 1119 GUT tests, all passing, and mvp_map.gd (the run's map) loads in them (kaiju/enemy tests build it). mvp_map.json is unchanged.
3. Pass. `python game/tools/run_scene_headless.py res://scenes/elevation_sample/elevation_sample_map.tscn 10`: "stopped after 10 s, no errors".
4. Pass, with one limit. `bash game/tools/drive_elevation_sample.sh` was refused (not on the pre-approved list), so I did not run it. The same drive runs inside test_drive_elevation_sample.gd (4/4 passed); its log:
   - Layers reached: 0 at 0.00 s, 3 at 1.82 s, 6 at 5.30 s, 0 at 7.32 s
   - Jump 1 (0-to-3 ramp top): max height 3.75, airtime 0.70 s, landed on 3
   - Jump 2 (3-to-6 ramp top): max height 6.89, airtime 0.76 s, landed on 6
   - Jump 3 (off the height-6 edge): max height 6.00, airtime 1.00 s, landed on the street
   - Maximum height 6.89 units at 4.92 s; airtime off the height-6 edge 1.00 s; wall hits 0; PASS
5. Pass. `git diff --stat master...HEAD`: 144 files, none under any trick code (no scripts/tricks, car or UI changes; the only grep hit for "trick|editor" in the new map script is a comment "run it from the editor"). No level-editor code. mvp_map.json and elevation_test.json show no diff. Changes in mvp_map.gd (8 lines), ground_height.gd and elevation_platform_drawing.gd are the height-layer support.
6. FAIL / not verified. docs/long-gdd.md is tracked and has no diff on the branch, although docs/level-design.md, drifting.md and visual-style.md changed. The runner's staleness result was not given to me, and `python tools/generate_long_gdd.py` / the staleness check is not on my pre-approved list (refused). So on the files I can see, the long GDD was not regenerated on the branch. The runner or Project Lead needs to run the regeneration and the check.
7. Pass. All 9 PNGs listed in T-199's result notes exist in art-archive/T-199/screenshots/ on the branch (street, ramp-0-3, ramp-3-6, height-3, height-6, air, behind-height-3, behind-height-6, city-overview). I looked at air.png and behind-height-6.png: they show the car on a rooftop and the ramp; the shadow under the car in air.png is hard to see and the see-through effect in behind-height-6.png is not obvious. T-199's notes already say the air shadow is weak.

**Screenshots:** none: this is a check ticket, with nothing new to picture.

**Refusals:** `bash game/tools/drive_elevation_sample.sh` and `python tools/generate_long_gdd.py --help` (not on the pre-approved list). Neither was essential; criterion 4 is covered by the GUT test of the same drive, criterion 6 is left to the runner.

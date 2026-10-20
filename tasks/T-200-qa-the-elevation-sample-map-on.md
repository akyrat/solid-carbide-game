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

Written by the agent when it finishes.

---
id: T-436
title: The kaiju reaches a rooftop car on the board's latest level
status: in-progress
from: project-lead
to: enemy-behavior
lead: Audit
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/enemies.md, tasks/T-419-kaiju-path-size.md, game/tests/unit/enemies/test_kaiju_path_size.gd, game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/enemy_path_follower.gd, game/docs/enemies/ledges-and-rooftops.md]
files_expected_to_change: [game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/enemy_path_follower.gd, game/tests/unit/enemies/test_kaiju_path_size.gd]
model: opus
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

Follow-up to T-419 (Enemies, Decisions, "The kaiju only takes paths it fits through", with the edge rule the board kept on 2026-10-30). T-419's test test_kaiju_path_size.gd, test_the_kaiju_reaches_a_car_on_a_rooftop_from_ten_street_spots, reads the board's live level res://data/levels/kaiju_city.json. It passed when T-419 merged (about 20:07). The board saved that level at 21:12, and since then, on clean master, the kaiju never reaches the rooftop car from street spot (-79, 47) (path 190 units): reached false after 84.2 s, longest stop 1.00 s, the same on every run. The other nine spots still pass. Every merge into master now stops on this test. Find why the kaiju can't get there on the new level (a gap or edge closed by the size and edge rule, a re-plan loop, a drop it never takes, or the spot really being cut off) and fix the kaiju's planning or following, not the level. If the car really can't be reached from that spot on the board's level, don't loosen the test on your own: stop and report what blocks it, with a picture, and the Project Lead brings it to the board. A copy of the board's levels is in the ticket's folder for reading only. Never write, move, copy or commit anything in game/data/levels/, in any folder.

The board's review: on its level, drive onto a rooftop with the kaiju out on the west side, and see it come up after the car instead of getting stuck.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] test_kaiju_path_size.gd passes in full on the board's current kaiju_city.json, including the kaiju reaching the rooftop car from (-79, 47). (QA: pass / fail) (QA: pass / fail)
- [ ] The result notes name the cause: what on the new level stopped the kaiju, and where. (QA: pass / fail) (QA: pass / fail)
- [ ] The T-419 rules still hold: no kaiju path point closer than 2 units to a building, no gap narrower than 4 units on its path, and minions still use narrow gaps (the existing T-419 tests pass). (QA: pass / fail) (QA: pass / fail)
- [ ] Nothing in game/data/levels/ is added or changed on the branch (git diff --stat). (QA: pass / fail) (QA: pass / fail)
- [ ] New or changed headless tests cover the fix, and all three test sets pass, with the counts in the result notes. Screenshots: a picture of the kaiju's path from (-79, 47) before and after, in art-archive/<id>/screenshots/. (QA: pass / fail) (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Audit: started from master in C:\solid-carbide-worktrees\T-436 with T-419's Enemy Behavior Agent. Master's tests fail on this until it lands; Greenbull is holding its merges.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Enemy Behavior Agent, 2026-10-30: done.**

**Cause.** The kaiju wasn't cut off, and it wasn't stopped by a wall or an edge. It was stuck in a re-plan loop at ramp-12's foot, at about (-79, 46): ramp-12 is the ramp from the street up to roof-11, x -78..-66, y 42..52, foot at x -78. On the board's level as saved at 21:12, the kaiju's way from (-79, 47) to roof-1 runs north along x -77, which crosses the ramp's two low foot cells (-77, 45) and (-77, 43), ramp height about 0.1 to 0.3. Ramp-12 itself is closed to the kaiju: the AC unit prop at its top leaves no cell where its 2-unit body fits, and that was already so before. The level edit (new props, such as the parked car prop-78 at (-74, 36), and craters) changed which way was shortest, so the path now skims the ramp's foot. `enemy_navigation.gd` `through_ramps()` only kept a skimmed ramp's own cells when the path started before the ramp. When the kaiju stood on a foot cell, the ramp run started the path (i == 0), so it got the ramp's foot point (-79.5, 47), off the ramp. From there the next plan (one a second) skimmed the ramp again, and so on: back and forth between about (-78.9, 46.1) and (-78.4, 45.1), never more than about 1 unit from one spot. The test saw this as reached false after 84.2 s, longest stop 1.00 s.

**Fix.** `through_ramps()`: a ramp run whose height change is under `CLIMB_MIN` counts as skimmed even when the path starts on the ramp (`skim := j + 1 < n and absf(h_out - h_in) < CLIMB_MIN`; `h_in` is then the height of the cell the enemy stands on). A path that really climbs from a ramp's foot still goes to its top point (tested). The T-419 size and edge rules are unchanged. The planning was wrong, not the following, so `enemy_path_follower.gd` is untouched.

**Result on the board's current kaiju_city.json** (test_kaiju_path_size.gd): from (-79, 47) (path 190 units) reached in 59.9 s, longest stop 0.44 s; all ten spots reach (longest stop at most 0.44 s). Criterion 1: 50 pairs, 2791 waypoints, nearest 2.00 units to a building, 0 over an edge. The gap tests pass, so minions still use the 3 and 3.5-unit gaps and the kaiju does not.

**Tests.**
- New in `test_kaiju_path_size.gd`, on a made-up map with one ramp (they don't need the board's level): `test_a_path_starting_on_a_ramps_foot_that_only_skims_it_keeps_its_cells` fails with the old code, because the foot point was added. `test_a_path_starting_on_a_ramps_foot_that_climbs_it_still_goes_by_its_top_point`.
- Changed: T-380's `test_minions_round_ramps.gd` had `test_reproduced_stuck_at_the_bottom_end_of_a_ramp_before_the_fix`. It reproduced the same loop (old surface rule, minion on ramp-nw-0-3's foot, "a path back to the foot's point"). This fix removes that loop for every enemy, so the old rule now reaches the car, and the test failed. It is now `test_the_surface_rule_no_longer_sticks_at_the_bottom_end_of_a_ramp_since_t436` and asserts reached and no stop. That is a stronger check, not a looser one; the kaiju still walks by that rule. Project Lead: this is another ticket's test, please note it.
- Test runs on this branch: Godot GUT 2194/2194 passed (766 s; test_run_likes passed in the full run). An earlier full run had 2193/2194; the one failure was the T-380 reproduction test, before I changed it. `game/tools` Python 752 OK (1 skipped). `tools` Python 582 OK.

**Other files.** `game/tools/draw_kaiju_nav.gd` now also takes start points ("x,y") after the car and draws only the kaiju's paths from them. `game/docs/enemies/ledges-and-rooftops.md`: a T-436 line under T-419's section. Nothing in game/data/levels/ was changed or committed. One refusal: the command guard refused a `python -` heredoc edit of draw_kaiju_nav.gd/.sh (it can't tell whether a python command writes a ticket). I made those changes with the Edit tool instead; they touch no ticket.

**Screenshots** (`art-archive/T-436/screenshots/`, drawn from the data by `bash game/tools/draw_kaiju_nav.sh ... -32 36 -79,47 -77.9,44.9`; the car (white) on roof-1, two yellow starts: (-79, 47) on the street and (-77.9, 44.9) on ramp-12's foot cell, the kaiju's plans in cyan):
- `before_kaiju_paths_from_-79_47.png`, `before_ramp12_foot_zoom.png`: from the ramp-foot start the plan first goes back down-left to the foot point (-79.5, 47), and from there the street plan goes over the foot cell again. This is the loop.
- `after_kaiju_paths_from_-79_47.png`, `after_ramp12_foot_zoom.png`: from the ramp-foot start the plan goes straight on north. The zooms show 40 x 40 units round the foot, 16 px per unit. The difference is a short segment; the full map pictures show the whole 190-unit way, which hasn't changed.

Board review files: art-archive/T-436/screenshots/before_ramp12_foot_zoom.png, art-archive/T-436/screenshots/after_ramp12_foot_zoom.png

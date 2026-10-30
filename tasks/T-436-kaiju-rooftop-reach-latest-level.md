---
id: T-436
title: The kaiju reaches a rooftop car on the board's latest level
status: open
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

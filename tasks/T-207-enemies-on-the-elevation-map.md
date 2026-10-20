---
id: T-207
title: Enemies on the elevation map, with a proposal for how they handle heights
status: blocked
from: project-lead
to: enemy-behavior
lead: Coursework
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-206]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/level-design.md, game/README.md, tasks/T-206-run-on-the-elevation-sample-map.md, game/scripts/enemies/enemy_depth.gd, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/scripts/enemies/, game/tests/unit/, docs/enemies.md, game/README.md, art-archive/T-207/screenshots/]
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

After T-206 the run plays on the elevation sample map, and the board wants to see how the enemies behave there (Level design, Decisions, 2026-10-20). How enemies handle heights is not decided yet (Enemies, Open questions). Start from T-206's branch once it is done.

First, look at what the enemies do on the map as they are now, and write it in the result notes with screenshots. Do they pass through rooftops and ramps, get stuck on their edges, draw in the wrong depth order, or never reach a car on a rooftop? Then fix only what is broken (wrong depth order, getting stuck, falling through). Make the smallest proposal for heights that keeps the run playable. One example: enemies on the street treat raised areas as solid, like buildings, and use the ramps to reach a car on a rooftop. Another simple rule is fine if it turns out simpler. It is a proposal for the board's playtest, not a decision: write it under Enemies, Open questions, with this ticket's id, and keep the question open. Do not add new enemies or change their stats, numbers or attacks.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] The result notes describe how each enemy type behaved on the elevation map before any change, with screenshots (QA: pass / fail)
- [ ] Enemies are drawn in the right depth order next to the rooftops and ramps: behind a rooftop that covers them, in front of one they are in front of (screenshots) (QA: pass / fail)
- [ ] No enemy gets permanently stuck on a rooftop or ramp edge in a scripted test of enemies chasing a car parked on the street, and one parked on a rooftop; the test is in the GUT suite (QA: pass / fail)
- [ ] The proposal for heights is written under Enemies, Open questions, with this ticket's id, and the question stays open (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run on the elevation map and judge how the enemies behave and the proposal for heights.
Board review files: a run from the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

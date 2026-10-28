---
id: T-328
title: More gift packs, earlier in the run (a gentler start to the likes curve)
status: open
from: project-lead
to: game-data
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/weapons.md, game/docs/game-loop/gift-pack-and-pickups.md, game/docs/game-loop/the-run.md, game/data/run.json, game/data/combo.json, game/scripts/run/run_state.gd]
files_expected_to_change: [game/data/run.json, game/tests/unit/, game/README.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "More gift packs, earlier", 2026-10-28): the board wants more gift packs, coming more often, early in a run. Each level-up sends a gift pack, and today each level needs 25% more likes than the one before (`game/data/run.json`, `levels`: 100, 125, 156, 195, 244, 305, 381, 477, 596, 745, 931 to reach levels 2 to 12). Likes come only from drifting on today's map: 10 likes per whole second of a drift, times the combo multiplier; the likes drain eats progress inside a level once the combo has drained.

Propose a new curve in `run.json` where the early levels need clearly fewer likes, so the first few gift packs come quickly (for example the first one after a few seconds of drifting), and the later levels keep the run's pacing. Keep the level cap (12) unless there's a strong reason, and say how the total likes for all 11 levels compare with today's 4,255. Give a table like the Project Lead's (likes per level, and the seconds of drifting needed at x1, x2 and x4), the time to each gift pack in a typical run if you can estimate it (for example from the drift prototype or a scripted run), and the reason for the shape. `challenge_xp` only matters on the old MVP map; leave it unless the curve needs it. The likes drain is a share of the level's bar, so it scales with the new curve on its own: check that it still feels right at the small early levels (at 8% a second, a 40-like bar drains 3.2 likes a second).

The board's review: play a run and feel how fast the first gift packs come.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `run.json`'s levels need fewer likes than today for at least the first four level-ups, and the result notes give the full table (likes per level, seconds of drifting at x1, x2 and x4, the total) with the reasons. (QA: pass / fail)
- [ ] The game reads the new curve: a test levels up through the new thresholds (one gift pack per level-up) and stops at the cap. (QA: pass / fail)
- [ ] Every test that assumed the old numbers is updated, and none is weakened beyond the number change (the result notes list them). (QA: pass / fail)
- [ ] Game loop architecture, Content ("Likes and levels") and game/README.md describe the new curve. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

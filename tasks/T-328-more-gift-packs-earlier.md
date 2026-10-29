---
id: T-328
title: More gift packs, earlier in the run (a gentler start to the likes curve)
status: needs-playtest
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
qa_rounds: 1
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

- [ ] `run.json`'s levels need fewer likes than today for at least the first four level-ups, and the result notes give the full table (likes per level, seconds of drifting at x1, x2 and x4, the total) with the reasons. (QA: pass)
- [ ] The game reads the new curve: a test levels up through the new thresholds (one gift pack per level-up) and stops at the cap. (QA: pass)
- [ ] Every test that assumed the old numbers is updated, and none is weakened beyond the number change (the result notes list them). (QA: pass)
- [ ] Game loop architecture, Content ("Likes and levels") and game/README.md describe the new curve. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started overnight (build A, Stream reacts): the Game Data Agent is making gift packs come more often early in the run.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done by the Game Data Agent. Data only, no code change (`RunData.xp_needed()` reads `run.json`).

New curve (`game/data/run.json`, `levels`), likes for levels 2 to 12: 30, 45, 65, 95, 140, 200, 290, 400, 560, 745, 931 (was 100, 125, 156, 195, 244, 305, 381, 477, 596, 745, 931). Total 3,501, was 4,255 (-18%). Cap stays 12. Full table (seconds at x1, x2, x4, running total) and the reasons are in Game loop architecture, Content, "Likes and levels". Short form (seconds at x1 / x2 / x4): level 2 at 30 = 3 / 1.5 / 0.75; level 3 at 45 = 4.5 / 2.25 / 1.1; level 4 at 65 = 6.5 / 3.25 / 1.6; level 5 at 95 = 9.5 / 4.75 / 2.4; then 140, 200, 290, 400, 560, 745, 931.
Shape: growth about x1.45 per level at the start, easing to x1.25 at the end; levels 10 and 11 unchanged, so the late run keeps its pace. Estimate (from the formula, not a scripted run): at about 10 likes a second on average (drifting half the time at x2), gift packs for levels 2 to 5 at about 3, 7, 14 and 24 s; level 12 at about 350 s of 480 (old curve: level 5 at about 70 s). Drain: still 8% of the bar a second (a full bar empties in 12.5 s), so 2.4 likes a second at level 2's 30 bar against 10 earned per drifted second: fine.
challenge_xp (old MVP map only): I had to touch it. The old values (100, 110, ...) would skip levels with the new small bars and break "one challenge fills the bar", so each keeps its old share of the bar, capped at the old value: 30, 40, 50, 65, 84, 106, 135, 164, 201, then 236, 259, 285 unchanged.

Tests changed (number changes only, none weakened): `tests/unit/test_run_data.gd` (a drift second is 10 likes, no longer "10% of level 1"; drain at level 1 is 2.4, not 8); `tests/unit/run/test_run_likes.gd` (3 s of drift now levels up, so that test drifts 2 s and expects 2 s worth); `tests/unit/hud/test_hud_sub_goal.gd` (label test adds 20.4 likes instead of 42.4, which now levels up). New in test_run_likes.gd: `test_t328_early_levels_need_fewer_likes` (first four under 70% of the old, curve rising, total 3,501, cap 12) and `test_t328_one_level_up_per_threshold_and_stops_at_the_cap` (11 level-ups in order, none past the cap).

Docs: docs/game-loop-architecture.md (Decisions entry and Content table), game/docs/game-loop/the-run.md, game/README.md (index line). The long GDD is not regenerated: the merge script does it.

QA (round 1): all five criteria pass. Tests 3/3 sets pass; docs changed. Screenshots check red but waived: data-only ticket, nothing to show. Table with x1/x2/x4 and total 3,501 vs 4,255 is in Game loop architecture Content; tests and README index/the-run.md match run.json.

Tests (foreground): GUT 1818/1818 pass (a first run had 11 failures from the old numbers, fixed; a later run had 1 timing flake in a physics-frame clock test, green on the rerun); `game/tools` unittest 657 OK (1 skipped); `tools` unittest 560 OK.

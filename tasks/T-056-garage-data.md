---
id: T-056
title: Garage numbers: 3 upgrades, about 10 levels each, prices and effects
status: done
from: project-lead
to: game-data
lead:
epic: garage
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-038]
documents_affected: [docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, docs/drifting.md, docs/weapons.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [JSON data under game/data/, tests, docs/garage-design.md, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-038 (the data convention and the car's starting health) is done.**

The MVP garage sells three permanent upgrades, each with about 10 levels (Garage design, Decisions). Work out each level's price in coins and how much it improves:
- **Acceleration:** reaching top speed faster. It changes the car's time to top speed (Drifting; the setting is in the car's tuning from T-012 and T-029).
- **Car health:** raises the car's starting health from T-038's value.
- **Damage bonus:** a percentage added to the car's weapons' damage.

Prices should fit how many coins a run gives. If T-039's coin numbers aren't done, say what you assumed. Explain the numbers in the result notes, with a table. The board judges them in playtests.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data is valid JSON under `game/data/`, and a test loads it through T-038's loader (QA: pass / fail)
- [ ] A test shows each upgrade has a price and effect for every level, prices never go down, and effects only improve (QA: pass / fail)
- [ ] The result notes have the table and the reasoning, and `docs/garage-design.md` points to the data in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the Game Data Agent.

**Produced:** `game/data/garage.json`; typed reader `game/scripts/data/garage_data.gd`; tests `game/tests/unit/test_garage_data.gd`; one line in References of `docs/garage-design.md`; a "Garage" bullet in `game/README.md` ("Game data"). Full GUT suite passes (105 tests). The Python tool tests have 1 failure and 2 errors in `test_build_mvp_map.py` (KeyError 'boulders'); they fail the same way on clean master, so they are not from this task.

**Assumption (T-039 not done):** an average run gives about 250 coins (a good run about 400). All three upgrades together cost 4665 coins, about 19 average runs, so the first level is affordable after one run and a full garage takes a long time. Revisit once T-039's drop numbers exist.

**Numbers (for the board to judge).** Prices start at 40 (damage 60, the strongest effect) and grow 25% per level, rounded to 5. Acceleration: -0.1 s of time to top speed per level, from the car's 2.3 s down to 1.3 s (43% faster). Car health: +10 per level, from T-038's 100 up to 200. Damage bonus: +5% per level, up to +50%.

| Level | Acceleration price | Time to top speed | Car health price | Starting health | Damage price | Damage bonus |
|---|---|---|---|---|---|---|
| 0 | | 2.3 s | | 100 | | +0% |
| 1 | 40 | 2.2 s | 40 | 110 | 60 | +5% |
| 2 | 50 | 2.1 s | 50 | 120 | 75 | +10% |
| 3 | 60 | 2.0 s | 60 | 130 | 95 | +15% |
| 4 | 80 | 1.9 s | 80 | 140 | 115 | +20% |
| 5 | 100 | 1.8 s | 100 | 150 | 145 | +25% |
| 6 | 120 | 1.7 s | 120 | 160 | 185 | +30% |
| 7 | 155 | 1.6 s | 155 | 170 | 230 | +35% |
| 8 | 190 | 1.5 s | 190 | 180 | 285 | +40% |
| 9 | 240 | 1.4 s | 240 | 190 | 360 | +45% |
| 10 | 300 | 1.3 s | 300 | 200 | 445 | +50% |
| Total | 1335 | | 1335 | | 1995 | |

Reasoning: linear effects with prices that grow steadily make each level feel the same size while costing more, so the player keeps choosing between the three. Damage costs 50% more because +50% damage is the strongest effect. Each upgrade stays a flat, readable step for the plain-list garage. The health base matches `run.json`; acceleration's base matches the tuning's `time_to_top_speed`. Nothing here applies the upgrades to the car; that is for the Driving, Game Loop and Weapon agents, reading `GarageData`.

### QA round 1

Written by the QA/Integration Agent. Result: all four criteria pass.

- **Criterion 1 (valid JSON, test loads it through the loader): pass.** `game/data/garage.json` parses; `test_loads_through_loader` uses `GameData.load_file("garage")` and `GarageData`. Three upgrades (acceleration, car health, damage bonus in percent), 10 levels each, matching Garage design, Decisions. Level 0 values match the game: car health 100 = `car.starting_health` in `run.json`; acceleration 2.3 s = `time_to_top_speed` in `car_tuning.gd`; damage bonus 0. A test (`test_bases_match_the_game`) checks these.
- **Criterion 2 (price and effect per level, prices never down, effects only improve): pass.** I checked the file directly: every level 1-10 has a price and value; prices never decrease (acceleration and health 40 to 300, damage 60 to 445); acceleration time falls 2.3 to 1.3, health and damage rise. Tests cover each of these and pass.
- **Criterion 3 (result notes table and reasoning; garage-design.md only gains a References line): pass.** The notes have the table and reasoning, and the table matches the JSON. `git diff master...HEAD -- docs/garage-design.md` shows one line changed, in References only. Note: the agent had also edited the status legend comment in this task file; I restored it to the template text.
- **Criterion 4 (full GUT suite and Python tests): pass.** GUT: 105 of 105 tests pass (TESTS PASSED). `tools` Python tests: 72 OK. `game/tools` Python tests: 51 run, 1 failure and 2 errors, all in `test_build_mvp_map.py` (KeyError 'boulders', 12 != 6). They fail identically on master (51 run, 1 failure, 2 errors), so they are the known pre-existing issue tracked in T-087, not from this task. Counted as a pass.

Not judged: the balance of the numbers (the board's playtests).

### Board review

Merged on QA's pass (no board review needed), 2026-10-10. The numbers are judged in the playtest sessions.

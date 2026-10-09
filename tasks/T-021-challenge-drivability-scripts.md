---
id: T-021
title: Challenge drivability check and driven-line tool
status: in-qa
from: project-lead
to: driving-drift
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/level-design.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/level-design/, game/README.md, .claude/agents/driving-drift.md, .claude/agents/level-challenge.md]
files_expected_to_change: [the drivability script and its tests, result files for the 3 MVP challenges under docs/level-design/, docs/level-design.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Unblocked: T-012 is done** (2026-10-08). The check must use the real Godot car, not a copy of its rules.

The Driving & Drift Agent provides the script that checks a challenge design can be driven (its role), and the Level/Challenge Design Agent runs it before handing a challenge over. The board decided each challenge's arrow is a corridor 3 units wide, and the drawn car (1 by 3 units) only has to touch it; the boulders are 3 units across and the car's physics body is 1 by 1 (Level design and Drifting, Decisions). The board drew the 3 MVP challenges in `docs/level-design/` (one `.json` per arrow, with its boulders and arrow points).

1. **Drivability check:** a script that takes one challenge drawing (`.json`) and decides whether the car, with the game's driving values, can drive it: keep the drawn car touching the corridor from the start of the arrow to its end, in the arrow's direction, without hitting a boulder. Drive it with the T-012 car's own movement code, steering automatically (for example, a simple path-following controller that chooses W, S, A and D each physics step). Report pass or fail, and on a fail, where along the arrow it fails and why (for example, "the turn at point 7 is too tight at any speed").
2. **Driven-line tool:** for a passing challenge, save the line the car actually drove, and a picture with the boulders, the corridor and that line, next to the drawing (for example `arrow-1.driven.svg`), so the board and the Level/Challenge Design Agent can see how it plays.
3. Run both on the 3 MVP challenges and record the results. The board's drawings are rough sketches; the Level/Challenge Design Agent makes fitted versions for the map (T-019). Check the fitted versions where they exist, otherwise the sketches. **Do not change the sketches or the fitted versions:** if one fails, say where and why in the result notes, so the Level/Challenge Design Agent can adjust its fitted version.
4. Document how to run the script in `game/README.md`. In `docs/level-design.md`, add the result pictures to References and a factual line per challenge under Content ("drivable: yes/no"); do not change Summary, Decisions or Open questions. Follow `docs/README.md`.
5. Tests: the check passes a simple wide, gentle curve and fails an impossibly tight one, and the result is the same on every run.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The script runs on any challenge drawing in `docs/level-design/` and prints pass or fail; a fail names where along the arrow and why (QA: pass / fail)
- [ ] It drives the car with the T-012 car's movement code and driving values, not a separate copy of the rules, shown by reading the script (QA: pass / fail)
- [ ] Tests show it passes a wide gentle curve, fails an impossibly tight one, and gives the same result on every run (QA: pass / fail)
- [ ] All 3 MVP challenges were checked; each passing one has a driven-line picture next to its drawing, and the result notes give pass or fail for each (QA: pass / fail)
- [ ] The board's drawings (`docs/level-design/*/arrow-*.json` and `.svg`) are unchanged (QA: pass / fail)
- [ ] `game/README.md` explains how to run the script; `docs/level-design.md` links the pictures and still follows the five-section structure, with Summary, Decisions and Open questions unchanged (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: look at the driven lines and judge whether the challenges play as intended.

Board review files: [docs/level-design/single-boulder/arrow-1.driven.svg, docs/level-design/single-boulder/arrow-2.driven.svg, docs/level-design/two-boulders/arrow-1.driven.svg]

## Result notes

Written by the agent when it finishes.

**Built** (Driving & Drift Agent, 2026-10-09):

- `game/tools/challenge_checker.gd`: the check. It drives the real car model (`game/scripts/driving/car_model.gd`, preloaded and stepped with `step(w, s, steer)`; handling from `car_tuning.gd`) along the arrow at 50 steps per second, picking W, S, A and D each step. Each step it checks that the drawn car (1 x 3) touches the 3-unit corridor on the stretch of the arrow it has reached, and that the 1 x 1 physics body touches no boulder (or building cell). The centre line is the same rounded curve as the drawing's picture. Two drivers: a path follower (120 fixed settings of target speed, look-ahead and counter-steer) and a search over key combinations (beam search: all 9 key sets held for 5 steps, best 48 drives kept). Pass if any drive reaches the end; the saved line is the quickest passing drive. A fail names how far along the arrow, the nearest drawing point, the reason (hit boulder N, left the corridor, hit a building, stopped making progress) and the drawn curve's radius there.
- `game/tools/check_challenge.gd` (command line) with `check_challenge.sh` / `check_challenge.ps1`. `--save` writes `<name>.driven.json` and `<name>.driven.svg` next to each passing drawing; `--attempts=<folder>` saves a picture of the furthest attempt for a failing one; `--set=<key>=<value>` overrides a handling value. Exit 0 all pass, 1 a fail, 2 bad input. Documented in `game/README.md`, "Challenge drivability check".
- Tests: `game/tests/unit/test_challenge_checker.gd` (10 tests): a wide gentle curve (quarter circle, radius 14) passes; an impossibly tight U-turn round a boulder (0.6-unit gap, narrower than the 1-unit body) fails and names the place; both give identical results (verdict, steps, settings and the driven line point for point) on repeated runs; plus the car model and overrides are used, the 1 x 3 touch shape, the 1 x 1 boulder hit, and buildings.

**Values the check used:** the car code as it is on this branch, before T-029: the Unity values (cruise 11, top speed 2.5 x cruise = 27.5 units/s, turn 191.9 deg/s, grip 0.98 per step, 50 steps/s). I also ran it with `--set=top_speed_multiplier=3.0` (the T-029 value): the same three passes (1 3.26 s, 2 3.48 s, figure-eight 5.58 s). Physics interpolation does not affect the check (it changes only how the drawing is smoothed between steps).

**Results, on the board's sketches** (T-019 is still open, so there are no fitted versions yet; the sketches were not changed):

| Challenge | Drivable | Quickest drive | Driver | With W held the whole way |
|---|---|---|---|---|
| Single Boulder, arrow 1 | yes | 3.40 s, average 8.3, top 12.2 units/s | path follower (target speed 9) | did not pass |
| Single Boulder, arrow 2 | yes | 2.18 s, average 13.3, top 22.8 units/s | search | did not pass |
| Two Boulders, arrow 1 | yes | 7.28 s, average 7.8, top 23.5 units/s | search | did not pass |

Pictures: `docs/level-design/single-boulder/arrow-1.driven.svg`, `arrow-2.driven.svg`, `docs/level-design/two-boulders/arrow-1.driven.svg` (data in the `.driven.json` next to each). Command: `bash game/tools/check_challenge.sh --save docs/level-design` (about 15 s).

**Observations for the board and the Level/Challenge Design Agent** (facts, not proposals):

- No drive passed with W held the whole way: at cruise speed (11 units/s) the car slides too far for these loops. Every passing drive coasts and taps W, or brakes. Tapping W snaps the car to cruise speed along its nose, which gives the driven lines their sharp corners.
- Because the drawn car only has to touch the corridor and is 3 units long, its centre can be about 3 units from the arrow's centre line. The quickest drives use this: on Single Boulder arrow 2 the car cuts inside the loop close to the boulder, and the drawn car's picture sometimes overlaps a boulder (only the 1 x 1 body collides).
- The figure-eight is the hardest: none of the 120 path-follower settings passed; only the search found a drive.

**Documents affected:** `docs/level-design.md` (Content: new "Drivability check" subsection with one "drivable: yes" line per challenge; References: the check and the three pictures; Summary, Decisions and Open questions unchanged), `game/README.md` (new section "Challenge drivability check"). The long GDD is now stale for `level-design.md`; regenerating it is the Project Lead's job.

**Tests run before handing over:** full GUT suite `bash game/tools/run_tests.sh`: 64 tests, TESTS PASSED. Python tool tests: `python -m unittest discover -s game/tools -p "test_*.py"` (45, OK) and `python -m unittest discover -s tools -p "test_*.py"` (70, OK).

Note for QA: running Godot touches the line endings of some `.import` files (no content change); they are not part of this task.

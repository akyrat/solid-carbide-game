---
id: T-021
title: Challenge drivability check and driven-line tool
status: done
from: project-lead
to: driving-drift
lead:
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/level-design.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/level-design/, game/README.md, .claude/agents/driving-drift.md, .claude/agents/level-challenge.md]
files_expected_to_change: [the drivability script and its tests, result files for the 3 MVP challenges under docs/level-design/, docs/level-design.md, game/README.md]
model: opus
qa_rounds: 1
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

- [x] The script runs on any challenge drawing in `docs/level-design/` and prints pass or fail; a fail names where along the arrow and why (QA: pass)
- [x] It drives the car with the T-012 car's movement code and driving values, not a separate copy of the rules, shown by reading the script (QA: pass)
- [x] Tests show it passes a wide gentle curve, fails an impossibly tight one, and gives the same result on every run (QA: pass)
- [x] All 3 MVP challenges were checked; each passing one has a driven-line picture next to its drawing, and the result notes give pass or fail for each (QA: pass)
- [x] The board's drawings (`docs/level-design/*/arrow-*.json` and `.svg`) are unchanged (QA: pass)
- [x] `game/README.md` explains how to run the script; `docs/level-design.md` links the pictures and still follows the five-section structure, with Summary, Decisions and Open questions unchanged (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

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

### QA round 1

**QA/Integration Agent, 2026-10-09.** Checked from scratch in `C:\solid-carbide-worktrees\T-021`. All 7 criteria pass.

- **Runs on any drawing, pass or fail with where and why:** `bash game/tools/check_challenge.sh --save docs/level-design` (15 s, exit 0) printed PASS for all 3 drawings with the same times as the result notes (3.40 s, 2.18 s, 7.28 s). On my own drawings outside the repo: a U-turn round a boulder with a 0.6-unit gap gave exit 1 and `FAIL ... the drawn car left the corridor at 9.4 of 19.9 units along the arrow, near drawing point 4 of 7 (x 1.6, y 0.0), on a drawn curve of radius 1.1 units`; `--attempts=<folder>` wrote its furthest-attempt picture there; a file that is not JSON gave exit 2 with a clear message.
- **Uses the game's car code:** `tools/challenge_checker.gd` preloads `res://scripts/driving/car_model.gd` and moves the car only through `car.step(w, s, steer)` (A = +1, D = -1, the same mapping as `car.gd`); the handling values come from the model's own `car_tuning.gd` instance, and `--set` only overrides fields on it. The checker has no movement, grip or speed rules of its own: it reads the tuning values only to decide which keys to press, and copies the car's state (including `_w_was_held`) when the search branches. `git diff master...HEAD -- game/scripts/driving/` is empty. A test also checks the car's script is `car_model.gd`.
- **Tests:** `test_challenge_checker.gd`, 10/10: a quarter circle of radius 14 passes; the 0.6-unit-gap U-turn fails at drawing point 2 to 5; both give the same verdict, steps, settings and driven line point for point on two runs. My own determinism check: re-running `--save` rewrote all six `.driven.json` / `.driven.svg` files byte-identical (`git status` showed no change).
- **3 MVP challenges and pictures:** all 3 pass; each has `arrow-N.driven.json` and `.driven.svg` next to its drawing; the result notes give the verdict for each. I checked the saved lines with my own script (not the checker's code): every line starts on the arrow's first point; the 1 x 1 body never touches a boulder (closest 0.035, 0.154 and 0.200 units); the drawn 1 x 3 car stays within 0.30, 0.98 and 0.63 units of the arrow's straight-segment path (corridor half-width 1.5); the heading never changes more than 3.84 degrees per step (191.9 deg/s x 0.02 s); distance per step matches the recorded speed within 0.006; and each line goes round each boulder the same way and about as far as the drawing says (399 vs 389 clockwise; 416 vs 431 counter-clockwise; 412 vs 422 clockwise and 336 vs 332 counter-clockwise). I rendered the three pictures and looked at them: boulders, corridor, dashed arrow, cyan driven line and the drawn car every half second are all there. With `--set=top_speed_multiplier=3.0` all 3 still pass (3.26, 3.48, 5.58 s), as `docs/level-design.md` says.
- **Drawings unchanged:** `git diff master...HEAD` lists no `arrow-*.json` or `arrow-*.svg` (only new `.driven.*` files), and the working tree has no change under `docs/`.
- **Documents:** `game/README.md` has "Challenge drivability check" (commands for bash and PowerShell, output, options, exit codes, what it checks). `docs/level-design.md` keeps the five sections in order; the diff touches only Content (new "Drivability check" with one "drivable: yes" line per challenge) and References (links to the three pictures). The long GDD is stale for `level-design.md`, which is expected (Project Lead regenerates it).
- **Full suites:** `bash game/tools/run_tests.sh`: 8 scripts, 64/64, TESTS PASSED. `python -m unittest discover -s game/tools -p "test_*.py"`: 45 OK. `python -m unittest discover -s tools -p "test_*.py"`: 70 OK.

**Observations for the Project Lead** (not fails):
- A drive passes when the car's centre reaches the end of the arrow measured along it (it crosses the line through the last point, square to the arrow), not when it is on the last point: the saved lines end 0.9, 2.2 and 1.1 units from it. `game/README.md` says "reaches the arrow's last point", which reads stricter than the code. Consistent with the board's "only has to touch" rule.
- Because the drawn car only has to touch the corridor, the driven lines' centres often run outside the drawn corridor in the pictures and cut across loops (most visible on Two Boulders, where the line crosses between the two loops, and Single Boulder arrow 2). The agent's notes say so; worth the board's attention in its review.
- The check can only fail a drawing because of boulders or buildings: a 0.5-unit hairpin with no boulders passed (the car slows and turns on the spot, turn rate does not depend on speed). So "too tight at any speed" in practice means "too tight for the gap between obstacles".
- Godot's `.import` line-ending changes were already in the working tree and were left uncommitted.

### Board review

Approved by the board on 2026-10-10 on QA's pass. The check ran on the board's sketches; the map's fitted versions (T-019) still need it.

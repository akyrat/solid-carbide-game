---
id: T-021
title: Challenge drivability check and driven-line tool
status: blocked
from: project-lead
to: driving-drift
epic: level-challenges
milestone: mvp
depends_on: [T-012]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/level-design.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, docs/level-design/, game/README.md, .claude/agents/driving-drift.md, .claude/agents/level-challenge.md]
files_expected_to_change: [the drivability script and its tests, result files for the 3 MVP challenges under docs/level-design/, docs/level-design.md, game/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-012 is done:** the check must use the real Godot car, not a copy of its rules.

The Driving & Drift Agent provides the script that checks a challenge design can be driven (its role), and the Level/Challenge Design Agent runs it before handing a challenge over. The board decided each challenge's arrow is a corridor 3 units wide, and the drawn car (1 by 3 units) only has to touch it; the boulders are 3 units across and the car's physics body is 1 by 1 (Level design and Drifting, Decisions). The board drew the 3 MVP challenges in `docs/level-design/` (one `.json` per arrow, with its boulders and arrow points).

1. **Drivability check:** a script that takes one challenge drawing (`.json`) and decides whether the car, with the game's driving values, can drive it: keep the drawn car touching the corridor from the start of the arrow to its end, in the arrow's direction, without hitting a boulder. Drive it with the T-012 car's own movement code, steering automatically (for example, a simple path-following controller that chooses W, S, A and D each physics step). Report pass or fail, and on a fail, where along the arrow it fails and why (for example, "the turn at point 7 is too tight at any speed").
2. **Driven-line tool:** for a passing challenge, save the line the car actually drove, and a picture with the boulders, the corridor and that line, next to the drawing (for example `arrow-1.driven.svg`), so the board and the Level/Challenge Design Agent can see how it plays.
3. Run both on the 3 MVP challenges and record the results. **Do not change the board's drawings.** If one fails, say so in the result notes; the Project Lead brings it to the board.
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

## Result notes

Written by the agent when it finishes.

---
id: T-081
title: The combo: tricks raise a multiplier on likes; collisions cut it; it drains
status: blocked
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-037, T-079, T-080, T-033]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, docs/hud-and-menus.md, tasks/T-036-run-scene-and-state.md, tasks/T-037-likes-and-levels.md, tasks/T-079-trick-detection.md, tasks/T-080-combo-data.md, tasks/T-033-car-collisions-and-knockback.md, game/README.md]
files_expected_to_change: [the run's code, tests, docs/game-loop-architecture.md, game/README.md]
model: opus
qa_rounds: 0
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

**Blocked until T-037 (likes), T-079 (tricks), T-080 (the numbers) and T-033 (car collisions) are done.**

Add the combo to the run, as Game loop architecture, Decisions describes it, with T-080's numbers:
1. Each trick signal (T-079) adds its value to the combo multiplier. Send a signal with the trick, the amount added and the new multiplier; the popups (T-083) use it.
2. The multiplier multiplies all likes gained (challenges and drifting seconds, T-037).
3. **Collisions:** colliding with anything cuts the combo by 80%. Walls, buildings and boulders come from T-033's collision signal. Enemies and meteors damage the car, so any damage to the car (the run's health, T-036) also counts as a collision.
4. **Drain:** if no trick follows within 2 seconds, the combo drains as the data says.
5. The current multiplier is readable at any time, with a change signal, for the HUD and for enemy spawning (T-085). It resets with every new run and stops while the run is paused.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test sends trick signals and shows the multiplier rises by the data's amounts, and the signal carries the trick, the amount and the new multiplier (QA: pass / fail)
- [ ] A test shows a challenge's likes and a drift second's likes are multiplied by the current multiplier (QA: pass / fail)
- [ ] A test sends T-033's collision signal and, separately, damages the car, and shows each cuts the combo by 80% as the data defines it (QA: pass / fail)
- [ ] A test waits 2 seconds after a trick and shows the combo starts to drain, and a trick before 2 seconds stops it from draining (QA: pass / fail)
- [ ] A test shows the combo resets at a new run and doesn't change while paused (QA: pass / fail)
- [ ] `game/README.md` documents the combo's signals, and `docs/game-loop-architecture.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

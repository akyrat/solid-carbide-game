---
id: T-046
title: The kaiju's meteor attack: warning circles, impacts and new boulders
status: blocked
from: project-lead
to: enemy-behavior
lead:
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-045, T-039, T-097]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-045-kaiju.md, tasks/T-097-mvp-map-without-challenges.md, tasks/T-039-enemy-data.md, game/README.md]
files_expected_to_change: [the enemy code and scenes, tests, docs/enemies.md, game/README.md]
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

**Blocked until T-045 (the kaiju), T-039 (the numbers) and T-097 (meteor boulders on the map) are done.**

Build the kaiju's one special move, as Enemies, Decisions describes it:
1. After a short animation (a placeholder pause or flash is enough), several meteors rain down at once, as often and as many as the data says.
2. **Warning:** before they land, a red warning circle shows on the ground where each will land, for 2 seconds. Meteors land near the car, only where T-097's placement check accepts a boulder.
3. **Impact:** a meteor landing on the car damages it and knocks it back (the run's damage function, T-033's knockback).
4. **New boulders:** each landed meteor leaves a plain boulder where it landed, through T-097's function. No challenge or arrow (challenges are left out of the MVP, Level design, Decisions).
5. Meteors and warnings stop when the run is paused.

The warning circle, meteors and dust burst are placeholders for now. Visual style describes the final look, and separate art tasks make it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test triggers an attack and shows warning circles appear for 2 seconds before the meteors land where they showed (QA: pass / fail)
- [ ] A test shows a meteor landing on the car damages it and knocks it back, and one landing elsewhere doesn't (QA: pass / fail)
- [ ] A test shows each landed meteor leaves a boulder through T-097's function, only at spots its placement check accepts, and the car bounces off it (QA: pass / fail)
- [ ] A test shows meteors and warnings stop while the run is paused (QA: pass / fail)
- [ ] A screenshot shows warning circles and boulders left by meteors (QA: pass / fail)
- [ ] `docs/enemies.md` describes the built attack in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.

---
id: T-046
title: The kaiju's meteor attack: warning circles, impacts and new challenges
status: blocked
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-045, T-035, T-039]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-045-kaiju.md, tasks/T-035-runtime-meteor-challenges.md, tasks/T-039-enemy-data.md, game/README.md]
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

**Blocked until T-045 (the kaiju), T-035 (challenges created during a run) and T-039 (the numbers) are done.**

Build the kaiju's one special move, as Enemies, Decisions describes it:
1. After a short animation (a placeholder pause or flash is enough), several meteors rain down at once, at the data's frequency.
2. **Warning:** before they land, a red warning circle shows on the ground where each will land, for 2 seconds.
3. **Impact:** a meteor landing on the car damages it and knocks it back (the run's damage function, T-033's knockback).
4. **New challenge:** the landed meteors become obstacles laid out as one of the challenge designs, through T-035's create function, at a spot T-035's placement check accepts and near enough to the car to reach. Its green arrow appears once they've landed. Never open more meteor challenges at once than the data allows.
5. Meteors and warnings stop when the run is paused.

The warning circle, meteors and dust burst are placeholders for now. Visual style describes the final look, and separate art tasks make it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test triggers an attack and shows warning circles appear for 2 seconds before the meteors land where they showed (QA: pass / fail)
- [ ] A test shows a meteor landing on the car damages it and knocks it back, and one landing elsewhere doesn't (QA: pass / fail)
- [ ] A test shows each attack creates a challenge through T-035, at a spot the placement check accepts (QA: pass / fail)
- [ ] A test shows the number of open meteor challenges never goes above the data's limit (QA: pass / fail)
- [ ] A screenshot shows warning circles and a meteor challenge with its green arrow (QA: pass / fail)
- [ ] `docs/enemies.md` describes the built attack in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

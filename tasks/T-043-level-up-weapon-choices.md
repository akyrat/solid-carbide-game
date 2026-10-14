---
id: T-043
title: Level-up offers: the 2 choices, and applying the one taken
status: blocked
from: project-lead
to: weapon-behavior
lead:
epic: weapons
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-037, T-041, T-042]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/game-loop-architecture.md, tasks/T-037-likes-and-levels.md, tasks/T-041-starting-gun.md, tasks/T-042-exhaust-flamethrower.md, game/README.md]
files_expected_to_change: [the weapon code, tests, docs/weapons.md, game/README.md]
model: sonnet
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

**Blocked until T-037 (levels), T-041 (the gun) and T-042 (the flamethrower) are done.**

Weapons, Decisions describes the MVP level-up flow: each level-up offers 2 choices and the player takes 1. The first offer is "get the flamethrower" or "upgrade the gun"; after that, "upgrade the gun" or "upgrade the flamethrower".

Build the logic:
1. On T-037's "level up" signal, work out the 2 choices for the current state and make them available to the level-up screen (a later UI task). Each choice has an id, so the screen can show its text.
2. A function the screen calls with the chosen id. It applies the choice (gives the flamethrower, or the weapon's next upgrade tier), then calls T-037's "choice made" function so the run resumes.
3. A weapon at its last tier isn't offered. If nothing can be offered, skip the choice and resume the run; the docs don't cover this case, so say what you did in the result notes.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test shows the first level-up offers exactly "get the flamethrower" and "upgrade the gun" (QA: pass / fail)
- [ ] A test takes the flamethrower and shows later level-ups offer "upgrade the gun" and "upgrade the flamethrower" (QA: pass / fail)
- [ ] A test takes each choice and shows it is applied and the run resumes (QA: pass / fail)
- [ ] A test shows a weapon at its last tier is not offered (QA: pass / fail)
- [ ] `game/README.md` documents the choice ids and functions for the UI Agent, and `docs/weapons.md` describes the flow in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

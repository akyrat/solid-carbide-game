---
id: T-067
title: The challenge arrow draws itself, pulses while open, and fades when completed
status: blocked
from: project-lead
to: level-challenge
epic: level-challenges
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: [T-066]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-066-challenge-arrow-art.md, game/README.md]
files_expected_to_change: [the challenge code, tests, docs/level-design.md, game/README.md]
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

**Moved after the MVP (2026-10-11): challenges are left out of the MVP (Level design, Decisions). Not to be started unless the board brings challenges back.**

**Blocked until T-066 (the arrow art) is done.**

Level design and Visual style, Decisions describe the arrow's animation: it draws itself along the path when the challenge appears, pulses while the challenge is open, and fades when it is completed. Build that with T-066's art, for both the blue and the green arrows. The game fades the whole object; the sprites have no semi-transparent pixels.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test shows a new challenge's arrow starts undrawn and is fully drawn after the animation (QA: pass / fail)
- [ ] A test shows the arrow pulses while open and fades out when the challenge is completed (QA: pass / fail)
- [ ] A screenshot sequence (start, open, completed) shows the three stages (QA: pass / fail)
- [ ] `docs/level-design.md` describes the animation in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

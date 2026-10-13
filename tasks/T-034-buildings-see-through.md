---
id: T-034
title: Buildings turn see-through when the car is behind them
status: in-progress
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019, T-020]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-020-see-through-buildings-research.md, tasks/T-019-build-mvp-map.md, game/README.md]
files_expected_to_change: [the map's building code or scene, their tests, docs/level-design.md, game/README.md]
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

**Blocked until T-019 (the MVP map) and T-020 (the research on how to do this) are done.**

In the isometric view, a tall building can hide the car. Visual style, Decisions says a building the car drives behind turns see-through. The game fades the whole object, so no sprite needs semi-transparent pixels.

Build it on the MVP map, following the approach T-020 recommends and the values the board chose (Visual style, Decisions: fade to 15% visible over 0.15 seconds, car only):
- When the car is behind a building (hidden by it on screen), that building fades.
- When the car comes out, the building fades back.
- Only the buildings actually covering the car fade, not the whole city.

The buildings are still T-019's flat placeholders. The final building art comes from a separate art task and must work with the same fade.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test places the car behind a building (covered by it on screen) and shows that building becomes see-through, while a building not covering the car stays fully opaque (QA: pass / fail)
- [ ] A test moves the car out from behind the building and shows it becomes fully opaque again (QA: pass / fail)
- [ ] Two screenshots, the car behind a building and the car in the open, show the fade (QA: pass / fail)
- [ ] The fade changes only the building's whole-object transparency: no sprite file was changed (QA: pass / fail)
- [ ] `docs/level-design.md` describes the see-through behaviour in Content without changing Summary, Decisions or Open questions, and `game/README.md` says how it works for whoever adds the final building art (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: drive behind buildings and judge whether the fade reads well.

## Result notes

Written by the agent when it finishes.

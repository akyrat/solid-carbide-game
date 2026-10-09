---
id: T-052
title: The level-up (gift pack) screen: 2 cards, take one
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-043, T-051]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, docs/weapons.md, tasks/T-043-level-up-weapon-choices.md, tasks/T-051-text-level-up-screen.md, game/README.md]
files_expected_to_change: [the level-up screen scene and script, tests, docs/hud-and-menus.md, game/README.md]
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

**Blocked until T-043 (the choices) and T-051 (their text) are done.**

When the player levels up, the run pauses (T-037) and this screen shows the 2 choices T-043 offers, as plain cards: each with a title, a description and a button to take it (HUD and menus, Decisions). Taking one calls T-043's function, which applies it and resumes the run. Use exactly T-051's text.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test fires a level-up and shows the screen opens with 2 cards whose titles and descriptions are T-051's text for T-043's offered choice ids (QA: pass / fail)
- [ ] A test presses a card's button and shows T-043's function is called with that choice id and the screen closes (QA: pass / fail)
- [ ] A screenshot shows the level-up screen over the paused run (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes the screen in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

---
id: T-089
title: Screen flow: wire the Garage button to the garage screen
status: blocked
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-055, T-058]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, tasks/T-055-screen-flow.md, tasks/T-058-garage-screen.md, game/README.md]
files_expected_to_change: [the scene flow code, tests, game/README.md]
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

**Blocked until T-055 (the screen flow) and T-058 (the garage screen) are done.**

T-055 left the main menu's Garage button unwired (board, 2026-10-10). Wire it: **Garage** opens the garage screen, and its back button returns to the main menu (Game loop architecture, Decisions).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test presses Garage and shows the garage screen opens (QA: pass / fail)
- [ ] A test presses the garage's back button and shows the main menu again (QA: pass / fail)
- [ ] `docs/game-loop-architecture.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

---
id: T-089
title: Screen flow: wire the Garage button to the garage screen
status: in-progress
from: project-lead
to: game-loop
lead: Playtest
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-055]
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

**Built on T-058's branch (board, 2026-10-15).** T-058 (the garage screen) waits for the board's playtest, and the board can only reach it from the main menu once it is wired. So branch `task/T-089-wire-garage-button` from `task/T-058-garage-screen` (not from master), in your own folder `C:\solid-carbide-worktrees\T-089`, merge master into it, and the board playtests the garage and its button together there. T-058 merges first, then this.

T-055 left the main menu's Garage button unwired (board, 2026-10-10). Wire it: **Garage** opens the garage screen, and its back button returns to the main menu (Game loop architecture, Decisions).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test presses Garage and shows the garage screen opens (QA: pass / fail)
- [ ] A test presses the garage's back button and shows the main menu again (QA: pass / fail)
- [ ] `docs/game-loop-architecture.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it, with T-058's garage screen, before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-15, Open → In progress

Started: the Game Loop Agent wires the Garage button on top of T-058's garage screen, so you can playtest both together.

## Result notes

Written by the agent when it finishes.

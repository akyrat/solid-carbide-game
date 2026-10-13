---
id: T-058
title: The garage screen: plain list of upgrades with buy buttons
status: blocked
from: project-lead
to: ui
epic: garage
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-057, T-059]
documents_affected: [docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-057-save-and-buy.md, tasks/T-059-text-garage.md, game/README.md]
files_expected_to_change: [the garage screen scene and script, tests, docs/garage-design.md, game/README.md]
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

**Blocked until T-057 (saving and buying) and T-059 (the text) are done.**

Build the MVP garage screen as Garage design, Decisions describes it, kept plain: a list of the three upgrades, each with its current level, the price of the next level and a button to buy it, plus the player's coins and a way back to the main menu (the back button sends a signal; T-055 connects it). Buying calls T-057's function; the screen shows the result, including "maxed" and "can't afford". Use exactly T-059's text.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot shows the three upgrades with level, price and buy button, the coins, and the back button (QA: pass / fail)
- [ ] A test buys an upgrade and shows the level, price and coins on screen update (QA: pass / fail)
- [ ] A test shows a maxed upgrade and an unaffordable one show T-059's messages and can't be bought (QA: pass / fail)
- [ ] A test shows every label is exactly T-059's text (QA: pass / fail)
- [ ] `docs/garage-design.md` describes the screen in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the agent when it finishes.

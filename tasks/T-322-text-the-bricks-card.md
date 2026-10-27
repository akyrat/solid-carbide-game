---
id: T-322
title: "Text: the Bricks weapon's card"
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/weapons.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/scripts/ui/level_up_texts.gd]
files_expected_to_change: [game/data/, docs/weapons.md, docs/hud-and-menus.md, art-archive/T-322/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (Weapons, Decisions, "Bricks", 2026-10-28): a new weapon, **Bricks**. The car carries a load of bricks; every time it lands after being in the air, a powerful impact wave goes out around it. The card should make it sound useless, so the player is tempted to try a jump and find out. The board's direction for the description: "Bricks - A bunch of bricks. No real use, other than making the car heavier." with something that hints the player should try a jump.

Write the level-up card texts the other weapons have (the card title "Bricks" and its description, and the description of each upgrade tier T-323 proposes: get Bricks, and each upgrade; if T-323's tiers aren't in yet, write them for the same number of tiers as the windshield wiper and say so), in the existing cards' lengths and format (Text rules, rule 4; the other weapons' cards in the level-up texts data). Keep the board's line as close to word for word as the rules allow, and keep the jump hint subtle. Every line goes through the style loop. Put the texts where the level-up screen reads the other weapons' texts, and list them in Weapons, Content, under a new "Bricks" heading.

The board's review: read the Bricks card texts in Weapons, Content, "Bricks".

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The Bricks card title, its description and each tier's text are in the level-up texts data file, next to the other weapons'. (QA: pass / fail)
- [ ] The description keeps the board's line "A bunch of bricks. No real use, other than making the car heavier." (or says in the result notes which rule made a change necessary) and hints at a jump. (QA: pass / fail)
- [ ] Each line scored at least 8 in the style loop, with every round in the Style review, and fits the card's length rules. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

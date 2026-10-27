---
id: T-318
title: "Text: the recap screen"
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
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/extended-narrative.md, docs/weapons.md, docs/enemies.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md, art-archive/T-318/]
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

The board's decision (Game loop architecture, Decisions, "Recap screen in the MVP", 2026-10-28): after a run ends, the player sees a recap: the enemies slain, the tricks completed, the highest combo multiplier reached and the weapons used. T-320 builds the screen and waits for this text.

Write: the screen's title (one for a win and one for a loss, if that reads better), the four section headings (enemies slain, tricks completed, highest combo, weapons used), the name shown for each enemy type and each trick if the game has no player-facing name for it yet (reuse the existing names where they exist: the trick popups' names, the weapons' card titles), and the button that leaves the screen (to the main menu). Use the game's vocabulary (Text rules: "likes", "the kaiju", "Stunt Driver", "gift pack"). Every new line goes through the style loop. Put the approved text where T-320 will read it (say where) and in HUD and menus, Content, under a new "Recap screen" heading.

The board's review: read the recap screen's text in HUD and menus, Content.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every label the recap needs is in a data file the game reads, named in the result notes, and in HUD and menus, Content, "Recap screen". (QA: pass / fail)
- [ ] Each new line scored at least 8 in the style loop, with every round in the Style review; names reused from existing texts are listed as reused. (QA: pass / fail)
- [ ] The labels follow Text rules (vocabulary, no banned word, lengths). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

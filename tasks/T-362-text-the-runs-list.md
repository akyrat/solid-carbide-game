---
id: T-362
title: Text: the runs list and its main menu button
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md, tasks/T-318-text-the-recap-screen.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md, art-archive/]
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

The board's decision (Game loop architecture, Decisions, "The runs list", 2026-10-29): a new main menu button opens a list of the player's past runs, each with the stats from its recap screen, saved on this computer. The UI ticket (the runs list screen) waits for this text.

Write: the main menu button's label (it sits with Start, Garage and Exit, T-053), the screen's title, the column or row labels the list needs (a proposal: the date, win or loss, the time survived, the highest combo, the likes or enemies slain; reuse T-318's recap labels where they fit and list them as reused), the line shown when there are no runs yet, and the button or X that goes back to the main menu. Use the game's vocabulary (Text rules: "likes", "the kaiju", "Stunt Driver", the livestream). Every new line goes through the style loop. Put the approved text where the UI ticket will read it (say where) and in HUD and menus, Content, under a new "Runs list" heading.

The board's review: read the runs list text in HUD and menus, Content.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every label the runs list and its main menu button need is in a data file the game reads, named in the result notes, and in HUD and menus, Content, "Runs list". (QA: pass / fail)
- [ ] Each new line scored at least 8 in the style loop, with every round in the Style review; lines reused from T-318 or the main menu are listed as reused. (QA: pass / fail)
- [ ] The labels follow Text rules (vocabulary, no banned word, lengths). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

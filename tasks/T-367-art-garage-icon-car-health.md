---
id: T-367
title: Art: the car health upgrade's icon
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-365]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/garage-design.md, tasks/T-352-art-reaction-icons.md]
files_expected_to_change: [game/art/garage/, game/tools/, art-archive/, docs/visual-style.md, game/docs/art/]
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

The board's decision (Garage design, Decisions, "Pixel art icons for the upgrades", 2026-10-29). Draw a small pixel art icon for the **car health** upgrade (each level adds a heart), for example a heart with a plus, close to the HUD's heart (T-339) so the player links them (your call). 16 x 16 (a proposal), in the game's pixel rules and the HUD icons' bold comic outline (T-352's reaction icons, which the board loved), readable at 3x in the garage. The five garage icons are drawn as one set, so match the others if they exist already. None of Greenbull's colours outside Greenbull's things (Visual style, Content, "Rules", rule 6). Save it as `game/art/garage/car_health.png` with a record; the garage picks it up on its own (T-365).

**PixelLab: no go.** Draw it by script, as T-352 did. Style loop, at most 3 refines.

The board's review: open the garage and see the car health icon.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/garage/car_health.png` exists with a record, and the garage shows it on the car health row. (QA: pass / fail)
- [ ] It scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] No PixelLab generations were used (the result notes say so). (QA: pass / fail)
- [ ] Visual style and the art docs under game/docs/art/ record it. (QA: pass / fail)
- [ ] The icon enlarged on a dark and a light background, and a screenshot of the garage, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

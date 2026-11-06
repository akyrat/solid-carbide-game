---
id: T-549
title: A ramp may climb onto several rooftops of the same height
status: open
from: project-lead
to: level-challenge
lead: Rails
epic: level-challenges
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/game-map.md, game/tools/check_height_data.py, game/scripts/level_creator/level_document.gd, game/scripts/level_creator/snapping.gd, game/scripts/level/ground_height.gd]
files_expected_to_change: [game/tools/check_height_data.py, game/tools/check_level.py, game/tools/test_check_height_data.py, game/scripts/level_creator/, game/scripts/level/, game/tests/, game/docs/level/, docs/level-design.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build Level design, Decisions, "A ramp may climb onto several rooftops" (board, 2026-11-06). The board's Kaiju City (C:\solid-carbide-game\game\data\levels\kaiju_city.json in the main checkout, untracked: read it there, never change it) fails check_level.py and check_height_data.py: "ramp 'ramp-2': climbs to unknown area ''" and the same for ramp-13. Both climb from 3 to 6 and their top end meets two rooftops at height 6 side by side (ramp-2: roof-6 and roof-7; ramp-13: roof-3 and roof-6), so the creator's relink (level_document.gd ramp_target) left "platform" empty. Make such a ramp valid everywhere, without changing the board's file: (1) the checks accept a non-jump ramp whose top touches, along its side, one or more areas all at its top_height, when "platform" is empty or names one of them, and still reject a ramp whose top meets nothing at that height; (2) the game (ground_height.gd, elevation_layer.gd and anything else reading a ramp's "platform") lets the car drive up such a ramp onto either rooftop, as on a ramp with one; (3) the creator handles it the same way (its relink and snapping don't break on it, and what it saves stays loadable). Choose the smallest design that keeps every existing level and test valid, and say it in game/docs/level/game-map.md. Write tests for each part, including a test that loads the board's Kaiju City from that path (skipped if the file is absent) and passes the checks.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels; reading is fine where the ticket says so). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] check_level.py and check_height_data.py pass on the board's game/data/levels/kaiju_city.json unchanged (output in the result notes), and still reject a non-jump ramp whose top meets no area at its top_height (test). (QA: pass / fail)
- [ ] In the game, the car drives up a ramp whose top meets two rooftops of the same height and ends on the rooftop it drives onto, either one (test). (QA: pass / fail)
- [ ] The level creator loads, relinks and saves a level with such a ramp without errors, and the saved level still passes the checks (test). (QA: pass / fail)
- [ ] Every existing level and test still passes: the agent's tests for the changed code, and QA's full run of the three test sets, with the counts in the result notes. (QA: pass / fail)
- [ ] game/docs/level/game-map.md and docs/level-design.md Content describe the rule. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

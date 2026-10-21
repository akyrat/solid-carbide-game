---
id: T-239
title: Level creator: play a listed level as a full run, and come back to the creator
status: blocked
from: project-lead
to: game-loop
lead: Goal-G-005
epic: game-loop
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-230, T-234, T-238]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/scripts/run/run.gd, game/scripts/game/game_flow.gd, game/scripts/level_creator/level_creator.gd, game/scripts/level_creator/level_list_screen.gd, game/scripts/enemies/enemy_navigation.gd]
files_expected_to_change: [game/scripts/level_creator/level_creator.gd, game/tests/unit/level_creator/test_play_level.gd, game/README.md]
model: opus
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

Custom levels are played only from the creator, as a full run: the same 8 minutes, enemies and kaiju as the game (Level design, Decisions, 'Level creator', board 2026-10-21). Pressing play on a listed level (the play label from creator_texts.json) starts a run on that level's file, using the run's layout path (the 'run can play any map file' ticket), with the pause screen, weapons and the garage upgrades as the game's own run sets them up (see game_flow.gd's start_run). The game's own flow and its map stay unchanged. When the run ends, win or loss, the creator shows its level list again (the docs don't say; this is a proposal for the board, written in the result notes). Tests use a level saved into a temporary levels folder that has at least one ramp. Add playing to game/README.md, 'Level creator'. Screenshot of a run on a custom level in art-archive/<this task's id>/screenshots/.

The board's review: In the level creator, press play on a level you made and play the run to its end.

## Acceptance criteria

- [ ] A unit test presses play on a listed level: a run starts on that file (the run's layout path is the level's path), the timer reads 8:00 and minions spawn; fast-forwarding the run state to the kaiju's time makes the kaiju appear; the run's map holds the level's buildings, platforms and ramps. (QA: pass / fail)
- [ ] A unit test on that custom level: enemy navigation built for the run's map returns a path from the street to a rooftop that passes over its ramp. (QA: pass / fail)
- [ ] A unit test: when the run ends (win and loss), the creator's level list is shown again. (QA: pass / fail)
- [ ] A run started from the game's main menu still uses res://data/level/elevation_sample_map.json (test). (QA: pass / fail)
- [ ] The test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', says how to play a level and where the run returns. (QA: pass / fail)
- [ ] A screenshot of a run on a custom level is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

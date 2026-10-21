---
id: T-240
title: QA: the level creator end to end, from an empty creator to playing a level
status: open
from: project-lead
to: qa-integration
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: no
changes_visuals: no
depends_on: [T-230, T-231, T-232, T-234, T-235, T-236, T-237, T-238, T-239]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/data/level/creator_assets.json, game/data/level/creator_texts.json, game/scripts/level/level_store.gd, game/scripts/level_creator/level_creator.gd, game/scripts/level_creator/editor.gd, game/scripts/run/run.gd]
files_expected_to_change: [game/tests/unit/level_creator/test_creator_end_to_end.gd]
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

The final check of the level creator goal, on the goal's build (playtest/G-005), before the board plays it: it must be possible to create a level from nothing, save it, see it in the list, and play it (Level design, Decisions, 'Level creator', board 2026-10-21). Write one scripted GUT test, using a temporary levels folder, that starts the creator with no levels, presses new level, places at least one asset of every kind (ground tile, road, building, boulder, rooftop at 3 and at 6, ramp 0 to 3 and 3 to 6), uses rotate and mirror on at least one piece and deletes one, names and saves the level, goes back to the list and finds it, and presses play: the run starts on that file with the timer at 8:00 and minions spawning. Then run every test set and check the game's main menu run still uses elevation_sample_map.json, and that game/README.md, 'Level creator', is complete. Report anything missing in the result notes.

## Acceptance criteria

- [ ] The end-to-end GUT test passes on playtest/G-005: from an empty creator it places every kind of asset, uses rotate, mirror and delete, saves, finds the level in the list and starts a run on it with the timer at 8:00 and minions spawning. (QA: pass / fail)
- [ ] The saved level from that test passes python game/tools/check_level.py. (QA: pass / fail)
- [ ] The full GUT suite, the Python tool tests and the tools/ tests all pass. (QA: pass / fail)
- [ ] A test confirms a run started from the game's main menu uses res://data/level/elevation_sample_map.json. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', explains how to open the creator, where levels are saved, and every control (place, delete, rotate, mirror, heights, snapping, save, play). (QA: pass / fail)
- [ ] The result notes say in one line that there is nothing new to screenshot (the earlier creator tickets hold the screenshots). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

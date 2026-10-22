---
id: T-260
title: The task board's Builds tab gets a "Play creator" button
status: open
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/test_taskboard_server.py, game/tools/level_creator.ps1]
files_expected_to_change: [tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/test_taskboard_server.py, docs/README.md]
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

The board's request (2026-10-22): starting the level creator needs a PowerShell command today (`game/tools/level_creator.ps1`), since it is a separate app with its own main scene, `scenes/level_creator/level_creator.tscn`, and the Builds tab's Play button starts the game. Add a third button, **Play creator**, to every Builds entry (and to a goal's build in its detail, where Play is shown) whose folder has `game/scenes/level_creator/level_creator.tscn`; it starts Godot on that scene the same way Play does (`"$GODOT_BIN" --path <folder>\game res://scenes/level_creator/level_creator.tscn`, no console window). It is disabled, like Play, for a folder without the scene. The server keeps starting only folders from its own worktree list and only this one fixed scene (no scene path from the page). The button's label is a tool label on the board's own page, like Play and Open in editor (not game text).

This is the task board's tooling, which the player never meets. Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture beyond a screenshot of the Builds tab with the new button, if one can be made.

## Acceptance criteria

- [ ] Tests show `/api/builds` reports for each folder whether it has the creator scene, and `/api/launch` with the creator option starts Godot on `res://scenes/level_creator/level_creator.tscn` for a listed folder, refuses folders outside the worktree list and takes no scene path from the request (QA: pass / fail)
- [ ] The Builds tab (and a goal build's detail) shows Play creator next to Play, disabled where the scene is missing (code review, and a screenshot if one can be made) (QA: pass / fail)
- [ ] `docs/README.md`, "The task board", describes the button; all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

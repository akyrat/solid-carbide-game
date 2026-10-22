---
id: T-260
title: The task board's Builds tab gets a "Play creator" button
status: in-qa
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

- [ ] Tests show `/api/builds` reports for each folder whether it has the creator scene, and `/api/launch` with the creator option starts Godot on `res://scenes/level_creator/level_creator.tscn` for a listed folder, refuses folders outside the worktree list and takes no scene path from the request (QA: pass; has_creator tests, creator launch args, 409 without scene, extra request fields ignored and 404/400 outside the list are covered and pass)
- [ ] The Builds tab (and a goal build's detail) shows Play creator next to Play, disabled where the scene is missing (code review, and a screenshot if one can be made) (QA: pass; by code review, creatorButton(b) renders Play creator in both the Builds entries and the goal build detail, disabled with a tooltip when has_creator is false; no screenshot)
- [ ] `docs/README.md`, "The task board", describes the button; all Python tool tests pass (QA: pass; docs/README.md describes the button; tools 451 OK, game/tools 395 OK, 1 skipped)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: a Play creator button on the Builds tab.

### 2026-10-22, In progress → In QA

Built: a Play creator button on each Builds entry that has the level creator. Sent to QA.

## Result notes

Written by the agent when it finishes.

### 2026-10-22, Project Lead's tooling agent

- `tools/taskboard/server.py`: `CREATOR_SCENE` (`res://scenes/level_creator/level_creator.tscn`) is a fixed constant. Each `/api/builds` entry gains `has_creator` (true only when the folder has both `game/project.godot` and `game/scenes/level_creator/level_creator.tscn`). `/api/launch` takes a third mode, `creator`, which starts `"$GODOT_BIN" --path <folder>\game res://scenes/level_creator/level_creator.tscn` through the same detached, no-console `start_detached` as Play. It refuses with 409 a folder without the scene, and with 404 any id outside the worktree list. The request's other fields (`scene`, `args`, `folder`) are never read.
- `tools/taskboard/taskboard.html`: a shared `creatorButton(b)` renders **Play creator** between Play and Open in editor, both on every Builds entry and in a goal build's detail. It is disabled, with a tooltip, where `has_creator` is false. The toast reads "Starting the level creator…". The existing click handlers already skip disabled buttons.
- `tools/test_taskboard_server.py`: five new tests. They cover `has_creator` per folder (a scene without project.godot counts as false), the creator launch arguments, refusals without the scene, extra scene/args/folder fields in the HTTP request being ignored, and HTTP refusals for ids outside the worktree list.
- `docs/README.md`, "The task board": describes the button.
- Tests: `python -m unittest discover -s tools -p "test_*.py"` passed 451 tests, OK. `python -m unittest discover -s game/tools -p "test_*.py"` passed 395 tests, OK (1 skipped).
- Screenshot: none. Making one would need a task board server serving this folder, and the instructions were not to touch the running server and to test with unit tests only. The creator scene exists today in the level-creator worktrees (T-234 to T-240, T-250 to T-257, G-005, creator-set) but not on master or in this folder, so on the live board those entries would show it enabled once this merges.

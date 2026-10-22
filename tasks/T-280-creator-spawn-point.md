---
id: T-280
title: "Level creator: a spawn point every level has, always visible and movable"
status: blocked
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-279]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/scripts/level_creator/, game/scripts/run/run.gd, game/tools/check_level.py, tasks/T-239-level-creator-play-a-listed-level.md, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/run/, game/tools/check_level.py, game/tests/, game/README.md, docs/level-design.md, art-archive/T-280/screenshots/]
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

The board's decision (Level design, Decisions, "The car's spawn point", 2026-10-22). Today a custom level's run starts the car at the map's centre. Give every level a **spawn point**:

- **Always there, always visible:** a marker on the map (drawn in code, clearly readable over any ground, for example a car silhouette or arrow with T-279's label; your proposal, never Redgull red) shows from the moment a level opens in the editor, above the pieces so it's never hidden. A new level puts it at the map's centre; a level saved before this ticket opens with it there too.
- **Movable:** drag it (or select it and click where it should go) anywhere the car can stand: on the street, a rooftop or a ramp, at that surface's height, snapped to the grid; never inside a building, an obstacle or off the map (refused with T-279's message, and the marker stays where it was). Turning it (R while selected) sets the car's starting heading (a proposal; four or eight headings).
- **Never deleted:** Delete on it shows T-279's message and keeps it; a level always has exactly one.
- **Saved and used:** saved in the level file; a run started from the creator starts the car there, at that height and heading. `check_level.py` refuses a level whose spawn point is missing or not where a car can stand. The game's own map is unchanged.

Built on T-262's branch once it passes QA (the Project Lead makes your folder), with T-279's labels. End with screenshots of a new level with its spawn point, the point moved onto a rooftop, and a short GIF of a run starting there.

## Acceptance criteria

- [ ] Tests show a new level and an old level open with a visible spawn point at the centre, it can be moved and turned, it can't be deleted, and it is refused inside a building, an obstacle or off the map (QA: pass / fail)
- [ ] Tests show the spawn point saves and reopens, and a run from the creator starts the car at its place, height and heading; `check_level.py` refuses a level without a valid one (QA: pass / fail)
- [ ] Labels from `creator_texts.json`; no Redgull red; the game's own map unchanged (QA: pass / fail)
- [ ] Screenshots and the GIF are in `art-archive/T-280/screenshots/`; `game/README.md` describes it; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: open a level, move the spawn point onto a rooftop, and play from there.
Board review files: the screenshots and GIF in `art-archive/T-280/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

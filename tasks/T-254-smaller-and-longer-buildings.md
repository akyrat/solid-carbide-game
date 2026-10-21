---
id: T-254
title: "Level creator: smaller and longer buildings"
status: blocked
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-250]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level/map_building.gd, game/scripts/level/building_towers.gd, game/scripts/level_creator/, game/tools/build_creator_assets.py]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/tools/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-254/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). Every building today is 12 x 12 units. Add two new footprints to the creator's Buildings: a **small square building** (6 x 6 units) and a **long building** (12 x 6 units, and 6 x 12 by rotating, R), both short buildings whose roofs show, at a height you propose (today's short buildings are 4.3). They are solid like today's buildings, see-through when the car is behind them (as today), and enemies path round them. Placeholder look first: a code-drawn box in the city's palette (cool blue-grey walls, pale lit windows; Visual style, Decisions, "City colours"), never Redgull red; T-257 generates the final art and swaps it in, so keep each footprint's textures per rotation and mirror in one data file. Names from T-250. The game's own map is unchanged.

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. End with a screenshot of both new buildings (both rotations of the long one) beside today's buildings in the creator.

## Acceptance criteria

- [ ] Tests show the small and long buildings (both rotations) can be placed, saved, reopened and pass `check_level.py`, collide with the car and are pathed round by enemies (QA: pass / fail)
- [ ] Their art per rotation lives in one data file; labels from `creator_texts.json`; no Redgull red; the game's own map unchanged (QA: pass / fail)
- [ ] The screenshot is in `art-archive/T-254/screenshots/`; `game/README.md` describes them; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place the new buildings and drive round them.
Board review files: the screenshot in `art-archive/T-254/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

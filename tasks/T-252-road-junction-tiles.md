---
id: T-252
title: "Level creator: road corners, T-junctions, crossroads and dead ends"
status: blocked
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-250]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/tools/build_ground_tiles.py, game/art/ground/ground_atlas.json, game/tools/build_creator_assets.py, game/data/level/creator_assets.json]
files_expected_to_change: [game/tools/, game/art/ground/, game/data/level/creator_assets.json, game/scripts/level/, game/scripts/level_creator/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-252/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). The creator has straight road tiles (plain, lane lines, zebra crossings, in both directions) but no way to turn or join roads. Add, drawn by script from the existing road tiles (`build_ground_tiles.py`; no PixelLab), the road pieces a street network needs, in every rotation: **corners** (4), **T-junctions** (4), a **crossroads**, and **dead ends** (4), at the same 2 x 2 unit tile size and in the ground atlas's style (asphalt, white lines, light cracks; Visual style, Decisions, "Ground"). Add them to the catalogue (rebuild `creator_assets.json`) under Roads, with their names from T-250, and make the existing ground tiles' x and y versions both show. The game's own map is unchanged.

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. End with a screenshot of a small street grid built in the creator using every new piece.

## Acceptance criteria

- [ ] The atlas and catalogue have corners, T-junctions and dead ends in 4 rotations and a crossroads; their lines join the straight tiles' lines without gaps (tests on the tile data, and the screenshot) (QA: pass / fail)
- [ ] The tiles pass `check_sprite_rules.py`; the game's own map's ground is unchanged (a test) (QA: pass / fail)
- [ ] The screenshot is in `art-archive/T-252/screenshots/`; `game/README.md` describes the pieces; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: lay out a street grid with corners and junctions.
Board review files: the screenshot in `art-archive/T-252/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

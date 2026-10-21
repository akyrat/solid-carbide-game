---
id: T-251
title: "Level creator: rooftops of any size, and ramps in every direction"
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level/elevation_layer.gd, game/scripts/level/elevation_platform_drawing.gd, game/tools/build_elevation_sample_art.py, game/tools/build_creator_assets.py, game/tools/check_height_data.py, game/scripts/level_creator/, tasks/T-198-art-rooftops-and-parking-garage-ramps.md]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/scenes/level_creator/, game/tools/, game/data/level/creator_assets.json, game/tests/, game/README.md, docs/level-design.md, art-archive/T-251/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). Today a rooftop or ramp in the creator is one fixed picture from the sample map (`art/elevation_sample/`), so there are only two rooftop sizes (84 x 30 at height 3, 30 x 30 at height 6) and two ramps. Make them free-sized so the board can build a multi-layer world:

1. **Rooftops of any size:** pick a rooftop (height 3 or 6), then drag on the map to size it (even units, at least 4 x 4, up to the map's size), with the size shown on the top bar (T-250's text). A height 6 can stand on a height 3 (`on`, as today) or straight on the ground. Snapping (T-237) and the overlap refusal still apply.
2. **Ramps in all four climb directions** (north, east, south, west) at 0 to 3 and 3 to 6, plus 0 to 6 if the height data allows it (your call; say so). Rotate (R) steps through the four directions. A ramp's width along the rooftop's side can be dragged too (at least 4 units); its length stays a fixed proposal per height step.
3. **Drawn in the engine, not as fixed pictures:** the new pieces are drawn from tileable textures projected onto each face (the top, and the east and south walls, which are the visible ones), the same projection `build_elevation_sample_art.py` uses (`screen x = (x-y)*32`, `screen y = (x+y)*16 - h*32`), nearest filtering, hard pixel edges, with a dark outline on the edges as the sample art has. For now use the T-198 textures in `art-archive/T-198/` (or the sample art's) as placeholders; T-255 swaps in new textures, so keep each texture (roof top, wall, ramp surface, ramp side, edge or parapet strip) a setting in one scene or resource. The fade and depth order (`silhouette`, `covers`) keep working.
4. **The game's own map is unchanged:** pieces with `art` (the sample map's) still draw as today; only pieces without it use the new drawing. Saved levels pass `python game/tools/check_level.py`, and enemies find their way up and down the new ramps (their pathfinding reads the same data).
5. **Catalogue:** `build_creator_assets.py` writes the resizable rooftop and ramp entries (rebuild `creator_assets.json`).

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. Every label comes from `creator_texts.json` (T-250). End with screenshots of a small multi-layer level built in the creator (rooftops of three sizes, a 6 on a 3, ramps in all four directions) and a short GIF of the car driving up and down it in a run.

## Acceptance criteria

- [ ] Tests show a rooftop can be placed at any even size from 4 x 4 up, at heights 3 and 6 (on a 3 and on the ground), and ramps in all four directions at 0 to 3 and 3 to 6, with the saved level passing `check_level.py` (QA: pass / fail)
- [ ] Tests show the game's own map and its pieces draw and play as before, and enemies path up a new ramp (QA: pass / fail)
- [ ] Textures are settings in one place; labels come from `creator_texts.json`; no Redgull red (QA: pass / fail)
- [ ] Screenshots and a GIF of the car driving the built level are in `art-archive/T-251/screenshots/`; `game/README.md` "Level creator" describes the new pieces; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: build a level with rooftops of several sizes and ramps in every direction, and drive it.
Board review files: the screenshots and GIF in `art-archive/T-251/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

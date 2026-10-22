---
id: T-264
title: "Level creator: closed ramps, arrows up or down, and S, M and L platforms"
status: blocked
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-261]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/scripts/level/elevation_platform_drawing.gd, game/scripts/level/elevation_layer.gd, game/scripts/level_creator/, game/tools/build_creator_textures_t255.py, tasks/T-251-resizable-rooftops-and-ramps.md, tasks/T-255-art-creator-textures.md, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/tools/, game/art/creator_pieces/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-264/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22), three fixes to T-251's pieces, all drawn in the engine (no PixelLab):

1. **Closed ramps:** every ramp (each direction, each height step) is a closed block: its tall end gets a wall down to what it stands on, in the ramp side's texture, even where it meets a rooftop or building. Today that end is open and the ramp looks hollow.
2. **Arrows up or down:** today the ramp arrows point up the slope on some directions and down it on others. Every ramp, in every direction and height step, can have its arrows pointing **up** or **down** the slope, the board's choice per ramp (key A, labels from T-261), saved with the ramp; the default is up. The arrows always match the choice.
3. **Platform sizes:** besides dragging any size, a platform at height 3 or 6 can be placed in one click at **S 8 x 8**, **M 16 x 16** or **L 32 x 32** units (labels from T-261), chosen on the top bar; the plain click's default becomes M (today it is 84 x 30). Snapping and the overlap refusal apply as before.

The game's own map is unchanged. Built on T-262's branch (the Project Lead makes your folder). End with screenshots of ramps in all four directions with arrows up and with arrows down, their tall ends closed, and of S, M and L platforms at both heights.

## Acceptance criteria

- [ ] Tests show every ramp draws a wall at its tall end, in every direction and height step (QA: pass / fail)
- [ ] Tests show the arrows point up or down the slope as chosen, in every direction and height step, the choice is saved and reopened, and the default is up (QA: pass / fail)
- [ ] Tests show S, M and L platforms place at 8, 16 and 32 units square at heights 3 and 6, and dragging still sizes them freely (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-264/screenshots/`; `game/README.md` describes the three; the game's own map is unchanged; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place ramps both ways round and S, M and L platforms.
Board review files: the screenshots in `art-archive/T-264/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

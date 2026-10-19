---
id: T-198
title: Art: rooftops and parking-garage ramps for the elevation sample map (PixelLab)
status: blocked
from: project-lead
to: asset-generation
lead: Goal-G-004
epic: art
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: yes
depends_on: [T-196]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, docs/working-with-the-board.md, game/README.md, game/tools/build_elevation_art.py, game/tools/test_build_elevation_art.py, game/tools/check_sprite_rules.py, game/tools/city_palettes.py, game/tools/pixellab_client.py, game/scripts/level/elevation_platform_drawing.gd, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/tools/build_elevation_sample_art.py, game/tools/test_build_elevation_sample_art.py, game/art/elevation_sample/, game/scripts/level/elevation_platform_drawing.gd, game/scripts/level/elevation_sample_map.gd, game/tests/unit/test_elevation_sample_art.gd, art-archive/<task id>/, docs/visual-style.md, game/README.md]
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

Visual style, Decisions, 'Elevation sample map art' (board, 2026-10-19: left to the Project Lead, up to 50 PixelLab generations, judged in the board's playtest). The raised areas of the sample map are building rooftops and the ramps parking-garage-style concrete ramps, in the City brief and City colours (steel and glass: cool blue-grey concrete, small amber accents, light damage), not the boulders' navy and purple, and not castle stone (the test scene's platform read as a dungeon, so its art is not reused).

The goal run is the board's go for PixelLab up to the goal's art cap: no sample review, one round, no regeneration. Before any call, write the planned calls and their cost in the result notes; the total must be 50 generations or fewer. Use a 600 s HTTP timeout. A likely plan (a proposal): textures for a rooftop top, a building wall with lit windows, and the ramp's concrete surface with garage markings, plus a few rooftop details (a low parapet, vents, AC units, a small rooftop sign, light cracks).

Write `game/tools/build_elevation_sample_art.py` (following build_elevation_art.py, which stays as it is for the test scene) that projects the textures onto the faces of every raised area and ramp in game/data/level/elevation_sample_map.json: the tops, the visible south and east walls (building walls with lit windows), and the ramps' concrete; it places the rooftop details on the tops. It has a check mode, and Python tests. Game-ready art in game/art/elevation_sample/, one sprite and record per area; raw generations and records in art-archive/<task id>/.

In the sample map scene, each area's drawing shows its art in place of the script drawing, which stays as the fallback when the art is missing; the elevation test scene keeps its own art. The art fades with its area when it turns see-through. Art rules: hard pixel edges, no semi-transparent pixels, at most 30 colours per sprite, transparent background, 32 art px per unit drawn at 0.5, no Redgull red. Weak results are noted in the result notes and in docs/visual-style.md, not regenerated. Screenshots in the game: the street, a rooftop at 3, a rooftop at 6, a ramp, and a see-through area.

The board's review: The rooftop and parking-garage ramp art on the elevation sample map, judged in the goal's final playtest.

## Acceptance criteria

- [ ] The result notes list the planned PixelLab calls and their cost, written before the first call (the commit order or the notes' timestamps show it); the total is 50 generations or fewer; the calls use a 600 s timeout; no call was repeated. (QA: pass / fail)
- [ ] `python game/tools/build_elevation_sample_art.py --check` passes and game/tools/test_build_elevation_sample_art.py passes; there is one game-ready sprite and record in game/art/elevation_sample/ per raised area and ramp in elevation_sample_map.json. (QA: pass / fail)
- [ ] check_sprite_rules.py (or the build's own check) passes on every sprite: hard pixel edges, no semi-transparent pixels, at most 30 colours, transparent background, no Redgull red; the records give 32 art px per unit drawn at 0.5. (QA: pass / fail)
- [ ] Raw generations and their records are in art-archive/<task id>/. (QA: pass / fail)
- [ ] A GUT test checks the sample map scene shows the art sprite for each area, falls back to the script drawing when an area's art is missing, and that the art's alpha follows its area's see-through fade. (QA: pass / fail)
- [ ] The elevation test scene's art and tests are unchanged (test_elevation_art.gd passes; game/art/elevation/ unchanged). (QA: pass / fail)
- [ ] Screenshots in the game, in art-archive/<task id>/screenshots/: the street, a rooftop at height 3, a rooftop at height 6, a ramp, and a see-through area; listed in the result notes and on the Board review files line. (QA: pass / fail)
- [ ] docs/visual-style.md (Decisions, 'Elevation sample map art') records the generations used and any weak results; game/README.md explains how to rebuild the art. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

---
id: T-198
title: Art: rooftops and parking-garage ramps for the elevation sample map (PixelLab)
status: in-progress
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

### 2026-10-20, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-198.

## Result notes

Written by the agent when it finishes.

### Planned PixelLab calls and cost (written before the first call)

Eight `/create-image-pixflux` calls, one generation each, 600 s HTTP timeout (`pixellab_client.py`'s `HTTP_TIMEOUT_SECONDS`), no retries, no regeneration. **Total: 8 generations** (cap 50; the goal has 50 left). Raw results and records go to `art-archive/T-198/`.

| # | name | size | what |
|---|------|------|------|
| 1 | raw_roof_top | 128x128 | rooftop surface texture: cracked cool blue-grey concrete/tar, light stains, flat, top-down |
| 2 | raw_wall | 128x128 | building wall with lit windows (steel and glass, small amber accents) |
| 3 | raw_ramp_top | 128x128 | garage ramp concrete with painted lane markings (top-down) |
| 4 | raw_ac_unit | 64x64, transparent | rooftop AC unit |
| 5 | raw_vent | 48x48, transparent | rooftop vent stack |
| 6 | raw_sign | 64x64, transparent | small rooftop sign (cyan/amber, no red) |
| 7 | raw_parapet | 128x32, transparent | low parapet wall segment |
| 8 | raw_cracks | 64x64, transparent | light crack decal |

Everything else (projection onto the faces, outlines, details placement, the colour reduction) is free script work in `game/tools/build_elevation_sample_art.py`.

### What was done

**PixelLab:** exactly the 8 planned calls, all `create-image-pixflux`, 1 generation each = **8 generations used** (42 of the goal's 50 left), 600 s HTTP timeout (the client's `HTTP_TIMEOUT_SECONDS`), none repeated, none failed. Raws and records: `art-archive/T-198/raw_*.png/.json`; request files: `art-archive/T-198/requests/`; the client also logged them in `game/art/pixellab-generation-log.jsonl`. The plan was committed (c3f46df) before the first call.

**Builder:** `game/tools/build_elevation_sample_art.py` (`build`, `--check`). It reads `elevation_sample_map.json` and writes one sprite and record per area into `game/art/elevation_sample/` (4 rooftops: roof-nw-3, roof-nw-6, roof-se-3, roof-se-6; 4 ramps: ramp-nw-0-3, ramp-nw-3-6, ramp-se-0-3, ramp-se-3-6). It handles all four ramp sides, stacked rooftops (walls start at the height they stand on) and ramps standing on a rooftop; a ramp has no wall at the end where it joins its rooftop and no outline there. Rooftop walls use the building wall texture with lit windows; ramp sides use darker rooftop concrete. Rooftop details: parapet along the back (north, west) edges with gaps at ramp joins and under higher rooftops, AC units, vents and a sign near the back edges (away from ramps and stacked rooftops), crack decals. Every sprite is reduced to 30 colours or fewer.

**Game:** `elevation_platform_drawing.gd` `setup()` takes an optional art folder and name (defaults are the elevation test scene's, so that scene and `art/elevation/` are unchanged); `elevation_sample_map.gd` passes `art/elevation_sample/` and the area's id instead of freeing the art. With the art missing the script drawing is drawn (the fallback). The art sprite is a child of the drawing, so it fades with it.

**Tests:** `game/tools/test_build_elevation_sample_art.py` (11 tests, pass); `game/tests/unit/test_elevation_sample_art.gd` (7: sprites and records, rules, every area shows its art sprite, placement by record, fallback to the script drawing for a missing name, the art's alpha follows the area's see-through fade to 15% and back, the test scene keeps its art); `test_elevation_sample_map.gd` changed its placeholder assertion to expect the art. Full GUT run: 1119 passing, TESTS PASSED. Python tool tests (`python -m unittest discover -s game/tools -p "test_*.py"`): 342 tests OK. `python game/tools/build_elevation_sample_art.py --check` passes (every sprite: transparent corners, no semi-transparent pixels, 28 to 30 colours, no Redgull red; records 32 art px per unit, scale 0.5, size matches). I ran only the pre-approved commands, so `python -m unittest discover -s tools` (the repo-level `tools/` tests) was not run: it is not importable as a start directory and I could not try other forms.

**Weak results (not regenerated; also in docs/visual-style.md):** the rooftop texture came back as a grid of big tiles with strong dark seams (it reads as a paved floor more than a rooftop); the building wall is very dark with small lit windows; the parapet is thin and grey, only on the back edges; the details are few and small, the crack decals faint; the see-through screenshot also shows a large dark square that is the existing map's building placeholder under the faded rooftop, not part of this art. The garage ramps read best. Details are baked in the sprite, so the car drives through them.

**Screenshots** (in `art-archive/T-198/screenshots/`, taken in the game with the existing sample map fixtures): `street.png` (the street at the start), `rooftop_height_3.png` (the car on the height-3 rooftop), `rooftop_height_6.png` (on the height-6 rooftop), `ramp.png` (on the 0-to-3 ramp), `see_through.png` (the car behind the height-3 rooftop, which has faded).

**Board review files:** art-archive/T-198/screenshots/street.png, rooftop_height_3.png, rooftop_height_6.png, ramp.png, see_through.png; sprites in game/art/elevation_sample/.

Documents affected and updated: docs/visual-style.md (Decisions, "Elevation sample map art": generations used, weak results), game/README.md ("Rooftop and ramp art (T-198)", how to rebuild).

**Refusals:** none from a hook or the permission system. An inline `python -c` contact-sheet command asked for approval and was not run (not essential; I looked at the raw images one by one instead).

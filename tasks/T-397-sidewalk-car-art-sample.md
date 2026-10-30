---
id: T-397
title: Art sample: one sidewalk tile with its curb and one parked car facing, for the board's review
status: in-progress
from: project-lead
to: asset-generation
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, docs/visual-style.md, docs/level-design.md, game/art/roads/, game/art/buildings/, game/art/boulders/, game/docs/level/level-creator-pieces.md]
files_expected_to_change: [art-archive/, game/docs/art/, docs/visual-style.md]
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

Sample first (docs/working-with-the-board.md, "Art and money"): one sidewalk tile with a curb edge against the road, and one normal parked car at one facing (top right), for the board's review before the full set (T-399). They must fit the existing roads, buildings and obstacles: the same isometric angle, tile size and pixel scale as the road tiles, the city's palette (Visual style, Decisions, "City colours"), and nothing of Greenbull. The parked car is a plain, boring city car, clearly not the player's car. Free script work first where it fits (for example the curb drawn by script from the road's kerb line). The board's go: PixelLab up to 50 generations for T-397 and T-399 together; write the planned calls and cost in the result notes before calling, and keep this sample to a few generations. Every asset goes through the style loop. Show the sample composed with a road tile, a building and a boulder, so the board judges the fit. Put the sample in `art-archive/<id>/`, not yet in the game.

The board's review: look at the sample next to the road, a building and a boulder, and approve or adjust it.

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", 2026-10-30). The board: "add sidewalk assets that fit with the road ... and the buildings and other assets that we have, and make sure that it works well, consider the curb as well. And I also want a few different car assets that are just sitting parked, just normal, boring kind of cars. Generate some broken ones as well. And make it so that they sit at four rotations: top right, bottom right, bottom left, top left. This is for the level creator." The board's answers: parked cars are solid obstacles like boulders (crash into them, pairable for thread the needle); sidewalks are painted like roads with the curb added automatically where they meet a road, and the car drives up over the curb; PixelLab up to 50 generations for the whole set (T-397 and T-399 together), sample first. The tickets: T-396 (piece names), T-397 (art sample), T-398 (the pieces in the creator and the run, placeholders), T-399 (the full art set, swapped in). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] One sidewalk tile with a curb edge and one parked car at the top-right facing are in `art-archive/<id>/`, at the road tiles' isometric angle and pixel scale (checked against a road tile). (QA: pass / fail)
- [ ] A composed preview shows them next to a road tile, a building and a boulder, on a dark and a light background, enlarged. (QA: pass / fail)
- [ ] Each went through the style loop, with its score in the Style review; the generations used are in the result notes, within the cap. (QA: pass / fail)
- [ ] Visual style describes the sidewalk's and the parked cars' look. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the art sample, one sidewalk tile with its curb and one parked car facing, for your review.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-30: art, brief `art-archive/T-397/briefs/sidewalk.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-397/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 6/10
- Reason: The tile passes the script checks and mostly fits. It is 128x64 and the right diamond. The pavement is a lighter, cooler grey than the asphalt and matches the creator building's pavement. It has slab joints and speckle, with no Greenbull, navy, purple or magenta colours. The other edges carry no outline, and it sits well beside the road in the preview (rules 1, 3, 4, 7 and 10 are fine).

The problem is rule 2 on the curb side, which the brief singles out as the one place an outline belongs. In the preview the curb reads as a thin pale line along the lower-right edge. Three parts are weak or missing:
- The stone top is barely distinguishable from the slabs.
- The small front face is nearly invisible.
- The dark gutter line where the curb meets the asphalt does not read. The curb blends into the road instead of showing a near-black line, and the lit edge is not broken into highlight pixels.

Fix, in the sidewalk script:
- Draw a 1 px dark, almost black gutter line along the whole SE edge.
- Add a front face 2 to 3 px tall, in a darker mid-grey than the top.
- Make the curb top a slightly different, lighter stone value from the slabs, with a lit top-edge row broken by highlight pixels.
- Keep the curb height under 3 art px.

Secondary: the cracks are tiny 3 to 4 px squiggles that are almost lost against the speckle. Make them slightly longer or darker so they read as light cracks, and keep the slab pattern repeating every 2 units.
- Rules broken: 2
- Refused: {"tool_input": {"command": "ls art-archive/T-397/style-loop 2>/dev/null; python -m unittest game/tools/test_build_sidewalk_car_sample.py 2>&1 | tail -3", "description": "Check existing versions and run tests"}, "tool_name": "Bash", "tool_use_id": "toolu_017RCTfhpNb783dwtpcQL4sM"}; {"tool_input": {"command": "python -m unittest game/tools/test_build_sidewalk_car_sample.py", "description": "Run sidewalk script tests"}, "tool_name": "PowerShell", "tool_use_id": "toolu_01NvNsoP77vHxpwZ5NFBBkGA"}; {"tool_input": {"command": "python game/tools/build_sidewalk_car_sample.py sidewalk --out art-archive/T-397/style-loop/v1.png", "description": "Draw sidewalk tile version 1"}, "tool_name": "PowerShell", "tool_use_id": "toolu_0168UnABh8f7SYKVEZDkY2R9"}; {"tool_input": {"command": "python -m unittest game/tools/test_build_sidewalk_car_sample.py", "description": "Run sidewalk script tests"}, "tool_name": "Bash", "tool_use_id": "toolu_018Qn5ctJDTyXzV5yKkrJDS5"}

### Round 2

- Version 2: `art-archive/T-397/style-loop/v2.png`
- What changed: Version 2 is a free script fix with no PixelLab call. I changed only the curb and the cracks in `game/tools/build_sidewalk_car_sample.py` and kept everything else the same: the pavement colours, the slab checker that repeats every 2 units, the speckle, the size and the diamond. The tile now has 13 colours.

What changed:
1. **Curb top.** It is now a clearly lighter stone value than the slabs: (146,164,183), against the slabs' 103/98. A dark seam row still separates it from the slabs.
2. **Lit edge.** The top row of the curb is a lit edge (172,187,203), broken by brighter highlight pixels (200,211,223) every 5 px.
3. **Front face.** It is about 3 rows of a darker mid-grey than the top: (104,118,136), with its lowest row shaded (86,99,117). The curb height stays at 3 art px.
4. **Gutter line.** A near-black 1 px line (14,14,20) now runs the whole SE edge, one row below the face. In front of it, a narrow road-dark strip (40,38,52) runs to the tile's edge.
5. **Curb position.** The whole curb now sits 0.18 unit in from the tile's SE edge (new `CURB_INSET`). In v1's composed preview, the road tile drawn next to the curb hid its face and gutter rows completely.
6. **Cracks.** They are longer, 10 to 15 px runs instead of 5 to 9, and stay off the curb.

The preview now also writes two close-ups. `preview_curb_zoom.png` is the curb against the road in the composed scene, at 8x. `tile_curb_zoom.png` is the tile's own curb corner, at 10x.

Previews (folder C:\solid-carbide-worktrees\T-397\art-archive\T-397\style-loop\sidewalk_v2_preview\):
- preview_side_by_side.png
- preview_curb_zoom.png
- tile_curb_zoom.png

What I see:
- **On the tile itself**, all four curb parts read clearly in tile_curb_zoom.png: the stone top, the broken lit edge, the grey face and the black gutter.
- **In the composed preview**, the light curb top, the lit edge and a dark line against the asphalt now show. But the grey front face is still mostly hidden: the neighbouring road tile still draws over the curb's lower rows there. I could not find out why, because ad-hoc Python needed approval. If the evaluator marks this down, the next fix is to move the curb further in (raise `CURB_INSET`) or to check how the road tiles overlap the curb tiles in `compose`.

Tests: I could not run `python -m unittest game/tools/test_build_sidewalk_car_sample.py`, because the command needed approval. I did not change the tests. Their checks on the gutter colour use the `GUTTER` constant, which is still drawn along the SE edge only. The Project Lead should run them.
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The tile meets the brief. It is a 128x64 diamond with 13 colours, hard pixels and a transparent background. The pavement is a cool blue-grey with no Greenbull, navy, purple or magenta colours (rules 1, 6, 7). The curb runs along the lower-right edge and reads clearly: a lit top, a bright edge, a small front face and a dark gutter line. It is low, a few px high. The other edges have no outline, so it joins neighbouring tiles. The night mood and 2:1 isometric scale are fine (rules 3, 4). Weak points, none a rule break: (a) the slab joints and cracks are very faint and low-contrast, so at 1x the top reads as a mostly flat grey with noise rather than slabs (rule 2, detail); (b) the gutter shadow below the curb is a wide dark band of 4-5 px, so the front face and gutter nearly merge into the road. A slightly stronger, regular slab-joint line and a thinner gutter would raise it.
- Rules broken: none
- Refused: {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-397/style-loop/v1.png').crop((56,24,128,64))\nbg=Image.new('RGBA',im.size,(40,38,50,255));bg.alpha_composite(im)\nbg.resize((im.width*10,im.height*10),Image.NEAREST).save('C:/Users/andre/AppData/Local/Temp/t397_v1_zoom.png')\"", "description": "Make zoomed crop of v1 curb"}, "tool_name": "Bash", "tool_use_id": "toolu_01Prta6nC7BDjTkKwN4aQQXz"}

**Kept:** version 2, score 8/10 (`art-archive/T-397/style-loop/v2.png`, copied to `art-archive/T-397/sidewalk_curb_se.png`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.

**Planned PixelLab calls and cost (written before any call, 2026-10-30).** The board's go: up to 50 generations for T-397 and T-399 together; this sample at most 8. Balance before: 4743 generations.

- Sidewalk tile with its curb: **0 generations**. Drawn by a free script (`game/tools/build_sidewalk_car_sample.py sidewalk`) in the buildings' own pavement colours (`build_creator_buildings_art.py` PAV), so it matches the pavement round the creator buildings; its refines in the style loop are script changes, no PixelLab.
- Parked car, top-right facing: **1 generation per round**, `/create-image-pixflux` 128 x 128 (`isometric`, `no_background`, `direction` north-east; request `art-archive/T-397/requests/car_v1.json`), then a free clean-up by script (`... car`: background, specks, at most 30 colours, a mirror if PixelLab faces it top-left). At most 4 rounds in the style loop: **up to 4 generations**.
- Total planned: **up to 4** (cap 8). 600 s HTTP timeout (the client's default).

Running total: 0 generations used.

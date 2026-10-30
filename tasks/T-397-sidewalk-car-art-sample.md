---
id: T-397
title: Art sample: one sidewalk tile with its curb and one parked car facing, for the board's review
status: done
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

Added by the board, 2026-10-30: one **meteor crater** joins the sample. It is a hole a meteor left in the ground, and the car drives over it: a ground piece, not an obstacle. It sits flat in the ground at the road tiles' angle and scale, in the meteors' and the city's palette, and joins the composed preview. Inside the same 50 cap; the sample's budget rises to at most 10 generations for the three pieces. Script first if it fits.

The board's review: look at the sample next to the road, a building and a boulder, and approve or adjust it.

Board review files: art-archive/T-397/screenshots/preview_side_by_side.png, art-archive/T-397/screenshots/crater_zoom.png, art-archive/T-397/screenshots/preview_curb_zoom.png, art-archive/T-397/sidewalk_curb_se.png, art-archive/T-397/parked_car_ne.png, art-archive/T-397/meteor_crater.png

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", 2026-10-30). The board: "add sidewalk assets that fit with the road ... and the buildings and other assets that we have, and make sure that it works well, consider the curb as well. And I also want a few different car assets that are just sitting parked, just normal, boring kind of cars. Generate some broken ones as well. And make it so that they sit at four rotations: top right, bottom right, bottom left, top left. This is for the level creator." The board's answers: parked cars are solid obstacles like boulders (crash into them, pairable for thread the needle); sidewalks are painted like roads with the curb added automatically where they meet a road, and the car drives up over the curb; PixelLab up to 50 generations for the whole set (T-397 and T-399 together), sample first. The tickets: T-396 (piece names), T-397 (art sample), T-398 (the pieces in the creator and the run, placeholders), T-399 (the full art set, swapped in). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] One sidewalk tile with a curb edge and one parked car at the top-right facing are in `art-archive/<id>/`, at the road tiles' isometric angle and pixel scale (checked against a road tile). (QA: pass / fail)
- [ ] A composed preview shows them next to a road tile, a building and a boulder, on a dark and a light background, enlarged. (QA: pass / fail)
- [ ] Each went through the style loop, with its score in the Style review; the generations used are in the result notes, within the cap. (QA: pass / fail)
- [ ] Visual style describes the sidewalk's and the parked cars' look. (QA: pass / fail)
- [ ] Added by the board, 2026-10-30: one meteor crater (a flat ground piece the car drives over, not an obstacle) is in `art-archive/<id>/` at the road tiles' isometric angle and pixel scale, in the meteors' and the city's palette, went through the style loop with its score in the Style review, and is in the composed preview; the three pieces together used at most 10 generations. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the art sample, one sidewalk tile with its curb and one parked car facing, for your review.

### 2026-10-30, Flagged for review → Done

Approved by you; merging the sample. The full set (T-399) follows once build G starts.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-30: art, brief `art-archive/T-397/briefs/sidewalk.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

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

#### Round 2

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

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-30: art, brief `art-archive/T-397/briefs/car.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-397/style-loop/v1-2.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The car is a plain, pale silver-blue sedan with unlit lights. Its nose points to the upper right and the red tail lights sit at the lower left, so it is clearly not the player's Mustang. It has no stripes, no dark green and no Greenbull colours or logo, and it shows no readable words or badges. The script checks pass for rules 1, 3 and 6. The view is 3/4 isometric with detailed shading, and the body fills most of the 128x128 frame. It is not a wreck, and the palette is neutral rather than the boulders' navy, purple or magenta, so rules 7, 8 and 10 are not broken. Minor weak points, none worth a refine unless the board wants more: the image was only 128 px, so I couldn't judge it closely, but the dark outline looks thinner and lighter along the roof and upper edges than rule 2's 'dark, almost black selective outline' asks for. The 30-colour count sits exactly at the limit, so any added colour would break rule 1. No rule is clearly broken.
- Rules broken: none
- Refused: {"tool_input": {"command": "python -c \"\nfrom PIL import Image; im=Image.open('art-archive/T-397/raw/car_v1_raw.png'); im.resize((512,512),Image.NEAREST).save('art-archive/T-397/raw/car_v1_raw_x4_view.png')\"", "description": "Enlarge raw car for viewing"}, "tool_name": "Bash", "tool_use_id": "toolu_01KSiDv2A1dgkzgBtm5x7a8E"}

**Kept:** version 1, score 8/10 (`art-archive/T-397/style-loop/v1-2.png`, copied to `art-archive/T-397/parked_car_ne.png`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-30: art, brief `art-archive/T-397/briefs/crater.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-397/style-loop/v1-3.png`
- Script checks: 6 of 6 pass
- Score: 5/10
- Reason: Passes the script checks (128x64, 19 colours, alpha 0 or 255, no Greenbull colours) and reads as a hole seen from above. The shape and the glowing floor are fine. It breaks these rules:

Rule 7 and the brief (asphalt): The rim is a smooth grey ring with no asphalt character. There are no broken or lifted slabs and no fragments round the lip, and the grey is close to the road's own grey, so the rim barely separates from the road. Draw a few chunky, angular slab pieces, with lighter top faces and dark edges, lifted along the rim. Make the rim lighter or more varied than the road.

Rules 5 and 2 (scorch halo): The scorched band is a 1-pixel checkerboard dither on the outer rim. It reads as noise, and it looks like blur on the sidewalk. Replace it with 2 or 3 solid stepped bands of darker asphalt, or with a few solid scorch patches.

Rules 5 and 8 (glow): The magenta cracks are scattered, disconnected pixel clusters lying on the ground outside the rim, like confetti. Real cracks should run from the rim into the rock or the wall, and be connected. The glow has no stepped halo of darker shades. Add one or two darker purple pixels round the bright cracks. The cracks are also spread over the rim at the same weight everywhere, so cut them back to a few good ones.

Rule 8 (rock): There are no navy rock fragments, only grey. Add a few dark navy meteor chunks, in the boulders' palette, at the floor or the rim.

Rule 2 (outline and detail): The two small navy boxes on the floor look like stray rectangles and don't read as rock. Redraw them as irregular rock chunks. The outline is not a clear dark selective line where the rim drops into the hole. The wall bands are low in contrast and overall too dark and flat, so the detail is thin for a high-detail sprite.
- Rules broken: 2, 5, 7, 8
- Refused: {"tool_input": {"command": "cd C:/solid-carbide-worktrees/T-397 && ls art-archive/T-397/ art-archive/T-397/style-loop 2>&1; python game/tools/build_sidewalk_car_sample.py crater --out art-archive/T-397/style-loop/v1-3.png && python game/tools/build_sidewalk_car_sample.py preview --sidewalk art-archive/T-397/sidewalk_curb_se.png --car art-archive/T-397/parked_car_ne.png --crater art-archive/T-397/style-loop/v1-3.png --out-dir art-archive/T-397/style-loop/crater_v1_preview && python -m unittest game/tools/test_build_sidewalk_car_sample.py 2>&1 | tail -3; python -c \"\nfrom PIL import Image;import numpy as np\nim=Image.open('art-archive/T-397/style-loop/v1-3.png');print(im.mode,im.size);a=np.array(im);print(set(np.unique(a[...,3])));print(len({tuple(p) for p in a.reshape(-1,4) if p[3]}))\""}, "tool_name": "Bash", "tool_use_id": "toolu_01EM7e81N1KZh6BysBGBPfR4"}; {"tool_input": {"command": "python game/tools/build_sidewalk_car_sample.py crater --out art-archive/T-397/style-loop/v1-3.png", "description": "Draw crater version 1"}, "tool_name": "PowerShell", "tool_use_id": "toolu_01DtwpFrzi86QgwUXKTyjytS"}; {"tool_input": {"command": "python -m unittest game/tools/test_build_sidewalk_car_sample.py", "description": "Run the sample builder's tests"}, "tool_name": "Bash", "tool_use_id": "toolu_01Nqa7kkofbpB36RjqqN45d6"}

#### Round 2

- Version 2: `art-archive/T-397/style-loop/v2-2.png`
- What changed: Version 2 is a free script fix. I rewrote draw_crater; no PixelLab was used. It is 128x64, 8-bit RGBA, 21 colours, alpha 0 or 255, and stays inside the diamond.
- Rule 7 (asphalt rim): the smooth ring is replaced by 10 angular, broken slabs drawn far to near. Each slab has its own lift (0 to 2 px), width and tilt, which gives straight outer edges. Each has a lit upper edge (new SLAB_HI, lighter than the road), a dark front face with a near-black foot, and a tone from three asphalt greys. Gaps between the slabs show the scorch, so they read as separate plates. On the near half, a dark line runs along the rim's outer edge so the slabs stand off the ground.
- Rules 5 and 2 (scorch): the checkerboard dither is gone. The scorch is now three solid stepped bands (SCORCH_DEEP, SCORCH, ASPH_DARK) with an uneven outer edge and five solid scorch tongues.
- Rules 5 and 8 (glow): the cracks are cut to 4 connected fissures. Each starts inside the lip and runs across the rim into the scorch, drawn as continuous lines. The bright core runs GLOW_CORE, then GLOW, then GLOW_MID. Round it is a stepped 1 px GLOW_HALO, plus a second GLOW_DEEP step near the rim. The floor glow is now solid stepped rings with no dither, and GLOW_DEEP lights the wall's foot.
- Rule 8 (rock): navy meteor chunks are now irregular, faceted and outlined in the boulders' palette. Three sit on the floor (two with a glowing seam) and four are thrown onto the rim and the scorch. A few navy grit pixels sit in the wall's earth.
- Rule 2 (outline and detail): a near-black selective outline runs all round the lip where the rim drops into the hole, with a dark line under the lit cut edge on the far side. The wall bands have more contrast: a lit cut-asphalt row, an asphalt row, a dark seam, a lighter earth stratum (new EARTH_LIGHT), then earth darkening downwards.
What I kept: the hole shape, the far-wall-only view and the floor glow.
My own notes for the evaluator: the floor shows only as a narrow strip, so most of the glow sits low in the hole. The scorch is a large dark area on the light sidewalk, solid and not dithered.
Preview: C:\solid-carbide-worktrees\T-397\art-archive\T-397\style-loop\crater_v2_preview\ (preview_dark.png, preview_light.png, preview_side_by_side.png, crater_zoom.png).
Open issue: the permission system refused the unit-test run (python -m unittest game/tools/test_build_sidewalk_car_sample.py), so the tests have not been run on this version. I did not work around the refusal.
- Script checks: 6 of 6 pass
- Score: 6/10
- Reason: I could only see the image at 128x64, so these points come from a small view.

What passes: the script checks pass (128x64, 21 colours, alpha 0 or 255, no Greenbull colours). The crater reads as a hole in the ground, with a dark inner pit. It has magenta and purple glowing cracks drawn as stepped pixels, with no blur (rules 1, 3, 5, 8). The theme is night and retro (rule 4).

Rules 2 and 10:
- The rim is a dark, nearly uniform navy and purple ring. It looks like a raised ring or lip, close to a mound or bowl, more than a hole with a clear far inner wall and a near wall hidden under the rim.
- Little of the road's own asphalt shows. The brief asks for broken, lifted grey asphalt slabs round the rim and a scorched band. Here the rim is almost all alien rock, so the ground piece does not read as the city's road broken open by a meteor.
- The outline and shading are flat. The dark outline is not broken by lighter highlight pixels. The rim has few mid-tone steps, so it lacks the detailed shading rule 2 asks for.

Fixes in draw_crater:
- Add grey asphalt slabs on the rim (lighter top faces, darker edges) and a scorched band between slab and pit.
- Keep the navy and purple rock fragments sparse.
- Light the far inner wall and darken the near rim edge, so it clearly reads as a hole.
- Add highlight pixels to the outline and more mid-tone steps.
- Rules broken: 2, 10

#### Round 3

- Version 3: `art-archive/T-397/style-loop/v3.png`
- What changed: Version 3 is another free script fix in draw_crater; no PixelLab was used. It is 128x64, 8-bit RGBA, 22 colours, alpha 0 or 255, and stays inside the diamond. It keeps v2's shape, lifted angular slabs, stepped scorch bands and connected cracks with stepped halos. The changes:
- Grey asphalt slabs: the tops now use new, lighter neutral greys (SLAB_TOP 98,97,108 and SLAB_MID 88,87,98) plus ASPH_HI, in place of the navy-purple asphalt shades. Far slabs face the light and are lighter. Near slabs are a step darker, which darkens the near rim edge. The lifted slabs keep their SLAB_HI lit upper edges and dark faces. That gives about four mid-tone steps per slab.
- Scorched band between slab and pit: each slab's inner edge now has a SCORCH strip, broken with SCORCH_DEEP, where it drops into the hole.
- Lit far inner wall: from the rim down it now runs ASPH_HI, ASPH_LIT, EARTH, a new lit stratum (WALL_LIT 92,84,104), EARTH_LIGHT, EARTH_DARK at the foot, then the floor's glow. This is lighter and has more steps than v2, so it reads as a hole's far wall.
- Outline highlights: the dark lip line is broken by SLAB_HI chips on the far side and ASPH_LIT chips on the sides.
- Sparser rock: only 2 navy chunks are now thrown onto the rim and scorch (down from 4). The 3 floor fragments stay.
My own notes for the evaluator: at 128x64 the crater is still mostly dark, because the hole and scorch are large. The floor glow shows as a narrow band low in the hole.
Preview: C:\solid-carbide-worktrees\T-397\art-archive\T-397\style-loop\crater_v3_preview\ (preview_dark.png, preview_light.png, preview_side_by_side.png, crater_zoom.png; the zoom is 6x, so judge from it rather than from 1x).
Open issue: the permission system refused the unit-test run (python -m unittest game/tools/test_build_sidewalk_car_sample.py) earlier in this loop. I did not retry it or work around it, so the tests have not been run on v2 or v3.
- Script checks: 6 of 6 pass
- Score: 7/10
- Reason: Passes the script checks: 128x64, 22 colours, alpha 0 or 255, no Greenbull colours (rules 1, 3, 6). The palette is right: grey asphalt slabs, navy rock, magenta and purple cracks (rules 7, 8). Glow is drawn as hard bright pixels with stepped halos (rule 5). It is dark and retro (rule 4).

Weaknesses, mainly rule 3 (view) and rule 2:
1. The "hole" reads partly as a domed bowl or lid. The banded purple-grey far wall plus the magenta floor look like a raised dome or an eye, not a pit. Fix: make the far inner wall darker and shaded, with a clear drop at the near rim. Put the glow only low on the floor, not mid-height.
2. The rim is a thick, even ring of similar slabs, so it looks tall, like a low wall. Fix: vary the slab heights and sizes, break the ring (gaps, tilted slabs), and make the near side thin.
3. There is no dark outline at the rim where it drops into the hole (rule 2). Fix: add a selective near-black line on the inner edge of the rim, broken by highlight pixels on the far slabs.
4. The magenta cracks run outward across the asphalt as long, thin lines. They look pasted on and they reduce the asphalt feel. Fix: shorten them or tie them to rim slabs. Add a scorched band and rubble round the rim, so the asphalt reads as broken.
5. A soft, dark skirt round the rim shows when the crater is alone on a transparent background. Keep it clearly inside the diamond and give it a hard, stepped edge.
- Rules broken: 2, 3

#### Round 4

- Version 4: `art-archive/T-397/style-loop/v4.png`
- What changed: Version 4 is the third and last refine, again a free script fix in draw_crater; no PixelLab was used. It is 128x64, 8-bit RGBA, 22 colours, alpha 0 or 255, and stays inside the diamond. Changes for each point:
1. Pit, not dome: the far wall is now dark. Only the cut asphalt at the top is lit (ASPH_LIT, then ASPH). The earth below steps down EARTH_LIGHT, EARTH, EARTH_DARK, FLOOR, and is darker at both ends where the wall curves away. The banded WALL_LIT stratum and the glow on the wall's foot are gone. The floor glow is smaller (three solid stepped rings) and sits only low on the floor round the fragments.
2. Broken, varied rim: about 1 in 5 slabs is now missing, leaving gaps, and the gap size varies per slab. Far slabs vary from flat to lifted 2 px, from narrow to wide, and are strongly tilted. Near slabs are thin and flat, so the near rim stays low.
3. Outline: the hole's whole edge gets a near-black line, at the slabs and in the gaps. It is 2 px on the near side, for the drop under the near rim. It is broken by SLAB_HI chips on the far slabs and ASPH_LIT chips on the sides.
4. Cracks: the 4 cracks are now short. Each starts in the lip and stops just past the slabs, in the scorch. 14 grey asphalt rubble chips (a lit top with a near-black foot) are scattered in the scorch round the rim. The navy chunks on the ground stay sparse (2).
5. No skirt: the scorch is narrower (outer edge at most about 0.15 unit past the rim, plus 3 small tongues). Each band's radius is quantised, so the edges step in hard runs.
My own notes for the evaluator: the whole piece is now darker. With slabs missing and the near slabs thin, less grey asphalt shows than in v3; the grey reads mainly on the far rim, and the near rim reads as dark ground.
Preview: C:\solid-carbide-worktrees\T-397\art-archive\T-397\style-loop\crater_v4_preview\ (preview_dark.png, preview_light.png, preview_side_by_side.png, crater_zoom.png at 6x).
Open issue: the unit tests (python -m unittest game/tools/test_build_sidewalk_car_sample.py) have not been run since v1. The permission system refused that command, and I did not work around it.
- Script checks: 6 of 6 pass
- Score: 7/10
- Reason: I scored from v4.png and from crater_zoom.png in crater_v4_preview. It passes the script checks: 128x64, 22 colours, alpha 0 or 255, no Greenbull colours. It reads as a ground hole from above with the road's isometric angle. The dark rim with slabs, the dark floor, the magenta cracks and the single navy fragment fit rules 7 and 8, and the glow is hard-edged (rule 5). Three things keep it from a higher score.

Rule 5: the glow has bright pixels but almost no stepped darker halo shades round the cracks. It looks like flat magenta lines. Add one or two darker purple pixel steps round each crack and round the floor glow, and keep them inside the sprite.

Rule 2: the shading is thin. The rim is a near-uniform dark band, and the lifted asphalt slabs and the scorched band are barely distinguishable. The far inner wall hardly separates from the floor, because the floor is nearly black. Add 2 or 3 more rim tones with lighter highlight pixels on the slab edges, a lighter far inner wall band, and a faint floor glow, so it reads as a bowl with depth. The outline where the rim drops into the hole is not clearly selective.

Rule 3: the crater is smaller than the 2x2 diamond. It fills only about 60% of the diamond width and leaves wide empty margins. This is acceptable for a decal, but a slightly wider crater, with a few rubble pixels scattered towards the diamond corners, would sit better on the road. Keep everything inside the diamond.
- Rules broken: 2, 5

**Kept:** version 3, score 7/10 (`art-archive/T-397/style-loop/v3.png`, copied to `art-archive/T-397/meteor_crater.png`): still below 8 after 3 refines, so the task is flagged for the board's review.

## Result notes

Written by the agent when it finishes.

**Planned PixelLab calls and cost (written before any call, 2026-10-30).** The board's go: up to 50 generations for T-397 and T-399 together; this sample at most 8. Balance before: 4743 generations.

- Sidewalk tile with its curb: **0 generations**. Drawn by a free script (`game/tools/build_sidewalk_car_sample.py sidewalk`) in the buildings' own pavement colours (`build_creator_buildings_art.py` PAV), so it matches the pavement round the creator buildings; its refines in the style loop are script changes, no PixelLab.
- Parked car, top-right facing: **1 generation per round**, `/create-image-pixflux` 128 x 128 (`isometric`, `no_background`, `direction` north-east; request `art-archive/T-397/requests/car_v1.json`), then a free clean-up by script (`... car`: background, specks, at most 30 colours, a mirror if PixelLab faces it top-left). At most 4 rounds in the style loop: **up to 4 generations**.
- Total planned: **up to 4** (cap 8). 600 s HTTP timeout (the client's default).

- Added by the board (2026-10-30), the meteor crater: **0 generations planned**, drawn by the same free script (`... crater`) in the road's asphalt and the boulders' own rock and glow colours; its refines are script changes. The sample's cap rises to 10 for the three pieces; total planned stays up to 4.

Running total: 0 before the car; **1 after the car's round 1** (the only PixelLab call: `car_v1_raw`, usage 1 generation, `art-archive/T-397/raw/car_v1_raw.json`, the log line in `game/art/pixellab-generation-log.jsonl`); sidewalk and crater 0. **Total for T-397: 1 generation** (cap 10), so 49 of the 50 remain for T-399. Note: the account balance went from 4743 to 4735 over the same time; only 1 of those 8 is T-397's (the record's usage and the log); the rest are other sessions on the same account.

**What was made (all in `art-archive/T-397/`, nothing in `game/art/`):**

- **Sidewalk tile with its curb** `sidewalk_curb_se.png` (128 x 64, the road tiles' diamond, 13 colours): script-drawn, 0 generations. Slabs in the creator buildings' pavement greys; a low curb (3 art px, under the 0.1-unit rule) on the south-east edge, the road side, with a lighter stone top, a lit lip with highlight pixels, a darker face and a near-black gutter. Style loop: v1 6/10 (the curb did not read), **v2 8/10, kept** (Run 1).
- **Parked car, top-right facing** `parked_car_ne.png` (128 x 128, the player car's frame): a pale silver-grey four-door sedan, PixelLab pixflux (1 generation), PixelLab drew it facing top left, so the free clean-up mirrored it to top right (the raw is the top-left facing for T-399). Style loop: **v1 8/10, kept** (Run 2).
- **Meteor crater** `meteor_crater.png` (128 x 64 ground decal, transparent round it; added by the board): script-drawn, 0 generations. Style loop (Run 3): 5, 6, **7 (v3, kept)**, 7. **Still below 8 after 3 refines, so the loop flagged the task for the board's review** (status `flagged-for-review`, set by the style loop; I did not move it to in-qa). The evaluator's remaining reasons: the glow lacks stepped halos round the cracks, the rim and scorch bands are thin in shading, the far wall barely separates from the dark floor, and v3 partly reads as a dome or lid rather than a pit. My honest read: the crater is the weak piece; it reads as a dark ring with magenta cracks more than a hole, and is small on the road. Cheapest next step if the board wants it better: one PixelLab picture of a crater (1 to 2 generations) cleaned by the same script, or the board's notes on the shape.
- Note on the script: `draw_crater()` now draws v4 (the last refine, also 7/10), not the kept v3; v3's PNG is kept as `meteor_crater.png` and `style-loop/v3.png`. The sidewalk script reproduces the kept sidewalk pixel for pixel.

**Previews and screenshots** (`art-archive/T-397/screenshots/`): `preview_side_by_side.png` (dark and light, 3x nearest neighbour: the game's road tiles, the curb tiles against the road, plain sidewalk behind, the creator small building, boulder_a, the car parked at the curb and the crater on the road), `preview_dark.png`, `preview_light.png`, `preview_curb_zoom.png`, `tile_curb_zoom.png`, `crater_zoom.png` (the crater on asphalt, on sidewalk and alone, 6x). Each style-loop version has its own preview in `style-loop/<piece>_v<N>_preview/`.

**Files:** `game/tools/build_sidewalk_car_sample.py` (sidewalk, crater, car clean-up, preview), `game/tools/test_build_sidewalk_car_sample.py` (10 tests), `game/docs/art/sidewalk-parked-cars.md` (new, indexed in `game/README.md`), briefs in `art-archive/T-397/briefs/`, the request in `art-archive/T-397/requests/car_v1.json`, the loop logs `art-archive/T-397/style-loop-*.log`. The worktree got a copy of the git-ignored `.env` for the PixelLab key (as the goal runner does).

**Tests:** `python -m unittest discover -s game/tools -p "test_*.py"`: 678 tests OK (1 skipped).

**Refused:** during the crater loop the generator agent reported that the permission system refused its unit-test run (`python -m unittest game/tools/test_build_sidewalk_car_sample.py`); it did not work around it. I ran the tests myself afterwards, and fixed one assertion that no longer matched the refined crater's colours.

**Documents affected:** `docs/visual-style.md` (Decisions, "Sidewalks, parked cars and meteor craters", proposals for the board's review), `game/docs/art/sidewalk-parked-cars.md` (new), `game/README.md` (index line).

**For T-399:** the curb is only drawn on the south-east edge; the other three edges and corner pieces need the same face (on the north-west and north-east edges the face is hidden, so only the lit top edge and a dark seam show). Car facings: one picture per car gives two facings by mirror (top left/top right from one, bottom left/bottom right from another), so about 2 generations per car plus refines.

- 2026-10-30, in-progress → flagged-for-review: the style loop kept version 3 (score 7/10), still below 8 after 3 refines; every version is in its Style review
- 2026-10-30, flagged-for-review → done: The board OK'd the sample (2026-10-30): sidewalk + curb, parked car, meteor crater (the crater's 7/10 accepted). T-399 builds the full set from it.

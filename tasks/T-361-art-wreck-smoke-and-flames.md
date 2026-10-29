---
id: T-361
title: Art: pixel art smoke and flames for the wrecked car
status: cancelled
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-360]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/working-with-the-board.md, game/docs/art/pixellab.md, docs/game-loop-architecture.md]
files_expected_to_change: [game/art/, game/scripts/, game/tools/, art-archive/, docs/visual-style.md, game/docs/art/]
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

The board's decision (Game loop architecture, Decisions, "Wrecked: the stream keeps rolling", 2026-10-29): when the car loses its last heart it sits crashed for 3 seconds, **smoking and burning**. The board: "It'd be cool if it was like pixel art smoke. And I want to play test it directly with a pixel art smoke. I trust you to generate the animation with it ... Maybe it'd be really cool to add some flames as well."

Make two looping animations: **smoke** rising from the wrecked car (dark grey puffs that rise, grow and thin out) and **flames** licking up from it (small, flickering). They sit on the isometric car at the game's pixel scale, in the game's pixel rules (Visual style, Content, "Rules"; none of Greenbull's colours outside Greenbull's things, rule 6), and read against the grey street and the car's colours. Save them as frames or sheets in `game/art/` with a record, then swap them in for the behaviour ticket's placeholders.

**PixelLab: the board's go** (2026-10-29: "I trust you to generate the animation"), **up to 16 generations** for the two animations, no sample review (the board plays it directly with the behaviour ticket). Write the planned calls and their cost in the result notes before calling; 600 s timeout. A script-drawn animation is fine instead if it scores better. Every animation goes through the style loop (at most 3 refines).

The board's review: lose all your hearts and watch the car smoke and burn for 3 seconds.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/` holds a looping smoke animation and a looping flames animation with records, and they replace the behaviour ticket's placeholders on the wrecked car. (QA: pass / fail)
- [ ] Each animation scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] The PixelLab generations used are at most 16 and listed in the result notes, with the plan written before the first call. (QA: pass / fail)
- [ ] Visual style and the art docs under game/docs/art/ record the art. (QA: pass / fail)
- [ ] A contact sheet of the frames, enlarged, on a dark and a light background, and a GIF of the wreck in a run are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: pixel art smoke and flames for the wreck, the board's PixelLab go, up to 16 generations, style loop.

### 2026-10-29, Flagged for review → Cancelled

Cancelled as you asked. Not merged; the placeholder smoke and flames stay. The generated art stays on this ticket's branch, not deleted.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-29: art, brief `art-archive/T-361/briefs/smoke.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-361/style-loop/v1.png`
- Script checks: 41 of 41 pass
- Score: 4/10
- Reason: I could only view the sheet at its small native size, so this is judged from that view plus the script facts. The script rules pass (rules 1, 3 and 6). The weaknesses are in rules 2 and 4 and in the brief.

1. The sequence doesn't thin out. Opaque pixel counts go 796, 761, 719, 692, 658, 783, 729, 922. Frame 7 is the largest and densest, but the brief wants it to be only a few ragged wisps. The count also jumps back up at frame 5. The dense grey mass in the last frames looks like a separate blob rather than a puff breaking up. Fix by free script edits first: skip or reorder frames in build_wreck_fx.py, or drop the late dense frames. If the frames can't be fixed that way, make one new animate call with a stronger "breaks apart into small separate wisps" action and a new seed.

2. Rule 2: the puffs read as flat dark blobs with only 4 to 5 colours. I can't see a clear dark near-black outline broken by lighter top-left highlights, and the brief needs these to read against grey asphalt. Check that the outline is the darkest colour and that the highlight pixels survive the palette snap. Add a lighter highlight shade if it was lost.

3. Rule 4: some frames show warm orange or white spots near the bottom that read as flame or stray bits, not night smoke. The brief asks for smoke only and the fire is not part of it. Remove the orange and white pixels, or confine the faint warm glow to the underside as a drawn, stepped glow (rule 5).

Rules 1, 3 and 6 pass.
- Rules broken: 2, 4
- Refused: {"tool_input": {"command": "cat > art-archive/T-361/pixellab/smoke_ff_v1_req.json <<'EOF'\n{\"description\": \"a small dense puff of thick dark grey smoke, a round billowing cloud with a few bulges, lit softly from the top left, darker underside with a faint warm orange glow from a fire below, dark almost black selective outline, seen from a 3/4 view from above, retro pixel art, night\", \"negative_description\": \"fire, flames, car, ground, background, text, white, blue, green, yellow\", \"image_size\": {\"width\": 32, \"height\": 32}, \"no_background\": true, \"outline\": \"selective outline\", \"shading\": \"detailed shading\", \"detail\": \"highly detailed\", \"text_guidance_scale\": 8, \"seed\": 361001}\nEOF\npython game/tools/pixellab_client.py generate --endpoint create-image-pixflux --params-file art-archive/T-361/pixellab/smoke_ff_v1_req.json --out-dir art-archive/T-361/pixellab/smoke --name smoke_ff_v1 --consulted docs/visual-style.md --consulted docs/extended-narrative.md --consulted docs/game-loop-architecture.md --task T-361 2>&1 | tail -15", "description": "Generate the smoke first frame via PixelLab", "timeout": 600000}, "tool_name": "Bash", "tool_use_id": "toolu_016dLNcstqHzPqB2CAvDBtRD"}; {"tool_input": {"command": "python game/tools/build_wreck_fx.py first-frame smoke art-archive/T-361/pixellab/smoke/smoke_ff_v1.png art-archive/T-361/pixellab/smoke/smoke_first_v1.png --req art-archive/T-361/pixellab/smoke_anim_v1_req.json --seed 361002 --action \"the puff of dark grey smoke billows outward and grows bigger, then thins and breaks apart into a few small ragged wisps that drift apart and vanish; the last frame is only a few small wisps\" 2>&1 | tail -10; python -c \"\nfrom PIL import Image\nfor n in ['smoke_ff_v1','smoke_first_v1']:\n  im=Image.open(f'art-archive/T-361/pixellab/smoke/{n}.png').convert('RGBA'); w,h=im.size\n  bg=Image.new('RGBA',(w,h),(40,40,48,255)); bg.alpha_composite(im); bg.resize((w*8,h*8),Image.NEAREST).save(f'C:/Users/andre/AppData/Local/Temp/{n}_big.png')\n\"", "description": "Build first frame and preview enlarged"}, "tool_name": "Bash", "tool_use_id": "toolu_01B91xtCqy4PVBR1K4cacD5C"}; {"tool_input": {"command": "python art-archive/T-361/pixellab/preview.py art-archive/T-361/pixellab/smoke/smoke_first_v1.png art-archive/T-361/pixellab/smoke/preview_first_v1.png 8", "description": "Make enlarged preview of first frame"}, "tool_name": "Bash", "tool_use_id": "toolu_01VhVXMTg5WzXz63kjLLe65m"}; {"tool_input": {"command": "rm art-archive/T-361/pixellab/preview.py && python -c \"from PIL import Image; im=Image.open('art-archive/T-361/style-loop/v1.png'); print(im.mode, im.size)\"", "description": "Remove unused scratch script and confirm PNG format"}, "tool_name": "Bash", "tool_use_id": "toolu_01GVpN1A3oE9wf3m2MAqtGVf"}

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-29: art, brief `art-archive/T-361/briefs/smoke.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-361/style-loop/v1-2.png`
- Script checks: 41 of 41 pass
- Score: 5/10
- Reason: Rule 1 passes by script (all frames 48x48, no semi-transparent pixels, at most 9 colours), and rule 6 is clean. The art breaks two things.

Rule 2 (outline and shading, detail): at 8 colours or fewer, the early puffs read as smooth, round dark blobs. The dark outline is hard to tell from the dark grey fill. There are few lighter top-left highlight pixels, and the brief says they are needed for the puff to read against the grey asphalt. There is no chunky, cloud-like edge detail (lobes, notches). The warm underside light is a thin orange smudge at the bottom of the first frames. Fix: give the puff lobed, cauliflower edges. Keep a near-black outline broken by pale-grey highlight pixels on the top-left. Add a clear mid-grey shade band and a stepped warm underside with 2 to 3 shades.

Brief and sequence (supports rule 2 and the retro look): the puff does not grow. Opaque pixel counts fall steadily (442, 428, 342, 237, 115, 61, 19, 3), so it only shrinks and fades away. The brief asks for small and dense at frame 0, growing bigger, then breaking into ragged wisps. Frames 6 and 7 are nearly empty (19 and 3 pixels, 2 and 1 colours), so the last third of the life shows almost nothing. Frame 0 is already as big as it gets. Fix: start frame 0 smaller, grow it through frames 1 to 3, then break it into several chunky multi-pixel wisps, each with outline and highlight. Frames 6 and 7 should keep a few readable wisps, not single specks.
- Rules broken: 2
- Refused: {"tool_input": {"command": "python game/tools/build_wreck_fx.py draw smoke art-archive/T-361/pixellab/smoke/smoke_first_v2.png --frame 2 --req art-archive/T-361/pixellab/smoke_anim_v2_req.json --seed 361003 --action \"the puff of dark grey smoke billows outward and grows bigger, then thins and breaks apart into a few small ragged wisps that drift apart and vanish; the last frame is only a few small wisps\" && python game/tools/build_wreck_fx.py dump art-archive/T-361/pixellab/smoke/smoke_first_v2.png 2>&1 | head -60; python -c \"import json;d=json.load(open('art-archive/T-361/pixellab/smoke_anim_v2_req.json'));print({k:(v if len(str(v))<200 else '...') for k,v in d.items()})\"", "description": "Draw first frame and request"}, "tool_name": "Bash", "tool_use_id": "toolu_013EdQjq8zixjoeXLeBSSv6o"}; {"tool_input": {"command": "python game/tools/build_wreck_fx.py sheet --help 2>&1 | tail -15; python -c \"\nfrom PIL import Image\nimport sys\nfor i in range(9):\n    im=Image.open(f'art-archive/T-361/pixellab/smoke/smoke_anim_v2_{i}.png').convert('RGBA')\n    a=im.getchannel('A'); px=list(a.getdata())\n    op=sum(1 for v in px if v>0); semi=sum(1 for v in px if 0<v<255)\n    print(i, 'opaque',op,'semi',semi,'bbox',a.getbbox(),'colours',len(set(p for p in im.getdata() if p[3]>0)))\n\"", "description": "Sheet help and per-frame stats"}, "tool_name": "Bash", "tool_use_id": "toolu_0156w3AryzFox6SpeWiHKV4f"}; {"tool_input": {"command": "python art-archive/T-361/style-loop/preview_tool.py art-archive/T-361/style-loop/v1-2.png art-archive/T-361/style-loop/v1-2_preview.png 4", "description": "Render enlarged preview"}, "tool_name": "Bash", "tool_use_id": "toolu_01A3gPo4hD2S1CVE5qCPjFh4"}

#### Round 2

- Version 2: `art-archive/T-361/style-loop/v2.png`
- What changed: Version 2 is the free, fully script-drawn sheet (`python game/tools/build_wreck_fx.py draw smoke <png> --sheet`). It uses no PixelLab frames and no new generation: this run has still spent 1 of its 4 generations (smoke_anim_v2, from version 1), so 3 are left. I rewrote `draw_smoke` in game/tools/build_wreck_fx.py to fix each point in the reason:
(1) Growth: frame 0 is now a small, dense puff about 11 px across. It grows through frames 1 to 3 to about 28 px, then breaks up. Opaque pixels per frame are 102, 225, 387, 600, 612, 370, 262, 178, where version 1 only shrank.
(2) Lobed cauliflower edges: the puff is built from 10 overlapping lobes. Each lobe is shaded from the top left on its own, so the edges have lobes and notches, and a darker crease shows where one lobe tucks under the lower right of another.
(3) Outline and highlights: every piece has a near-black outline (24, 22, 30), broken on its top-left arc by pale-grey (170, 170, 180) highlight pixels. Just inside the outline on the top left runs a rim of light, with clear light-to-mid-to-dark grey bands from 6 greys.
(4) Warm underside: the fire's light is drawn in 3 steps, dim brown to bright warm orange (a new palette colour, 176, 112, 70, far from Greenbull's yellow), brightest at the bottom and following the curve of the lower lobes. It is strongest at birth and gone by frame 5, as the smoke rises away from the fire.
(5) Break-up: from frame 4 the middle thins away first and the outer lobes drift apart as 4 to 5 chunky wisps. Each wisp keeps its outline, a highlight and 2 to 3 shades. Frames 6 and 7 still show 5 readable wisps of about 20 to 40 pixels each, not single specks.
Checks: `style_rules.py --size 48x48 --frames 8` passes everything (7 to 10 colours per frame, no semi-transparent pixels, none of Greenbull's colours). game/tools/test_build_wreck_fx.py passes 18 tests (1 skipped: the game sheet isn't made yet). I added two tests: the last frames keep 3 or more wisps, each with an outline and a lit top left; and every frame has highlights, with the warm underside in 2 steps at frame 0, 3 steps in frames 1 to 3, and none at the end.
Version 1 (v1-2.png) is untouched. A stray helper I wrote, art-archive/T-361/style-loop/preview_tool.py, was never run (the run refused it) and can be ignored.
- Script checks: 41 of 41 pass
- Score: 7/10
- Reason: The sheet passes the script checks: 48x48 frames, 7 to 10 colours per frame, no semi-transparent pixels, no Greenbull colours. Rules 1, 3, 4, 5 and 6 are fine. The warm underside is stepped, not blurred. The puffs sit in the sheet's lower half and have a dark outline with lighter top-left highlights, which suits rule 2.

The sequence also does what the brief asks. Frame 0 is small and dense, frames 3 and 4 are the biggest, and frames 5 to 7 break into separate chunks.

Rule 2 is the weak spot. I could only view the image small, so this is a judgement from a rough look. The puffs read as tight, rounded lumps of dark rock with little interior shading. Frames 0 to 2 are close to plain dark blobs. To fix it, add more mid-tone and highlight clusters inside the bigger puffs (frames 2 to 4) and break the outline with a few lighter pixels. Make the silhouette lumpier and more billowy.

The last frames (5 to 7) are mostly small round dots scattered about, not the ragged wisps the brief describes. They look like debris or pebbles. Make the pieces irregular and stretched upward, and keep a darker outline on them.

The brief's intent that the smoke read against grey asphalt is not clearly met, because the grey fill is dark and the highlights are faint. Lift the highlight tone a step.
- Rules broken: 2
- Refused: {"tool_input": {"command": "cd /c/solid-carbide-worktrees/T-361/game/tools && python -m unittest test_build_wreck_fx -v 2>&1", "description": "Run wreck fx tests"}, "tool_name": "Bash", "tool_use_id": "toolu_01UVjRdpyh21Jmdi1jsGEJGA"}; {"tool_input": {"command": "python C:/solid-carbide-worktrees/T-361/game/tools/test_build_wreck_fx.py -v", "description": "Run wreck fx tests"}, "tool_name": "Bash", "tool_use_id": "toolu_012xfa7sNj6ruD8iX5vRJa6D"}

#### Round 3

- Version 3: `art-archive/T-361/style-loop/v3.png`
- What changed: Version 3 is still the free, script-drawn sheet (`python game/tools/build_wreck_fx.py draw smoke <png> --sheet`), with no new PixelLab generation. This run has spent 1 of its 4 (smoke_anim_v2, used only in version 1), so 3 are left. Changes to `draw_smoke` / `smoke_lobes` in game/tools/build_wreck_fx.py, against each point in the reason:
(1) Lifted highlights, so the smoke reads against the grey asphalt: I added a palest grey (206, 206, 214) and moved the whole tone ladder up one step (shadow to highlight: 42, 60, 82, 108, 138, 170, 206). The top-left halves of the puffs are now 138 to 206 greys, well above the asphalt's ~80. Pale 206 pixels break the near-black outline along the top-left arc, about every other pixel, and a 170 rim runs just inside it.
(2) More shading inside the big puffs (frames 2 to 4): each lobe is now lit mostly from its own top left (0.8 lobe, 0.4 whole puff). The big puffs show several separate clusters of light-grey cap, a mid-grey body and dark lower right, with darker creases where the lobes tuck under each other, instead of one smooth gradient.
(3) Lumpier, more billowy silhouette: every lobe's edge wobbles with its angle (5 and 9 bumps per lobe), so the outline has bulges and notches.
(4) Ragged wisps stretched upward, not round dots: from frame 4 the middle thins away. Each of the 4 outer groups pulls together into one chunky wisp, about 6 to 9 px wide and 12 to 15 px tall, stretched upward. Each trails a narrower tail lobe above, leaning to one side, and its edges wobble more as it breaks up. A 3x3 opening removes 1- and 2-pixel slivers, so no piece is outline only. Every wisp keeps its dark outline, a pale top-left and 3 to 4 greys.
(5) The warm underside: still 3 steps (96,66,58 / 138,86,62 / 176,112,70) curving along the lower lobes in frames 0 to 4, and gone by frame 5, as the smoke rises away from the fire.
Opaque pixels per frame: 102, 220, 387, 598, 679, 487, 377, 292. It is small and dense at birth, biggest at frames 3 and 4, then breaks into 4 ragged wisps that are still readable at the end.
Checks: `style_rules.py --size 48x48 --frames 8` passes all (8 to 11 colours per frame, no semi-transparent pixels, none of Greenbull's colours), and test_build_wreck_fx.py passes 19 tests (1 skipped). I changed one existing test on purpose: the thinning check now asks that frame 7 is under half of frame 3 and smaller than frame 5, where it used to ask for under a third, because the chunkier wisps the evaluator asked for hold more pixels. I added a test that the end wisps are taller than they are wide.
Versions v1-2.png and v2.png are untouched.
- Script checks: 41 of 41 pass
- Score: 6/10
- Reason: The sheet passes the script checks for rule 1, rule 3 (size) and rule 6. It is 8 frames of 48x48, fully opaque or transparent, with 8 to 11 colours and no Greenbull colours. The broken rules are about look, and I could only see the sheet at about 1x, so these points are less certain.

Rule 2: frames 0 to 4 are round clumps with a dark outline and a clear top-left highlight, but the shading is faceted and lumpy. It makes them read as grey rocks or boulders rather than smoke. Smoke needs billowing, irregular cloud lobes with softer stepped tone bands. Break the near-circular silhouette into 3 to 5 distinct bulges. Cut the speckled, rock-like internal texture. Use fewer, larger shade steps.

Rule 5 and the brief: the warm fire light is a brown or orange strip along the bottom of frames 0 to 4. It reads as a flat rim or base, like a rock sitting on a ground, not as light on the puff. Draw it as a few stepped orange pixels with darker halos on the underside edge only. Remove it from the thinned frames, or let it fade out across frames 5 to 7.

Brief (thinning): frames 5 to 7 break up into separate arcs and short vertical shards, not a puff that thins out. Frame 5 looks like a ring of fragments. Keep the dark outline and top-left highlight on the remaining wisps. Make them rise and tilt like curls, not upright slivers, so the sequence reads as smoke dispersing.

Rule 8 risk: the dark grey faceted chunks resemble the boulders, though without glowing cracks. The smoke needs to look clearly different from the boulders.
- Rules broken: 2, 5
- Refused: {"tool_input": {"command": "python game/tools/style_rules.py art art-archive/T-361/style-loop/v3.png --size 48x48 --frames 8 | python -c \"import json,sys; r=json.load(sys.stdin); print(all(c['ok'] for c in r), [c['detail'] for c in r if 'colours' in c['check']])\"", "description": "Check v3 rules, summarised"}, "tool_name": "Bash", "tool_use_id": "toolu_012vwbrcjqgU9ieJBJdkBpcE"}

#### Round 4

- Version 4: `art-archive/T-361/style-loop/v4.png`
- What changed: Version 4 is the third and last refine. It is still free and script-drawn (`python game/tools/build_wreck_fx.py draw smoke <png> --sheet`), with no new PixelLab call: this run has spent 1 of its 4 generations in total (smoke_anim_v2, used only in version 1). I rewrote the shape, shading and warm light in `smoke_lobes` / `draw_smoke`, against each point in the reason:
(1) Cloud, not rock (rule 2 and the rule 8 risk): the speckle jitter, the dark creases between lobes and the edge wobble are all gone, since they made the faceted, rocky texture. The inside now uses a few broad bands over the whole piece (60, 82, 108 and 138 greys, from the top left), and each bulge gets one smooth bright cap on its own top left (170, then 206 at the very top). The puff reads as rounded billows, lighter overall (mostly 108 to 170 grey), and the brightest pixels are on top, the opposite of the dark boulders.
(2) Silhouette: a smaller middle lobe and outer lobes pushed outward give 5 clear bulges (left, top left, top, top right, right) over a rounded bottom, instead of a near-circle. The near-black outline is still broken by pale 206 pixels, every other pixel along the top-left arc.
(3) Warm light (rule 5): the bottom strip is gone. The fire's light is now a short stepped glow on the underside edge only: the lowest inside pixel of each column near the middle, with bright orange (176, 112, 70) in the centre, then (138, 86, 62), then a dim (96, 66, 58) at the ends and as a darker halo pixel above each bright one. It is about 4 to 8 pixels wide, strongest in frames 0 to 3, smaller in frame 4, and gone from frame 5 on.
(4) Thinning: frame 5 is now still one thinning puff, opened by holes, with its lower lobes coming apart, not a ring of pieces. In frames 6 and 7 the four outer groups become curls: short chains of circles that rise from a base and lean or hook over outward (left ones to the left, right ones to the right), not upright slivers. Each keeps its dark outline, a pale top-left and 3 to 4 greys.
Opaque pixels per frame: 93, 209, 362, 563, 571, 424, 291, 254. It is small and dense at birth, biggest at frames 3 and 4, then thins steadily.
Checks: `style_rules.py --size 48x48 --frames 8` passes all (7 to 10 colours per frame, no semi-transparent pixels, none of Greenbull's colours). test_build_wreck_fx.py passes 20 tests (1 skipped). I replaced last version's "wisps taller than wide" test with one that the end curls rise at least 8 px and lean at least 2 px. I added a test that the warm light is a small glow (under 10% of a frame's pixels, and narrower than 60% of the puff), not a rim-to-rim strip.
Earlier versions (v1-2, v2, v3) are untouched. If this still scores under 8, the loop has no refines left, so it goes to the board as is. 3 paid generations remain within the board's go for this run.
- Script checks: 41 of 41 pass
- Score: 6/10
- Reason: The technical side is clean. Rule 1 passes: 8 frames of 48x48, transparent background, 0 semi-transparent pixels, 7-10 colours. Rule 6 passes: no Greenbull green or yellow. The sheet does what the brief asks: a small dense puff grows over frames 0-4, then breaks into chunky wisps in frames 5-7, with a dark outline and light top-left highlights.

Rule 2 is the weak point, and it is a style problem, not a count. Frames 2-4 are round, lumpy, faceted grey blobs with a hard dark rim and a flat highlight patch. They read as small boulders or rubble, not as billowing smoke. Rule 8 reserves rock for the alien things (dark rock with glowing cracks), so smoke that looks like rock blurs two looks.

How to fix it, with no paid call:
- Break up the rim of frames 1-4. Use an irregular, cauliflower-like edge with several lobes, and leave gaps in the outline.
- Make the shading less rock-like. Use two or three stepped greys, and keep the highlight as a few lighter pixels on the upper-left lobes instead of one facet.
- Make the fire's warm underside bolder. It is barely visible, and it would also help the night mood (rule 4) and the drawn glow (rule 5).

Other notes:
- Frame 7 is only a few tiny scattered flecks, so it will be hard to read at 0.5 scale. Make the wisps slightly bigger and chunkier.
- Frame 0 is very small.
- Frames 3 and 4 look almost the same, so the growth stalls before the thinning starts.
- Rules broken: 2, 8

**Kept:** version 2, score 7/10 (`art-archive/T-361/style-loop/v2.png`, copied to `game/art/effects/wreck_smoke.png`): still below 8 after 3 refines, so the task is flagged for the board's review.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-29: art, brief `art-archive/T-361/briefs/flames.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-361/style-loop/v1-3.png`
- Script checks: 41 of 41 pass
- Score: 7/10
- Reason: The sheet passes the script checks: 48x48 frames, 8 colours, no semi-transparent pixels, and no Greenbull light green or yellow (rules 1, 3, 6). Visually it fits rule 5, glow drawn and not rendered. Each frame is a small flame with a white-hot core, stepped orange bands and a dark red rim, and there are no blurs or halos. The base is flat and sits at the bottom centre. The flames are small, with a few embers and no logs, ground or smoke. The loop from frame 7 back to frame 0 looks continuous. I saw the sheet only at its native 384x48 size, so these judgements are less certain than usual. Weaknesses are minor. (1) The flicker is shallow: the frames are near copies of one tongue shape, with frames 3 and 6 mostly just smaller. Add more variation in tongue count, split and lean, so it reads as licking flames and not as pulsing. (2) The inner bands read as smooth gradients. Make the steps crisper and keep the rim a clear dark red. Rule 2's near-black outline does not suit fire, so I did not penalise it. (3) The embers are sparse and faint. Add a few clearer ones, still as single hard pixels. No rule is clearly broken. The one rule 2 and 5 point is crisper stepped shading and more varied frames.
- Rules broken: 2
- Refused: {"tool_input": {"command": "Get-ChildItem -Recurse art-archive/T-361 -ErrorAction SilentlyContinue | Select-Object FullName,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 300; git status --short; git log --oneline -3", "description": "Check the existing T-361 archive and repo state"}, "tool_name": "PowerShell", "tool_use_id": "toolu_019pZiFqaGSxq5sYd2RYajv5"}; {"tool_input": {"command": "mkdir -p /tmp/t361 && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-361/pixellab/flames/flames_first_v1.png').convert('RGBA')\ns=8\nbig=im.resize((im.width*s,im.height*s),Image.NEAREST)\nout=Image.new('RGBA',(big.width*2+16,big.height),(0,0,0,0))\nd=Image.new('RGBA',big.size,(40,44,52,255)); d.alpha_composite(big)\nl=Image.new('RGBA',big.size,(220,220,220,255)); l.alpha_composite(big)\nout.paste(d,(0,0)); out.paste(l,(big.width+16,0)); out.save('/tmp/t361/first.png')\n\"", "description": "Enlarge the first frame on dark and light backgrounds"}, "tool_name": "Bash", "tool_use_id": "toolu_018gSaZJMTJj1oBGsMKPuTe7"}; {"tool_input": {"command": "ls tools/art_preview.py game/tools/art_preview.py 2>/dev/null; python tools/art_preview.py --help 2>/dev/null || python game/tools/art_preview.py --help", "description": "Show art_preview usage"}, "tool_name": "Bash", "tool_use_id": "toolu_01C3bGdqYrDx2Wi4HQWyW2d2"}

#### Round 2

- Version 2: `art-archive/T-361/style-loop/v2-2.png`
- What changed: Version 2 is fully drawn by script with no PixelLab call; it uses `build_wreck_fx.py draw flames --sheet` after I tuned `draw_flames`. This run's PixelLab use is still the 1 generation from version 1, so 5 of the 6 are left. The sheet passes every check in style_rules.py (`--size 48x48 --frames 8`): 7 colours, no semi-transparent pixels, no Greenbull light green or yellow. It's 384 x 48, 8-bit RGBA.

Fixes for each point in the reason:
1. **Shallow flicker.** Five tongues now grow and shrink a lot (66% to 100% of their height). Their tips bend left and right on the loop, and small licks break off a tip as it falls back. The frames are no longer near copies:
   - frame 0: low, three points
   - frame 1: one tall spire
   - frame 2: split, with licks breaking off
   - frame 3: leaning right
   - frame 4: two horns
   - frame 5: tall, leaning left
   - frame 6: split
   - frame 7: a right-hand tongue
   
   Every term repeats over the 8 frames, so frame 7 flows back into frame 0 at the same step size as any other pair (a test checks that frame 8 equals frame 0).
2. **Smooth inner bands.** I removed the random dither. The bands now step one colour per pixel of depth in from the edge, with no blur. The order is a 1-pixel dark red rim (122, 24, 24) on every edge, then red (176, 38, 26), three orange steps, pale orange, and the white-hot core (255, 242, 222). Height caps keep the white core on the base and cooler colours in the tongue tips.
3. **Faint embers.** There are now three embers. Each is a hard pale-orange pixel over a red one, rising from the tips and dimming as it climbs. An ember the fire would cover moves aside instead of disappearing.

Kept from version 1: the base is flat at the bottom centre, it's small (hood fire, not a bonfire), it has no logs, ground or smoke, and it stays inside the 8-colour fire palette.

Tests: three new ones in `game/tools/test_build_wreck_fx.py` (rim and stepped bands, lean and loop, bright embers). All 24 tests pass, with one skipped because the game-ready sheet doesn't exist yet.

The enlarged preview is at `art-archive/T-361/pixellab/flames/v2-2_preview.png`. Rejected drafts from tuning (try1 to try4) are kept in the same folder.
- Script checks: 41 of 41 pass
- Score: 8/10
- Reason: The 8 frames read as small car-fire flames: a pale white-hot core at the base, stepped orange and red rims, a dark red edge, and a few single-pixel embers. Rule 1 passes (7 colours, hard edges, transparent background). Rule 5 passes: the glow is drawn as stepped bands with no blur. Rule 6 passes: the oranges are fire colours, with no Greenbull yellow or light green. Rule 4 is fine; the warm fire suits the night. Rule 2 is only loosely met. The outline is a dark red rim, not near-black, which suits fire, but with 7 colours there is little shading and few highlight breaks. The art is also quite flat and uniform from frame to frame, with similar tongue shapes in several frames (frames 1, 2 and 5). To raise it, add one more shade step inside the tongues and vary the tongue silhouettes more between frames. Check that frame 7 loops cleanly back to frame 0 (the base should stay identical). I could only view the sheet at its native 384 x 48 size, so this is judged at that scale.
- Rules broken: 2
- Refused: {"tool_input": {"command": "python - <<'EOF'\nEOF\necho", "description": "No-op"}, "tool_name": "Bash", "tool_use_id": "toolu_01HLm7FY2LMDryq38w5XbvmR"}; {"tool_input": {"command": "python -m unittest game/tools/test_build_wreck_fx.py 2>&1 | tail -15", "description": "Run the wreck FX tests"}, "tool_name": "Bash", "tool_use_id": "toolu_013c5sHBJsJFJDGJ2kEj5ayu"}

**Kept:** version 2, score 8/10 (`art-archive/T-361/style-loop/v2-2.png`, copied to `game/art/effects/wreck_flames.png`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.

### Plan and cost (written before the first PixelLab call)

The board's go: up to 16 generations for both animations. Each animation runs through its own style loop run (`tools/style_loop/run.py art`), one-row sheets of 8 frames of 48 x 48 art pixels (drawn at 0.5 like the rest of the world), checked with `--size 48x48 --frames 8`.

- **Smoke** (one puff's life: born small and dense, billows and grows, then thins and breaks into wisps; the code moves and spawns the puffs): version 1 = 1 `create-image-pixflux` call (the first frame, a dense dark grey puff) + 1 `animate-with-text-v3` call (8 frames from it) = **2 generations**. A refine is a free script fix first (`game/tools/build_wreck_fx.py`: palette snap, alpha, framing, specks); only if the reason needs new drawing, a paid regeneration of at most 2 generations. At most 4 versions: **at most 8 generations**.
- **Flames** (a looping flicker licking up from the car): the same, version 1 = 1 pixflux + 1 animate = **2 generations**, paid refines at most 2 each: **at most 8 generations**.
- Total: **at most 16**, expected 4 to 8. 600 s HTTP timeout (the client's default). Raw output in `art-archive/T-361/pixellab/`, every loop version in `art-archive/T-361/style-loop/`.

**Plan change after smoke run 1 (before any further call):** the PixFlux first frame came back as a whole night scene (sky, a tree, ground), not a puff; round 1 scored 4/10 and I stopped the run once round 1 was recorded, before its refine could spend more (2 generations spent; the refine had only written `smoke_ff_v2_req.json`, never sent). From here no PixFlux: the first frames are drawn by script (`build_wreck_fx.py draw`, the meteors' way, T-070) and PixelLab only animates them. Smoke run 2: version 1 = 1 animate call, refines free first (frame choice, or the fully script-drawn sheet), at most 4 generations in the run (smoke at most 6 in all). Flames run 1: the same, at most 6. New total cap: **at most 12**.
- 2026-10-29, in-progress → flagged-for-review: the style loop kept version 2 (score 7/10), still below 8 after 3 refines; every version is in its Style review
- 2026-10-29, flagged-for-review → cancelled: The board (2026-10-29): smoke and flames art: cancel that ticket and close it, dont merge. im happy with the current state of the smoke.

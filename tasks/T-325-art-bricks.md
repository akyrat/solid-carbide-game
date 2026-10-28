---
id: T-325
title: "Art: the Bricks card image and the impact wave"
status: done
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-324]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/weapons.md, game/README.md, docs/working-with-the-board.md]
files_expected_to_change: [game/art/weapons/, art-archive/T-325/, docs/visual-style.md, game/README.md]
model: opus
qa_rounds: 1
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

The board's decision (Weapons, Decisions, "Bricks", 2026-10-28). Make Bricks' final art and swap it in for T-324's placeholders: the level-up card image (64 x 64, like the other weapons' card images, T-174: a stack of bricks, perhaps in a car's boot, a proposal) and the impact wave on landing (a ground ring with dust and brick chips, in the City's colours, never in Greenbull's colours), in the game's pixel rules (Visual style, Content, "Rules"). Every asset goes through the style loop.

**PixelLab needs the board's go for this ticket before any generation** (docs/working-with-the-board.md, "Art and money"). Try free script work first (the wave may be drawn by script well enough); if PixelLab is needed, write the planned calls and their cost in the result notes and wait for the go. Sample first: the card image alone for the board's review, then the wave.

The board's review: look at the Bricks card and a landing wave in a run.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The card image and the wave art are in game/art/weapons/ and replace T-324's placeholders in the game. (QA: pass)
- [ ] Each asset scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass)
- [ ] The PixelLab generations used are within the board's go and listed in the result notes (or none, if all script work). (QA: pass)
- [ ] Visual style and game/README.md record the art. (QA: pass)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-325/screenshots/`, as `tasks/README.md`, "Screenshots", asks. The card on the level-up screen and a GIF of the wave. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the board approved Bricks (T-324) and gave the go for the art. Card first, then the wave, script work before PixelLab, up to 8 generations.

### 2026-10-28, Needs playtest → Done

The board approved it; merging to master next.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-28: art, brief `art-archive/T-325/briefs/card.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-325/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The version fits the rules and I found no rule it clearly breaks. It is a neat stack of terracotta bricks seen from a 3/4 view from above, with the top and one side showing. The shading goes from lit tops to darker side faces, and there is a dark outline. The background is transparent and the edges are hard. A little rubble sits at the base, and the picture has no car. The colours are brick browns, not red or orange, with pale mortar and rubble, and the script check found no Greenbull colours (rule 6). The script checks pass: 64x64, 28 colours, no semi-transparent pixels. It reads as a night-friendly retro game icon. It has no brands or words. The preview I could view is very small, so my judgement of the finer detail is limited. Two minor points, neither enough to fail it. Rule 2: the outline is mostly solid, with few lighter highlight pixels breaking it. The bricks could also show more lit edges and clearer mortar lines. If refined, brighten the top edges of the bricks with a few lighter terracotta pixels. Make the staggered rows more distinct, so the stack reads as a wall of bricks and not as cubes.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls tasks | grep T-325; cat tasks/T-325*.md | head -80; ls art-archive/T-325 2>/dev/null -R; cat game/art/level_up/weapon_molotov.json", "description": "Read task file and reference records"}, "tool_name": "Bash", "tool_use_id": "toolu_01CoixqRCYbN158dXzoSjQ5z"}; {"tool_input": {"command": "cd /c/solid-carbide-worktrees/T-325; ls tasks | grep T-325; ls -R art-archive/T-325; cat game/art/level_up/weapon_molotov.json", "description": "Read task file list and reference record"}, "tool_name": "Bash", "tool_use_id": "toolu_01Rc3B5WWZ6V2cuPrSEniEnC"}; {"tool_input": {"command": "mkdir -p art-archive/T-325/card art-archive/T-325/style-loop && cat > art-archive/T-325/card/card_v1_params.json <<'EOF'\n{\n  \"description\": \"a small neat stack of old clay bricks, four rows staggered like a brick wall, warm terracotta brown bricks with darker shaded side faces and lighter lit top edges, thin grey-white mortar lines between them, one loose brick leaning against the side of the stack, a chip broken off one corner, seen from a 3/4 view from above showing the top and one side, retro pixel art, game icon\",\n  \"image_size\": {\"width\": 64, \"height\": 64},\n  \"no_background\": true,\n  \"outline\": \"single color black outline\",\n  \"shading\": \"medium shading\",\n  \"detail\": \"highly detailed\",\n  \"text_guidance_scale\": 8\n}\nEOF\npython game/tools/pixellab_client.py --help 2>&1 | head -30; python game/tools/reduce_palette.py --help 2>&1 | head -30", "description": "Write params file and check tool help"}, "tool_name": "Bash", "tool_use_id": "toolu_014TQaz9JHp6AEnYmrNtX7ah"}; {"tool_input": {"command": "python game/tools/style_rules.py art art-archive/T-325/card/card_v1.png --size 64x64 2>&1 | tail -15; python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-325/card/card_v1.png').convert('RGBA'); im.resize((512,512),Image.NEAREST).save('art-archive/T-325/card/card_v1_x8.png')\na=[p[3] for p in im.getdata()]; print('partial alpha',sum(1 for x in a if 0<x<255),'colors',len(set(p for p in im.getdata() if p[3]>0)))\"", "description": "Run style rules and make enlarged preview"}, "tool_name": "Bash", "tool_use_id": "toolu_01R5aEY3B9MDXWt8iMtyokm2"}; {"tool_input": {"command": "python art-archive/T-325/card/preview.py art-archive/T-325/card/card_v1.png art-archive/T-325/card/card_v1_preview.png", "description": "Make enlarged preview and count specks"}, "tool_name": "Bash", "tool_use_id": "toolu_01C3Qqu6gFaRWnFbLc3wgHSg"}; {"tool_input": {"command": "cp -n art-archive/T-325/card/card_v1.png art-archive/T-325/style-loop/v1.png && python game/tools/style_rules.py art art-archive/T-325/style-loop/v1.png --size 64x64", "description": "Save version 1 into the style loop folder and recheck"}, "tool_name": "Bash", "tool_use_id": "toolu_01QkCHo8mjXFqoKJwSgM5Lym"}

**Kept:** version 1, score 8/10 (`art-archive/T-325/style-loop/v1.png`, copied to `game/art/level_up/weapon_bricks.png`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-28: art, brief `art-archive/T-325/briefs/wave.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-325/style-loop/v1-2.png`
- Script checks: 61 of 61 pass
- Score: 6/10
- Reason: The sheet is mostly on-style, but it is weak on rules 5 and 2, and I judged it from a downscaled view. Two grounds for this: I only saw the strip at 2000 px wide (the original is 4608 px), and it was not zoomed in.

What passes:
- Rule 1: the script checks pass. The frames are transparent, have no semi-transparent pixels, and use at most 12 colours.
- Rule 3: the ring is a flat isometric ellipse that grows over the frames, with the right frame size and 12 frames.
- Rule 6: no Greenbull colours.
- The colours are cool blue-grey and pale blue, which suits the City palette. Nothing is red, purple or magenta.

What to fix:
1. Rule 5 (glow). I can't see any bright ring glow or checker-dithered halo. The ring reads as a flat, matte, pale blue-grey band with a dark outline. Add a bright pale-white core on the ring's leading edge. Put a 1 to 2 step checker-dithered halo of darker pale blues just outside and inside it, kept inside the frame.
2. Rule 2 (outline and shading, detail). The dust puffs are rounded grey blobs with smooth two-tone shading. They look like small boulders, not dust. Give them a dark navy outline broken by lighter highlight pixels, ragged stepped edges and more shade steps. The brick chips are only a few tiny red-brown dots, and I can't see the navy outline on them. Make them bigger (at least 3 to 4 px), more numerous (they read as sparse), and outlined in navy with a lighter top-face highlight so they read as brick.
3. Rule 2 (detail, frames 7 to 11). The ring thins to a single one-pixel line, which is almost empty and lacks detail. Keep a visible dark outline plus a highlight band while it crumbles. Break the ring into stepped gaps and fall-away chips, as the brief says ("thins and crumbles away").
4. Rule 4 (night and retro). Nothing breaks it. A little more contrast against a dark road would help the pale-white pixels read at night.

None of this breaks rules 1, 3, 6, 7, 8, 9 or 10.
- Rules broken: 2, 5
- Refused: {"tool_input": {"command": "V=art-archive/T-325/style-loop/v1-2.png && python game/tools/build_bricks_wave.py build --radius 4 --out $V && python game/tools/build_bricks_wave.py preview --png $V --out art-archive/T-325/wave/preview_v1-2.png && python game/tools/style_rules.py art $V --frames 12 --size 384x246; python -c \"from PIL import Image; im=Image.open('$V'); print(im.mode, im.size)\"; cmp $V art-archive/T-325/style-loop/v1.png && echo same-as-v1", "description": "Build version 1 sheet, preview, and run style rules check"}, "tool_name": "Bash", "tool_use_id": "toolu_011VWzAHqcWQDsxx2G4uFAMS"}; {"tool_input": {"command": "V=art-archive/T-325/style-loop/v1-2.png && python game/tools/build_bricks_wave.py build --radius 4 --out $V && python game/tools/build_bricks_wave.py preview --png $V --out art-archive/T-325/wave/preview_v1-2.png && python game/tools/style_rules.py art $V --frames 12 --size 384x246; python -c \"from PIL import Image; im=Image.open('$V'); print(im.mode, im.size)\"", "description": "Build version 1 sheet, preview, and run style rules check"}, "tool_name": "Bash", "tool_use_id": "toolu_01VBfWebVeU62CwymH2tSPm7"}; {"tool_input": {"command": "V=art-archive/T-325/style-loop/v1-2.png && python game/tools/build_bricks_wave.py build --radius 4 --out $V && python game/tools/build_bricks_wave.py preview --png $V --out art-archive/T-325/wave/preview_v1-2.png && python game/tools/style_rules.py art $V --frames 12 --size 384x246", "description": "Build version 1 sheet, preview, and run style rules check"}, "tool_name": "Bash", "tool_use_id": "toolu_01QGQPbHMrj6gex3qU2s3uKP"}

#### Round 2

- Version 2: `art-archive/T-325/style-loop/v2.png`
- What changed: Version 2 fixes the four points in the reason by changing the free script game/tools/build_bricks_wave.py (no PixelLab call, nothing spent). The output is still deterministic, the same size (12 frames of 384x246) and has the same timing. Frames 1 to 6 use 15 colours each. Every check in `style_rules.py art` passes: transparent corners, no semi-transparent pixels, none of Greenbull's colours.

1. Glow (rule 5): the ring's leading edge now has a pure pale-white core about 2 px thick, and it stays white on the far half too. The band behind it steps glow-blue, then pale, then mid. Outside the ring there is a 2-step halo: a pale-blue checker, then a sparser mid-blue dot grid. Inside it there is a matching pale and grey checker. The halo stays inside the frame. As the ring stops, the halo drops a step at a time (2, 1, 1, 0, 0) instead of fading.
2. Dust (rule 2): each puff is now 5 lumps with ragged, stepped edges and 5 shade steps, lit from the top left: dust-white, light, mid, dark and a navy-grey shadow. The outline is navy, broken on the lit side by light dust pixels. Each puff has a few loose dust specks around it.
3. Brick chips (rule 2): there are now 24 chips instead of 10, spread around the ring. Most are 6x5 px and every third is 3x3. Each has a lit top face (a new light brick colour), front, side and shadow faces, and a full navy outline.
4. Crumbling, frames 7 to 11: the ring no longer thins to a 1 px line. The band stays 0.20 to 0.14 units wide, with its white core and navy outline. It breaks into 30 pieces whose gaps grow in steps (18% of each piece, then 36%, 54% and 72%). Small outlined ring fragments fall away into the gaps.
5. Night contrast: the white core is now brighter, (250, 252, 255).

Preview on dark and light ground: art-archive\T-325\wave\preview_v2.png. A 3x version is at art-archive\T-325\wave\preview_v2_x3.png.

Of the script's 10 tests, the 8 drawing tests pass. The 2 tests that need the committed in-game sheets in game/art/weapons/ fail for now, because those sheets are only built once the loop keeps a version.
- Script checks: 61 of 61 pass
- Score: 7/10
- Reason: I judged this from one view of the whole sheet scaled down to 2000 px wide. I did not inspect pixels at full size. The script checks all pass.

Rules 1, 3, 4, 6 and 7 are met. The art is true pixel art on a transparent background, the sheet has 12 frames at 384x246, and the palette is cool blue-grey and pale white with no Greenbull colours. The ring lies flat as the isometric ellipse and reads as night and retro.

Rule 2 is partly met. The ring bands have a dark outline broken by lighter highlight pixels, and the stepped crumble-away frames look good. Two details are weak:
1. The dust puffs look like smooth, round, shaded balls (grey spheres), not dust clouds. Give them a ragged stepped silhouette, with a dark outline broken by highlights and darker shade pixels on the underside.
2. The brick chips are only a few pixels each and look like dots, so the brick-brown and navy-outline read is lost. Make them 3-4 px chunks with an outline and one highlight pixel, so they read as bricks.

Rule 5 is weakly met. I couldn't confirm the ring's bright core and checker-dithered halo at this scale. The bands look like flat grey-blue lines, so make the bright edge and the stepped dithered halo clearly visible in frames 3-8.

None of these is a hard violation. Fixing the puff shapes, the chip size and the glow halo would reach 8 or more.
- Rules broken: 2, 5
- Refused: {"tool_input": {"command": "python -m pytest -q game/tools/test_build_bricks_wave.py 2>&1 | tail -15", "description": "Run the wave builder's unit tests"}, "tool_name": "Bash", "tool_use_id": "toolu_01UrgVK4tV3fkWzUSsuGZwcF"}; {"tool_input": {"command": "python -m pytest -q game/tools/test_build_bricks_wave.py", "description": "Run the wave builder's unit tests"}, "tool_name": "Bash", "tool_use_id": "toolu_016UNDjkCxLcCdMAoa2YYyBY"}

#### Round 3

- Version 3: `art-archive/T-325/style-loop/v3.png`
- What changed: Version 3 is the third free script fix to game/tools/build_bricks_wave.py (no PixelLab call, nothing spent). The output is still deterministic, with 12 frames of 384x246, the same timing and at most 15 colours. Every check in `style_rules.py art` passes. Version 2 was judged from a strip shrunk about 4.6x, where details 1 px wide disappear, so the glow, dust and chips are now drawn bigger in art pixels.

1. Glow (rule 5): while the ring travels, the pale-white leading core is wider (0.15 units, about 3 px at the ellipse's ends and 6 to 7 px at its sides). The band behind it widens from 0.26 to 0.34 units. Both halo steps are now about twice as wide, on both sides of the ring: a 0.13-unit pale-blue checker next to the ring, then a sparser 2x2-grid step out to 0.24 units. The halo is clipped so it stays inside the frame's margin. The halo stays at 2 steps for one more frame after the ring stops (2, 2, 1, 0, 0), and the band narrows more gently (0.26 down to 0.15 units).
2. Dust (rule 2): each puff is now a wide, low cloud of 8 uneven lumps, with wisps to the sides and on top, instead of a round ball. The edges are more ragged, in 7 angle steps with radii varying from 0.55 to 1.15. The shading is lit from above, with a checker-dithered step into a dark navy-grey underside. The navy outline is broken by light dust pixels on the lit side, and the loose specks are kept. The puffs are slightly smaller (6 to 10 px instead of 7 to 12).
3. Brick chips (rule 2): the chips are now 8x6 to 8x7 px chunks, and every third is 4x4 or smaller. Each has a lit brick-top face, front, side and shadow faces, one bright highlight pixel on its lit corner, and a full navy outline. There are still 24 chips.

The crumble frames (stepped gaps and falling pieces) and the colours are unchanged.

New preview option: `preview --frames 4-5` shows only those frames, as a close-up at full detail. Close-up of frames 4 and 5 at 2x: art-archive\T-325\wave\preview_v3_closeup_f4-5.png. Full strip: art-archive\T-325\wave\preview_v3.png.

Of the script's 10 tests, the 8 drawing tests pass. The 2 tests that need the committed in-game sheets in game/art/weapons/ fail for now, because those sheets are only built once the loop keeps a version.
- Script checks: 61 of 61 pass
- Score: 7/10
- Reason: I could only view the sheet downscaled (4608x246 shown at 2000x107), so fine pixel detail is a judgement from the overall look. The script checks all pass.

What fits the rules:
- The 12 frames read as one ring on the ground, drawn as the isometric ellipse, growing to full size at about frame 7 and then thinning and crumbling away (rule 3).
- The colours are the City's cool blue-grey, pale white and pale blue. There is no Greenbull green or yellow (rules 6 and 7).
- The background is transparent and the edges are hard (rule 1).
- There are no words or logos (rule 9).

Weaknesses to fix:
1. Rule 2 (outline, shading, detail): the dust puffs look like flat pale cones or triangles, and the chips are tiny orange-brown dots. Both look low in detail and shading. Give each puff a darker underside, a lighter highlight pixel and a stepped silhouette. Give each chip a navy outline, two brown shades and a highlight pixel. A dark inner ring line shows in the mid frames, but the outer ring has little outline contrast against the background.
2. Rule 5 (glow): I can't see a clear bright core with a checker-dithered halo on the ring. In the mid frames the ring looks like flat grey bands. Add an explicit bright pale-white core band, with a darker-blue checker-dithered halo on both sides, inside the ellipse.
3. Chips look orange rather than brick brown. Shift them to a darker, less saturated brown so they stay inside the City palette and are not mistaken for amber or a fire effect (rule 7).
4. The last two frames (10 and 11) are almost empty: a few dashes and specks. Keep them, but make the crumble fragments chunkier so they don't read as noise (rule 2).
- Rules broken: 2, 5, 7

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-28: art, brief `art-archive/T-325/briefs/wave.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-325/style-loop/v1-3.png`
- Script checks: 61 of 61 pass
- Score: 9/10
- Reason: No real rule break found. The script checks pass: 14 colours or fewer per frame, no semi-transparent pixels, transparent background, size 384x246, no Greenbull colours (rules 1, 3, 6). Rule 1: the pixel edges are hard, and the stepped frames are drawn at final size. Rule 2: the ring has a dark navy outline broken by white highlight pixels, with banded shading. The dust puffs are dithered and shaded, and the brick chips have a dark outline. Rule 3: the ring lies flat as the isometric ellipse, at the right scale. Rule 4: the cool-blue ring and dithered halo read as night on the dark background, and the pixel look is retro. Rule 5: the ring glow is bright white and pale-blue pixels with a checker-dithered halo inside the sprite, with no blur. Colours are cool blue-grey, white and pale blue, with grey dust and brown chips, so none of Greenbull's, the boulders' or any real brand's look appears (rules 6, 7, 8, 9). Minor notes only, not rule breaks: on a light background the outline and halo read a little heavy. The chips are small, about 6 to 8 art px, and the crumble frames are sparse, so they could be slightly bolder. No fix is needed.
- Rules broken: none
- Refused: {"tool_input": {"command": "cat art-archive/T-325/style-loop/v4.json; python -c \"from PIL import Image;i=Image.open('art-archive/T-325/style-loop/v1-3.png');print(i.mode,i.size)\"", "description": "Read v4 record and check PNG mode"}, "tool_name": "Bash", "tool_use_id": "toolu_016KWFchWVHJo9Wy75KGd9Do"}

**Kept:** version 1, score 9/10 (`art-archive/T-325/style-loop/v1-3.png`, copied to `game/art/weapons/bricks_wave_r4_0.png`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.

### Plan and cost (written before any call)

The board's go: up to 8 PixelLab generations for this ticket; the board said (2026-10-28) to go on without stopping for a sample sign-off. PixelLab balance before: 4769 of 5000 generations left.

- **Card image** (`game/art/level_up/weapon_bricks.png`, 64 x 64, where the screen reads every weapon's card image: `level_up_screen.gd` `WEAPON_ART`): PixelLab `/create-image-pixflux`, 64 x 64, `no_background`, black outline, like T-174's five card images. 1 generation per version, so at most 4 (version 1 and up to 3 refines in the style loop), each with `pixellab_client.py` (HTTP timeout 600 s). A free script fix (palette cut, speck clean-up) comes before any paid refine.
- **Impact wave** (`game/art/weapons/bricks_wave_r*.png`): drawn by a free script, no PixelLab: a one-row sheet of stepped frames per damage radius the tiers use, so the ring is drawn at its final size for every tier (never scaled). 0 generations.
- Planned total: 1 to 4 generations, within the go of 8.

### What was done

**PixelLab: 1 generation used** of the board's go of 8 (balance 4769 before, 4768 after). Everything else was free script work.

- **Card image:** `game/art/level_up/weapon_bricks.png` (record `weapon_bricks.json`), PixelLab `/create-image-pixflux` 64 x 64, `no_background`, black outline; the raw generation passed every script check (28 colours) and is used unchanged. Style loop Run 1: **8/10** at the first version, no refine. The evaluator's minor note, honestly: the bricks read a little like cubes rather than a staggered wall. The HUD's weapon icon reuses this image (`weapon_icons.gd`), so it changed too. Raw generation, params and record: `art-archive/T-325/card/`.
- **Impact wave:** drawn by the new free script `game/tools/build_bricks_wave.py` (no PixelLab). Style loop Run 2 (versions 1 to 3 scored 6, 7, 7: glow halo too faint, dust read as balls, chips too small) refined the script three times; a usage limit cut Run 2 off before its version 4 was scored, so Run 3 scored that same version unchanged (byte-identical, `v1-3.png` = `v4.png`): **9/10**, kept. No refine beyond the three Run 2 used. The script then built one sheet per tier radius: `game/art/weapons/bricks_wave_r4_0.png`, `_r4_8.png`, `_r6_0.png`, `_r7_8.png` (12 frames each, 32 art px per unit, shown at 0.5; records next to them). The kept 4.0 sheet is the one the loop scored, byte for byte. Every version and preview: `art-archive/T-325/style-loop/` and `art-archive/T-325/wave/`; briefs: `art-archive/T-325/briefs/`.
- **Swap-in:** `game/scripts/weapons/bricks.gd`, `BricksWave` loads the sheet for its radius and shows its frames in step with the old timing (0.05 s, 12 frames); T-324's code drawing stays only as the fallback for a radius with no sheet. The card needed no code change (the screen already loads `weapon_<id>.png`); the level-up test no longer lists Bricks as waiting for art.
- **Tests (new):** `game/tools/test_build_bricks_wave.py` (radii from `weapons.json`, names, timing against `bricks.gd`, ring growth, iso inverse, pixel rules, deterministic rebuild equal to the committed sheet); in `game/tests/unit/weapons/test_bricks.gd`: a sheet for every tier, the frames shown in order with none skipped, a wider sheet at tier 8. `test_level_up_screen.gd` now checks the Bricks card image like the other five.
- **Test counts (run one at a time, in the foreground):** `python -m unittest discover -s game/tools -p "test_*.py"`: 630 OK (1 skipped); `python -m unittest discover -s tools -p "test_*.py"`: 501 OK; `bash game/tools/run_tests.sh`: 1738 of 1738 passing.
- **Screenshots:** `art-archive/T-325/screenshots/bricks_card_level_up.png` (the Bricks card on the level-up screen, next to the wiper), `art-archive/T-325/screenshots/bricks_wave_landing.gif` (a landing on a rooftop from T-324's recording fixture, the wave hitting 12 minions), and stills `bricks_wave_frame_114.png`, `_118`, `_122`, `_126`.
- **Documents:** `docs/visual-style.md` (Decisions, "Bricks' art"), `game/README.md` (Weapons, Bricks: "Bricks' art"), and `docs/weapons.md` (Content, "Bricks", the Look line, which still described the placeholder; not in `documents_affected`, so listed here).
- **Refusals:** the PreToolUse hook refused one command of mine that began with `time` (it can't tell `time` won't write a ticket); I ran the command without `time`, as the refusal message suggested. In the loops the headless generator had some read-only Bash commands refused (listed in the Style review's "Refused" lines); none stopped its work.
- **For the board's playtest:** if the tiers' radii change in `weapons.json`, rerun `python game/tools/build_bricks_wave.py build` (the tests catch a missing sheet).

### QA (round 1)

qa_check.py: tests, documents and screenshots all pass. Every criterion passes: card and four wave sheets are in game/art (card in level_up/, where the screen loads it) and bricks.gd uses the sheets; card 8/10 and wave 9/10 with all rounds in the Style review; 1 PixelLab generation of 8; visual-style.md and game/README.md record the art; card screenshot seen (Bricks card on the level-up screen), GIF and stills present; test counts in the notes and new tests exist. Ticket file is well-formed.
- 2026-10-28, needs-playtest → done: The board approved it (2026-10-28).

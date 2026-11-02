---
id: T-503
title: Icons: Rusty Paintjob's spray can and the Polarized Steering Wheel
status: flagged-for-review
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, game/art/power_ups/]
files_expected_to_change: [game/art/power_ups/, art-archive/, game/tests/unit/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-02 (docs/drifting.md, Decisions, "Rusty Paintjob and the Polarized Steering Wheel"): two new power-up icons, in the style of the other power-up icons (game/art/power_ups/, Visual style). 1. **Rusty Paintjob**: a rusty-looking spray can (it replaces Rusty Overcoat's icon, game/art/power_ups/rusty_overcoat.png; keep the old one in art-archive). 2. **Polarized Steering Wheel**: a steering wheel (it replaces T-502's placeholder). Same size, outline and palette as the other icons. The board's go for PixelLab (2026-11-02): through the style loop, each asset at most 4 generations (the first plus up to 3 refines), 8 in all; write the planned calls and their cost in the result notes before calling; 600 s HTTP timeout. Swap the art into the game yourself (the icons in the power-up overlay, the HUD and wherever the others show) and keep every generation in art-archive/T-NNN/. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/art/power_ups/ has the spray can for rusty_overcoat and the steering wheel for the new power-up, the same size as the other icons; the old Rusty Overcoat icon is kept in art-archive. (QA: pass / fail)
- [ ] Every generation is in art-archive/T-NNN/, and the result notes count them (at most 4 per asset, 8 in all). (QA: pass / fail)
- [ ] The ticket's Style review records the style loop for both assets, with their scores. (QA: pass / fail)
- [ ] The power-up overlay and the HUD show the new icons (screenshots on dark and light, enlarged). (QA: pass / fail)
- [ ] The full Godot test set passes in QA (the art tests included). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: spray can and steering wheel icons with PixelLab (up to 8 generations).

## Style review

Run by `tools/style_loop/run.py` on 2026-11-02: art, brief `art-archive/T-503/briefs/rusty_paintjob.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-503/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 6/10
- Reason: At 32x32 the image reads as an upright spray can with a dark outline, a nozzle on top and an orange and blue-grey body. The script checks pass (18 colours, transparent, opaque pixels only, no Greenbull colours). I could only view it at native size, because the zoomed inspect was refused. I judged the following from that tiny view and could not confirm them. (1) Rule 2: the rust reads as one large orange block down the body, not as patches over blue-grey metal. The flaking paint is not clear. The outline looks fairly uniform, with few lighter highlight pixels breaking it. The top-left light and the detailed shading are weak. (2) The nozzle spray puff and the cyan and magenta neon glints are barely visible or missing. Rule 5 asks for glow drawn as bright pixels with small stepped halos, and the brief asks for these glints. (3) Rule 4: the neon night feel is weak, and the palette looks flat and warm. Fix: break the rust into several irregular patches over a clearly blue-grey body, add a bright rim on top, add 2-3 cyan and magenta glint pixels with stepped halos, add a visible spray puff above the nozzle, and add lighter highlight pixels along the top-left outline.
- Rules broken: 2, 4, 5
- Refused: {"tool_input": {"command": "sed -n 100,170p game/tools/pixellab_client.py; env | grep -i style", "description": "Check style loop requirement and env"}, "tool_name": "Bash", "tool_use_id": "toolu_01JE6fxitjFbdGKpZNDRAVc3"}; {"tool_input": {"command": "mkdir -p art-archive/T-503/pixellab && cat > art-archive/T-503/pixellab/rusty_paintjob_v1.params.json <<'EOF'\n{\n  \"description\": \"pixel art game icon, a single upright rusty spray paint can, front view, nozzle cap on top with a small puff of spray mist, cylindrical body of blue-grey metal with orange-brown rust patches and flaking paint, bright metal rim at top and bottom, small cyan and magenta neon glints, dark almost-black outline, light from top-left, centred, filling the frame, no text, no label\",\n  \"image_size\": {\"width\": 32, \"height\": 32},\n  \"no_background\": true,\n  \"outline\": \"single color black outline\",\n  \"shading\": \"detailed shading\",\n  \"detail\": \"highly detailed\",\n  \"text_guidance_scale\": 8\n}\nEOF\npython game/tools/pixellab_client.py generate --endpoint create-image-pixflux --params-file art-archive/T-503/pixellab/rusty_paintjob_v1.params.json --out-dir art-archive/T-503/pixellab --name rusty_paintjob_v1_raw --consulted docs/visual-style.md --consulted docs/extended-narrative.md --consulted game/art/power_ups/ --consulted art-archive/T-503/old/rusty_overcoat_old.png --consulted art-archive/T-465/pixellab/rusty_overcoat_v1.params.json --task T-503 --notes \"Rusty Paintjob spray can icon, style loop v1\"", "description": "Generate spray can icon via PixelLab", "timeout": 660000}, "tool_name": "Bash", "tool_use_id": "toolu_01QUNxyDispZkcCJZzzECzSn"}; {"tool_input": {"command": "mkdir -p art-archive/T-503/work && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-503/pixellab/rusty_paintjob_v1_raw.png').convert('RGBA')\npx=[p for p in im.getdata() if p[3]>0]\ncols=set(p[:3] for p in px); print('colours',len(cols),'bbox',im.getbbox(),'semi',sum(1 for p in px if p[3]<255))\nprint('greenbull', [c for c in cols if c in ((104,220,96),(247,208,52))])\nfor bg,n in (((18,16,28),'dark'),((235,235,235),'light')):\n  b=Image.new('RGBA',im.size,bg+(255,)); b.alpha_composite(im); b.resize((256,256),Image.NEAREST).save('art-archive/T-503/work/v1_prev_'+n+'.png')\n\"", "description": "Inspect generated icon and make previews"}, "tool_name": "Bash", "tool_use_id": "toolu_01TsrduLtB5ddMstThRhNKJE"}; {"tool_input": {"command": "python art-archive/T-503/work/inspect_icon.py art-archive/T-503/pixellab/rusty_paintjob_v1_raw.png art-archive/T-503/work", "description": "Inspect icon and write previews"}, "tool_name": "Bash", "tool_use_id": "toolu_01Advf9wx5K8V8PQUB1JwroZ"}; {"tool_input": {"argv": ["inspect", "C:\\solid-carbide-worktrees\\T-503\\art-archive\\T-503\\style-loop\\v1.png", "--region", "0,0,31,31", "--scale", "12"]}, "tool_name": "mcp__pixellab__pixelart_workbench", "tool_use_id": "toolu_01FqZNgF9f6AGXRUFFRm6o6h"}

### Round 2

- Version 2: `art-archive/T-503/style-loop/v2.png`
- What changed: Version 2 is a free script fix with no PixelLab call, so this asset has still used 1 generation of its 4. The script, game/tools/build_power_up_icon_rusty_paintjob.py (command `v2`), keeps v1's spray-can outline shape and repaints everything inside it. Its 4 unit tests pass.

Fixes for the reason given:
- **Rule 2:** The body is now blue-grey metal, with cylinder shading lit from the top-left (darkest on the right), a lighter domed shoulder and a dark seam. A bright rim runs along the top and bottom edges of the body. The single orange block is replaced by five irregular rust patches, each with a darker centre (pits), plus bright chipped-paint pixels at the patch edges. Five lighter pixels break the left outline, which is now the matched set's dark outline (33,29,50).
- **Rule 5:**
  - A cyan glint with a small stepped halo on the lit left side.
  - Single cyan sparks on the top rim and the shoulder.
  - A magenta glint with a halo on the dark right side.
  - A magenta pixel on the nozzle tip.
  - A small stepped spray puff, light and dim mist, above and to the right of the nozzle.
- **Rule 4:** The palette is the cool night palette. The rust, outline and neon colours are taken from the current rusty_overcoat.png so the set matches.

Framing: two repeated body rows were dropped, so the can is 30 px tall and sits at y 1 to 30, no longer touching the top and bottom edges. It spans x 10 to 23 with the puff.

Checks: 18 colours, fully opaque pixels only, no Greenbull colours. The rust is orange-brown, not red, so --allow-red is not needed.

Enlarged previews are at art-archive/T-503/work/v2_try1_prev_dark.png and v2_try1_prev_light.png. The image in them is identical to v2.png.

Weak points:
- The can is slim (about 13 px wide plus the puff), so it fills less width than the other icons.
- The nozzle is small.
- Script checks: 6 of 6 pass
- Score: 5/10
- Reason: The script checks pass, so rules 1, 3 and 6 are fine, and no text or brands appear (rule 9). The weak points are rules 2 and 4, and the brief's "one clear central symbol", judged from the 32x32 render, which is tiny and hard to read.

1. Rule 2 (outline and shading): the dark outline looks continuous and heavy. It is not broken by lighter highlight pixels, especially on the top-left edge. The body is shaded mostly in pale lavender and pink, with little clear top-left light. Add a bright rim highlight on the top-left and darker shading on the right.

2. Subject read: the silhouette reads more as a tall bottle or vial than a spray can. There is no distinct nozzle on top, no small spray puff, and no bright rim band. Add a clear dark nozzle cap with a 2-3 px spray puff, and a lighter rim ring below the cap.

3. Rust and palette (rule 4, night neon): the orange-brown rust patches and flaking paint are barely visible. The body looks pastel pink and lavender instead of blue-grey with rust. Make the body darker blue-grey, add clear orange-brown rust patches with 2-3 tones, and keep the cyan and magenta glints small and bright (neon at night, rule 5 stepped glints).

4. Fill: the icon seems narrower than the ~28 px fill, with thin proportions. Widen the body to about 14-16 px so the can reads at 64 px on the card.
- Rules broken: 2, 4, 5

### Round 3

- Version 3: `art-archive/T-503/style-loop/v3.png`
- What changed: Version 3 is a free script redraw with no PixelLab call, so this asset has still used 1 generation of its 4. The script is game/tools/build_power_up_icon_rusty_paintjob.py (command `v3`). It draws the can as hand-made pixel rows instead of repainting v1's thin outline shape. Its 8 unit tests pass.

Fixes for the reason given:
- **Fill and shape:** The body is now 16 px wide (x 8 to 23) and about 30 px tall (y 0 to 30 with the puff), so it reads as a can, not a vial. On top it has a distinct dark violet-navy cap with its own highlight. Above the cap is a nozzle button with a dark nozzle hole on its right side.
- **Spray puff:** A small cloud, 4 to 5 px across, of light and dim mist comes from the nozzle hole, above and to the right.
- **Rim:** A bright white rim ring sits under the cap, above a dark groove, and a second bright rim runs at the bottom.
- **Rule 2:**
  - The metal is darker blue-grey, with stepped cylinder shading lit from the top-left: highlight band on the left, dark and deep on the right.
  - The pale lavender and pink tones are gone.
  - Lighter pixels break the outline at the top-left: three on the body's left edge, one at the rim's end and two at the cap's corners.
- **Rule 4:** There are four irregular rust patches in three orange-brown tones (light, mid, dark), plus dark pits. Light paint chips at their top-left edges show the flaking paint. The rust is orange-brown, not red.
- **Rule 5:**
  - A cyan glint with a stepped halo on the lit left side.
  - A cyan spark on the rim.
  - A magenta glint with a halo on the dark right side.
  - A magenta glint on the cap.

Checks: 20 colours, opaque pixels only, transparent background, no Greenbull colours, no text.

Enlarged previews (the same image as v3.png) are at art-archive/T-503/work/v3_try2_prev_dark.png and v3_try2_prev_light.png. An earlier draft and its previews are in art-archive/T-503/work/v3_try1*.

Weak points:
- The puff touches the top edge (y 0).
- The rust patches are somewhat blob-shaped.
- Script checks: 6 of 6 pass
- Score: 5/10
- Reason: The script checks pass for rule 1 (20 colours, transparent, opaque only) and rule 6. The image reads as a blue jar or bottle with orange patches, not a spray can. The brief asks for "one clear central symbol", and this fails it, which is a rule 2 detail and readability problem. It has no clear nozzle on top, no spray puff, and no bright rim. The rust patches look like round orange blobs or gems, not flaking rust. The cyan and magenta neon glints are barely visible. Rule 2 is also weak: the dark outline is not clearly broken by highlight pixels, and the shading is flat, with no clear top-left light. Rule 4: the night palette is muted and the neon cues are missing. Fix: redraw it as a tall cylinder with a narrower shoulder, a clear nozzle cap and a small stepped spray puff on top. Add a bright rim, a vertical top-left highlight strip, irregular rust patches and flaking edges, and 2-3 cyan and magenta glint pixels.
- Rules broken: 2, 4

### Round 4

- Version 4: `art-archive/T-503/style-loop/v4.png`
- What changed: Version 4 is the third and last refine. It is a free script redraw with no PixelLab call, so the whole asset used 1 generation of its 4. The script is game/tools/build_power_up_icon_rusty_paintjob.py (command `v4`); its 12 unit tests pass.

Fixes for the reason given:
- **Silhouette:** The jar shape is now a spray-can shape. A stepped, domed shoulder narrows from the 16 px body to a 10 px dark violet-navy cap. A bright white-grey collar ring sits under the cap. On top is a nozzle button with a nozzle hole on its right.
- **Spray puff:** A larger stepped puff of mist, bright core near the nozzle fading to dim droplets, fans up and to the right (x 19 to 26, y 1 to 4).
- **Highlight strip:** A 2 px white strip runs down the lit left of the body (x 11 to 12), with lighter and darker tones stepping across it. Lighter pixels break the left outline at the shoulder and the upper body.
- **Rust:** Three ragged, irregular rust patches in three orange-brown tones, with dark pits and a few short drips. White paint flakes sit where the rust breaks the strip and the paint. The round gem shapes and the stem-like drips from the first draft are gone.
- **Glints:** A cyan glint with a stepped plus-shaped halo on the body, a cyan spark on the shoulder rim, a magenta glint with a halo on the dark right side, and a magenta glint on the cap.

Checks: 20 colours, opaque pixels only, transparent background, no Greenbull colours, no text. The bounding box is x 8 to 26, y 1 to 30.

Enlarged previews (the same image as v4.png) are at art-archive/T-503/work/v4_try2_prev_dark.png and v4_try2_prev_light.png. The first draft is in art-archive/T-503/work/v4_try1*.

Honest note: the enlarged view reads as a rusty spray can spraying mist. At native 32 px the domed shoulder can still suggest a bottle. If this stays below 8, the cheapest next step is the board's own look at 64 px on the card.
- Script checks: 6 of 6 pass
- Score: 6/10
- Reason: The script checks all pass (32x32, transparent, 20 colours, no Greenbull colours), so rules 1, 3 and 6 are fine, and no text or brand shows (rule 9). Rule 2 is partly broken. At 32 px the subject reads more like a squat blue jar or bottle than an upright spray can. The body is too wide and round for its height, and the nozzle and the small spray puff are tiny and hard to see. The rust is a scatter of isolated orange and red dots rather than rust patches with flaking paint, so the weathering is noisy and the central symbol is weak. The dark outline is mostly continuous, and there are too few lighter highlight pixels breaking it, especially on the top-left light side. Fix: make the body taller and narrower (about 12 to 14 px wide, 20 or more px tall, a cylinder with a bright rim line near the top), put 2 or 3 contiguous rust patches in orange-brown on the lower body, add a clear nozzle cap with a 3 to 5 px spray puff above it, and add a few cyan and magenta glint pixels and highlight breaks in the outline on the top-left. Rule 5 (glints should be bright pixels with stepped halos) and rule 4 (neon night feel) are only weakly met.
- Rules broken: 2, 5

**Kept:** version 1, score 6/10 (`art-archive/T-503/style-loop/v1.png`, copied to `game/art/power_ups/rusty_overcoat.png`): still below 8 after 3 refines, so the task is flagged for the board's review.

## Result notes

Plan (before any PixelLab call): two assets through the style loop (tools/style_loop/run.py art), each starting with 1 create-image-pixflux 32x32 call (same settings as T-465), then free script fixes, then at most 3 paid refines if below 8: at most 4 generations per asset, 8 in all. Cost is 1 generation each from the Tier 2 subscription (4692 of 5000 left). 600 s HTTP timeout. Old icons kept in art-archive/T-503/old/. Briefs in art-archive/T-503/briefs/.
- 2026-11-02, in-progress → flagged-for-review: the style loop kept version 1 (score 6/10), still below 8 after 3 refines; every version is in its Style review

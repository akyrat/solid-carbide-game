---
id: T-293
title: "Art: the minion redesigned as a car-sized mini kaiju, one sample direction through the style loop"
status: done
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-292]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/enemies.md, game/README.md, agent-notes/asset-generation.md, art-archive/T-068/review_all8_directions_dark.png, game/art/car/car_iso.png]
files_expected_to_change: [art-archive/T-293/, docs/visual-style.md]
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

The board's redesign of the minion (Visual style, Decisions, "The minion, redesigned", 2026-10-25), in its words: bigger and more detailed, "slightly like a mini kaiju monster". It is still a lizard and walks on all fours, with a snapping jaw with teeth and a reptilian-looking face, and it is about as big as the car.

This task makes **one sample direction** (south-east, the car sheet's frame 0 direction), standing or mid-stride, as a single sprite for the board's review. It is the first real asset made through the style loop (`tasks/README.md`, "The style loop"), and its Style review is evidence for the course's Style Guide Agent assignment. The walk sheets for all directions and the minion's in-game size and hitbox come in later tasks, after the board approves the sample.

**The asset:**
- **Frame:** 128 x 128, like the car's frames. The minion is about the car's size: about 96 art pixels long at 32 art pixels per unit (Visual style, Content, "Rules", rule 3).
- **Look:** in the style guide (Visual style, Content, "Rules"): light green, not too bright, with darker scales; the pixel rules; a dark selective outline; a transparent background; at most 30 colours; no Redgull red.
- **Kaiju-like, not the kaiju:** it may echo the kaiju's Godzilla-style build, smaller, but it must not be a copy of Godzilla (rule 9).

**How:** through the style loop only, with the PixelLab go the board gave on 2026-10-25: at most 4 generations (the first version and up to 3 refines), free script fixes before a paid regeneration. Write the planned calls and their cost in the result notes before calling. The Project Lead starts the loop: `python tools/style_loop/run.py art --task T-293 --brief <brief> --out art-archive/T-293/minion_sample_se.png --size 128x128`. The kept sample stays in `art-archive/T-293/` until the board approves it; nothing goes into `game/art/` or the game yet.

The board's review: look at the kept sample next to the car and the current minion, on a dark and a light background, enlarged. Read the Style review to see how the loop got there.
Board review files: art-archive/T-293/review_sample_vs_car_dark.png, art-archive/T-293/review_sample_vs_car_light.png

## Acceptance criteria

- [ ] The task's `## Style review` section holds every round of the loop: each version's file, the script checks, the score, the reason and (from round 2) what changed, and a final "Kept" line. (QA: pass / fail)
- [ ] Every version is in `art-archive/T-293/style-loop/` with its PixelLab record, and the kept sample is `art-archive/T-293/minion_sample_se.png`. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py art art-archive/T-293/minion_sample_se.png --size 128x128` passes, or its failures are named in the Style review. (QA: pass / fail)
- [ ] At most 4 PixelLab generations were used, as `game/art/pixellab-generation-log.jsonl` shows for T-293. (QA: pass / fail)
- [ ] The two review images exist: the sample next to a car frame and a current minion frame, enlarged with nearest-neighbour, on a dark and a light background. (QA: pass / fail)
- [ ] Nothing under `game/art/` changed except the PixelLab log. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-25, Open → In progress

Started: the first real style loop run. The Asset Generation Agent makes one south-east sample of the mini kaiju minion, the Style Evaluator scores it, and it refines below 8. At most 4 PixelLab generations.

### 2026-10-25, Flagged for review

The loop ran for real: 4 versions, 4 PixelLab generations, the best scored 6/10, so the loop flagged it for the board. The Style review shows every score and reason; the review images are in art-archive/T-293/.

### 2026-10-26, Flagged for review → Done

Approved by the board: version 4 without its shadow. Merged to master; the sample stays in art-archive until the rotation and walk tickets.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-25: art, brief `art-archive/T-293/brief.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-293/style-loop/v1.png`
- Script checks: 5 of 6 pass; failed: rule 6, no Redgull red (nor any red that reads as it) (reds: [[92, 45, 64], [138, 87, 66], [198, 69, 105]])
- Score: 5/10
- Reason: Rule 6 (script, fact): the check finds reds [92,45,64], [138,87,66] and [198,69,105]. The mouth interior and tongue use the crimson-pink (198,69,105), which reads as red. The brief allows only a dull pink or dark brown. Fix: recolour the mouth inside to a dull desaturated pink or dark brown, and remove or darken the red-brown pixels, with a free palette-remap script before any paid regeneration.

Rule 4 (night and retro): the lizard is lit like a bright, flat daytime scene. The greens are saturated and bright, and the brief asked for light green that is "not too bright". There is no cool night tone, rim light or darker shadow side. Fix: shift the greens to a duller, cooler, darker range, and darken the shadow side and underside.

Rule 3 (3/4 isometric view showing the top and one side): the creature is drawn mostly as a side or front-on view. It stands upright and leans forward, with the head high on the right. It barely shows its top, and it does not clearly face south-east lying on the ground like the car. The pose is more upright than the brief's "four legs on the ground". The tail curls up at the left instead of lying along the ground. Fix: ask for a lower, more top-down 3/4 view with the body flat and long, facing bottom-right.

Rule 2 (outline and shading): the dark outline is present and the shading is decent, but some outline pixels are lighter and the body is a bit flat. This is minor.

Rule 1 (pixel art): passes the script checks (128x128, transparent, 17 colours, no semi-transparent pixels). Rules 5, 7, 8 and 9 don't apply here, and nothing in the image is a copy of an existing character.
- Rules broken: 3, 4, 6
- Refused: {"tool_input": {"command": "echo \"RUN=$SOLID_CARBIDE_STYLE_LOOP_RUN\"; ls .board/style-loop/ 2>&1; sed -n 67,95p docs/visual-style.md; python game/tools/pixellab_client.py --help 2>&1 | head -40; python game/tools/pixellab_client.py generate --help 2>&1 | head -40", "description": "Check loop env, rules, client usage"}, "tool_name": "Bash", "tool_use_id": "toolu_01QqZGHbv13nZS1vuceGnenH"}; {"tool_input": {"command": "printenv SOLID_CARBIDE_STYLE_LOOP_RUN; ls .board/style-loop/ 2>&1; sed -n 67,95p docs/visual-style.md; python game/tools/pixellab_client.py generate --help 2>&1 | head -40", "description": "Check loop env, rules, client usage"}, "tool_name": "Bash", "tool_use_id": "toolu_019ZHmPRtFF9FK3yhey4zJ8J"}; {"tool_input": {"command": "python game/tools/style_rules.py art art-archive/T-293/style-loop/v1_raw.png --size 128x128; python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-293/style-loop/v1_raw.png').convert('RGBA')\na=[p[3] for p in im.getdata()]\nprint('semi',sum(1 for x in a if 0<x<255),'colors',len(set(p for p in im.getdata() if p[3]==255)),'bbox',im.getbbox())\nbig=im.resize((512,512),Image.NEAREST)\nfor name,bg in (('dark',(20,20,30,255)),('light',(220,220,225,255))):\n  b=Image.new('RGBA',big.size,bg); b.alpha_composite(big); b.save(f'art-archive/T-293/style-loop/v1_raw_preview_{name}.png')\n\"", "description": "Check raw v1 against script rules and make previews"}, "tool_name": "Bash", "tool_use_id": "toolu_01TQssm2czkiUiLm8n4GHnAA"}; {"tool_input": {"command": "python art-archive/T-293/recolour_reds.py art-archive/T-293/style-loop/v1_raw.png art-archive/T-293/style-loop/v1.png 92,45,64=70,48,44 138,87,66=120,96,80 198,69,105=176,128,136 && python game/tools/style_rules.py art art-archive/T-293/style-loop/v1.png --size 128x128 && python game/tools/reduce_palette.py preview art-archive/T-293/style-loop/v1.png art-archive/T-293/style-loop/v1_preview.png --scale 4", "description": "Recolour reds, recheck rules, make preview"}, "tool_name": "Bash", "tool_use_id": "toolu_011jVtFS4arKy4EPvFSuoCBF"}

### Round 2

- Version 2: `art-archive/T-293/style-loop/v2.png`
- What changed: Version 2 is a paid regeneration (PixelLab pixflux, generation 2 of the 4 allowed), because the pose, view and lighting faults in rules 3 and 4 can't be fixed by a script. The new prompt (v2_params.json) asked for: a low, long body crawling on all four bent legs with the belly near the ground; the head lowered and pointing bottom-right; the tail lying flat towards the top-left; a 3/4 view from above showing the back and one side; muted dusky sage green with dark olive scales and a dark underside; cool blue night lighting with a faint rim light; and a dark brown mouth inside with yellow eyes, so no reds.

Free fixes after generating: the raw output had 32 colours and reds [94,46,45], [133,78,63] and [149,97,6]. I reduced the palette with the approved game/tools/reduce_palette.py, to 22 colours. At 28 colours two reds were left (kept as v2_reduce28.png); at 22 the brown-reds merge into neutral dark tones. style_rules.py now passes every check: 128x128, transparent, no semi-transparent pixels, 22 colours, no reds. Files: the raw PixelLab output is v2_raw.png with its record v2_raw.json; v2.json is a copy of that record.

Honest assessment: rules 3, 4 and 6 are addressed. It is clearly a low, top-down 3/4 lizard facing south-east, in dull cool night greens. But the result is weaker against the brief: the body is thin and small (only 1870 opaque pixels, well short of a car-sized, about 96 px heavy kaiju build), it reads as an ordinary lizard rather than a menacing mini kaiju, and after the palette merge the open jaw shows few visible teeth. A v3 refine (generation 3) should keep v2's view and night palette but ask for a much bulkier, heavier body filling the frame, with a big head and a wide-open jaw with clearly visible pale teeth.
- Script checks: 6 of 6 pass
- Score: 5/10
- Reason: The script rules pass: rule 1 (128x128, transparent, 22 colours, no semi-transparent pixels), rule 3 size and rule 6.

Rule 3 (view): it reads as a lizard seen from the top and one side, facing south-east. It is a low, flat, slender, gecko-like animal. It doesn't read as car-sized, so the scale half of rule 3 is not met. The body looks well under the 96 px target length and the legs are thin. Make it larger and heavier, filling the frame, with a thick torso and a chunky stance.

Rule 2 (outline, shading, detail): the outline is dark and the shading is only moderate. At this size the body is a mostly flat, desaturated grey-green with little scale texture. There are few highlight pixels breaking the outline and no clear darker scale pattern or paler belly. Add darker scale rows, a pale belly, and lighter highlight pixels on the back and head.

Rule 4 (night, retro): the colours are grey and muted rather than the light green the brief asks for. There is little night lighting or rim light, so the sprite reads as flat daylight grey. Shift the hue to a light, not-too-bright green and add cool night shading.

Brief points that the rules don't cover but that need fixing: the head is small and the jaw looks closed, with no visible teeth. It needs a heavy reptilian head with an open, snapping jaw showing small pale teeth. Thicker clawed legs and a thicker tail base would give the kaiju build.

Rules 5, 7, 8 and 9 don't apply here. Rule 10 is not examined.
- Rules broken: 2, 3, 4
- Refused: {"tool_input": {"command": "cd art-archive/T-293/style-loop && mv v2.png v2_raw.png && mv v2.json v2_raw.json && cd ../../.. && python game/tools/reduce_palette.py reduce --max-colors 28 art-archive/T-293/style-loop/v2_raw.png art-archive/T-293/style-loop/v2.png && cp art-archive/T-293/style-loop/v2_raw.json art-archive/T-293/style-loop/v2.json && python game/tools/style_rules.py art art-archive/T-293/style-loop/v2.png --size 128x128", "description": "Keep raw v2, reduce colours into v2.png, recheck"}, "tool_name": "Bash", "tool_use_id": "toolu_01RKnonFHeS7uWtionX1C6KE"}

### Round 3

- Version 3: `art-archive/T-293/style-loop/v3.png`
- What changed: Version 3 is a paid regeneration (PixelLab pixflux, generation 3 of the 4 allowed; prompt in v3_params.json). It fixes version 2's scale, bulk, head and teeth, and hue. The new prompt asked for a big, bulky lizard filling the image, with very thick clawed legs, a wide stance and a barrel torso. It also asked for a huge reptilian head with a wide-open jaw showing small pale teeth, and a very thick tail. The colours asked for were light soft green (not too bright) with rows of darker scales, a dark spiky back ridge, a pale cream belly, and cool night lighting: dark green and navy shadows on the underside and far legs, pale highlights on the back and head. It kept version 2's isometric, high top-down, south-east settings.

The raw output (v3_raw.png, record v3_raw.json) had 51 colours, and two eye and mouth browns that the red check flags by distance. I fixed both for free with the approved reduce_palette.py at 30 colours: the browns merged into duller tones and the eyes became a dull amber-brown. style_rules.py now passes every check: 128x128, transparent, no semi-transparent pixels, 30 colours, no reds. v3.json is a copy of the PixelLab record.

What improved: it is car-sized and heavy (4260 opaque pixels against 1870 in v2, about 100 px from tail tip to snout). It has a heavy head with an open jaw and visible pale teeth, thick clawed legs, a thick tail, darker scale rows, a pale belly, and a dark night-shaded far side. Weakness I see: PixelLab drew the pose upright again. It shows mostly the side, the body rears up on its hind legs and the front legs are lifted, so the top view and "all fours on the ground" (rule 3 and the brief) are only partly met. The silhouette also leans towards the Godzilla build. One generation is left for a refine.
- Script checks: 6 of 6 pass
- Score: 4/10
- Reason: The script checks pass (rules 1 and 6, size). The image breaks the brief and three rules.

Rule 3 (view): the creature stands upright on its hind legs, like a bipedal Godzilla. Its torso is vertical and its front arms hang down. It is drawn mostly side-on and front-on, not as a 3/4 isometric view from above and one side facing south-east. The brief asks for a creature on all four legs, seen from the top and one side like car frame 0. Redraw it low and horizontal, with the back visible from above, the body running diagonally towards the bottom right, and all four legs on the ground.

Rule 9 (no copy of an existing character): the upright pose, the rounded dorsal plates and the heavy-bellied build read as Godzilla. Make it clearly a lizard: a longer, lower body, a flatter reptilian head, and no upright dinosaur-monster posture.

Rule 4 (night and retro): the greens are bright and saturated, with flat daylight-like shading. The brief asks for a light green that is not too bright. Darken and desaturate the body and use cooler, moonlit shading with dark scale detail and a paler belly.

Rule 2 (outline and shading): the outline is dark, but the shading is blobby and the scale pattern is weak at this size. Add darker scale texture and highlight pixels to the outline.

The jaw is open with teeth, which meets the brief.
- Rules broken: 3, 4, 9, 2
- Refused: {"tool_input": {"command": "for n in 30 26 22; do python game/tools/reduce_palette.py reduce --max-colors $n art-archive/T-293/style-loop/v3_raw.png art-archive/T-293/style-loop/v3_probe$n.png >/dev/null && echo \"== $n\" && python game/tools/style_rules.py art art-archive/T-293/style-loop/v3_probe$n.png --size 128x128 | grep -A3 '\"rule\": 6' | grep detail; done", "description": "Probe palette reductions for version 3"}, "tool_name": "Bash", "tool_use_id": "toolu_01GG3ZMbWDhhsnDJkvJHzpzk"}

### Round 4

- Version 4: `art-archive/T-293/style-loop/v4.png`
- What changed: Version 4 is the last paid regeneration (PixelLab pixflux, generation 4 of the 4 allowed; the board's go is now used up; prompt in v4_params.json). Lesson from v1 and v3: the words "kaiju" and "monster standing" made PixelLab draw an upright Godzilla. So this prompt drops "kaiju" and uses v2's posture words, which had given the right view. It asks for a huge heavy monitor lizard, like a giant armoured komodo dragon, crawling low on four thick splayed legs with all feet flat on the ground. The body runs long and horizontal, diagonally, with the belly near the ground and the broad back visible from above. The head points bottom-right: big, wide and flat, with the jaw open showing small pale teeth. The thick tail lies flat towards the top-left, with low bumpy spine ridges and no dorsal plates. Colours: muted light green with dense darker scales, a pale belly, moonlit blue-green shadows and pale highlight pixels.

Free fix: the raw output (v4_raw.png, record v4_raw.json) had 51 colours and five reds. I reduced it to 24 colours with the approved reduce_palette.py, which merged away the bright red eye, the magenta claws and the darker reds. v4.json is a copy of the PixelLab record. style_rules.py passes size, transparency, no semi-transparent pixels and 24 colours. One rule 6 failure remains: a single dull pink (147,93,93) on the mouth inside and a thin belly line. It survives every palette size (16 to 30). The brief allows a dull pink mouth, but the check flags it by distance. Recolouring it needs a small remap script, and the permission system refused that script in round 1, so I didn't work around it.

Against v3's reason: rule 3 is fixed (four legs on the ground, low and horizontal, back seen from above, facing south-east, filling the frame with 4799 opaque pixels). Rule 9 is fixed (clearly a lizard, a flat reptilian head, no upright pose or plates). Rules 4 and 2 are improved (more muted green, darker scale rows, cool shadows, highlight pixels). Remaining weaknesses: PixelLab drew a soft blue-grey cast shadow on the ground under and right of the body, despite "no ground shadow", and removing it would also need a script. The teeth are small, and the build is more heavy monitor lizard than menacing kaiju.
- Script checks: 5 of 6 pass; failed: rule 6, no Redgull red (nor any red that reads as it) (reds: [[147, 93, 93]])
- Score: 6/10
- Reason: Rule 6 is broken. The script found a red-reading colour, (147, 93, 93), which is a dusty pink-brown. It is probably the mouth or tongue. The brief allows a dull pink or dark brown mouth, but the script flags this one, so treat it as a failure. Fix it with a free script step: recolour that palette entry to a clear brown, for example about (110, 70, 50), or a pink with less red, and re-check the colour count. Do not pay for a new generation for this.

The other script-checked parts of rules 1 and 3 pass. The sprite is 128x128, with a transparent background, no semi-transparent pixels and 24 colours. Rule 4 is met: the lighting is night and retro. Rule 2 is mostly met: the outline is dark, the shading is detailed and there are highlights. Rule 3's 3/4 view is acceptable, since the top and one side show and the sprite faces south-east.

The image is judged against the brief, not only the rules. The creature looks like a slim, ordinary lizard or iguana with a long thin tail. It is not a heavy, menacing mini kaiju. The legs are thin, with no bulky haunches or heavy head, and the jaw is only slightly open. This is a brief miss rather than a rule break. If a refine is left, ask for a bulkier body, thicker legs and a wider head with a clearly open, toothy jaw. Rule 9 is not broken, because it is not a copy of any real character.
- Rules broken: 6

**Kept:** version 4, score 6/10 (`art-archive/T-293/style-loop/v4.png`, copied to `art-archive/T-293/minion_sample_se.png`): still below 8 after 3 refines, so the task is flagged for the board's review.

## Result notes

- 2026-10-25, in-progress → flagged-for-review: the style loop kept version 4 (score 6/10), still below 8 after 3 refines; every version is in its Style review

- 2026-10-25, Asset Generation, finishing step: the style loop used the board's 4 generations (1 first version plus 3 refines), kept version 4 at 6/10, and the task is flagged for the board's review. Look at: `art-archive/T-293/review_sample_vs_car_dark.png` and `_light.png` (car frame 0, the current minion, the kept sample, same scale, 4x), `art-archive/T-293/review_all_versions_dark.png` and `_light.png` (v1 to v4, 3x), the kept sample `art-archive/T-293/minion_sample_se.png`, and every version and probe in `art-archive/T-293/style-loop/`. The images are made with `game/tools/review_sheet.py` (test: `game/tools/test_review_sheet.py`).
- My view of the four versions: v1 is the bright green upright biped, readable but far too saturated and cartoonish next to the car. v2 is a small grey four-legged lizard, closest to the current minion but flat and low on detail. v3 is a Godzilla-like upright dinosaur, charming but a different creature from the on-all-fours minion. v4 is a four-legged lizard with a long tail and a cast shadow, the best pose match, but it is large and detailed for a minion, and the shadow is baked in. None reached 8; v4 is the one to judge or hand-edit.
- Commands refused during the loop (all in the Style review's "Refused" lines, none worked around): a compound command checking the loop env and the client's help (twice, as two variants), the v1 raw check that wrote preview images with inline Python, the recolour command naming a task script, the v2 rename-and-reduce chain, and the v3 palette-reduction probe loop.

- 2026-10-26, quick tweak from the board: "I like the last one, but I don't want it to have a shadow. at least not the sprite, because we're going to generate, you know, animations from this and rotations." Version 4 is approved; the baked-in ground shadow is removed by a free script (no PixelLab, no loop run): `game/tools/remove_sprite_shadow.py` (test `game/tools/test_remove_sprite_shadow.py`) makes transparent only pixels of the two shadow colours (70,90,109) and (74,96,114) that connect to the transparent background. It removed 1060 pixels, kept every other pixel unchanged, and adds no colours (22 colours left). Result: `art-archive/T-293/minion_sample_se_noshadow.png`; v4.png and minion_sample_se.png are kept as they are. Review images: `art-archive/T-293/review_noshadow_dark.png` and `_light.png` (v4 left, no-shadow right, 4x); I looked at the dark one: no shadow left, nothing of the lizard eaten. `style_rules.py art` check: every rule passes except rule 6, the dull pink (147,93,93) in the mouth, left unchanged for the Project Lead to ask the board.
- 2026-10-26, flagged-for-review → done: The board's review (2026-10-26): likes version 4; wants it without the baked-in shadow (removed by script) and keeps the dull pink mouth.

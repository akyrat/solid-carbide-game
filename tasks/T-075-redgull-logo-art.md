---
id: T-075
title: Art: the Redgull logo, a seagull's head in profile in one shade of dark red
status: done
from: project-lead
to: asset-generation
lead: Art
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md, docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/extended-narrative.md]
files_expected_to_change: [art files under game/art/ and their records, the scenes that used the placeholders, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Redgull's logo, as Visual style, Decisions describes it (board, 2026-10-16): the **side profile of a seagull's head only**, not the whole bird (a full body would look like any bird), **as minimalistic as possible**, in **one single shade of dark red** on a transparent background. Slightly evil and unsettling on purpose (Extended narrative, Decisions). It is a fictional brand: it must not look like any real brand's logo. Where it appears in the MVP is decided separately; this task only makes the logo, so there is no placeholder to swap.

Because it is a flat one-colour logo, the sprite rules for outline, shading and about 30 colours do not apply. Still: hard pixel edges, no anti-aliasing, no semi-transparent pixels, transparent background. If PixelLab returns more than one shade, a free script may flatten every visible pixel to the single dark red and clear the rest; keep the raw output in `art-archive/T-075/`.

**Sample first** (board, 2026-10-16, `docs/working-with-the-board.md`, "Art and money"): this round makes **one** logo sample for the board to judge. The board has given the go for this PixelLab generation. Write the planned call(s) and their cost in the result notes before calling. Keep it to the smallest number of calls that gives one usable sample (one call, or one call returning a few options to choose from if the endpoint does that at the same cost). The other sizes (for example 32, 64 and 128 pixels wide) are made from the approved sample afterwards, by script where possible.

Use the existing client, `game/tools/pixellab_client.py`, with a 600 s HTTP timeout. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. Never delete generated art.

**Allowance** (board, 2026-10-16, after the first sample read as a bell or the letter R): up to **10 more generations**, spent at the agent's judgement, to reach a sample worth showing the board. This replaces the one-round rule for this task only. The agent judges its own candidates and stops early once one is good; it never goes over 10.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A check script shows each logo file uses exactly one visible colour (a dark red), has a transparent background and no semi-transparent pixels (QA: pass)
- [x] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; the calls after the first sample stay within the board's allowance of 10 generations (QA: pass)
- [x] The board's pick (2026-10-16: `art-archive/T-075/redgull_logo_raw_init128_s80.png`, flattened to its own main red, RGB 135,17,27) exists as `game/art/logo/redgull_logo_128.png`, `redgull_logo_64.png` and `redgull_logo_32.png`, each one colour, the smaller ones made by script from the 128; the other candidates are in `art-archive/T-075/`, not `game/art/`; Godot imports all three (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: judge the sample's look (a seagull's head in profile, minimal, one dark red). Once approved, the other sizes follow from it.

## Updates

### 2026-10-16, Open → In progress

Started: rescoped to your direction (seagull head in profile, one shade of dark red, minimal). One PixelLab sample first for your review.

### 2026-10-16, In QA

Sample made (1 generation, 4909 -> 4908). It reads poorly: a bell / letter-R blob with an eye hole, no gull beak or forehead. QA held until the board picks the next step: free scripted silhouette (recommended) or one more paid call.

### 2026-10-16, In QA

Board's allowance: up to 10 more generations to reach a showable logo. Agent resumed; I'll check the candidates before showing the board.

### 2026-10-16, In QA

Round 3 is worth showing: gull head in profile, one dark red. 5 of the 10 allowed generations used (balance ~4904). Pick: redgull_logo_128_pl_s150.png. Waiting for the board's verdict before QA.

### 2026-10-16, In QA

Board's extra call: silhouette_init_128 as init, strength 80. Still raptor-like. 6 of 10 generations used (balance ~4903).

### 2026-10-16, In QA

Board picked the s80 PixelLab result (raw, its own darker red 135,17,27). Agent is making the final 128/64/32 files; then QA and the board's review.

### 2026-10-16, Needs playtest

QA passed all four criteria (round 1). Waiting in Needs playtest for the board's look check; files in C:\solid-carbide-worktrees\T-075\game\art\logo\.

### 2026-10-16, Done

Merged into master. Logo at game/art/logo/ (128, 64, 32). Where it appears in the game is still to be decided.

## Result notes

Written by the agent when it finishes.

### Plan (before the call)

- Balance before: 4909 of 5000 generations (Tier 2 plan; credits USD 0).
- One call: `/create-image-pixflux`, 64x64, no_background, flat shading, low detail, `single color black outline` (the only outline option that gives a hard silhouette; the outline colour is then flattened away by script), text_guidance_scale 8, 600 s HTTP timeout. Cost: 1 generation. Params file: `art-archive/T-075/req.json`.
- Canvas 64 px: the logo is a single big shape, 64 px is enough for the beak hook and the eye cut-out to read, and it scales down to 32 by script and up to 128 by integer scale. Pixflux returns one image per call.
- Flatten by script afterwards (every visible pixel to one dark red, alpha thresholded), check script `game/tools/check_logo_one_colour.py`.

### Result (sample round, 2026-10-16)

- **Calls:** one, `/create-image-pixflux`, params in `art-archive/T-075/req.json`, prompt in the record `art-archive/T-075/redgull_logo_raw.json` and the generation log. 1 generation. Balance before 4909 of 5000, after 4908 (the first balance read right after the call still showed 4909, it lagged). No regeneration.
- **Raw output:** `art-archive/T-075/redgull_logo_raw.png` (64x64, 3 visible colours: two near-identical reds and one dark brown-red streak).
- **Flattened sample:** `game/art/logo/redgull_logo_64.png`, made by `game/tools/flatten_logo.py` (every visible pixel to one dark red, RGB 150,24,28; the eye hole is transparent in the raw output already).
- **Check:** `python game/tools/check_logo_one_colour.py game/art/logo/redgull_logo_64.png` prints PASS (one visible colour, dark red, transparent background, no semi-transparent pixels). Tests: `game/tools/test_check_logo_one_colour.py`. GUT suite: all passed. Python tool tests: `game/tools` 264 OK (1 skipped), `tools` 180 OK.
- **Honest note for the board's review:** the shape does not read as a seagull's head. PixelLab gave a rounded bell/blob with a square eye hole and a stepped notch on the right; there is no long beak with a hook and no sloping forehead, so it looks more like a bell or a letter R than a gull. The eye cut-out gives a little of the staring look. Not regenerated, per the one-round rule. Cheapest next step if the board wants it: a free hand-drawn or scripted pixel silhouette from the board's own description (no PixelLab), or one more paid call with a changed prompt on the board's say-so.
- 2026-10-16, in-progress → in-qa: One sample made; check script passes; honest note: it does not read as a gull's head (blob, no beak).

### Round 2 plan (board's allowance: up to 10 more generations)

- Free first: `game/tools/draw_gull_silhouette.py` draws a one-colour gull-head silhouette by script (long straight beak with a hook at the tip, flat forehead, angled eye cut-out): `art-archive/T-075/silhouette_init_64.png` and `silhouette_init_128.png`. No PixelLab.
- Paid: `/create-image-pixflux` with `init_image` (the silhouette) so PixelLab refines a shape that already reads as a gull. Prompt: "logo, flat silhouette, single colour, side view, seagull head, hooked beak, minimalist icon, no body", no_background, flat shading, low detail, 600 s timeout. One variable changes per call; each call is listed below with its settings, cost and balance as it is made. Cost: 1 generation per call, cap 10.

### Round 2 calls (2 of the 10 allowed; stopped early)

Both: `/create-image-pixflux`, description "logo, flat silhouette, single colour, side view, seagull head, hooked beak, minimalist icon, no body", no_background, `single color black outline`, flat shading, low detail, text_guidance_scale 8, `init_image` = the script silhouette, 600 s timeout, 1 generation each. Balance: 4908 before call 1; 4907 after call 1 and still 4907 read after call 2 (the balance lags by one call; true figure about 4906).

1. `art-archive/T-075/redgull_logo_raw_02_init64_s400.png`: 64x64, init `silhouette_init_64.png`, strength 400. Result: almost identical to the init image (PixelLab only copied it). Params `req_02.json`.
2. `art-archive/T-075/redgull_logo_raw_03_init128_s200.png`: 128x128, init `silhouette_init_128.png`, strength 200 (one change from call 1: size and strength). Result: again the init shape, with smoother edges. Params `req_03.json`.

Stopped after 2 calls: PixelLab at these strengths only reproduces the script shape, so more calls would only spend the allowance. The shape itself (the script silhouette) is what the board should judge; changing it is free.

Candidates under `game/art/logo/` (all pass `check_logo_one_colour.py`): `redgull_logo_64_script.png` (script only, no PixelLab), `redgull_logo_64_init.png` (call 1 flattened), `redgull_logo_128.png` (call 2 flattened). The first one-round sample `redgull_logo_64.png` is the rejected blob. Script: `game/tools/draw_gull_silhouette.py`.

Honest view: the script shape reads clearly as a bird's head in profile with a long, straight beak and a hooked tip, and the slanted eye hole gives the menacing look. It reads as a gull more than the first sample did, but the head and neck are heavy and boxy, so it can also pass for a raptor or a vulture; a gull wants a thinner beak, a rounder crown and a slimmer neck. Not yet a finished logo.

### Round 3 plan (3 more generations at most, total 6 of the allowed 10 after it; round 3 cost so far 0)

- Free: the script silhouette was corrected toward a gull (domed crown, long slim bill, gonys bump under the bill, small slanted eye, tapering neck with a diagonal cut): variants A, B, C, D in `game/tools/draw_gull_silhouette.py`, files `art-archive/T-075/silhouette_<V>-64.png` and `-128.png`. Pick: D (stout bill, larger slanted eye, no gape line, which is noise at 64 px).
- Paid, one change per call: (4) `/create-image-pixflux` 128x128 with D-128 as init_image, strength 150; (5) the same at strength 100. Prompt (both): "gull seabird logo mark, flat silhouette, single colour, side view, seagull head, hooked beak, minimalist icon, no body". Same settings as round 2. 1 generation each.

### Round 3 result (2 calls; 5 generations spent in total across rounds 1 to 3, 5 of the 10 allowance left unused; balance 4909 at the start, 4905 on the last read, the final read lags so about 4904)

- Call 4: `art-archive/T-075/redgull_logo_raw_D128_s150.png` (init D-128, strength 150; params `req_D128_s150.json`). Keeps the shape, tidies the curves and sharpens the hooked tip. Best PixelLab result.
- Call 5: `art-archive/T-075/redgull_logo_raw_D128_s100.png` (same, strength 100; params `req_D128_s100.json`). The eye became a round dot (loses the menacing slant) and the neck gets a notch. Worse.
- Flattened picks in `game/art/logo/`: `redgull_logo_128_pl_s150.png` (best PixelLab), `redgull_logo_128_script_D.png` and `redgull_logo_64_script_D.png` (script only), plus `redgull_logo_128_pl_s100.png`. All pass the check script.
- Honest view: variant D (script) and its s150 refinement read as a gull's head: domed round crown, long slim bill nearly straight along the top, small hook at the tip with a gonys bump beneath, slanted eye hole. The slant is mild, so "slightly evil" is subtle. The neck block is still somewhat large for a logo mark.

### Round 4 plan (the board's request: 1 generation; total would be 6 of 10)

- One call: `/create-image-pixflux` 128x128, init_image `art-archive/T-075/silhouette_init_128.png` (the round 2 raptor-like script silhouette, as the board asked), init strength 80 (lower than the 200 used for `redgull_logo_raw_03_init128_s200.png`, which came back almost identical), prompt "gull seabird logo mark, flat silhouette, single colour, side view, seagull head, hooked beak, minimalist icon, no body", no_background, `single color black outline`, flat shading, low detail, text_guidance_scale 8, 600 s timeout. Raw saved as `art-archive/T-075/redgull_logo_raw_init128_s80.png`. Cost 1 generation.

### Round 4 result

Call made as planned (1 generation; total 6 of 10 spent). Balance read 4904 before and 4904 after (lagging; about 4903 true). Raw: `art-archive/T-075/redgull_logo_raw_init128_s80.png` (params `req_init128_s80.json`); flattened: `game/art/logo/redgull_logo_128_pl_init_s80.png`, check script PASS. Result: even at strength 80 PixelLab stayed close to the init silhouette (slightly rounder, cleaner curves, a bumpy eye hole); it still reads as a raptor/vulture, as the init does.

### Final files (after the board's pick, no more PixelLab calls)

- The board picked `art-archive/T-075/redgull_logo_raw_init128_s80.png`. Generations used in total: 1 (first sample) + 5 (rounds 2 to 4) = 6; 4 of the allowance left unused.
- Final files, all one colour RGB 135,17,27 (the raw's own main red), made by `game/tools/make_logo_sizes.py`: `game/art/logo/redgull_logo_128.png` (the raw flattened), `redgull_logo_64.png` and `redgull_logo_32.png` (area-averaged alpha from the 128, hard threshold). Small-size cleanup: the script checks that the eye hole survives and widens a 1-px hole or reopens a closed one to 2x1 px; at 64 and 32 the hole survived, so nothing was changed (the 32 px eye is a two-pixel stepped diagonal, the beak tip is one pixel hooking down).
- The previous `redgull_logo_128.png` (round 2) and `redgull_logo_64.png` (the first blob) are in `art-archive/T-075/` as `redgull_logo_128_round2_init200_flattened.png` and `redgull_logo_64_round1_blob_flattened.png`; all other candidate PNGs moved there too.
- Check script PASS on all three; Godot imported them (headless import in the GUT run); GUT suite all passed; Python tests `game/tools` 265 OK (1 skipped), `tools` 180 OK.

### QA round 1 (2026-10-16)

- [x] One colour, transparent, no semi-transparent: PASS. Check script PASS on 128, 64 and 32; all pixels are (135,17,27,255) or fully transparent.
- [x] Call record and allowance: PASS. The generation log has 6 entries for T-075 (1 first sample + 5 after), each with prompt, endpoint and usage 1 generation; balance 4909 before, about 4903 after. Calls after the first sample: 5, within the allowance of 10. Wording slip: the notes say "6 of 10 generations used" where it is 5 of the 10 extra (6 in total); not a fail.
- [x] Final files: PASS. `redgull_logo_128/64/32.png` exist in `game/art/logo/`, one colour 135,17,27, with `.import` files; the other candidates are in `art-archive/T-075/`, not `game/art/`; the headless import in the GUT run raised no errors.
- [x] Tests: PASS. GUT 745/745 passing; `game/tools` 265 OK (1 skipped); `tools` 180 OK.
- 2026-10-16, in-qa → needs-playtest: QA round 1: all four criteria pass
- 2026-10-16, needs-playtest → done: The board's review: 'the icons look good to me, merge them'. Count correction: 6 generations in total (the first sample plus 5 of the board's allowance of 10); where the notes say '6 of 10', read 5 of the 10 extra.

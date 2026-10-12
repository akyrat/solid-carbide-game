---
id: T-014
title: The first pixel-art car sprite: one direction, front to the bottom-left (PixelLab)
status: done
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-013, T-012]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, tasks/T-013-placeholder-car-sprites.md, game/README.md, docs/extended-narrative.md]
files_expected_to_change: [a car sprite PNG and its record under game/art/, the PixelLab generation log, game/README.md]
model: sonnet
qa_rounds: 2
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Scoped down by the board (2026-10-12): one sprite only, for now.** The board wants to see the first generated car before anything else. The other 15 directions, and swapping the final sheet in for the placeholder, moved to T-101, which waits for the board's review of this sprite.

Generate **one** pixel-art car sprite with PixelLab:

- **The car** (Visual style, Decisions, "The car"): looks like a 1967 Ford Mustang GT fastback, **dark green** as the main colour, with **two white racing stripes** running down the length of the car (bonnet, roof and boot), centred on the car as much as possible, with a **gap of body colour between the two stripes**. No real badges or logos (no Ford, Mustang or Shelby badges). The reference photos are in Visual style, References.
- **The direction:** seen in the game's isometric view, the car lies on the diagonal from the top-right of the screen to the bottom-left, with its **front (nose) at the bottom-left** (facing south-west on screen). Use the isometric projection the game uses (`game/art/placeholders/car/car_iso.json` and `game/README.md`, "Placeholder car sprite sheets") and say in the result notes which frame of T-013's 16-frame layout this sprite matches, so T-101 can build on it.
- **The technical style** (Visual style, Decisions): a 128 by 128 pixel frame, about 40 pixels per unit (the car about 120 pixels long and 3 times as long as it is wide, Drifting, Decisions), a selective dark outline, detailed shading, high detail, about 30 colours, no anti-aliasing, no semi-transparent pixels, a transparent background, the isometric view only. The technical-style reference image (Visual style, References) may be used as a style image, for its style only.

**PixelLab:** pick the endpoint that best makes one isometric sprite in a given direction at 128 by 128 (re-check https://www.pixellab.ai/llms.txt and https://api.pixellab.ai/v2/openapi.json first; the API changes), and say in the result notes why. Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after, as for T-003. **One round of generation only:** do not regenerate; report problems instead. If a single call returns several images, keep them all for the board to choose from.

**Do not put it into the game yet:** save the sprite (and its record) under `game/art/` next to the placeholders, without changing any scene, script or the placeholder sheets. T-101 does the swap once the full set exists.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The sprite is a 128 by 128 pixel PNG under `game/art/`, and the result notes say which of T-013's isometric frames its direction matches (QA: pass)
- [ ] A check script shows it follows Visual style's technical rules: transparent background, no semi-transparent pixels, about 30 colours or fewer (QA: pass)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass)
- [ ] `git diff master...HEAD` shows no change to scenes, game scripts or the placeholder sheets (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: judge the car's look (the Mustang GT shape, the dark green, the two centred stripes with a gap, the direction); one round only, so problems are reported rather than regenerated.
Board review files: the new sprite PNG(s) under `game/art/`.

## Result notes

Written by the agent when it finishes.

**Asset Generation Agent, 2026-10-12**

**Sprite:** `game/art/car/car_sw_front.png` (128x128 RGBA), record `game/art/car/car_sw_front.json`, log entry in `game/art/pixellab-generation-log.jsonl`. One call, one image, no regeneration.

**Endpoint: `POST /create-image-pixflux`** (direct, existing client). Why: after re-reading llms.txt and the OpenAPI spec, it is the cheap single-image endpoint that takes 128x128 (area up to 400x400), `isometric`, `no_background`, a `direction` (south-west), outline/shading/detail settings, and a `view`. Bitforge was not used: it is limited to 200x200 and its extra feature, a style image, would risk copying the reference car's colours and angle; the object endpoints cost far more and make several directions at once (not wanted now). No style image was used.

**Settings:** `image_size` 128x128, `isometric: true`, `no_background: true`, `view: high top-down`, `direction: south-west`, `outline: selective outline`, `shading: detailed shading`, `detail: highly detailed`, `text_guidance_scale` 8. Full prompt in the record. Resources consulted: Visual style (The car, technical rules, both reference photos), this task, llms.txt and the OpenAPI spec.

**Cost and balance:** 1 subscription generation ($0.00 USD). Balance before: 5000 of 5000 generations (plan Tier 2, USD credits $0.00). After: 4999 of 5000.

**Direction:** the nose points south-west on screen. It matches **frame 4** of T-013's 16-frame isometric sheet (heading 90 degrees, nose along world +y, screen angle 153.43 degrees, down-left). Note for T-101: PixelLab's "south-west" is a loose guide; in the picture the nose angle on screen is roughly 25 to 30 degrees below the horizontal, close to frame 4's, not a steep 45 degree diagonal (frame 3 is 129.64 degrees).

**Check script:** `game/tools/check_sprite_rules.py` (tests `game/tools/test_check_sprite_rules.py`, 3 tests). Result for the sprite: 128x128 PASS; transparent background (all four corners alpha 0) PASS; semi-transparent pixels 0, PASS; **33 distinct opaque colours** against about 30 (the script's limit is 30, so it reports FAIL; 3 over, which I read as "about 30" but QA and the board decide); car bounding box x 6 to 122, y 23 to 107 (117 wide, 85 tall).

**What I see in it (not a judgement):** a dark-green fastback coupe seen from above-right, nose at the bottom-left with a chrome grille and a small yellow light, tail at the top-right with a small red light, two wheels visible on the near side, a darker body shade and cyan-green highlights. Two white stripes run over the bonnet, roof and boot. Possible problems: (1) the two stripes are close together and the gap between them is thin and dark-green; on the bonnet they read almost as one wide white band, and the stripes sit slightly off-centre toward one side; (2) the car looks about 1.4 to 1.5 times as long as the bounding box is tall and its body looks shorter and chunkier than the 3:1 proportion in Drifting; the sprite is about 117 pixels wide, so the length is near the 120 pixel target; (3) the sprite includes a dark shadow under the car made of opaque pixels (no transparency), which would be drawn as part of the car; (4) a few windscreen/chrome pixels are very light lavender, and the roof reads as one dark glass shape rather than a body-colour roof with stripes (the roof stripes show only partly); (5) 33 colours.

**Tests:** full GUT suite 294/294 passed (`bash game/tools/run_tests.sh`); Python tool tests `python -m unittest discover -s game/tools -p "test_*.py"`: 70 OK. The headless Godot run rewrote some tracked `.import` files; I restored them, and kept only the new `car_sw_front.png.import`.

**Files:** created `game/art/car/car_sw_front.png`, `.json`, `.png.import`, `game/tools/check_sprite_rules.py`, `game/tools/test_check_sprite_rules.py`; changed `game/art/pixellab-generation-log.jsonl`, `game/README.md` (new section "The first final car sprite (T-014)"), this task file. No scene, game script or placeholder sheet changed. Documents affected: `game/README.md`.

### QA round 1

**QA/Integration Agent, 2026-10-12. Result: all five criteria pass; needs the board's review of the look.**

1. **PNG and frame note: pass.** `game/art/car/car_sw_front.png` is 128x128 RGBA; the result notes and `game/README.md` say it matches frame 4 of T-013's isometric sheet.
2. **Technical rules: pass.** Check script run by QA: 128x128 pass, transparent corners pass, 0 semi-transparent pixels pass, 33 opaque colours (script limit 30, so the script prints FAIL on that line). QA judgement: 33 is within "about 30". The Visual style rule says "about 30" and its own reference image has 29, so the intent is a small palette, not an exact cap; 3 over (10%) is a small miss, and 5 of the 33 colours are used by 10 to 15 pixels or fewer (lavender highlights, yellow light, red light), so it is the same palette size class. The board judges the look, and can ask T-101 to tighten the palette if it wants. Note for the board: the shadow under the car is opaque pixels (agent's notes, problem 3), which the rule allows but which will be drawn as part of the car.
3. **Record: pass.** One call only: log has one new T-014 line (`/create-image-pixflux`, prompt, usage 1 generation); `car_sw_front.json` has the full prompt, all settings and usage 1 generation ($0.00 subscription). The balance before (5000 of 5000) and after (4999 of 5000) is in the result notes only, not in the JSON or log file; QA could not verify it (no PixelLab calls were made), but it is consistent with one generation.
4. **Diff scope: pass.** `git diff master...HEAD` touches only game/README.md, the new car PNG, its .json and .png.import, the log, the new check script and its test, and this task file. No scene, game script or placeholder sheet.
5. **Tests: pass.** Full GUT suite 294/294 (`TESTS PASSED`); `tools` Python tests 75 OK; `game/tools` Python tests 70 OK. Line-ending-only .import changes from the Godot run were left uncommitted.

Board review files: `game/art/car/car_sw_front.png`.

### Board review

2026-10-12: the board loves the sprite and wants to see a version **without the shadow** under the car. Keep the original (`car_sw_front.png`) as it is and add the shadowless version next to it; the car itself must stay exactly the same. Removing the shadow by script is preferred (no generation). The shadow's colour is also used for the windows, the side of the body and the tyres, so a colour swap alone won't do; if a clean result needs PixelLab (for example inpainting only the shadow area with a mask), that is allowed for this one fix (board's request), with one call, recorded like the first.

2026-10-12, third note: the first inpaint call timed out and was charged; the board approved one retry.

2026-10-12, fourth note: the inpaint retry drew a shadow back in; the board asked for one fresh generation with 'no shadow' in the prompt.

### Shadowless version (Asset Generation Agent, 2026-10-12)

`game/art/car/car_sw_front_noshadow.png` (record `car_sw_front_noshadow.json`), next to the unchanged original. **No PixelLab call** (cost 0; balance unchanged at 4999 of 5000 generations). Made by `game/tools/remove_car_shadow.py` (tests `game/tools/test_remove_car_shadow.py`). The shadow shares its colour with the windows, body side and tyres, so a pixel is made transparent only if it is one of the four near-black colours, connected to the transparent background through such colours, below a hand-placed line along the car's lower edge, and outside two wheel ellipses. 734 pixels changed, all to fully transparent; every other pixel is identical to the original (the test checks this). Check script: size, transparent corners and no semi-transparent pixels pass; still 33 colours (the same palette). I looked at it enlarged on light and dark backgrounds: no stray shadow dots remain and no body, window or tyre part is cut. Side effects to know: the bumper's chrome now has no dark underline, so its lower edge looks lighter and slightly ragged, and a small dark spur remains beside the rear tyre. Python tests 72 OK. Documents affected: `game/README.md`.

2026-10-12, second note: the board doesn't like how the script-edited versions look and asks for a shadowless version made with PixelLab, using a generation (board's request). Use **one** PixelLab call that keeps the car: inpaint the original `car_sw_front.png` with a mask over the shadow area, including the bumper's lower edge and the spot beside the rear tyre, so PixelLab redraws them cleanly with a transparent background. Keep the original and the script version as they are, and save the result as a new file with its own record. If inpainting can't be done at this size or can't keep the background transparent, stop and report; don't make a fresh generation of a different car.

### PixelLab shadowless attempt (Asset Generation Agent, 2026-10-12): no image received

Endpoint `POST /inpaint` (direct; max area 200x200, takes an inpainting image, a mask, `no_background`, isometric and direction settings; `/inpaint-v3` is asynchronous and Pro-priced, and was not needed). I added `/inpaint` to `game/tools/pixellab_client.py` as a direct endpoint. Request: the original `car_sw_front.png` as the inpainting image, the mask `game/art/car/car_sw_front_noshadow_pixellab_mask.png` (white = redraw: the 734 shadow pixels grown by 2 pixels, so the bumper's lower edge, the tyre bottoms and the spot beside the rear tyre are included, plus nearby transparent pixels), 128x128, `no_background: true`, `isometric: true`, `direction: south-west`, `view: high top-down`, selective outline, detailed shading, highly detailed, `text_guidance_scale` 3; prompt and negative description are in the log entry. Balance before: 4999 of 5000.

**The client's read timed out after 120 seconds ("The read operation timed out") and no image was saved.** The log entry says `error`. The balance afterwards reads **4998**, so the call was charged (1 generation) even though the result never reached us; a direct endpoint gives no job id to fetch it later. As instructed (one call only, never retry), I made **no second call**. The output files `car_sw_front_noshadow_pixellab.png` and its record do not exist. Decision for the board or Project Lead: whether to allow one more inpaint call (the same request is saved in the log and mask; the client's HTTP timeout could first be raised from 120 s).

### PixelLab shadowless retry (Asset Generation Agent, 2026-10-12)

The board-approved retry (third note) of the same `/inpaint` request: same original image, same mask (`car_sw_front_noshadow_pixellab_mask.png`), same settings and prompt (in the log and the record). The client's HTTP read timeout was raised from 120 s to 600 s first. Balance before 4998, after **4997** of 5000 (1 generation, $0.00). Saved as `game/art/car/car_sw_front_noshadow_pixellab.png` with its record `.json`; the log has the earlier timed-out entry and this one (2 inpaint calls in all, 2 generations charged). The original and the script version are unchanged.

Check script: 128x128, transparent corners and no semi-transparent pixels pass; **49 colours** (the original had 33, so the inpainting added colours). 534 pixels differ from the original. Seen enlarged on light and dark backgrounds (not a judgement): the car is recognisably the same (stripes, windows, wheels, green, direction), the bumper's lower edge was redrawn as a lighter chrome bar with a small orange light below it. **A shadow is still there**: a hard-edged dark wedge under the whole car, smaller and flatter than the original but still a dark ground shape beside the wheels and under the bumper, so the shadow was reduced, not removed. The body shading and the tyres look slightly changed in places.

### Fresh generation with "no shadow" (Asset Generation Agent, 2026-10-12)

One call to `POST /create-image-pixflux` with the same settings as the first sprite (128x128, isometric, no_background, south-west, high top-down view, selective outline, detailed shading, highly detailed, guidance 8; HTTP timeout 600 s). The prompt is the first prompt plus ", no shadow, no ground shadow, no drop shadow, nothing under the car, car floating on a fully transparent background" (full text in the record). Balance before 4997, after **4996** of 5000 (1 generation, $0.00). One image, saved as `game/art/car/car_sw_front_v2.png` with its record `car_sw_front_v2.json`; every existing file is unchanged.

Check script: 128x128, transparent corners and no semi-transparent pixels pass; **61 colours** (limit about 30, so it fails; the first sprite had 33). Seen enlarged on light and dark backgrounds (not a judgement): **a shadow is still visible**, a hard-edged dark wedge under the car, beside both wheels and under the bumper, much like the first sprite's. This is a different car from the first sprite: brighter, more saturated green, a visible red interior through the windows, a black air scoop on the bonnet, wider white stripes with a thin dark line inside them on the bonnet, a chrome bumper with a dark grille. The "no shadow" wording did not remove the shadow. No further calls made.


2026-10-12, fifth note: the board approved the **original** sprite, `car_sw_front.png`, shadow included; it stays in `game/art/car/` and is the one T-101 builds on. New rule (Visual style, Decisions, 2026-10-12): every generated asset is kept, and only clean, game-ready art lives under `game/art/`. Move every other version from this task (the script-edited one, the PixelLab inpaint result and its mask, the fresh `_v2` generation), with their records, to `art-archive/T-014/`, and T-003's test-run art (`game/art/_test-run/`) to `art-archive/T-003/`. Delete nothing. No more generations.

### Archiving (Asset Generation Agent, 2026-10-12)

No PixelLab calls. With `git mv` (nothing deleted): `car_sw_front_noshadow.png`, `car_sw_front_noshadow_pixellab.png`, `car_sw_front_noshadow_pixellab_mask.png` and `car_sw_front_v2.png`, with their `.json` records, moved from `game/art/car/` to `art-archive/T-014/`; T-003's `sports-car` and `asphalt-road-tile` (png and json) moved from `game/art/_test-run/` to `art-archive/T-003/`. Their Godot `.import` files were removed (removed with `git rm`; they are generated). Before moving T-003's art I searched the repo: no scene, script or test names it (the GUT test `test_pixellab_assets.gd` scans `res://art` generically and handles the folder being empty of them). `art-archive/` is outside `game/` (the Godot project root), so Godot does not import it. `art-archive/README.md` lists each file with its task, what it was, why it was not used and its original path; the generation log is unchanged. `game/README.md` no longer lists archived files as game art and points to the archive. `game/tools/test_remove_car_shadow.py` now reads the archived shadowless copy. Game art now under `game/art/car/`: only the approved `car_sw_front.png` (+ json, import). Documents affected: `game/README.md`, `art-archive/README.md`.


### QA round 2

**QA/Integration Agent, 2026-10-12. Result: all criteria pass and the archive check passes; needs-playtest (the board already approved the sprite, T-101 can build on it).**

1. **PNG and frame note: pass.** `game/art/car/car_sw_front.png` is byte-identical to commit ef3f8b3; 128x128; notes say frame 4.
2. **Technical rules: pass.** Check script: size, transparent corners, 0 semi-transparent pixels pass; 33 colours (script limit 30; judged "about 30" as in round 1, and the board approved this sprite).
3. **Record: pass, with a count note.** The log has 4 T-014 lines (first sprite, timed-out inpaint with `error` and no usage, inpaint retry, `_v2`), each with endpoint, prompt/settings and usage 1 generation (the timed-out one has no usage but the balance dropped, noted in the result notes). Balances in the notes run 5000, 4999, 4998, 4997, 4996, which is exactly 4 charged calls. The brief said 5 calls; QA finds 4 (the log, the records and the balance chain agree on 4), so nothing is missing. Balances live in the task notes only, not in the log.
4. **Diff scope: pass.** `git diff master..HEAD` touches no .tscn, .gd game script or placeholder sheet (only tools scripts, tests, README, art, archive, task file). Nothing in game/ references archived files (grep for art-archive, _test-run, noshadow, _v2: none).
5. **Tests: pass.** Full GUT suite passed (All tests passed); `game/tools` Python 72 OK; `tools` Python 75 OK. Line-ending .import changes discarded, not committed.

**Archive check: pass.** `art-archive/` holds T-014 (noshadow, noshadow_pixellab, its mask, v2, with .json records) and T-003 (sports-car, asphalt-road-tile, png and json). `git log --diff-filter=D --name-only master..HEAD` lists only two `.import` files. `game/art/` holds only `car/` (approved png, json, import), `placeholders/` and the log. `art-archive/README.md` lists all 6 entries with task, what it was, why unused and original path (the mask has no .json record by design; it is an input).

### Board review

The board approved the original sprite (car_sw_front.png), shadow included, on 2026-10-12, after a script edit, two inpaint calls and a fresh generation all left the shadow problem unsolved or changed the car. The other versions are archived in art-archive/T-014/.

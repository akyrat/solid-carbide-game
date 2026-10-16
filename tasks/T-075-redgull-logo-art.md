---
id: T-075
title: Art: the Redgull logo, a seagull's head in profile in one shade of dark red
status: in-qa
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
qa_rounds: 0
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

- [ ] A check script shows the sample uses exactly one visible colour (a dark red), has a transparent background and no semi-transparent pixels (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; the calls after the first sample stay within the board's allowance of 10 generations (QA: pass / fail)
- [ ] The sample is saved under `game/art/` with its raw output in `art-archive/T-075/`, and Godot imports it (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the sample's look (a seagull's head in profile, minimal, one dark red). Once approved, the other sizes follow from it.

## Updates

### 2026-10-16, Open → In progress

Started: rescoped to your direction (seagull head in profile, one shade of dark red, minimal). One PixelLab sample first for your review.

### 2026-10-16, In QA

Sample made (1 generation, 4909 -> 4908). It reads poorly: a bell / letter-R blob with an eye hole, no gull beak or forehead. QA held until the board picks the next step: free scripted silhouette (recommended) or one more paid call.

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

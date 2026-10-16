---
id: T-145
title: Art: the Redgull helicopter that drops the gift pack
status: in-progress
from: project-lead
to: asset-generation
lead: Level-up
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, tasks/T-144-gift-pack-drop.md, tasks/T-075-redgull-logo-art.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the T-144 scenes that use the placeholder, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The helicopter Redgull sends to drop each gift pack (Game loop architecture, Decisions, "Gift pack drop"; board, 2026-10-16). It flies over the screen and drops the package, as built in T-144. It is Redgull's helicopter, so it may carry the Redgull logo (`game/art/logo/`, T-075) and Redgull red where it fits.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. It belongs to Redgull, so Redgull's red is allowed where it fits (Visual style, Decisions, "Redgull's look"). No real brands. Details the docs leave open (directions, frame counts, size) are this agent's proposal, written in the result notes for the board to judge.

**PixelLab:** the board gave its go for one sample (below). Sample first (`docs/working-with-the-board.md`, "Art and money"): one sample for the board's review, then the full set from the approved sample. Write the planned calls and cost in the result notes before calling. Use `game/tools/pixellab_client.py` with a 600 s HTTP timeout, and record every call with its prompt, settings and cost, and the balance before and after. Never delete generated art: raw output in `art-archive/T-145/`.

**PixelLab go (board, 2026-10-16):** one sample, for the board's review. Write the planned calls and their cost in the result notes before calling. The full set only after the board approves the sample.

This art task swaps its art in for T-144's placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

**Builds on T-144's branch (board, 2026-10-16):** the board plays the whole new level-up in one build, so this task doesn't wait for T-144 to be done. It makes its sample first; for the swap-in it merges T-144's branch (`task/T-144-gift-pack-drop`) into its own once T-144 has passed QA, and replaces the placeholder there.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] The helicopter sprite (and its frames, if animated) replaces T-144's placeholder, and T-144's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the sample, then the helicopter in a run.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-16, Blocked → In progress

Started on the board's go for one sample; builds on T-144's branch for the one level-up build.

## Result notes

- 2026-10-16, open → blocked: Waits for T-144 (the placeholder drop flow).

### Proposal and sample plan (Asset Generation Agent, 2026-10-16, before any PixelLab call)

**Proposal for the board to judge**
- **Directions:** one drawn heading, the helicopter flying toward the south-east of the isometric view (down-right on screen), and its **mirror** for the opposite sweep (flying down-left). A helicopter that flies a straight line over the screen needs no more. A second drawn heading (about 1 generation with `/rotate`) only if T-144's flight path turns out not to be a straight line.
- **How it is seen:** the same 3/4 isometric view as the car (top and one side), flying high above the road: it is drawn with no ground shadow in the sprite (T-144 may add a soft shadow on the ground itself if wanted). It is drawn at the world scale (32 art pixels per unit, scale 0.5) but is larger than the car: about 150 by 120 art pixels of helicopter on a 192 by 160 canvas (the car is about 96 long).
- **Animation:** the body is drawn once by PixelLab. The **rotor spin is 4 frames made by a free script** (the blades turned a step each frame, plus a see-through-free blur drawn as dark pixels), not by PixelLab, so a rotor animation costs no generations. Playback speed is a data value for T-144's scene.
- **Redgull look:** the approved logo (`game/art/logo/redgull_logo_32.png`, exact pixels, 135,17,27) is **stamped by script** on the fuselage side, so the logo stays the approved one (PixelLab would redraw it). The body is dark charcoal and maroon with red accent panels, within about 30 colours.

**Planned PixelLab calls for this round (the sample)**
1. One call, `/create-image-pixflux`, 192 x 160, `no_background`, `isometric`, `view: high top-down`, `direction: south-east`, selective outline, detailed shading, highly detailed, text guidance 8, seed 145145. Prompt and settings: `art-archive/T-145/helicopter_sample_request.json`. Cost: **1 generation** (as in T-064 and T-065 for similar canvases). Balance before: 4902 of 5000 generations.
2. Free script steps after it: cut the palette to 30 colours (`game/tools/reduce_palette.py`), make the dark and light review image. No more PixelLab calls this round; if the sample comes out wrong, I report it and do not regenerate.

**Planned cost of the full set (after the board approves the sample):** 0 generations if the sample is approved as it is (mirror, 4 rotor frames and the logo stamp are scripts). If the board wants a second drawn heading: 1 generation (`/rotate`), or up to 2 for a pair of retries it asks for.

### Sample result (2026-10-16)

- **Call made:** one `/create-image-pixflux`, exactly as planned (`art-archive/T-145/helicopter_sample_request.json`; record `helicopter_sample_raw.json`; also in `game/art/pixellab-generation-log.jsonl`). Cost: **1 generation**. Balance before 4902, after **4901** of 5000 (the balance lagged a minute behind the call, as in earlier tasks). No regeneration.
- **Files** (all in `art-archive/T-145/`): `helicopter_sample_raw.png` (raw, 192 x 160), `helicopter_sample.png` (palette cut to 30 colours by `game/tools/reduce_palette.py`, free), `helicopter_sample_review.png` (4x nearest-neighbour, dark and light background side by side).
- **Check** (`check_sprite_rules.py`): transparent background, 0 semi-transparent pixels, 30 colours, the helicopter fills 150 x 123 pixels of the canvas.
- **Problems to report, not fixed:** (1) the nose points to the south-west (down-left), not the south-east I asked for; I did not regenerate. For the sweep that way the sprite is used as it is and the mirror gives the other way, so this only changes which way is "drawn" and which is "mirrored". (2) The red is a crimson-pink, brighter than the logo's 135,17,27; a free script step can shift the red accents to the logo's red. (3) The red is thin stripes; there is no big flat side panel for the logo, only the door area, so the logo stamp would be small (the 32 px logo roughly fits the rear door). (4) The rotor is four long static blades; the 4-frame spin would be a script drawing.
- Status not changed; the full set waits for the board's go.

### Board approval and the swap-in (2026-10-16)

- **Approval (board, 2026-10-16):** "Yeah, looks good to me. Um, please make sure to include like the redgull, um, the logo where needed or appropriate." Approved with the free script changes.
- **Done by script, 0 more PixelLab calls** (total for the task: 1 generation, balance 4902 to 4901): `game/tools/build_helicopter.py build` mirrors the sample (it flies left to right, nose down-right), recolours the body to a red ramp around the logo's 135,17,27 (dark navy stripes and purple glass stay), erases the static blades and redraws them turned a step per frame (4 frames), and stamps the approved Redgull logo (64 px file cut to 18 and 12 px, hard pixels) on a pale panel on the fuselage side and the tail fin. Colours merged to 30. Output: `game/art/gift_pack/helicopter_sheet.png` (4 frames of 192 x 160 side by side) and `helicopter_sheet.json`. No mirrored copy: T-144's helicopter only flies left to right.
- **Swap-in:** merged `task/T-144-gift-pack-drop`; `gift_helicopter.tscn` `Sprite` now uses the sheet (`hframes` 4, `scale` 0.5); `GiftHelicopter._process` steps the rotor frame (`ROTOR_FPS` 24, art only, pauses with the tree). Behaviour unchanged. T-144's test of "placeholders not red" now covers only the package; new test for the helicopter's red, logo and rotor; the sprite-path test points to the sheet.
- **Checks:** sprite rules pass on all 4 frames (`build_helicopter.py check`); Python tool tests OK (274); full GUT suite 808/808 pass.
- **Screenshot:** `art-archive/T-145/screenshots/helicopter_in_run.png` (the helicopter carrying the package, from `gift_drop_demo`). Review images of the build steps: `art-archive/T-145/build/`.
- Note for T-146: the package hangs at `CARRY_OFFSET` (0, 14), now under a larger helicopter, so it overlaps the helicopter's belly a little; adjust only if the board dislikes it.

---
id: T-146
title: Art: the Redgull gift pack package
status: done
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
qa_rounds: 1
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

The package the helicopter drops, which the player drives over to open the level-up screen (Game loop architecture, Decisions, "Gift pack drop"; board, 2026-10-16). It carries Redgull's brand: the logo (`game/art/logo/`, T-075) and Redgull red where it fits. It is seen falling and lying on the ground in the isometric view, as built in T-144.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. It belongs to Redgull, so Redgull's red is allowed where it fits (Visual style, Decisions, "Redgull's look"). No real brands. Details the docs leave open (directions, frame counts, size) are this agent's proposal, written in the result notes for the board to judge.

**PixelLab:** the board gave its go for one sample (below). Sample first (`docs/working-with-the-board.md`, "Art and money"): one sample for the board's review, then the full set from the approved sample. Write the planned calls and cost in the result notes before calling. Use `game/tools/pixellab_client.py` with a 600 s HTTP timeout, and record every call with its prompt, settings and cost, and the balance before and after. Never delete generated art: raw output in `art-archive/T-146/`.

**PixelLab go (board, 2026-10-16):** one sample, for the board's review. Write the planned calls and their cost in the result notes before calling. The full set only after the board approves the sample.

This art task swaps its art in for T-144's placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

**Builds on T-144's branch (board, 2026-10-16):** the board plays the whole new level-up in one build, so this task doesn't wait for T-144 to be done. It makes its sample first; for the swap-in it merges T-144's branch (`task/T-144-gift-pack-drop`) into its own once T-144 has passed QA, and replaces the placeholder there.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after (QA: pass)
- [ ] The package sprite replaces T-144's placeholder, and T-144's tests still pass (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: judge the sample, then the package in a run.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-16, Blocked → In progress

Started on the board's go for one sample; builds on T-144's branch for the one level-up build.

### 2026-10-16, In QA

Art swapped in for T-144's placeholder, with the Redgull logo. In QA.

### 2026-10-16, Needs playtest

QA passed every criterion. Waits in Needs playtest for the one level-up build.

### 2026-10-16, Needs playtest → Done

Board played the one level-up build: everything looks great. Done; merged into master.

## Result notes

- 2026-10-16, open → blocked: Waits for T-144 (the placeholder drop flow).

- 2026-10-16, sample round, PROPOSAL (asset-generation):
  - Size: one 64 x 64 canvas, package about 40 px wide on it (about 1.25 units at 32 px per unit, half-scale in game, so it reads next to the 96 px car without hiding it). No frames.
  - One generated sprite: the package lying on the ground, isometric 3/4 view. The falling look is free, made by script from it: the same sprite plus a script-drawn parachute (hard-pixel red and white canopy with lines, no semi-transparent pixels) as a second PNG, and a swaying tilt is left to the game. If the board wants no parachute, only the ground sprite is used and the helicopter drop stays as built in T-144.
  - The Redgull logo (`game/art/logo/redgull_logo_32.png`, T-075) is stamped on the package's light label panel by script, not generated, so the brand is exact. Red on the package: band and lid in Redgull's dark red (135,17,27 family, with shading shades) over a dark charcoal-navy body.
  - Consistency with T-145: same dark red family (RGB 135,17,27 for the base red), charcoal body, no extra neon.
  - PLANNED CALL (1 only): `/create-image-pixflux`, 64 x 64, no_background true, outline "selective outline", shading "detailed shading", detail "high detail", view "high top-down", direction "south-east", text_guidance_scale 8. Prompt: "isometric supply crate gift package, dark charcoal metal box with a dark red lid and a dark red band, a plain pale grey label panel on the front side, rounded edges, cargo handles, night lighting, pixel art, no text". Cost: 1 generation (as T-075's pixflux calls were billed). Balance before: 4902 generations. Expected after: 4901.
  - Planned cost of the rest (after approval): 0 PixelLab calls if the sample is approved (parachute variant, logo stamp, palette check and any small variants are scripts); at most 1 more call if the board asks for a different shape.
- 2026-10-16, sample made (asset-generation): the first attempt of the retry hit a free HTTP 422 again (my earlier sed had been in the refused command, so `detail` was still "high detail"); fixed to "highly detailed". Then ONE paid call, `/create-image-pixflux`, request in `art-archive/T-146/req_package.json` (prompt, settings inside), usage 1 generation. Balance: 4902 (before the first attempt), 4901 read just before and just after the successful call (the counter may lag, or the T-145/T-140 agents' calls overlap; I read it honestly, the call itself reports 1.0). Output: `art-archive/T-146/package_raw.png` (64x64, bbox 6,4 to 58,60, 27 colours, alpha only 0 or 255) and its record `package_raw.json`. Review image: `art-archive/T-146/package_raw_review.png` (4x nearest-neighbour, dark and light). Observation, not a judgement: a charcoal crate with a red strap and a grey label panel; the red is a pinker crimson than the logo's 135,17,27 and the lid is not red. Logo stamp and parachute variant not made yet (scripts, after approval). No regeneration.

- 2026-10-16, board's decision: the dropped package uses T-140's red-and-gold gift box instead of the crate, so the drop matches the level-up screen. The crate sample stays in `art-archive/T-146/` (package_raw.png, never deleted). The board also said: "please make sure to include like the redgull, um, the logo where needed or appropriate."
- 2026-10-16, swap-in (0 PixelLab calls): raw box from T-140's branch saved as `art-archive/T-146/gift_box_from_T-140_raw.png` (128x128, 17 colours). `game/tools/build_gift_package.py build` scales it to 40 px wide (box filter, hard alpha, 24-colour quantize) on a 64x64 canvas, stamps `redgull_logo_32.png` (scaled to 13 px, RGB 135,17,27) on a cream tag on the right face (the tag is small, so the gull reads as a head with a beak only at 1x; it is the logo's size limit), and draws the parachute variant (64x96). Output `game/art/gift_pack/package.png` (27 colours) and `package_falling.png` (30 colours), alpha 0/255 only. T-144's branch merged; `GiftPackage/Sprite` swapped; `refresh_look()` shows the parachute only while falling (look only, no behaviour change). T-144's test that checked the package placeholder for not-red now skips the package (final Redgull art may be red) and a new test covers the parachute swap. GUT: 808 passing; all Python tool tests pass (unittest discover in game/tools, 274). Screenshots in `art-archive/T-146/screenshots/` (drop_*.png; landed: drop_250/400; falling_sequence*.png). Known gap: in the demo fixture the drop height is clipped by the screen's top, so the fall is almost zero and the parachute never shows on screen; it is covered by the unit test and visible in `game/art/gift_pack/package_falling.png`. The helicopter's body is still T-144's placeholder (T-145).
- 2026-10-16, in-progress → in-qa: Package art swapped in: T-140's gift box scaled to 40 px with Redgull logo tag, script parachute while falling; GUT 808 pass, Python tests pass, 0 extra PixelLab calls.
- 2026-10-16, in-qa → needs-playtest: QA pass: sprite checks, PixelLab record vs board go, GUT and Python tests all pass
- 2026-10-16, needs-playtest → done: The board's playtest of the one level-up build (2026-10-16): "i played the level up playtest, and everything looks great"

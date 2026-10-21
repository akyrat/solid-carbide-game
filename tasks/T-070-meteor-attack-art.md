---
id: T-070
title: Art: the kaiju's meteor attack (warning circle, meteor, dust burst)
status: in-progress
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-046]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/enemies.md, tasks/T-046-kaiju-meteor-attack.md]
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

**Rescoped by the board (2026-10-21), after the PixelLab sample.** The board doesn't want new meteor pictures: the meteor already falls as it should. Add only two animations (Visual style, Decisions, "The kaiju's meteor attack"):

- a **comet tail** that streams behind the meteor while it falls;
- an **impact animation** when it hits the ground, before it becomes the boulder.

Keep the meteor, the warning circle and the boulder as they are. How to make the two animations is your choice (board, 2026-10-21): PixelLab (its animation endpoints, if they suit effects), a script, Godot particles, or a mix. The board's go covers up to 10 PixelLab generations for this task; plan the calls and cost in the result notes first, as usual, and the earlier sample stays in `art-archive/T-070/`. Use the boulders' magenta and violet glow, never Redgull red.

Make **two or three different versions** of the tail and impact, for the board to compare. The board wants to **see them animated**, not judge still images: record a short video (MP4 or GIF) of each version, with a few meteors falling with their tails and hitting the ground in a real run, into `art-archive/T-070/screenshots/` (`tasks/README.md`, "Screenshots"). In the build, one setting picks the version (say which in `game/README.md`), so the board can also play each one. Lengths, sizes and frame counts are your proposals.

The rest of this description is the original brief, kept for its style rules, which the animations follow where they apply.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] While a meteor falls, a comet tail streams behind it, and when it lands an impact animation plays before the boulder appears; the meteor, warning circle and boulder are unchanged (QA: pass / fail)
- [ ] Two or three versions exist, one setting picks between them (documented in `game/README.md`), and a recording (MP4 or GIF) of each from a real run shows several meteors falling with their tails and hitting the ground, in `art-archive/T-070/screenshots/` (QA: pass / fail)
- [ ] The record lists every PixelLab call with its settings and cost, and the balance before and after, at most 10 generations; the animations use no Redgull red (QA: pass / fail)
- [ ] Tests cover that the tail shows only while falling and the impact plays once on landing; T-046's and T-147's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run and watch the meteors' tails and impacts.
Board review files: the recording in `art-archive/T-070/screenshots/`.

## Updates

### 2026-10-21, Open → In progress

Started at the board's request, in C:\solid-carbide-worktrees$t.

### 2026-10-21, In progress → In QA

Meteor sample is weak: a stone pillar on a tile base, not a falling meteor (1 generation, 4860 to 4859). Recommended: the free option, the approved boulder as the falling body with a script-drawn trail. Pictures: C:\solid-carbide-worktrees\T-070\art-archive\T-070\review_meteor_dark.png

### 2026-10-21, In progress

Started: the agent makes 2 or 3 versions of the comet tail and impact, with a video of each.

## Result notes

### Sample round (2026-10-21, board's go for PixelLab given)

Planned call (written before calling): 1 x `/create-image-pixflux`, 128 x 128, isometric, no background, selective outline, detailed shading, highly detailed, text guidance 8; prompt in `art-archive/T-070/meteor_req.json`. Expected cost: 1 generation. Balance before: 4860 generations (Tier 2, 5000 total). After: 4859. Actual cost: 1 generation. HTTP timeout 600 s. One round, no regeneration.

Result: `art-archive/T-070/meteor_sample_raw.png` (record `meteor_sample_raw.json`). 57 colours (over the 30 limit; would need `reduce_palette.py`), no semi-transparent pixels, transparent background. Review images: `art-archive/T-070/review_meteor_dark.png` and `review_meteor_light.png` (4x, nearest-neighbour, boulder_a on the left for scale). Problems: the model drew a purple stone pillar standing on a paved tile base, with a thin pale streak at the top right, so it does not read as a falling meteor and the tile base is unusable. The palette and cracks match the boulders. Not regenerated.

Proposal for the rest (the board judges):
- Free, script-drawn (like the level-up particles and drift smoke, Visual style): the warning circle (a pixel-art ellipse ring on the isometric ground, no Redgull red by the placeholder rule, but the docs call for a red danger circle: the board should say whether a traffic-sign red is allowed here as for the alert signs; otherwise orange), and the dust burst (a few script-drawn grey-brown puff frames, no PixelLab).
- Free alternative for the meteor itself: reuse boulder_a (already approved art) as the falling body, with a script-drawn magenta and violet trail drawn behind it. This costs no generations and makes the falling rock match the landed boulder exactly.
- Paid, only if the board wants a distinct falling look: one more round of the meteor with a changed prompt (a round fireball rock, no tile or base) or the boulder as `init_image`. Not done: needs the board's say.
- Nothing swapped into the game yet.

Skipped commands: none refused.

### Rescoped round: comet tail and impact, three versions (2026-10-21)

**Planned before calling:** 2 x `/animate-with-text-v3` (tail, impact), 8 frames each from a script-drawn first frame, no_background, seeds 70001 and 70002, 600 s timeout, expected about 1 generation each (T-068's walk calls cost 1 each); the rest free. Balance before: 4856 (Tier 2).
**Actual:** each call cost **2 generations** (records in `game/art/pixellab-generation-log.jsonl`), 4 in all for the rescope (5 with the earlier sample, of the 10 allowed). Balance after: 4839; the account is shared with other sessions running at the same time, so the drop (17) is not all this task's: the calls' own usage is 2 + 2. Params: `art-archive/T-070/pixellab/{tail,impact}_req.json`; raw frames (9 each, first 8 used) in `pixellab/{tail,impact}_raw/`. No regeneration.

**How each version is made** (setting `data/meteor_fx.json` `version`, env `METEOR_FX`; `game/README.md`, "Meteor effects"):
- `pixel` (default): script-drawn sheets (`game/tools/build_meteor_fx.py build`): a 6-frame tapered violet-to-white tail with shed sparks, and an 8-frame impact (white flash and spike, 2:1 shockwave ring, glow pool, rock shards, grey-violet dust puffs). 0 generations.
- `pixellab`: the same first frames animated by PixelLab, cut to 128 x 128, 30 colours max, hard alpha (`from-pixellab`). 4 generations.
- `particles`: no art files, square pixel embers, ring, sparks, shards, dust drawn live in `meteor_fx.gd`, impact 0.6 s. 0 generations.
- `off`: the old placeholder.
The meteor, warning circle and boulder are unchanged; the boulder still appears at the instant of landing (delaying it would change T-046/T-147 behaviour), so the impact's first flash frames play over it rather than before it. Cell 128 art px drawn at 0.75 (proposal).

**Honest judgment (the board judges):**
- `pixel`: the most consistent look; the tail reads as a violet comet streak, the impact is a clear flash, ring and puffs. The tail is a smooth gradient (less "pixel art" than the boulders), the ring is flat and wide, a bit like a splash.
- `pixellab`: tail is almost the same as the script one but gets a stray white star at the head in some frames (looks like a glitch); the impact turned pale pink and blobby, the dust became pink bubbles, less readable than the script version. Weakest; not regenerated.
- `particles`: chunkier, clearly pixel-blocky and lively (sparks, flying shards), but the tail is thin and sparse (a short streak with a few pink squares) and the dust squares look boxy.
- Recommendation: `pixel`, optionally with the particles' flying shards.

**Recordings** (GIF, 9 s each, from the real run scene via `tests/fixtures/meteor_fx_demo.tscn`, three meteors every 1.5 s): `C:\solid-carbide-worktrees\T-070\art-archive\T-070\screenshots\meteor_fx_pixel.gif`, `meteor_fx_pixellab.gif`, `meteor_fx_particles.gif`. Previews of the sheets: `art-archive/T-070/preview_*`.
**Tests:** `tests/unit/enemies/test_meteor_fx.gd` (tail only while falling, impact once and gone, each version draws, setting, sheets, no red) and `game/tools/test_build_meteor_fx.py`. All pass: GUT 1196/1196 (needed GUT_TIME_LIMIT=900, the default 300 s timed out on a loaded machine), game/tools unittest 361 OK, tools unittest OK. T-046's and T-147's tests are in that run.
**Skipped/refused commands:** none refused (one hook rejected `pip list` and a `sed -n` once; I used other read tools).
**Proposals:** the default version `pixel`; cell size and scale; frame counts; the fixture and recording script.
**Documents affected:** game/README.md updated.
- 2026-10-21, in-progress → in-qa: Meteor sample ready for the board alone, no QA agent
- 2026-10-21, in-qa → in-progress: the board took it out of QA with 5 acceptance criteria not marked

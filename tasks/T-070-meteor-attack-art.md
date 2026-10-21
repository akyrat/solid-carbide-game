---
id: T-070
title: Art: the kaiju's meteor attack (warning circle, meteor, dust burst)
status: in-qa
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

Keep the meteor, the warning circle and the boulder as they are; don't call PixelLab (no new generations; the sample already made stays in `art-archive/T-070/`). Make both animations by script or as Godot effects, free, in the boulders' magenta and violet glow, never Redgull red. Their length, size and number of frames are your proposals for the board's playtest. The board wants to **see them animated**, not judge still images: record a short video (MP4 or GIF) of a few meteors falling with their tails and hitting the ground, in a real run, into `art-archive/T-070/screenshots/` (`tasks/README.md`, "Screenshots"), and the board plays the build.

The rest of this description is the original brief, kept for its style rules, which the animations follow where they apply.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] While a meteor falls, a comet tail streams behind it, and when it lands an impact animation plays before the boulder appears; the meteor, warning circle and boulder are unchanged (QA: pass / fail)
- [ ] A recording (MP4 or GIF) from a real run shows several meteors falling with their tails and hitting the ground, in `art-archive/T-070/screenshots/` (QA: pass / fail)
- [ ] No new PixelLab calls were made after the sample, and the animations use no Redgull red (QA: pass / fail)
- [ ] Tests cover that the tail shows only while falling and the impact plays once on landing; T-046's and T-147's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run and watch the meteors' tails and impacts.
Board review files: the recording in `art-archive/T-070/screenshots/`.

## Updates

### 2026-10-21, Open → In progress

Started at the board's request, in C:\solid-carbide-worktrees$t.

### 2026-10-21, In progress → In QA

Meteor sample is weak: a stone pillar on a tile base, not a falling meteor (1 generation, 4860 to 4859). Recommended: the free option, the approved boulder as the falling body with a script-drawn trail. Pictures: C:\solid-carbide-worktrees\T-070\art-archive\T-070\review_meteor_dark.png

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
- 2026-10-21, in-progress → in-qa: Meteor sample ready for the board alone, no QA agent

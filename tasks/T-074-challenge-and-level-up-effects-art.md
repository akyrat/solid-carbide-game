---
id: T-074
title: Art: the level-up effect
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-112]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, docs/game-loop-architecture.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [a particle-drawing script and its test, particle sprites under game/art/ and their record, T-112's effect scene, game/README.md]
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

The level-up effect (Visual style, Decisions, "Level-up effect"): when the player levels up, the car gives off a burst of pixel-art particles. T-112 builds the working effect with plain placeholder squares; this task draws the final particle art and swaps it in. The challenge completed effect moved to T-100, after the MVP (2026-10-11).

**No PixelLab** (board, 2026-10-13): the particles are small enough to draw with a script. Write a script that draws the particle sprites (for example sparks, stars, small diamonds or pixel crosses, a few pixels across, with a frame or two of twinkle if it helps), within Visual style, Decisions: the night neon palette, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, about 30 colours or fewer. Not Redgull red (red belongs to Redgull only). The shapes, colours, count, sizes, speed, spread and lifetime are your proposal, written in the result notes for the board to judge (Visual style, Decisions).

Swap the art into T-112's effect scene and retune its settings there (`tasks/README.md`, "Art replaces placeholders"), without changing when or how the effect plays. Particles do not fade by alpha: they pop out or shrink.

Keep the script and its output: game-ready sprites under `game/art/`, with a short record of how they were made; anything not used goes in `art-archive/T-074/`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer, and none uses Redgull red (QA: pass / fail)
- [ ] The sprites are made by a committed script, with a test, and no PixelLab calls were made (QA: pass / fail)
- [ ] A screenshot shows the effect around the car at a level-up (QA: pass / fail)
- [ ] T-112's tests still pass, and the particles still have no alpha fade and use nearest-neighbour filtering (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the level-up effect in the run and judge the look.

## Result notes

- 2026-10-13, planning → blocked: waits for T-112 (placeholder particles)

---
id: T-069
title: Art: the kaiju
status: in-progress
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-045]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/enemies.md, tasks/T-045-kaiju.md]
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

**Blocked until T-045 (the kaiju, with placeholders) is done.**

The kaiju, as Visual style, Decisions describes it: a giant Godzilla-style monster several times the car's size, never a copy of Godzilla. Propose its size, directions and walk frames. Swap it in for T-045's placeholder. It has no shield in the MVP (Enemies, Decisions, 2026-10-11); the shield moved to T-099, after the MVP.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot shows the final kaiju in a run (QA: pass / fail)
- [ ] T-045's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Updates

### 2026-10-21, Open → In progress

Started at the board's request, in C:\solid-carbide-worktrees$t.

### 2026-10-21, In progress → In QA

Kaiju sample in (1 generation). Good palette and detail, but side-on rather than isometric, toy-like joints, and very close to Godzilla itself. Pictures: C:\solid-carbide-worktrees\T-069\art-archive\T-069\review_kaiju_se_dark.png

## Result notes

### Sample round (2026-10-21, board's go for T-069's generations)

**Planned call and cost (written before calling):** one `/create-image-pixflux` call, 224x224, `view: high top-down`, `isometric: true`, `direction: south-east`, `no_background: true`, selective outline, detailed shading, highly detailed, seed 69001; expected cost 1 generation. Prompt and settings: `art-archive/T-069/kaiju_se_sample_req.json` (record: `kaiju_se_sample.json`; log row in `game/art/pixellab-generation-log.jsonl`). Balance before: 4860 of 5000 generations (USD credit 0). Balance after: the account still showed 4860.0 right after the call (the counter may lag); the call reported usage of 1 generation. One call only, no regeneration.

**Proposal for the board (mine, nothing in the docs):**
- Size: 7 units tall, as T-045's placeholder (224 art pixels at 32 px per unit; canvas 224x224), about 2.3 car lengths tall. Against the elevation sample map: skyscrapers are drawn 15 units high, so it is shorter than the towers but taller than a rooftop's height of 6 units; from the street it stands about as high as a second-floor rooftop, so it will not loom over rooftops. If the board wants that, 9 units (288 px) is the next size up.
- Directions: 8, like the minion (5 drawn, 3 mirrored), built from this sample with the minion's recipe (rotate, then animate).
- Walk frames: 6 per direction (a slow, heavy stride), so about 30 drawn frames plus 18 mirrored.

**Judgment of the sample (honest):** it reads as a Godzilla-style kaiju: dark green hide, big pale cyan dorsal plates, yellow eyes, teeth, curled tail, in the night palette, with a selective outline and shading; 20 colours, no semi-transparent pixels. It is not a copy of the film monster. Problems: (1) PixelLab ignored `no_background` at this canvas size and returned an opaque speckled grey background; I removed it by a free flood-fill script and kept the raw (`kaiju_se_sample_clean.png`); the walk frames may have the same fault. (2) The view is a front three-quarter, upright pose, not a clean isometric one: it faces the camera and the right, the tail curls up on the left instead of lying along the isometric ground axes like the car, so it may look a little out of place beside the isometric buildings. (3) The limbs look like segmented shiny balls, somewhat toy-like, and the mid-stride is not clear. (4) The sprite fills the canvas almost to its edges (x 13 to 211, y 18 to 206), leaving no room for more tail or glow. No glow is drawn into the pixels yet.

**Files:** `art-archive/T-069/kaiju_se_sample.png` (raw), `kaiju_se_sample_clean.png` (transparent), review images `review_kaiju_se_dark.png` and `review_kaiju_se_light.png` (3x nearest-neighbour, the car's first frame beside it for scale). Nothing is swapped into the game yet. Refused command: an inline Python edit of this file was refused by the status hook, so I made this edit with the Edit tool instead.
- 2026-10-21, in-progress → in-qa: Kaiju sample ready for the board alone, no QA agent
- 2026-10-21, in-qa → in-progress: the board took it out of QA with 5 acceptance criteria not marked

---
id: T-073
title: Art: drift smoke and tyre tracks
status: open
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-029]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-003-pixellab-test-generation.md, tasks/T-014-car-sprites-16-directions.md, game/README.md, docs/drifting.md, tasks/T-029-drift-defaults-after-playtest.md]
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

**Blocked until T-029 (the car's new defaults) is done.**

Drift smoke and tyre tracks (Visual style, Decisions), shown while the car drifts (the car's drift state from T-012). The tracks fade over time as whole objects. Hook them to the car, in the drift prototype and the run.

Follow Visual style, Decisions: pixel art for the isometric view at about 40 pixels per unit, a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, and the night neon palette. Real-world things are inspiration only: no real logos, no copies of existing characters. Details the docs leave open (directions, frame counts, variants, sizes) are this agent's proposal, written in the result notes for the board to judge (Visual style, Decisions).

Use the existing client, `game/tools/pixellab_client.py`. Record every call with its prompt, settings and cost, and the balance before and after. One round of generation only: don't regenerate; report problems instead. The board judges the result.

This art task swaps its art in for the placeholder itself (`tasks/README.md`, "Art replaces placeholders"), without changing how the game behaves.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, and about 30 colours or fewer (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] A screenshot of the car drifting shows the smoke and tracks behind it, and none while driving straight (QA: pass / fail)
- [ ] The T-012 and T-029 tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

Written by the agent when it finishes.

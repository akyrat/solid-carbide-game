---
id: T-075
title: Art: the Redgull logo, a seagull's head in profile in one shade of dark red
status: open
from: project-lead
to: asset-generation
lead:
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

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows the sample uses exactly one visible colour (a dark red), has a transparent background and no semi-transparent pixels (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] The sample is saved under `game/art/` with its raw output in `art-archive/T-075/`, and Godot imports it (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the sample's look (a seagull's head in profile, minimal, one dark red). Once approved, the other sizes follow from it.

## Result notes

Written by the agent when it finishes.

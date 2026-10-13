---
id: T-130
title: Art: a few alert banners about the kaiju, on buildings and on the pavement
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-128, T-064]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-128-narrative-tokyo-under-attack.md, tasks/T-064-building-art.md]
files_expected_to_change: [art under game/art/ and its records, the map's drawing of banners, tests, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board wants **a few** banners (only a few!) around the city alerting about the monster (Visual style, Decisions, 2026-10-14): some hanging on buildings, some standing as signs on the pavement, each with a silly, minimalistic pixel painting of the kaiju's head or its general Godzilla-like body shape. Their form and any words come from T-128 (approved by the board); if they carry words, those words are the approved text, and this task does not start until they are approved.

Propose how many banners on the whole map (a few), where (which buildings and pavement spots; never on the roads, never blocking the car), and how many designs, in the plan. Banners are visual only: no collisions. They sit in the map's depth order and fade with the building they hang on.

Follow Visual style, Decisions: pixel art for the isometric view at the game's pixel density (the car and ground are drawn at 32 art pixels per unit, scale 0.5), a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, the night neon palette, no Redgull red. Real-world things are inspiration only: no real logos, no copies of existing characters (the kaiju is "in the style of Godzilla", never Godzilla). Read T-128's narrative guidance first and keep the look consistent with every approved asset (car, ground, boulders, drift marks and smoke).

PixelLab: never call it without the board's go for this task. Plan first (calls, sizes, cost) in the result notes and bring it to the board; then one sample for the board's review; then the full set from the approved sample. Use `game/tools/pixellab_client.py` with a 600 s timeout, record every call with its prompt, settings and cost and the balance before and after, and do not regenerate weak results: report them. Free script fixes come before paid calls. Never delete generated art: unused versions go to `art-archive/<task>/`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; every call had the board's go (QA: pass / fail)
- [ ] Screenshots in a run show the banners on buildings and on the pavement, only a few on the map, none on the roads; any words are exactly T-128's approved text (QA: pass / fail)
- [ ] The banners have no collisions, sit in the right depth order and fade with their building; T-034 and T-064's tests pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the city and judge the banners.

## Result notes

- 2026-10-14, open → blocked: waits for T-128 and T-064

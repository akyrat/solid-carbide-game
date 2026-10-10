---
id: T-084
title: Art: the comic-style look of the trick popups
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-091]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, tasks/T-083-hud-combo-and-trick-popups.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the popup scene, game/README.md]
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

**Blocked until T-091 (the popups, with placeholder styling) is done.**

The trick popups use comic-style writing (HUD and menus, Decisions). Make that look, in the game's pixel-art style and night neon palette (Visual style, Decisions): a comic-style burst or shape behind the text, and a pixel font with comic lettering. If you use an existing font, it must have a licence that allows use in a commercial game; record its source and licence. Swap it in for T-091's placeholder styling (it covers the challenge popup from T-092 too, once that exists) (`tasks/README.md`, "Art replaces placeholders"). PixelLab calls are recorded with their cost as usual; one round of generation only.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot shows each trick's popup in the final comic style (QA: pass / fail)
- [ ] The font's source and licence are recorded, and the licence allows commercial use (QA: pass / fail)
- [ ] Every PixelLab call is recorded with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] T-091's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

Written by the agent when it finishes.

---
id: T-086
title: Art: the heart icon on the likes bar
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-049]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, tasks/T-048-text-hud.md, tasks/T-049-hud-run-values.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the HUD scene, game/README.md]
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

**Blocked until T-049 (the HUD, with a placeholder heart) is done.**

The likes bar shows the word "Likes" with a heart icon at its left end (T-048, approved by the board). The icon: a small, plain, flat heart in Redgull red, like a social app's like button, with a thin dark outline so it reads on any background; small enough to sit beside the label. Follow Visual style's technical rules (pixel art, no anti-aliasing, no semi-transparent pixels, transparent background). PixelLab calls are recorded with their prompt, settings and cost, and the balance before and after; one round of generation only. Swap it in for T-049's placeholder heart (`tasks/README.md`, "Art replaces placeholders").

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot of the HUD shows the final heart next to "Likes" (QA: pass / fail)
- [ ] A check script shows the icon has a transparent background, no semi-transparent pixels, and few colours (QA: pass / fail)
- [ ] Every PixelLab call is recorded with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] T-049's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

Written by the agent when it finishes.

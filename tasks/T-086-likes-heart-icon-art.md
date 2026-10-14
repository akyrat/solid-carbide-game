---
id: T-086
title: Art: the heart icon on the likes bar
status: planning
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

T-049 (the HUD, with a placeholder heart) is done. Since T-131 the "LIKES" and "HYPE LV" texts are in the Bangers comic font with a dark outline.

The likes bar shows the word "Likes" with a heart icon at its left end (T-048, approved by the board). The icon: a small flat heart in Redgull red, like a social app's like button. **Board, 2026-10-14:** it matches the HUD's comic look: a thick dark outline like the "LIKES" and "HYPE LV" text's, a little chunky, sized to the height of the "LIKES" text so it sits level with it. **Drawn by script, no PixelLab** (a hand-placed pixel grid, like the kaiju warning signs in T-130): 0 generations. Follow Visual style's technical rules (pixel art, no anti-aliasing, no semi-transparent pixels, transparent background). The red is the Redgull red the placeholder uses (the only red on the HUD). Swap it in for T-049's placeholder heart (`tasks/README.md`, "Art replaces placeholders"); keep T-113/T-131's layout (nothing else moves). Game-ready art in `game/art/`, any other versions in `art-archive/T-086/`, with the record Visual style asks for.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot of the HUD in a run shows the final heart next to "LIKES", level with it, about the same height, with a dark outline like the text's; also one at combo step 3 (likes bar on fire) so the heart reads next to the flames (QA: pass / fail)
- [ ] A check script or GUT test shows the icon has a transparent background, no semi-transparent pixels, few colours, and uses the HUD's Redgull red (QA: pass / fail)
- [ ] No PixelLab call was made: the result notes say so and the art is made by a committed script that can rebuild it (QA: pass / fail)
- [ ] T-049's, T-113's and T-131's HUD tests (layout, combo hidden, combo heat) still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)
- [ ] `game/README.md` (the HUD section) says where the heart art is and how it is made (QA: pass / fail)

The board's review: play a run in this task's folder and judge the heart's look next to "LIKES".
Board review files: the HUD screenshots listed in the result notes

## Result notes

Written by the agent when it finishes.

---
id: T-035
title: Challenges created during a run, for the kaiju's meteors
status: open
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/enemies.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-019-build-mvp-map.md, game/README.md]
files_expected_to_change: [the challenge code, their tests, docs/level-design.md, game/README.md]
model: opus
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

**Blocked until T-019 is done:** it builds the preset challenges, their completion rule and the "challenge completed" signal.

When the kaiju attacks, its meteors land and become obstacles laid out as one of the challenge designs. A guide arrow then appears for the player to complete (Enemies, Decisions). Completing one of these challenges is the only way to make the kaiju vulnerable. Their arrows are green; the map's preset challenges are blue (Visual style, Decisions).

This task builds the challenge side, so the Enemy Behavior Agent's meteor attack (a later task) can call it:

1. **Create a challenge during a run:** a function that places one of the 3 MVP challenge designs at a given position and rotation. It uses T-019's fitted versions and 3-unit boulders, and draws the arrow corridor in **green**. It returns an id for the new challenge.
2. **Same completion rule** as the preset challenges (Level design, Decisions). On completion the arrow disappears and the boulders stay as plain obstacles.
3. **A separate signal for these challenges**, carrying the challenge's id, so the kaiju's shield logic can tell them apart from the map's preset (blue) challenges. Completing a preset challenge must not send it.
4. **Placement check:** a function that says whether a design fits at a position: no overlap with buildings, other boulders or the map edge. The meteor attack needs it to choose where meteors land.
5. **Several at once:** more than one of these challenges can exist at a time, each completed separately. How many the kaiju may have open at once is decided elsewhere (Enemies, Decisions).

The meteor sprites, the falling animation and the red warning circle are not part of this task. Use T-019's placeholder boulders, with a flat green band for the arrow.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test creates each of the 3 challenge designs during a run at a free spot and shows its boulders and green arrow corridor exist at the given position and rotation (QA: pass / fail)
- [ ] A test drives a stand-in body along a created challenge per the completion rule and shows the meteor-challenge signal fires once, with the right id. The arrow disappears and the boulders remain (QA: pass / fail)
- [ ] A test completes a preset (blue) challenge and shows the meteor-challenge signal does not fire (QA: pass / fail)
- [ ] A test shows the placement check rejects a spot overlapping a building, another boulder or the map edge, and accepts a free one (QA: pass / fail)
- [ ] A test creates two challenges at once and completes them one at a time, each signalling separately (QA: pass / fail)
- [ ] A screenshot shows a created challenge with its green arrow next to a preset challenge with its blue arrow (QA: pass / fail)
- [ ] `game/README.md` documents the functions and the signal for the Enemy Behavior Agent. `docs/level-design.md` describes them in Content without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

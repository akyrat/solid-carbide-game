---
id: T-117
title: Drift marks: the rear tyres leave marks on the ground while drifting (placeholder)
status: in-progress
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/drifting.md, game/README.md, tasks/T-112-level-up-particles-placeholder.md]
files_expected_to_change: [the car's scripts or a new drift marks scene and script, the run scene and the drift prototype scene, their tests, game/README.md]
model: opus
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

The board wants drift marks (Visual style, Decisions, "Drift marks", 2026-10-13): while the car drifts, its two rear tyres leave marks on the ground. This task builds the working effect with a placeholder look; T-118 draws the final mark texture and swaps it in, built on this task's branch, and the board playtests both together from T-118's folder.

1. **When:** marks are laid only while the car is drifting, using the car's own drift state (the same one that gives likes for drifting). No marks while driving straight or standing still. A new mark starts each time a drift starts, so separate drifts leave separate marks.
2. **Where:** one mark per rear tyre, following where each rear tyre actually is on the ground as the car turns and slides (work it out from the car's position, heading and size, Drifting, Decisions). Drawn on the ground: over the road and gravel, under the car, enemies, buildings and the HUD. They stay where they were laid when the camera or car moves.
3. **How long:** each mark stays fully visible for about 6 seconds after it was laid, then fades out as a whole and is removed (Visual style, Decisions, "See-through rule": the game may fade a whole object; no semi-transparent pixels inside the texture itself). Cap the number of mark segments kept at once so long runs stay fast; propose the numbers in the result notes.
4. **Placeholder look:** a plain dark line about one tyre wide, drawn by code or a tiny script-made texture, not Redgull red, nearest-neighbour filtering. Keep the texture, width, lifetime and fade time in one scene or resource, so T-118 can swap the art and retune without touching the code.
5. Works in the run (including runs started from the main menu) and in the drift prototype.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge: per the board's rule, nothing user-facing merges before the board has played it; the board plays it together with T-118.

## Acceptance criteria

- [ ] GUT tests show marks are laid while the car drifts and not while it drives straight or stands still, one per rear tyre, and that a new drift starts a new mark (QA: pass / fail)
- [ ] GUT tests show a mark stays for its lifetime, then fades as a whole and is removed, and that the number of segments never exceeds the cap during a long drift (QA: pass / fail)
- [ ] A GUT test or a check on the scene shows the marks are drawn above the ground and below the car, and the placeholder uses nearest-neighbour filtering and is not Redgull red (QA: pass / fail)
- [ ] A screenshot of the car drifting in a run shows two marks behind the rear tyres, and a screenshot of driving straight shows none being laid (QA: pass / fail)
- [ ] game/README.md says how the marks work and which scene and settings T-118 changes to swap the art (QA: pass / fail)
- [ ] The drift and car tests, the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest drifting in a run (from T-118's folder, together with the final marks) and judge the marks.

## Result notes

Written by the agent when it finishes.

---
id: T-093
title: Rework (T-015): zoom label, and see the zoom change while moving the slider
status: in-progress
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-015]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, tasks/T-015-pause-on-escape.md, tasks/T-047-text-pause-screen.md, game/README.md, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [the pause screen scene and script, tests, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's feedback after Playtest 1 (2026-10-11) on the pause screen built in T-015:

1. **Label:** the zoom slider's label is **Camera zoom level** (the board's own wording; T-047's board note). Replace "Camera zoom, for the fans".
2. **See the zoom change live:** while the board moves the slider on the pause screen, the game view behind must visibly zoom in and out at once. Today the change isn't visible while paused. Keep the game paused (nothing moves), but make sure the camera zoom updates immediately and the view behind the pause screen can be seen (for example by keeping the pause screen's backdrop see-through or to one side).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot of the paused run shows the label "Camera zoom level" and the map visible behind the pause screen (QA: pass / fail)
- [ ] A test moves the slider while paused and shows the camera's zoom changes at once, while the car and the clock stay paused (QA: pass / fail)
- [ ] Two screenshots at different slider values, both paused, show the view zoomed differently (QA: pass / fail)
- [ ] T-015's tests still pass (with the new label) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

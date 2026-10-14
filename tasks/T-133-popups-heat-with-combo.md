---
id: T-133
title: Trick popups heat up with the combo at x2, x3 and x4
status: open
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-131, T-132]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-131-combo-heat-levels.md, tasks/T-084-trick-popup-art.md, tasks/T-125-popups-follow-the-car.md, game/scripts/hud/trick_popups.gd, game/scripts/hud/trick_popup_art.gd]
files_expected_to_change: [game/scripts/hud/trick_popups.gd, game/scripts/hud/trick_popup_art.gd, their tests, a screenshot fixture, game/README.md, docs/hud-and-menus.md]
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

The trick popups follow the combo's heat steps from T-131 (decision: `docs/hud-and-menus.md`, Decisions, board 2026-10-14). Use T-131's thresholds and step logic (same constants, one place), applied to the multiplier the trick brought the combo to (the run state's `combo_trick` signal):

- **Below x2:** today's popup, unchanged: white rounded rectangle, black border, black Bangers lettering.
- **Step 1, from x2:** a hot accent: for example an orange border, or the "+amount" in orange.
- **Step 2, from x3:** hotter: a stronger accent (for example a thicker or yellow-orange border, both border and amount coloured).
- **Step 3, from x4 up:** a flaming edge around the popup, in the same fire style as T-131's burning likes bar.

Colour only comes in from x2: at low combo the popup stays black and white, as the board asked on 2026-10-13. The letters stay readable on white at every step. Oranges and yellows only, never Redgull red. Hard pixel edges, only opaque or fully transparent pixels, as in T-084. Size, stacking, following the car, the quarter-screen limit, three at most (T-125) and drawing above the buildings (T-132) stay as they are. The challenge popup follows the same rule. The drift prototype has no combo and keeps the plain popup. Drawn in code, no PixelLab.

Add a screenshot fixture showing one popup per step, and say in the result notes how to run it.

The board's review: play a run in this task's folder, chain tricks past x2, x3 and x4, and judge whether the popups heat up with the counter and still read well.
Board review files: the step screenshots listed in the result notes

## Acceptance criteria

- [ ] The popup's step comes from the multiplier after the trick, with the same thresholds as T-131 (one shared source; a test checks both use it): a GUT test shows tricks at x1.5, x2.0, x3.0 and x4.5 and checks each popup's step. (QA: pass / fail)
- [ ] Below x2 the popup is exactly as before (only black, white and transparent pixels; T-084's art tests still pass). (QA: pass / fail)
- [ ] Steps 1, 2 and 3 each add a visible accent and differ from each other: a test checks each step's baked image differs from the others and contains orange or yellow pixels, and the fixture's screenshots show four different looks. (QA: pass / fail)
- [ ] No Redgull red and no semi-transparent pixels in any step (test). (QA: pass / fail)
- [ ] The popup's fill stays white at every step, and the trick names stay black (test samples the colours). (QA: pass / fail)
- [ ] T-125's and T-132's popup tests and the whole GUT suite pass; the drift prototype shows plain popups. (QA: pass / fail)
- [ ] `game/README.md` ("Trick popups") and `docs/hud-and-menus.md` (Content, "Trick popups") describe the steps. (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

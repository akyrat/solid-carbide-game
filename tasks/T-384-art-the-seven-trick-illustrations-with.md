---
id: T-384
title: Art: the seven trick illustrations with PixelLab (art cap 40)
status: open
from: project-lead
to: asset-generation
lead: Goal-G-007
epic: art
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: yes
depends_on: [T-382]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/working-with-the-board.md, game/docs/hud-and-menus/tutorial-slides.md, game/docs/driving/tricks.md, game/tools/style_rules.py, game/tools/pixellab_client.py, game/tools/review_sheet.py, game/docs/setup/screenshots.md]
files_expected_to_change: [art-archive/<task id>/pixellab/, art-archive/<task id>/style-loop/, art-archive/<task id>/screenshots/, docs/visual-style.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Goal: the trick illustrations are made both by script and with PixelLab, and QA picks the one that reads better (board, 2026-10-29). This ticket is the PixelLab set, with the goal's go for at most 40 generations in all and at most 4 per illustration (the style loop: one generation and up to 3 refines; free script fixes before paid regenerations). It does not put art in game/art (the comparison ticket copies the winning set there). Make seven still pixel art PNGs, one per trick id in game/docs/driving/tricks.md (extended_drift, three_sixty, alternate_drift, air_one_eighty, air_three_sixty, airtime, thread_the_needle), each showing the car's movement (a drift curve, a loop for the 360, an S for the alternate drift, jump arcs for the air tricks, a high arc for airtime, passing between two obstacles for thread the needle), at the illustration size in game/docs/hud-and-menus/tutorial-slides.md, so they compare like for like with the script set. Write the planned calls and their cost in the result notes before calling, and the running total after each call; use a 600 s HTTP timeout. Save the kept ones as art-archive/<task id>/pixellab/<trick id>.png. Any illustration still below 8 after its refines is noted for the final playtest. Save a preview sheet and a screenshot of the trick list scene with its illustration folder set to this set. Record the set in Visual style, Decisions.

The board's review: Look at the PixelLab trick illustrations on the preview sheet; the final pick comes from the comparison ticket.

## Acceptance criteria

- [ ] Seven PNGs, art-archive/<task id>/pixellab/<trick id>.png, one per trick id in game/docs/driving/tricks.md, at the illustration size in game/docs/hud-and-menus/tutorial-slides.md. (QA: pass / fail)
- [ ] The result notes list each PixelLab call and the running total: no more than 40 generations in all and at most 4 per illustration, matching the generation log. (QA: pass / fail)
- [ ] Each PNG passes game/tools/style_rules.py art (Visual style, Rules 1 and 6). (QA: pass / fail)
- [ ] The ticket's Style review records the style loop rounds for each illustration, and any illustration below 8 after its refines is listed in the result notes for the final playtest. (QA: pass / fail)
- [ ] A preview sheet of all seven, enlarged with nearest filtering on dark and light backgrounds, and a screenshot of the trick list scene showing this set are saved in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] docs/visual-style.md, Decisions records the PixelLab trick illustrations and where they are. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

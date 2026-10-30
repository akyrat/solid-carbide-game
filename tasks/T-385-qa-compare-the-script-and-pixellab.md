---
id: T-385
title: QA: compare the script and PixelLab trick illustrations, and copy the better set into game/art
status: open
from: project-lead
to: qa-integration
lead: Goal-G-007
epic: hud-menus
milestone: mvp
goal: G-007
user_facing_text: no
changes_visuals: yes
depends_on: [T-382, T-383, T-384]
documents_affected: [docs/visual-style.md, game/docs/hud-and-menus/tutorial-slides.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/tutorial-slides.md, game/docs/driving/tricks.md, game/tools/review_sheet.py, game/tools/style_rules.py]
files_expected_to_change: [art-archive/<task id>/comparison.png, game/art/tutorial/tricks/, docs/visual-style.md, game/docs/hud-and-menus/tutorial-slides.md]
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

Goal: QA compares which set of trick illustrations reads better and the better one is used (board, 2026-10-29). Build a side-by-side comparison sheet of the script set (D3, art-archive/<D3 id>/script/) and the PixelLab set (D4, art-archive/<D4 id>/pixellab/): one row per trick, the two versions side by side, enlarged with nearest filtering on dark and light backgrounds. Judge each trick on how clearly it shows the movement at the size it is shown in the trick list, and give a verdict per trick and overall, with reasons. Proposal for the open question (one whole set or a mix): pick one whole set, the one that wins more tricks (tie: the higher average style loop score), so the slide keeps one look; list the question in the result notes for the playtest. Copy the chosen seven PNGs into game/art/tutorial/tricks/<trick id>.png (trick ids from game/docs/driving/tricks.md); the other set stays in art-archive. Record the outcome in Visual style, Decisions, and the chosen set in game/docs/hud-and-menus/tutorial-slides.md.

The board's review: Compare the two sets on the comparison sheet and check QA's pick on slide 2.

## Acceptance criteria

- [ ] A comparison sheet, art-archive/<task id>/comparison.png, shows both sets with each trick in a row, enlarged on dark and light backgrounds. (QA: pass / fail)
- [ ] The result notes record a verdict per trick and overall, with reasons, and which set was chosen. (QA: pass / fail)
- [ ] game/art/tutorial/tricks/ holds seven PNGs named by the trick ids in game/docs/driving/tricks.md, byte-identical to the chosen set's files; the other set's files are still in art-archive. (QA: pass / fail)
- [ ] A screenshot of slide 2 showing the chosen illustrations is saved in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] docs/visual-style.md, Decisions records the trick illustrations and which method won; game/docs/hud-and-menus/tutorial-slides.md names the chosen set. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-466
title: Art: Rev Charge's charging and boost effect
status: blocked
from: project-lead
to: asset-generation
lead: Goal-G-009
epic: art
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-460]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, game/scripts/driving/rev_charge_effect.gd, game/scripts/driving/boost_effect.gd, game/tools/build_boost_lines.py]
files_expected_to_change: [game/art/driving/rev_charge/, game/scripts/driving/rev_charge_effect.gd, docs/visual-style.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Drifting, Decisions, 'Driving power-ups': Rev Charge has a visible charging and boost effect. Make the charge and boost frames (PixelLab, or a free script like the cruise boost's lines if it holds up; free first) through the style loop, and swap them into D6's effect in place of its placeholder. Write the planned calls and cost in the result notes first. Record in Visual style, Decisions; archive the rest under art-archive/<id>/.

The board's review: play a run with Rev Charge and watch the charge and the boost effect.

## Acceptance criteria

- [ ] The charge and boost frames are in game/art/, with a Style review round on the ticket and the generation count (0 if script-drawn) in the result notes. (QA: pass / fail)
- [ ] The Rev Charge effect uses them instead of the placeholder, and D6's tests still pass. (QA: pass / fail)
- [ ] A recording or screenshot sequence of a charge and release is in art-archive/<id>/screenshots/. (QA: pass / fail)
- [ ] Visual style records the effect. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

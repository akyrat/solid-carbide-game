---
id: T-465
title: Art: the four driving power-up icons (PixelLab)
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
depends_on: [T-455, T-459]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, game/data/power_ups.json, game/scripts/ui/power_up_screen.gd]
files_expected_to_change: [game/art/power_ups/rev_charge.png, game/art/power_ups/jump.png, game/art/power_ups/bouncy_bumpers.png, game/art/power_ups/rusty_overcoat.png, docs/visual-style.md]
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

Drifting, Decisions, 'Driving power-ups': each power-up has an icon. Make icons for Rev Charge (charging a boost, W and S held), Jump (a hop), Bouncy Bumpers (a bigger bounce off walls) and Rusty Overcoat (a rusty armoured coat that hurts enemies on contact) with PixelLab through the style loop, as one matched set, at the exact paths power_ups.json names. Write the planned calls and cost in the result notes first; at most 4 generations per icon within the goal's art cap. The overlay cards then show them instead of D5's placeholders. Record them in Visual style, Decisions; archive other generations under art-archive/<id>/.

The board's review: look at the four power-up icons on the overlay: whether each reads as its power-up and they match as a set.

## Acceptance criteria

- [ ] Four icon PNGs exist at the paths in power_ups.json, each with a Style review round on the ticket, and the generation count is in the result notes. (QA: pass / fail)
- [ ] The power-up overlay's cards show the icons instead of placeholders, and its tests still pass. (QA: pass / fail)
- [ ] A screenshot showing all four icons (on the overlay, or a sheet of the four) is in art-archive/<id>/screenshots/. (QA: pass / fail)
- [ ] Visual style records the icons. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

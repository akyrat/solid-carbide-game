---
id: T-357
title: Art: the six bad reaction icons for a broken combo
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-356]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, tasks/T-352-art-reaction-icons.md]
files_expected_to_change: [game/art/hud/, game/scripts/hud/reactions.gd, game/tools/, art-archive/, docs/visual-style.md, game/docs/art/]
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

The board's decision (HUD and menus, Decisions, "Bad reactions when the combo breaks", 2026-10-29). Draw the six **bad reaction icons** for the burst when the combo breaks (the linked behaviour ticket): a crying-laughing face, a thumbs down, a face peeking between its hands, a broken heart, a skull and a screaming face. Same size and look as T-352's six reaction icons, which the board loved (16 x 16, bold comic outline, script-drawn), so the two sets sit together; they must read small at 0.9 alpha against the grey street. None of Greenbull's colours outside Greenbull's things (Visual style, Content, "Rules", rule 6). Save each as its own PNG in `game/art/hud/` with a record, then swap them in for the behaviour ticket's placeholders.

**PixelLab: no go.** Draw them by script, as T-352 did. Every icon goes through the style loop (at most 3 refines).

The board's review: crash in a run and see the bad reactions burst up.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/hud/` holds the six bad reaction icons, each its own PNG with a record, and they replace the behaviour ticket's placeholders in the game. (QA: pass / fail)
- [ ] Each icon scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] No PixelLab generations were used (the result notes say so). (QA: pass / fail)
- [ ] Visual style and the art docs under game/docs/art/ record the art. (QA: pass / fail)
- [ ] A contact sheet, enlarged, on a dark and a light background, and a screenshot of the burst after a crash are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

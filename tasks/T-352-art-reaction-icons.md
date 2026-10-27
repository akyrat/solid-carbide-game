---
id: T-352
title: "Art: the reaction icons (likes, thumbs up, hearts) for the livestream bursts"
status: blocked
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-351]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/README.md, tasks/T-351-reaction-bursts-on-a-sub-goal-and-at-high-viewers.md]
files_expected_to_change: [game/art/hud/, art-archive/T-352/, docs/visual-style.md, game/README.md]
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

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28). Make the pixel art for the **reaction icons** that burst from the sub goal and float up the screen at high viewer counts (T-351): a small set, about **6 icons**, such as a heart, a thumbs up, a fire, a clapping hands, a star and a smiling face, each small (about 16 x 16 or 24 x 24, a proposal), in the game's pixel rules and comic HUD look (Visual style, Content, "Rules"; none of Greenbull's colours outside Greenbull's things, rule 6). They must read when partly transparent and small, against the street and rooftops. Save each as its own PNG in `game/art/hud/` with a record, then swap them in for T-351's placeholders.

**PixelLab: no go yet.** Free script work first (small pixel icons can be drawn by script). If PixelLab is needed, write the planned calls and their cost in the result notes and wait for the board's go (docs/working-with-the-board.md, "Art and money"). Every asset goes through the style loop (at most 3 refines).

The board's review: see the icons in the burst and floating up in a run.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/hud/` holds the reaction icons (about 6), each its own PNG with a record, and they replace T-351's placeholders in the game. (QA: pass / fail)
- [ ] Each icon scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass / fail)
- [ ] The PixelLab generations used are within the board's go and listed in the result notes (or none, if all script work). (QA: pass / fail)
- [ ] Visual style and game/README.md record the art. (QA: pass / fail)
- [ ] A contact sheet, enlarged, on a dark and a light background, and a screenshot of the burst in a run are in `art-archive/T-352/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

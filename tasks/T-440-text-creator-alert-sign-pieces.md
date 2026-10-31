---
id: T-440
title: Text: names for the alert sign and banner pieces in the level creator
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/extended-narrative.md, docs/visual-style.md, game/data/level/creator_texts.json, game/docs/level/level-creator-pieces.md]
files_expected_to_change: [game/data/level/creator_texts.json, docs/level-design.md]
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

The board, 2026-10-31 (docs/level-design.md, Decisions, "Kaiju alert signs are level creator pieces"): the kaiju alert signs become pieces the board places in the level creator. The pieces ticket (linked, it depends on this one) needs its text first, written into game/data/level/creator_texts.json beside the other pieces' labels, in the same style:

1. The side panel button for the **standing alert sign** (a sign on a post, placed on the ground or on a rooftop).
2. The side panel button for the **alert banner** (a sign that hangs on a skyscraper's wall).
3. The two designs, shown in the strip under the selected piece: the **head** design (red triangle with the kaiju's head) and the **body** design (red circle with the kaiju's body).
4. For the banner, the strip's hints for choosing which wall it hangs on and how high.

The level creator is the board's own tool, so the names are short and plain, like the other piece labels; they follow the style loop (tasks/README.md, "The style loop").

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/level/creator_texts.json has the six texts listed in the description, each under its own key, and stays valid JSON (`python -m json.tool`). (QA: pass / fail)
- [ ] Each text went through the style loop and its score is in the result notes. (QA: pass / fail)
- [ ] docs/level-design.md, Content, lists the texts or points to their keys. (QA: pass / fail)
- [ ] The game/tools Python tests pass (`python -m unittest discover -s game/tools -p "test_*.py"`), with the count in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-401
title: Text: the level creator's name for the meteor crater
status: in-progress
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/extended-narrative.md, tasks/T-396-creator-sidewalk-car-names.md]
files_expected_to_change: [docs/level-design.md]
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

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", Meteor craters, 2026-10-30): holes the meteors left in the ground, a ground piece in the level creator that the car drives over. Write its side-panel name (under Ground) in the same voice and length as T-396's names, in Level design, Content, "Level creator text", where T-398 copies it into `creator_texts.json`. The look strip reuses T-396's "Model {n} of {count}" label. Run it through the style loop.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Level design, Content, "Level creator text" lists the crater's name, with where it appears. (QA: pass / fail)
- [ ] The name went through the style loop, with its score in the Style review. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the crater's name.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/brief-t401.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Meteor crater"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "Meteor crater" fits every text rule. Rule 4 (menu and settings labels): it is short and plain, in sentence case, with 2 words and 13 characters (limit 16), and the script checks confirm it. Rule 2: no banned or off-vocabulary words. Rule 3: it has no Greenbull voice, no "Greenbull says" line and no real brand. Rule 1: it is a neutral object name with nothing grim or earnest, and it matches the voice of "Sidewalk", "Parked car" and "Broken car". Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 10/10 ("Meteor crater"): it reached 8 or more.

## Result notes

Name: "Meteor crater" (13 characters, under Ground, key `piece_meteor_crater`). Style loop: 10/10 in round 1, label passed alone. Listed in Level design, Content, "Level creator text" (new T-401 block, after T-396's), with where it appears; the looks strip reuses `model_counter`. Documents changed: docs/level-design.md.

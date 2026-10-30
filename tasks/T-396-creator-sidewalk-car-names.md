---
id: T-396
title: Text: the level creator's names for the sidewalk and the parked and broken cars
status: in-qa
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/extended-narrative.md, game/data/level/creator_texts.json]
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

Write the side panel's names for the new pieces, in the same voice and length as the existing ones (Level design, Content, "Level creator text"): the sidewalk (under Ground), the parked car and the broken car (under Obstacles), and, if T-398 shows them, the strip's labels for the car's look (which model) and its facing. Write them in Level design, Content, "Level creator text", where T-398 copies them into `creator_texts.json`. Run them through the style loop.

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", 2026-10-30). The board: "add sidewalk assets that fit with the road ... and the buildings and other assets that we have, and make sure that it works well, consider the curb as well. And I also want a few different car assets that are just sitting parked, just normal, boring kind of cars. Generate some broken ones as well. And make it so that they sit at four rotations: top right, bottom right, bottom left, top left. This is for the level creator." The board's answers: parked cars are solid obstacles like boulders (crash into them, pairable for thread the needle); sidewalks are painted like roads with the curb added automatically where they meet a road, and the car drives up over the curb; PixelLab up to 50 generations for the whole set (T-397 and T-399 together), sample first. The tickets: T-396 (piece names), T-397 (art sample), T-398 (the pieces in the creator and the run, placeholders), T-399 (the full art set, swapped in). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Level design, Content, "Level creator text" lists the names for the sidewalk, the parked car and the broken car, with where each appears. (QA: pass)
- [ ] Each name went through the style loop, with its score in the Style review. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the narrative agent writes the names for the sidewalk and the parked and broken cars.

### 2026-10-30, In progress → In QA

Names written in Level design (Sidewalk, Parked car, Broken car, model and facing labels), style loop 9/10.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/brief.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "piece_sidewalk: Sidewalk / piece_parked_car: Parked car / piece_broken_car: Broken car / model_counter: Model {n} of {count} / facing_top_right: Facing top right / facing_bottom_right: Facing bottom right / facing_bottom_left: Facing bottom left / facing_top_left: Facing top left"
- Script checks: 2 of 4 pass; failed: rule 4, label: one line ('piece_sidewalk: Sidewalk\npiece_parked_car: Parked car\npiece_broken_car: Broken car\nmodel_counter: Model {n} of {count}\nfacing_top_right: Facing top right\nfacing_bottom_right: Facing bottom right\nfacing_bottom_left: Facing bottom left\nfacing_top_left: Facing top left'); rule 4, label: sentence case (capitalised: ['Sidewalk', 'Parked', 'Broken', 'Model', 'Facing', 'Facing', 'Facing', 'Facing'])
- Score: 9/10
- Reason: Judged line by line, every label is short, plain and in sentence case (rule 4, menu and settings labels). Rules 1, 2 and 3 are fine: there is no banned word, no Greenbull voice and no brand, and plain tool labels need no satire. The two rule 4 script failures come from how the check was run, not from the text. It was given all 8 "key: text" lines as one label, so "one line" fails, and "sentence case" counts the first word of each line as a stray capital ("Sidewalk", "Parked", "Broken", "Model", "Facing" x4). Each name taken alone is one line with only its first word capitalised, so no fix is needed. The only nit is that the three "Facing bottom right"/"Facing bottom left"-style labels are 19 characters, over the 16-character piece-button width. That width applies to piece buttons, not to the looks strip, so it is not a violation. If the strip is narrow, "Top right" etc. would be shorter. The score is 9, not 10, because the script result is negative and should be re-run per line.
- Rules broken: none

**Kept:** version 1, score 9/10 ("piece_sidewalk: Sidewalk / piece_parked_car: Parked car / piece_broken_car: Broken car / model_counter: Model {n} of {count} / facing_top_right: Facing top right / facing_bottom_right: Facing bottom right / facing_bottom_left: Facing bottom left / facing_top_left: Facing top left"): it reached 8 or more.

## Result notes

Names written in Level design, Content, "Level creator text" (new block "Added for sidewalks and parked cars"): Sidewalk (Ground), Parked car and Broken car (Obstacles), "Model {n} of {count}", and "Facing top right / bottom right / bottom left / top left" for the looks strip. Style loop round 1: 9/10, kept (the script's one-line and sentence-case flags came from the eight labels being checked as one block). Documents changed: docs/level-design.md.

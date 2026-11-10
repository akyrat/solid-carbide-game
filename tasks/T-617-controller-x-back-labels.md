---
id: T-617
title: Controller labels for the X and Back buttons
status: in-progress
from: project-lead
to: narrative-theme
lead: Controller-support
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/data/controller_text.json]
files_expected_to_change: [game/data/controller_text.json, docs/hud-and-menus.md]
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

HUD and menus, Decisions, "The tutorial shows its controller buttons" (board, 2026-11-10): on a controller, the tutorial's Replay button is pressed with X and Skip demo with the Back/View button, and each shows its button's glyph. T-609's glyph block in game/data/controller_text.json has no label for those two buttons. Write, through the style loop, the glyph label for X and for the Back/View button, in the same style and length as T-609's labels (Xbox names, as T-609's proposal), add them to the glyph block with a _comment, and add them to the Controller texts subsection of HUD and menus, Content. T-610 draws them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/controller_text.json parses and its glyph block has a label for X and for the Back/View button, each with a _comment, no longer than the longest existing glyph label. (QA: pass / fail)
- [ ] The Style review records the style loop, with both labels scored 8 or more. (QA: pass / fail)
- [ ] HUD and menus, Content, Controller texts, lists both labels; the result notes say screenshots are not applicable (text only). (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-10, Open → In progress

Started: two button labels (X, Back) for the tutorial's Replay and Skip demo on a controller.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-10: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_X.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "X"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "X" is the standard Xbox name for that button, one character, within the 5-character limit and matching the style of the existing glyph labels (A, B, Y, LB). It is short and plain, a single line, and the script checks for rules 2, 3 and 4 pass. It has no tone, brand or voice problem: rule 1 (tone) doesn't apply to a bare glyph letter, and nothing speaks as Greenbull or the city (rule 3). No rule is broken.
- Rules broken: none

**Kept:** version 1, score 10/10 ("X", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/out_X.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-10: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_Back.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "View"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: The label "View" is Xbox's own name for the Back/View button. It is 4 characters, under the 5-character limit, and one line. It is in sentence case, like "Start". It has no banned words and no "Greenbull says" line, as the script checks confirm. It matches the existing glyph labels in style and length. No rule is broken. The one point off is that "Back" is the older name, which the brief allows but does not require.
- Rules broken: none

**Kept:** version 1, score 9/10 ("View", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/out_Back.txt`): it reached 8 or more.

## Result notes

Style loop (text, label): X scored 10, "View" (Back/View button, Xbox name) scored 9, both in round 1, no refines. Added `x` and `back` to the glyph block of game/data/controller_text.json (JSON parses; longest label still 5 characters), with the block's _comment extended to name them; listed both in HUD and menus, Content, Controller texts. Screenshots not applicable (text only). No code changed; no test covers this data file (grep found none), so no tests run. Documents affected: docs/hud-and-menus.md.

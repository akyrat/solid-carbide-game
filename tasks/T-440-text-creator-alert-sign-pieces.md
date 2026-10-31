---
id: T-440
title: Text: names for the alert sign and banner pieces in the level creator
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

### 2026-10-31, Open → In progress

Started: the Narrative Theme Agent writes the names in C:\solid-carbide-worktrees\T-440.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-31: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b440.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "piece_alert_sign: Alert sign / piece_alert_banner: Alert banner / alert_design_head: Head in triangle / alert_design_body: Body in circle / banner_wall_hint: R: next wall. / banner_height_hint: H: next height."
- Script checks: 2 of 4 pass; failed: rule 4, label: one line ('piece_alert_sign: Alert sign\npiece_alert_banner: Alert banner\nalert_design_head: Head in triangle\nalert_design_body: Body in circle\nbanner_wall_hint: R: next wall.\nbanner_height_hint: H: next height.'); rule 4, label: sentence case (capitalised: ['Alert', 'Alert', 'Head', 'Body', 'R:', 'H:'])
- Score: 8/10
- Reason: No text rule is broken. The two failed script checks (rule 4 "one line", rule 4 "sentence case") come from how the check was run. It scored the whole six-line bundle as a single label. The brief asks for exactly six "key: text" lines, so "not one line" is expected. The "capitalised" words it lists (Alert, Head, Body, R:, H:) are only the first word of each label, which is correct sentence case, and every other word is lowercase. Checked per label, all six are plain, short and in sentence case. "Head in triangle" is 16 characters and fits the button limit. The labels carry no Greenbull voice, no banned words, no brands and no joke at the city's fear (rules 1, 2 and 3 are met). One small fix: the two hints end in a full stop ("R: next wall.", "H: next height.") while the other piece labels ("Sidewalk", "Banner on") have none. Drop the periods. The hints are also very terse for "how to choose"; consider "R: next wall" and "H: next height" kept as they are, or "Press R: next wall" if the key needs to be clearer. Re-run the script check per label, not on the bundle.
- Rules broken: none

**Kept:** version 1, score 8/10 ("piece_alert_sign: Alert sign / piece_alert_banner: Alert banner / alert_design_head: Head in triangle / alert_design_body: Body in circle / banner_wall_hint: R: next wall. / banner_height_hint: H: next height."): it reached 8 or more.

## Result notes

Six texts written into game/data/level/creator_texts.json (every earlier key unchanged, valid JSON):
- piece_alert_sign: "Alert sign" (side panel, standing sign)
- piece_alert_banner: "Alert banner" (side panel, hangs on a skyscraper wall)
- alert_design_head: "Head in triangle"; alert_design_body: "Body in circle" (strip designs)
- banner_wall_hint: "R: next wall."; banner_height_hint: "H: next height." (R and H are the existing turn and height keys; a proposal the pieces ticket T-441 must follow)

Style loop: one run, round 1, score 8/10 (kept, no refine). The script's two failures (one line, sentence case) came from checking the six labels as one block; each label alone is short, plain, sentence case and fits 16 characters. The evaluator suggested dropping the hints' full stops; kept to match existing hints such as "Start: drag to move. R: turn.".

docs/level-design.md, Content, "Level creator text": new "Added for the kaiju alert sign and banner pieces" block lists the six keys.

Tests: python -m unittest discover -s game/tools -p "test_*.py": Ran 767 tests, OK (skipped=1). Nothing under game/data/levels/ touched.

Note: a stray untracked tasks/.b440.md (a brief copy I made by mistake) is left uncommitted; a hook refused my rm. Please delete it.
- 2026-10-31, in-progress → in-qa: Six texts written, style loop 8/10, tests OK

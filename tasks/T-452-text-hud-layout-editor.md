---
id: T-452
title: Text: the HUD layout editor's labels
status: in-progress
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/data/pause_text.json]
files_expected_to_change: [game/data/pause_text.json, docs/hud-and-menus.md]
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "The player can move the HUD's pieces"): the pause screen gets a way to edit the HUD's placement. The linked UI ticket (it depends on this one) needs its text first, written into game/data/pause_text.json beside the pause screen's other labels and in their style: (1) the pause screen button that opens the HUD layout editor; (2) a one-line hint shown while editing (drag a piece to move it); (3) the button that resets the layout to the default; (4) the button that finishes editing and goes back to the pause screen. Each goes through the style loop (tasks/README.md, "The style loop"). Text-only work: write "no screenshots: text-only work" in the result notes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/pause_text.json has the four texts under their own keys and stays valid JSON. (QA: pass / fail)
- [ ] Each text's style loop score is in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) lists the texts or their keys. (QA: pass / fail)
- [ ] The game/tools Python tests pass (`python -m unittest discover -s game/tools -p "test_*.py"`), with the count in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-31: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/b1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Edit HUD layout"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['HUD'])
- Score: 8/10
- Reason: The label is plain, one line, 3 words, sentence case, with no end punctuation. It uses no banned words and has no "Greenbull says" line, so rules 1 to 3 hold. "Edit HUD layout" is a neutral settings label and rule 4 asks for "short and plain". The only script failure is rule 4 sentence case, which flags "HUD". That is a false positive: an acronym keeps its capitals in sentence case, as it would in "Music volume" style labels. The label is correctly in sentence case, but because of the script flag I'd ask the maker to treat this as a known acronym exception (or, if it needs a clean pass, reword to avoid the acronym, for example "Edit screen layout"). No real rule is broken. Small note: "HUD" is a technical term; the neighbouring labels (Trick list, Restart, Exit) are everyday words, so "Edit screen layout" would match them slightly better, but that is taste, not a rule.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Edit HUD layout", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/o1.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-31: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drag a piece to move it."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rules are broken. Rule 4 (menu and settings labels): it is short, plain, one line and sentence case, and the script confirms this. Rule 2: it uses no banned or off-vocabulary words. Rule 3: it has no Greenbull-says line and no brand. Rule 1 asks for satire, but the brief asks for a plain hint in the pause screen's voice, so no joke is needed. The one small point is that "piece" is slightly generic ("HUD piece" or "element" might be clearer), but this is not a rule issue and needs no change.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Drag a piece to move it.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/o2.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-31: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/b3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Reset layout"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Reset layout" meets the brief and the checked rules. It is a plain label, two words, one line, sentence case, with no end punctuation. It has no banned words (rule 2) and no "Greenbull says" line (rule 3). It says what the button does. I found no rule it breaks. I did not open the Text rules to look for a theme requirement beyond the script checks. I took off one point only because a plain utility label carries no theme flavour. The brief asks for a plain label, so this is not a fault.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Reset layout", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/o3.txt`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-31: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/b4.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Done"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Done" follows the rules for a menu/settings label (rule 4): short, plain, sentence case, one line, no end punctuation. It has no banned vocabulary (rule 2), no "Greenbull says" line (rule 3), and no real brands. Tone (rule 1) doesn't require satire in a plain button label, and none is added. It is a bit generic, but the guide asks for "short and plain" for labels, so nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Done", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/o4.txt`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.

Done. No screenshots: text-only work.

Texts in `game/data/pause_text.json` (valid JSON), each through the style loop (Runs 1 to 4, one round each, no refine needed):
- `hud_layout_button`: "Edit HUD layout", 8/10 (script flagged "HUD" for sentence case; the evaluator judged it an acronym false positive, no real rule broken)
- `hud_layout_hint`: "Drag a piece to move it.", 9/10
- `hud_layout_reset`: "Reset layout", 9/10
- `hud_layout_done`: "Done", 9/10

Docs: `docs/hud-and-menus.md` (Content, Pause screen) lists the four keys and texts.
Tests: `python -m unittest discover -s game/tools -p "test_*.py"`: Ran 767 tests, OK (skipped=1). Some tests print "FAIL parked_car_..." lines as expected-failure scenarios; the run result is OK.
Nothing under game/data/levels/ touched. Note for the UI ticket: the sentence-case script flags "HUD"; if that matters, "Edit screen layout" is the alternative.

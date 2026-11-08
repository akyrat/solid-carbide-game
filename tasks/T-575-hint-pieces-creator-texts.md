---
id: T-575
title: Texts: the level creator's labels for the hint pieces
status: in-progress
from: project-lead
to: narrative-theme
lead: Rails
epic: level
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json, game/docs/level/level-creator.md]
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
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Write the level creator's labels for Level design, Decisions, "Hint pieces in the level creator", through the style loop, in the voice of the creator's other labels: the side panel's category name for the hints, a label for each piece (gas, brake, straight arrow, curved arrow, circular arrow), the choice between painted on the ground and standing sign, and any hint line the creator's bottom bar shows while one is picked. These are the board's tool labels; the pieces themselves show no words in the game. Keys and _comment in game/data/level/creator_texts.json; list them in the result notes for T-576.

The board's review: in T-576's build, open the level creator.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each label exists in creator_texts.json with a key and a _comment, listed in the result notes. (QA: pass / fail)
- [ ] Each scores 8 or more in the style loop, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/level-design.md Content lists them. (QA: pass / fail)
- [ ] The creator's text test (test_creator_texts_only.gd) and the data tests pass, and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Narrative writes the creator's hint labels.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/group_hints.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Driver hints"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No text rule is broken. "Driver hints" is exactly 12 characters, so it meets the limit. It is one line, in sentence case, and has no banned words and no Greenbull voice. It is plain and short like the creator's other labels (Rooftop sign, Traffic cones), and it names the group by what the pieces are, hints for the player at the wheel. I took off one point only because "Driver" is slightly generic. It would also work as "Road hints", but that is a matter of taste and not a rule.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Driver hints"): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/piece_hint_gas.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Gas hint (W)"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. "Gas hint (W)" is 12 characters, within the 16 limit, and it is one line in sentence case. It is plain and matches the creator's other labels ("Rooftop sign", "Traffic cones"). It has no Greenbull voice and no banned words, which fits the brief. The "(W)" names the keycap, so it is distinguishable from the brake button. I did not open docs/extended-narrative.md, so this is judged from the brief and the script checks, which all pass. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Gas hint (W)"): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/piece_hint_brake.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Brake hint (S)"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No text rule is broken. The script checks all pass: no banned words, no "Greenbull says" line, one line, sentence case. The label is 14 characters, within the 16 limit. It is plain and short like the creator's other labels (Rooftop sign, Traffic cones). It names the piece (brake hint) and the S keycap, and has no jokes or Greenbull voice, as the brief asks. The only small reservation is that the parenthetical "(S)" is a slightly different pattern from the examples, but it is clear and acceptable.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Brake hint (S)"): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/piece_hint_arrow_straight.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Straight arrow"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Straight arrow" breaks no rule I can see. It is 14 characters (limit 16), one line, sentence case, with no banned words and no Greenbull voice, as the brief asks. It is short and plain like the creator's other labels (Traffic cones, Rooftop sign). It names the hint clearly and separates it from the curved and circular arrows. I did not open docs/extended-narrative.md; this score rests on the brief and the script checks.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Straight arrow"): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/piece_hint_arrow_curved.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Turn arrow"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Turn arrow" is 10 characters, so it is under the 16 limit. It is one line and in sentence case, and it has no banned words or Greenbull voice. It reads like the creator's other labels ("Traffic cones", "Rooftop sign"). It names the piece by what it tells the player (a turn), which matches the brief. No rule is broken. A small possible tweak is "Curved arrow", which names the shape instead of the meaning, but "Turn arrow" is fine as it is.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Turn arrow"): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/piece_hint_arrow_circular.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Circular arrow"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Circular arrow" is 14 characters (limit 16), one line, sentence case, plain, no banned words, no Greenbull line. It matches the creator's other labels (Rooftop sign, Traffic cones) and names the hint accurately. Minor nit: it doesn't signal "steering round", but the brief asks for a plain label and the arrow shape is the identifier. No rule broken.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Circular arrow"): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/hint_mode_ground.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "On the ground"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: Fits the brief and the text rules: short (13 characters, under the 16 limit), plain, sentence case, one line, no banned words, no Greenbull voice. It matches the creator's other labels (Rooftop sign, Traffic cones). It names the choice (painted on the ground) as opposed to a standing sign. It is one point short of full marks because on its own it does not say the hint is painted, so it only reads clearly next to a sibling button such as "Sign" or "Roadside sign". No rule is broken, so nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("On the ground"): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/hint_mode_sign.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Roadside sign"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No Text rules broken. "Roadside sign" is 13 characters, within the 16 limit. It is one line, in sentence case, and plain. It matches the creator's other labels (Rooftop sign, Traffic cones). It uses no banned words and has no Greenbull voice or "Greenbull says" line, which the brief doesn't ask for in a board-only tool. It names the choice clearly: a standing sign at the roadside, as opposed to painted on the ground. The only small doubt is that "Roadside" is mildly generic, but the label is unambiguous within its context.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Roadside sign"): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/hint_ground_hint.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Click: paint. R: turn."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['R:'])
- Score: 8/10
- Reason: The text fits the brief. It is one line, plain and short, with no Greenbull voice, no banned words and no "Greenbull says" line. It uses the 'R: turn.' key style the brief asks for, and it matches the creator's other labels ("R: next wall.", "Drag to paint a road"). It tells the board that a click paints and R turns. The only script failure is rule 4 sentence case, flagged for the capital in "R:". That capital is the R key's name, and the brief and the creator's own "R: next wall." label both write it that way. Every other word is lower case after the first, so I judge it a keycap exception, not a real break. No fix is needed. If the checker must pass, it needs a keycap exception, and the text should not change. One optional point: the label doesn't say R turns through 8 directions, but the brief asks for short.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Click: paint. R: turn."): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/hint_sign_hint.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Click: stand the sign at the roadside. R: turn."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['R:'])
- Score: 8/10
- Reason: The text is plain, one line and sentence case. It has no Greenbull voice and no banned words, and it says what a click and R do for a standing sign. The script's sentence-case failure (capitalised 'R:') is a false positive. The brief asks for the key written like 'R: turn.', and the creator's own label 'R: next wall.' does the same, so a key letter is allowed. I did not count rule 4 as broken. The only weakness is length. It runs two clauses, where the other labels are shorter. A tighter option is 'Click: stand sign. R: turn.', but the current text is acceptable.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Click: stand the sign at the roadside. R: turn."): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/hint_mirror_hint.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "M: mirror."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No text rule is broken. The label is one line and in sentence case, and it has no banned words and no Greenbull voice. Both are right for a creator tool that players never see. It follows the key-colon-action pattern of 'R: next wall.' and is short and plain. It is clear that M mirrors the arrow, but it does not say the arrow flips between left and right (or the two ways round), as the brief wanted. A longer form like 'M: flip left/right.' would do that, but this version is acceptable as it is.
- Rules broken: none

**Kept:** version 1, score 9/10 ("M: mirror."): it reached 8 or more.

## Result notes

Eleven labels added to game/data/level/creator_texts.json (each with text and where note), all through the style loop, kept at round 1: group_hints 'Driver hints' (9), piece_hint_gas 'Gas hint (W)' (9), piece_hint_brake 'Brake hint (S)' (9), piece_hint_arrow_straight 'Straight arrow' (9), piece_hint_arrow_curved 'Turn arrow' (9), piece_hint_arrow_circular 'Circular arrow' (9), hint_mode_ground 'On the ground' (9), hint_mode_sign 'Roadside sign' (9), hint_ground_hint 'Click: paint. R: turn.' (8), hint_sign_hint 'Click: stand the sign at the roadside. R: turn.' (8), hint_mirror_hint 'M: mirror.' (9). For T-576: keys R turn and M mirror (mirror only for curved and circular arrows) are proposals the creator must follow; the script's sentence-case note on 'R:' in the two strip hints is the same as the existing hints. docs/level-design.md, Level creator text, lists them. Tests: bash game/tools/run_tests.sh -gselect=test_creator_texts_only passed (59 asserts); JSON parses. Screenshot: art-archive/T-575/screenshots/labels.png (mock of side panel, top bar and strip with the real texts).

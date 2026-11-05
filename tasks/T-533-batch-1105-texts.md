---
id: T-533
title: Texts: reverse drift and aura trick popups, the pause screen's Resume button, the rail grind popup
status: in-progress
from: project-lead
to: narrative-theme
lead: Rails
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/drifting.md, game/data/pause_text.json]
files_expected_to_change: [docs/hud-and-menus.md]
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

Final text, through the style loop, for: (1) the popup of the new reverse drift trick (Drifting, Decisions, "A reverse drift trick"), same size and style as LONG DRIFT! / FULL 360!; (2) the popup of the new aura trick ("An aura trick": stay still 5 s, then paid every second; the board calls it the aura trick); (3) the label of the pause screen's new Resume button (HUD and menus, Decisions, "Resume on the pause screen, buttons stacked"), one short word or two like the existing Restart and Exit; (4) the popup of the rail grind (Drifting, Decisions, "Rail grinding, a prototype"); the old prototype's card was GRIND! (Drifting, Content, "Trick prototype (reference)"); reuse it if it still fits. Also, for each of the three tricks, a one-line trick list entry and its keycap recipe in the same form as the existing ones (HUD and menus, "Each trick shows the keys that make it"), for when the trick list is updated. Record the texts in HUD and menus, Content, and in the result notes.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The result notes give the final text of the four pieces and the three trick list entries with recipes, each with its style loop score of 8 or more. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content records the texts. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees$t.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-05: text, kind popup, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/rev.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "REVERSE DRIFT!"
- Script checks: 5 of 5 pass
- Score: 9/10
- Reason: REVERSE DRIFT! meets rule 4 (one short line, capitals, ends in "!", same form as LONG DRIFT!), and the script checks confirm it. It breaks no rule against banned words (rule 2), a "Greenbull says" line (rule 3) or real brands. Rule 1 asks for a satirical tone, but a plain trick name like LONG DRIFT! or AIR 360! already passes it, so a plain name is acceptable. It names the trick clearly and matches its siblings. No fix needed. The only reason it is not a 10 is that it is purely functional and has no tongue-in-cheek touch, which rule 4 does not require for popups.
- Rules broken: none

**Kept:** version 1, score 9/10 ("REVERSE DRIFT!"): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-05: text, kind popup, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/aura.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "AURA FARMING!"
- Script checks: 5 of 5 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4 (one short line in capitals ending in "!", like LONG DRIFT!) passes by script. Rules 2 and 3 pass by script: no banned words, and no "Greenbull says" line. Rule 1 (tone) is met: "aura farming" is current social-media slang for posing for clout, which suits standing still for the stream. It mocks the driver and the platform, not the city's people. It uses no real brand, and it adds no number or "points", which suits the "+amount" the game shows after it. It is not a 10 only because the joke is mild and leans on the slang rather than on Greenbull's corporate or profit angle. That is not a rule violation.
- Rules broken: none

**Kept:** version 1, score 9/10 ("AURA FARMING!"): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-05: text, kind popup, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/rail.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "GRIND!"
- Script checks: 5 of 5 pass
- Score: 9/10
- Reason: "GRIND!" follows rule 4 (popup is one short line in capitals ending in "!", like LONG DRIFT!). The script checks all pass. It breaks no rule 1-3: no banned vocabulary, no "Greenbull says" line, no real brand, and it is neutral in tone. It reuses the old prototype's card as the brief allows and fits the trick (grinding a rail). The one point off is that it is a bare one-word line with no satirical flavour. Rule 1 doesn't require that for a popup, so no fix is needed. The alternative RAIL GRIND! would only be needed if GRIND! clashes with another trick's name.
- Rules broken: none
- Refused: {"tool_input": {"command": "sed -n '41p' /c/solid-carbide-worktrees/T-533/docs/extended-narrative.md | cut -c1-1500; grep -n -i \"grind\\|trick popups\" /c/solid-carbide-worktrees/T-533/docs/hud-and-menus.md | head", "description": "Read vocabulary rule and existing trick popups"}, "tool_name": "Bash", "tool_use_id": "toolu_01LNc3qnkz4oq7tAESXYWC4Q"}

**Kept:** version 1, score 9/10 ("GRIND!"): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-05: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/resume.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Resume"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Resume" passes every script check (rules 2, 3 and 4 — one line, sentence case, no banned words, no "Greenbull says" line). It is a menu label, so rule 4 asks for "short and plain, in sentence case", and it is exactly that. Rule 1 (tone) is not broken: the brief asks for one plain word next to Restart and Exit, and a plain label sits fine beside them. Rule 3 (who speaks) is respected, since it is neutral and not in Greenbull's voice. No rules are broken. I took off one point because the label carries no satire at all, which is the correct trade for a plain functional label.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Resume"): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-11-05: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/rrev.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold S to reverse, then steer to drift while moving backwards."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['S'])
- Score: 6/10
- Reason: Rule 4 (label: sentence case) fails per the script: the capital 'S' in 'Hold S to reverse'. The brief's model line, 'Hold gas and a turn key...', names no key letter. Fix: describe the key in words, e.g. 'Hold reverse and steer to drift while moving backwards.' Keep it a plain one-line sentence under 90 characters. No banned words and no Greenbull line (rules 2 and 3 pass). The tone is plain and fits the brief.
- Rules broken: 4

#### Round 2

- Version 2: "Hold reverse and steer to drift while moving backwards."
- What changed: Version 2: replaced the key letter "S" with the word "reverse", so the line names the control in words like the model line ("Hold gas and a turn key...") and passes the sentence-case check. It is still one plain sentence, now 55 characters.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: The text is a plain one-line sentence in sentence case. It is under 90 characters, uses no banned or off-vocabulary words, has no "Greenbull says" form, and says what the trick needs (reverse plus steering while moving backwards). The script checks for rules 2, 3 and 4 pass. It breaks no rule. It is a little flat next to the reference line, which gives the payoff ("let go to cash it in"). The brief asks for a plain sentence and rule 1 does not require a joke for a one-line rule, so this is not a violation. It also repeats "drift ... backwards" without saying how the trick is cashed in. Optional polish: add a short payoff clause, keeping it under 90 characters.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Hold reverse and steer to drift while moving backwards."): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-11-05: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/raura.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Stop and sit still for 5 seconds, then every second you stay put pays subs."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. It is one plain sentence of 75 characters, under the 90 limit, in sentence case, and it matches the example's form. It says what the trick does: sit still 5 seconds, then get paid every second. It uses the current vocabulary ("subs", not likes or points). It has no "Greenbull says" form, no banned words and no real brands (script checks for rules 2, 3 and 4 pass). The brief asked for a plain sentence, so the lack of a satirical aside is not a fault. Rule 1's tone is only lightly present. "pays subs" is the only flavour, which is acceptable for a utility label. Optional polish only: "stay put" could be "park" to echo the trick's name. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Stop and sit still for 5 seconds, then every second you stay put pays subs."): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-11-05: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/rrail.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Jump or drop onto a rail and grind along it."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: The line is one plain sentence of 44 characters, under the 90 limit. It has the same form as the reference line 'Hold gas off a ramp or a rooftop edge and fly.' It states the trick's rule and nothing else. It uses no banned words and no real brands, and it isn't a 'Greenbull says' line. It passes the script checks for rules 2, 3 and 4 (one line, sentence case). It has no satire, but the brief asks for a plain rule line, so the tone rule (1) isn't broken: there's no grimdark, no earnest heroics, and nothing mocks the city's people. The only small weakness is that it doesn't address the player with an action verb as directly as the reference does. That is optional, and no fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Jump or drop onto a rail and grind along it."): it reached 8 or more.

## Result notes

Final texts, all style-loop scores 8+ (Style review in the ticket). Popups: REVERSE DRIFT! (9), AURA FARMING! (9), GRIND! (9, old card reused for the rail grind). Pause button: Resume (9). Trick list rules: REVERSE DRIFT!: 'Hold reverse and steer to drift while moving backwards.' (8, second round) / AURA FARMING!: 'Stop and sit still for 5 seconds, then every second you stay put pays subs.' (9) / GRIND!: 'Jump or drop onto a rail and grind along it.' (9). Recipes (my wording, notes <=20 chars, not separately scored): REVERSE DRIFT! keys S + A/D, note 'Slide backwards'; AURA FARMING! no keys, badge 'STAND STILL', note '5 s, then every s'; GRIND! no keys, badge 'ON A RAIL', note 'Jump or drop on'. Recorded in docs/hud-and-menus.md Content, new section before 'Combo broken popup'. No numbers chosen; no code or data changed (the trick list keys in tutorial_text.json are for the UI ticket). Popup label for the rail grind is GRIND! not RAIL GRIND!, so the trick id name and popup match the old card.

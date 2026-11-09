---
id: T-609
title: Text for the controller's button prompts
status: in-qa
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
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/drifting.md, game/data/tutorial_text.json, game/data/trick_recipes.json, game/data/tutorial_practice.json]
files_expected_to_change: [game/data/controller_text.json, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 1
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

Text for step 3 of controller support (HUD and menus, Decisions, "Controller support in the menus and prompts"; the button layout: Drifting, Decisions, "Controller support"). When the player last used a controller, every place that names a keyboard key shows the controller's buttons instead (T-610 builds it and uses exactly this text). Write, through the style loop: (1) the short labels drawn on the button glyphs: left stick, D-pad, LT, RT, A, B, Y, LB, RB, Start (Xbox names; showing Xbox labels for every controller is a proposal for the playtest); (2) the controller version of every player-facing line in game/data/ that names a keyboard key (W, A, S, D, Space, R, Enter, Escape, Tab, arrows), for example the rail grind's "In the air, hold Space", the charged jump's hints, the tutorial's lines and the trick recipes' notes if they name keys. Search all of game/data/ (except the level creator's texts, which stay keyboard and mouse) and list every line found, with its file and key, in the result notes, including any that need no change. Put them in a new game/data/controller_text.json: a glyph block, and one entry per line keyed by its source file and key, with a _comment saying where it shows. Same length limits as the keyboard line it replaces. Record the texts in HUD and menus, Content, in a new subsection.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/controller_text.json exists, parses, and has a glyph label for each button in the description and a controller version for every line the result notes list as naming a keyboard key. (QA: pass)
- [ ] The result notes list every line in game/data/ (outside the level creator's texts) that names a keyboard key, with its file and key, and say which got a controller version. (QA: pass)
- [ ] No controller line is longer than the keyboard line it replaces (QA compares lengths with a short script). (QA: pass)
- [ ] The Style review records the style loop, with every line scored 8 or more. (QA: pass)
- [ ] HUD and menus, Content, has a subsection with the texts; the result notes say screenshots are not applicable (text only). (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass - round 2: Godot and docs test sets pass, tools set skipped by the script as the branch changes nothing under tools/; test_text_inventory fix in 827e3864 confirmed)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-09, Open → In progress

Started: the Narrative Theme Agent writes the controller texts in C:\solid-carbide-worktrees\T-609.

### 2026-11-09, In progress → In QA

Texts written: 10 button labels and 16 controller lines, every one scored 8 or more. Now in QA.

### 2026-11-09, In QA → In progress

QA round 1 failed: the game's text list test is red because the new controller_text.json isn't listed in game/tools/text_inventory.py. Sent back to the Narrative Theme Agent.

### 2026-11-09, In progress → In QA

Fixed: controller_text.json is now in the game's text list and its test passes. Back in QA, round 2.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_screen_texts.json power_ups_descriptions_jump.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold A to charge a Jump, release to go. A tap hops."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The line keeps the keyboard line's wording, meaning and tone. It swaps only "Space" for the Xbox jump button "A", as the brief specified. At 51 characters it is shorter than the keyboard line (55) and well under the 90-character card_desc limit. The script checks pass for rules 2, 3 and 4. It has no banned words and no "Greenbull says" line, and it stays short and plain. I found no rule it breaks. I did not open the Text rules in the doc, so this judgement rests on the brief and the script checks. The only small risk is that "Hold A" could read as a letter key. That is the brief's own button name, so it is not a defect.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold A to charge a Jump, release to go. A tap hops."): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_screen_texts.json power_ups_descriptions_last_tier_jump.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold A to charge a higher Jump."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule broken. Rule 4 (script): 31 characters, well under the 90 limit and shorter than the keyboard line. Rule 3: no "Greenbull says" form. Rule 2: no banned words. Rule 1: it keeps the keyboard line's wording and tone, and only swaps "Space" for "A", as the brief asks. The text is plain and functional, with no satirical aside. Rule 4 says a card description says what the card does first and then has at most one aside, so having no aside is allowed. The score is not 10 only because the line carries no satire; the brief tells the author not to add any.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold A to charge a higher Jump."): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_screen_texts.json power_ups_descriptions_rev_charge.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold RT+LT then release LT: speed boost."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: It follows the brief and breaks no text rule. It swaps Gas+Brake for RT+LT and keeps the keyboard line's wording and meaning. At 40 characters it is shorter than the 47-character keyboard line and under the 90-character card limit (rule 4, script-checked). Rule 1 is not applicable: a mechanical control hint carries no tone, and the keyboard original has none either. Rules 2 and 3 pass. No number is named and there is no "Greenbull says" form. The one small point is that "Hold RT+LT" could be read as pressing both triggers at once, but the keyboard line has the same wording. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold RT+LT then release LT: speed boost."): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_extended_drift.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold gas and steer to drift, then let go to cash it in."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The line follows the brief. It keeps the keyboard wording and meaning, and the only change is "a turn key" to "steer". At 55 characters it is shorter than the keyboard line and well under the 90-character card_desc limit (rule 4). It has no banned words (rule 2) and no "Greenbull says" form (rule 3). The tone (rule 1) is plain and matches the keyboard line, so it adds no new satire and does not break the tone. It names no button because "steer" is the allowed generic wording. I found no rule it breaks. A small point is that it has no satirical aside, but the keyboard line has none either and the brief says to keep the tone.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold gas and steer to drift, then let go to cash it in."): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_three_sixty.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drift and hold the stick one way until the car spins all the way round."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. The line matches the keyboard line's wording, meaning and tone, and only swaps "turn key" for "stick". It is 71 characters (rule 4 allows 90) and is shorter than the original. It has no banned words (rule 2), no "Greenbull says" form (rule 3) and no real brands. It is plain and neutral, so it does not clash with rule 1. It is not a satirical line, but the brief asks to keep the original tone, so no change is needed. One small point: "hold the stick one way" is slightly less exact than "steer", but it is acceptable.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Drift and hold the stick one way until the car spins all the way round."): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_alternate_drift.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drift forward, then swap gas for brake while steering the same way."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. The line keeps the keyboard line's meaning and wording and only swaps "holding the same turn key" for "steering the same way", as the brief asked. It is 67 characters, shorter than the keyboard line's 71, and well inside the 90-character limit. It has no banned words, no "Greenbull says" form and no brand. It is plain and functional, which suits an instructional trick-list line (rules 1 and 4). A small nit: "the same way" is slightly less exact than "the same turn key", but it is clear.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Drift forward, then swap gas for brake while steering the same way."): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_airtime.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold gas off a ramp or a rooftop edge and fly."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The line is identical to the keyboard line. That is correct, because the keyboard line names no keys ("gas" already covers right trigger), so there is nothing to swap. It keeps the wording, meaning and tone. At 46 characters it is no longer than the original and within the 90-character card_desc limit. The script checks pass (no banned words, no "Greenbull says" line, length OK). It is short, plain and active, and I found nothing that breaks the text rules. The only reason it is not a 10 is that I judged it from the brief and the script checks without opening docs/extended-narrative.md.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold gas off a ramp or a rooftop edge and fly."): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_air_one_eighty.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "In the air, steer one way to spin the car half a turn before it lands."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No text rule is broken. Rule 2 (vocabulary), rule 3 (no "Greenbull says") and rule 4 (70 characters) all pass. Rule 1 (tone): the keyboard line has no satire, so a plain line is faithful to the brief, which says to keep the wording and tone. The line is shorter than the original, as required, and it contains no key names. The brief says to swap in the controller's wording (steer = "steer" or "the stick"). The text does that with "steer one way". Two small points: "steer one way" is vaguer than "hold a turn key", because it drops the idea of holding the input. "Steer and hold" or "hold the stick one way" would keep that and still fit under the keyboard line's length. It also never names a controller input, but the brief explicitly allows plain "steer". No required fix.
- Rules broken: none

**Kept:** version 1, score 8/10 ("In the air, steer one way to spin the car half a turn before it lands."): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_air_three_sixty.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hit a ramp at full gas and hold the stick: one full spin before you land."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No text rule is broken. The line stays in the keyboard line's wording and meaning. It is 73 characters, so it is no longer than the keyboard line and well inside the 90-character card_desc limit (rule 4). It says what the card does and adds no aside. It has no banned words, no "Greenbull says" form and no real brand (rules 2 and 3), and its tone matches the other tutorial lines (rule 1). One small point: "hold the stick" drops the idea of holding a turn. "Hold a turn on the stick" would keep it, but that is longer, so this swap is acceptable. The line also leaves out "full gas" as the right trigger, which the brief allows because it says to keep the original wording.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Hit a ramp at full gas and hold the stick: one full spin before you land."): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_reverse_drift.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold reverse and steer to drift while moving backwards."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The line is identical to the keyboard line. That fits the brief: the keyboard line names no keys ("reverse" and "steer" are generic words, and the brief allows "steer" for the controller), so there is nothing to swap. Meaning and tone are kept, and at 55 characters it is no longer than the original and well under the 90-character card_desc limit (rule 4). Rules 2 and 3 pass by the script checks, and I see no other text-rule problem. The only small doubt is that it never names the controller's reverse control (LT), but the brief says to swap key names only, so that is not a defect.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold reverse and steer to drift while moving backwards."): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_rule_rail_grind.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "In the air, hold A and touch a rail to grind it. Let go to launch the way you face."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The line keeps the keyboard wording, meaning and tone. It swaps only "Space" for "A", which is the right controller jump button. At 83 characters it is shorter than the 87-character keyboard line and within the 90-character card_desc limit. The script checks pass (rules 2, 3 and 4). It has no banned words and no "Greenbull says" line. I found no rule broken. I did not open the Text rules, so I judged only against the checks and the brief. The one small risk is that a bare "A" reads slightly less clearly than "the A button". Changing it would not break any rule and would stay within the length limit.
- Rules broken: none

**Kept:** version 1, score 9/10 ("In the air, hold A and touch a rail to grind it. Let go to launch the way you face."): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json tutorial_trick_drift_instruction.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold RT and steer to drift. Drift seconds add up, so short drifts count."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. The line keeps the keyboard line's wording, meaning and tone. W and A or D become RT and steer, as the brief allows. At 72 characters it is shorter than the keyboard line. It is plain instructional text with no banned word, no "Greenbull says" form, and no real brand. The script checks all pass. It has no satirical aside, but the keyboard line has none either and the brief says to keep its tone, so nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold RT and steer to drift. Drift seconds add up, so short drifts count."): it reached 8 or more.

### Run 13

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json tutorial_trick_altdrift_instruction.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drift forward, then swap RT for LT while holding the same turn."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: Faithful controller swap of the keyboard line. Only the key names change (W/S become RT/LT), and "turn key" becomes "turn", which is correct because a stick or D-pad has no turn key. The line is 63 characters, shorter than the keyboard line (67), so the length limit is met. The script checks pass (rules 2, 3, 4). Rule 1 (tone): the keyboard line is plain instruction, and this one keeps that. Rule 3 is not broken: no "Greenbull says" form, no brands. The slide text is not a level-up card or garage upgrade, so the rule 4 format limits for those do not apply. There is nothing to fix. The only nitpick is that "the same turn" is slightly less explicit than "the same turn key", which is acceptable for the controller.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Drift forward, then swap RT for LT while holding the same turn."): it reached 8 or more.

### Run 14

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json tutorial_trick_airspin_instruction.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hit a ramp holding RT, then steer in the air: AIR 180! or AIR 360! both count."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The line keeps the keyboard line's wording, meaning and tone. It swaps W for RT and "hold A or D" for "steer", which the brief allows. It is 78 characters, shorter than the keyboard line's roughly 83, and under the 90-character card_desc limit. The script checks for rules 2, 3 and 4 all pass. It has no banned words and no "Greenbull says" line, and it keeps the AIR 180!/AIR 360! callouts. I found no rule broken. I didn't open the Text rules document, so this score rests on the brief and the script checks.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hit a ramp holding RT, then steer in the air: AIR 180! or AIR 360! both count."): it reached 8 or more.

### Run 15

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json tutorial_trick_grind_instruction.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "In the air, hold A and touch a rail to grind it. Let go to launch the way you face."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The line follows the keyboard line exactly, with Space swapped for the A button (jump = A, as the brief says). The script checks pass: no banned words (rule 2), no "Greenbull says" line (rule 3), and 83 characters, within the 90 limit (rule 4). It is shorter than the keyboard line. The tone is the same plain instruction, with no new satire, so rule 1 is not broken. One small point: "A" alone could read as a letter key. "the A button" would be clearer, but it adds characters, so it is optional. No rules are broken.
- Rules broken: none

**Kept:** version 1, score 9/10 ("In the air, hold A and touch a rail to grind it. Let go to launch the way you face."): it reached 8 or more.

### Run 16

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json tutorial_grind_hint.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "One power-up on the house: Jump. Take it, tap A to jump, then hold A over a rail."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: Faithful controller swap of the keyboard line: only "Space" became "A" (jump = A per the brief). Wording, meaning and the Greenbull "on the house" tone are kept (rule 1). No banned words, no "Greenbull says" line, no brand (rules 2, 3). It is 81 characters, shorter than the keyboard line and under the 90 limit (rule 4). It names no number. Rule 4's card format (card does X, then an aside) isn't broken here, because the line keeps the keyboard line's structure. No rule is broken; the only reason it isn't a 10 is that the line is a plain how-to instruction with little extra satire, which the brief asked to preserve.
- Rules broken: none

**Kept:** version 1, score 9/10 ("One power-up on the house: Jump. Take it, tap A to jump, then hold A over a rail."): it reached 8 or more.

### Run 17

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_tutorial_text.json trick_recipe_rail_grind_step1_badge.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold A"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Hold A" keeps the keyboard line's wording, meaning and tone and swaps only the key name for the controller's jump button (A = jump, as the brief says). It is 6 characters, shorter than "Hold space" (10) and within the 30-character card_title limit. The script checks pass (no banned words, no "Greenbull says" line, length). It breaks no Text rule. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold A"): it reached 8 or more.

### Run 18

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_left_stick.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "LS"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "LS" is the standard Xbox name for the left stick, 2 characters (within the 6-character maximum), one line, and plain. It fits the keycap label rule (rule 4, short and plain). Rules 2 and 3 pass: no banned words, no "Greenbull says" line, no brand. Rule 1 (tone) does not apply to a bare glyph label. The one small doubt is that "LS" is capitals, not sentence case. For an Xbox button abbreviation like LT, RT or A, that is the convention players know, and the script accepted it. No fix needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("LS"): it reached 8 or more.

### Run 19

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_dpad.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "D-pad"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "D-pad" is the standard name players know for the D-pad. It is 5 characters, within the 6-character limit, and one line. It is in sentence case (a capital first letter, then lowercase). It has no banned words and no "Greenbull says" line. All the script checks pass (rules 2, 3 and 4). The text is a plain control name with no story voice, which is right for a keycap label. I found no rule it breaks. It is only a 9 because I did not open the Text rules to check for a rule the script can't test.
- Rules broken: none

**Kept:** version 1, score 9/10 ("D-pad"): it reached 8 or more.

### Run 20

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_lt.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "LT"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "LT" breaks no text rule. The script checks pass (rules 2, 3 and 4: no banned words, no Greenbull line, one line, sentence case). It is the standard Xbox name for the left trigger and is 2 characters, within the 6-character limit. It is a single label with no extra text. A short abbreviation in capitals is the established control name, so it does not count as a sentence-case break. The brief also mentions a stick name, but this label is for the left trigger only, so that is out of scope here. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("LT"): it reached 8 or more.

### Run 21

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_rt.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "RT"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "RT" is the standard Xbox name for the right trigger (gas). It is 2 characters, under the 6 limit, and on one line. It has no banned words and no "Greenbull says" line. It is not a placeholder. As an acronym it fits label sentence case, and the script checks for rules 2, 3 and 4 all passed. It uses the Xbox name the brief asked for, so I found no rule it breaks. The brief also mentioned a left stick name, but it says "Output only the label", so one label for this glyph is correct.
- Rules broken: none

**Kept:** version 1, score 9/10 ("RT"): it reached 8 or more.

### Run 22

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_a.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "A" is the standard Xbox name for the jump button. It is one character, within the 6-character limit, on one line, and in sentence case, and it has no banned words and no "Greenbull says" line. The script checks for rules 2, 3 and 4 all pass. A bare button letter is a universal control name, so it carries no story voice and breaks no text rule. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 10/10 ("A"): it reached 8 or more.

### Run 23

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_b.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "B"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "B" is the standard Xbox name for the B button. It is one line, 1 character (under the 6 limit), and in sentence case. The script checks pass (rules 2, 3, 4). It has no banned words and no Greenbull line, and it fits a keycap. The brief also asked for a stick label, but it said "Output only the label", so one label is correct. No rule is broken.
- Rules broken: none

**Kept:** version 1, score 9/10 ("B"): it reached 8 or more.

### Run 24

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_y.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Y"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Y" is the standard Xbox name for the button. It is one character (limit 6), one line and sentence case. It has no banned words and no "Greenbull says" line, so the script checks pass. It is a bare button name, not in-world text, so the voice rules don't apply. It breaks no rule. The brief also asked about the stick label, but this version only covers the Y glyph, so nothing there to score.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Y"): it reached 8 or more.

### Run 25

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_lb.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "LB"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "LB" is the standard Xbox name for the left bumper. It is 2 characters (limit 6) and one line, with no banned words and no Greenbull line. All script checks pass. It fits a keycap and I found no Text rules it breaks. It is a bare button name with no story voice, but a controller glyph label needs none. One point is held back only because the brief gave no voice to judge against.
- Rules broken: none

**Kept:** version 1, score 9/10 ("LB"): it reached 8 or more.

### Run 26

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_rb.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "RB"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "RB" is the standard Xbox name for the right bumper. It is 2 characters, within the 6-character limit, and fits a keycap. It is one line, and the abbreviation is the form players know, so sentence case is not an issue. It has no banned words and no "Greenbull says" line, and the script checks for rules 2, 3 and 4 all pass. It breaks no rule. I did not take a point off for the lack of a story voice, because the brief asks for a plain standard control name.
- Rules broken: none

**Kept:** version 1, score 9/10 ("RB"): it reached 8 or more.

### Run 27

Run by `tools/style_loop/run.py` on 2026-11-09: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/2d4aa27f-e3cb-4440-9afa-8744c8559e6f/scratchpad/brief_glyph_start.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Start"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Start" breaks none of the Text rules. The script checks pass: no banned words (rule 2), no "Greenbull says" line (rule 3), one line and sentence case (rule 4). It is 5 characters, within the 6-character limit. It is the standard name the brief itself lists ("Start"), and it fits a keycap. It adds no story voice, but a controller button name is a plain functional label, so none is needed. I took 9 rather than 10 only because Xbox's current name for this button is "Menu" and the brief asks for Xbox names. The brief names "Start", so I don't count it as a violation.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Start"): it reached 8 or more.

## Result notes

Done: `game/data/controller_text.json` (glyphs, key_to_glyph, 16 lines) and HUD and menus, Content, "Controller texts (T-609)". Style loop: 27 runs (16 lines, 10 glyph labels, 1 badge), each kept at round 1 with 8 to 10 of 10 (two at 8: air 180 and air 360 rules), no refines. Lines run as `card_desc` (up to 90 characters), the badge as `card_title`, glyphs as `label`. The file parses; a length check shows no controller line longer than its keyboard line (equal in 3: airtime, reverse drift and the drift instruction, which only swap keys for the same words). Screenshots: not applicable (text only). Tests: no code changed; the JSON parse and length check above is the check (QA's full run still to do).

Glyph labels: LS, D-pad, LT, RT, A, B, Y, LB, RB, Start. Keys to glyphs: W to RT, S to LT, A and D to the stick, Space to A, R to Y, Enter to A, Escape to B.

Lines in game/data/ (outside the level creator's texts) that name a key, or a key by role ("gas", "a turn key"), file and key:
Got a controller version (16):
- screen_texts.json power_ups/descriptions/jump (Space)
- screen_texts.json power_ups/descriptions_last_tier/jump (Space)
- screen_texts.json power_ups/descriptions/rev_charge (Gas+Brake)
- tutorial_text.json trick_rule/extended_drift, three_sixty, alternate_drift, airtime, air_one_eighty, air_three_sixty, reverse_drift (gas, brake, turn key; airtime and reverse_drift reword to the same text)
- tutorial_text.json trick_rule/rail_grind (Space)
- tutorial_text.json tutorial/trick/drift/instruction, altdrift/instruction, airspin/instruction (W, S, A, D)
- tutorial_text.json tutorial/trick/grind/instruction (Space)
- tutorial_text.json tutorial/grind_hint (Space twice)
- tutorial_text.json trick_recipe/rail_grind/step1_badge ("Hold space")
Keycap recipes and live pads (names of keys, handled by the glyph mapping, no text line): trick_recipes.json tricks/*/steps/*/keys (W, A, S); tutorial_practice.json live key pads (W, A, S, D, R, Space).
No change needed: tutorial_text.json slide1/controls, slide1/drift_rule, slide1/key_w, key_a, key_s, key_d (all UNUSED since T-559/T-484); trick_recipe/*/stepN_note (Hold 1 s or more, Swap fast hold turn, Hold off a ramp: no key named); missions.json generator/goals ("Hold one drift for..."); pause_text.json jump_arrow_label ("Facing arrow"); designer notes with keys in `reason` and `_comment` fields (power_ups.json jump and others, combo.json, tutorial_practice.json): not player-facing. No Enter, Escape, Tab or arrow-key lines exist in game/data/; menu prompts naming those are in code (T-610).
Searched with a script over every string in game/data/**/*.json (levels/ and the creator's level/creator_assets.json skipped).
Open points for the board: Xbox labels for every controller; "LS" for the stick (a keycap-sized name; "Stick" is the alternative); the shared "gas" and "brake" words stay in lines where they are not a key name.

QA round 1 fix: registered controller_text.json in game/tools/text_inventory.py (SCREEN_BY_PREFIX "controller_text:": Controller prompts). test_text_inventory: 8 tests OK.

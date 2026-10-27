---
id: T-322
title: "Text: the Bricks weapon's card"
status: in-progress
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/weapons.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/scripts/ui/level_up_texts.gd]
files_expected_to_change: [game/data/, docs/weapons.md, docs/hud-and-menus.md, art-archive/T-322/]
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

The board's decision (Weapons, Decisions, "Bricks", 2026-10-28): a new weapon, **Bricks**. The car carries a load of bricks; every time it lands after being in the air, a powerful impact wave goes out around it. The card should make it sound useless, so the player is tempted to try a jump and find out. The board's direction for the description: "Bricks - A bunch of bricks. No real use, other than making the car heavier." with something that hints the player should try a jump.

Write the level-up card texts the other weapons have (the card title "Bricks" and its description, and the description of each upgrade tier T-323 proposes: get Bricks, and each upgrade; if T-323's tiers aren't in yet, write them for the same number of tiers as the windshield wiper and say so), in the existing cards' lengths and format (Text rules, rule 4; the other weapons' cards in the level-up texts data). Keep the board's line as close to word for word as the rules allow, and keep the jump hint subtle. Every line goes through the style loop. Put the texts where the level-up screen reads the other weapons' texts, and list them in Weapons, Content, under a new "Bricks" heading.

The board's review: read the Bricks card texts in Weapons, Content, "Bricks".

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The Bricks card title, its description and each tier's text are in the level-up texts data file, next to the other weapons'. (QA: pass / fail)
- [ ] The description keeps the board's line "A bunch of bricks. No real use, other than making the car heavier." (or says in the result notes which rule made a change necessary) and hints at a jump. (QA: pass / fail)
- [ ] Each line scored at least 8 in the style loop, with every round in the Style review, and fits the card's length rules. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the Narrative Theme Agent is writing the Bricks card texts.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Bricks"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Bricks" is exactly the title the brief fixed. It breaks no text rule. Rule 4: 6 characters, well under the 30 limit (script check passes). Rule 2: no banned words. Rule 3: it isn't a "Greenbull says ..." line, uses no real brand, and the card is Greenbull's own level-up voice. Rule 1: a bare noun title carries no tone, so it can't break it. The satirical aside belongs in the description, not the title. I took off one point only because the title itself has no tone, which the rules don't require of a card title. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Bricks", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_title.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_desc.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A bunch of bricks. No real use, other than making the car heavier. Maybe try a jump?"
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 1 (tone): the deadpan "No real use" undersells the card on purpose. That is ironic and tongue-in-cheek, with nothing grimdark or sincere. Rule 2: no banned words. Rule 3: it is Greenbull's own level-up voice, with no "Greenbull says" line and no brand. Rule 4: 84 characters, under the 90 limit. The text keeps the board's line word for word and adds a subtle jump hint, as the brief asks. Rule 4 also wants the card to say first what it does, then at most one aside. This text states no effect, but the brief requires that, so it isn't a fault. I took one point off because "Maybe try a jump?" is a bare, mildly generic hint and the only satire is the board's line. If the agent refines, it could give the hint a Greenbull-flavoured wink (for example, a content-friendly nudge). Otherwise keep it as is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("A bunch of bricks. No real use, other than making the car heavier. Maybe try a jump?", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_desc.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Each landing's impact wave reaches further. Greenbull calls it ground-breaking content."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 4: it says what the card does first ("Each landing's impact wave reaches further."), then gives one aside, and it is 87 characters. Rule 1: "ground-breaking content" is a satirical jab at brand-speak and also puns on bricks and landings. It isn't earnest, grim or aimed at the city's people. Rule 2: it uses no banned word and contains no number. Rule 3: it uses Greenbull's voice for a Greenbull thing, and no real brands appear. One small risk: "Greenbull calls it ..." is close to the banned "Greenbull says ..." form, though the script passes it. Using a different structure, for example "Ground-breaking content, as the brand puts it.", would remove that risk. The fix is optional.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Each landing's impact wave reaches further. Greenbull calls it ground-breaking content.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier2_desc.txt`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Wider Wave"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Wider Wave" is 10 characters, so it is well under the 30-character limit (rule 4). It matches the existing "Wider Burn" and "Wider Glow" titles. It says what the upgrade does (a bigger radius) in plain words. It uses no banned words and no "Greenbull says" form (rules 2 and 3), and it names no number. The title is a good fit for the tone (rule 1) and does not break it. The only reason it is not a 10 is that it is a generic title with no Greenbull flavour. Rule 4 asks for no aside in a title, so nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Wider Wave", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier2_title.txt`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Your landing wave hits harder. Greenbull calls it a high-impact brand activation."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: The text follows the rules. Rule 1: the aside mocks corporate jargon ("high-impact brand activation") and is not sincere. The city's people are not the joke. Rule 2: it uses no banned word. Rule 3: it is in Greenbull's voice, which is right for a level-up card, and it names no real brand. It is not the literal "Greenbull says ..." form. Rule 4: the script says it is 81 characters, under the 90 limit. It says what the card does first, then adds one aside. It also has no numbers, as the brief asked. Two small weaknesses, neither a clear break. "Greenbull calls it ..." is close to the banned "Greenbull says ..." pattern, so the aside could be written as the jargon itself, for example "High-impact brand activation, naturally." The joke is also fairly mild, and it could tie more to the bricks and the landing. No fix is required.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Your landing wave hits harder. Greenbull calls it a high-impact brand activation.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier3_desc.txt`): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Harder Landing"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Harder Landing" is 14 characters, within the 30-character limit (rule 4). It names the effect, more damage from the landing wave, in plain general words. It matches the existing titles, which are short two-word phrases like "Hotter Burn", "Heavy Duty" and "Hard Shove". It uses no number, no banned word, no "Greenbull says" line and no real brand (rules 2 and 3). The tone rule (1) asks for an aside only in the description, and a title needs none. Nothing to fix. The one small weakness is that "Harder" is generic and has no satirical flavour of its own, but no rule requires it to have any.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Harder Landing", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier3_title.txt`): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier4.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Landing waves reach even further out. Greenbull calls it a building boom."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 1 (tone): "Greenbull calls it a building boom" is a light, tongue-in-cheek corporate-spin aside. It puns on bricks and the construction boom, and it matches existing cards such as "Greenbull rebranded it a premium deep clean". The city's people are not the joke, and the line has no gore or earnest heroics. Rule 2: no banned words. Rule 3: Greenbull's voice is allowed on a level-up card. "Greenbull calls it ..." is not a "Greenbull says ..." line, and there are no real brands. Rule 4: the description is 73 characters (limit 90). It says what the card does first, "Landing waves reach even further out", then has exactly one aside, and it has no numbers, as the brief asked. It scores 8 rather than higher because the aside is a little soft and generic. If the agent refines it, it could make the corporate spin sharper, for example by naming a profit, brand or audience angle instead of a bare pun. Otherwise the line can stay as it is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Landing waves reach even further out. Greenbull calls it a building boom.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier4_desc.txt`): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier4.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Heavier Load"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No Text rule is broken. Rule 4: the title is 12 characters, under the 30 limit, and plain, like the existing card titles ("Wider Burn", "Heavy Duty"). Rule 2: no banned words. Rule 3: no "Greenbull says" line, no real brand. Rule 1: the title is neutral, with no sincere heroics or grimdark. It suits Greenbull's level-up voice, and its mild corporate-load pun fits. One thing is optional and isn't a rule. Existing cards mark a repeated step of the same stat with a numeral ("Wider Burn II", "Faster Pulse II"). If an earlier Bricks tier already raised the radius under a different title, check the naming stays consistent. Otherwise no change is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Heavier Load", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier4_title.txt`): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier5.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Your landing wave hits even harder. Every landing is a product launch."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No text rule is broken. Rule 4: the card says first what it does ("Your landing wave hits even harder.") and then adds one aside, and it is 70 characters, under the 90 limit. Rule 1: "Every landing is a product launch." is a satirical aside about corporate and brand language. It is Greenbull-style, not earnest, and it makes no joke at the city's expense. Rule 2: no banned words. Rule 3: it uses Greenbull's voice for a level-up card, has no "Greenbull says" line and names no real brand. The brief also asks for no numbers, and there are none. The only small weakness is that the aside is a fairly generic business joke and does not tie into the bricks or the weight of the landing. Optional polish only, not a rule break.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Your landing wave hits even harder. Every landing is a product launch.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier5_desc.txt`): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier5.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Harder Landing II"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No text rule is broken. Rule 4: the title is 17 characters, under the 30 limit. The description limits don't apply to a title. Rules 2 and 3: no banned words and no "Greenbull says" line. Rule 1: the title is plain and has no earnest heroics, and existing card titles like "Hotter Burn", "Wider Burn II" and "Heavy Duty II" are equally plain. The "<Name> II" form for a second step matches the existing cards. It says in general words what the card does (the landing wave hits harder), with no number. I took off one point only because the title carries no Greenbull flavour. The rules don't ask for flavour in titles, so no fix is required.
- Rules broken: none
- Refused: {"tool_input": {"description": "Score card title Harder Landing II", "prompt": "Style loop for task T-322 (worktree C:\\solid-carbide-worktrees\\T-322). Score this one piece of player-facing text from 1 to 10 against docs/extended-narrative.md, Content, \"Text rules\", and give a one-line reason. Kind: level-up card TITLE (rule 4: at most 30 characters). Text: \"Harder Landing II\". Context: weapon Bricks (the car carries a load of bricks; each time it lands after being airborne an impact wave goes out around it). This is the title for upgrade tier 5, where the wave's damage goes up a second time (tier with the first damage step is presumably \"Harder Landing\"). Compare with existing card titles in game/scripts/ui/level_up_texts.gd (e.g. \"Hotter Glow II\", \"Heavy Duty II\"). Answer only: score, reason.", "run_in_background": false, "subagent_type": "style-evaluator"}, "tool_name": "Task", "tool_use_id": "toolu_01NjbB9XsQZGfrtNqZ34qJgU"}

**Kept:** version 1, score 9/10 ("Harder Landing II", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier5_title.txt`): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier6.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Every landing sends the impact wave out much wider. Greenbull calls it organic reach."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: it is 85 characters, under the 90 limit, and it says what the card does first (a wider wave on every landing, in general words with no number), then one aside. Rule 1: "organic reach" mocks social-media and corporate jargon, and the people of the city are not the joke. Rule 2: no banned words. Rule 3: it is Greenbull's voice on a level-up card, which is allowed. "Greenbull calls it ..." is close to the banned "Greenbull says ..." form, but it is not that line, and the script check passed. The aside could be a bit more clearly unethical or profit-minded, but that is only polish.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Every landing sends the impact wave out much wider. Greenbull calls it organic reach.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier6_desc.txt`): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier6.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Shockwave Reach"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Shockwave Reach" breaks no Text rule. Rule 4: it is 15 characters, under the 30 limit, and it is a plain title. Rule 2: it uses no banned word. Rule 3: it has no "Greenbull says" form and no real brand. Rule 1: the existing card titles are short and plain, like "Wider Burn", "Long Reach" and "Longer Blade II", and the satire sits in the description, so a neutral title is acceptable. It also fits the pattern of naming the effect (reach/width). I took off one point only because it is a little less playful than titles like "Hot Take Exhaust" or "Afterglow". That is optional, not a rule break. Only the title was given for scoring.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Shockwave Reach", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier6_title.txt`): it reached 8 or more.

### Run 13

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier7.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Your landing wave hits harder still. Greenbull's insurers have stopped returning calls."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: The text follows the rules. Rule 4: it is 87 characters, says what the card does first ("Your landing wave hits harder still.") and then has one aside. Rule 1: the aside is satirical and corporate, with Greenbull as the out-of-touch sponsor. The slightly unethical tone comes through, and neither the city's people nor their fear is the joke. Rules 2 and 3: no banned words, no "Greenbull says" line, no real brands. Rule 1 is the only weak point. The line "Greenbull's insurers have stopped returning calls" is a bit mild and generic. It doesn't tie to Greenbull's profit and brand obsession the way the existing cards do (e.g. "pending legal review", "brought to you by Greenbull"). It also reads as Greenbull being in trouble, not Greenbull being callous or chasing profit. To reach 9 or 10, rework the aside so Greenbull's profit or brand focus is the joke, for example Greenbull treating the damage as a marketing win. Keep the total at 90 characters or fewer.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Your landing wave hits harder still. Greenbull's insurers have stopped returning calls.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier7_desc.txt`): it reached 8 or more.

### Run 14

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier7.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Harder Landing III"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The title passes the checked rules (2, 3, 4: 18 of 30 characters, no banned words, no "Greenbull says"). It matches the existing card titles, which are short, plain and sometimes carry a roman numeral: "Quicker Trigger III", "Wider Burn III". It states what the upgrade does (landing hits harder), uses no number and mentions no real brand. Rule 1 (tone) is only lightly served, because the satire belongs in the description's aside, not the title. The brief does not ask for satire in the title. The numeral III is consistent with the tier-7 pattern. One caveat: no "Harder Landing" title exists yet in game/, so I could not check it against the earlier tiers of this weapon. If tiers 3 and 5 are not "Harder Landing" and "Harder Landing II", the III would look odd. Otherwise no fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Harder Landing III", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier7_title.txt`): it reached 8 or more.

### Run 15

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier8.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Landings send out the biggest, hardest-hitting wave yet. Greenbull calls it a mic drop."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 2: no banned words. Rule 3: it is Greenbull's own level-up voice, and "Greenbull calls it a mic drop" is not a "Greenbull says ..." line. There are no real brands. Rule 4: it is 87 characters (limit 90) and says what the card does first, in general words with no numbers, then has one aside. Rule 1: the tone is tongue-in-cheek and never sincere or earnest, and the city's people are not the joke. The only weakness is that the aside is mild. "Mic drop" is a generic phrase and doesn't clearly mock corporate language, brand obsession or the livestream audience, so it is lighter than the satire Rule 1 asks for. A sharper aside, for example one about likes, the stream or Greenbull's profit, would score higher. The text is only 3 characters under the limit, so any rewrite should stay short.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Landings send out the biggest, hardest-hitting wave yet. Greenbull calls it a mic drop.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier8_desc.txt`): it reached 8 or more.

### Run 16

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/t_tier8.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Total Impact"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Total Impact" breaks no text rule. Rule 4: 12 characters, under the 30 limit. Rules 2 and 3: no banned words, no "Greenbull says" form, no real brand. Rule 1: a card title doesn't need an aside, and the plain, punchy corporate-sounding phrase fits the existing tier-8 titles ("Through and Through", "Always Lit", "Blinding Glow"). It says in general words that this is the last, biggest wave, and has no numbers. Nothing to fix. The only reason for 9 and not 10 is that it is a little generic, but no rule asks for more.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Total Impact", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b322/o_tier8_title.txt`): it reached 8 or more.

## Result notes

Narrative Theme Agent: the Bricks card texts are written, all 16 through the style loop (each kept in round 1, scores 8 or 9, every round in the Style review above).

- **Where:** `game/scripts/ui/level_up_texts.gd` (`get_bricks.*` and `upgrade_bricks.tier2` to `tier8`, after the wiper's), and listed in `docs/weapons.md`, Content, "Bricks".
- **Card:** title "Bricks" (9); description "A bunch of bricks. No real use, other than making the car heavier. Maybe try a jump?" (8, 84 characters). The board's line is word for word; the hint is the question at the end. The rule that cards say first what they do, then an aside, is not met on purpose: the board's line is the whole joke of the card, and the style loop scored it 8.
- **Tiers:** T-323's tiers were not available, so I wrote 7 upgrade tiers (2 to 8), the same as the windshield wiper, with no numbers: tiers 2, 4, 6 widen the wave (Wider Wave, Heavier Load, Shockwave Reach), tiers 3, 5, 7 make it hit harder (Harder Landing, II, III), tier 8 is both (Total Impact). When T-323 sets its real tiers, any card whose effect differs needs rewording through the style loop.
- **Skipped:** `docs/hud-and-menus.md` is unchanged: it points to the level-up texts and the weapon's texts live in Weapons only (one decision, one document). Tests were not run: only text data changed (the length checks ran inside the loop).

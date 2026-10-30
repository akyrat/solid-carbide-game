---
id: T-412
title: Text: level-up cards for the gun's tiers 2 to 11 and the stronger neon underglow
status: done
from: project-lead
to: narrative-theme
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/extended-narrative.md, game/scripts/weapons/level_up_texts.gd, tasks/T-408-gun-one-shot-and-targets.md, tasks/T-409-underglow-two-ticks-and-push.md]
files_expected_to_change: [docs/weapons.md]
model: sonnet
qa_rounds: 1
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

The level-up cards show a title and a line per weapon tier (`game/scripts/weapons/level_up_texts.gd`, `upgrade_gun.tier2` to `tier8`, `get_underglow`, `upgrade_underglow.*`), so the board's weapon changes of 2026-10-30 (Weapons, Decisions, "The gun one-shots minions ..." and "The neon underglow kills a minion in 2 ticks ..."; T-408, T-409) need new text before the code. Write it in the same voice and length as today's lines, in Weapons, Content, under a new "Level-up card text (T-412)" heading, keyed as in `level_up_texts.gd`, where T-408 and T-409 copy it.

The numbers (the Project Lead's, for the playtest; the code follows them):
- **Gun, tiers 2 to 11 (titles and lines):** 2: +1 bullet (2 a volley); 3: +1 bullet (3); 4: fires 20% faster; 5: fires 20% faster again; 6: aims at up to 3 enemies at once; 7: +1 bullet (4); 8: +1 bullet (5); 9: fires 20% faster; 10: fires 20% faster again; 11 (the last): aims at up to 5 enemies at once. Replace today's tier 2 to 8 lines.
- **Neon underglow:** `get_underglow` now says 2 damage a second (was 1) and that it pushes enemies back a little; `upgrade_underglow.tier3` damage to 3 (was 1.5) and `tier6` to 4.5 (was 2.25). The other underglow lines keep their wording unless a number in them changes.

Run each line through the style loop (pass each title and line alone).

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Weapons, Content, "Level-up card text (T-412)" lists titles and lines for the gun's tiers 2 to 11 and the changed underglow lines, keyed as in level_up_texts.gd, with the numbers in the description. (QA: pass)
- [ ] Each went through the style loop, with its score in the Style review. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the gun's tier 2-11 card text and the stronger underglow's lines.

### 2026-10-30, In progress → In QA

Card text for the gun's tiers 2 to 11 and the underglow is in Weapons, Content; all pieces scored 8 or 9.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun2t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Extra Bullet"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Extra Bullet" is 12 characters, so it is within rule 4's 30-character limit for a level-up card title. The effect-first format and the 90-character description limit apply to the description, which this title doesn't carry. It has no banned words (rule 2). It has no "Greenbull says" line, no real brand and no city voice (rule 3). It isn't grimdark or earnest, so rule 1 is not broken. It is plain, with no satirical bite. Rule 4 asks for the aside in the description, at most one, not in the title, so that is fine. I found no fault, and the draft can stay.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Extra Bullet"): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun2d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "+1 bullet per volley, 2 in all. A free sample, courtesy of Greenbull."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 4: the effect comes first ("+1 bullet per volley, 2 in all"), followed by exactly one aside, and it is 69 characters against the 90 limit. The numbers match the brief. Rule 2: no banned words, and "Greenbull" is spelled correctly. Rule 3: the line is in Greenbull's voice on a level-up card, which is allowed, and it doesn't take the form "Greenbull says ...". There are no real brands. Rule 1: the tone is corporate and ironic, and nothing earnest or grim. It loses two points because the aside is mild. "A free sample, courtesy of Greenbull" is generic marketing speak and doesn't have the slightly unethical, profit-focused edge that rule 1 asks for. A sharper aside would be a stronger fix, for example one that frames the free sample as Greenbull's way of getting the player to buy more. This is optional, since the brief says to keep the draft unless there is a fault.
- Rules broken: none

**Kept:** version 1, score 8/10 ("+1 bullet per volley, 2 in all. A free sample, courtesy of Greenbull."): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun3t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Another Extra Bullet"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the title is 20 characters, under the 30 limit, and it states the effect (one more bullet), so effect-first holds. The numbers "+1" and "3 a volley" belong in the description, not the title. Rule 2: no banned words, and "Bullet" is plain game vocabulary. Rule 3: no "Greenbull says" line, no real brand, no city voice. Rule 1: the mild deadpan of "Another Extra" fits the satirical, tongue-in-cheek tone, with nothing grimdark or earnest. The brief says to keep the draft unless there is a fault, and there is none. I took off one point only because the title carries little satire on its own. That is fine, since the satirical aside belongs in the description.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Another Extra Bullet"): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun3d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "+1 bullet per volley, 3 in all. Greenbull feels generous on camera."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 4: the effect comes first ("+1 bullet per volley, 3 in all."), then one aside, and it is 67 characters, within the 90 limit. Rule 2: the vocabulary is correct. Greenbull is spelled right, with no banned words. Rule 3: it is not a "Greenbull says ..." line, and a level-up card may use Greenbull's things. Rule 1: the aside "Greenbull feels generous on camera." pokes at brand and camera obsession and has the slightly unethical, insincere tone, with no earnest heroics and no joke at the city's expense. Why it is not a 9 or 10: the aside is narration about Greenbull ("Greenbull feels...") instead of a line in Greenbull's own voice, and it is mild. It is also close to the "Greenbull says ..." form that rule 3 forbids. A possible fix is a short line in Greenbull's own corporate voice, such as "Generosity, now with more camera time.", which keeps the effect first and stays within 90 characters.
- Rules broken: none

**Kept:** version 1, score 8/10 ("+1 bullet per volley, 3 in all. Greenbull feels generous on camera."): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun4t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Quicker Trigger"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Quicker Trigger" breaks no text rule. Rule 4: it is 15 characters, under the 30 limit, and a title needs no aside (the description holds the effect and any aside). Rule 2: it uses no banned or old vocabulary. Rule 3: it is not a "Greenbull says ..." line and names no real brand. Rule 1: it is plain and neutral, with no earnest heroics or grimdark. It is a little flat, not satirical, but the rules ask for no satire in a title. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Quicker Trigger"): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun4d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Fires 20% faster. The audience is getting restless."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the effect comes first ("Fires 20% faster."), then one satirical aside, and it is 51 characters, under the 90 limit (script-confirmed). Rule 2: "the audience" fits the livestream framing, and no banned or old words appear (script-confirmed). Rule 3: the aside is in Greenbull's voice, which is allowed on a level-up card, and it has no "Greenbull says" form and no real brand. Rule 1: the tone is dry and ironic. It treats the audience as a metric that must be kept entertained, which is the stream-obsession joke. It does not mock the city's people. It is mild and could be slightly sharper or more corporate-slimy, but the rules don't require that, so I took off only one point for that.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Fires 20% faster. The audience is getting restless."): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun5t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Quicker Trigger II"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No Text rule is broken. Rule 4: the title is 18 characters, under the 30 limit, and the script confirms it. Rules 2 and 3: no banned vocabulary, no real brand, no "Greenbull says" line. Rule 1: a short, plain gun-upgrade title that is neutral and fits the tone. The effect and the aside belong in the description, which is a separate piece. One small note, not a rule break: "II" doesn't show that this is tier 5, but the brief said to keep the draft.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Quicker Trigger II"): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun5d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Fires 20% faster again. Engagement waits for no one."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: The text follows the rules. Rule 4: effect first ("Fires 20% faster again."), then one aside, 52 characters (limit 90), number kept exactly. Rule 1: "Engagement waits for no one." is a tongue-in-cheek corporate-speak aside about engagement metrics. It is not earnest, and it doesn't make the city's people or their fear the joke. Rule 2: no banned words. Rule 3: Greenbull's voice is allowed on level-up cards, there is no "Greenbull says" line, and there are no real brands. Small weakness: the aside is mild and generic. It could tie more clearly to the stream (viewers or subs) and to the slightly unethical, profit-focused Greenbull tone. That is optional polish and breaks no rule. No fix is required.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Fires 20% faster again. Engagement waits for no one."): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun6t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Multi-Target Mode"
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 4: the title is 17 characters, under the 30 limit. The "effect first, then at most one aside" format applies to the description, and this is only the title. Rules 2 and 3: no banned vocabulary, no real brands, and no "Greenbull says" line. Rule 1: "Multi-Target Mode" names the effect (aiming at several enemies) and "Mode" gives a faint corporate feature-speak flavour. It is plain and not sincere heroics, grimdark or gore. It is a bit flat for a satirical voice. The only possible improvement is a slightly more corporate or brand-obsessed wording, but the brief says to keep the draft unless there is a fault, and there is none. Keep it.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Multi-Target Mode"): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun6d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Aims at up to 3 enemies at once. Multitasking is a brand value."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: Rules 2, 3 and 4 pass, per the script checks (63 characters, under the 90 limit). Rule 4's structure holds: the card says what it does first ("Aims at up to 3 enemies at once."), then adds one aside, and the number 3 is kept. Rule 1 (tone) is met but only just. "Multitasking is a brand value." is deadpan corporate-speak in Greenbull's voice, but it is mild. It doesn't land the "slightly unethical", profit-focused feel, and it is generic rather than tied to the stream or the brand's profit. A sharper aside would score higher, for example one that treats the 3 targets as extra sponsored content. No rule is broken, so the text can stay as it is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Aims at up to 3 enemies at once. Multitasking is a brand value."): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun7t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Bullet Bundle"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Bullet Bundle" breaks no text rule. Rule 4: it is 13 characters, under the 30 limit, and the script confirms it. Rules 2 and 3: it has no banned words, no "Greenbull says" form and no real brand. Rule 1: the alliteration and the "bundle" wording echo corporate gift-pack and bundle marketing, which fits the satirical tone without being earnest or grim. It also names what the card does, since it adds a bullet. It could be a little sharper, but no rule is broken, and the brief says to keep the draft unless there is a fault. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Bullet Bundle"): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun7d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "+1 bullet per volley, 4 in all. Buy more, shoot more."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: The text follows Text rules 1 to 4. Rule 4 (level-up card): the effect comes first ("+1 bullet per volley, 4 in all."), then one satirical aside ("Buy more, shoot more."), and the 53 characters are under the 90 limit. The numbers are kept. Rule 2: no banned words. Rule 3: no "Greenbull says" line, no real brand, and the voice is Greenbull's own. Rule 1: the aside is a consumerist slogan, so it is on tone. It is mild, though. It is only a generic buy-more slogan with no corporate or brand-obsession bite and no slightly unethical edge, and "shoot more" has no tie to the stream, subs or gift packs. No rule is broken. To raise the score, make the aside sharper in Greenbull's out-of-touch, profit-driven voice, for example one tied to the gift pack or the audience, while keeping the effect first and the length under 90.
- Rules broken: none

**Kept:** version 1, score 8/10 ("+1 bullet per volley, 4 in all. Buy more, shoot more."): it reached 8 or more.

### Run 13

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun8t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Bulk Bullets"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: "Bulk Bullets" breaks no Text rule. Rule 4: 12 characters, under the 30 limit, and the script confirms it. Rules 2 and 3: no banned vocabulary, no real brand, no "Greenbull says" line. Rule 1: the wholesale-shopping sound of "Bulk" fits the corporate-satire tone and is never earnest, and nothing mocks the city's people. The title also hints at the effect, since more bullets are bought in bulk. The only reason it isn't a 10 is that the satire is light, but the rules don't ask for satire in a title. No fix is needed. Keep it.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Bulk Bullets"): it reached 8 or more.

### Run 14

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun8d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "+1 bullet per volley, 5 in all. Terms and conditions apply to enemies."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule broken. Rule 4: it is 70 characters, under the 90 limit, and it says what the card does first ("+1 bullet per volley, 5 in all."), then gives exactly one aside. The numbers match the brief. Rule 1: "Terms and conditions apply to enemies." mocks corporate legalese, with a slightly unethical note in Greenbull's out-of-touch voice. It is not grimdark, and the city's people and their fear are not the joke. Rule 2: it uses no banned or old vocabulary. Rule 3: it is a Greenbull-voiced level-up card, so that voice is allowed, and it has no "Greenbull says" line and no real brand. I took 1 point off because the aside is mild and a little generic. It does not use the stream, subs or gift-pack framing. That is a matter of taste the rules don't cover, so nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("+1 bullet per volley, 5 in all. Terms and conditions apply to enemies."): it reached 8 or more.

### Run 15

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun9t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Quicker Trigger III"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The title breaks no rule. Rule 4: it is 19 characters, under the 30 limit, and a title needs no aside. Rule 2: it has no banned vocabulary and no real brand. Rule 3: it has no "Greenbull says" form. Rule 1: it is plain and neutral, and it has no earnest heroics or grimdark. It names the effect (faster fire) and the tier (III) clearly. It is not satirical, but the rules put the satirical aside in the description, not the title. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Quicker Trigger III"): it reached 8 or more.

### Run 16

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun9d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Fires 20% faster. Content never sleeps."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 4: 39 characters, under the 90 limit, and the card says what it does first ("Fires 20% faster.") and then adds one aside. The number is kept exactly. Rule 1: "Content never sleeps." mocks hustle-culture and brand-obsessed corporate language, and it never targets the city's people or their fear. Rule 2: no banned words. The stream and content framing fits. Rule 3: Greenbull's voice is allowed on level-up cards, and there is no "Greenbull says" line and no real brand. The only reason for not giving a 9 or 10 is that the aside is a mild, generic slogan. It doesn't tie to the gun or the fire rate, and it isn't clearly "slightly unethical". That isn't a rule break, so no fix is needed.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Fires 20% faster. Content never sleeps."): it reached 8 or more.

### Run 17

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun10t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Quicker Trigger IV"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the title is 18 characters, under the 30 limit, and the description rule doesn't apply to a title. Rule 2: it uses no banned or old vocabulary. Rule 3: it has no "Greenbull says" line, no real brand and no city voice. Rule 1: it is short and neutral, and a title needs no satire because the aside belongs in the description. "Quicker Trigger IV" matches the tier-10 "again" progression. The one point off is that the title is a plain gameplay label with no Greenbull flavour. The rules don't ask for flavour here, so no fix is required.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Quicker Trigger IV"): it reached 8 or more.

### Run 18

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun10d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Fires 20% faster again. The feed refreshes for no one."
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: No hard rule is broken. Rule 2: no banned words. Rule 3: no "Greenbull says" line and no real brand. Rule 4: 54 characters, under the 90 limit, and the effect comes first, followed by exactly one aside. "Fires 20% faster again." keeps the brief's number. The only weakness is rule 1 (tone). The aside "The feed refreshes for no one." reads as lonely or bleak, not as Greenbull's out-of-touch, profit-minded corporate voice. It mocks nothing specific (brand obsession, engagement, content) and has no slightly unethical edge. This is a minor tone fault, so the draft can be kept. An optional fix is to make the aside clearly Greenbull's, for example about engagement or content being monetised, so the joke lands on the sponsor and not on an empty feed. Keep the effect sentence and the aside under 90 characters in total.
- Rules broken: 1

#### Round 2

- Version 2: "Fires 20% faster again. Viewers blink less, so we sell more ads."
- What changed: I kept the effect sentence "Fires 20% faster again." exactly as it was. I replaced the bleak aside with one in Greenbull's voice. The sponsor now says plainly that a faster gun keeps viewers' eyes on the stream so it can sell more ads. That is the slightly unethical, profit-minded tone rule 1 asks for, and the joke now lands on Greenbull, not on an empty feed. The text is 64 characters, under the 90 limit, with one aside and no banned words or real brands.
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: Passes all the rules. Rule 4: effect first ("Fires 20% faster again."), then one satirical aside, 64 characters, number kept exactly. Rule 1: the aside mocks corporate ad-selling and profit focus, and Greenbull is out of touch and slightly unethical in it. It doesn't joke about the city's people. Rule 2: no banned words. Rule 3: it is a level-up card, so Greenbull's voice fits, and it has no "Greenbull says" form and no real brands. The only small weakness is that the aside is a bit literal and generic ("so we sell more ads"). The brief said to keep the draft ("The feed refreshes for no one.") unless there is a fault, and the evaluator finds no rule fault in the draft. The agent should have kept the draft. This version is acceptable, but the draft would be the safer choice.
- Rules broken: none

**Kept:** version 2, score 9/10 ("Fires 20% faster again. Viewers blink less, so we sell more ads."): it reached 8 or more.

### Run 19

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_title, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun11t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Everyone Gets Exposure"
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 1 (tone): "Everyone Gets Exposure" mocks corporate creator-economy language ("paid in exposure") in Greenbull's out-of-touch, slightly unethical voice. It isn't earnest or grim, and it doesn't make the city's people or their fear the joke. Rule 2: no banned or old terms. Rule 3: it is in Greenbull's voice, which fits a level-up card, it has no "Greenbull says" form, and it names no real brand. Rule 4: it is a title of 22 characters, under the 30 limit. The "effect first" order applies to the description, so the title can be the aside. The title doesn't state the effect itself ("up to 5 enemies"), so the description must carry that effect and the number 5 exactly. The only weak point is that "Exposure" is a slightly familiar joke, but no rule covers that.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Everyone Gets Exposure"): it reached 8 or more.

### Run 20

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/gun11d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Aims at up to 5 enemies at once. Nobody is left unengaged."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 4: the effect comes first and the text has one aside, at 58 of 90 characters. The numbers are kept ("up to 5 enemies at once"). Rules 2 and 3: the script checks pass, and there are no banned words, no "Greenbull says" line and no real brands. Rule 1: "Nobody is left unengaged" plays on engagement metrics, which is soulless corporate and social-media language. It is dry rather than sincere, and it makes no joke at the city's people. It doesn't read as clearly Greenbull and slightly unethical, so it is a little mild. This is a nitpick, not a fault, and the brief says to keep the draft unless there is a fault. Optional sharpening only: a more openly profit-minded or audience-minded aside, for example about every target being a viewer-friendly opportunity. The aside must stay under 90 characters in total.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Aims at up to 5 enemies at once. Nobody is left unengaged."): it reached 8 or more.

### Run 21

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/ug1d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A neon ring burns nearby enemies, 2 damage a second, and nudges them back. So aesthetic."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 4: 88 characters (limit 90), and the effect comes first with exactly one aside ("So aesthetic."). The brief's numbers are kept. Rule 1: the aside mocks social-media and brand-obsessed talk and doesn't joke about the city or its people. It is also not earnest or grimdark. Rule 2: no banned or old vocabulary. Rule 3: it is a level-up card, which is Greenbull's voice, with no "Greenbull says" line and no real brand. One small note, not a violation: the aside is mild and doesn't show Greenbull's profit-minded, slightly unethical edge. That is optional polish, and the draft should stay unless a sharper aside fits within 90 characters.
- Rules broken: none

**Kept:** version 1, score 8/10 ("A neon ring burns nearby enemies, 2 damage a second, and nudges them back. So aesthetic."): it reached 8 or more.

### Run 22

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/ug3d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Glow damage up 50%, to 3. Looks expensive."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the effect comes first ("Glow damage up 50%, to 3."), then one satirical aside ("Looks expensive."), at 42 characters, under the 90 limit. Rule 1: the aside mocks brand and status obsession lightly, is not sincere, and doesn't joke about the city's people. Rule 2: the script found no banned words, and no off-vocabulary terms appear. Rule 3: it is in Greenbull's voice, appropriate for a level-up card, with no "Greenbull says" line and no real brand. The numbers match the brief exactly. The only reason for not giving 10 is that the aside is mild and could be sharper on corporate language, but the rules don't require that.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Glow damage up 50%, to 3. Looks expensive."): it reached 8 or more.

### Run 23

Run by `tools/style_loop/run.py` on 2026-10-30: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/b/ug6d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Glow damage up another 50%, to 4.5. Peak aesthetic."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the card says what it does first ("Glow damage up another 50%, to 4.5"), then gives one short satirical aside ("Peak aesthetic."). It is 51 characters, under the 90 limit, and the numbers match the brief exactly. Rule 1: the aside mocks brand and social-media aesthetics and does not make fun of the city's people. Rule 2: no banned words. Rule 3: Greenbull's voice is allowed on level-up cards, and there is no "Greenbull says" line and no real brand. The only reason for 9 and not 10 is that the aside is mild and generic, with little corporate-profit bite. That is a matter of taste the rules don't cover, so no change is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Glow damage up another 50%, to 4.5. Peak aesthetic."): it reached 8 or more.

## Result notes

All 13 cards (gun tiers 2 to 11, title and line; get_underglow.desc; underglow tier3 and tier6 desc) are in Weapons, Content, "Level-up card text (T-412)", keyed as in level_up_texts.gd. Each piece went through the style loop alone: all kept at 8 or 9; only tier 10's line needed one refine (7 to 9). Documents affected: docs/weapons.md.
- 2026-10-30, in-qa → done: QA passed

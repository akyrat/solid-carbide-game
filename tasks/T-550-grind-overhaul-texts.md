---
id: T-550
title: Texts for the grind overhaul, the jump arrow and the Cosmetics menu
status: in-qa
from: project-lead
to: narrative-theme
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, docs/garage-design.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md, docs/garage-design.md]
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

Write every player-facing text the overhaul needs, through the style loop, into the data files the game already reads texts from (or a new one the UI ticket T-553 will read, named in your notes). (1) New texts: the main menu button that opens the Cosmetics submenu; the submenu's title, and its labels for a locked item with its price, buying, picking (equipped) and not enough coins; a name and a one-line description for each of the 5 jump effects (ids: dash_cloud, spring, jet_thrust, stunt_sparks, shockwave_ring; HUD and menus Decisions and Drifting, Decisions, "A jump effect around the car"); the label of the pause screen's checkbox for the jump arrow (HUD and menus, Decisions, "The jump arrow"), in the Drift Guide checkbox's voice. (2) Every existing text the overhaul makes wrong: search the game's data and docs for texts about grinding, Jump off a rail, the Jump power-up's cooldown (it has none now) and how a grind starts (now: hold Space in the air and touch a rail; release Space to launch where the car faces): the tutorial's slides, the trick list's GRIND! recipe, the Jump power-up's card and mission gift texts, and any other. Fix each, and list each text you changed with its file and key in the result notes. The texts the menu and checkbox use are listed with their keys, for T-553.

The board's review: read the new and changed texts in the combined build (playtest/grind-overhaul).

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each new text in the description exists in a data file with a key, listed in the result notes with what it is for and where it appears. (QA: pass)
- [ ] Every existing text about grinding, Jump off a rail or the Jump cooldown that the overhaul makes wrong is changed, each listed with its file and key, and a search of game/data for "cooldown" near Jump shows none left. (QA: pass; only Jump's numeric cooldown_seconds in power_ups.json remains, T-551 removes it)
- [ ] Each text has a style loop score of 8 or more in the Style review, or is noted for the playtest. (QA: pass; Premium Shockwave Ring 7 is noted for the playtest)
- [ ] docs/hud-and-menus.md and docs/garage-design.md Content list the new texts. (QA: pass)
- [ ] The tests for the changed data pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass; round 2: all test sets pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: texts for Cosmetics, the jump effects, the arrow checkbox, and fixing texts about grinding and the Jump cooldown.

### 2026-11-07, In progress → In QA

Texts written; one effect name scored 7 (Premium Shockwave Ring), noted for your playtest. QA now.

### 2026-11-07, In QA → In progress

QA round 1: a text inventory test fails (the new cosmetics text file isn't listed) and screenshots are missing. Back to the agent.

### 2026-11-07, In progress → In QA

Fixed: the text list test and screenshots. QA round 2.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/menu.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Cosmetics"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Cosmetics" is one word, sentence case, short and plain, so it fits rule 4 (menu labels). It has no banned words (rule 2) and no "Greenbull says" form (rule 3). It matches the sibling buttons Start, Garage, Past streams and Exit. It carries no satire (rule 1), but the rules ask for plain labels, so that costs only a little. I found no rule it breaks, and there is nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Cosmetics", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/menu.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Cosmetics"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Cosmetics" is a short, plain, one-line label in sentence case (rule 4, menu and settings labels). It has no banned words (rule 2). It has no "Greenbull says ..." form and no real brand (rule 3). It is a neutral menu title, so nothing in it clashes with the tone (rule 1). The only thing keeping it from a 10 is that it carries no satire. Rule 1 asks for satirical text, but rule 4 asks for short and plain labels, and the brief asked for a short, title-like text, so a plain title is correct here. No fix needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Cosmetics", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/title.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/locked.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Unlock for {price} coins"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Unlock for {price} coins" meets the script checks: no banned words, no "Greenbull says" line, one line, sentence case. It has the {price} slot exactly once and is short enough for a small button. Rule 4 asks menu and settings labels to be short and plain, and this is. Rule 1's satire has little room in a plain price label, and the text is neutral, not off-tone. Rule 3 is not broken, since it isn't in Greenbull's voice. It uses "coins", the currency named in the brief. I couldn't read the full vocabulary line of rule 2, so I'm relying on the script's rule 2 check. The text is correct but flat; if the board wants some Greenbull flavour, that would be a taste change the rules don't require.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Unlock for {price} coins", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/locked.txt`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/buy.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Unlock"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Unlock" breaks no rule. Rule 4 (menu labels short, plain, sentence case): it is one plain word in sentence case. Rule 2 (vocabulary): no banned words. Rule 3: no "Greenbull says" form and no real brand. Rule 1 (tone): a button label is plain by rule 4, so it needs no satire. The word is plain, clear and accurate for buying a locked cosmetic. The only weakness is that it doesn't say the coins are spent ("Unlock" vs a coin-priced label), but that is optional and the price can sit beside the button. If the maker wants a refine, a tiny brand-flavoured option is possible, but "Unlock" is acceptable as is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Unlock", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/buy.txt`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/equipped.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Equipped"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Equipped" meets rule 4 (menu and settings label: short, plain, sentence case, one word) and rules 2 and 3 (no banned words, no "Greenbull says" line). It fits the brief: 1-2 words, the state label for the currently picked cosmetic. Rule 1 (satirical tone) is not broken. A plain functional label is what rule 4 asks for, so there is nothing to fix. Not a 10 because it carries no Greenbull flavour, and rule 1 makes that optional for plain menu labels.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Equipped", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/equipped.txt`): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/pick.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Equip"
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: Rule 4 (menu labels): short, plain, sentence case, one line. "Equip" passes. Rules 2 and 3 pass (no banned words, no "Greenbull says"). Rule 1 (satirical tone) is not broken, but the label has no flavour. Plain labels are what rule 4 asks for, so this is acceptable. A small Greenbull-flavoured touch could lift it, but it must stay 1-2 words and plain. Nothing needs fixing.
- Rules broken: none

#### Round 2

- Version 2: "Flex it"
- What changed: Version 2 adds the light flavour the reason asked for and keeps the label at 2 words, plain, in sentence case (rule 4). "Flex it" is influencer slang for showing off, so equipping a jump effect reads like posing for the stream (rule 1, mocking social media). The button sits on an unlocked cosmetic, so it still clearly means equip. It uses no banned words and no Greenbull voice (rules 2 and 3).
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Flex it" passes the script checks (rules 2, 3, 4: one line, sentence case, 2 words, no banned words, no "Greenbull says"). Rule 1 (tone): a light, ironic, influencer-flavoured verb that fits the livestream and brand-obsession satire without making the city the joke. Rule 4 asks menu labels to be "short and plain", and "Flex it" is slightly slangy rather than plain. It also does not read as "equip" or "select", so a player might not see that it picks the cosmetic. It is clear enough from context, and the tone fits. If you want to push toward plain, use "Equip" or "Use it", but this is acceptable as is.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Flex it", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/pick.txt`): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/poor.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Not enough coins. Looking this good isn't free."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['Looking'])
- Score: 6/10
- Reason: Rule 4 (menu and settings labels: short, plain, sentence case) fails the script check "sentence case": it flags the capitalised "Looking", the start of the second sentence. Written by hand, two sentences would be normal sentence case, but the script check counts as a fact, so as written the line fails. Fix: make it a single sentence with only the first word capitalised, for example "Not enough coins, and looking this good isn't free." Rules 1, 2 and 3 are fine. The tone is mildly satirical and in the garage's voice, with no banned words and no "Greenbull says". The joke is gentle, though; one more beat of Greenbull-style brand obsession would fit rule 1 better.
- Rules broken: 4
- Refused: {"tool_input": {"command": "sed -n '41p' /c/solid-carbide-worktrees/T-550/docs/extended-narrative.md; grep -n -i \"coin\\|not enough\\|garage voice\\|voice of the garage\" /c/solid-carbide-worktrees/T-550/docs/hud-and-menus.md /c/solid-carbide-worktrees/T-550/docs/garage-design.md | head -40", "description": "Read vocabulary rule and coin text references"}, "tool_name": "Bash", "tool_use_id": "toolu_016AJudeJvBZuAZnPpHQxb7e"}

#### Round 2

- Version 2: "Not enough coins, and looking on-brand isn't free."
- What changed: Version 2. The line is now one sentence, so only the first word starts with a capital. That passes the script's sentence-case check (rule 4). I kept "Not enough coins" so it still matches the Garage's wording. For rule 1, "looking this good" became "looking on-brand", which adds the brand-obsession beat the evaluator asked for. I left out "Greenbull" on purpose: a capitalised proper noun could trip the sentence-case check again. It's still short and has no banned words.
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: Mostly on-style. Rule 1 (tone): "looking on-brand isn't free" is a light corporate-brand jab in the garage's voice. It targets brand obsession, not the city or its people. Rule 3: the garage is Greenbull's own area, so its voice is allowed, and there is no "Greenbull says" line and no real brand. Rule 4 (menu and settings labels): the script checks pass (one line, sentence case). The rule asks for "short and plain", and this is a clause plus a quip, so it is a little more than plain. To fix: make the aside shorter and plainer, for example "Not enough coins. Style isn't free." Rule 2 (vocabulary): "coins" fits the game's vocabulary. No rule is clearly broken; the only weakness is that it is slightly wordy and the joke is mild.
- Rules broken: none

#### Round 3

- Version 3: "Not enough coins: style isn't free."
- What changed: Version 3. I cut the aside to "style isn't free", as the evaluator asked, so the line is shorter and plainer for rule 4 and the brand jab still hits. I used a colon instead of the evaluator's two-sentence example. A second sentence would start with a capital "Style", and that fails the sentence-case script check again, as it did in version 1. "Not enough coins" still matches the Garage's wording, and there are no banned words.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rule 1 (tone): "style isn't free" is a light, ironic, brand-flavoured quip, not earnest, and it doesn't touch the city's people. Rule 2: "coins" is the stated currency and there are no banned words. Rule 3: it uses the garage's voice and has no "Greenbull says" form. Rule 4 (menu and settings label): it is one line in sentence case, short and plain. One small point: the satire is mild and doesn't point at corporate or sponsor language. A sharper aside (for example about Greenbull monetising looks) would fit rule 1 better. That is optional.
- Rules broken: none

**Kept:** version 3, score 8/10 ("Not enough coins: style isn't free.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/poor.txt`): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/arrow.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Facing arrow"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Facing arrow" follows the rules. It is two words, one line and sentence case, and it is short and plain like "Music volume" (rule 4, settings labels). It uses no banned words and has no "Greenbull says" form (rules 2 and 3). It has no joke, but a settings label isn't supposed to carry one (rule 1). It describes what the arrow shows and fits next to "Drift Guide" and "Rain". The only reservation is that "Facing" is slightly technical. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Facing arrow", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/arrow.txt`): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_name, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/dash_cloud_n.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Dash cloud"
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: "Dash cloud" is the exact name the brief gave. It is 10 characters, so it is under the 25 limit (rule 4). It is plain sentence case, with no banned words, no "Greenbull says" line and no real brand (rules 2 and 3). It makes no fun of anyone, so rule 1 isn't broken. The only weakness is that it carries no Greenbull-style satire. A bare name is acceptable for a free default effect, and the rules don't require a joke in a name, so nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Dash cloud", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/dash_cloud_n.txt`): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/dash_cloud_d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A little puff of dust under every jump. Free, which Greenbull finds awkward."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. It says first what the effect does ("A little puff of dust under every jump"), which matches the brief. The aside "Free, which Greenbull finds awkward" fits rule 1: Greenbull is profit-focused and out of touch, and the joke is on Greenbull, not on the city's people. Greenbull is the speaker for the garage, so rule 3 is met, and the text is not a "Greenbull says ..." line. It names no real brand and no number. The script checks pass: 76 characters (limit 80), no banned words, no number. The one small weakness is that "awkward" is mild, so the joke could be sharper (for example, a dig at the missing price). That is optional and not a rule breach.
- Rules broken: none
- Refused: {"tool_input": {"command": "python -c \"s='A little puff of dust under every jump. Free, which Greenbull finds awkward.';print(len(s))\"", "description": "Count characters of draft"}, "tool_name": "Bash", "tool_use_id": "toolu_01C91FTufJwyvXv5LnxKNgd9"}

**Kept:** version 1, score 9/10 ("A little puff of dust under every jump. Free, which Greenbull finds awkward.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/dash_cloud_d.txt`): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_name, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/spring_n.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Spring Loaded"
- Script checks: 3 of 3 pass
- Score: 6/10
- Reason: Rules 2, 3 and 4 pass by script (13 characters, no banned words, no "Greenbull says"). The name is valid, short and on brand for a garage item. It is fairly plain and has little satire. It is a stock pun on "spring-loaded" that could come from any generic game. Rule 1 asks for a satirical, tongue-in-cheek tone that mocks corporate language, social media or brand obsession. "Spring Loaded" has no hint of that. To fix it, keep the name short (at most 25 characters) and give it a corporate or influencer flavour, in the style of a brand-speak product name (e.g. "Synergy Spring"). Do not invent a real brand name. It should still say plainly that it is the spring effect.
- Rules broken: 1

#### Round 2

- Version 2: "Engagement Spring"
- What changed: Version 2 adds the satire the evaluator found missing (rule 1). Social-media jargon replaces the stock pun: 'engagement' is the metric a livestream chases, so the spring that boosts the car also boosts the stream's numbers, in brand-speak. 'Spring' stays in the name, so the player still sees plainly that it is the spring effect. It is 17 characters (the limit is 25), uses no banned words or real brands, and doesn't use a 'Greenbull says' line.
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 1 (tone): "Engagement" is soulless social-media jargon, so it is a light satirical jab, and it doesn't touch the city or its people. The name still says what the effect is: a spring. Rule 3: it is Greenbull's garage voice, uses no real brand and is not a "Greenbull says" line. Rule 4: 17 characters, within the 25 limit, and the script confirms it. Rule 2: the script found no banned words, and nothing in the name conflicts with the stream vocabulary, though I could not read the full rule 2 text. It loses points only because the joke is mild. A sharper corporate twist would help, for example a metrics or monetisation word in place of "Engagement", as long as "Spring" stays and the name stays under 25 characters.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Engagement Spring", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/spring_n.txt`): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/spring_d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A spring pops the car into the air. Gravity's contract is under review."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. Rule 1 (tone): "Gravity's contract is under review" mocks soulless corporate and HR language, is ironic and not earnest, and doesn't joke about the city's people. Rule 3: it has no "Greenbull says" form and names no real brand. Rule 4: the script confirms 71 characters (limit 80) and no number. It says what the effect does first ("A spring pops the car into the air"), then adds one satirical aside, the same pattern as the level-up cards. The aside is a little generic. It doesn't mention Greenbull or the stream, so a sharper version could tie the joke to the sponsor or the audience, but no rule requires that.
- Rules broken: none

**Kept:** version 1, score 9/10 ("A spring pops the car into the air. Gravity's contract is under review.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/spring_d.txt`): it reached 8 or more.

### Run 13

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_name, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/jet_n.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Jet Thrust (Sponsored)"
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: No rule is clearly broken. The script checks pass (22 of 25 characters, no banned words, no "Greenbull says" line). The tone fits rule 1: "(Sponsored)" mocks brand obsession in a light, slightly unethical way, and the city's people are not the joke. Rule 3 is fine because the garage is Greenbull's voice. Two weaknesses cost points. (1) The brief asked for only the name of the effect 'jet thrust'. The "(Sponsored)" tag turns the name into a name plus a gag, and it uses 11 of the 25 characters. If every cosmetic gets the same tag, it stops being funny. (2) The joke is a generic internet label, not specific Greenbull corporate language. To fix it, either drop the tag and use the plain name "Jet thrust", or write a more specific corporate-speak name (for example "Jet Thrust Pro Max") that stays within 25 characters. Keep it consistent with the other cosmetic names.
- Rules broken: none

#### Round 2

- Version 2: "Jet Thrust Zero Sugar"
- What changed: Version 2. I replaced the generic "(Sponsored)" tag with energy-drink product-line wording, "Zero Sugar". That makes the joke Greenbull's own corporate language instead of a general internet label, and it reads as one product name rather than a name with a gag stuck on. The effect is still named plainly first, so the player knows what they're buying. It is 21 of the 25 characters (rule 4), uses no banned words (rule 2), is in Greenbull's garage voice (rule 3), and keeps the light brand-obsession satire (rule 1). Other cosmetics can use other product-line words (Original, Ultra, Limited Edition) so the joke doesn't repeat.
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 1 (tone): "Zero Sugar" parodies energy-drink product-variant branding, so it mocks brand obsession and fits Greenbull's voice without being sincere or grim. Rule 2 (vocabulary): no banned words or off-vocabulary terms. Rule 3 (who speaks): it is a plain name, not a "Greenbull says ..." line, and "Zero Sugar" is a generic label, not a real brand. Rule 4 (format and length): 21 characters, under the 25 limit. It still names the effect, "jet thrust". The only small reservation is that "Zero Sugar" is a fairly common joke format. Nothing needs fixing.
- Rules broken: none

**Kept:** version 2, score 9/10 ("Jet Thrust Zero Sugar", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/jet_n.txt`): it reached 8 or more.

### Run 14

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/jet_d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A jet flame blasts under your car on every jump. Safety review pending."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rules broken. Rule 4 (script): 71 characters, under the 80 limit, and it names no number. Rule 2: it uses no banned word. "Your car" is plain and consistent. Rule 3: it has no "Greenbull says" form, no real brand, and it fits Greenbull's garage voice. Rule 1: it says what the effect does first, then adds one dry corporate aside. "Safety review pending" is soulless compliance language that implies Greenbull is shipping an unsafe flame anyway. That is the slightly unethical, out-of-touch tone the rule asks for. The city's people are not the joke, and there is no grimdark. Only a small point is left. "Pending" is a mild joke, not a sharp one. It could be a little more specific to Greenbull's profit-first attitude, but that is optional.
- Rules broken: none

**Kept:** version 1, score 9/10 ("A jet flame blasts under your car on every jump. Safety review pending.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/jet_d.txt`): it reached 8 or more.

### Run 15

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_name, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/sparks_n.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Stunt sparks"
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: "Stunt sparks" is the name the brief gave, and the script checks pass. It is 12 characters against a limit of 25, in sentence case, with no banned words, no "Greenbull says" line, no real brand and no number. It fits the player's identity as Stunt Driver, and it describes the effect (sparks under the car) in plain words.

It is a little flat for rule 1's satirical tone. It has no Greenbull-flavoured irony, though a bare effect name need not carry any. This is a minor point and not a break. I could not see rule 2's full text because the file omits it. Nothing in the name touches the vocabulary it covers (subs, coins, the combo multiplier).
- Rules broken: none

**Kept:** version 1, score 8/10 ("Stunt sparks", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/sparks_n.txt`): it reached 8 or more.

### Run 16

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/sparks_d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Sparks burst under the car on every jump. Greenbull calls it content."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: It breaks no rule I can find. It says what the effect does first ("Sparks burst under the car on every jump"), then adds one satirical aside ("Greenbull calls it content"). The aside mocks Greenbull's brand-obsessed, profit-first view of the stream, so it fits rule 1 (tone). Greenbull speaks in the garage, which rule 3 allows, and the line is not in the "Greenbull says ..." form. It names no number and is 69 characters, within rule 4's 80. It uses no banned words. The only reason it is not a 10 is that I could not read rule 2 (the vocabulary), which the document omits in the section I was given. "Content" and "car" look fine against it, but I could not check them against that rule.
- Rules broken: none
- Refused: {"tool_input": {"command": "sed -n '41p' /c/solid-carbide-worktrees/T-550/docs/extended-narrative.md", "description": "Show vocabulary rule line"}, "tool_name": "Bash", "tool_use_id": "toolu_01YKp9EC7gEZrBMWe5LC3c39"}

**Kept:** version 1, score 9/10 ("Sparks burst under the car on every jump. Greenbull calls it content.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/sparks_d.txt`): it reached 8 or more.

### Run 17

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_name, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/ring_n.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Premium Shockwave Ring"
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: No rule is broken. Rule 4 passes at 22 characters, under the 25 limit. Rules 2 and 3 pass by script. Rule 1 (tone): "Premium" is a mild corporate upsell word, so Greenbull's profit-minded voice shows, and it names the shockwave ring clearly with nothing earnest or grim. It scores 7 and not higher because the satire is thin. "Premium" is generic marketing filler and the name carries no real joke. To reach 8 or 9, make the corporate flourish more pointed, for example "Shockwave Ring (Sponsored)" or "Ring Pro Max", while staying under 25 characters, keeping the name recognisable and using no numbers.
- Rules broken: none

#### Round 2

- Version 2: "Shockwave Ring Pro Max"
- What changed: Version 2. I replaced the generic "Premium" with "Pro Max", which mocks the way tech products pile on tiers to upsell, so the satire is sharper (rule 1). The plain "Shockwave Ring" stays, so the player still knows what the effect is. The name is 22 characters, still under the 25 limit (rule 4), with no numbers, banned words or real brands.
- Script checks: 3 of 3 pass
- Score: 4/10
- Reason: Rules 2, 3 and 4 pass by the script checks (22 characters, no banned words, no "Greenbull says" line). Rule 4's garage-name format also asks for a name that is short and plain, and this one is padded.

It breaks rule 1 (tone). "Pro Max" is a generic phone/tech product suffix. It reads as a joke at the product-naming trend, but it is not tied to Greenbull's out-of-touch, profit-driven corporate voice, and it is not funny in itself. The rule wants satire of soulless corporate language, social media or brand obsession.

"Pro Max" is also close to a real brand's naming scheme (Apple's "iPhone Pro Max"). Rule 3 says no real brands, so the suffix is a likely violation. It is also a stretch for a ring that ripples out on the ground. The fix is to drop the suffix.

Safe fix: write plain "Shockwave ring" in sentence case, which matches the plain-label style. If satire is wanted, make it a Greenbull-flavoured, brand-obsessed name such as "Shockwave ring (sponsored)". Keep it within 25 characters and use no real-brand echoes.
- Rules broken: 1, 3

#### Round 3

- Version 3: "Sponsored shockwave ring"
- What changed: Version 3. I dropped "Pro Max" because it echoes a real brand's naming (rule 3) and has nothing to do with Greenbull. In its place is "Sponsored", the evaluator's suggestion: the effect becomes one more paid placement, which mocks brand obsession in Greenbull's own profit-minded way (rule 1). It now reads in sentence case like a plain label. "Sponsored" goes at the front because "Shockwave ring (sponsored)" is 26 characters, one over the limit. This version is 24 characters, under the 25 limit (rule 4), with no numbers, banned words or real brands.
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: No rule is clearly broken. Rule 1 (tone): "Sponsored" is a light, corporate-ad joke that fits Greenbull's voice and lets the name stay the effect it describes. Rule 3: it is a garage item, so Greenbull's voice is allowed, and it has no "Greenbull says" form and no real brand. Rule 4: 24 of 25 characters, so it is inside the limit. I could not read rule 2 (the vocabulary), only the script check, which passed. It loses points because the satire is thin and generic. "Sponsored" is a familiar social-media label and adds little that is specific to Greenbull, drifting or the stream. A sharper version would keep the effect recognisable and use a more pointed Greenbull-flavoured term, within 25 characters. That would also leave a little more room for the other cosmetics' names to use the same pattern.
- Rules broken: none

#### Round 4

- Version 4: "Brand reach shockwave"
- What changed: Version 4. I replaced the generic "Sponsored" with "Brand reach", a marketing term for how far a brand spreads. It turns the ring rippling out across the ground into the joke: the effect is Greenbull's reach spreading out, so it mocks brand obsession and corporate language in a way tied to this effect and the stream (rule 1). "Shockwave" keeps the effect recognisable. The name is 21 characters, under the 25 limit with more room than before, in sentence case, with no numbers, banned words or real brands (rules 2 to 4).
- Script checks: 3 of 3 pass
- Score: 6/10
- Reason: No rule is broken. It passes the script checks (rules 2, 3 and 4: 21 characters, within the 25 limit) and it keeps the vocabulary. Rule 1 (tone) is only partly met. "Brand reach" is a light corporate-marketing jab, so the Greenbull satire is there. But the brief asks for the name of a ring that ripples out on the ground. "Brand reach" hides the effect, and the two nouns "reach" and "shockwave" read as a clumsy stack. The name also stays vague about what the player is buying. To raise the score, keep a clear effect word such as "ring" or "ripple" and put the corporate spin around it, for example "Synergy ripple" or "Reach ring". Keep it at 25 characters or fewer, with no number.
- Rules broken: none

**Kept:** version 1, score 7/10 ("Premium Shockwave Ring", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/ring_n.txt`): still below 8 after 3 refines, so the task is flagged for the board's review.

### Run 18

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind garage_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/ring_d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A ring ripples out on the ground when you jump. Disruptive, like the brand."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is clearly broken. It passes the script checks (rules 2, 3 and 4: 75 characters, no number, no banned words, no "Greenbull says"). It says what the effect does first, then adds one aside. "Disruptive, like the brand" mocks corporate buzzwords in Greenbull's voice, which suits rules 1 and 3. Two weaknesses cost points. The aside is mild and generic, since "disruptive" is a stock buzzword and a sharper, more specific corporate or sponsor-obsessed joke would score higher under rule 1. It also reads slightly like a tagline about the brand, not about the car. To improve, keep the first sentence and swap the aside for a sharper joke, still within 80 characters and with no number.
- Rules broken: none
- Refused: {"tool_input": {"command": "sed -n '41p' /c/solid-carbide-worktrees/T-550/docs/extended-narrative.md", "description": "Show vocabulary rule line"}, "tool_name": "Bash", "tool_use_id": "toolu_01Ps76ZWX8c2RxBMvN5YAMqH"}

**Kept:** version 1, score 8/10 ("A ring ripples out on the ground when you jump. Disruptive, like the brand.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/ring_d.txt`): it reached 8 or more.

### Run 19

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/grule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "In the air, hold Space and touch a rail to grind along it. Let go of Space to launch the way you're facing."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['Space', 'Let', 'Space'])
- Score: 6/10
- Reason: Rule 4 (menu and settings labels: short and plain, sentence case, one line) is broken. The sentence-case script check fails: it flags 'Space' twice and 'Let'. 'Let' is the start of a second sentence, which the script counts as an extra capital. 'Space' is a key name, but the check treats it as a capital mid-sentence. The text is also two sentences, which is long for a one-line pause-screen rule. To fix it, make it one sentence with no capitals after the first word, for example: 'In the air, hold space and touch a rail to grind, then let go to launch the way you face.' Rules 1, 2 and 3 are fine: the text is plain, with no brand or banned words and no 'Greenbull says'. It is clear and accurate, and it matches the 'Hold reverse and steer...' example style.
- Rules broken: 4

#### Round 2

- Version 2: "In the air, hold space and touch a rail to grind along it, then let go to launch the way you face."
- What changed: Version 2 fixes the rule 4 script failures. The text is now one sentence with no capitals after the first word: "space" is lowercase and the second sentence is joined with "then let go". It is also shorter. The plain instruction style and the full mechanic stay the same: in the air, hold space, touch a rail to grind, release to launch the way you face.
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: No rule is clearly broken. The script checks pass: one line, sentence case, no banned words, no "Greenbull says" line. It is a plain instruction with no satire, which fits the brief's "plain instruction" example, and nothing in it breaks rule 1 or rule 3. Rule 4 asks labels to be "short and plain". At about 100 characters with three clauses (in the air, hold and touch, then let go), it is longer and denser than the example rule (~70 characters), and "launch the way you face" reads a little awkwardly. To fix: shorten it to two clauses, for example "In the air, hold Space on a rail to grind, then let go to launch forward." Also write the key name "Space" with a capital, the way a key is named.
- Rules broken: none

#### Round 3

- Version 3: "In the air, hold space on a rail to grind, then let go to launch forward."
- What changed: Version 3 is shorter, about 72 characters, close to the example rule's length. It has two clauses instead of three: "hold space and touch a rail to grind along it" became "hold space on a rail to grind". The awkward "the way you face" became "forward", which keeps the meaning that the car launches the way it faces. I did not take the suggestion to capitalise "Space": version 1 failed the rule 4 sentence-case script on that capital, so it stays lowercase to keep the script passing.
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No Text rule is broken. Rule 4 (menu and settings labels): it is one line, plain, in sentence case, and the script confirms it. Rules 2 and 3: no banned words, no "Greenbull says" line. Rule 1: it is a plain instruction, in line with the brief's example. Optional polish only: "hold space on a rail" is slightly ambiguous. "Hold space and touch a rail to grind" would match the mechanic more closely. "Launch forward" is fine for "in the direction it faces".
- Rules broken: none

**Kept:** version 3, score 9/10 ("In the air, hold space on a rail to grind, then let go to launch forward.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/grule.txt`): it reached 8 or more.

### Run 20

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/gbadge.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Touch rail"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rules 2, 3 and 4 pass: no banned words, no "Greenbull says" line, one line in sentence case, 1-2 words. It is plain and says what to do: touch a rail while in the air. It matches the 'Stand still' example. The tone rule (1) needs no joke for a keycap badge, and a neutral badge is fine. The score is not higher only because "Touch rail" is generic. It leaves out the airborne condition, but the GRIND! popup and the keycap context carry that. Optional tweak: 'Hit a rail' or 'Land on rail' if the writer wants the airborne part to show.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Touch rail", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/gbadge.txt`): it reached 8 or more.

### Run 21

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/gnote.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Touch a rail mid-air"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. It is exactly 20 characters, one line and sentence case (rule 4, label format). It has no banned words and no "Greenbull says" line (rules 2 and 3). It is plain and short like the brief's 'Slide backwards' example, and it states the mechanic (touch a rail in the air). It has no satirical edge, but a key hint note doesn't need one under rule 1. It sits at the 20-character limit, so any rewording must not grow.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Touch a rail mid-air", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/gnote.txt`): it reached 8 or more.

### Run 22

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/grule2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "In the air, hold Space and touch a rail to grind it. Let go of Space to launch the way you face."
- Script checks: 2 of 3 pass; failed: rule 4, card_desc: at most 90 characters (96 characters)
- Score: 6/10
- Reason: Rule 4 broken (script fact): the text is 96 characters, 6 over the 90-character card_desc limit. Fix by trimming at least 6 characters while keeping the order, e.g. "In the air, hold Space and touch a rail to grind. Let go of Space to launch ahead." or "In the air, hold Space on a rail to grind it. Release Space to launch forward." Rules 1 and 3 are fine: the text is plain, not Greenbull's voice and has no "Greenbull says" line. Rule 2 is fine: it has no banned words. It states what to do first, as the brief asks. It has no satirical aside, which the brief does not ask for, so that is not penalised.
- Rules broken: 4

#### Round 2

- Version 2: "In the air, hold Space and touch a rail to grind it. Let go to launch the way you face."
- What changed: Version 2 cuts the line from 96 to 87 characters, so it fits the 90-character card_desc limit (rule 4). I dropped the second "of Space", since "Let go" clearly means releasing the Space key held in the first sentence. Everything else stays the same: the action comes first and plainly, then the launch on release. It has no aside, no Greenbull voice and no banned words.
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is clearly broken. The script checks pass: no banned words, no "Greenbull says" line, and 87 characters against the 90 limit. Rule 4 asks a card description to say first what it does. This line does: it leads with the action (in the air, hold Space, touch a rail), then the release and launch. The rules allow "at most one" satirical aside, so having none is allowed. The brief asked for plain wording, and the line follows it. Rule 3 is fine: no Greenbull voice is used, and no brand is named. Rule 1 (tone) is only weakly served, because the line is neutral with no wit. That is acceptable for a mechanic rule. I could not see rule 2 (vocabulary) in the doc text I read, but nothing here looks off-vocabulary. To reach 9–10, add a short satirical aside only if the 90-character limit allows it. Currently 3 characters are free, so this is probably not worth doing.
- Rules broken: none

**Kept:** version 2, score 8/10 ("In the air, hold Space and touch a rail to grind it. Let go to launch the way you face.", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/grule2.txt`): it reached 8 or more.

### Run 23

Run by `tools/style_loop/run.py` on 2026-11-07: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/gbadge2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "HOLD SPACE"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['SPACE'])
- Score: 6/10
- Reason: Rule 4 (labels: sentence case) is broken. The text is stored as "HOLD SPACE", and the script flags "SPACE" as capitalised. The brief says the badge is shown in capitals, so the UI does the uppercasing. The stored text should be sentence case: "Hold space". The content is right: two words, one line, it names the key (holding Space), and it matches the note "Touch a rail mid-air". Rules 2 and 3 pass. Fix: write "Hold space".
- Rules broken: 4

#### Round 2

- Version 2: "Hold space"
- What changed: Version 2 saves the text in sentence case ("Hold space") to pass rule 4's sentence-case check for labels. The UI makes it capitals on screen, as the brief says, so the player still reads HOLD SPACE. The wording is the same two words as before. It names the key and the action and still pairs with the note "Touch a rail mid-air".
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: Passes all script checks. It is two words, plain and in sentence case, and it names the key as the brief asks. No banned words, no "Greenbull says" line, nothing unethical or off-tone. Rule 1 (tone): it is plain and has no satire, but a keycap badge is a functional label, and rule 4 asks for labels to be "short and plain". Small deductions: (a) the brief says the badge is shown in capitals, so "Hold space" will appear as "HOLD SPACE", which is fine for display. (b) "Hold" may suggest holding Space for the whole move, while the note says "Touch a rail mid-air". If the key is only held while touching the rail, "Hold space" is still accurate. No rule is broken.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Hold space", copied to `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/b/out/gbadge2.txt`): it reached 8 or more.

## Result notes

- 2026-11-07, in-progress → flagged-for-review: the style loop kept version 1 (score 7/10), still below 8 after 3 refines; every version is in its Style review

Done. Every text went through the style loop (rounds in Style review). Status note: the loop itself flagged the ticket (flagged-for-review) because effects.shockwave_ring.name stayed at 7 after 3 refines (kept for the playtest); the Project Lead should put the status back.

NEW (game/data/cosmetics_text.json unless noted; T-553 reads these):
- menu_button 'Cosmetics' (9): main menu button opening the submenu.
- title 'Cosmetics' (9): submenu title.
- locked 'Unlock for {price} coins' (8): locked item's label, {price} is coins.
- buy 'Unlock' (8): button that buys a locked item.
- pick 'Flex it' (8): button that picks an unlocked item.
- equipped 'Equipped' (8): label on the picked item.
- not_enough_coins 'Not enough coins: style isn't free.' (8): shown when the player can't pay.
- effects.<id>.name / .description, ids dash_cloud, spring, jet_thrust, stunt_sparks, shockwave_ring: Dash cloud (8) / A little puff of dust under every jump. Free, which Greenbull finds awkward. (9); Engagement Spring (8) / A spring pops the car into the air. Gravity's contract is under review. (9); Jet Thrust Zero Sugar (9) / A jet flame blasts under your car on every jump. Safety review pending. (9); Stunt sparks (8) / Sparks burst under the car on every jump. Greenbull calls it content. (9); Premium Shockwave Ring (7, below 8, for the playtest) / A ring ripples out on the ground when you jump. Disruptive, like the brand. (8). Names <=25, descriptions <=80, no numbers.
- game/data/pause_text.json key jump_arrow_label 'Facing arrow' (9): pause screen checkbox for the jump arrow, next to Drift Guide.

CHANGED (game/data/tutorial_text.json): trick_rule.rail_grind -> 'In the air, hold Space and touch a rail to grind it. Let go to launch the way you face.' (8; was 'Jump or drop onto a rail and grind along it.'); trick_recipe.rail_grind.step1_badge -> 'Hold space' (8, shown in capitals; was 'On a rail'); step1_note -> 'Touch a rail mid-air' (9; was 'Jump or drop on'). Also game/tests/unit/test_trick_list_recipes.gd updated to match; screen_texts.json descriptions_comment now says 'the burst's cooldown_seconds' (it was a comment). Unchanged and still true: Jump card 'Press Space to Jump.' / '...higher.', GRIND! popup, recap/tutorial trick names; no mission or gift pack text mentions grinding or a Jump cooldown.
FOR T-552: game/data/power_ups.json still has cooldown_seconds on Jump tiers 1 and 2 (data, not text); that is the only 'cooldown' near Jump left in game/data.
Docs: docs/hud-and-menus.md (new Content section, GRIND! lines fixed), docs/garage-design.md (new Content section).
Tests: new game/tests/unit/test_cosmetics_text.gd (3 tests) plus test_trick_list_recipes, test_trick_list, test_tutorial_clips pass; full run left to QA.
- 2026-11-07, flagged-for-review → in-progress: Project Lead: the one text below 8 (Premium Shockwave Ring, 7) is noted for the board's playtest, as the criteria allow.

QA round 1 fixes: (1) game/tools/text_inventory.py now lists cosmetics_text.json ('Cosmetics menu (not in the game yet)'). (2) Full runs on the branch: GUT 255 scripts, 2920 tests, 2919 passing, 0 failing, 1 risky/pending; python game/tools 1020 tests OK (4 skipped); python tools 639 tests OK. (3) Screenshots in art-archive/T-550/screenshots/: trick_list.png (the pause trick list) and trick_list_grind.png (GRIND! selected: the new rule text, badge HOLD SPACE and the note; the note wraps to two lines at 'mid-air' in the current layout, a UI matter). The tutorial slides do not show the grind rule (slide 2 shows no trick list), so the trick list is the only place it appears today. The new menu texts (Cosmetics button, submenu labels, effect names, Facing arrow checkbox) are shown by T-553, so no screenshots of them here.

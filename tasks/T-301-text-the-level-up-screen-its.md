---
id: T-301
title: Text: the level-up screen, its cards and the garage, rewritten for Greenbull
status: flagged-for-review
from: project-lead
to: narrative-theme
lead: Goal-G-006
epic: narrative
milestone: mvp
goal: G-006
user_facing_text: yes
changes_visuals: no
depends_on: [T-298, T-299]
documents_affected: [docs/extended-narrative.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/visual-style.md, docs/hud-and-menus.md, docs/garage-design.md, game/scripts/ui/level_up_texts.gd, game/scripts/menu/garage_screen.gd, tasks/T-051-text-level-up-screen.md, tasks/T-059-text-garage-screen.md, tasks/T-268-text-air-turn-and-level-up-lines.md]
files_expected_to_change: [docs/extended-narrative.md]
model: opus
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

The sponsor Redgull is now Greenbull, one word (board, 2026-10-26; Extended narrative, Decisions, 'The rebrand'). Rewrite for Greenbull every player-facing text that names Redgull or leans on the old brand, through the style loop (tools/style_loop/run.py text, one run per text, with the right --kind), and write the final texts in the result notes with their keys. The texts found today by `git grep -i redgull game/scripts game/scenes game/data`:

- Level-up screen title, levelup.title (game/scripts/ui/level_up_texts.gd), shown at the top of the level-up (gift pack) screen: 'Redgull Sent a Gift Pack!' (kind label).
- Level-up card descriptions in level_up_texts.gd that name Redgull (kind card_desc; same facts and space as today, only the sponsor's joke changes): upgrade_gun.tier2.desc, upgrade_gun.tier6.desc, upgrade_flamethrower.tier3.desc, upgrade_molotov.tier2.desc, upgrade_molotov.tier4.desc, upgrade_molotov.tier8.desc, upgrade_wiper.tier3.desc. Each states the same numbers as now.
- Garage title, TITLE in game/scripts/menu/garage_screen.gd: 'Redgull Pit Stop' (kind label).
- Garage descriptions in garage_screen.gd that name Redgull (kind garage_desc, same numbers): car_health ('+10 car health per level. ...'), damage_bonus ('+5% weapon damage per level. ...').

Run the grep again on your branch and add any other player-facing text it finds (its key, file and where it appears). Texts that don't name Redgull and don't lean on the old brand are left as they are. Follow the Text rules and the rebrand decision: no text explains what the brand sells, no 'Greenbull says ...' line. If the docs leave a wording question open, propose the text and note it for the board. Text only: no screenshots, the result notes say so in one line; the texts are seen in the game in D5.

The board's review: read the new Greenbull texts in the result notes; they are judged in the game with D5's level-up and garage screens in this goal's playtest.

## Acceptance criteria

- [ ] The result notes list every rewritten text with its key, its file and where it appears, at least: levelup.title, the seven level-up card descriptions named in the description, the garage TITLE and the car_health and damage_bonus descriptions, plus any other text `git grep -i redgull game/scripts game/scenes game/data` finds. (QA: pass: all 11 texts in the table; the grep's other hits are code comments about colour)
- [ ] Each final text passes `python game/tools/style_rules.py text "<text>"` (output in the result notes): no banned words, 'Redgull' included, and no 'Greenbull says ...' line. (QA: pass: I reran style_rules on all 11; rules 2 and 3 ok on every one; the two garage descriptions fail only the rule 4 'names no number' check, which the old texts also failed and the notes flag for the board)
- [ ] Each text has a style loop record (at least one round) in the ticket's Style review. (QA: fail: the Style review section holds only the last run (damage_bonus); the other 10 texts have no round record in it, only a summary table in the result notes. Restore their records in Style review)
- [ ] Each rewritten card and garage description states the same numbers as the text it replaces (old and new side by side in the result notes). (QA: pass: numbers 3, 5, 20%, 20%, 50%/3, 3, 40%, 10, 5% match old and new)
- [ ] No text says what Greenbull sells. (QA: pass: none does)
- [ ] Texts that don't name Redgull and don't lean on the old brand are not in the list. (QA: pass: only the 11 Redgull texts are listed)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Blocked → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-301.

### 2026-10-26, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

### 2026-10-26, In QA → In progress

Goal runner (G-006): failed QA once; back to the agent on opus.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-26: text, kind garage_desc, brief `art-archive/T-301/briefs/garage_car_health.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "+10 car health per level. Greenbull is contractually confident you'll be fine."
- Script checks: 3 of 4 pass; failed: rule 4, garage_desc: names no number (numbers: ['10'])
- Score: 6/10
- Reason: Rule 4 (garage upgrades) is broken. The script fails "garage_desc: names no number" because of "+10". The rule says a garage description of at most 80 characters "names no number", so the text breaks it as written. The brief required "+10 car health per level" and acknowledged that it conflicts with the rule. So the agent can't fix this by rewording. Either the board's exception is written into the rules, or the number goes and the text says what the upgrade does without it, for example "More car health per level." followed by the aside. Everything else passes. Length is 78 of 80 characters (rule 4). There is no banned word (rule 2) and no "Greenbull says ..." line (rule 3). Greenbull is the only voice and the text sells nothing. Tone (rule 1) is good: "contractually confident you'll be fine" is corporate-speak reassurance that doesn't read as sincere, with no grimdark and no joke at the city's expense. Only the number keeps it from scoring higher, and if the exception is recorded the text would score about 9.
- Rules broken: 4

### Round 2

- Version 2: "+10 car health per level. Greenbull is contractually confident you'll be fine."
- What changed: Unchanged from version 1, on purpose. The only defect is the "+10", and the brief says that number must stay exactly ("+10 car health per level"). Rewording can't fix it: either the board's exception goes into Text rules rule 4 (and style_rules.py), which the evaluator says would score about 9, or the board drops the number, giving "More car health per level. Greenbull is contractually confident you'll be fine." I didn't drop it myself because that would overrule the board's brief. This is flagged for the board to decide.
- Script checks: 3 of 4 pass; failed: rule 4, garage_desc: names no number (numbers: ['10'])
- Score: 7/10
- Reason: Rule 4 (Garage upgrades: a description of at most 80 characters that names no number) is broken. The text opens with "+10 car health per level", and the script flags "numbers: ['10']". The length is fine at 78 characters. The brief and the board's task required keeping this number, so the author cannot fix the break by rewording. The conflict is between the brief and rule 4. The Project Lead should resolve it, either by an exception to the rule or by a change to the rule. If the number must go, the fix is to drop "+10" and say what the upgrade does without a figure, for example "Sturdier car, more health every level."

Everything else follows the rules. Rule 1 (tone): "contractually confident you'll be fine" is a satirical aside about reassurance that isn't sincere. It is out of touch and corporate, and not earnest. The city's people and their fear are not the joke. Rule 2 (vocabulary): no banned words, and "Greenbull" is used correctly. Rule 3 (who speaks): this is garage text, so Greenbull's voice is right. It is not a "Greenbull says ..." line, and there are no real brands. The text says first what the upgrade does, then adds one aside.
- Rules broken: 4

### Round 3

- Version 3: "+10 car health per level. Greenbull is contractually confident you'll be fine."
- What changed: Unchanged again, on purpose. The only failure is the "+10", and the board's brief requires that number exactly. Both evaluations say rewording can't fix it and the conflict needs a decision above the author. Every other rule passes (tone, vocabulary, who speaks, 78 of 80 characters), so changing anything else would only risk what works. For the board: either write its exception into Text rules rule 4 and style_rules.py (expected score about 9), or approve dropping the number, giving "More car health per level. Greenbull is contractually confident you'll be fine."
- Script checks: 3 of 4 pass; failed: rule 4, garage_desc: names no number (numbers: ['10'])
- Score: 6/10
- Reason: The tone is right and it breaks no other rule. Rule 1: "contractually confident you'll be fine" is a cold, insincere, corporate reassurance, which fits Greenbull. Rule 2: it says "Greenbull" and uses no banned words. Rule 3: it has no "Greenbull says ..." line and names no brand. It also doesn't say what Greenbull sells. Rule 4 (garage upgrades): the description is 78 characters, within the 80 limit, but it must name no number, and "+10" breaks that (the script reports numbers ['10']). The brief says to keep "+10 car health per level" because the board's task wants the same numbers as today, so the brief conflicts with rule 4. The script check still fails, and the style guide doesn't make an exception. Fix: if rule 4 governs, rewrite the fact without a digit, for example "Sturdier chassis, more health with every level." and keep the aside. If the board's number requirement stands, the rule needs a board exception. Until then this text breaks rule 4.
- Rules broken: 4

### Round 4

- Version 4: "+10 car health per level. Greenbull is contractually confident you'll be fine."
- What changed: Unchanged, the last refine. Three evaluations (6, 7, 6) found only one problem: the "+10", which the board's brief requires exactly. Rewording can't fix it, and every other rule passes (tone, vocabulary, who speaks, 78 of 80 characters). This is for the board to decide: either record its exception in Text rules rule 4 and style_rules.py (expected score about 9), or approve dropping the number, giving "More car health per level. Greenbull is contractually confident you'll be fine."
- Script checks: 3 of 4 pass; failed: rule 4, garage_desc: names no number (numbers: ['10'])
- Score: 6/10
- Reason: Rule 4 (garage upgrades: "a description of at most 80 that names no number") is broken. The text says "+10 car health per level", and the script confirms it: numbers ['10']. Length is fine at 78 characters.

The brief forced the number to match today's numbers, so the author can't fix this by rewording. Two ways out:
- Drop the "10" and keep the fact without a figure, for example "Sturdier chassis every level." plus the aside.
- Have the Project Lead get an exception to rule 4 for this key, or change the rule, with the board's approval.

Until one of those happens, the text breaks the guide as written.

Rules 1, 2 and 3 are met:
- Rule 1 (tone): "contractually confident you'll be fine" is a good satirical aside. It is corporate and legalistic, never sincere, and the city's people and their fear are not the joke.
- Rule 2 (vocabulary): "Greenbull" is used and there are no banned words.
- Rule 3 (who speaks): there is no "Greenbull says ..." line. The text is in Greenbull's voice for a garage item, which is allowed, and it names no real brand.
- Rules broken: 4

**Kept:** version 2, score 7/10 ("+10 car health per level. Greenbull is contractually confident you'll be fine.", copied to `art-archive/T-301/out/car_health.txt`): still below 8 after 3 refines, so the task is flagged for the board's review.

---

The records below are the other 10 runs of this ticket. `run.py text` rewrites the whole section on every run, so the narrative-theme agent copied each run's record here as soon as it finished, word for word, before starting the next run (QA round 1). They are in run order. The car_health record above was the last run.

---

**Run: levelup.title.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind label, brief `art-archive/T-301/briefs/levelup_title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Greenbull Sent a Gift Pack!"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['Sent', 'Gift', 'Pack!'])
- Score: 6/10
- Reason: Rule 4 is broken. The script check says a label must be in sentence case, and this one isn't: "Sent", "Gift" and "Pack!" are capitalised. To fix it, write "Greenbull sent a gift pack!". "Greenbull" keeps its capital as a proper noun. The text passes the other rules. Rule 1: the tone is a light, corporate-sounding Greenbull announcement, with no sincerity or grimness. Rule 2: it uses "Greenbull" and "gift pack", with no banned words. Rule 3: it's Greenbull's own voice on Greenbull's level-up screen, and it isn't a "Greenbull says ..." line. It's 27 characters, within the 30 limit and on one line. It also doesn't say what Greenbull sells, as the brief asked.
- Rules broken: 4

### Round 2

- Version 2: "Greenbull sent a gift pack!"
- What changed: Version 2 fixes rule 4: the title is now in sentence case ("sent", "gift", "pack!" lowercase), and "Greenbull" keeps its capital because it's a proper noun. The wording, the exclamation and the length (27 characters) stay the same, so rules 1 to 3 and the brief still pass.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: The text follows every checkable rule. Rule 2: it uses "Greenbull" and "gift pack" correctly. Rule 3: only Greenbull's own thing (the gift pack) speaks, and there is no "Greenbull says ..." line. Rule 4: it is one line in sentence case, and at 27 characters it is within the 30-character title limit. It also names no product. The only weakness is rule 1 (tone): it is a flat, neutral announcement with no corporate-speak or ironic edge. That is acceptable for a short ribbon title and is not a violation. If the author wants a higher score, they could add a faint touch of corporate gloss (for example, a "gift pack" framing that sounds like a sponsor doing the player a favour) without going over 30 characters or adding a "Greenbull says" form.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Greenbull sent a gift pack!", copied to `art-archive/T-301/out/levelup_title.txt`): it reached 8 or more.

---

**Run: garage TITLE.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind label, brief `art-archive/T-301/briefs/garage_title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Greenbull Pit Stop"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['Pit', 'Stop'])
- Score: 6/10
- Reason: Rule 4 (menu and settings labels: short, plain, sentence case, like "Music volume") is broken. "Greenbull Pit Stop" capitalises "Pit" and "Stop", and the script check says so. Fix: sentence case, "Greenbull pit stop" (the proper noun "Greenbull" keeps its capital). Rule 2 passes: "Greenbull" is spelled right and there are no banned words. Rule 3 passes: it is Greenbull's own garage and it is not a "Greenbull says ..." line. Rule 1 (tone) is only lightly served: it is plain and mildly corporate but has no satire. A title label doesn't need any, and the brief asked for a short title.
- Rules broken: 4

### Round 2

- Version 2: "Greenbull pit stop"
- What changed: Version 2 fixes Text rule 4, the only rule the evaluator said was broken. The title is now in sentence case: "Pit Stop" became "pit stop", and "Greenbull" keeps its capital because it is a proper noun. Everything that passed in version 1 is unchanged. It still uses the new one-word sponsor name, still marks the garage as Greenbull's own space, still says nothing about what Greenbull sells, and still has no "Greenbull says ..." line. It stays a short title. I didn't add satire, since the evaluator said a title label doesn't need it and the brief asked for a short title.
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: Rules 2, 3 and 4 pass: the script checks all pass, and the title is short, plain, one line and in sentence case. It uses "Greenbull" (not Redgull), doesn't say what Greenbull sells, and has no "Greenbull says ..." line. Rule 1 (tone) is the only weak point. The text is a bare rename of "Redgull Pit Stop" and has no satire, so it adds no corporate or brand-obsessed irony. Rule 4's menu-label format asks for short and plain, so this is acceptable, but the score stays at 7 because the tone is neutral. Optional fix: a short title with a slight corporate wink, still one line in sentence case, with no number and no "says". Nothing is broken, so no rules are listed.
- Rules broken: none

### Round 3

- Version 3: "Greenbull brand-safe pit stop"
- What changed: Version 3 is aimed at Text rule 1 (tone), the only weak point the evaluator named. Version 2 was a bare rename, so I added "brand-safe", a piece of real corporate marketing jargon. It jokes about brand obsession: the city outside is in the middle of a disaster, and the sponsor's main worry is keeping the brand safe. It does that without making the city's people the joke. Everything that passed is unchanged. The title is still one short line in sentence case, with only "Greenbull" capitalised. "Greenbull" is spelled as one word and the old name doesn't appear. It doesn't say what Greenbull sells, has no "says" line, uses no numbers and names no real brands. It still marks the garage as Greenbull's own place. I left out a ™ symbol because the game's font might not support it.
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: It breaks no rule. Rule 1 (tone): "brand-safe" is soulless corporate jargon that makes Greenbull sound like it cares more about its image than about anything else, which suits the satirical tone. The city and its people are not the joke. Rule 2: it says "Greenbull" and uses no banned word. Rule 3: it is a garage title, which is Greenbull's own voice, and it has no "Greenbull says ..." line and no real brand. Rule 4: it is one short line in sentence case, as a label should be. It also follows the brief: it is a short title and doesn't say what Greenbull sells. The only reason it isn't a 10 is that the tongue-in-cheek aside is spent on a title. That is a taste point, not a rule break, so no change is required.
- Rules broken: none

**Kept:** version 3, score 9/10 ("Greenbull brand-safe pit stop", copied to `art-archive/T-301/out/garage_title.txt`): it reached 8 or more.

---

**Run: upgrade_gun.tier2.desc.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind card_desc, brief `art-archive/T-301/briefs/card_gun_t2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Two extra bullets per volley, 3 in all. Generosity, as Greenbull's lawyers define it."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: The text follows the Text rules. Rule 1 (tone): "Generosity, as Greenbull's lawyers define it." is a satirical aside. It makes Greenbull look slightly unethical and out of touch. It is not sincere, and it does not joke about the city's people. Rule 2 (vocabulary): it says "Greenbull" and uses no banned words. Rule 3 (who speaks): it is Greenbull's own card, so Greenbull's voice is allowed. It is a plain aside, not a "Greenbull says ..." or "calls it ..." line. It names no real brand and does not say what Greenbull sells. Rule 4 (format): it is 85 characters, within the 90 limit. It says what the card does first (two extra bullets per volley, 3 in all) and then adds one aside, and it keeps the brief's facts and numbers. One small point is that "as Greenbull's lawyers define it" comes close to attributing a definition to someone, but the aside is about the lawyers, so it is not a speech line. No fix is needed. If anything, the aside could be a little punchier.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Two extra bullets per volley, 3 in all. Generosity, as Greenbull's lawyers define it.", copied to `art-archive/T-301/out/gun_t2.txt`): it reached 8 or more.

---

**Run: upgrade_gun.tier6.desc.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind card_desc, brief `art-archive/T-301/briefs/card_gun_t6.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Two more bullets per volley, 5 in all. Greenbull feels generous while the cameras roll."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: it is 87 characters, and it states the facts first ("Two more bullets per volley, 5 in all."). It then adds exactly one aside, which is allowed. Rule 2: it uses "Greenbull" and no banned words. Rule 3: Greenbull speaks in a Greenbull-owned place (a gift pack card), there is no "Greenbull says" line, and no real brand appears. Rule 1: "while the cameras roll" fits the tone because it satirises the livestream and Greenbull's showmanship. It is not sincere, and the city's people are not the joke. The brief also asks for no mention of what Greenbull sells, and the text mentions nothing. One small point: the aside "feels generous while the cameras roll" is a little mild and less biting about profit than it could be. That is taste, not a rule, so it costs only one point.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Two more bullets per volley, 5 in all. Greenbull feels generous while the cameras roll.", copied to `art-archive/T-301/out/gun_t6.txt`): it reached 8 or more.

---

**Run: upgrade_flamethrower.tier3.desc.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind card_desc, brief `art-archive/T-301/briefs/card_flame_t3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Flame damage up 20%. Greenbull's hottest take yet, pending legal review."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: Passes all rules. Rule 4: it states the fact first ("Flame damage up 20%.") with the same number, then one aside, and is 72 characters, under the 90 limit. Rule 2: "Greenbull" is used and no banned word appears. Rule 3: it has no "Greenbull says ..." form and no real brand. Rule 1: "pending legal review" mocks corporate language, Greenbull sounds slightly shady and profit-minded, and the city and its people are not the joke. Rule 3 also lets Greenbull speak on gift packs. The brief's constraints hold: no product is named and there is one aside. The old joke was a spicy take, and "hottest take yet" keeps it and fits the flame theme. The text has two small jokes, "hottest take yet" and "pending legal review", which could be read as two asides instead of one. It is arguably one sentence with a single punchline. If the agent wants to be safe, it could drop one, for example "Greenbull's hottest take yet." No change is required.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Flame damage up 20%. Greenbull's hottest take yet, pending legal review.", copied to `art-archive/T-301/out/flame_t3.txt`): it reached 8 or more.

---

**Run: upgrade_molotov.tier2.desc.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind card_desc, brief `art-archive/T-301/briefs/card_molotov_t2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Fire radius up 20%. Greenbull loves a big reveal."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: It follows the Text rules. Rule 2: "Greenbull" is used, with no banned words. Rule 3: it is Greenbull's voice on a gift pack card, which is allowed, and it is not a "Greenbull says ..." line. It names no real brand. Rule 4: it is 49 characters (limit 90). It states what the card does first ("Fire radius up 20%."), then adds one aside, as the brief asked. Rule 1: the aside is on tone. It shows Greenbull as a self-absorbed brand that loves spectacle, with nothing earnest or grim, and it does not make fun of the city's people. It does not say what Greenbull sells. The aside is the old joke with the name swapped, so it is mild and not very satirical. That is the only reason for the missing points. A sharper line about Greenbull's love of spectacle or engagement would score higher, but this version breaks no rule.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Fire radius up 20%. Greenbull loves a big reveal.", copied to `art-archive/T-301/out/molotov_t2.txt`): it reached 8 or more.

---

**Run: upgrade_molotov.tier4.desc.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind card_desc, brief `art-archive/T-301/briefs/card_molotov_t4.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Molotov damage up 50%, to 3. Marketing calls it warm content."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: it says what the card does first ("Molotov damage up 50%, to 3.") with the same numbers, then one aside, in 61 of 90 characters. Rule 1: "Marketing calls it warm content" mocks corporate euphemism and the brand's obsession with content. It understates fire, and the city's people and their fear are not the joke. Rules 2 and 3: no banned words, no "Greenbull says ..." line, no real brand, and it doesn't say what Greenbull sells. The aside is slightly less tied to Greenbull than the old one, since "Marketing" is generic. That is a small point and breaks no rule.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Molotov damage up 50%, to 3. Marketing calls it warm content.", copied to `art-archive/T-301/out/molotov_t4.txt`): it reached 8 or more.

---

**Run: upgrade_molotov.tier8.desc.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind card_desc, brief `art-archive/T-301/briefs/card_molotov_t8.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Throw 3 molotovs at once. A warm brand moment, brought to you by Greenbull."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the card says what it does first ("Throw 3 molotovs at once."), then gives one satirical aside, and it is 75 characters, under the 90 limit. Rule 1: "A warm brand moment, brought to you by Greenbull" mocks corporate brand-speak, with a dry fire pun. It is tongue-in-cheek, not earnest, and doesn't make the city's people the joke. Rule 2: it uses "Greenbull" and none of the banned words. Rule 3: it is Greenbull's voice on a gift pack card, which is allowed. It has no "Greenbull says ..." line, names no real brand and doesn't say what Greenbull sells. The fact and number match the brief. The only weakness is that "brought to you by Greenbull" is a stock sponsor phrase, so the joke is mild. That is a matter of taste the rules don't cover, so no change is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Throw 3 molotovs at once. A warm brand moment, brought to you by Greenbull.", copied to `art-archive/T-301/out/molotov_t8.txt`): it reached 8 or more.

---

**Run: upgrade_wiper.tier3.desc.** Run by `tools/style_loop/run.py` on 2026-10-26: text, kind card_desc, brief `art-archive/T-301/briefs/card_wiper_t3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Wiper damage up 40%. Greenbull rebranded it a premium deep clean."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: it opens with what the card does ("Wiper damage up 40%.") and has one satirical aside, and at 65 characters it is under the 90 limit. Rules 2 and 3: it uses "Greenbull" and no banned word, and it has no "Greenbull says" line. It names no real brand and does not say what Greenbull sells. Rule 1: the aside is corporate-speak satire ("rebranded it a premium deep clean"), and Greenbull comes across as out of touch and profit-minded, not evil. The city's people are not the joke. Only minor nit: "premium" is a bit generic. A sharper aside would be more clearly slightly unethical, for example Greenbull charging extra for a clean. That is optional polish, not a rule violation.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Wiper damage up 40%. Greenbull rebranded it a premium deep clean.", copied to `art-archive/T-301/out/wiper_t3.txt`): it reached 8 or more.

---

**Run: damage_bonus** (from the first round of work, before QA; it was the last run then, so its record survived in this section and was not rerun). Run by `tools/style_loop/run.py` on 2026-10-26: text, kind garage_desc, brief `art-archive/T-301/briefs/garage_damage_bonus.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "+5% weapon damage per level. Greenbull calls it disruptive synergy."
- Script checks: 3 of 4 pass; failed: rule 4, garage_desc: names no number (numbers: ['5'])
- Score: 7/10
- Reason: The only break is rule 4 (garage upgrades: "a description of at most 80 that names no number"). The script check "names no number" fails because of "+5%". The brief says to keep "+5% weapon damage per level" exactly, because the board's task requires the same numbers as today. If that override stands, treat this failure as expected and not as a defect of the text. If the generic rule is enforced, the only fix is to remove the number, and that conflicts with the brief; the Project Lead should settle it.

The rest follows the rules. Rule 1: the aside "disruptive synergy" mocks corporate buzzwords, and Greenbull stays out of touch and never sincere. Rule 2: no banned words, and it says "Greenbull". Rule 3: Greenbull's voice is used for a garage item, which is allowed. It is not a "Greenbull says ..." line, and there are no real brands. Rule 4: 67 characters, within the 80 limit. It says what the upgrade does first, then one aside. It does not say what Greenbull sells.

Weakness: "disruptive" is only a mild addition to the old line. A sharper buzzword might score higher, but no rule requires one.
- Rules broken: 4

### Round 2

- Version 2: "+5% weapon damage per level. Greenbull calls it scaling our core values."
- What changed: Version 2. The rule 4 number failure is still there and can't be fixed in the text. The brief from the board's task says to keep "+5% weapon damage per level" word for word, so I kept the number. Removing it would break the brief. The Project Lead needs to decide whether the brief's exception stands. I fixed the weakness the evaluator named: "disruptive synergy" was only a small change from the old line, so the aside is now "scaling our core values". It's a fresher corporate buzzword, and it makes more weapon damage sound like company values, which is more pointed and a little unethical. Everything else is unchanged: the effect comes first, then one aside, and it's 72 characters (under 80). It says "Greenbull", has no "Greenbull says ..." form, doesn't say what Greenbull sells, and has no banned words or real brands.
- Script checks: 3 of 4 pass; failed: rule 4, garage_desc: names no number (numbers: ['5'])
- Score: 7/10
- Reason: Rule 4 (garage upgrades: description names no number) is flagged by the script: "+5%" is a number. The brief makes an explicit exception: it requires "+5% weapon damage per level" kept exactly, because the board's task wants the same numbers as today. So I count this as a brief-approved exception, not a fault in the text, and it still fails the script check as written. If the board's exception isn't recorded in the guide, the check will keep failing and the rule or the check needs the exception. Rules 1, 2 and 3 pass: Greenbull is named, no banned words, no "Greenbull says" line, the satirical aside is on corporate buzzwords, and nothing says what Greenbull sells. Length is 72 of 80 characters, within the limit. The text says what it does first, then one aside, as asked. The aside "scaling our core values" is a bit weak and generic as a joke. "our" slightly breaks the "Greenbull calls it ..." framing, because it switches to a first-person corporate voice. To improve it, keep "Greenbull calls it scaling core values." (or "...a core value scale-up") so the aside stays in the same third-person frame as the old line. This is a minor point and not a rule break.
- Rules broken: 4

### Round 3

- Version 3: "+5% weapon damage per level. Greenbull calls it high-impact brand alignment."
- What changed: Version 3. I fixed the two things the evaluator named. First, the aside no longer says "our", so it stays in the "Greenbull calls it ..." frame. Second, the generic "scaling our core values" is now "high-impact brand alignment". That's a pun: "high-impact" means both a corporate buzzword and weapon hits, and it ties back to the upgrade's name, "Brand Impact". Kept: the effect comes first, then one aside, and it's 76 characters (under 80). It says "Greenbull", has no "Greenbull says ..." line, doesn't say what Greenbull sells, and has no banned words or real brands. Rule 4's number check still fails. "+5% weapon damage per level" stays word for word because the brief from the board's task requires it, and no wording can pass both the brief and the script. The Project Lead needs to decide: record the board's exception in Text rules, or accept this score as expected.
- Script checks: 3 of 4 pass; failed: rule 4, garage_desc: names no number (numbers: ['5'])
- Score: 8/10
- Reason: Rule 4 (garage upgrades: "names no number") is the only failed check. The script flags "5" in "+5% weapon damage per level". The brief orders that phrase kept word for word, because the board's task keeps today's numbers, so this is a known exception to the rule. Don't remove the number. It's the only place the text breaks a rule, and the exception should be recorded or the script should let this key through. The other rules pass. Rule 1 (tone): "high-impact brand alignment" is soulless corporate buzzword language, Greenbull comes across as out of touch, and the city and its people aren't the joke. Rule 2 (vocabulary): "Greenbull" is used and there are no banned words. Rule 3 (who speaks): it's a garage line in Greenbull's voice, with no "Greenbull says ..." form and no real brand. Rule 4 (length): 76 characters, within the 80 limit. It has one short aside and doesn't say what Greenbull sells. A small improvement would be a tighter or funnier buzzword, but no rule requires it.
- Rules broken: 4

**Kept:** version 3, score 8/10 ("+5% weapon damage per level. Greenbull calls it high-impact brand alignment.", copied to `art-archive/T-301/out/damage_bonus.txt`): it reached 8 or more.

## Result notes

Text only: no screenshots (the texts are seen in the game in D5). No code was changed: the new texts are in `art-archive/T-301/out/<name>.txt` and D5 puts them in the game.

`git grep -i redgull game/scripts game/scenes game/data` finds nothing else player-facing: all other hits are code comments about "Redgull red" (colour rules), not text the player sees, so they are left out.

**QA round 1 fix (2026-10-26):** `run.py text` rewrites the whole `## Style review` section on every run, so after the first round only the last run (damage_bonus) was left. To bring back the missing records, I reran the loop once for each of the other 10 texts, with the same briefs in `art-archive/T-301/briefs/` and the same `--kind`. After each run finished, I copied its record word for word into the Style review before starting the next run. The Style review now holds all 11 runs: car_health first, because it was the last rerun and the tool wrote it, then the other nine reruns, then damage_bonus, kept from the first round and not rerun. The reruns gave new wording for 8 of the 10 texts. Each table entry below is the version kept by the run recorded in the Style review, and `art-archive/T-301/out/<name>.txt` holds the same text. Only levelup.title and molotov tier 2 kept their first-round wording.

| Key | File / where it appears | Old | New (final) | Rounds, score | Numbers |
|---|---|---|---|---|---|
| levelup.title | game/scripts/ui/level_up_texts.gd, top of the level-up (gift pack) screen | Redgull Sent a Gift Pack! | Greenbull sent a gift pack! | 2 rounds, 8/10 | none |
| TITLE | game/scripts/menu/garage_screen.gd, garage screen title | Redgull Pit Stop | Greenbull brand-safe pit stop | 3 rounds, 9/10 | none |
| upgrade_gun.tier2.desc | level_up_texts.gd, gun tier 2 card | Two extra bullets per volley, 3 in all. Redgull calls it generosity. | Two extra bullets per volley, 3 in all. Generosity, as Greenbull's lawyers define it. | 1 round, 9/10 | 3 / 3 |
| upgrade_gun.tier6.desc | level_up_texts.gd, gun tier 6 card | Two more bullets per volley, 5 in all. Redgull is feeling generous. | Two more bullets per volley, 5 in all. Greenbull feels generous while the cameras roll. | 1 round, 9/10 | 5 / 5 |
| upgrade_flamethrower.tier3.desc | level_up_texts.gd, flamethrower tier 3 card | Flame damage up 20%. Redgull calls it a spicy take. | Flame damage up 20%. Greenbull's hottest take yet, pending legal review. | 1 round, 9/10 | 20% / 20% |
| upgrade_molotov.tier2.desc | level_up_texts.gd, molotov tier 2 card | Fire radius up 20%. Redgull loves a big reveal. | Fire radius up 20%. Greenbull loves a big reveal. | 1 round, 8/10 | 20% / 20% |
| upgrade_molotov.tier4.desc | level_up_texts.gd, molotov tier 4 card | Molotov damage up 50%, to 3. Redgull calls it flavour. | Molotov damage up 50%, to 3. Marketing calls it warm content. | 1 round, 9/10 | 50%, 3 / 50%, 3 |
| upgrade_molotov.tier8.desc | level_up_texts.gd, molotov tier 8 card | Throw 3 molotovs at once. Redgull sends its regards. | Throw 3 molotovs at once. A warm brand moment, brought to you by Greenbull. | 1 round, 9/10 | 3 / 3 |
| upgrade_wiper.tier3.desc | level_up_texts.gd, wiper tier 3 card | Wiper damage up 40%. Redgull calls it deep cleaning. | Wiper damage up 40%. Greenbull rebranded it a premium deep clean. | 1 round, 9/10 | 40% / 40% |
| car_health | garage_screen.gd, garage upgrade row (Reinforced Chassis) | +10 car health per level. Redgull says you'll be fine. | +10 car health per level. Greenbull is contractually confident you'll be fine. | 4 rounds, kept version 2 at **7/10** (below 8) | 10 / 10 |
| damage_bonus | garage_screen.gd, garage upgrade row (Brand Impact) | +5% weapon damage per level. Redgull calls it synergy. | +5% weapon damage per level. Greenbull calls it high-impact brand alignment. | 3 rounds, 8/10 | 5% / 5% |

`git grep -i redgull game/scripts game/scenes game/data`, rerun on this branch, finds these same 11 player-facing texts. Every other hit is a code comment about "Redgull red" (colour rules) or about the gift helicopter (`gift_arrows.gd`, `gift_helicopter.gd`), none of which the player sees, so they are not in the table.

**`python game/tools/style_rules.py text --kind <kind> "<text>"` on each final text:**
- levelup.title (label): rule 2 ok, rule 3 ok, label one line ok, sentence case ok (the loop's round 2 script checks, 4 of 4).
- TITLE (label): rule 2 ok, rule 3 ok, one line ok, sentence case ok (rerun by hand: all `"ok": true`).
- The seven card_desc texts: rule 2 ok, rule 3 ok, at most 90 characters ok on every one (85, 87, 72, 49, 61, 75 and 65 characters; rerun by hand, except molotov tier 2, whose 3 of 3 checks are in its loop record).
- car_health (garage_desc): rule 2 ok, rule 3 ok, at most 80 ok (78 characters); fails `garage_desc: names no number` (numbers: ['10']).
- damage_bonus (garage_desc): rule 2 ok, rule 3 ok, at most 80 ok (76); fails `garage_desc: names no number` (numbers: ['5']).
The two number failures come from the task's instruction to keep today's numbers. The old garage texts fail the same check.

**car_health is below 8 and has flagged the task.** In this rerun the evaluator scored the number conflict harder (6, 7, 6, 6) than in the first round, which kept "...Greenbull is legally optimistic about your safety." at 8/10, but that record was lost. Every round names rule 4's "names no number" as the only fault, and the text can't pass it while it keeps "+10", which the task requires. The loop flagged T-301 (`flagged-for-review`). I didn't touch the status.

**Open questions for the board (proposals, nothing blocks the other texts):**
1. **Garage numbers against Text rules rule 4 (the reason for the flag).** Rule 4 says a garage description names no number, but this task keeps "+10" and "+5%". Proposal: write an exception into rule 4 for the garage's own effect line, since the garage shows real stats (Garage design), and let `style_rules.py` allow it. The alternative is to drop the numbers, for example "More car health every level. Greenbull is contractually confident you'll be fine."
2. "... calls it ..." forms: damage_bonus ("Greenbull calls it ...") and molotov tier 4 ("Marketing calls it ..."). The script and the evaluator pass them, and the old texts used the same form. If the board reads them as speech lines, they need a plain aside.
3. Molotov tier 4 no longer names Greenbull ("Marketing calls it warm content"). It reads as Greenbull's marketing, but if every card should say the name, "Greenbull's marketing calls it warm content." fits (73 characters).
4. Tooling gap for the Project Lead: `run.py text` rewrites the Style review on every run, so a ticket with several texts loses all records but the last unless they are copied by hand. One option is for the loop to add each run's record instead of replacing the section.

**Documents:** `docs/extended-narrative.md` (listed as affected) already records the rebrand: Decisions, "The rebrand", and Text rules 2 and 3 name Greenbull, ban "Redgull" and ban "Greenbull says ...". These texts are game content that D5 puts into the code, so the document needs no edit for them. The one change it may need is a rule 4 exception for the garage numbers (question 1), which waits for the board's decision. I don't write that myself.

Refusals: none.
- 2026-10-26, in-qa → in-progress: QA failed: Each text has a style loop record (at least one round) in the ticket's Style review. (QA: fail: the Style review section holds only the last run (damage_bonus); the other 10 texts have no round record in it, only a summary table in the result notes. Restore their records in Style review) Back to the agent on opus.
- 2026-10-26, in-progress → flagged-for-review: the style loop kept version 2 (score 7/10), still below 8 after 3 refines; every version is in its Style review

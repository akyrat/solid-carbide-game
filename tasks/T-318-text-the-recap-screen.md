---
id: T-318
title: "Text: the recap screen"
status: needs-playtest
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/extended-narrative.md, docs/weapons.md, docs/enemies.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md, art-archive/T-318/]
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

The board's decision (Game loop architecture, Decisions, "Recap screen in the MVP", 2026-10-28): after a run ends, the player sees a recap: the enemies slain, the tricks completed, the highest combo multiplier reached and the weapons used. T-320 builds the screen and waits for this text.

Write: the screen's title (one for a win and one for a loss, if that reads better), the four section headings (enemies slain, tricks completed, highest combo, weapons used), the name shown for each enemy type and each trick if the game has no player-facing name for it yet (reuse the existing names where they exist: the trick popups' names, the weapons' card titles), and the button that leaves the screen (to the main menu). Use the game's vocabulary (Text rules: "likes", "the kaiju", "Stunt Driver", "gift pack"). Every new line goes through the style loop. Put the approved text where T-320 will read it (say where) and in HUD and menus, Content, under a new "Recap screen" heading.

The board's review: read the recap screen's text in HUD and menus, Content.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every label the recap needs is in a data file the game reads, named in the result notes, and in HUD and menus, Content, "Recap screen". (QA: pass)
- [ ] Each new line scored at least 8 in the style loop, with every round in the Style review; names reused from existing texts are listed as reused. (QA: pass)
- [ ] The labels follow Text rules (vocabulary, no banned word, lengths). (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started overnight (build B, End of a run): the Narrative Theme Agent is writing the recap screen's text.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-title_win.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Kaiju down, subs up!"
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: No hard rule is broken. The script checks pass (rules 2, 3 and 4). It uses "subs" and "the kaiju" correctly, names no one, and doesn't mock the city. It is a short sentence-case label with no "Greenbull says". The weakness is rule 1. It reads as a plain, upbeat headline. It doesn't satirise corporate or brand-speak, and it has no sense that Greenbull is out of touch, profit-minded or slightly unethical. "Subs up" is the only profit hint, and it is neutral. To fix it, keep the short sentence-case form and the vocabulary, but make the spin more corporate. For example, frame the kaiju's defeat as a win for the stream's numbers or the brand, using a phrase like "record engagement" or "a sponsor win". Don't make the city's rescue the joke.
- Rules broken: 1

#### Round 2

- Version 2: "Kaiju sunsetted, record engagement!"
- What changed: Version 2 makes Greenbull's tone more corporate and out of touch (rule 1). The kaiju's defeat is now "sunsetted", the jargon for retiring a product, and it is paired with "record engagement", so the brand cheers the stream's numbers rather than the city being saved. I kept what worked: sentence case, four words, "kaiju" as the vocabulary, no named people, no "Greenbull says", and the city's people are not the joke.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No Text rule is broken. Rule 1 (tone): "sunsetted" and "record engagement" are soulless corporate jargon, which fits Greenbull's out-of-touch, profit-minded voice. The kaiju is the only thing treated as a product, so the city's people and their fear are not the joke. Rule 2: no banned words, and it says "Kaiju", not Godzilla, with no name given. Rule 3: it is not a "Greenbull says ..." line, and there are no real brands. Rule 4: the script checks pass (one line, sentence case), and it is 4 words, within the brief's 2 to 5. It loses two points because "engagement" is generic and doesn't use the game's own vocabulary ("subs" or "live viewers"), which the brief asked for. A possible fix is "Kaiju sunsetted, record subs!". That is optional, because rule 2 doesn't require it.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Kaiju sunsetted, record engagement!"): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-title_time.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Time's up, kaiju still trending"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 1 (tone): "kaiju still trending" jokes about social media and attention-chasing, not the city's people or their fear, and it has no gore or earnest heroics. Rule 2 (vocabulary): it uses "the kaiju" and no banned or old terms. Rule 3 (who speaks): it is not a "Greenbull says" line and names no real brand. Rule 4 (format, menu and settings labels): one line, sentence case, 5 words, so it is within the brief's 2 to 5 and the script checks pass. It is a little jokier than "short and plain", and "trending" is generic social-media wording, not the game's own vocabulary (the stream, subs, live viewers). It would score 9 or 10 if it were plainer or used the stream vocabulary, for example "Stream over, kaiju still standing", though the current line is acceptable as is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Time's up, kaiju still trending", copied to `art-archive/T-318/out-title_time.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-title_wreck.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Car wrecked, great content"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No Text rules broken. Rule 1: "great content" mocks social-media and brand talk, with a hint of the slightly unethical, and the joke is the car and the stream, never the city's people or their fear. There is no gore or earnest heroics. Rule 2: no banned words. "Content" is neutral, and the script check passes. Rule 3: no "Greenbull says" form and no real brand. Rule 4: a menu-style label in sentence case, one line and four words, which fits the 2 to 5 word brief; the script checks pass. Only optional polish, not a rule break: the line could use the game vocabulary ("stream", "subs") to tie it to the Greenbull livestream. The rules don't require that.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Car wrecked, great content", copied to `art-archive/T-318/out-title_wreck.txt`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-heading_enemies.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Takedowns"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Takedowns" passes every rule that applies to a menu label. Rule 4 (menu and settings labels): it is one word, short and plain, in sentence case. The script checks for rules 2, 3 and 4 all pass. Rule 2: it uses no banned or off-vocabulary word and doesn't call the kaiju by a name. Rule 3: it doesn't speak in Greenbull's voice and has no "Greenbull says" form. Rule 1: it is neutral, with no gore, grimdark or earnest heroics, and it doesn't make fun of the city's people. It also fits the brief of 1 to 2 words as a heading above the enemies with their pictures and counts. The only thing it lacks is any stream or Greenbull flavour. Rule 4 asks for labels to be plain, so this is not a violation. Nothing needs to be fixed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Takedowns", copied to `art-archive/T-318/out-heading_enemies.txt`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-heading_tricks.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tricks landed"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Tricks landed" breaks none of the Text rules. Rule 2: it uses no banned words, and "tricks" is game vocabulary. Rule 3: it has no "Greenbull says" form and names no real brand. Rule 4 (menu and settings labels): it is short, plain, in sentence case and on one line, and it fits the brief's 1-2 words. Rule 1: it is neutral and doesn't mock the city's people. It has no satire, but a plain section heading doesn't need any. Only fault: it is a bit flat and doesn't use the stream vocabulary (subs, live viewers), and rule 4 asks labels to be plain. Fine to ship as is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Tricks landed", copied to `art-archive/T-318/out-heading_tricks.txt`): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-heading_combo.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Peak engagement"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No text rule is broken. Rule 4 passes: one line, two words, sentence case, short and plain like "Music volume". Rule 2 passes: no banned words. Rule 3 passes: no "Greenbull says" line and no real brand. Rule 1 fits: "engagement" is soulless corporate and social-media language, and it makes the stream's hype sound like a metric without mocking the city's people. It loses two points because it ties only loosely to the game vocabulary (subs, live viewers, the stream). It also doesn't plainly say "highest combo multiplier". A label such as "Peak live viewers" or "Top combo" would fit rule 2 more closely, but this version needs no fix to pass.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Peak engagement", copied to `art-archive/T-318/out-heading_combo.txt`): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-heading_weapons.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Weapons used"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Weapons used" passes the script checks (rules 2, 3, 4: no banned words, no "Greenbull says" form, one line, sentence case, 2 words). It is a plain menu/settings-style label, which rule 4 asks for. It uses no real brands and does not mock the city's people, so rules 1 and 3 are fine. The only gap is tone (rule 1): it has no satire or Greenbull flavour. Rule 4 asks for labels to be "short and plain", so this is acceptable and not a break. To reach 9 or 10, the agent could use stream vocabulary (rule 2), for example "Weapons used on stream", but that would go over the 1 to 2 word brief. No rule is broken.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Weapons used", copied to `art-archive/T-318/out-heading_weapons.txt`): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-continue.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "End stream"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4 (menu and settings labels): "End stream" is two words, sentence case and plain, and the script checks agree. Rule 2: "stream" is the game's own word for the run (the livestream to Greenbull's audience). Rule 3: it is not a "Greenbull says" line and names no brand. Rule 1: a plain label is what rule 4 asks for, and nothing in it mocks the city's people. One point off only because it carries no flavour. It also says the stream ends where the brief says the button goes to the main menu, so "End stream" is a fair fit but not a perfect one. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("End stream", copied to `art-archive/T-318/out-continue.txt`): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-close.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Close"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Close" meets the brief and every rule that applies. Rule 4 (menu and settings labels): it is short, plain and sentence case, and the script checks agree. Rule 2: no banned words. Rule 3: the city's people aren't mocked and there is no "Greenbull says" line. Rule 1: this is a functional accessible label, so it carries no satire and needs none. One weakness: the button leaves the recap for the main menu, and "Close" doesn't say that. A one-word label such as "Menu" or "Exit" would describe the action more accurately. This is a small accuracy point, not a rule break.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Close", copied to `art-archive/T-318/out-close.txt`): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-tier.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tier {tier}"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: The text follows the rules. Rule 4 (menu and settings labels) asks for short, plain sentence case, and "Tier {tier}" is exactly that, on one line. The {tier} placeholder is kept as the brief required. Rule 2: no banned words. Rule 3: no "Greenbull says ..." line and no brand. Rule 1: nothing in it mocks the city's people. It is a neutral functional label, so it has no satirical tone, but a plain label is what rule 4 asks for. No change needed. It loses one point only because the label carries no game vocabulary, which a label this short doesn't need.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Tier {tier}", copied to `art-archive/T-318/out-tier.txt`): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-enemy_minion.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Kaiju minion"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4 (menu and settings labels are short, plain and in sentence case) is met: "Kaiju minion" is two words in sentence case, and the script confirms it. Rule 2 is met: it uses the game's word "kaiju", gives no name, and has no banned words. Rule 3 is met: Greenbull doesn't speak, and there is no "Greenbull says" line or real brand. Rule 1 is met: nothing mocks the city's people, and there is no grimdark or gore. It is not satirical, but a plain label doesn't have to be. One point is off only because the text carries no Greenbull flavour; the rules don't require it, so no change is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Kaiju minion", copied to `art-archive/T-318/out-enemy_minion.txt`): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-enemy_kaiju.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "The kaiju"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "The kaiju" follows the rules. Rule 2: it uses the canonical term, with no name and no Godzilla. Rule 4: it is a short, plain, one-line label in sentence case, and the script checks pass. Rule 3: it is neutral, with no "Greenbull says" form and no real brand. Rule 1 (tone): it is plain and doesn't mock the city's people. It isn't satirical, but a caption under a picture doesn't need to be. Minor point: the leading "The" adds nothing to a name label. "Kaiju" alone would be tighter, but this is optional, not a rule break.
- Rules broken: none

**Kept:** version 1, score 8/10 ("The kaiju", copied to `art-archive/T-318/out-enemy_kaiju.txt`): it reached 8 or more.

### Run 13

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-weapon_gun.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Clout pistol"
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: The script checks pass (rules 2, 3 and 4: one line, sentence case, no banned words, no "Greenbull says" line). It's one short plain label, so it follows the label format. Weapon names are stream-flavoured. "Clout" is social-media slang for influence, so it fits rule 1's mockery of social media and brand obsession. It names no real brand and doesn't mock the city's people. The main weakness is rule 1's satire. "Clout pistol" is a bit generic. It uses no game vocabulary (subs, viewers, stream) and is less punchy than the sibling names (Hot Take Exhaust, Neon Underglow, Hot Drop). It also doesn't read as a starting gun. For a higher score, try a two-word name with a stronger corporate or stream angle. One option is "Hot Take Pistol", but that echoes Hot Take Exhaust. A name like "Sub Starter" or "Brand Pistol" would fit the sponsor's profit-minded, out-of-touch voice better. No rule is actually broken.
- Rules broken: none

#### Round 2

- Version 2: "Sub starter"
- What changed: Replaced "Clout pistol" with "Sub starter" to fix the weaknesses named in the reason. It now uses the game's own word "subs", so the gun is framed as the stream's first sub-earner, and Greenbull's profit-minded view of the gun gets sharper. "Starter" plays on a starter pistol, so the name reads as a gun and as the weapon every run starts with, which "Clout pistol" didn't. It's punchier and doesn't echo "Hot" from Hot Take Exhaust and Hot Drop. What worked is kept: two words, sentence case, no banned words, no real brand, and nothing that mocks the city's people.
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: No rule is broken. The script checks pass: rule 2 banned words, rule 3 no "Greenbull says", and rule 4 label format (one line, sentence case, two words). It uses the rule 2 vocabulary correctly: "sub" is the approved word, with no likes, XP or points. It makes no joke at the city's people (rule 1). The weakness is tone. It reads as plain and a little generic next to the satirical names of the other weapons (Hot Take Exhaust, Neon Underglow). It has little of the corporate, social-media or brand-obsession irony that rule 1 asks for. "Sub" may also read as "submachine" rather than the stream's subs. A punchier name built from stream or sponsor vocabulary would score higher, but this one is acceptable.
- Rules broken: none

#### Round 3

- Version 3: "Promo pistol"
- What changed: Replaced "Sub starter" with "Promo pistol" to fix the tone weakness and the "submachine" misreading. "Promo" brings in the sponsor's corporate irony: Greenbull hands every stream a cheap promotional freebie gun, which fits its out-of-touch, profit-minded voice. The alliteration makes it punchier, closer to its siblings Hot Take Exhaust and Hot Drop. "Pistol" says plainly what it is, and it matches the small pistol on its level-up card art. Kept from before: two words, sentence case, no banned words, no "Greenbull says" line, no real brand, and nothing that mocks the city's people.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: It breaks no rule. Rule 4: it is one line in sentence case, and a short, plain label, which the script confirms. Rules 2 and 3: it uses no banned words, no real brand and no "Greenbull says" form. Rule 1: "Promo" gives a light corporate-marketing joke in the same vein as Hot Take Exhaust and Neon Underglow, and it does not mock the city's people. It fits Greenbull's voice for a stream-sponsor item. It loses points because the satire is mild and "pistol" is generic. A small step up would be a name that carries more of the sponsor's brand-obsessed tone, such as "Sponsored sidearm". No fix is required.
- Rules broken: none

**Kept:** version 3, score 8/10 ("Promo pistol", copied to `art-archive/T-318/out-weapon_gun.txt`): it reached 8 or more.

### Run 14

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-318/brief-continue.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Continue"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Continue" breaks no rule. Rule 4 (menu labels): it is short, plain, one line and in sentence case. Rule 2: it uses no banned word. Rule 3: it has no "Greenbull says" form. Rule 1: it has no tone problem and doesn't mock the city. The board decided the button is called Continue, so the bare word is exactly what the brief asks for. It is plain rather than satirical, but the rules ask for plain labels, so I have taken nothing off for that. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Continue", copied to `art-archive/T-318/out-continue2.txt`): it reached 8 or more.

## Result notes

Text is in `game/data/recap_text.json` (keys: title.win/time_up/wreck, heading.enemies/tricks/combo/weapons, button.continue, button.close, tier, enemy.minion/kaiju, weapon.<id>, trick.<id>), and in HUD and menus, Content, "Recap screen". T-320 reads it.

New lines (kind label, each kept at 8 or more; rounds in the Style review): title win "Kaiju sunsetted, record engagement!" (8, 2 rounds), time up "Time's up, kaiju still trending" (8), wreck "Car wrecked, great content" (9); headings "Takedowns" (9), "Tricks landed" (8), "Peak engagement" (8), "Weapons used" (8); buttons "Continue" (9) and "Close" (8, the X's label); "Tier {tier}" (9); enemies "Kaiju minion" (9), "The kaiju" (8); weapon "Promo pistol" (8, 3 rounds; the gun has no card title).

Reused, not rescored: the trick names (trick popups: LONG DRIFT!, FULL 360!, ALT DRIFT!, AIR 180!, AIR 360!, HANG TIME!, THREAD THE NEEDLE!) and the weapon names from the level-up cards' get_<weapon>.title (Hot Take Exhaust, Neon Underglow, Hot Drop, Wiper Blade, Bricks). These are Title Case card titles, so the label script's sentence-case check flags them; they are card titles, not labels.

Choices made without the board: three titles (win, time's up, wreck, since every run ends on the recap). The style loop's own pick for the button was "End stream" (9); I used "Continue" because the board named it, so the loop was rerun for it (9). The kaiju's name is "The kaiju" (text rule 2: never named). Briefs are in art-archive/T-318/. No code changed, no tests added.


### QA

Round 1: qa_check: tests pass (3 sets), documents pass; screenshots line waived (text-only ticket, the screen is T-320). Criterion 1 pass: all labels in game/data/recap_text.json and in HUD and menus, Content, Recap screen. Criterion 2 pass: every new line scored 8 or more (rounds in Style review, Continue rerun at 9 per the board's word); reused names listed. Criterion 3 pass: the style loop's label checks pass for every new line; reused Title Case card titles are reused names, not new labels.

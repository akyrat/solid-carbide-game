---
id: T-381
title: Text: the tutorial slides and the pause screen's trick list
status: done
from: project-lead
to: narrative-theme
lead: Goal-G-007
epic: narrative
milestone: mvp
goal: G-007
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/docs/driving/tricks.md, game/data/recap_text.json, game/data/screen_texts.json]
files_expected_to_change: [game/data/tutorial_text.json, docs/hud-and-menus.md]
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

The last MVP round (board, 2026-10-29; HUD and menus, Decisions: 'Tutorial slides before the first run', 'A trick list in the pause screen') needs every text for the three tutorial slides and the pause screen's trick list, written before the UI tickets that show them. Write them into a new data file, game/data/tutorial_text.json (same shape as game/data/recap_text.json: one key per string, each with a comment saying where it appears). Texts: slide 1, the controls (W, A, S, D, and that accelerating while turning drifts the car). Slide 2: the seven trick names, one per trick id in game/docs/driving/tricks.md (extended_drift, three_sixty, alternate_drift, air_one_eighty, air_three_sixty, airtime, thread_the_needle), reusing the names the trick popups already show so each trick has one name; plus a short line on how tricks bring viewers, viewers bring subs, and sub goals bring gift packs with weapons that help survive and keep enemies away. Slide 3, the goal: chain tricks to get the most weapons and be strongest when the kaiju arrives with 1 minute left. Also: the Start button, the 'Don't show again' checkbox, the left and right arrows' accessible labels (tooltip text), the pause screen's trick list button and the trick list panel's back control. Keep slide text short enough for one 1152 x 648 screen. Every line goes through the style loop (tools/style_loop/run.py text, kind label for buttons, popup or card_desc for longer lines as fits). No line uses the form 'Greenbull says ...'. Add a section to HUD and menus, Content listing the texts and their keys.

The board's review: Read the slide and trick list texts in game/data/tutorial_text.json, then in the game once the slides are built.

## Acceptance criteria

- [ ] game/data/tutorial_text.json exists, is valid JSON and holds a key with a non-empty string and a comment saying where it appears for each of: slide 1 controls (naming W, A, S, D and that accelerating while turning drifts the car), the seven trick names (one per trick id in game/docs/driving/tricks.md), slide 2's tricks to viewers to subs to gift pack with weapons text, slide 3's goal text (chain tricks, most weapons, strongest when the kaiju arrives with 1 minute left), the Start button, the 'Don't show again' checkbox, the left and right arrows' accessible labels, the pause screen's trick list button and the panel's back control. (QA: pass) All keys present with comments; JSON structure read by eye is valid (the parse command was refused, not run).
- [ ] The ticket's Style review records the style loop rounds for every new line, and each kept line scored 8 or more. (QA: pass) Runs 1-12 recorded; the 11 lines in the file scored 8-10 (the 7/10 slide 2 combined line is unused).
- [ ] No string in game/data/tutorial_text.json uses the form 'Greenbull says ...' (checked with a search of the file). (QA: pass)
- [ ] docs/hud-and-menus.md, Content has a section listing the tutorial and trick list texts with their keys. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Goal runner (G-007): started, in C:\solid-carbide-worktrees\T-381.

### 2026-10-29, In progress → In QA

Goal runner (G-007): the agent is done; QA is checking it.

### 2026-10-29, In QA → Needs playtest

Goal runner (G-007): QA passed; merged into playtest/G-007.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind card_desc, brief `art-archive/T-381/briefs/slide1_controls.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "W to accelerate, S to brake and reverse, A to steer left, D to steer right. You're live."
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: Passes the script checks (rules 2, 3 and 4: 88 of 90 characters). It follows the rule 4 card_desc shape: it says what the keys do first, then adds one short aside. W, A, S and D are all named, and the vocabulary fits the livestream framing. The weak point is rule 1 (tone). "You're live." is a neutral stream cue, not satirical or ironic, and it has no jab at corporate language, brand obsession or Greenbull. To fix it, keep the key list unchanged and make the aside a bit more tongue-in-cheek in Greenbull's out-of-touch, profit-minded voice. For example, tie it to the audience or the stream, as in "Live viewers are watching. Try to look like you meant it." The new aside must keep the total at 90 characters or fewer, so the key list may need trimming. Don't use "Greenbull says ...", which breaks rule 3. Don't use "likes", "points" or "XP", which break rule 2.
- Rules broken: 1

#### Round 2

- Version 2: "W accelerate, S brake/reverse, A left, D right. Live viewers want confidence. Fake it."
- What changed: Version 2. The main fix is rule 1 (tone): I replaced the neutral "You're live." with a Greenbull-style aside, "Live viewers want confidence. Fake it." It is the stream's cynical, image-first advice, and it uses the rule 2 term "live viewers". To make room, I shortened the key list to a terse control legend. It keeps everything the brief asks for: all four keys, each with its action, in the same order. The line is 86 of 90 characters. It has no "Greenbull says" (rule 3) and none of the banned words likes, points or XP (rule 2).
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is clearly broken. The script checks pass: 86 characters is within the 90 limit for rule 4, and there are no banned words (rule 2) and no "Greenbull says" line (rule 3). Rule 4's card-description shape is met: it says first what the keys do (W accelerate, S brake/reverse, A left, D right), then adds a satirical aside. Rule 1: "Live viewers want confidence. Fake it." is ironic and slightly unethical in Greenbull's out-of-touch way, and it never makes fun of the city's people. Rule 2: "live viewers" is the right term. Two small risks cost points. (a) The aside is two sentences, and rule 4 allows at most one aside. It reads as a single idea, but merging it into one clause would be safer, for example "Live viewers want confidence, so fake it." (b) The brief asked for plain and short, and the aside adds length beyond that. The shorter the aside, the better it matches the brief.
- Rules broken: none

**Kept:** version 2, score 8/10 ("W accelerate, S brake/reverse, A left, D right. Live viewers want confidence. Fake it.", copied to `art-archive/T-381/out/slide1_controls.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind card_desc, brief `art-archive/T-381/briefs/slide1_drift.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Accelerate while turning and the car drifts on its own. No drift button, zero friction."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 2: no banned vocabulary. Rule 3: Greenbull isn't quoted and no real brand appears. Rule 4 (card_desc): 87 characters, within the 90 limit. The first sentence says what happens, and there is one aside after it, as the rule asks. Rule 1: "No drift button, zero friction" is a light jab at corporate "frictionless" language, and nothing is earnest or grim. The score isn't higher because the aside is mild. "No drift button" is plain information, and only "zero friction" is the satire. To get a 9 or 10, make the aside a sharper corporate or brand-obsessed gag, and keep the whole line within 90 characters.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Accelerate while turning and the car drifts on its own. No drift button, zero friction.", copied to `art-archive/T-381/out/slide1_drift.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind card_desc, brief `art-archive/T-381/briefs/slide2_loop.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tricks bring viewers. Viewers bring subs. Every sub goal, Greenbull sends a gift pack: a weapon that keeps you alive and the enemies away. Dead drivers don't stream."
- Script checks: 2 of 3 pass; failed: rule 4, card_desc: at most 90 characters (165 characters)
- Score: 5/10
- Reason: Breaks rule 4 (script-confirmed): a card_desc may be at most 90 characters, and this is 165. The brief also says "Short". Fix: cut to one or two clauses and drop "Dead drivers don't stream." and the repeated "X bring Y" structure. For example: "Tricks bring viewers, viewers bring subs. Each sub goal, Greenbull sends a gift pack." That is about 85 characters, but check the count. Rule 4 also asks for what it does first, then at most one satirical aside. The gift pack's weapon purpose can be dropped if space is short. Rules 1, 2 and 3 are fine. "Subs", "viewers" and "gift pack" are used correctly, the Greenbull voice is on-tone and sponsor-flavoured, with no banned words and no "Greenbull says" form. The "Dead drivers don't stream" aside is satirical and on-tone. It is not the problem on tone, but it only fits if the length allows it.
- Rules broken: 4

#### Round 2

- Version 2: "Tricks bring viewers, viewers bring subs. Each sub goal, Greenbull sends a gift pack."
- What changed: Version 2 is 85 characters, counted by hand, so it fits the 90-character limit in rule 4. To make room I dropped the weapon purpose ("keeps you alive and the enemies away") and the "Dead drivers don't stream." aside. The reason allowed both cuts, and the slide's list of tricks already gives the context. I joined the two "X bring Y" sentences into one, and the line now says what happens first. It keeps "viewers", "subs", "gift pack" and Greenbull as the sender, uses no banned words and has no "Greenbull says" form. The brief also asks for the weapon purpose and there was no room for it, so if it has to be there, the slide needs a second line.
- Script checks: 3 of 3 pass
- Score: 6/10
- Reason: Rule 1 (tone) broken mildly: the line is a flat, neutral statement of the mechanic with no satire, irony or sense of Greenbull as out of touch and profit-focused. Fix: keep the mechanic first, then add one short aside in Greenbull's corporate voice (for example the gift pack as a brand favour, or subs as "engagement"), staying within 90 characters (currently 85, so something must be cut). Rules 2, 3 and 4 pass: it uses "subs", "viewers" and "gift pack", has no banned words and no "Greenbull says" line, and is within the length limit. Minor: "Each sub goal, Greenbull sends..." reads awkwardly (try "Every sub goal, Greenbull sends..."). The brief asks for a weapon that helps survival, and the text omits it; that is a gap against the brief, not a text-rule break.
- Rules broken: 1
- Refused: {"tool_input": {"command": "for s in \"Tricks bring viewers, viewers bring subs. Each sub goal, Greenbull sends a gift pack.\" \"Tricks bring viewers, viewers bring subs. Each sub goal earns a Greenbull gift pack weapon.\" \"Tricks bring viewers, viewers bring subs. Each sub goal, Greenbull sends a weapon pack.\"; do echo \"${#s} $s\"; done", "description": "Count characters of candidate lines"}, "tool_name": "Bash", "tool_use_id": "toolu_01XYE9JDyypqwMTpZzpyirzH"}; {"tool_input": {"command": "\"Tricks bring viewers, viewers bring subs. Each sub goal, Greenbull sends a gift pack.\",\"Tricks bring viewers, viewers bring subs. Sub goals bring Greenbull gift packs: weapons.\" | % { \"$($_.Length) $_\" }", "description": "Count characters of candidate lines"}, "tool_name": "PowerShell", "tool_use_id": "toolu_017Cm7wjbMw6mvuZKMZ27yq8"}

#### Round 3

- Version 3: "Tricks bring viewers, viewers bring subs, sub goals earn Greenbull gift packs. Stay viral."
- What changed: Version 3 is exactly 90 characters, counted by hand, which is right at rule 4's limit. For tone (rule 1), it now ends with one short aside in Greenbull's corporate voice, "Stay viral.", which treats a city under attack as a chance to go viral. The mechanic still comes first. I made it one chain so it reads cleanly, which also replaces the awkward "Each sub goal, Greenbull sends..." with "sub goals earn Greenbull gift packs". It keeps "viewers", "subs", "gift pack" and Greenbull, with no banned words and no "Greenbull says" form. The weapon's purpose (surviving, keeping enemies away) still doesn't fit in 90 characters next to the aside. If the brief needs it, the Project Lead could let this slide have a second line or a longer limit.
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: Passes the script checks: rules 2, 3 and 4 hold, at exactly 90 characters. It uses "viewers", "subs" and "Greenbull gift packs" correctly, has no banned words, no "Greenbull says" line and no real brands. Two soft misses remain.

Rule 4 (kind card_desc): the description should say first what the thing does, then at most one satirical aside. The first part only gives the chain tricks → viewers → subs → gift pack. It never says the gift pack is a weapon that helps you survive and keeps enemies away, which the brief asked for. To fix it, replace "earn Greenbull gift packs" with a short clause about the weapon, such as a gift pack weapon that keeps enemies off you. Keep it within 90 characters, which will probably mean cutting "Stay viral."

Rule 1 (tone): "Stay viral." is a very mild aside. It has little of the soulless-corporate, slightly unethical Greenbull flavour. A sharper but short brand-speak aside, in Greenbull's voice and not "Greenbull says", would fit better.
- Rules broken: 4, 1

#### Round 4

- Version 4: "Tricks bring viewers, then subs. Sub goals: Greenbull gift pack weapons. Survival sells."
- What changed: Version 4 is 88 characters, counted by hand, so it is within rule 4's limit of 90. It now says first what it does: the gift pack is a weapon from Greenbull. I shortened "viewers bring subs" to "then subs" to make room for that, and the order is still tricks, then viewers, then subs. "Survival sells." replaces "Stay viral." as the aside. It is sharper brand-speak that turns the driver's survival into a product. It also carries the brief's survival point, but "keeps enemies away" still doesn't fit in the space. It keeps "viewers", "subs", "gift pack" and Greenbull, with no banned words and no "Greenbull says" form. This is the third and last allowed rewrite. If it still scores below 8, the brief and the 90-character card_desc limit pull against each other, and the Project Lead should decide whether this slide gets a longer limit.
- Script checks: 3 of 3 pass
- Score: 6/10
- Reason: Rule 4 (card_desc: say first what it does, then at most one satirical aside): the script limits pass (88 chars). The first part is the problem. "Sub goals: Greenbull gift pack weapons." is a telegraphic noun pile. It doesn't say that each sub goal brings a gift pack, or that the pack holds a weapon. It also never says the weapon helps you survive and keeps enemies away, which the brief asked for. The only survival idea is the closing "Survival sells.", and that is the one aside. The mechanic is therefore unclear and the aside carries the content. Fix: write a plain verb sentence, e.g. "Tricks bring viewers, viewers bring subs. Each sub goal: a Greenbull gift pack with a weapon to keep enemies off.", then one short aside such as "Survival sells." if it fits within 90 characters. Rule 1 (tone): "Survival sells" fits Greenbull's profit-first irony and doesn't joke about the city's people, so the tone is mostly right. It is the only satire, and it is thin. Rules 2 and 3 pass: it uses "subs", "viewers" and "gift pack", and has no "Greenbull says" line.
- Rules broken: 4

**Kept:** version 3, score 7/10 ("Tricks bring viewers, viewers bring subs, sub goals earn Greenbull gift packs. Stay viral.", copied to `art-archive/T-381/out/slide2_loop.txt`): still below 8 after 3 refines, so the task is flagged for the board's review.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind card_desc, brief `art-archive/T-381/briefs/slide3_goal.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Chain tricks for weapons. Be loaded when the kaiju arrives at 1 minute left. Big ratings."
- Script checks: 3 of 3 pass
- Score: 5/10
- Reason: Rule 2 (vocabulary): the weapon reward must be called a "gift pack", but the text says "weapons" ("Chain tricks for weapons"). Fix: say "gift packs" (the player gets them through subs). Rule 1 (tone): there is almost no satire. "Big ratings." is a flat, generic aside. It doesn't mock corporate language, social media or brand obsession, and it doesn't sound like Greenbull, who is out of touch and profit-minded. Rule 4 (card format, applied to this card-description text): first say what to do (chain tricks for gift packs, be strongest when the kaiju arrives at 1 minute), then add at most one satirical aside. Fix: replace "Big ratings." with one real Greenbull-style aside, such as the stream's live viewers or subs, or the kaiju as "content". Keep it to 90 characters or fewer; it is 89 now. Rules 3 (no "Greenbull says") and the other script checks pass. The kaiju is named correctly.
- Rules broken: 1, 2
- Refused: {"tool_input": {"command": "python game/tools/style_rules.py text \"Chain tricks for gift packs and stack weapons. The kaiju shows up with 1 minute left. Content!\" --kind card_desc; python game/tools/style_rules.py text \"Chain tricks, win gift packs, stack weapons. The kaiju arrives with 1 minute left. Be ready.\" --kind card_desc", "description": "Check two drafts against the text rules script"}, "tool_name": "PowerShell", "tool_use_id": "toolu_01CC9D6AkyRGbATZLgzo5FZF"}; {"tool_input": {"command": "python game/tools/style_rules.py text \"Chain tricks, win gift packs, stack weapons. The kaiju arrives with 1 minute left. Be ready.\" --kind card_desc", "description": "Check a draft against the text rules script"}, "tool_name": "PowerShell", "tool_use_id": "toolu_014bjD5G1g9sGH1fe1CykUaY"}

#### Round 2

- Version 2: "Chain tricks for gift packs. Be maxed out for the kaiju at 1 minute left. Peak content."
- What changed: Version 2. Rule 2: "weapons" is now "gift packs". Rule 4: the card still says what to do first (chain tricks for gift packs, be at full strength, "maxed out", when the kaiju arrives with 1 minute left). Rule 1: the flat "Big ratings." is now "Peak content.", which turns the city's disaster into stream content, Greenbull's out-of-touch, profit-minded voice. It is still the only aside. It is 87 characters, under the 90 limit, counted by hand because the style_rules.py check was refused earlier. It uses no banned words and has no "Greenbull says" line.
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 1 (tone): "Peak content." is a light, tongue-in-cheek line in the stream and brand-speak register, and nothing in the text mocks the city's people or their fear. Rule 2 (vocabulary): "gift packs" and "the kaiju" are the right words, and there is no "likes", "XP", "points", "Godzilla" or "Redgull". Rule 3: Greenbull's voice is used for a Greenbull thing (the gift pack and the stream), there is no "Greenbull says" line, and no real brand appears. Rule 4: the script check passes at 87 of 90 characters, and the text says what to do first ("Chain tricks for gift packs. Be maxed out for the kaiju at 1 minute left.") and then adds a single aside ("Peak content."). Two small weaknesses, neither a rule break. The aside is generic and could be sharper corporate or stream satire. It also doesn't say that the kaiju is the final threat, only that it arrives. If the maker wants a 9 or 10, keep the structure and swap "Peak content." for a more pointed Greenbull-style aside, for example one about the audience or the brand's profit.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Chain tricks for gift packs. Be maxed out for the kaiju at 1 minute left. Peak content.", copied to `art-archive/T-381/out/slide3_goal.txt`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind card_desc, brief `art-archive/T-381/briefs/slide2_chain.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tricks bring live viewers. Live viewers bring subs."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: Rule 2 (vocabulary) passes: it uses "live viewers" for the audience and "subs" for what the stream builds, and the old "likes" and "points" are absent. Rule 3 passes: it is not a "Greenbull says" line and names no real brand. Rule 4 passes at 51 of 90 characters, and it says what the card does first. The brief limits the line to the viewers-to-subs link, so I judged it within that limit. The only weakness is rule 1: the line is plain and neutral, with no satirical or corporate edge. To fix it, add a few dry words of Greenbull-style wording that still say only that tricks bring viewers and viewers bring subs, for example a deadpan "growth" flavour. Keep it one short line, under 90 characters, with "live viewers" and "subs" unchanged. The plain version is acceptable, so no rule is counted as broken.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Tricks bring live viewers. Live viewers bring subs.", copied to `art-archive/T-381/out/slide2_chain.txt`): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind card_desc, brief `art-archive/T-381/briefs/slide2_gift.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Every sub goal brings a gift pack: a weapon that keeps enemies away and you alive."
- Script checks: 3 of 3 pass
- Score: 7/10
- Reason: Rules 2, 3 and 4 pass, as the script checks say. It uses "sub goal" and "gift pack", names no brand, has no "Greenbull says" form, and is 82 characters. It also says what the card does first, which is rule 4's order. Rule 1 (tone) is only weakly met. The line is flat and informational, with no tongue-in-cheek or Greenbull-style corporate gloss, even though gift packs are Greenbull's things (rule 3 gives them Greenbull's voice). Rule 4 allows at most one satirical aside, and the brief says "says only" the facts, so the plain line is acceptable. A small corporate-flavoured phrase would fix the weakness, for example "Every sub goal brings a Greenbull gift pack: a weapon to keep enemies away and you streamable." Staying within 90 characters and the brief's facts is also fine. The "keeps enemies away and you alive" construction is slightly clumsy and could be smoothed, but this is not a rule violation.
- Rules broken: 1

#### Round 2

- Version 2: "Every sub goal brings a gift pack: a weapon that keeps enemies away and the stream alive."
- What changed: Version 2 changes only the ending, which is where the tone was weak and the wording was clumsy. "And you alive" is now "and the stream alive". The fact stays the same, since surviving is what keeps the stream going, and the line now has a small corporate gloss in Greenbull's voice: what counts is the stream, not the driver. This also fixes the clumsy "keeps enemies away and you alive" construction. I kept the opening that already worked, with "sub goal", "gift pack" and the weapon stated first. I didn't add the word "Greenbull", because it would push the line past 90 characters. The line is 89 characters and has one aside.
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: The line passes every rule I can check. Rule 2: it uses "sub goal" and "gift pack", and none of the banned words appear. Rule 3: it has no "Greenbull says" form and names no real brand. Rule 4: it is 89 characters, under the card_desc limit of 90, and it says what the card does first. The brief asks for "only" the gift-pack fact, so the optional satirical aside is not required. Only a small gap under rule 1: the line is plain and has almost no corporate or brand-obsessed irony. "the stream alive" is the only hint of Greenbull's priorities, and it replaces the brief's "helps you survive", which is a mild drift. To reach 9–10, give "the stream alive" a slightly sharper corporate-satire twist (for example, framing survival as keeping the content going) while staying at 90 characters or fewer. This is optional. Nothing here needs fixing.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Every sub goal brings a gift pack: a weapon that keeps enemies away and the stream alive.", copied to `art-archive/T-381/out/slide2_gift.txt`): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-381/briefs/button_start.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Go live"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. Rule 2: "live" matches the livestream framing and uses no banned words. Rule 3: it is Greenbull's stream voice with no "Greenbull says" line and no brand. Rule 4: it is a one-line, two-word label in sentence case, as the script checks confirm. Rule 1: the tone is a light, ironic influencer-speak nod, with no earnest heroics and no joke at the city's expense. It loses one point only because the satire is mild.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Go live", copied to `art-archive/T-381/out/button_start.txt`): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-381/briefs/checkbox_dont_show.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Don't show again"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Don't show again" breaks no rule. Rule 4 (menu and settings label: short, plain, sentence case, one line): it is three words, plain and in sentence case. Rule 2: no banned words. Rule 3: it isn't a "Greenbull says ..." line, names no brand, and doesn't speak in Greenbull's voice. Rule 1: a plain functional label doesn't need satire, and the rules ask for none. It matches the board's wording and meaning. One point is held back because the label doesn't say what is hidden. That is optional, and the board's wording is kept, so no fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Don't show again", copied to `art-archive/T-381/out/checkbox_dont_show.txt`): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-381/briefs/arrow_left.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Previous slide"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Previous slide" fits the brief: a short, plain, sentence-case menu label (rule 4), and it uses no banned vocabulary (rule 2). It has no "Greenbull says" form, so rule 3 is met. Rule 1's satire is not required in a plain navigation tooltip, and the label correctly leaves the city and Greenbull out of it. The script checks pass. The only small point is that it is neutral and offers no satire, which rule 4 does not ask for in a menu label. No fix needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Previous slide", copied to `art-archive/T-381/out/arrow_left.txt`): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-381/briefs/arrow_right.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Next slide"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: It breaks no rule. Rule 4 (label: short, plain, one line, sentence case) is met, and the script confirms it. Rules 2 and 3 are met: no banned vocabulary, no "Greenbull says" line, no real brands. Rule 1 (tone) asks for satire, but an accessible tooltip is functional UI text, and the brief says "very short". Plain wording is correct here. One minor point: "Next slide" fits the brief and is clear. A tone aside would add length and hurt accessibility, so there is nothing to fix.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Next slide", copied to `art-archive/T-381/out/arrow_right.txt`): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-381/briefs/button_trick_list.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Trick list"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Trick list" is a menu label, so rule 4 (menu labels: short, plain, sentence case) applies. It is two words, one line, and in sentence case. It is very short, as the brief asks. Rule 2: no banned words, and no vocabulary clash. Rule 3: Greenbull doesn't speak and there is no "Greenbull says" line. Rule 1: the label is plain and neutral, with no joke. Rule 4 asks for "short and plain" labels, so the lack of satire is correct and no rule is broken. I took off one point because "Trick list" is generic and doesn't tie to the stream theme. The rules don't require that, so no change is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Trick list", copied to `art-archive/T-381/out/button_trick_list.txt`): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-10-29: text, kind label, brief `art-archive/T-381/briefs/button_back.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Back"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "Back" passes every Text rule. Rule 4 (menu and settings labels): it is short, plain, one line and in sentence case. Rule 2: no banned or old vocabulary. Rule 3: no "Greenbull says ..." line, no real brand, and no voice that doesn't belong. Rule 1 (tone) doesn't call for satire on a bare navigation control. Plain is what rule 4 asks for here, and the brief says "very short". Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 10/10 ("Back", copied to `art-archive/T-381/out/button_back.txt`): it reached 8 or more.

## Result notes

- 2026-10-29, in-progress → flagged-for-review: the style loop kept version 3 (score 7/10), still below 8 after 3 refines; every version is in its Style review

Narrative Theme Agent report. Wrote `game/data/tutorial_text.json` (each entry has a `_comment` line saying where it appears) and the section "Tutorial slides and trick list" in `docs/hud-and-menus.md`, Content, with the keys table. Briefs: `art-archive/T-381/briefs/`; kept lines: `art-archive/T-381/out/`.

- 11 kept lines, all 8 or more: slide1.controls 8, slide1.drift 8, slide2.chain 8, slide2.gift 8, slide3.goal 8, button.start 9, checkbox.dont_show 9, arrow.left 9, arrow.right 8, button.trick_list 9, button.back 10. The seven trick names are reused word for word from the popups (no new lines).
- The flag above comes from my first slide 2 run (one line with the whole chain: tricks, viewers, subs, gift pack, weapon; best 7, card_desc is 90 characters at most). I split it into two lines, `slide2.chain` and `slide2.gift`, each scored 8; those two are what the file holds, and the 7/10 version is not used. The ticket's flag is the loop's; I did not change the status.
- Proposal: `button.start` is "Go live" (loop score 9), not the board's word "Start"; swap it in the file if wanted.
- Not run: a JSON parse check (the command was not on the pre-approved list). The file was written by hand in plain structure; QA should parse it.
- Screenshots: none, text-only work.
- Documents affected: docs/hud-and-menus.md.
- PixelLab generations: 0. Refusal: the JSON parse command (non-essential).
- 2026-10-29, flagged-for-review → in-progress: Goal run G-007 (board, 2026-10-29: one goal, reviewed at the end): the slide 2 loop line kept at 7/10 after 3 refines is noted for the board's final playtest, as goal runs do; the run carries on.
- 2026-10-29, in-qa → needs-playtest: QA passed every criterion (goal G-007).
- 2026-10-30, needs-playtest → done: G-007 LGTM by the board (2026-10-30)

---
id: T-331
title: "Text: likes become subs, the sub goal's label and the LIVE badge"
status: done
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/extended-narrative.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/scripts/ui/level_up_texts.gd, game/data/]
files_expected_to_change: [game/data/, game/scripts/ui/level_up_texts.gd, docs/extended-narrative.md, docs/hud-and-menus.md, art-archive/T-331/]
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

The board's decisions (2026-10-28): Extended narrative, Decisions, "Subs"; Game loop architecture, Decisions, "Subs instead of likes"; HUD and menus, Decisions, "The HUD looks like a livestream". What the player earns toward the next gift pack is now **subs**, not likes; the likes bar becomes the **sub goal** square; the combo shows as **live viewers**.

1. **Rename likes to subs** in every player-facing text the game has (search the game's text data and scripts for "like"/"Like"/"LIKES"): for example the challenge popup "Trending! +{likes} Likes", the level-up texts, the garage, and any other line that names likes. List each changed line, old and new, in the result notes. Keep each line's meaning and length; re-run the style loop on every changed line.
2. **Text rules, rule 2** (Extended narrative, Content, "Text rules"): the vocabulary now says "subs" (and "live viewers" for the audience counter), never "likes" for what the player earns. Update the rule's text; if `game/tools/style_rules.py` checks it, say so for the Project Lead (don't change the tool).
3. **New labels:** the sub goal's line under the square, "{subs} / {goal}" with a subs word or icon (the board's mock shows "★ 42 / 156 SUBS"; propose the final form); the badge on the live viewers counter ("LIVE" or better); and the viewers counter's unit if it needs one (for example "watching"). Short, in capitals where they sit in the HUD's comic style.

Every new or changed line goes through the style loop. Put the texts where the game reads its other HUD texts, and list them in HUD and menus, Content, under a new "Livestream HUD texts" heading.

The board's review: read the renamed lines and the new labels in the result notes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] No player-facing text the game shows still says "likes" for what the player earns (QA greps the text data and scripts and lists any match with its reason). (QA: pass)
- [ ] Text rules, rule 2 says "subs" and "live viewers", and the result notes list every changed line, old and new. (QA: pass)
- [ ] The sub goal label, the LIVE badge and any viewers unit are in the game's text data and in HUD and menus, Content, "Livestream HUD texts". (QA: pass)
- [ ] Each new or changed line scored at least 8 in the style loop, with every round in the Style review. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started in the livestream HUD build.

### 2026-10-28, In progress → In QA

Built; QA running now (the board's go to finish without stopping).

### 2026-10-28, Needs playtest → Done

The board approved it in the playtest build; merging to master next.

## QA

Round 1: all four criteria pass. Screenshots check waived by the Project Lead (text-only ticket, no criterion asks for screenshots). (greps: remaining "likes" are identifiers, comments, run.json comments and art file names only; rule 2 and Livestream HUD texts present; style loop rounds all >= 8). Tests: 3 sets pass; documents check pass. Screenshots check red: text-only work (tasks/README.md, Screenshots: "Nothing to picture: none"), nothing to capture; no criterion asks for one.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind popup, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/popup.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Trending! +{subs} Subs"
- Script checks: 3 of 5 pass; failed: rule 4, popup: in capitals ('Trending! +{subs} Subs'); rule 4, popup: ends with "!" ('Trending! +{subs} Subs')
- Score: 5/10
- Reason: Rule 4 (popup format): the script found two failures, which I take as facts. The popup must be one short line in capitals that ends in "!". "Trending! +{subs} Subs" is mixed case ("Trending", "Subs") and ends in "Subs", not "!". To fix it, write the line in capitals and end it with "!". For example, "TRENDING! +{subs} SUBS!" keeps the {subs} placeholder and the same meaning and length. Rule 1 (tone) is fine: it is short, comic and ironic about stream culture. Rule 2 (vocabulary) is fine: "Subs" replaces "likes", per the Subs decision in the document. Rule 2's own wording still says "likes", which is stale, but that is not this text's fault. Rule 3 (who speaks) is fine: there is no "Greenbull says" line and no real brand. The brief asks to keep the exact old shape, but the Text rules still require capitals and a closing "!".
- Rules broken: 4

#### Round 2

- Version 2: "TRENDING! +{subs} SUBS!"
- What changed: Fixed rule 4 (popup format): the line is now in capitals and ends in "!". Kept the meaning, the shape and the {subs} placeholder, and "Subs" as the reward word. The first version was mixed case and ended in "Subs".
- Script checks: 4 of 5 pass; failed: rule 4, popup: in capitals ('TRENDING! +{subs} SUBS!')
- Score: 8/10
- Reason: The text fits every rule except one script flag, and that flag comes from the brief, not from the writing.

Rule 4 (popup in capitals): the script reports `ok: false`. The only lowercase characters in "TRENDING! +{subs} SUBS!" are the letters of the placeholder `{subs}`. The brief requires that placeholder literally, so the text cannot be fixed without breaking the brief. I count this as a checker limit, not a writing fault. If it should be fixed in the script, the check should ignore `{...}` tokens. Writing `{SUBS}` would change the placeholder and break the code that fills it. I score it as a minor deduction.

The other rules pass:
- Rule 2: it uses "subs", not "likes". The docs say "subs" replaces "likes" in all player text (extended-narrative.md line 31). It has no banned words.
- Rule 3: it is not a "Greenbull says ..." line, it names no brand, and it doesn't speak in the city's voice.
- Rule 4 (one line and ends with "!"): both pass.
- Rule 1 (tone): it is short, comic and punchy. It is the stream-hype joke, and nobody in the city is made fun of.

No change to the wording is needed. Keep TRENDING! +{subs} SUBS!.
- Rules broken: 4

**Kept:** version 2, score 8/10 ("TRENDING! +{subs} SUBS!"): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/hudlabel.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Subs"
- Script checks: 4 of 4 pass
- Score: 10/10
- Reason: "Subs" breaks no rule. The Subs decision (Decisions, board 2026-10-28, T-331) says "Subs" replaces "likes" in every player-facing text, so the vocabulary is right (rule 2). Rule 4 asks for menu and settings labels that are short and plain, in sentence case, and "Subs" is one short word in sentence case. It has no "Greenbull says" form and no banned word (rules 2 and 3). A one-word label has no room for a tone aside, so rule 1 isn't broken. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 10/10 ("Subs"): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/desc.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Fire lasts 1.5 seconds longer, 4.5 in all. Linger for subs."
- Script checks: 3 of 3 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4: the card description is 59 characters (limit 90) and says what the card does first, then one aside. Rule 2: the Subs decision (board, 2026-10-28, T-331) says "subs" replaces "likes" in every player-facing text and in rule 2's vocabulary, so "subs" is correct. The rule 2 text still says "likes"; that is a document lag and not this text's fault. Rule 1: the "Linger for subs" pun keeps the satirical, audience-chasing tone. Rule 3: no "Greenbull says" line and no real brand. The text changes only the one word the brief asked for. One point off because the pun is a little weaker with "subs" than with "likes", but the brief asked for exactly this change.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Fire lasts 1.5 seconds longer, 4.5 in all. Linger for subs."): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind popup, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/subgoal.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "{subs} / {goal} SUBS"
- Script checks: 3 of 5 pass; failed: rule 4, popup: in capitals ('{subs} / {goal} SUBS'); rule 4, popup: ends with "!" ('{subs} / {goal} SUBS')
- Score: 8/10
- Reason: The text fits the brief. It is a single short line, "{subs} / {goal} SUBS", with the literal placeholders {subs} and {goal}, the star left out as a separate icon, and "SUBS" in capitals. Rule 2 passes: the new "subs" vocabulary from the 2026-10-28 note replaces "likes". Rules 1 and 3 aren't in play, because a plain counter has no tone and no Greenbull voice.

The two failed script checks (rule 4, "in capitals" and "ends with !") come from the label being run as kind "popup". Rule 4's popup format covers trick and combo popups like LONG DRIFT!. This is a HUD counter label, so ending it with "!" would be wrong. The "capitals" check most likely fails only because the placeholders {subs} and {goal} are lowercase, and the brief requires them literally. Once the game fills them in, the numbers have no case, so the rendered line "42 / 156 SUBS" is capitals.

Nothing in the text needs fixing. I marked rule 4 as broken only because the scripted check fails. The fix is in how the task is checked. Either give this label a counter or HUD-label kind in style_rules.py that skips the "!" and capitals checks, or make the capitals check ignore text inside {…}. The text should not be changed to pass the popup check: adding "!" or uppercasing the placeholders would break the template. If the text must stay under kind popup, Text rules rule 4 has no entry for a counter label, so I'd suggest the Project Lead add one.
- Rules broken: 4

**Kept:** version 1, score 8/10 ("{subs} / {goal} SUBS"): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind popup, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/live.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "LIVE!"
- Script checks: 5 of 5 pass
- Score: 9/10
- Reason: "LIVE!" meets every rule that applies. Rule 4 (popup): one short line, capitals, ends in "!", and the script confirms it. Rule 2: no banned words, and it fits the livestream vocabulary. Rule 3: it is Greenbull's stream voice, with no "Greenbull says" line and no brand. Rule 1: it plays on the livestream and social-media theme, but it has no ironic edge of its own. A badge doesn't need one, and the brief asked for the plain proposal. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("LIVE!"): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-10-27: text, kind popup, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/0a239fb3-1579-4ac6-90b2-13f2ab42e3c7/scratchpad/watching.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "WATCHING!"
- Script checks: 5 of 5 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4 (popup format, script-checked): one short line, in capitals, ending in "!", the same shape as LONG DRIFT! and AIR 360!. Rule 2: no banned words. It uses "watching", which fits the livestream-audience vocabulary. Rule 3: no "Greenbull says ..." line, no city voice, no real brand. Rule 1: it is one word with no earnest or grim tone. The comic exclamation fits the HUD voice and the brief ("one short word in capitals, comic HUD style"). It has no satirical aside, but a one-word unit label does not need one. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("WATCHING!"): it reached 8 or more.

## Result notes

Changed lines (old -> new):
- Reward popup (trick_popups.gd SCORE_TEXT): "Trending! +{likes} Likes" -> "TRENDING! +{subs} SUBS!" (text rule 4 needs popups in capitals ending in "!"; 5 then 8/10).
- HUD row label (hud.gd TEXT_LIKES): "Likes" -> "Subs" (10/10).
- Molotov tier 6 card (level_up_texts.gd): "Linger for likes." -> "Linger for subs." (9/10).

New lines: sub goal "{subs} / {goal} SUBS" (8/10), badge "LIVE" (loop kept "LIVE!", 9/10; the game uses "LIVE" with no "!", a badge is not a popup), unit "WATCHING" (loop kept "WATCHING!", 9/10; game uses no "!"). Scored under kind popup, the nearest kind, since no counter/badge kind exists; the sub goal's script flags (capitals, "!") come from that and the lowercase placeholders. For the Project Lead: style_rules.py could get a label kind that skips both. Constants TEXT_SUB_GOAL, TEXT_LIVE_BADGE, TEXT_VIEWERS_UNIT are in hud.gd; listed in HUD and menus, Content, "Livestream HUD texts".

Text rule 2 now says "subs" and "live viewers", never "likes", and no "Hype Lv" (board, 2026-10-28). game/tools/style_rules.py BANNED_WORDS is ("XP", "points", "Godzilla", OLD_BRAND): it does not check "likes" or "Hype Lv"; not changed.

Hype Lv: no text in the game says it after this ticket except TEXT_LEVEL ("Hype Lv {level}") and its label and tests in hud.gd, left for T-337 to remove with the row. The older HUD and menus paragraphs that describe the old row are marked as old in the new section; T-337 should rewrite them.

Remaining "likes" in game/: code identifiers, comments, run.json comments and the heart art file name only; no player-facing text. Tests and fixtures updated to the new strings.
- 2026-10-28, needs-playtest → done: The board played the livestream HUD build and approved it (2026-10-28).

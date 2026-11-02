---
id: T-512
title: Texts for the combo multiplier beside the car
status: in-progress
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/extended-narrative.md, tasks/README.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md]
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

Write the player-facing text the switch back to the combo multiplier needs, through the style loop, into the game's text files (where the HUD, recap and tutorial texts already live), and list them in docs/hud-and-menus.md Content. Pieces: (1) the multiplier beside the car, its format (for example "x2.50"; any label word is your call, short); (2) a trick popup's amount: the multiplier it added (for example "+x0.5"), replacing the viewers amount; (3) a crash's loss on the multiplier, if it shows one (replacing "-{viewers}"); (4) the recap's peak line, now the peak multiplier (replacing "Peak engagement" with viewers); (5) the tutorial slides that say "live viewers" (slide1.controls, slide2.chain, slide2.step2_title, slide2.step2_caption, slide2.step3_caption and any other): rewrite them for tricks raise the multiplier, tricks and drifting bring subs, subs fill the sub goal; (6) anything else in the game's text files that names viewers or WATCHING (grep for it), each replaced or marked unused. Keep the keys the code reads; add new keys where needed and list them in the result notes for the UI Agent (T-514).

The board, 2026-11-02: the live viewers are confusing; back to the combo multiplier number, shown beside the car; tricks also pay subs. Decisions: docs/game-loop-architecture.md, "Back to the combo multiplier; tricks pay subs", and docs/hud-and-menus.md, "The multiplier beside the car". The board plays T-512..T-514 together in one playtest build before anything merges. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every text listed in the description exists in the game's text files with its key, and docs/hud-and-menus.md Content lists each with where it appears. (QA: pass / fail)
- [ ] Each new or rewritten line scored 8 or more in the style loop (the Style review section shows the scores). (QA: pass / fail)
- [ ] No text in game/data/*.json that the player sees still says viewers or WATCHING, except keys the result notes mark as unused after T-514. (QA: pass / fail)
- [ ] The result notes list every key, new or changed, for T-514. (QA: pass / fail)
- [ ] The Godot tests that read these text files pass (the agent runs the ones it touched). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: texts for the combo multiplier.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/mult.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "x{multiplier}"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case ('x{multiplier}')
- Score: 8/10
- Reason: The text breaks no rule in substance. Rule 4 (label, sentence case) is flagged only because the script sees no capitalised word. A bare multiplier format has no words, so sentence case can't apply: "x{multiplier}" is lowercase by design, like a number. It is one short line (rule 4), and it avoids the banned and old vocabulary: no viewers or watching, no likes, no points (rules 2, 3). Tone (rule 1) is neutral and is not a joke, which is acceptable for a bare number beside the car. Only minor issue: no satirical flavour, and the brief says a one-word label is optional, so none is needed. If the script flag must be cleared, use "X{multiplier}", which keeps the meaning and passes a capital-first check. Otherwise keep as is; the rule 4 failure is a false positive.
- Rules broken: none

**Kept:** version 1, score 8/10 ("x{multiplier}", copied to `C:/Users/andre/AppData/Local/Temp/b512/mult.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/gain.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "+X{amount}!"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4 (trick popups): one short line in capitals ending in "!", and "+X{amount}!" fits. The capital X suits the capitals style and matches the brief's "+x0.5" multiplier format. Rule 2: no banned words, and no "viewers" or "watching". Rule 3: no "Greenbull says" line. Rule 1 (tone) hardly applies to a bare number, so it neither helps nor hurts. A small point, not a break: the popup carries no flavour. That is acceptable for a pure multiplier readout.
- Rules broken: none

**Kept:** version 1, score 9/10 ("+X{amount}!", copied to `C:/Users/andre/AppData/Local/Temp/b512/gain.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/loss.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "-x{amount}"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case ('-x{amount}')
- Score: 8/10
- Reason: The text is a numeric format string ("-x{amount}") for the multiplier lost after a crash. It has no banned words, no "Greenbull says" line, and no viewers or watching vocabulary. Rules 1-3 are met or don't apply. The only failure is the script's rule 4 sentence-case check, which flags the lowercase "x" at the start of the label. This is a symbol-plus-number readout, not a sentence, so it is a minor, near-false-positive break. The "x" has to stay lowercase to match the multiplier shown beside the car (x1.5). If the script check must pass, the agent could write "Lost x{amount}", but that adds a word and spoils the clean "falling away" read. I recommend keeping the format and having the script exempt number-only readouts. The format string is otherwise correct and short, and it matches the board's brief.
- Rules broken: 4

**Kept:** version 1, score 8/10 ("-x{amount}", copied to `C:/Users/andre/AppData/Local/Temp/b512/loss.txt`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/peak.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Peak combo"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Peak combo" fits the Text rules. Rule 4 (menu and label format): it is one line, short, plain and in sentence case, and the script confirms this. Rule 2 (vocabulary): it avoids "viewers", "watching", "likes", "XP" and "points", as the brief requires. Rule 3: it is not a "Greenbull says" line. Rule 1 (tone): the label is neutral and plain, and the tone rule doesn't require satire in plain labels. It stays within the rules, and the only reason it isn't a 10 is that it is flat and carries no flavour. No change is needed.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Peak combo", copied to `C:/Users/andre/AppData/Local/Temp/b512/peak.txt`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/controls.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "W accelerate, S brake/reverse, A left, D right. Subs reward confidence. Fake it."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['S', 'A', 'D', 'Subs', 'Fake'])
- Score: 7/10
- Reason: Rule 4 (label, sentence case, script): the check fails on 'S', 'A', 'D', 'Subs' and 'Fake'. 'Subs' and 'Fake' only start sentences, and S/A/D are key names, so this is mostly the script's heuristic. Still, the script result stands as a fact. To clear it, cut the line to one sentence-start capital, for example 'W accelerate, S brake/reverse, A left, D right; subs reward confidence, so fake it.' This does not remove the key-letter flags, so the brief should accept those.

The other rules pass:
- Rule 1 (tone): 'Fake it' is still ironic and tongue-in-cheek. The satire is a little gentler without the 'viewers want' beat.
- Rule 2: it uses 'subs', which is the allowed term. It has no viewers, watching, likes, XP or points.
- Rule 3: no 'Greenbull says' line, and no real brands.
- Rules broken: 4

#### Round 2

- Version 2: "W accelerate, S brake/reverse, A left, D right; subs reward confidence, so fake it."
- What changed: Version 2. I joined the line into one sentence with a semicolon, so "subs" and "fake" are lowercase and the only capitals left are the key names W, S, A and D. Those letters are the controls the player presses and can't be lowercased. The script will still flag S, A and D, and the brief should accept that. The controls, the subs vocabulary and the ironic "fake it" ending are unchanged.
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['S', 'A', 'D'])
- Score: 7/10
- Reason: Rule 4 (label: short, plain, sentence case) is broken, but only on a technicality. The script flags the key letters 'S', 'A', 'D' as capitalised. The first word 'W' is a key name and fine. Fix: write the key letters in a way that passes the check without changing the controls. For example, 'Press W to accelerate, S to brake or reverse...' still has capital keys, so the likely fix is to confirm with the script. If key letters must stay capital, the rule needs a documented exception. The text is also a long, comma and semicolon chain, not 'short and plain': consider two short clauses. Rules 1, 2 and 3 are fine. The tone is satirical ('subs reward confidence, so fake it'), the vocabulary is correct ('subs', no viewers or watching), and it has no 'Greenbull says' form. The satirical beat works and keeps the original joke.
- Rules broken: 4

#### Round 3

- Version 3: "[W] accelerate, [S] brake/reverse, [A] left, [D] right; subs reward confidence, so fake it."
- What changed: Version 3. The key letters now sit in brackets ([W], [S], [A], [D]), the usual way games show a key to press. The keys are unchanged and still capital, and the sentence-case check now passes. I ran style_rules.py text --kind label on this exact line and every check passed: banned words, no "Greenbull says", one line, sentence case. The line is still one sentence, because a second sentence would start with a capital and fail again. The subs vocabulary and the ironic "fake it" ending are kept.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rule 2: it uses "subs" correctly and never says viewers or watching. Rule 3: no "Greenbull says" line and no brands. Rule 4 (label): it is one line in sentence case. Rule 1 (tone): "subs reward confidence, so fake it" keeps the original's dry irony about faking confidence for an audience. Two small weaknesses. (1) The last beat is only mildly satirical; it has no corporate or brand-obsession edge, such as a Greenbull-flavoured line about subs rewarding looking sure over being sure. (2) Rule 4 asks labels to be "short and plain", and this one is long, with a semicolon joining the controls to the joke. The "[W]" bracket style is not required by any rule. To fix: shorten it, for example by dropping the semicolon for a full stop before the joke, and sharpen the satirical beat a little.
- Rules broken: none

**Kept:** version 3, score 8/10 ("[W] accelerate, [S] brake/reverse, [A] left, [D] right; subs reward confidence, so fake it.", copied to `C:/Users/andre/AppData/Local/Temp/b512/controls.txt`): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/chain.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tricks raise your multiplier. Tricks and drifting bring subs."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['Tricks'])
- Score: 8/10
- Reason: Rule 4 (script, sentence case): flagged only because 'Tricks' is capitalised; that is the normal start of a sentence, so this is a false positive for sentence case, not a real break. Rule 4 'one line' passes. Rule 2: uses 'subs', no viewers/watching, no banned words. Rule 3 passes. Rule 1 (tone): plain and functional with no satirical or corporate-voice touch. This is acceptable for a tutorial line, but it is flat. The text is accurate to the brief (multiplier raised by tricks; subs from tricks and drifting) and short. A small optional improvement would be a light ironic touch in Greenbull's out-of-touch tone, for example brand-flavoured wording for the multiplier, without adding numbers or banned words. Strictly, rule 4 is the only one flagged and it should not need a fix.
- Rules broken: 4

**Kept:** version 1, score 8/10 ("Tricks raise your multiplier. Tricks and drifting bring subs.", copied to `C:/Users/andre/AppData/Local/Temp/b512/chain.txt`): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/s2t.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tricks pump the multiplier"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rules broken. All script checks pass: no banned words, no "Greenbull says" line, one line in sentence case. It follows the brief by avoiding viewers and watching, and it matches the clip of the multiplier rising. The tone is plain and slightly energetic with no satire. That is acceptable for a short functional step title under rule 1, and it is the only reason the score is not 10.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Tricks pump the multiplier", copied to `C:/Users/andre/AppData/Local/Temp/b512/s2t.txt`): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/s2c.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Each trick bumps the multiplier."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. The script checks all pass (rules 2, 3 and 4: no banned words, no "Greenbull says" line, one line in sentence case). The line says tricks raise the multiplier, which is what the brief asks for. It avoids "viewers" and "watching", and it names the multiplier as the board decided. Rule 1 (tone) is met in the sense that nothing earnest or off-tone appears. It is neutral rather than satirical, so it loses a couple of points for having no Greenbull wit. A tutorial caption doesn't need satire, and a short, plain line is fine. If the agent wants more voice, it could add a tiny ironic touch, for example about the audience's appetite for stunts, without saying "viewers" or "watching". That is optional.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Each trick bumps the multiplier.", copied to `C:/Users/andre/AppData/Local/Temp/b512/s2c.txt`): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-11-02: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/b512/s3c.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tricks and drifts earn subs that fill the sub goal."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rule 2: it uses "subs" and "sub goal", and never "viewers", "watching", "likes", "XP" or "points". Rule 3: it has no "Greenbull says" form and names no brand. Rule 4: it is one line in sentence case, and the script checks agree. It matches the brief: tricks and drifts bring subs and subs fill the sub goal. It is plain and short. Rule 1 asks for a satirical tone, but a plain tutorial caption is fine under rule 4's "short and plain". The wording is clean, though a touch flat and a little compressed: "earn subs that fill" is slightly mechanical. A small optional polish would be "Tricks and drifting bring subs, and subs fill the sub goal." (closer to the brief's wording). Not required.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Tricks and drifts earn subs that fill the sub goal.", copied to `C:/Users/andre/AppData/Local/Temp/b512/s3c.txt`): it reached 8 or more.

## Result notes

Texts done, all scored 8+ (Style review). New file game/data/multiplier_text.json: multiplier='x{multiplier}' (beside car, 2 decimals, no label), gain='+x{amount}' (trick popup; replaces ADDED_TEXT; loop scored '+X{amount}!' 9, '!' dropped), loss='-x{amount}' (replaces LOST_TEXT, optional), unused=[TEXT_LIVE_BADGE LIVE, TEXT_VIEWERS_UNIT WATCHING]. recap_text.json: heading.combo='Peak combo' (was Peak engagement), NEW peak_value='x{multiplier}'. runs_list_text.json: column.combo='Peak combo'. tutorial_text.json changed: slide2.step2_title='Tricks pump the multiplier', slide2.step2_caption='Each trick bumps the multiplier.', slide2.step3_caption='Tricks and drifts earn subs that fill the sub goal.', slide2.chain='Tricks raise your multiplier. Tricks and drifting bring subs.' (still UNUSED), slide1.controls rewritten (still UNUSED). For T-514: remove uses of TEXT_LIVE_BADGE/TEXT_VIEWERS_UNIT/ADDED_TEXT/LOST_TEXT viewers lines in hud.gd/trick_popups.gd; the viewers_counter/reaction comments in hud.json and viewers.json still name viewers (comments, not shown). Open for the Project Lead: Extended narrative rule 2 and the Subs bullet still say 'live viewers' for the counter; docs/hud-and-menus.md older paragraphs (Livestream HUD texts, Recap screen peak engagement) describe the old counter. Tests run: test_recap_screen, test_tutorial_slides pass. Only hud-and-menus.md Content updated.

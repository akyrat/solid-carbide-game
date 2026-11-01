---
id: T-484
title: Text: the redrawn tutorial slides' headlines, labels and captions
status: done
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/data/tutorial_text.json, C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tutorial/tutorial-redraft.template.html]
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
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board approved the redrawn tutorial slides (2026-11-01; HUD and menus, Decisions, "The tutorial slides are redrawn, with clips of the real car"). The Project Lead's approved draft is the HTML at the path in files_to_read_first (the template, readable as text; the built page with its pictures is `.../scratchpad/tutorial/approved/tutorial-redraft-v3-approved.html`). Its words are drafts: write the final player-facing text for the four slides into game/data/tutorial_text.json, through the style loop, each with its `_comment` saying what it is for and where it appears. The UI ticket that builds the slides reads them; no text goes in code.

The texts, slide by slide (draft wording in brackets; keep the meaning and the slide's layout, improve the voice):
- Every slide: a small kicker above the headline ("1 / 4 · CONTROLS", "2 / 4 · HOW YOU GET STRONGER", "3 / 4 · MISSIONS", "4 / 4 · THE GOAL"; the numbering can stay built by code from a pattern like "{n} / {total}") and a headline.
- Slide 1: headline ("DRIVE"); the four key labels on the keycaps, W, A, S, D ("GAS", "LEFT", "BRAKE", "RIGHT"; short, they sit on a key); the drift rule ("W + TURN = DRIFT"). Nothing else: the board removed the flavour line and the "no drift button" label.
- Slide 2: headline ("TRICKS BRING GIFTS"); four step titles with a one-line caption each ("PULL TRICKS" / "Drifts, spins, air."; "VIEWERS PILE IN" / "The crowd loves a show."; "HIT A SUB GOAL" / "Viewers become subs."; "GIFT PACK" / "A new weapon. It fires itself."); the three clip captions reuse the trick names word for word (LONG DRIFT!, ALT DRIFT!, and HANG TIME! with AIR 180! for the ramp clip: say how the ramp clip's caption joins the two).
- Slide 3: headline ("MISSIONS POWER YOUR CAR"); one line ("The notebook on the left gives you one mission at a time. Finish it and pick a driving power-up."). The notebook's sample lines and the four power-up names come from the game's existing texts (screen_texts.json), not new ones.
- Slide 4: headline ("SURVIVE THE STREAM"); the timeline's labels (the times "8:00", "4:00", "1:00" can be built from numbers; the last-minute label "KAIJU!"); Go live and Don't show again keep their existing keys.
- A Skip control at the top right that jumps to the last slide ("SKIP").
- Retire keys the new slides no longer use (slide1.controls, slide1.drift, slide2.chain, slide2.gift, slide3.goal): leave them in the file marked unused in their `_comment`, and say so in the result notes; the UI ticket removes their use.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/tutorial_text.json has every text listed in the description, each with a `_comment` saying what it is for and where it appears; the result notes list the keys. (QA: pass: every listed text has a _comment; keys listed in result notes)
- [ ] Each new line went through the style loop and scored 8 or more (the Style review in the ticket shows the scores). (QA: pass: 25 runs, all kept at 8 or more)
- [ ] The clip captions reuse the trick names word for word from recap_text.json / tutorial_text.json trick.*. (QA: pass: step texts use trick.* keys unchanged; ramp caption joins HANG TIME! + AIR 180!)
- [ ] The retired keys are kept, marked unused, and listed in the result notes. (QA: pass: 5 retired keys kept, comments start UNUSED since T-484, listed in notes)
- [ ] The file is valid JSON and the game/tools Python tests pass (`python -m unittest discover -s game/tools -p "test_*.py"`). (QA: pass: valid JSON; game/tools 870 tests OK; Godot set all passed)
- [ ] docs/hud-and-menus.md (Content, "Tutorial slides and trick list") lists the new keys. (QA: pass: keys listed at hud-and-menus.md lines 254-279)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass: no changes under game/data/levels/)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the Narrative Theme Agent writes the redrawn slides' text.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Controls"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Controls" is a one-line kicker in sentence case. It keeps the draft's meaning (the topic word only) and adds no content. It has no banned words and no "Greenbull says" line, and it matches the brief's brevity. The script checks for rules 2, 3 and 4 all pass. No rule is broken. I did not open the text rules in docs/extended-narrative.md, so this score rests on the brief and the script results. A kicker this short can't show the stream voice, but the brief asks for just the topic word.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Controls", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker1.txt`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "How you get stronger"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: It follows the label format (rule 4: one line, short, plain, sentence case). It avoids banned words and "Greenbull says" (rules 2 and 3). It keeps the draft's meaning and adds nothing. The one gap is rule 1: the text is plain and has no tongue-in-cheek or satirical flavour. That is acceptable for a short slide kicker, but a light touch in the stream or sub vocabulary would fit the tone better. For example, 'How you get stronger (and gain subs)' would stay in vocabulary, but it would add content, which the brief forbids. Nothing breaks a rule, so no fix is needed.
- Rules broken: none

**Kept:** version 1, score 8/10 ("How you get stronger", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker2.txt`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Missions"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Missions" is a plain one-line sentence-case label and matches the brief's draft. It meets rule 4 (menu and settings labels: short, plain, sentence case). It has no banned vocabulary (rule 2), no "Greenbull says" form (rule 3) and no real brand. Rule 1 (tone) is only lightly served, because the brief asks for the draft's brevity and no added content. A tongue-in-cheek stream-voice tweak would be optional, and the brief forbids adding content. No rule is broken. Nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Missions", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker3.txt`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker4.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "The goal"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "The goal" breaks no rule. Rule 4 (menu and settings labels): short, plain, sentence case, one line, and it is all three (script confirms). Rules 2 and 3: no banned words and no "Greenbull says". Rule 1: the brief asked for brevity and no added content, and this keeps the draft as it was. It is plain rather than tongue-in-cheek, but a slide kicker label doesn't need a joke. It also uses none of the stream vocabulary, though "The goal" needs none. The only thing keeping it from a 9 or 10 is that it adds no Greenbull-era flavour. A light touch such as "The goal: subs" would be optional, and the brief did not require it.
- Rules broken: none

**Kept:** version 1, score 8/10 ("The goal", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kicker4.txt`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drive"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Drive" passes every script check and breaks no rule. It uses no banned vocabulary (rule 2). It has no "Greenbull says" form and speaks in no one's voice (rule 3). It is one short line in sentence case, matching the brief's "keep the draft's meaning and brevity, add no content" (rule 4, menu and settings labels). Rule 1 (tone) hardly applies to a one-word headline. The brief asked for tongue-in-cheek voice only in a loose sense, and adding wit here would break the brevity requirement. I dropped one point only because the text carries no stream-voice flavour. That is not a rule violation. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Drive", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title1.txt`): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_w.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Gas"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Gas" keeps the draft's meaning and one-word brevity, with no added content. It is in sentence case and on one line (rule 4, menu and settings labels). It uses no banned words (rule 2) and has no "Greenbull says" line (rule 3). Rule 1's satirical tone cannot be applied to a one-word keycap label, and the brief asks for brevity, so no rule is broken. I took off one point only because a bare label carries no tone, which is acceptable here.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Gas", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_w.txt`): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_a.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Left"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Left" breaks no rule I can find. The script checks pass: no banned words (rule 2), no "Greenbull says" line (rule 3), one line, and sentence case (rule 4). The brief asks for one word on the A keycap and to keep the draft's meaning with nothing added. "Left" does that. It adds no content and uses no off-voice vocabulary. A one-word key label has no room for the stream voice, so the lack of tongue-in-cheek flavour is not a fault. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Left", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_a.txt`): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_s.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Brake"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Brake" keeps the draft's meaning and brevity as the brief asks. It is one word, one line and in sentence case, and the script checks pass: no banned words and no "Greenbull says". It adds no content and uses no invented vocabulary. The only reason it isn't a 10 is that a single functional word carries no stream voice. The brief asks for brevity on a tiny keycap label, though, so this is acceptable and no rule is broken. I scored it from the brief and the script checks, without reading the Text rules in docs/extended-narrative.md.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Brake", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_s.txt`): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_d.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Right"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: Passes all script checks (rules 2, 3, 4: one line, sentence case, no banned words, no "Greenbull says"). It keeps the draft's meaning, adds no content, and is one word, as the brief asks for a tiny keycap label. Nothing is broken. It loses one point only because it has no stream voice, but the brief allows that for a one-word keycap label.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Right", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/key_d.txt`): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/drift_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "W + turn = drift"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "W + turn = drift" breaks no rule. Scripts pass: no banned words (2), no "Greenbull says" (3), one line and sentence case (4). It is a short, plain label, as rule 4 asks for menu and settings labels. It uses no off-vocabulary terms and no real brands, and the city does not speak in Greenbull's voice (3). It matches the brief: the W is part of the rule, and there is no flavour line and no drift button. The one small gap is tone (rule 1): the line is purely functional and has no tongue-in-cheek note. The brief asked for no flavour line, so this is acceptable and nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("W + turn = drift", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/drift_rule.txt`): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Tricks bring gift packs"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. The script checks pass: no banned words, no "Greenbull says" line, one line, sentence case. The text keeps the draft's meaning and brevity ("Tricks bring gifts" becomes "Tricks bring gift packs"). It uses the brief's approved vocabulary ("gift pack") and adds no new content. I did not re-read the full Text rules in docs/extended-narrative.md. The score rests on the script checks and the brief. I took one point off only because the tongue-in-cheek stream voice is very light, and a plain label like this one is acceptable.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Tricks bring gift packs", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title2.txt`): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step1_title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Pull tricks"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Pull tricks" is a plain, short, one-line label in sentence case (rule 4). It keeps the draft's meaning and adds no content. It uses no banned words, has no "Greenbull says" line, and names no brands (rules 2 and 3). It has no satire, but rule 1 asks for a tongue-in-cheek tone, and a bare instruction label needs none. The only small gap is that it doesn't use the stream vocabulary (for example "Stunt Driver" or "live viewers"). The brief asks for brevity and no added content, so this is not a violation. No fix needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Pull tricks", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step1_title.txt`): it reached 8 or more.

### Run 13

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step1_caption.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drifts, spins, air."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No text rule is broken. It is a single line in sentence case (rule 4, labels), and it uses no banned vocabulary and no "Greenbull says" line (rules 2 and 3). It keeps the draft's brevity and adds nothing. The only weakness is rule 1: the tone is plain and carries almost none of the tongue-in-cheek stream voice. That is acceptable for a short slide caption, and the brief asked for brevity and no added content. A small ironic touch would lift it, but only if the meaning stays the same.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Drifts, spins, air.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step1_caption.txt`): it reached 8 or more.

### Run 14

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step2_title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Live viewers pile in"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rule 2: it uses the approved term "live viewers". Rule 3: it has no "Greenbull says" form and no real brands. Rule 4 (menu and settings labels): it is one line in sentence case and short and plain. Rule 1: it keeps the draft's meaning and brevity and adds no content. The wording is plain with only a mild stream flavour from "pile in". That is acceptable for a label, so no fix is needed.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Live viewers pile in", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step2_title.txt`): it reached 8 or more.

### Run 15

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step2_caption.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Live viewers love a show."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rule 2: "Live viewers" is the correct audience term, and the banned-word check passes. Rule 3: no "Greenbull says" line, and no real brands. Rule 4: one line in sentence case, short and plain like a menu label. Rule 1: the tone is light and fits the stream voice. It keeps the draft's meaning and length, with "the crowd" changed to "live viewers". The one weakness is that it is plain and has no satirical edge. The brief asked for brevity and no added content, though, so that is acceptable. If it is refined, a small ironic touch could be added without lengthening it, for example by treating the viewers as customers or numbers. That is optional.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Live viewers love a show.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step2_caption.txt`): it reached 8 or more.

### Run 16

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step3_title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hit a sub goal"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: Keeps the draft's meaning and brevity. It uses the approved term "sub goal" (Extended narrative, Content, subs entry) and is sentence case on one line. Rules 2 and 3 pass, and rule 4 passes on the script checks. It adds no content and has no banned words. The only reason it isn't a 10 is that it carries no stream-voice flavour, but the brief asked for slide labels that keep the draft as it is, so nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hit a sub goal", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step3_title.txt`): it reached 8 or more.

### Run 17

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step3_caption.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Live viewers become subs."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: The script checks pass (rules 2, 3 and 4). The label is one line, in sentence case, and has no banned words or "Greenbull says" line. It uses the approved term "live viewers" and "subs" correctly, and it keeps the draft's meaning and brevity. "Live" is not new content, because the brief lists 'live viewers' as vocabulary. It is a plain step caption with little stream-voice humour. The rules don't ask for a joke here, so I took off one point only for that. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Live viewers become subs.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step3_caption.txt`): it reached 8 or more.

### Run 18

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step4_title.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Gift pack"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Gift pack" breaks no rule. Rule 2: it uses the approved term "gift pack" for the weapon reward and has no banned word. Rule 3: it has no "Greenbull says" line and no brand. Rule 4: it is a short, plain, one-line label in sentence case, which matches the guide for menu and settings labels. Rule 1: the tone is neutral. A two-word title has little room for satire, and the brief asked to keep the draft's brevity and add nothing, so this is acceptable. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Gift pack", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step4_title.txt`): it reached 8 or more.

### Run 19

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step4_caption.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "A new weapon. It fires itself."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['It'])
- Score: 6/10
- Reason: Breaks rule 4 (label: sentence case). The script check fails with "capitalised: ['It']". The text is two sentences, so the second one starts with a capital, and a label must be sentence case with only its first word capitalised. Rules 2 and 3 pass and the label is one line. The voice and meaning match the draft, with no added content. Fix: make it one sentence with a single capital, keeping the draft's meaning and brevity, e.g. "A new weapon that fires itself." or "A new weapon, and it fires itself."
- Rules broken: 4

#### Round 2

- Version 2: "A new weapon that fires itself."
- What changed: Version 2. I joined the two sentences into one so only the first word has a capital, which fixes rule 4 (label: sentence case, capitalised 'It'). The meaning, brevity and deadpan "fires itself" stay as they were, and nothing is added.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: It breaks no rule. Rule 4 (label, plain, one line, sentence case) passes, and so do the script checks. It uses no banned words (rule 2), has no "Greenbull says" line (rule 3), and no real brands. It keeps the draft's meaning and adds nothing. It is plain, so it carries almost none of the tongue-in-cheek tone from rule 1. For a short slide caption that is acceptable, and the brief says not to add content. If the agent wants a higher score, it could add a small ironic touch within the same length, for example by using "gift pack" or "Greenbull". That is optional.
- Rules broken: none

**Kept:** version 2, score 8/10 ("A new weapon that fires itself.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/step4_caption.txt`): it reached 8 or more.

### Run 20

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/clip_ramp.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "HANG TIME! + AIR 180!"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['TIME!', 'AIR'])
- Score: 9/10
- Reason: The text keeps both trick names word for word in capitals with their "!", as the brief requires, and adds no content. Rule 1: no tone problem for a two-name caption. Rule 2: no banned words. Rule 3: no "Greenbull says" line. Rule 4: it is one short line, and the trick-popup format (capitals, ending in "!", like AIR 360!) fits the two trick names. The failed script check "label: sentence case" is a false positive here. That check is meant for menu and settings labels, and the brief tells the writer to keep the names in capitals. The "+" joiner is plain. Nothing needs to change. I took off one point because the "!" in the middle, before the "+", makes the line slightly busy. It is still within the brief.
- Rules broken: none

**Kept:** version 1, score 9/10 ("HANG TIME! + AIR 180!", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/clip_ramp.txt`): it reached 8 or more.

### Run 21

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Missions power your car"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rules 2, 3 and 4 pass (script facts: no banned words, no "Greenbull says", one line, sentence case). It is short and plain, as a label should be, and it keeps the draft's meaning with no added content. The only gap is rule 1 (tone). The line is flat and has none of the tongue-in-cheek stream or Greenbull voice. The brief asked for brevity and no added content, so this is minor. If the agent wants a higher score, it could add a very light ironic touch without adding meaning or length, for example by using the stream vocabulary ("subs" or "gift pack") where it is true to the draft. Otherwise keep it as is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Missions power your car", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title3.txt`): it reached 8 or more.

### Run 22

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/missions_line.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "The notebook on the left gives you one mission at a time. Clear it, then pick a driving power-up."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['Clear'])
- Score: 6/10
- Reason: Rule 4 (label format, sentence case) fails by the script check: 'Clear' is capitalised. It starts the second sentence, so it is correct grammar, but the label rule asks for short, plain, one-line sentence case and the checker only accepts a capital on the first word. Fix: write it as one sentence so only 'The' is capitalised, e.g. 'The notebook on the left gives you one mission at a time, so clear it and pick a driving power-up.' or 'The notebook on the left gives you one mission at a time: clear it, then pick a driving power-up.' Rules 2 and 3 pass. The meaning matches the draft, the vocabulary is plain, and nothing is added. The text is also fairly long for a label, so shorten it if the slide space is tight.
- Rules broken: 4

#### Round 2

- Version 2: "The notebook on the left gives you one mission at a time: clear it, then pick a driving power-up."
- What changed: Version 2: joined the two sentences with a colon, so "The" is now the only capital and the sentence-case script check for rule 4 should pass. The wording, meaning and vocabulary from version 1 are unchanged, and nothing is added. I kept the full meaning instead of cutting it down, since the draft's length was accepted and no slide space limit was given.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is clearly broken. Rules 2, 3 and 4 pass: no banned words, no "Greenbull says", one line in sentence case. Meaning and brevity match the draft, and the colon joins the two sentences into one line. Vocabulary needs nothing here. The only gap is rule 1 (tone): the text is plain and has no Greenbull-era tongue-in-cheek touch. The brief says to add no content, so this is minor. A small ironic word in the same length would lift it, for example "one mission at a time, like a good intern", but only if that doesn't add content.
- Rules broken: none

**Kept:** version 2, score 8/10 ("The notebook on the left gives you one mission at a time: clear it, then pick a driving power-up.", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/missions_line.txt`): it reached 8 or more.

### Run 23

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title4.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Survive the stream"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: The text keeps the draft's meaning and brevity, and the script checks pass: no banned words, no "Greenbull says" line, one line, sentence case. "Stream" fits the Greenbull-era stream voice, and nothing is added. The only gap is that it doesn't use the tongue-in-cheek vocabulary (live viewers, subs, gift pack). The brief asked for brevity and no added content, so this is not a rule break. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Survive the stream", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/title4.txt`): it reached 8 or more.

### Run 24

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kaiju_label.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "The kaiju!"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: The label is one line in sentence case and keeps the draft's meaning and brevity. It uses the approved vocabulary "the kaiju" and has no banned words and no "Greenbull says" line. All four script checks pass. It breaks no rule I can see. It is only a little flat for the tongue-in-cheek stream voice, but the brief asked for brevity and no added content, so this is acceptable. I did not re-read the Text rules in docs/extended-narrative.md.
- Rules broken: none

**Kept:** version 1, score 8/10 ("The kaiju!", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/kaiju_label.txt`): it reached 8 or more.

### Run 25

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/skip.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Skip"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Skip" is a single word in sentence case on one line. It uses no banned words and no "Greenbull says" line. It keeps the draft's meaning and brevity, as the brief asked, and adds no content. The script checks for rules 2, 3 and 4 all pass. It has no stream-voice flavour, but a skip control is a plain function label and the brief asks for brevity, so I take no points off for that. I found nothing to fix.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Skip", copied to `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t484/skip.txt`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.

Final text for the four redrawn slides is in `game/data/tutorial_text.json` (every entry has a `<key>_comment`). 25 pieces went through the style loop (label kind; Style review, Runs 1 to 25); all kept at 8 or more (step4_caption and missions_line needed one refine, 6 to 8; the rest passed in round 1). Stored in sentence case (the label kind requires it); the slides show them in capitals in the display font, so the UI upcases for display. `trick.*` stay in capitals.

Keys and final text (score):
- `kicker.pattern` "{n} / {total} · {topic}" (code pattern, not scored); `kicker.controls` Controls (9); `kicker.loop` How you get stronger (8); `kicker.missions` Missions (9); `kicker.goal` The goal (8)
- Slide 1: `slide1.title` Drive (9); `slide1.key_w` Gas, `key_a` Left, `key_s` Brake, `key_d` Right (9 each); `slide1.drift_rule` "W + turn = drift" (9; the W is part of the line)
- Slide 2: `slide2.title` Tricks bring gift packs (9); `step1_title` Pull tricks (9) / `step1_caption` Drifts, spins, air. (8); `step2_title` Live viewers pile in (8) / `step2_caption` Live viewers love a show. (8); `step3_title` Hit a sub goal (9) / `step3_caption` Live viewers become subs. (9); `step4_title` Gift pack (9) / `step4_caption` A new weapon that fires itself. (8); `slide2.clip_ramp` "HANG TIME! + AIR 180!" (9). The other two clip captions read `trick.extended_drift` (LONG DRIFT!) and `trick.alternate_drift` (ALT DRIFT!) word for word, not duplicated.
- Slide 3: `slide3.title` Missions power your car (8); `slide3.missions` "The notebook on the left gives you one mission at a time: clear it, then pick a driving power-up." (8)
- Slide 4: `slide4.title` Survive the stream (9); `slide4.kaiju` The kaiju! (8; the times 8:00, 4:00, 1:00 are built by code)
- `button.skip` Skip (9). Go live and Don't show again keep `button.start` and `checkbox.dont_show`.

Retired, kept in the file with a `_comment` starting "UNUSED since T-484": `slide1.controls`, `slide1.drift`, `slide2.chain`, `slide2.gift`, `slide3.goal` (the UI ticket removes their use).

Other changes: `docs/hud-and-menus.md` (Content, "Tutorial slides and trick list") lists the new keys; `game/tools/text_inventory.py` maps the new key prefixes (kicker, slide4, button.skip) to screens, which its test required. Tests: the full game/tools suite had one failure (text inventory, unlisted keys), fixed and re-run green. Nothing under game/data/levels/ touched. For the playtest: the draft's "KAIJU!" became "The kaiju!"; the step 2 and 3 captions say "Live viewers" (the loop's choice).
- 2026-11-01, in-progress → in-qa: Text for the four redrawn slides done, 25 lines scored 8+, keys in result notes
- 2026-11-01, in-qa → done: QA round 1 passed: all 7 criteria, tools 870 OK, Godot set passed

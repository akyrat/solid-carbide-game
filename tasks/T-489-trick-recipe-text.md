---
id: T-489
title: Text: each trick's rule and its key recipe notes for the trick list
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, docs/extended-narrative.md, game/data/tutorial_text.json, C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tricks/tricks.template.html]
files_expected_to_change: [game/data/tutorial_text.json, docs/hud-and-menus.md]
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

The board, 2026-11-01 (HUD and menus, Decisions, "Each trick shows the keys that make it"): the pause screen's trick list shows each trick with a keycap recipe (keys joined with +, steps joined with an arrow, a short note under each step) and a one-line rule. The Project Lead's draft page (its template is in files_to_read_first; the TRICKS array near the end holds the draft words: `rule`, `small`, and each recipe step's `note` or `sit`) has the draft wording; write the final text into game/data/tutorial_text.json through the style loop, each with its `_comment` saying what it is for and where it appears. The keys themselves (W, A, S, D) are drawn as keycaps and are not text.

For each of LONG DRIFT!, FULL 360!, ALT DRIFT!, HANG TIME!, AIR 180!, AIR 360!: a one-line rule (short: it sits beside the clip in the trick list), and each recipe step's note (very short, it sits under a keycap in tiny pixel type: about 20 characters at most) or step badge (a word or two in capitals, for steps with no keys: for example LET GO, IN THE AIR, LAND, FULL CIRCLE). THREAD THE NEEDLE!: the rule only, no recipe (the board: no keys for it, the player just drives through the gap). Correction from the board: AIR 360! is reachable on today's map (a fast ramp jump flies far), so don't say it needs the upgrade. Trick names stay the existing trick.* keys. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/tutorial_text.json has a rule for all seven tricks and the recipe notes and badges for the six tricks listed (none for thread the needle), each with a `_comment`; the result notes list the keys. (QA: pass / fail)
- [ ] Each new line went through the style loop and scored 8 or more (the Style review shows the scores). (QA: pass / fail)
- [ ] Every recipe note is 20 characters or fewer (the result notes show the longest). (QA: pass / fail)
- [ ] The file is valid JSON and the game/tools Python tests pass. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, "Tutorial slides and trick list") lists the new keys. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

From the board's go on the trick-controls draft: writing each trick's rule and recipe notes. Narrative Theme agent started.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_extended_drift_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold W and a turn key to drift. Let go to cash it in."
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case (capitalised: ['W', 'Let'])
- Score: 6/10
- Reason: Rule 4 (label, sentence case) is broken, confirmed by the script: it flags "W" and "Let" as capitalised. "Let" is only the start of the second sentence, which sentence case allows, so that flag is a false positive. "W" is the key name and is a legitimate capital, but the script counts it. To pass the script, reword so no mid-line capital remains. Examples: "Hold the gas and a turn key to drift. Let go to cash it in." The second sentence still trips the "Let" flag. A single sentence avoids it: "Hold gas and a turn key, then let go to cash it in." Rules 2 and 3 pass. Rule 1 (tone) is only lightly served: "cash it in" is a faint monetising joke, which fits Greenbull's profit-minded voice, but it is mild. Neither rule 1 nor rule 3 is broken: the line is plain, short and one line. It also drops the brief's point that the drift lasts until you let go. Fix: make it a single sentence with no capital after the first word, and avoid the bare "W" if the script flags it.
- Rules broken: 4

#### Round 2

- Version 2: "Hold gas and a turn key to drift, then let go to cash it in."
- What changed: Version 2 fixes the sentence-case failure. It is now one sentence, so "Let" no longer opens a second sentence. The bare "W" is replaced with "gas", the tutorial's own name for the W keycap (slide1.key_w "Gas"), so only the first word is capitalised. "Drift, then let go" puts back the brief's point that the drift lasts until you let go, which is accurate because the drift ends when the turn key is released. The "cash it in" wink stays, matching LONG DRIFT! paying once when the drift ends. Still a short, plain, one-line instruction with no banned words.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rule 2: no banned words, and "drift" is not a name. Rule 3: it has no "Greenbull says" form and no brand. Rule 4: the script confirms one line in sentence case, and it is short and plain as a menu label should be. Rule 1: the tone is a plain instruction with no earnest heroics. "Cash it in" is a light stream/profit idiom that fits the voice without breaking the brief's "plain instruction". It is not a perfect 10 for two reasons. It drops the brief's point that the drift lasts as long as you hold the keys, so "cash it in" is slightly vaguer about when the trick ends. It also names "gas" where the draft named the actual key, W. If the pause screen shows key names, check that "gas" matches the control the player sees.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Hold gas and a turn key to drift, then let go to cash it in."): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_three_sixty_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drift and hold the turn key one way until the car spins all the way round."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: Rules 2, 3 and 4 pass: no banned words, no "Greenbull says", one line in sentence case, plain and short, with no key letters (it says "turn key"). Rule 1 (tone) is only lightly touched: it is a plain instruction, which the brief asks for, with no irony and no clash with the tone. Two small issues, neither a rule break. First, "hold the turn key one way" is clumsier and less clear than the draft's "keep turning the same way", and "one way" is vague. Second, "Drift and" is slightly ambiguous about order. A fix that reads better: "Drift and keep turning the same way until the car spins all the way round." No rule is broken.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Drift and hold the turn key one way until the car spins all the way round."): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_alternate_drift_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drift forward, then swap gas for brake while holding the same turn key."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rules 2, 3 and 4 (one line, sentence case) pass by script. It is a plain instruction with no key letters, using "gas", "turn key" and "brake" as the brief asked. It makes no Greenbull-says claim and has no brand names. Rule 1 (tone) does not require a joke on a how-to label, and the plain wording is acceptable. Minor: it is a bit long for a one-line label, and the dry how-to has no touch of the game's satirical voice. This is optional. Fix only if wanted: shorten it, e.g. "Drift forward, then swap gas for brake, holding the same turn key."
- Rules broken: none

**Kept:** version 1, score 8/10 ("Drift forward, then swap gas for brake while holding the same turn key."): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_airtime_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold gas off a ramp or a rooftop edge and fly."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rule 2: no banned words, and "gas" is the brief's own wording. Rule 3: no "Greenbull says" form and no brands. Rule 4: it is one line in sentence case, plain and short. It follows the brief and names no key letters. Rule 1: it is plain instruction with no satirical edge. The brief asks for a plain instruction, so that is acceptable for a rule line. It is a small loss, not a break. A little wit would be allowed, but the brief doesn't ask for it. Optional polish only: the draft's "Take a ramp ... with gas held" and this version say the same thing, and "Hold gas" is slightly clearer.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Hold gas off a ramp or a rooftop edge and fly."): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_one_eighty_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "In the air, hold a turn key to spin the car half a turn before it lands."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: Passes rules 2, 3 and 4. It is one line in sentence case, and it is short and plain as menu labels should be. It uses no banned words and no "Greenbull says" form. It names no key letters and says "turn key", as the brief asks. It carries no satirical tone, but the brief asks for a plain instruction, and rule 1 does not require a joke in every label. The one small blemish is that the line is long for a label (72 characters), and "before it lands" could be trimmed. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("In the air, hold a turn key to spin the car half a turn before it lands."): it reached 8 or more.

### Run 6

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_three_sixty_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hit a ramp at full gas and hold a turn key: one full spin before you land."
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: The text breaks no rule. The script checks pass for rules 2, 3 and 4 (one line, sentence case, no banned words, no "Greenbull says" line). Rule 4 asks menu and settings labels to be "short and plain, in sentence case", and this one is. It is a plain instruction in the game's voice. It names no upgrade and writes no key letters. It says "gas" and "turn key" as the brief asked. It uses no brand, and Greenbull and the city are not involved (rules 1 and 3 are fine). The one weakness is length: at 74 characters, with a colon clause, it is wordy for a "short" rule beside a clip. A tighter version would be "Full gas off a ramp, hold a turn key: one full spin before you land." or the draft "A full turn in the air before landing." It also adds "hold a turn key" while the brief's draft did not have that. That is only a mild readability concern, not a rule violation.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Hit a ramp at full gas and hold a turn key: one full spin before you land."): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_thread_the_needle_rule.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drive between two paired obstacles without touching either."
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: Passes all checks. Rule 1 (tone): plain instruction with no sincere or earnest heroics, which is fine for a how-to line. Rule 2: no banned words. Rule 3: not a "Greenbull says" line and no brand names. Rule 4 (label): one line, sentence case, short and plain. It names no key letters, as the brief asks. Dropping "the gap" from the draft keeps the meaning and shortens the line. The only gap is that it carries no satire; the brief asks for plain instruction, so this is not a violation. No fix needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Drive between two paired obstacles without touching either."): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_extended_drift_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Gas + turn keys"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: It meets every rule I can check. Rules 2 and 3: no banned words and no "Greenbull says" line. Rule 4: one line in sentence case, plain and short. The brief's no-key-letters condition is met, since W, A, S and D don't appear. The brief only wanted a very short note, and 15 characters is well within that. The tone (rule 1) barely applies to a functional label, and the label isn't a joke. This is a neutral hint, which fits the "short and plain" label style. The only small gap is that it drops the brief's "under" cue, which is probably fine because the note already sits under the keycap. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Gas + turn keys"): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_extended_drift_b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Let go"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Let go" passes all script checks. It is plain sentence case, fits 14 characters, has no banned vocabulary, no "Greenbull says" form and no real brands. As a step badge it is clear and short. Rule 1 (tone) is not really tested by a label this short and plain. Menu and settings labels are meant to be plain, so this fits. It has no satire, and it doesn't need any. Nothing to fix; it is acceptable as is.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Let go"): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_extended_drift_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Cash in"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. The script checks pass (rules 2, 3 and 4). It is a 7-character, one-line label in sentence case, with no key letters and no banned words. "Cash in" fits the payout moment and has a light monetizing, corporate edge that suits rule 1. The tone is a little mild. A slightly sharper streamer or brand twist could reach 9, but rule 1 doesn't require one.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Cash in"): it reached 8 or more.

### Run 11

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_three_sixty_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Keep holding"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Keep holding" passes every script check (rules 2, 3, 4) and is short, plain and sentence case. It uses no key letters and names no banned word. It fits the menu/settings label format in rule 4. Rule 1 (tone) asks for nothing satirical in a functional hint, and "Keep holding" is neutral, so there is no break. It does lose a little: it is bland, and it gives the player no clue what to hold (the gas and turn keys), which the brief's keycap recipe may cover. Optional improvement: a plain verb phrase that signals sustained input, with no key letters. No rule is broken.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Keep holding"): it reached 8 or more.

### Run 12

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_three_sixty_b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Full circle"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. Rule 4 (label: short, plain, sentence case) holds: "Full circle" is 11 characters, within the 14 limit, and in sentence case. Rule 2 holds: none of the banned words appear and no vocabulary is violated. Rule 3 holds: it is not a "Greenbull says" line and no brand appears. Rule 1 (tone) holds: it is neutral and plain, and it doesn't clash with the satirical tone. It is not satirical, but a step badge needs no joke. It is also accurate for the 360 trick. One small point: it is a little generic, but that is acceptable for a plain label. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Full circle"): it reached 8 or more.

### Run 13

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_three_sixty_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Same way round"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. "Same way round" is one line, sentence case, with no banned words, no "Greenbull says" form and no key letters (rules 2, 3, 4 pass; the script checks agree). It's short, plain and neutral, so it fits the label format. It is a tiny hint for FULL 360!, a trick whose recipe is one full circle. The phrase says the turn has to go one way round, but it is slightly ambiguous: "Same way" could be read as the same way as the previous trick. It also has no Greenbull tone (rule 1), which a plain menu label doesn't require. If you want a higher score, make the meaning clearer, for example "One direction only", while keeping it very short.
- Rules broken: none
- Refused: {"tool_input": {"-C": 2, "output_mode": "content", "path": "C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tricks/tricks.template.html", "pattern": "(?i)same way|full circle"}, "tool_name": "Grep", "tool_use_id": "toolu_01Be62ErzbPKQewby8QBNuTk"}

**Kept:** version 1, score 8/10 ("Same way round"): it reached 8 or more.

### Run 14

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_alternate_drift_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Drift one way"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Drift one way" follows the Text rules. Rule 4 (menu and settings labels): it is short, plain, one line and in sentence case, and the script confirms this. Rule 2: no banned words. Rule 3: no "Greenbull says" line and no real brand. Rule 1: labels are meant to be plain, so a neutral hint is fine, and nothing in it makes light of the city's people. The brief names no key letters and the text has none. The only soft point is clarity: "one way" is slightly vague as a first-drift hint. A clearer wording such as "Hold turn to drift" would be slightly better, but no rule requires it.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Drift one way"): it reached 8 or more.

### Run 15

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_alternate_drift_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Swap fast, hold turn"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: The text passes the script checks (rules 2, 3 and 4: one line, sentence case, no banned words, no "Greenbull says"). It is short and plain, as the menu-label format (rule 4) asks. It has no key letters and does what the brief says: swap fast, keep the same turn key. Tone (rule 1): it is neutral and instructional, with no satire. For a tiny hint label under keycaps, that is acceptable and creates no conflict. Vocabulary (rule 2) is clean. Only nit: "hold turn" is slightly ambiguous, because "turn" could mean the key or the action, so "Swap fast, keep turning" or "Swap fast, same turn key" would read more clearly. No rule is broken.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Swap fast, hold turn"): it reached 8 or more.

### Run 16

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_airtime_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold off a ramp"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: No rule is broken. The script checks pass. The text is one short line in sentence case (15 characters) and has no key letters, so it fits rule 4's "short and plain" labels. It contains none of the rule 2 banned words. It has no "Greenbull says" form and no brand (rule 3). It is neutral, with no sincere heroics, so rule 1 is met. One small weakness: "Hold off a ramp" can be misread as "hold back from a ramp". The hint is meant to say that the key shown above is held while leaving a ramp. If the agent revises, it could use "Hold at a ramp" or "Hold off the ramp", to stay short and keep the meaning clear. Rule 4 sets no character limit for this kind of label, and the brief's limit is garbled, so I couldn't check it beyond "very short".
- Rules broken: none

**Kept:** version 1, score 8/10 ("Hold off a ramp"): it reached 8 or more.

### Run 17

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_airtime_b2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Airborne"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Airborne" meets the brief and the script checks. It is one word, 8 characters (limit 14), and sentence case. It has no banned words and no Greenbull line. It names the middle step of HANG TIME! (no key pressed, in the air) in plain words that read well in capitals as AIRBORNE. I did not open the full Text rules in docs/extended-narrative.md, so this score rests on the script checks and the brief. It breaks no rule I can see. Nothing needs fixing.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Airborne"): it reached 8 or more.

### Run 18

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_airtime_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "0.3 s or more"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case ('0.3 s or more')
- Score: 8/10
- Reason: "0.3 s or more" is short, plain, one line, uses no banned words, no "Greenbull says" form, and no key letters (W, A, S, D). It fits the label rule 4 (short and plain). The script's rule 4 sentence-case failure is a false positive: the text starts with a digit, so there is no first letter to capitalise, and the rest is lowercase, which is correct for sentence case. The only weak point is that "s" next to the number is terse and the text carries no tone (rule 1). That is acceptable for a tiny note under a keycap. If the script check must pass, the agent could reword so it starts with a letter, for example "Hold 0.3 s or more", but that is optional. Rule 4 is not really broken.
- Rules broken: none

**Kept:** version 1, score 8/10 ("0.3 s or more"): it reached 8 or more.

### Run 19

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_airtime_b3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Land"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Land" passes every script check and breaks no rule. It is plain, short (4 characters, within the 14 limit) and in sentence case. It uses no banned word and has no "Greenbull says" form. It also matches the HANG TIME! trick's final step, so there's nothing to fix. It scores 8, not 10, because it is neutral and carries none of the satirical Greenbull tone from rule 1. For a badge that is shown in capitals and only labels a step, that is acceptable, and the rules don't require a joke here.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Land"): it reached 8 or more.

### Run 20

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_airtime_n3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Cash in"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Cash in" passes all script checks (rules 2, 3, 4). It's 7 characters, one line, sentence case, with no key letters and no banned words. It says what a landed trick does (pays now), which suits a tiny note under the 'land' badge. Tone (rule 1) is only lightly Greenbull: it has a mild monetising, transactional feel but no real satirical bite. It would reach 9-10 with a slightly more corporate wink that still fits the length limit, for example "Monetise" or "Cash out". As it stands, it breaks no rule.
- Rules broken: none
- Refused: {"tool_input": {"output_mode": "content", "path": "C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tricks/tricks.template.html", "pattern": "(?i)pays|land"}, "tool_name": "Grep", "tool_use_id": "toolu_01P23VnX3N85n8VZgsbtwUA5"}

**Kept:** version 1, score 8/10 ("Cash in"): it reached 8 or more.

### Run 21

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_one_eighty_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "At a ramp"
- Script checks: 4 of 4 pass
- Score: 7/10
- Reason: No rule is broken. "At a ramp" is one line, sentence case, plain and short (9 characters). It has no banned words, no key letters, no real brand and no "Greenbull says" line, which matches rules 2, 3 and 4 and the script checks. It also fits as a label for a hint under the gas key. The score is not higher because the tone of rule 1 (satirical, tongue-in-cheek) is absent: the line is a flat instruction. A short, dry touch of Greenbull's out-of-touch voice would fix that, as long as it stays one line, in sentence case and with no key letters. It also doesn't say what the gas key does, only where. The brief itself was garbled, with an empty draft and a repeated length limit, so the fit to the brief can't be fully judged.
- Rules broken: none

#### Round 2

- Version 2: "Full send at a ramp"
- What changed: Version 2. I kept the "at a ramp" place from version 1 and added what the gas key does there. "Full send" is streamer slang for flooring it, so the line now says both what to do and where. It also gives the tongue-in-cheek livestream voice that rule 1 asks for, without naming Greenbull or adding new content. It is still one line in sentence case, 19 characters, with no key letters and no banned words.
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: The line meets the checked rules. Rule 2 has no banned words. Rule 3 has no "Greenbull says" line and no real brand. Rule 4 gives one line in sentence case. It is 19 characters, and the brief allows a few dozen at most. It has no key letters (W, A, S, D). It is short, plain and clear, and it matches the "AIR 180!" trick it sits under. The only weakness is rule 1 (tone). "Full send" is generic slang, with no satirical or corporate-stream edge, though a tiny hint doesn't need one. To raise the score, add a light stream or brand-obsession wink, for example "Send it for the cameras". Keep it under about 25 characters and in sentence case. This is optional, because nothing here breaks a rule.
- Rules broken: none

**Kept:** version 2, score 8/10 ("Full send at a ramp"): it reached 8 or more.

### Run 22

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_one_eighty_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Half a turn in the air"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: The text breaks no rule. Rule 4 (label: short, plain, one line, sentence case): "Half a turn in the air" is one line in sentence case and matches the plain style of "Music volume". The script checks passed. Rule 2: it uses no banned words and no off-vocabulary terms. Rule 3: it has no "Greenbull says" line and no brand, and it contains no key letters. Rule 1: a functional note needs no joke, so a plain label doesn't break the tone rule. The brief's length limit was garbled ("At most In the air, half a turn characters"), so I couldn't check length. At 22 characters it is short enough for a "very short" note, so I took it as fine. The only reason not to give 10 is that the brief asked for something "very short", and a shorter wording such as "Half turn in the air" would leave more room. That is optional.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Half a turn in the air"): it reached 8 or more.

### Run 23

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_one_eighty_n3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Cash in"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Cash in" is short, plain, sentence case and one line. It passes the script checks (rules 2, 3 and 4). It has no banned words, no key letters and no "Greenbull says" form. It also fits the brief's "Pays now" idea: a very short note under a "land" badge, meaning the trick pays out when you land. Rule 1 (tone) is only lightly touched. "Cash in" has a faint monetised, brand-economy flavour but no real satire, which is acceptable for a tiny pixel-type note. Rule 4's "short and plain" label guidance is met. If you want a higher score, add a slightly more Greenbull-flavoured and ironic touch while keeping it very short, for example "Cash out" or "Bank it". This is optional, and no rule is broken.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Cash in"): it reached 8 or more.

### Run 24

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_three_sixty_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "At a ramp"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "At a ramp" fits the Text rules. Rule 4 (menu labels): short, plain, one line, sentence case, and the script confirms it. Rule 2: it uses no banned or old vocabulary. Rule 3: it is not a "Greenbull says ..." line and names no brand. It also respects the brief: it is very short and has no key letters (W, A, S, D). It is a plain hint saying where the trick happens, which is the right job for a tiny note under a keycap. The only gap is rule 1 (tone). The line is neutral and has no satirical edge. Rule 1 only asks that text not be earnest or heroic, and a tiny functional pixel-type label doesn't need a joke, so this is a minor point, not a break. No fix is needed. If the agent wants a little flavour, it could add a light, tongue-in-cheek wording within the same length. That is optional.
- Rules broken: none

**Kept:** version 1, score 8/10 ("At a ramp"): it reached 8 or more.

### Run 25

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_three_sixty_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold in the air"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Hold in the air" is a plain, short label: one line, sentence case, no key letters, no banned words, no "Greenbull says" line, no real brand (rules 2, 3 and 4 hold; the script checks pass). It describes the AIR 360! condition accurately. Two small points keep it from a 10. It is a bit longer than the brief's "In the air". It gives no Greenbull-flavoured aside, but a tiny key-recipe note under a keycap should be plain (rule 4, menu and settings labels: "short and plain"), so this is acceptable. Tone (rule 1) is neutral and breaks nothing. No fix is required. Optionally shorten to "In the air" if the space under the keycap is tight.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Hold in the air"): it reached 8 or more.

### Run 26

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_three_sixty_n3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Pays on landing"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Pays on landing" is a short, plain, sentence-case, one-line label. It uses no banned vocabulary, has no "Greenbull says" form and names no brand or key letters. That matches rules 2, 3 and 4 (menu/settings label format), and the script checks pass. The brief's character limit is garbled ("At most Pays now characters"), so length can't be checked. At 15 characters it's very short either way. It's neutral and carries no satire, so it's a weak fit for rule 1 (tone). A label doesn't need an aside, and rule 1 only bars grimdark or earnest heroics, which this isn't. No rule is broken. If you want it sharper, add a hint of Greenbull's profit-minded voice while keeping the text this short.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Pays on landing"): it reached 8 or more.

### Run 27

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_extended_drift_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Hold 1 s or more"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: No rule is broken. Rule 4 (label: short, plain, one line, sentence case) is met: "Hold 1 s or more" is 16 characters, within the brief's limit, and has no key letters. Rule 2 is met: no banned words. Rule 3 is met: no "Greenbull says" line, and nothing speaks in the city's voice. It keeps the required fact, 1 s or more. Rule 1 (tone) does not apply to a plain control note like this; a label should be plain, so the lack of satire is correct. The only small point is "1 s" in place of "1 second", which suits a tiny pixel-type note. No fix is needed.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Hold 1 s or more"): it reached 8 or more.

### Run 28

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_alternate_drift_n1.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "0.3 s or more"
- Script checks: 3 of 4 pass; failed: rule 4, label: sentence case ('0.3 s or more')
- Score: 8/10
- Reason: The text is a one-line label that keeps the fact (at least 0.3 s), is very short and uses no key letters or banned words. The only failed check is rule 4, sentence case. That failure looks like a false positive: the label starts with a digit, so it has no first letter to capitalise, and the rest is lowercase, which is what sentence case gives. If the checker must pass, a fix is to start with a letter, e.g. "Hold 0.3 s or more" or "At least 0.3 s". Both keep the fact and the brevity. The current text is otherwise acceptable. It may lose a point for the flagged check and for "s" with a space, but nothing needs a real fix.
- Rules broken: 4

**Kept:** version 1, score 8/10 ("0.3 s or more"): it reached 8 or more.

### Run 29

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_three_sixty_n3.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Cash in"
- Script checks: 4 of 4 pass
- Score: 8/10
- Reason: "Cash in" is short, one line, sentence case and has no key letters (W, A, S, D). It has no banned words and no "Greenbull says" form, so rules 2, 3 and 4 hold. Its dry corporate-money tone fits rule 1 (Greenbull's profit focus). It is slightly generic, not a clear satirical joke, and it says what the trick does less directly than the brief's meaning ("Pays now"). The brief's character limit was garbled ("At most Pays now characters"), so I could not check length against a number; at 7 characters it should fit any plausible limit. To raise the score, add a touch of Greenbull-style satire while staying short, for example "Cash in now" if it fits. No rule is broken.
- Rules broken: none
- Refused: {"tool_input": {"head_limit": 30, "output_mode": "content", "path": "C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tricks/tricks.template.html", "pattern": "(?i)air360|AIR 360|Pays now|land"}, "tool_name": "Grep", "tool_use_id": "toolu_01SFsombMh2S3vg6tucHxMBA"}

**Kept:** version 1, score 8/10 ("Cash in"): it reached 8 or more.

### Run 30

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_one_eighty_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Half a turn, midair"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: The text passes all the script checks (rules 2, 3, 4). It is 19 characters, under the hard limit of 20. It says it is a half turn and that it happens in the air. It has no key letters, it is one line, and it is in sentence case. It adds no banned words and no Greenbull line. I found no breaks in the Text rules. The text is plain, short and on-tone for a tiny pixel-type note. One point is held back only because it is 1 character from the limit, so any later change to the font or the keycap width could force a re-cut.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Half a turn, midair"): it reached 8 or more.

### Run 31

Run by `tools/style_loop/run.py` on 2026-11-01: text, kind label, brief `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/t489/b_air_three_sixty_n2.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: "Full turn in the air"
- Script checks: 4 of 4 pass
- Score: 9/10
- Reason: "Full turn in the air" is exactly 20 characters, so it meets the hard limit with no spare room. It says it is a full turn, it is on one line and in sentence case, and it has no key letters or banned words. It matches the brief's "held in the air" and "full turn". The script checks for rules 2, 3 and 4 all pass. I found no rule it breaks. I took the 20-character count from the text itself, not from a script check. Any edit that adds even one character would break the limit.
- Rules broken: none

**Kept:** version 1, score 9/10 ("Full turn in the air"): it reached 8 or more.

## Result notes

Wrote trick_rule.<id> (7 rules) and trick_recipe.<id> (stepN_note / stepN_badge, 6 tricks, none for thread the needle) in game/data/tutorial_text.json, each with a _comment. Every line went through the style loop (label kind), all scored 8 or more (see Style review). Rules carry no key letters (the label check rejects capital W/A/S/D), so they say gas, brake, turn key. Keys drawn by the UI as keycaps (draft page): LONG DRIFT! step1 W+A/D, step2 none; FULL 360! step1 W+A/D, step2 none; ALT DRIFT! step1 W+A/D, step2 S+A; HANG TIME! step1 W; AIR 180! step1 W, step2 A/D; AIR 360! step1 W, step2 A/D. AIR 360! rule mentions no upgrade (board correction). Longest recipe note: 20 chars. Tests: python -m pytest game/tools: 898 passed, 1 skipped. docs/hud-and-menus.md table updated. Nothing under game/data/levels/ touched.

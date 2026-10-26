---
id: T-301
title: Text: the level-up screen, its cards and the garage, rewritten for Greenbull
status: in-qa
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

## Style review

Run by `tools/style_loop/run.py` on 2026-10-26: text, kind garage_desc, brief `art-archive/T-301/briefs/garage_damage_bonus.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

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

**Style loop note:** `run.py text` overwrites the `## Style review` section on each run, so that section shows only the last run (garage damage_bonus). All 11 runs happened (briefs in `art-archive/T-301/briefs/`); their rounds and scores are in the table below.

| Key | File / where it appears | Old | New (final) | Rounds, score | Numbers |
|---|---|---|---|---|---|
| levelup.title | game/scripts/ui/level_up_texts.gd, top of the level-up screen | Redgull Sent a Gift Pack! | Greenbull sent a gift pack! | 2 rounds, 8/10 | none |
| TITLE | game/scripts/menu/garage_screen.gd, garage title | Redgull Pit Stop | The Greenbull pit stop experience | 3 rounds, 8/10 | none |
| upgrade_gun.tier2.desc | level_up_texts.gd, gun tier 2 card | Two extra bullets per volley, 3 in all. Redgull calls it generosity. | Two extra bullets per volley, 3 in all. Greenbull's generosity, terms apply. | 1 round, 9/10 | 3 |
| upgrade_gun.tier6.desc | level_up_texts.gd, gun tier 6 card | Two more bullets per volley, 5 in all. Redgull is feeling generous. | Two more bullets per volley, 5 in all. Greenbull is feeling generous this quarter. | 1 round, 9/10 | 5 |
| upgrade_flamethrower.tier3.desc | level_up_texts.gd, flamethrower tier 3 card | Flame damage up 20%. Redgull calls it a spicy take. | Flame damage up 20%. Greenbull's marketing team is calling it a hot take. | 1 round, 9/10 | 20% |
| upgrade_molotov.tier2.desc | level_up_texts.gd, molotov tier 2 card | Fire radius up 20%. Redgull loves a big reveal. | Fire radius up 20%. Greenbull loves a big reveal. | 1 round, 8/10 | 20% |
| upgrade_molotov.tier4.desc | level_up_texts.gd, molotov tier 4 card | Molotov damage up 50%, to 3. Redgull calls it flavour. | Molotov damage up 50%, to 3. Greenbull calls it a limited edition. | 1 round, 9/10 | 50%, 3 |
| upgrade_molotov.tier8.desc | level_up_texts.gd, molotov tier 8 card | Throw 3 molotovs at once. Redgull sends its regards. | Throw 3 molotovs at once. Greenbull sends its regards. | 1 round, 8/10 | 3 |
| upgrade_wiper.tier3.desc | level_up_texts.gd, wiper tier 3 card | Wiper damage up 40%. Redgull calls it deep cleaning. | Wiper damage up 40%. Now marketed as a premium deep-cleaning experience. | 1 round, 9/10 (a first run kept "...Now marketed as a deep clean.", 9/10; the second run replaced it) | 40% |
| car_health | garage_screen.gd, garage upgrade row | +10 car health per level. Redgull says you'll be fine. | +10 car health per level. Greenbull is legally optimistic about your safety. | 2 rounds, 8/10 | 10 |
| damage_bonus | garage_screen.gd, garage upgrade row | +5% weapon damage per level. Redgull calls it synergy. | +5% weapon damage per level. Greenbull calls it high-impact brand alignment. | 3 rounds, 8/10 | 5% |

**`style_rules.py text` output:** every final text passes rule 2 (no banned words, Redgull included) and rule 3 (no "Greenbull says ..." line) and its length or case checks (`levelup.title`, garage `TITLE`, the six card texts run here and the wiper card: all `ok: true`). The two garage descriptions fail only one check, `garage_desc: names no number` (rule 4, T-268), and so does the old text they replace (the old car_health fails it too).

**Open questions for the board (proposals, nothing blocks):**
1. Extended narrative, Text rules, rule 4 says a garage description names no number, but the task (and today's garage text) keeps "+10" and "+5%". I kept the numbers as the task asks. If the rule should win, the descriptions become, for example, "More car health every level. Greenbull is legally optimistic about your safety."
2. Three texts still use a "Greenbull calls it ..." form (molotov tier 4, damage_bonus; the flamethrower one says "is calling it"). The script and the evaluator pass them, but it is close to the banned "Greenbull says ..." speech line. The old texts used the same form. If the board reads it as a speech line, those three need a plain aside.
3. The garage title is longer than a plain label ("The Greenbull pit stop experience", 33 characters); it passes the label checks. A shorter option is "Greenbull pit stop".
4. The loop's overwriting of the Style review section by each run is a tooling gap to pass to the Project Lead.

Refusals: none.

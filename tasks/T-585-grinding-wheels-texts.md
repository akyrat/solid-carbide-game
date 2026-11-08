---
id: T-585
title: Texts: the Grinding Wheels power-up
status: in-progress
from: project-lead
to: narrative-theme
lead: Rails
epic: power-ups
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, game/data/screen_texts.json]
files_expected_to_change: [game/data/screen_texts.json, docs/hud-and-menus.md]
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

Write the texts for Drifting, Decisions, "Grinding Wheels, a driving power-up", in the voice and length of the other driving power-ups' texts in game/data/screen_texts.json (for example Jump's name and tier lines): the name is the board's own, "Grinding Wheels" (no style loop for it); its tier 1 description for the gift card and the power-up overlay (the longer you grind, the hotter the sparks and the faster the launch), through the style loop. Use the same keys and places the other power-ups use, with _comment where the file has them; list them in the result notes for T-586.

The board's review: the Project Lead shows the texts with a screenshot; then in T-586's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The name and description exist in screen_texts.json in the same places as the other power-ups', listed in the result notes. (QA: pass / fail)
- [ ] The description scores 8 or more in the style loop, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists them. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-585/screenshots/ shows them as on a gift card. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: Narrative writes the Grinding Wheels texts.

## Style review

Run by `tools/style_loop/run.py` on 2026-11-08: text, kind card_desc, brief `C:/Users/andre/AppData/Local/Temp/claude/4933a5c551de0266/ac041598-2b19-4839-9304-391fb93c4750/scratchpad/brief.md`. Generator: narrative-theme (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: "Grind a rail: sparks heat up; a longer grind, a faster launch. Burns not covered."
- Script checks: 3 of 3 pass
- Score: 8/10
- Reason: No rule is broken. Rule 4 passes: it is 81 characters, under the 90 limit. It states what the card does first ("Grind a rail: sparks heat up; a longer grind, a faster launch"), then adds one short aside, as the card format requires. The aside "Burns not covered." is a deadpan corporate liability disclaimer, which fits rule 1 (mocking soulless corporate language, slightly unethical, never sincere). It does not make fun of the city's people. The text has no "Greenbull says" line (rule 3), no banned words and no real brands (rules 2 and 3). It matches the length and voice of the other power-up texts. The only weakness is that the plain part is terse. It never mentions releasing Space to launch, and "a longer grind, a faster launch" is a bit clipped. That is minor and not a rule break. If the agent wants to tighten it, "Grind a rail, release Space: longer grinds launch faster" would still leave room for the aside.
- Rules broken: none

**Kept:** version 1, score 8/10 ("Grind a rail: sparks heat up; a longer grind, a faster launch. Burns not covered."): it reached 8 or more.

## Result notes

Texts written. Name (board's own, no loop): power_ups.names.grinding_wheels 'Grinding Wheels'. Description (style loop, round 1, score 8, 3 of 3 script checks pass): power_ups.descriptions.grinding_wheels 'Grind a rail: sparks heat up; a longer grind, a faster launch. Burns not covered.' (82 chars, no slots, one tier so no descriptions_last_tier entry; describe() in power_up_screen.gd falls back to descriptions then). Keys for T-586: both in game/data/screen_texts.json under power_ups, same places as the other power-ups (names, descriptions; no _comment change needed). docs/hud-and-menus.md Content, 'Mission notebook and power-up texts', lists them. Screenshot: art-archive/T-585/screenshots/gift_card_grinding_wheels.png (the real overlay, with the Jump card temporarily swapped to the new texts for the shot, then restored; the icon shown is Jump's stand-in because grinding_wheels is not in power_ups.json until T-586). Tests: JSON parses; full run left to QA.

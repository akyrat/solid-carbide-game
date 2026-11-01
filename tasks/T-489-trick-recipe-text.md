---
id: T-489
title: Text: each trick's rule and its key recipe notes for the trick list
status: open
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

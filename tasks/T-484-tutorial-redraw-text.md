---
id: T-484
title: Text: the redrawn tutorial slides' headlines, labels and captions
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/data/tutorial_text.json, C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tutorial/tutorial-redraft.template.html]
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

- [ ] game/data/tutorial_text.json has every text listed in the description, each with a `_comment` saying what it is for and where it appears; the result notes list the keys. (QA: pass / fail)
- [ ] Each new line went through the style loop and scored 8 or more (the Style review in the ticket shows the scores). (QA: pass / fail)
- [ ] The clip captions reuse the trick names word for word from recap_text.json / tutorial_text.json trick.*. (QA: pass / fail)
- [ ] The retired keys are kept, marked unused, and listed in the result notes. (QA: pass / fail)
- [ ] The file is valid JSON and the game/tools Python tests pass (`python -m unittest discover -s game/tools -p "test_*.py"`). (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, "Tutorial slides and trick list") lists the new keys. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

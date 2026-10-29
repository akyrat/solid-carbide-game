---
id: T-356
title: Bad reactions burst out when the combo breaks
status: in-progress
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/reactions.gd, game/data/hud.json]
files_expected_to_change: [game/scripts/hud/, game/data/hud.json, game/tests/unit/hud/, game/docs/hud-and-menus/hud.md, docs/hud-and-menus.md, art-archive/]
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

The board's decision (HUD and menus, Decisions, "Bad reactions when the combo breaks", 2026-10-29): when a crash cuts the combo (the moment the COMBO BROKEN! popup shows and the live viewers counter flashes red, T-336), the stream reacts badly: a **burst of bad reactions** rises from the live viewers counter, in the same lane as T-351's floating reactions (the right side, over the counter's width, never into the middle). Six bad reactions: a **crying-laughing face**, a **thumbs down** (a dislike), a **face peeking between its hands**, and the Project Lead's three (the board left them to it): a **broken heart**, a **skull** and a **screaming face**. Proposals for the playtest, in `game/data/hud.json`: about 10 icons in a quick flow over about 1.5 seconds, a mix of the six, rising a little faster than the good floaters, same size and alpha as T-351's icons. Only a crash that cuts the combo starts it (the combo draining away doesn't, the same rule as the counter's red flash). Pause freezes them; a new run clears them; they count toward the on-screen cap.

**The icons:** placeholders drawn in code first (simple pixel shapes in the right colours; none of Greenbull's colours, Visual style, Content, "Rules", rule 6). The art is the linked art ticket, which swaps its icons in. No new text.

The board's review: play a run, build a combo and crash: the bad reactions burst up from the viewers counter.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A crash that cuts the combo starts a burst of bad reactions from the viewers counter's lane, once per crash; the combo draining away doesn't (tests). (QA: pass / fail)
- [ ] The burst mixes the six bad reactions, and its count, spread and speed come from `game/data/hud.json` (tests with a fixed seed). (QA: pass / fail)
- [ ] They start only on the right side over the viewers counter, are drawn under the HUD pieces, count toward the cap, freeze on pause and clear on a new run (tests). (QA: pass / fail)
- [ ] HUD and menus, Content and game/docs/hud-and-menus/hud.md describe it. (QA: pass / fail)
- [ ] A screenshot and a GIF of the burst after a crash are in `art-archive/<id>/screenshots/` and show the bad reactions rising on the right. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started overnight (build A, Stream reacts): the UI Agent is making the bad reactions burst when a crash cuts the combo, with placeholders.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

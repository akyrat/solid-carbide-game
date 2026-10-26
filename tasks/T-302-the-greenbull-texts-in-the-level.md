---
id: T-302
title: The Greenbull texts in the level-up screen, its cards and the garage
status: blocked
from: project-lead
to: ui
lead: Goal-G-006
epic: hud-menus
milestone: mvp
goal: G-006
user_facing_text: yes
changes_visuals: yes
depends_on: [T-301]
documents_affected: [docs/hud-and-menus.md, docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/visual-style.md, docs/hud-and-menus.md, docs/garage-design.md, game/README.md, game/scripts/ui/level_up_texts.gd, game/scripts/menu/garage_screen.gd, game/tests/unit/test_level_up_screen.gd, game/tests/unit/test_garage_screen.gd]
files_expected_to_change: [game/scripts/ui/level_up_texts.gd, game/scripts/menu/garage_screen.gd, game/tests/unit/test_level_up_screen.gd, game/tests/unit/test_garage_screen.gd, docs/hud-and-menus.md, docs/garage-design.md]
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

Put D4's Greenbull texts in the game, word for word, in level_up_texts.gd, garage_screen.gd and any other file D4 lists. Use no wording of your own; if a text you need isn't in D4, stop and say so in the result notes. Update the tests that check the level-up title and the garage title to the new texts. Where HUD and menus or Garage design quote the old titles, replace them with the new ones. Take screenshots with the screenshot tool (game/README.md): the level-up screen with at least one card naming Greenbull (if D4 has one) and the garage screen, in art-archive/<this ticket>/screenshots/.

The board's review: play a run to a level-up and open the garage: read the new Greenbull titles and card and garage descriptions.

## Acceptance criteria

- [ ] level_up_texts.gd and garage_screen.gd (and any other file D4 lists) hold D4's texts word for word for every key D4 lists. (QA: pass / fail)
- [ ] `git grep -i redgull game/scripts game/scenes game/data` finds no player-facing text (any match left is a code comment, listed in the result notes for the code sweep ticket). (QA: pass / fail)
- [ ] test_level_up_screen.gd checks the new level-up title and test_garage_screen.gd checks the new garage title, and both pass. (QA: pass / fail)
- [ ] Screenshots of the level-up screen (with at least one card naming Greenbull, if D4 has one) and of the garage screen are in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] HUD and menus and Garage design quote no old Redgull title. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

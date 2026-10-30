---
id: T-433
title: Art: the splash cover behind the main menu (PixelLab)
status: blocked
from: project-lead
to: asset-generation
lead: Goal-G-008
epic: art
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: yes
depends_on: [T-432]
documents_affected: [docs/visual-style.md, game/docs/hud-and-menus/main-menu.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md, game/scripts/menu/main_menu.gd, game/tools/pixellab_client.py, game/tools/style_rules.py]
files_expected_to_change: [game/art/menu/splash.png, game/art/menu/splash.json, docs/visual-style.md, game/docs/hud-and-menus/main-menu.md]
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

Goal G-008, Visual style, Decisions, 'The splash cover': make the splash cover behind the main menu with PixelLab, as Visual style describes it, through the style loop, judged on consistency with the game's style, palette and car. D7 built the menu's slot: put the kept image at game/art/menu/splash.png with its record, and the menu shows it. Write the planned PixelLab calls and their cost in the result notes before the first call; at most 20 generations within the goal's art cap. Keep the title and buttons readable over it. Greenbull's colours only on Greenbull's things. Keep every rejected generation in art-archive/<id>/.

The board's review: Open the main menu with the splash cover behind it, and look at the enlarged image and the sampled compositions.

## Acceptance criteria

- [ ] game/art/menu/splash.png exists with its record, and a screenshot shows the main menu with it behind the title and buttons, which stay readable. (QA: pass / fail)
- [ ] The planned PixelLab calls and their cost are in the result notes before the first call's log line; at most 20 generations were used, all listed. (QA: pass / fail)
- [ ] It went through the style loop, with every round in the Style review, scoring at least 8 or noted below 8 after 3 refines; python game/tools/style_rules.py finds no Greenbull colour outside Greenbull's things. (QA: pass / fail)
- [ ] docs/visual-style.md and the art docs under game/docs/ record it; rejected generations are in art-archive/<id>/. (QA: pass / fail)
- [ ] The image enlarged, the sampled compositions, and a screenshot of the main menu with it are in art-archive/<id>/screenshots/. (QA: pass / fail)
- [ ] python -m unittest discover -s game/tools -p "test_*.py" passes, with the count in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

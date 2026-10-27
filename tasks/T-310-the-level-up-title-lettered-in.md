---
id: T-310
title: The level-up title lettered in cream with a dark outline, to read on a dark green ribbon
status: in-progress
from: project-lead
to: ui
lead: Goal-G-006
epic: hud-menus
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/README.md, game/scripts/ui/level_up_screen.gd, game/tests/unit/test_level_up_screen.gd, game/tools/build_level_up_art.py, tasks/T-303-art-the-level-up-screen-in.md]
files_expected_to_change: [game/scripts/ui/level_up_screen.gd, game/tests/unit/test_level_up_screen.gd, docs/hud-and-menus.md, game/README.md, art-archive/]
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

The docs say the level-up screen is in Greenbull's dark green leading, with light green and a little yellow (Visual style, Decisions, 'Greenbull's look'; Content, Rules, rule 6). T-303's header ribbon has a light green centre field under the black title. Light green leads the screen's art, so the goal check failed. The art ticket that depends on this one makes the ribbon's field dark green. Black ink won't read on it, so the title has to change first.

In level_up_screen.gd, give the ribbon's title label (TitleLabel, levelup.title) a cream font colour, RGB 246, 250, 232 (CREAM in build_level_up_art.py), and a dark outline in the art's outline colour, RGB 14, 22, 18, a few pixels thick, like the comic lettering elsewhere. Only the title changes. The card titles, descriptions and buttons keep their black ink on the cream cards. The text, its size, its position and the animation stay unchanged. Until the new ribbon art lands, the cream title sits on today's light green ribbon. That is expected (functional work goes first, the art follows). Screenshots of the open screen go in art-archive/<this ticket>/screenshots/. Update HUD and menus (the level-up screen's look) and game/README.md ('Level-up screen').

The board's review: open a level-up in a run: the title is in cream with a dark outline (it sits on the light green ribbon until the dark green ribbon art lands).

## Acceptance criteria

- [ ] The level-up screen's TitleLabel uses font colour RGB 246, 250, 232 and an outline of RGB 14, 22, 18 with an outline size above 0; test_level_up_screen.gd checks both. (QA: pass / fail)
- [ ] The card titles, card descriptions and buttons still use black ink (test). (QA: pass / fail)
- [ ] The title's text, size and position are unchanged, and test_level_up_screen.gd still passes: the screen opens, animates and takes cards as before. (QA: pass / fail)
- [ ] A screenshot of the open level-up screen with the new title lettering is in art-archive/<this ticket>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md and game/README.md say the title is lettered in cream with a dark outline. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-310.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

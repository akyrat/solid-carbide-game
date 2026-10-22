---
id: T-265
title: "Level creator: skyscraper banners on or off, off by default"
status: blocked
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-261]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level/building_towers.gd, game/scripts/level/map_building.gd, game/art/banners/, game/scripts/level_creator/, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-265/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22): in the creator every skyscraper shows a kaiju alert banner in the middle of its face, and the board doesn't want them on all of them. Each skyscraper placed in the creator has its banner **on or off** (key B, labels from T-261), **off by default**, saved with the building; the creator's preview shows the choice. Find where the banner comes from first (the banner art in `game/art/banners/` is separate from the skyscraper art; if a banner is baked into some skyscraper pictures instead, say so and remove it by script from a copy, keeping the original, no PixelLab). The game's own map keeps its banners as today. Earlier saved levels open with their skyscrapers' banners off unless their data says otherwise (your proposal; say which).

Built on T-262's branch (the Project Lead makes your folder). End with a screenshot of the six skyscrapers with banners off and two with banners on.

## Acceptance criteria

- [ ] Tests show a creator skyscraper places with no banner by default, B turns it on and off, and the choice is saved, reopened and drawn in a run (QA: pass / fail)
- [ ] The game's own map still shows its banners as before (a test) (QA: pass / fail)
- [ ] The screenshot is in `art-archive/T-265/screenshots/`; `game/README.md` describes the toggle; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place skyscrapers with and without banners.
Board review files: the screenshot in `art-archive/T-265/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

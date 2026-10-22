---
id: T-262
title: "Level creator: one button per kind of piece, in six groups, with looks chosen by keys"
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
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/scripts/level_creator/, game/tools/build_creator_assets.py, game/data/level/creator_assets.json, game/data/level/props.json, game/data/level/creator_buildings.json]
files_expected_to_change: [game/scripts/level_creator/, game/scenes/level_creator/, game/tools/build_creator_assets.py, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-262/screenshots/]
model: opus
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22; the plan it read: https://claude.ai/artifact/2TXG35AkZFYXKvfNUUPfNN). Today the side panel has about 126 buttons, one per rotation, mirror and variant (98 of them roads), and lookalikes sit in different places. Rework it to one button per kind of thing, in six groups from the ground up, with T-261's names:

- **Roads:** Road, Centre line, Zebra crossing, Cracked road (the brush itself is T-263; until then each opens today's tiles for that kind).
- **Ground:** Gravel (its looks), Pavement (if the existing pavement art can be a ground tile; if not, leave it out and say so).
- **Levels:** Platform (heights with H, style with T), Ramp (its height steps, direction with R).
- **Buildings**, smallest to tallest: Small building, Long building, Low-rise (today's short buildings), Skyscraper.
- **Obstacles:** Boulder, Barrier, Cones, Crates.
- **Decoration:** Street lamp, AC unit, Water tank, Roof vent, Rooftop sign.

A piece's variants are keys, not buttons: **V** next look, **R** turn, **M** mirror, **H** height (3 / 6), with T (style) as today. The selected piece shows a **looks strip** under it: small pictures of its looks, clickable, with the counter from T-261. The catalogue builder writes families (one entry per kind, listing its looks, turns, mirrors and heights) so new art adds looks, not buttons. Saved levels and the run are unchanged: a placed piece still writes the same data as today, so earlier levels load and play as before. Every label from `creator_texts.json`; the controls hint is T-261's new line.

Built on the level creator's build: the Project Lead makes your folder from `playtest/creator-set`. T-263 (road brush), T-264 (ramps and platforms) and T-265 (banners) are built on your branch afterwards, so keep the family data and the key handling in one place each. End with screenshots of the whole panel and of the looks strip for a skyscraper and a boulder.

## Acceptance criteria

- [ ] The panel shows the six groups with one button per kind (about 25 in all), labels from `creator_texts.json`; V, R, M and H step through a piece's looks, turns, mirror and heights, and the looks strip shows and picks them (tests and screenshots) (QA: pass / fail)
- [ ] Every look, turn and mirror the old panel offered can still be placed (a test walks the old catalogue and finds each in a family) (QA: pass / fail)
- [ ] Levels saved before this ticket open, place and play as before, and new saves pass `check_level.py` (tests) (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-262/screenshots/`; `game/README.md` "Level creator" describes the panel; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: browse the panel and place a few pieces with their looks.
Board review files: the screenshots in `art-archive/T-262/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

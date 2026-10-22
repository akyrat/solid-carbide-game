---
id: T-261
title: "Text: the level creator rework's groups, pieces and keys"
status: open
from: project-lead
to: narrative-theme
lead: Coursework
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json, tasks/T-250-text-level-creator-piece-set.md]
files_expected_to_change: [game/data/level/creator_texts.json, docs/level-design.md]
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22). Write the labels the reworked creator needs, in the plain style of T-233 and T-250 (buttons about 16 characters, group names about 12), into `game/data/level/creator_texts.json` (one key per piece with a "where it appears" note; keep every existing key unchanged, add new ones), and list them in Level design, Content, "Level creator text", with this ticket's id. Built on the level creator's build: the Project Lead makes your folder from `playtest/creator-set`.

Pieces, each with where it appears:

- **Group names** (side panel): Roads, Ground, Levels, Buildings, Obstacles, Decoration.
- **Piece buttons** (side panel): Road, Centre line, Zebra crossing, Cracked road; Gravel, Pavement; Platform, Ramp; Small building, Long building, Low-rise, Skyscraper; Boulder, Barrier, Cones, Crates; Street lamp, AC unit, Water tank, Roof vent, Rooftop sign (reuse T-250's wording where a piece already has a name).
- **The looks strip** under a selected piece: its short heading (for example "Looks"), and the look counter (for example "Look {n} of {count}").
- **Platform sizes** (top bar): S, M, L and "Any size (drag)".
- **Ramp arrows** (top bar): "Arrows up" and "Arrows down".
- **Banner** (top bar, skyscrapers): "Banner on" and "Banner off".
- **Road brush** (top bar): a hint while painting a road (for example "Drag to paint a road").
- **Controls hint line**: an updated line with the keys R turn, V next look, M mirror, H height, A arrows, B banner, T style, Del delete, and dragging to paint roads and size platforms.

## Acceptance criteria

- [ ] `creator_texts.json` is valid JSON with a text and a "where it appears" note for every piece above, and every existing key is unchanged (QA: pass / fail)
- [ ] Level design, Content, "Level creator text" lists them with this ticket's id; buttons fit about 16 characters and group names about 12 (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

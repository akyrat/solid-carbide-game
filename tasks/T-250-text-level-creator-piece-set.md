---
id: T-250
title: "Text: the level creator's new pieces and controls"
status: open
from: project-lead
to: narrative-theme
lead:
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json, tasks/T-233-text-the-level-creator-s-screens.md]
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22): the level creator gets a comprehensive set of pieces. Write the labels it needs, in the same plain style as T-233's (buttons fit about 16 characters, panel category names about 12), into `game/data/level/creator_texts.json` (one key per piece with a short "where it appears" note, as T-233 did), and list them in Level design, Content, "Level creator text", with this ticket's id. Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`.

Pieces, each with where it appears:

- **Sizing a rooftop** (T-251): the top bar's hint while dragging out a rooftop's size, and the width and depth readout (for example "Size: {w} x {d}").
- **Ramp directions** (T-251): the four climb directions shown on the top bar for a picked ramp (north, east, south, west), and a "Ramp 0 to 6" height label if T-251 adds one (write it anyway).
- **Road pieces** (T-252): names for the corner, T-junction, crossroads and dead end tiles in the side panel.
- **Props** (T-253): the new side panel category name (Props) and the name of each prop: concrete barrier, traffic cones, crate stack, AC unit, water tank, roof vent, street lamp, rooftop sign.
- **Buildings** (T-254): names for the small square building and the long building in the side panel.
- **Controls hint:** an updated hint line that adds dragging to size a rooftop.

## Acceptance criteria

- [ ] `game/data/level/creator_texts.json` is valid JSON and has a text and a "where it appears" note for every piece listed above, and T-233's keys are unchanged (QA: pass / fail)
- [ ] Level design, Content, "Level creator text" lists them with this ticket's id; labels fit the lengths above (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

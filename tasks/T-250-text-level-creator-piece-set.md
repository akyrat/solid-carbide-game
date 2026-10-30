---
id: T-250
title: "Text: the level creator's new pieces and controls"
status: done
from: project-lead
to: narrative-theme
lead: Greenbull
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
qa_rounds: 1
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

- [ ] `game/data/level/creator_texts.json` is valid JSON and has a text and a "where it appears" note for every piece listed above, and T-233's keys are unchanged (QA: pass; JSON valid, 48 entries, all 25 T-233 keys identical to playtest/G-005, all 23 new keys have text and where note)
- [ ] Level design, Content, "Level creator text" lists them with this ticket's id; labels fit the lengths above (QA: pass; all listed in level-design.md with T-250; buttons and panel labels <=16 chars, Props is 5; only the hint lines are longer, as they are lines)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's go: labels for the creator's new pieces and controls.

### 2026-10-22, In progress → In QA

Text written: 23 new labels (sizing, ramp directions, road pieces, props, buildings, hint). Sent to QA.

### 2026-10-30, In QA → Done

Closed: merged with the creator-set build you played; only the status was left behind.

## Result notes

Written by the agent when it finishes.

Narrative Theme Agent, 2026-10-22: wrote 23 new keys at the end of `game/data/level/creator_texts.json` (T-233's 25 keys are unchanged; the file has 48 entries): size_hint, size_readout, ramp_dir_north/east/south/west, ramp_height_0_6, road_corner, road_t_junction, road_crossroads, road_dead_end, category_props, prop_barrier, prop_cones, prop_crates, prop_ac_unit, prop_water_tank, prop_roof_vent, prop_street_lamp, prop_roof_sign, building_small, building_long, controls_hint_sizing. Each has a text and a where note. Buttons and panel labels fit 16 characters (category "Props" is 5); the two hint lines (size_hint, controls_hint_sizing) are lines, not buttons. controls_hint_sizing is a new key because the old controls_hint must stay unchanged; the creator should show the new one. Listed in `docs/level-design.md`, Content, "Level creator text".

Tests: `python -m unittest discover -s game/tools -p "test_*.py"` 416 tests OK (1 skipped); `bash game/tools/run_tests.sh -gselect=test_creator_texts_only` 4 of 4 passing (it scans scripts for hard-coded labels; no test checks the JSON's keys).

Refusal note: my first attempt, one inline `python -` heredoc to write both files, was refused by the status-script guard (it saw `**` as task files). A second attempt to append these notes with a shell variable and heredoc was refused too. I did not work around either; the Project Lead told me to use Edit and Write for the non-task files, and I used Edit for these notes.
- 2026-10-30, in-qa → done: Already merged into master with playtest/creator-set (67996a22), after the board's playtest; status closed by Greenbull after taking it over from Coursework (board, 2026-10-30).

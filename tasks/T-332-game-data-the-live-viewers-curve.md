---
id: T-332
title: "Game data: the live viewers curve, its heat steps and how the number moves"
status: open
from: project-lead
to: game-data
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/data/combo.json, game/scripts/data/combo_data.gd, game/scripts/hud/combo_heat.gd]
files_expected_to_change: [game/data/, game/scripts/data/, game/tests/unit/, game/README.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "The combo shows as live viewers", 2026-10-28): the combo multiplier (x1.0 to its x6.0 cap, `combo.json`) keeps working as it does, and the player sees it as live viewers. Put in the data, read through the game's data scripts (no HUD in this ticket; T-336 builds the counter):

- **The curve from multiplier to viewers.** The board's anchors: **x2 = 20,000** and **x6 = 1,000,000**. Proposals (the Project Lead's starting point, change them if you have a reason): **x1 = 2,500** (a quiet stream), rising to 20,000 at x2; from x2 to x6 a smooth exponential curve through the anchors (`20,000 × 50^(log(m/2)/log 3)`: about 85K at x3, 236K at x4, 520K at x5). One function the counter calls, tested at the anchors.
- **How the number moves:** how fast the shown number counts toward its target (up and down), and a small constant wobble so it never sits still, like a real stream (for example ±0.5% every fraction of a second). Numbers in the data.
- **The heat steps in viewers:** the counter's looks follow today's combo heat steps (x2, x3, x4: `ComboHeat.THRESHOLDS`), so in viewers about 20K, 85K and 236K; plus a **fire** step **over 1,000,000** (the board). Expose the thresholds so the counter and the popups use the same ones.
- **The "+viewers" of a trick:** a function giving the viewers a trick brought (the target before and after the trick's multiplier change), and the viewers a crash lost, for T-336's popups.
- **Display format:** how numbers shorten (for example 2,500 / 20.4K / 1.02M), proposed and tested.

The board's review: none needed (data); judged in the HUD playtest.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The curve gives 20,000 at x2 and 1,000,000 at x6 (±1%), rises with the multiplier everywhere, and its x1 value is in the data (tests). (QA: pass / fail)
- [ ] The heat thresholds in viewers, the fire threshold (1,000,000), the counting speed and the wobble are in the data with a reason each (Game loop architecture, Content). (QA: pass / fail)
- [ ] The trick gain and crash loss functions and the number format have tests. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

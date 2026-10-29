---
id: T-365
title: The garage shows an icon beside each upgrade
status: open
from: project-lead
to: ui
lead: Greenbull
epic: garage
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/garage-design.md, game/docs/]
files_to_read_first: [tasks/README.md, docs/garage-design.md, game/scripts/menu/garage_screen.gd, game/data/garage.json]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/tests/unit/, game/docs/, docs/garage-design.md, art-archive/]
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

The board's decision (Garage design, Decisions, "Pixel art icons for the upgrades", 2026-10-29): each garage upgrade gets a small pixel art icon. This ticket puts an icon beside each upgrade's row on the garage screen, with placeholders; five linked art tickets draw the icons.

For each upgrade in `game/data/garage.json` (`acceleration`, `car_health`, `damage_bonus`, `pickup_magnet`, `air_turn`, and any later one), the row shows the icon from `game/art/garage/<upgrade key>.png` when that file exists, scaled up with hard pixel edges (no smoothing; a proposal: 16 x 16 art drawn at 3x), and a placeholder drawn in code when it doesn't (a simple pixel square with the upgrade's first letter is fine; no new text, so a shape is better than a letter: your call). That way each art ticket only adds its PNG and the garage picks it up with no code change. None of Greenbull's colours on the placeholders (Visual style, Content, "Rules", rule 6). The rest of the garage stays as it is.

The board's review: open the garage and see an icon beside each upgrade.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each upgrade row shows an icon: the PNG from game/art/garage/<key>.png when it exists, else a placeholder drawn in code (tests with and without a file). (QA: pass / fail)
- [ ] Icons are scaled with hard pixel edges (nearest filter) and don't change the rows' layout, buying or text (tests). (QA: pass / fail)
- [ ] Garage design, Content and the game docs describe it, including where the art tickets put their files. (QA: pass / fail)
- [ ] A screenshot of the garage with the placeholders is in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

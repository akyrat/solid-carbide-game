---
id: T-393
title: Bug: barriers and other objects in the level creator ignore the heights of buildings and rooftops
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/docs/level/elevation-sample-map.md, game/scripts/level_creator/, game/scripts/level/]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

The board's decision (Level design, Decisions, "Obstacles and decorations respect the buildings' and rooftops' heights", 2026-10-29; a bug the board wants fixed at once): "When I put the barriers [they] ignore heights of buildings. And I think this might be the case with other objects as well. Please look into the root cause and fix it." The board's screenshot: `C:\Users\andre\Pictures\Screenshots\Screenshot 2026-10-29 235513.png` (read it): a row of barriers on the street running towards a raised rooftop; the last barriers are drawn over the rooftop's edge and its AC units as if the rooftop weren't there, and a barrier sits where the rooftop is.

Find the root cause, for every kind of placed object (barriers, boulders, cones, crates, street lamps, AC units, water tanks, roof vents, rooftop signs), for example: the object's height not taken from what is under it (street, rooftop 3 or 6, ramp), its draw order (y-sort or z-index) not accounting for the rooftop's height, or the creator letting an object be placed half on a rooftop's edge. Fix it so each object sits at the height of what it stands on and is drawn in front of or behind buildings and rooftops correctly, in the editor and in the run; decide (and write as a proposal) what happens when an object is placed across a rooftop's edge (for example refused like a road over a building, or snapped to one side). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked; `kaiju_city.json` is the one in the screenshot): read copies only, never write or commit them. Earlier levels and the game's own map must look as before where nothing was wrong.

The board's review: place barriers and other objects next to and on a rooftop in the creator, and press Play.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The root cause is written in the result notes for each kind of object, with a test that fails before the fix (named) for the barrier next to a rooftop. (QA: pass / fail)
- [ ] Every kind of placed object sits at the height of what it stands on (street, rooftop 3 and 6, ramp) and draws in front of or behind buildings and rooftops correctly, in the editor and in the run (tests). (QA: pass / fail)
- [ ] Placing an object across a rooftop's edge does what the result notes propose (test). (QA: pass / fail)
- [ ] The game's own map and an earlier level build as before (tests), and the board's level files are unchanged and uncommitted. (QA: pass / fail)
- [ ] Level design, Content and game/docs/level/ describe the fix and the proposal. (QA: pass / fail)
- [ ] Screenshots of the board's case (barriers by a rooftop) before and after, in the editor and in the run, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

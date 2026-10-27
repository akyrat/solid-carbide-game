---
id: T-324
title: "The Bricks weapon: an impact wave each time the car lands"
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-322, T-323]
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/drifting.md, game/README.md, game/scripts/weapons/weapons.gd, game/scripts/weapons/weapon.gd, game/scripts/weapons/level_up_offers.gd, game/scripts/weapons/windshield_wiper.gd]
files_expected_to_change: [game/scripts/weapons/, game/scenes/, game/tests/unit/, game/README.md, docs/weapons.md]
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

The board's decision (Weapons, Decisions, "Bricks", 2026-10-28). Build Bricks as a weapon like the other five: offered on level-up cards (with T-322's texts and a placeholder card image until T-325's art), with T-323's numbers and tiers. Each time the car lands on the ground after being in the air (off a ramp, a rooftop's edge or any drop, the car's existing landing signal; a time in the air below T-323's minimum doesn't count), a powerful impact wave goes out around the car: it damages every enemy within its radius (the kaiju too) and knocks minions back if T-323 gives a knockback. The same wave whatever the height. A placeholder wave drawn in code (an expanding ring on the ground with a dust burst, in the City's colours, none of Greenbull's colours), with a placeholder sound if the SFX bus makes it easy (or none). The car's handling doesn't change ("making the car heavier" is only the joke).

The board's review: take Bricks, jump off a ramp into a crowd of minions, and judge the wave.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Bricks can be offered on a level-up card and taken, and its upgrades raise what T-323 says (tests). (QA: pass / fail)
- [ ] A landing after enough time in the air sends one wave that damages each enemy within the radius once, and none outside it (tests); a shorter hop sends none (test). (QA: pass / fail)
- [ ] The wave is the same after a short and a tall drop (test). (QA: pass / fail)
- [ ] The card shows T-322's texts word for word. (QA: pass / fail)
- [ ] Weapons, Content, "Bricks" and game/README.md describe how it works. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-324/screenshots/`, as `tasks/README.md`, "Screenshots", asks. A GIF of a jump that lands among enemies. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-334
title: "Hearts in the run: damage in hearts, 1 second of invulnerability with a blink, health drops"
status: open
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-333]
documents_affected: [docs/game-loop-architecture.md, docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md, game/docs/game-loop/the-run.md, game/docs/hud-and-menus/hud.md, game/scripts/run/run_state.gd, game/scripts/run/run.gd]
files_expected_to_change: [game/scripts/run/, game/scripts/enemies/, game/scripts/driving/, game/scripts/garage/, game/tests/unit/, game/README.md, docs/game-loop-architecture.md, docs/enemies.md]
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

The board's decision (Game loop architecture, Decisions, "Hearts instead of health points", 2026-10-28), with T-333's numbers. The run counts the car's health in whole **hearts** (5 to start, more with the garage upgrade):

- Every hit takes its hearts at once (minion 1, meteor 1, kaiju 2). The repeated contact hits every 0.5 s go: after **any** hit the car is **invulnerable for 1 second**, and **blinks** the whole time so the player sees it; hits during that second do nothing at all (no hearts, no knockback if that reads better (your proposal), and **no combo cut**: only the first hit cuts the combo).
- A health pickup heals 1 heart, never above the maximum, and drops at T-333's chance.
- The garage's car health upgrade adds 1 heart per level.
- The run ends at 0 hearts as it ended at 0 health.
- Everything that read the old health (the HUD's health bar, the recap if built, the crash pays the trick in progress of T-315, the time's up screen) keeps working; the HUD's health bar can show hearts as a fraction until T-338 replaces it with the heart row.

The board's review: play a run and get hit: you lose a heart, the car blinks for a second and you can drive out of a swarm.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A run starts with 5 hearts (plus 1 per garage level); a minion and a meteor take 1, the kaiju 2 (tests). (QA: pass / fail)
- [ ] After a hit the car is invulnerable for 1 s (±0.05) and blinks; a second hit inside it takes nothing and doesn't cut the combo, and one after it does (tests). (QA: pass / fail)
- [ ] A health pickup heals 1 heart and never goes above the maximum; it drops at T-333's chance (tests). (QA: pass / fail)
- [ ] The run ends at 0 hearts with the same result as at 0 health before (test). (QA: pass / fail)
- [ ] Game loop architecture, Enemies and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-334/screenshots/`, as `tasks/README.md`, "Screenshots", asks: a GIF of a hit, the blink and the car driving out of a swarm. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

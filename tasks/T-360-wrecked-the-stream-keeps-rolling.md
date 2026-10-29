---
id: T-360
title: Wrecked: the car smokes and burns for 3 seconds when its last heart is gone
status: in-progress
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/hud-and-menus.md, game/docs/game-loop/the-run.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/scripts/run/run_state.gd, game/scripts/game/game_flow.gd, game/scripts/driving/, tasks/T-317-the-time-s-up-screen.md, tasks/T-320-the-recap-screen.md]
files_expected_to_change: [game/scripts/run/, game/scripts/driving/, game/scripts/game/game_flow.gd, game/data/, game/tests/unit/, game/docs/game-loop/the-run.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, art-archive/]
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

The board's decision (Game loop architecture, Decisions, "Wrecked: the stream keeps rolling", 2026-10-29), in its words: "when the player dies, don't end the scene yet and just disable the controls. Keep any movement that the car had. And then maybe we can show some smoke coming out of it ... Maybe it'd be really cool to add some flames as well ... So for 3 seconds, the car is still on the screen, kind of crashed and smoking. Then we show the recap." Like the end of a livestream that doesn't cut away.

When the car loses its last heart:
- The run's result is decided at that moment (a loss), but the scene stays for **3 seconds** before the run ends (the same `run_ended` as today, so the recap, T-320, or the main menu follows exactly as now).
- **The controls go dead**: no steering, throttle, brake, drift or handbrake input reaches the car. The car **keeps the movement it had** and slows to a stop with its normal physics (it can still slide, spin out or bump into things; the camera keeps following). Driving & Drift's code owns the car: add the smallest switch that turns its input off, and don't change how it handles while alive.
- The car can't take damage, collect coins, likes or gift packs, or score tricks during the 3 seconds. Enemies, the timer and the HUD carry on or freeze: your proposal for the playtest (the board wants the stream to feel like it is still live: the HUD stays on screen).
- **Smoke and flames** come out of the car for the 3 seconds: placeholders in code first (simple pixel puffs and flickers, none of Greenbull's colours, Visual style, Content, "Rules", rule 6). The linked art ticket (pixel art smoke and flames animations) swaps its art in; the board wants to play this ticket with that art, so they are played together.
- Pause still works during the 3 seconds. The time's up screen (T-317) is the timer's loss; this is the health loss; a kaiju kill ends the run as before.
- The 3 seconds and any other numbers go in a data file in `game/data/` (proposals for the playtest). No text.

The board's review: lose all your hearts at speed: the car slides on, uncontrollable, then sits crashed, smoking and burning for 3 seconds before the recap.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Losing the last heart starts a 3-second wreck (±0.1 s, from a data file) and the run ends after it with the same result and signal as before; a kaiju kill and the time's up loss are unchanged (tests). (QA: pass / fail)
- [ ] During the wreck no player input moves the car, the car keeps its velocity and slows with its normal physics, and handling while alive is unchanged (tests). (QA: pass / fail)
- [ ] During the wreck the car takes no damage and collects no coins, likes, gift packs or tricks; pause freezes the wreck (tests). (QA: pass / fail)
- [ ] Smoke and flames show on the car for the whole wreck (placeholders in code, drawn in the right place as the car moves). (QA: pass / fail)
- [ ] Game loop architecture, HUD and menus and game/docs/game-loop/the-run.md describe it. (QA: pass / fail)
- [ ] A screenshot and a GIF of the whole wreck after losing the last heart at speed are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started (build B, End of a run): the Game Loop Agent is making the car slide on with dead controls and sit smoking and burning for 3 seconds when its last heart is gone, with placeholders, on top of the run stats (T-319).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

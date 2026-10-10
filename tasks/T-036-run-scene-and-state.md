---
id: T-036
title: The run: scene, 8-minute clock, car health, coins, win and loss
status: open
from: project-lead
to: game-loop
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-019, T-038]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md, docs/level-design.md, tasks/T-012-godot-drift-prototype.md, tasks/T-019-build-mvp-map.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [a run scene and its scripts under game/scenes/run/ and game/scripts/run/, their tests, game/README.md, docs/game-loop-architecture.md]
model: opus
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-019 (the MVP map) and T-038 (the run's numbers) are done.**

This is the first task for the Game Loop Agent: the run itself, as Game loop architecture, Decisions describes it. It ties the existing pieces together and owns the run's state. Other agents' work plugs into it later through signals and functions this task defines.

1. **Run scene:** a scene that loads the MVP map (T-019) and places the T-012 car on it, at a start position you choose and note in the result notes. The camera follows the car as in the drift prototype. The drift prototype scene stays as it is, as a tuning tool.
2. **The clock:** the run starts at 8:00 and counts down.
   - When 7 minutes have passed (1:00 left), it sends a "boss time" signal. The Enemy Behavior Agent will spawn the kaiju on it (Game loop architecture, Decisions).
   - At 0:00 the run ends.
   - The clock stops while the game is paused.
3. **Car health:**
   - The run holds the car's health. It starts at the value in T-038's data.
   - Other agents call a public function to damage the car.
   - Health reaching 0 ends the run as a loss.
4. **Coins:** a public function adds coins collected in this run. The run keeps the total.
5. **Win and loss** (Game loop architecture, Decisions):
   - **Loss:** health reaches 0, or the clock reaches 0:00 while the kaiju is still alive.
   - **Win:** a public function the Enemy Behavior Agent calls when the kaiju is killed ends the run at once as a win.
   - On either, the run sends one "run ended" signal with the result (win or loss) and the coins collected. The coins are kept either way. Saving them is a Game Data task, which will listen to this signal.
   - Going back to the main menu is a later task (the screen flow), since the main menu doesn't exist yet. For now, after the run ends, nothing else needs to happen.
6. **Values for the HUD:** time left, health and max health, and coins this run, readable at any time, with a signal when each changes. The UI Agent will build the HUD from them later.
7. **Starting a run:** a function that starts a fresh run from the start: full health, 8:00, 0 coins.

Write the public functions and signals in `game/README.md` ("The run"), so the enemy, weapon, UI and data tasks can use them.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test starts a run and shows: time 8:00, health equal to T-038's starting value, 0 coins, and the map and car loaded (QA: pass / fail)
- [ ] A test simulates time and shows the "boss time" signal fires once, when 7 minutes have passed, and the run ends as a loss at 0:00 if the kaiju is not killed (QA: pass / fail)
- [ ] A test damages the car to 0 health and shows the run ends once, as a loss, with the coins collected so far (QA: pass / fail)
- [ ] A test calls the kaiju-killed function and shows the run ends at once, as a win, with the coins collected (QA: pass / fail)
- [ ] A test shows the clock does not advance while the game is paused (QA: pass / fail)
- [ ] A test starts a second run after the first ends and shows everything is reset (QA: pass / fail)
- [ ] A screenshot of the run scene shows the car on the MVP map (QA: pass / fail)
- [ ] `game/README.md` documents the run's public functions and signals. `docs/game-loop-architecture.md` describes the run scene in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

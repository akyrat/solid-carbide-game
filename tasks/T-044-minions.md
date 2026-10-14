---
id: T-044
title: Minions: spawn, chase the car, contact damage, die and drop coins
status: open
from: project-lead
to: enemy-behavior
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-036, T-039, T-033]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-039-enemy-data.md, tasks/T-033-car-collisions-and-knockback.md, game/README.md]
files_expected_to_change: [the enemy code and scenes, tests, docs/enemies.md, game/README.md]
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

**Blocked until T-036 (the run), T-039 (the numbers) and T-033 (car collisions and knockback) are done.**

Build the MVP minion as Enemies, Decisions describes it, with T-039's numbers:
1. **Spawning:** minions come in from the edges of the screen, in numbers that grow slightly over the run (the run's clock, T-036).
2. **Movement:** they walk towards the car. They use T-033's enemy collision layer, so the car never bounces off them.
3. **Contact damage:** while touching the car, a minion damages it through the run's damage function (T-036) at the data's rate, and knocks it back through T-033's knockback function.
4. **Taking damage:** a public damage function the weapons call (T-041, T-042). Document it for them. A minion dies at 0 health.
5. **Coins:** on death a minion may drop coins (the data's chance and amount). Driving over a coin collects it through the run's add-coins function (T-036).
6. Minions stop when the run is paused, and are cleared when a new run starts.

Minions and coins are placeholders for now (simple shapes in the palette; minions light green). The final minion and coin art come from separate art tasks.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

**Draw order (from T-034's QA, 2026-10-13):** once T-034 (see-through buildings) is merged, buildings get a depth order and the car is drawn just under the buildings covering it. Minions must get a place in that order too (see `map.car_z_index()` and game/README.md, "See-through buildings"), or they will be drawn under every building even when in front of one. The fade itself stays car-only.

## Acceptance criteria

- [ ] A test simulates the run's clock and shows there are more minions at the end of the 7 minutes than at the start, as the data says (QA: pass / fail)
- [ ] A test shows a minion moves towards the car (QA: pass / fail)
- [ ] A test keeps a minion touching the car and shows the car's health drops at the data's rate and the car is knocked back (QA: pass / fail)
- [ ] A test damages a minion to 0 and shows it dies; over many deaths, coins drop at about the data's chance (QA: pass / fail)
- [ ] A test drives the car over a coin and shows the run's coin total goes up and the coin disappears (QA: pass / fail)
- [ ] A test shows minions don't move while the run is paused, and are cleared when a new run starts (QA: pass / fail)
- [ ] A screenshot of the run shows placeholder minions around the car (QA: pass / fail)
- [ ] `game/README.md` documents the enemies' damage function for the weapon tasks, and `docs/enemies.md` describes the built minion in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it). There are no weapons yet, so this playtest covers spawning, chasing, contact damage, knockback, pause and draw order. Killing minions and coins are checked by the tests only, and the board judges them in a playtest once the starting gun (T-041) is in. No debug kill key (board, 2026-10-14).

## Result notes

Written by the agent when it finishes.

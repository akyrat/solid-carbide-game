---
id: T-057
title: Saving coins and upgrade levels, and buying an upgrade
status: blocked
from: project-lead
to: game-data
epic: garage
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-036, T-056]
documents_affected: [docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, tasks/T-036-run-scene-and-state.md, tasks/T-056-garage-data.md, game/README.md]
files_expected_to_change: [the save code, tests, docs/garage-design.md, game/README.md]
model: sonnet
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

**Blocked until T-036 (the run's "run ended" signal) and T-056 (the upgrades) are done.**

The player's coins and the upgrade levels bought are saved to disk and kept between game sessions (Garage design, Decisions). Build:
1. **Saving and loading** in a file under `user://`. A missing file means a new player: 0 coins, every upgrade at level 0.
2. **Banking a run's coins:** on the run's "run ended" signal, win or loss, add the coins collected to the saved total and save (Game loop architecture, Decisions).
3. **Buying:** a function the garage screen calls with an upgrade's id. If the player has enough coins and the upgrade isn't at its last level, it spends the price, raises the level and saves. Otherwise it refuses and says why (not enough coins, or maxed).
4. **Reading:** each upgrade's current level, next price and effect, and the coin total, for the garage screen and for applying upgrades at the start of a run.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test with no save file shows 0 coins and every upgrade at level 0 (QA: pass / fail)
- [ ] A test ends a run (simulated signal) with some coins and shows they are added to the total and saved (QA: pass / fail)
- [ ] A test buys an upgrade with enough coins and shows coins go down by the price, the level goes up, and both are saved (QA: pass / fail)
- [ ] A test shows buying is refused with too few coins, and at the last level, and nothing changes (QA: pass / fail)
- [ ] A test saves, reloads from disk, and shows the same coins and levels (QA: pass / fail)
- [ ] `game/README.md` documents the functions for the UI and the run, and `docs/garage-design.md` describes saving in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

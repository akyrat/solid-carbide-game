---
id: T-077
title: Play the MVP's sound effects in the game
status: open
from: project-lead
to: sfx
lead: Playtest
epic: sound
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-076, T-036, T-041, T-042, T-044, T-046]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/unfiled-game-details.md, tasks/T-076-mvp-sound-effects.md, tasks/T-036-run-scene-and-state.md, tasks/T-041-starting-gun.md, tasks/T-042-exhaust-flamethrower.md, tasks/T-044-minions.md, tasks/T-046-kaiju-meteor-attack.md, game/README.md]
files_expected_to_change: [audio code and scenes, tests, game/README.md]
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

**Unblocked (2026-10-16):** T-076's sounds are approved by the board ("sfx looks good") and merged; the run, gun, flamethrower, minions and coins, and meteor attack are all in master. Use the recommended file per sound from T-076's result notes.

Play T-076's recommended sounds at their moments: the engine while driving (following the car's speed if that's simple), a drift sound while drifting, the gun firing, the flames while they're on, enemy hits, coin pickups, the meteor warning and impact. Keep volumes balanced, and add a CC BY credits list to `game/README.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test fires each moment (signal or function) and shows its sound plays (QA: pass / fail)
- [ ] A test shows the drift and flame sounds stop when drifting stops (QA: pass / fail)
- [ ] `game/README.md` lists where each sound plays and credits every CC BY sound (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-16: "make a ticket to integrate it in the game, and I'll playtest it").

## Result notes

Written by the agent when it finishes.

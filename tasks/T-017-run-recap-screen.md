---
id: T-017
title: Recap screen after a run ends, win or loss
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: final-release
user_facing_text: yes
changes_visuals: yes
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [the recap screen scene and script, and their tests]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Final release. Blocked until** the board has listed the stats the screen shows beyond kills, and described its look; until the game has a complete run (enemies, the kaiju, win and loss) for the screen to follow; and until the Visual style document has content. The Project Lead adds these here, with the tasks it depends on, and unblocks it.

Right after a run ends, whether the player won or lost, a recap screen shows how the run went (Game loop architecture, Decisions):

- **How many of each enemy type the player killed** (the enemy types are listed in the Enemies game area doc).
- **Other stats:** to be chosen by the board. Agents do not invent them.

The UI Agent builds the screen and shows the numbers only. Counting them during a run belongs to the agents that own what is counted (for example, the Enemy Behavior Agent for kills); when this task is unblocked, the Project Lead writes linked tasks for that counting.

## Acceptance criteria

To be written when the board's list of stats and description are in.

## Result notes

Written by the agent when it finishes.

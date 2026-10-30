---
id: T-423
title: The board slims the docs and fixes what the audit found
status: open
from: project-lead
to: board
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/enemies.md, docs/weapons.md, docs/hud-and-menus.md, docs/drifting.md, docs/level-design.md, docs/garage-design.md, docs/visual-style.md, docs/extended-narrative.md]
files_to_read_first: [CLAUDE.md, tasks/T-030-design-pillars-rework.md]
files_expected_to_change: [docs/]
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

The board's own ticket, worked by hand. The board wants the docs left better than they were found: cut each game area doc to its essence and its facts, each decision written once, no duplication or repetition. Related: T-030 (the board reworks the short GDD's design pillars). Factual fixes the audit found: Game loop architecture's Content, "Wrecked", still says the loss is decided at once and that a kaiju kill both ends the run and can't turn it into a win (now replaced by the audit's Decision); Enemies (T-404 line) mentions a kaiju "vulnerable window", but the kaiju has none; HUD and menus says T-317 and T-320 are not built yet, but both are; Weapons, Content, "Garage damage bonus" names only the gun and the flamethrower, but the bonus covers every weapon (2026-10-18). Once a doc is done, the Project Lead regenerates the long GDD and the short GDD's fingerprint.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The four factual fixes above are made. (QA: pass / fail)
- [ ] The board marks each doc it has slimmed in the result notes; the docs staleness check passes after the long GDD is regenerated. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

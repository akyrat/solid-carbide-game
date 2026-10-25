---
id: T-287
title: "Story and text: views instead of likes on the livestream"
status: planning
from: project-lead
to: narrative-theme
lead: Coursework
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/extended-narrative.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/scripts/ui/level_up_texts.gd, tasks/T-288-tricks-pay-views.md, tasks/T-289-likes-bar-restyle.md]
files_expected_to_change: [docs/extended-narrative.md, docs/hud-and-menus.md, game/scripts/ui/level_up_texts.gd, game/data/]
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

**On hold: needs refining before work starts (board, 2026-10-25).**

The board's playtest note on the game build (2026-10-24): the run is a livestream, so what the player earns could be **views** rather than likes, and views read like the score that tricks earn. Today the Extended narrative says "likes are XP": drifting earns likes, and they fill the bar toward gift packs.

If the board goes ahead, this ticket:
- updates the Extended narrative's "likes are XP" decision;
- renames likes to views in every piece of player-facing text: the HUD, level-up texts, gift pack wording and garage descriptions;
- writes the words the views counter and the end-of-run score need (T-288, T-289).

## Open questions (for refining with the board)

1. Do views replace likes completely, or are they a separate score with likes kept for the bar? (The Project Lead's recommendation: replace, so there is one number.)
2. Does drifting still pay views every second, or do only tricks pay views (T-288)?
3. Does the heart icon stay (as the stream's reaction flair) or become something else, for example an eye?

## Acceptance criteria

To be written once the open questions are answered.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-25, Open → Planning

On hold at the board's request: needs refining before work starts. Open questions are in the ticket.

## Result notes

Written by the agent when it finishes.

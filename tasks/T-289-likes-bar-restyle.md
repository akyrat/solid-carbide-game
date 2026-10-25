---
id: T-289
title: "The likes bar restyled: red outline, drift trail fill, an audience gathering"
status: planning
from: project-lead
to: ui
lead: Coursework
epic: ui
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-287]
documents_affected: [docs/hud-and-menus.md, docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/scripts/hud/hud.gd, game/scripts/hud/likes_spring.gd, tasks/T-273-likes-bar-thicker-springs.md, tasks/T-249-hype-drift-trail.md, tasks/T-287-text-views-instead-of-likes.md]
files_expected_to_change: [game/scripts/hud/, game/tests/, docs/hud-and-menus.md, docs/visual-style.md, game/README.md, art-archive/T-289/screenshots/]
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

The board's playtest notes on the game build (2026-10-24). The likes bar (64 px tall since T-273, purple today) should:

- **Outline:** have its outline in the heart's red. That is the one approved red, so this extends the board's approval from the heart to the bar's outline.
- **Fill:** fill in the colour of the drift tracks. The Project Lead's reading: the fill takes the hype drift trail's look at the current combo step (T-249: yellow at x2, orange at x3, white-hot at x4), because plain tyre marks are dark.
- **Theme:** look more in the game's theme, not a plain rectangle, as if it's gathering views. For example, small reactions flying into the bar as it fills, or a live tag. These are the agent's proposals for the playtest.

The spring fill (T-273) and the x4 flames stay.

## Open questions (for refining with the board)

1. Does the fill follow the hype trail's colours at the current combo step (the Project Lead's reading), or one fixed drift-track colour?
2. Which "gathering views" touches does the board want, or should the agent propose a few for the playtest?
3. Does this wait for the views decision (T-287), since the bar may show views instead of likes?

## Acceptance criteria

To be written once the open questions are answered.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-25, Open → Planning

On hold at the board's request: needs refining before work starts. Open questions are in the ticket.

## Result notes

Written by the agent when it finishes.

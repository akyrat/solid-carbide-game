---
id: T-092
title: Challenge completed: the likes gained pop out from the car
status: in-progress
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-091, T-037]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-091-trick-popups.md, tasks/T-037-likes-and-levels.md, tasks/T-048-text-hud.md, game/README.md]
files_expected_to_change: [the popup code, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-091 (the popups) and T-037 (likes, with its "score" signal) are done.**

HUD and menus, Decisions (2026-10-10): when the player completes a challenge, the likes it gave pop out from the car like the trick popups, using T-048's approved `hud.score_flash` text ("Trending! +{likes} Likes"). Use T-091's popups and T-037's "score" signal.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test fires T-037's score signal and shows a popup with T-048's text and the likes gained appears near the car, then goes away (QA: pass / fail)
- [ ] A screenshot shows the popup after a challenge is completed in the run (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

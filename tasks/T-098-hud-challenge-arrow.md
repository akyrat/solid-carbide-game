---
id: T-098
title: HUD: the arrow to the nearest challenge
status: blocked
from: project-lead
to: ui
epic: hud-menus
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: [T-050, T-019, T-035]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/level-design.md, tasks/T-049-hud-run-values.md, tasks/T-019-build-mvp-map.md, tasks/T-035-runtime-meteor-challenges.md, game/README.md]
files_expected_to_change: [the HUD scene and script, tests, docs/hud-and-menus.md, game/README.md]
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

**Moved after the MVP (2026-10-11): challenges are left out of the MVP (Level design, Decisions). Not to be started unless the board brings challenges back.**

Split from T-050. An arrow near the car pointing to the nearest open challenge. Use the challenge positions T-019 and T-035 expose. When a challenge is completed, the arrow points to the next nearest. When none is open, the arrow hides. The arrow is a placeholder shape for now.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test with two open challenges shows the arrow points to the nearer one, and after completing it, to the other (QA: pass / fail)
- [ ] A test with no open challenge shows the arrow is hidden (QA: pass / fail)
- [ ] A screenshot shows the arrow in a run (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

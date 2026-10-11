---
id: T-088
title: Meteor challenges never land on another challenge's arrow
status: open
from: project-lead
to: level-challenge
epic: level-challenges
milestone: final-release
user_facing_text: no
changes_visuals: no
depends_on: [T-035]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-035-runtime-meteor-challenges.md, game/README.md]
files_expected_to_change: [the challenge code, tests, docs/level-design.md, game/README.md]
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

T-035's placement check lets a meteor challenge land on a preset challenge's arrow. The board decided it must not (Level design, Decisions, 2026-10-10): a meteor challenge's boulders and its arrow corridor must not overlap any other challenge's arrow corridor, preset or meteor.

Extend `can_place_meteor_challenge` to reject those spots too, keeping everything it already rejects (buildings, boulders, the map edge).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test shows the placement check rejects a spot where the new challenge's boulders or corridor overlap a preset challenge's corridor (QA: pass / fail)
- [ ] A test shows it rejects a spot overlapping an open meteor challenge's corridor (QA: pass / fail)
- [ ] A test shows a free spot is still accepted, and T-035's tests still pass (QA: pass / fail)
- [ ] `game/README.md` and `docs/level-design.md` (Content) describe the stricter check, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

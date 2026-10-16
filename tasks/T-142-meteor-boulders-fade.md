---
id: T-142
title: Meteor boulders fade away 10 seconds after landing
status: in-progress
from: project-lead
to: enemy-behavior
lead: Playtest
epic: enemies
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-046]
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, tasks/T-046-kaiju-meteor-attack.md, game/README.md]
files_expected_to_change: [the meteor boulder script, tests, game/data/enemies.json, docs/enemies.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-046 (the meteor attack) is merged.**

The board played the meteor attack and liked it, with one change (board, 2026-10-15; Enemies, Decisions): a boulder left by a meteor stays for 10 seconds after it lands, then fades away and is gone. While it fades it is still drawn; once it is gone it no longer blocks the car or anything else. Put the 10 seconds and the fade's length in `game/data/enemies.json` with the other meteor numbers, so they can be tuned without code. The map's own boulders are not affected.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test lands a meteor and shows its boulder is still there, fully visible and blocking, just before 10 seconds (QA: pass / fail)
- [ ] A test shows the boulder fades out after 10 seconds (its transparency goes down over the fade) and is then removed: it no longer blocks the car and is no longer in the scene (QA: pass / fail)
- [ ] A test shows the map's own boulders are not removed (QA: pass / fail)
- [ ] The 10 seconds and the fade length are read from `game/data/enemies.json` (QA: pass / fail)
- [ ] `docs/enemies.md` Content and `game/README.md` describe the fade, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-16, Open → In progress

Started: the Enemy Behavior Agent makes meteor boulders fade away after 10 seconds. You'll playtest it in C:\solid-carbide-worktrees\T-142.

## Result notes

Written by the agent when it finishes.

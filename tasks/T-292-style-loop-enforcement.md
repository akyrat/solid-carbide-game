---
id: T-292
title: "Enforce the style loop: no PixelLab call and no art or text ticket to QA without it"
status: open
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-291]
documents_affected: [tasks/README.md, game/README.md]
files_to_read_first: [tasks/README.md, game/README.md, game/tools/pixellab_client.py, tools/task_status.py, tools/style_loop/run.py, tools/goal_agent/build.py]
files_expected_to_change: [game/tools/pixellab_client.py, game/tools/test_pixellab_client.py, tools/task_status.py, tools/test_task_status.py, tools/goal_agent/build.py, tools/goal_agent/test_build.py, tasks/README.md, game/README.md]
model: opus
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

Third of three tickets for the style loop (`tasks/README.md`, "The style loop"). The board's request: no asset or text can be made without going through the loop. Two gates, at the two places all the work already passes through:

1. **PixelLab:** every paid call goes through `game/tools/pixellab_client.py`. Its `generate` refuses to run unless it is inside a style loop run started by `tools/style_loop/run.py` (T-291). For example, the loop writes a run marker and passes its id, and the client checks the marker is live. `balance` keeps working. The refusal message names the loop command.
2. **Art and text tickets:** every status change goes through `tools/task_status.py`. It refuses to move a ticket with `epic: art` or `epic: narrative` to `in-qa` when its `## Style review` section has no rounds, with a message naming the loop.

The goal runner's prompt to headless agents (`tools/goal_agent/build.py`) still says "one round per task" for PixelLab. It changes to the loop rule.

## Acceptance criteria

- [ ] `python game/tools/pixellab_client.py generate ...` run directly, outside a loop, exits non-zero without calling PixelLab, and its message names `tools/style_loop/run.py`. Shown by a unit test with the HTTP call mocked (nothing is charged). (QA: pass / fail)
- [ ] Inside a style loop run (fake mode is enough), the same `generate` call is allowed through to the HTTP layer (mocked in the test). (QA: pass / fail)
- [ ] `python tools/task_status.py <id> in-qa` on an `epic: art` or `epic: narrative` ticket with an empty `## Style review` section is refused with a message naming the loop; with at least one round it is accepted; tickets of other epics are unaffected. Shown by unit tests. (QA: pass / fail)
- [ ] `tools/goal_agent/build.py` no longer tells agents "one round per task" and names the style loop instead; its tests pass. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)
- [ ] `tasks/README.md`, "The style loop", says how it is enforced, replacing "being built in T-290 to T-292", and `game/README.md`'s PixelLab client section says `generate` runs only inside the loop. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

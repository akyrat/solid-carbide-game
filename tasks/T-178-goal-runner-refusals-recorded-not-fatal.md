---
id: T-178
title: Goal runner: a refusal the agent got past is recorded, not a pause
status: open
from: project-lead
to: project-lead
lead:
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/working-with-the-board.md, course-material/goal-oriented-code-agent/README.md]
files_to_read_first: [tasks/README.md, tools/goal_agent/build.py, tools/goal_agent/loop.py, tools/goal_agent/test_build.py, tools/goal_agent/test_loop.py, goals/G-002-add-an-image-of-the.md]
files_expected_to_change: [tools/goal_agent/build.py, tools/goal_agent/loop.py, tools/goal_agent/fake_team.py, tools/goal_agent/fixtures/, tools/goal_agent/test_*.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

G-002 paused again on T-166 (`goals/G-002-add-an-image-of-the.md`, "Pauses"): its agent tried one command outside the board's pre-approved list (a `python -c` check), it was refused, and the agent skipped it, did not work around it, and finished the ticket. `check_refusals` in `build.py` pauses the whole goal on any refusal a headless session reports, so every run would stop at the first unlisted command an agent tries. The board wants goal runs to carry on on their own and gave the Project Lead the decision (board, 2026-10-18).

New rule:
- The agent's and QA's structured results get a field `blocked` (boolean, required): true only when a refused action was essential and the agent or QA could not finish its job without it. The prompts say so: skip a refused action that isn't essential, never work around it, list it in `refusals`, and set `blocked` only when the work can't be finished.
- A session with refusals but `blocked` false: the refusals are written into the goal file's iteration log for that step (and the agent lists them in the ticket's result notes, as the prompt asks), and the ticket goes on as usual (QA judges the criteria).
- `blocked` true pauses the goal (`refusal`) as today, with the refusals in `## Pauses`.
- A refused command the runner itself runs (`Shell`) and a refused status move still pause the goal: nothing changes there.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] A test shows an agent session reporting a refusal with `blocked` false lets the ticket go on to QA and pass, and the refusal is written in the goal file's iteration log (QA: pass / fail)
- [ ] A test shows an agent or QA session with `blocked` true pauses the goal with the refusal in `## Pauses`, and the existing pause tests for the runner's own refused commands still pass (QA: pass / fail)
- [ ] Both prompts tell the agent when to set `blocked`, and `blocked` is required in both result schemas (QA: pass / fail)

## Updates

## Result notes

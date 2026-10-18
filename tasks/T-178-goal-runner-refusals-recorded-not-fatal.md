---
id: T-178
title: Goal runner: a refusal the agent got past is recorded, not a pause
status: done
from: project-lead
to: project-lead
lead: Coursework
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
qa_rounds: 1
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

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass)
- [ ] A test shows an agent session reporting a refusal with `blocked` false lets the ticket go on to QA and pass, and the refusal is written in the goal file's iteration log (QA: pass)
- [ ] A test shows an agent or QA session with `blocked` true pauses the goal with the refusal in `## Pauses`, and the existing pause tests for the runner's own refused commands still pass (QA: pass)
- [ ] Both prompts tell the agent when to set `blocked`, and `blocked` is required in both result schemas (QA: pass)

## Updates

### 2026-10-18, Open → In progress

Quick fix started: a refusal an agent got past (skipped, not worked around) is recorded and the ticket goes on to QA; the run pauses only when an agent says a refusal blocked its work.

### 2026-10-18, In progress → In QA

Built: refusals an agent got past are logged and the ticket goes on; only a blocked agent or QA pauses the run. 309 tools tests pass. QA checks it now.

### 2026-10-18, In QA → Done

QA passed all 4 criteria. Merged; G-002 resumes now.

## Result notes

What changed (tools/goal_agent):
- `build.py`: `AGENT_SCHEMA` and `QA_SCHEMA` have a required boolean `blocked`. Both prompts say: skip a refused action that isn't essential, never work around it, list it in `refusals` (the agent also in its result notes), set `blocked` true only when the work can't be finished without it. `check_refusals` pauses (`refusal`) only when `blocked` is true; a missing `blocked` (and the goal check, whose schema has none) counts as blocked, so it stays safe. Otherwise it returns the refusals (permission denials and reported ones, as text). `run_agent` / `run_qa` return their data with `refusals` set to those; `build_ticket` collects them (prefixed with the agent or `QA:`) into the result's new `refusals` list.
- `loop.py`: `after_ticket` writes them into the step's iteration log entry ("Refused, got past and not blocking: ..."). Docstring and the `refusal` kind text updated. The runner's own refused commands (`Shell`, `command` pause) and refused status moves are untouched and still pause.
- Fixtures: `fixtures/whole-goal.json` agent and QA answers carry `"blocked": false`; the `agent()` / `qa()` helpers in `test_loop.py` default `blocked=False` (`fake_team.py` needed no change: it passes the answer through).

Tests (`tools/goal_agent/test_loop.py`, class Pauses), per criterion:
- Criterion 1: whole suite `python -m unittest discover -s tools -p "test_*.py"`: 309 tests, all pass (no Claude or network).
- Criterion 2: `test_a_refusal_the_agent_got_past_is_logged_and_the_ticket_goes_on` (agent refusal + permission denial, `blocked` false: QA runs, ticket done, both in the iteration log); also `test_a_refusal_qa_got_past_is_logged`.
- Criterion 3: `test_a_blocked_agent_pauses_with_the_refusal_in_the_pauses`, `test_a_blocked_qa_pauses`, `test_a_refusal_without_a_blocked_answer_counts_as_blocked`, and the existing `test_a_refusal_in_a_headless_session`, `test_a_refusal_the_agent_reports` (now `blocked=True`) and `test_a_refused_command` (unchanged) pass.
- Criterion 4: `test_both_schemas_require_blocked_and_the_prompts_explain_it`.

Docs for the Project Lead: `docs/working-with-the-board.md` and `course-material/goal-oriented-code-agent/README.md` (documents_affected) should say that a refusal an agent got past is logged and not a pause; only a `blocked` one pauses. I did not edit docs.

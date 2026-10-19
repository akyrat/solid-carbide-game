---
id: T-190
title: Goal runner: agents take screenshots and QA checks them
status: in-qa
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, tools/goal_agent/build.py, tools/goal_agent/test_build.py]
files_expected_to_change: [tools/goal_agent/build.py, tools/goal_agent/test_build.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Since 2026-10-19 every ticket ends with screenshots wherever anything can be shown (`tasks/README.md`, "Screenshots"; board). In G-003, T-184 (how the platform's sides meet the car) had nothing on screen yet, and its agent wrote "no visuals change, so no screenshots" instead of drawing a picture from the data; QA passed it. The runner's prompts don't mention the rule, so agents and QA rely on reading the README.

Fix, in `tools/goal_agent/build.py`:
1. The agent prompt says: end with screenshots as `tasks/README.md`, "Screenshots" says, in `art-archive/<ticket id>/screenshots/`, listed in the result notes: in-game screenshots when something is on screen; a picture drawn from the data by a script when nothing is on screen yet (a map of a layout, a side view of a motion, a plot of a curve); none only for tooling, docs or text-only work, saying so in one line.
2. The QA prompt says: check the screenshots rule as part of the ticket; a ticket whose work could be pictured (on screen or drawn from its data) and has no screenshots fails, whatever its criteria say.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass)
- [ ] A test shows the agent prompt asks for screenshots in `art-archive/<ticket id>/screenshots/`, including a picture drawn from the data when nothing is on screen, and the QA prompt asks QA to fail a ticket that could be pictured and has none (QA: pass)

## Updates

### 2026-10-19, Open → In progress

Started: the runner's prompts tell agents to take screenshots (or draw a picture from the data) and QA to fail a ticket without them.

### 2026-10-19, In progress → In QA

Built: the agent prompt asks for screenshots (or a picture drawn from the data), and the QA prompt fails a ticket that could be pictured and has none. 331 tools tests pass. QA checks it now.

## Result notes

- `tools/goal_agent/build.py`: new shared constants `SCREENSHOTS_RULE` (added to the agent prompt as a bullet after the ticket-editing rule) and `QA_SCREENSHOTS_RULE` (added to the QA prompt after the same rule), worded as the Description says.
- `tools/goal_agent/test_build.py`: new test `test_agent_prompt_asks_for_screenshots_and_qa_prompt_fails_a_ticket_without_them` in `HeadlessRuns`.
- Full suite `python -m unittest discover -s tools -p "test_*.py"`: 331 tests, OK (no Claude or network calls).
- No screenshots: tooling.

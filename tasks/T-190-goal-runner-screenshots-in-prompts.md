---
id: T-190
title: Goal runner: agents take screenshots and QA checks them
status: open
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

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] A test shows the agent prompt asks for screenshots in `art-archive/<ticket id>/screenshots/`, including a picture drawn from the data when nothing is on screen, and the QA prompt asks QA to fail a ticket that could be pictured and has none (QA: pass / fail)

## Updates

## Result notes

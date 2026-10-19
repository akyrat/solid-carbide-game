---
id: T-189
title: Goal runner: agents and QA edit ticket files with the file editing tool only
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
documents_affected: []
files_to_read_first: [tasks/README.md, tools/goal_agent/build.py, tools/goal_agent/loop.py, tools/goal_agent/test_build.py, goals/G-003-build-the-elevation-system-in.md]
files_expected_to_change: [tools/goal_agent/build.py, tools/goal_agent/loop.py, tools/goal_agent/test_build.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

G-003 paused on T-183 (`goals/G-003-build-the-elevation-system-in.md`, "Pauses"): QA had passed every criterion but wrote its marks into the ticket with a `python -c` script, which the status guard rightly refuses (a script that writes a task file; only the file editing tool's edits are checked line by line, T-181), and QA reported itself blocked. The board wants runs to finish on their own (2026-10-18).

Fix: the agent prompt and the QA prompt in `tools/goal_agent/build.py`, and the goal check's prompt in `tools/goal_agent/loop.py`, say that ticket files (result notes, QA marks, notes) are edited only with the file editing tool (Edit or Write), never with shell commands or scripts, because the guard refuses scripts that write task files. Nothing else changes.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] A test shows the agent, QA and goal check prompts all say to edit ticket files only with the file editing tool, never with scripts or shell commands (QA: pass / fail)

## Updates

## Result notes

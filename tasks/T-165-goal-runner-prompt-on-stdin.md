---
id: T-165
title: Goal runner: send prompts on standard input, and tell the planner the goal's id
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
files_to_read_first: [tasks/README.md, tools/goal_agent/claude_call.py, tools/goal_agent/prioritize.py, tools/goal_agent/run.py, goals/G-002-add-an-image-of-the.md]
files_expected_to_change: [tools/goal_agent/claude_call.py, tools/goal_agent/prioritize.py, tools/goal_agent/test_*.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

The goal runner's second real run (G-002, `goals/G-002-add-an-image-of-the.md`, "Pauses") planned well, then paused in gap detection: `RealClaude.ask` puts the whole prompt on the `claude -p` command line, and the gap prompt (sub-goals plus every ticket header) is longer than Windows allows for a command line (`[WinError 206] The filename or extension is too long`). The board asked for quick fixes to keep the run going (2026-10-18).

1. **Prompt on standard input.** `RealClaude.ask` runs `claude -p` without the prompt as an argument and passes the prompt through standard input (`subprocess.run(..., input=prompt)`), which `claude -p` reads. Everything else on the command line stays as it is (the JSON schema is short). Update the file's docstring to match.
2. **The goal's id in the planning prompt.** The planner wrote `playtest/G-001` in G-002's criteria because the prompt never says which goal it is. `prioritize.plan` takes the goal's id and the prompt says it, including that the goal's build branch is `playtest/<goal id>`; `run.py start` passes it.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] A test (`subprocess.run` mocked) shows `RealClaude.ask` passes the prompt as standard input and not on the command line, with a prompt longer than 40,000 characters (QA: pass / fail)
- [ ] A test shows the planning prompt names the goal's id and its build branch `playtest/<goal id>`, and that `run.py start` passes the new goal's id (QA: pass / fail)

## Updates

## Result notes

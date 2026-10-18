---
id: T-165
title: Goal runner: send prompts on standard input, and tell the planner the goal's id
status: in-progress
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

### 2026-10-18, Open → In progress

Quick fix started: prompts go to Claude on standard input (Windows refused the long command line), and the planner is told the goal's id. Then G-002 resumes.

## Result notes

What changed:
- `tools/goal_agent/claude_call.py`: `RealClaude.ask` no longer puts the prompt on the `claude -p` command line; it passes it as `input=prompt` to `subprocess.run`. Everything else on the command line is unchanged. Docstring updated.
- `tools/goal_agent/prioritize.py`: `prompt(goal_text, goal_id)` and `plan(claude, goal_text, goal_id, root, model)`; the planning prompt states the goal's id and that its build branch is `playtest/<goal id>`.
- `tools/goal_agent/run.py`: `start` passes `goal.id` (created by `goal_file.new` before planning) to `prioritize.plan`.

Tests by criterion:
- Criterion 1: `python -m unittest discover -s tools -p "test_*.py"`: 300 tests, OK (no Claude or network calls).
- Criterion 2: `test_prioritize.Claude.test_a_long_prompt_goes_on_standard_input_not_the_command_line` (50,000-character prompt, `subprocess.run` mocked: `input` is the prompt, no command-line part holds it, command stays short). Also updated `test_real_claude_command_and_denials` and `test_build.RealCommand.test_the_headless_claude_command` to check `input` and that the prompt is absent from the command.
- Criterion 3: `test_prioritize.Plan.test_plan_asks_once_and_ranks` (prompt names `G-007` and `playtest/G-007`) and `test_run.Start.test_start_passes_the_new_goals_id_to_the_planner` (`run.start` passes `G-001`; prompt contains `G-001` and `playtest/G-001`).

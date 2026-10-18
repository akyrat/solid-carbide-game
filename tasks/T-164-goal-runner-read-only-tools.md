---
id: T-164
title: Goal runner: planning and gap detection get only read tools
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
files_to_read_first: [tasks/README.md, tools/goal_agent/claude_call.py, tools/goal_agent/prioritize.py, tools/goal_agent/gaps.py, goals/G-001-add-an-image-of-the.md]
files_expected_to_change: [tools/goal_agent/claude_call.py, tools/goal_agent/prioritize.py, tools/goal_agent/gaps.py, tools/goal_agent/test_*.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

The goal runner's first real run (G-001, `goals/G-001-add-an-image-of-the.md`, "Pauses") paused in layer 1: the planning call passes `--allowedTools Read,Glob,Grep`, which only pre-approves those tools and leaves the others available. Claude tried a read-only `ls`/`grep` through Bash, the headless session refused it (no one to ask), and the runner paused on the refusal, as it should. The board asked for a quick fix (2026-10-18).

Fix: the calls that should only read (priority scoring in `prioritize.py`, gap detection in `gaps.py`) must offer Claude only `Read`, `Glob` and `Grep`, with `claude -p --tools Read,Glob,Grep` (the CLI's flag for the list of available tools), so no other tool can be tried. Add a `tools` option to `RealClaude.ask` for it, next to the existing options, and use it in those two calls (keeping `--allowedTools` for the same tools is fine). The building and QA calls (layer 3 and the goal check) keep their full tools: nothing changes there. A refusal still pauses the run.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] A test checks that `RealClaude.ask` with `tools` puts `--tools Read,Glob,Grep` on the `claude -p` command line (`subprocess.run` mocked), and one that the priority scoring and gap detection calls pass exactly `Read,Glob,Grep` as `tools` (QA: pass / fail)
- [ ] The agent and QA calls in `build.py` and the goal check in `loop.py` pass no `tools` (their command lines are unchanged), shown by reading the code or a test (QA: pass / fail)

## Updates

## Result notes

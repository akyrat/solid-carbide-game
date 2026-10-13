---
id: T-122
title: The hooks refuse to start an agent on a task with the wrong model
status: in-progress
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/hooks/board_gate.py, .claude/settings.json, tools/test_task_status.py]
files_expected_to_change: [.claude/hooks/board_gate.py, .claude/settings.json, tools/test_task_status.py, tasks/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board found that agents were started on Opus although their task files said Sonnet (2026-10-13): agents started without a model run on the Project Lead's model. The board wants the rule "an agent runs on the model in its task file" enforced by the task board's hooks, not left to memory.

Add a PreToolUse check for the Agent tool to `.claude/hooks/board_gate.py` (wired in `.claude/settings.json`):

1. **Which task:** the first task id (`T-<number>`) in the agent's prompt, when a matching file exists in `tasks/`. Prompts start with it ("Work on task T-121", "QA round 1 for task T-065", "Continue task T-084"). No task id, or a fork: no check.
2. **Which model:** the task file's `model` line. For the QA/Integration Agent (`qa-integration`), the `tasks/README.md` "Models" rule: sonnet, but opus when the task has a `The board's review:` line (QA of a task the board is about to playtest).
3. **The check:** the Agent call must pass `model` equal to that model. Missing or different: refuse, saying which task, which model it needs and why, so the Project Lead relaunches with it (or changes the task file's model first, for example after a failed QA round).
4. Tests in `tools/test_task_status.py`, next to the existing hook tests.
5. `tasks/README.md`, "Models", says the hooks enforce it.

## Acceptance criteria

- [ ] Tests show: an agent on a sonnet task without `model` or with `opus` is refused, and with `sonnet` is allowed; an opus task needs `opus`; a QA agent needs sonnet, or opus when the task has a board's review line; a prompt with no task id, an unknown task id or a fork is allowed (QA: pass / fail)
- [ ] `.claude/settings.json` runs the hook before Agent calls, and the refusal message names the task and the model needed (QA: pass / fail)
- [ ] `tasks/README.md`, "Models", says the hooks enforce the model (QA: pass / fail)
- [ ] All Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

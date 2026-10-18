---
id: T-177
title: Goal runner: tell headless agents which commands are pre-approved
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
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, .claude/settings.json, tools/goal_agent/build.py, tools/goal_agent/test_build.py, goals/G-002-add-an-image-of-the.md]
files_expected_to_change: [tools/goal_agent/build.py, tools/goal_agent/test_build.py]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

G-002 paused on its first ticket (T-166, `goals/G-002-add-an-image-of-the.md`, "Pauses"): the headless agents run with `--permission-mode acceptEdits`, so every shell command they needed (the game's tests, `git add`, `git commit`) needed an approval nobody could give, and was refused. The board added a narrow allowlist of the commands agents need to the project's `.claude/settings.json` (board, 2026-10-18), which every task folder gets. The agents keep `acceptEdits`; anything outside the list is still refused and still pauses the run.

Fix: the prompt `build.py` gives each headless agent and QA session says which commands are pre-approved, read from the `permissions.allow` list in `.claude/settings.json` (so it never drifts from the settings), and asks the agent to run them as plain, separate Bash commands (no `&&` chains, pipes into other programs, heredocs or PowerShell for them), since anything else needs an approval it can't get.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass)
- [ ] A test shows the agent and QA prompts list the `permissions.allow` entries read from a settings file and ask for plain, separate Bash commands; a missing or empty list leaves the prompt as it was (QA: pass)
- [ ] The headless sessions still run with `--permission-mode acceptEdits` (a test or the code) (QA: pass)

## Updates

### 2026-10-18, Open → In progress

Started: the runner will tell its headless agents which commands the board pre-approved in the settings. Then G-002 resumes.

### 2026-10-18, In progress → In QA

Built: the runner lists the pre-approved commands from the settings in every agent and QA prompt, and asks for plain separate commands. 303 tools tests pass. QA checks it now.

### 2026-10-18, In QA → Done

QA passed all 3 criteria. Merged; G-002 resumes now.

## Result notes

- `tools/goal_agent/build.py`: new `pre_approved(root)` reads `permissions.allow` from `<root>/.claude/settings.json` (empty list when the file, key or list is missing or unreadable) and `pre_approved_note(root)` builds the prompt lines ('' when none). `agent_prompt` and `qa_prompt` append it (root = the runner's main checkout, `b.root`): the entries, then a request to run them as plain, separate Bash commands (no `&&` chains, pipes into other programs, heredocs or PowerShell). `PERMISSION_MODE` stays `acceptEdits`.
- Tests in `tools/goal_agent/test_build.py` (`HeadlessRuns`): criterion 2: `test_prompts_list_the_pre_approved_commands_from_the_settings` (temp settings file, agent and QA prompts), `test_a_missing_or_empty_list_leaves_the_prompts_as_they_were` (no file, empty list, no key); criterion 3: `test_the_sessions_keep_accept_edits` plus the existing `options["permission_mode"]` check.
- Criterion 1: `python -m unittest discover -s tools -p "test_*.py"` runs 303 tests, all OK, no Claude or network calls.

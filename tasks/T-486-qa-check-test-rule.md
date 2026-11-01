---
id: T-486
title: qa_check.py follows the new test rule: the tools set only when tools change, and a marks-only second run
status: in-progress
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, tools/qa_check.py, tools/test_qa_check.py, tools/goal_agent/]
files_expected_to_change: [tools/qa_check.py, tools/test_qa_check.py, tools/goal_agent/, tasks/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-01 (tasks/README.md, "Which tests run when"): each full run of the test sets is paid once per stage. The agent runs only the tests for what it changed; QA runs the full sets once; the merge runs them once per batch. Bring the tools in line:

1. `tools/qa_check.py` runs the `tools` Python set (the studio's own scripts) only when the ticket's branch changes something under `tools/` or `.claude/` against `--base`; otherwise its tests line says the set was skipped and why. The Godot set and the `game/tools` set always run. A flag forces all three.
2. QA's second run after marking checks only the marks: make that the documented way (`--no-tests`, or a `--marks-only` alias), and say so in the script's usage.
3. The goal runner's prompts (tools/goal_agent/): wherever they tell an agent to run all three sets before handing back, they now say the agent runs the tests for what it changed, and QA's prompt follows the rule above. Find each place and list it in the result notes.
4. tasks/README.md ("Which tests run when", "QA") matches what the script does.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows qa_check skips the tools set on a branch that changes nothing under tools/ or .claude/, and runs it on one that does; the skip is printed on the tests line. (QA: pass / fail)
- [ ] A test shows the force flag runs all three sets. (QA: pass / fail)
- [ ] The usage text documents the marks-only second run. (QA: pass / fail)
- [ ] The goal runner's prompts follow the new rule; the result notes list each changed place, and the goal runner's own tests pass. (QA: pass / fail)
- [ ] tasks/README.md matches the script. (QA: pass / fail)
- [ ] The tools Python tests pass (`python -m unittest discover -s tools -p "test_*.py"`), with the count in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: qa_check follows the new test rule.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

qa_check.py now follows the test rule (T-486).

- tools/qa_check.py: the default sets are DEFAULT_SETS; the `tools` set runs only when the branch changes something under tools/ or .claude/ against --base; otherwise the tests line ends "(tools set skipped: the branch changes nothing under tools/ or .claude/)". `--all-tests` forces all three. `--marks-only` is an alias of `--no-tests`; the usage docstring documents the marks-only second run.
- tools/test_qa_check.py: 4 new tests (skip when no tools/.claude change; run on tools/ and on .claude/ change; --all-tests runs all three; --marks-only/--no-tests skip tests and usage mentions both flags).
- Goal runner prompts changed (tools/goal_agent/build.py): (1) agent_prompt, the "Write tests for your code and run them" line, now says run the tests for what you changed, not the three full sets, and list what was run; (2) qa_prompt now tells QA to run qa_check --no-marks once for the full sets (tools set skipped if tools/.claude untouched) and --marks-only after marking. No other place in tools/goal_agent/ (loop.py goal check, gaps, prioritize, tickets) tells an agent to run all three sets.
- tasks/README.md: "Which tests run when" and "QA" describe the skip, --all-tests and --marks-only.

Tests run: python -m unittest tools.test_qa_check (10 tests, OK); goal_agent test_build, test_loop, test_run: see below. Godot set not run (rule). Nothing under game/data/levels/ touched.

Update: goal_agent test_build + test_loop + test_run: 64 tests OK (run after the prompt edits); tools.test_qa_check: 10 OK.

---
id: T-358
title: Token spend: where a QA run spends its calls
status: open
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/token-spend/qa-calls-2026-10-29.md, docs/README.md]
files_to_read_first: [docs/token-spend/after-2026-10-29.md, docs/token-spend/baseline-2026-10-28.md, tools/token_report.py, tools/qa_check.py, .claude/agents/qa-integration.md, tasks/README.md]
files_expected_to_change: [tools/qa_calls.py, tools/test_qa_calls.py, docs/token-spend/qa-calls-2026-10-29.md, docs/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's go (2026-10-29), from `docs/token-spend/after-2026-10-29.md`: QA took about 33 calls per merged ticket (533 qa-integration calls for 16 tickets) against 12.3 in the baseline, though T-347 meant to make QA cheaper. Find out where a QA run spends its calls, and propose cuts. This is analysis: no change to QA's definition, the guard or the scripts it uses.

Write a script, `tools/qa_calls.py`, that reads the qa-integration subagent transcripts (same layout and reading code as `tools/token_report.py`: `<dir>/<session>/subagents/agent-*.jsonl` with `.meta.json`; streamed, never modified) for a time range, and for each QA run prints: the ticket it checked (from its prompt), calls, cache read, and its tool calls grouped by kind (test runs, polling or waiting such as Monitor, sleep, BashOutput, tail of a log; `qa_check.py`; reading the ticket and diff; screenshots and images; git; Edit/Write of the ticket; other), plus how many calls were failures and of what kind. Also a total by kind, and the same for the baseline period (to 2026-10-28T01:43:02Z) so the two can be compared.

Run it for the period from 2026-10-28T03:55:00Z to 2026-10-29T01:10:00Z and for the baseline, and write `docs/token-spend/qa-calls-2026-10-29.md`: the tables, the three dearest QA runs looked at by hand (what took their calls), and a short list of proposed cuts, each with the calls it would have saved in this period. Proposals only; the board decides. Agents never read whole transcripts into context: the script summarises them. Nothing to picture.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `tools/qa_calls.py` runs with `--from`, `--to` and `--dir` like token_report.py, and `tools/test_qa_calls.py` tests its grouping on small made-up transcripts (at least: a test run, a poll, a qa_check.py call, a screenshot read, a failure). (QA: pass / fail)
- [ ] `docs/token-spend/qa-calls-2026-10-29.md` has per-run and by-kind tables for the period and for the baseline, with total QA calls matching token_report.py's qa-integration count for the same range within 5%, or the difference explained. (QA: pass / fail)
- [ ] The doc names the three dearest QA runs in the period and what took their calls. (QA: pass / fail)
- [ ] The doc lists proposed cuts, each with the calls it would have saved in the period, and says which are proposals for the board. (QA: pass / fail)
- [ ] `docs/README.md` links the new doc and the script in its token-spend line. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

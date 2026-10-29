---
id: T-358
title: Token spend: where a QA run spends its calls
status: done
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
qa_rounds: 1
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

- [ ] `tools/qa_calls.py` runs with `--from`, `--to` and `--dir` like token_report.py, and `tools/test_qa_calls.py` tests its grouping on small made-up transcripts (at least: a test run, a poll, a qa_check.py call, a screenshot read, a failure). (QA: pass; script takes --from/--to/--dir, 5 tests cover test run, polls, qa_check, screenshot, failures)
- [ ] `docs/token-spend/qa-calls-2026-10-29.md` has per-run and by-kind tables for the period and for the baseline, with total QA calls matching token_report.py's qa-integration count for the same range within 5%, or the difference explained. (QA: pass; tables match my rerun (533 calls, 610 tool calls, 73 failed) and token_report's 533 exactly; baseline difference explained)
- [ ] The doc names the three dearest QA runs in the period and what took their calls. (QA: pass; a1575a33, acaa27b3, a3e6e13f named with what took their calls)
- [ ] The doc lists proposed cuts, each with the calls it would have saved in the period, and says which are proposals for the board. (QA: pass; four cuts, arithmetic follows (240-54=186 ~160, 117-18=99 ~86, 422-246=176, 10/run), labelled proposals)
- [ ] `docs/README.md` links the new doc and the script in its token-spend line. (QA: pass; token-spend line links script and doc)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; tools set rerun by me: 565 OK; other two counts recorded in notes (657, 1816))

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: a script groups the QA agents' calls by kind, and a doc names the dearest runs and proposes cuts.

### 2026-10-29, In progress → In QA

In QA: QA's calls go mostly to polling the three test sets (about 15 min, over the 10-min foreground limit), then to writing the marks.

### 2026-10-29, Done

Merged: QA's calls go to waiting for the tests and writing marks; proposed cuts are in docs/token-spend/qa-calls-2026-10-29.md for the board.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**T-358, 2026-10-29 (opus).** Done: `tools/qa_calls.py`, `tools/test_qa_calls.py` (5 tests), `docs/token-spend/qa-calls-2026-10-29.md`, and the token-spend line in `docs/README.md` now links the script and the doc.

- `tools/qa_calls.py` takes `--from`, `--to`, `--dir` like token_report.py (reuses its `in_range`, `usage_of`, `error_kind`, default dir), plus `--out`, `--top N` and `--detail AGENT_ID` (one run's tool calls in order, with failures, so a dear run can be read without reading its transcript). Kinds: test run, poll / wait, qa_check.py, ticket and diff, screenshots / images, git, ticket edit, read / search other files, other. Tests cover each kind (test run, Monitor/sleep/echo/output-file polls, qa_check.py, screenshot read and script, ticket read/diff, git commit, ticket edits), dedup of streamed messages, the range, two failures (sleep blocked, edit before read), the ticket from description or prompt, the report and `main --out`.
- Totals match token_report.py exactly for the same ranges: period 533 qa-integration calls, baseline 3,656. The baseline doc's 3,507 was token_report's count when the baseline was taken; rerun today over the same range token_report itself gives 3,656 (explained in the doc).

Headline findings:
1. Two of the 20 "QA" runs were playtest-build merges given to the qa-integration agent (111 of 533 calls); real QA: 18 runs, 23.4 calls each against 13.3 in the baseline.
2. Waiting for the tests is the biggest cost: tests, qa_check and polling 13.3 tool calls per run (polling alone 11.3) against 4.5 in the baseline. The three sets take about 15 min in a row (87 s + 337 s + 472 s here), over one foreground command's 10-minute limit, so QA backgrounds them and polls; the final `qa_check.py` also reruns all tests.
3. Writing the marks is second: 6.5 ticket edits per run, 40 failed (python/sed writes refused by the guard, then Edit before Read).
4. Proposed cuts (board's call): tests waited on in one call and last check `--no-tests` (about 160 calls), one command for the marks (about 86), playtest merges off the QA agent (111 out of QA's count). With the first two, about 10 calls per QA run.

Observation for the Project Lead: while running T-358's own tests, a foreground Bash command (the tools set, 337 s) was moved to the background after 180 s even with a 600 s timeout; the Godot suite (472 s, 517 s) was not. This likely also pushes QA into polling.

Tests (all green, foreground): game/tools 657 tests OK (1 skipped); tools 565 tests OK (this ran past 180 s and was moved to the background by the tool, result read from its output file; after the docs edits test_new_ticket, test_guard and test_qa_calls were rerun: 101 OK); Godot suite 148 scripts, 1816 tests, 1816 passing, TESTS PASSED.

**QA, 2026-10-29 (sonnet).** All 6 criteria pass. Reran qa_calls.py for the period: tables match the doc and token_report's qa-integration count (533). tools test set: 565 OK in the foreground.
- 2026-10-29, in-qa → done: QA passed 6/6; analysis only, the cuts are proposals for the board.

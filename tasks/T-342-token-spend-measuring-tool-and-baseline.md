---
id: T-342
title: Token spend: a measuring tool and the baseline report
status: in-progress
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, tools/taskboard/taskboard.html]
files_expected_to_change: [tools/token_report.py, tools/test_token_report.py, docs/token-spend/baseline-2026-10-28.md, tools/taskboard/taskboard.html, docs/README.md]
model: sonnet
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

The board wants the effect of the token-spend epic measured, not guessed. Turn the Tokens session's one-off recon into a repo tool, `tools/token_report.py`, and use it to write the baseline now, before the epic's other tickets merge.

The tool reads the Claude Code transcripts in `C:\Users\andre\.claude\projects\C--solid-carbide-game\` (main sessions `<id>.jsonl` and the subagent transcripts in each `<id>\` folder; about 1.7 GB, so it streams them line by line and never loads a file whole), deduplicates usage by `message.id`, and takes a date range (`--from`, `--to`) so the same measures can be compared before and after. It reports: (1) tokens by kind (input, cache creation, cache read, output) and by model, main sessions vs subagents, and by subagent type; (2) calls per session, context size per call (average, peak), compactions; (3) what fills the main sessions' context, by category (typed prompts, assistant text, tool inputs, tool results by tool and by Bash command kind, subagent reports, system reminders and hooks), as a share and as a weighted cost (characters x calls remaining until the next compaction or the end); (4) failed tool calls (edit-before-read, hook refusals, sleeps); and from the tickets: QA rounds and fail rate by agent and model, and model choice counts. The Tokens session's scratch scripts may help: `C:\Users\andre\AppData\Local\Temp\claude\C--solid-carbide-game\2c104619-72b8-44ca-a9af-e1e03eadc5a7\scratchpad\recon-bigsessions\`.

Run it for everything up to 2026-10-28 and save the result as `docs/token-spend/baseline-2026-10-28.md` (tables, plain text). Known figures to reproduce within 2%: session `88cd5834` 2,283 calls and 883M cache-read tokens; session `ac11e792` 1,237 calls and 546M.

Also, so the board sees the epic's tickets together: add a `Token spend` bubble for the `token-spend` epic to the task board's areas (`tools/taskboard/taskboard.html`, `AREAS`), left out of the MVP figure like Tooling.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `python tools/token_report.py --to 2026-10-28` runs without error and its numbers for sessions `88cd5834` (2,283 calls, 883M cache read) and `ac11e792` (1,237 calls, 546M) are within 2%. (QA: pass / fail)
- [ ] `docs/token-spend/baseline-2026-10-28.md` exists and holds the four groups of measures in the description, plus the ticket measures (QA fail rate by agent and model, model counts). (QA: pass / fail)
- [ ] The tool takes `--from` and `--to` and only counts calls inside the range (a unit test on a small fixture transcript checks it, and the deduplication by `message.id`). (QA: pass / fail)
- [ ] The task board shows a Token spend bubble holding the `token-spend` tickets, not counted in the MVP figure. (QA: pass / fail)
- [ ] `docs/README.md` says what the tool is and how to run it. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the measuring tool and the baseline, first so the numbers are taken before anything changes.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Nothing to picture (a tool, a report and one board bubble).

**Built**
- `tools/token_report.py`: streams every transcript line by line (main `<id>.jsonl` and `<id>/subagents/agent-*.jsonl` with the `.meta.json` agent type), `--from`/`--to` (dates of the calls, both ends inclusive), `--dir`, `--tasks`, `--out`, `--session <id prefix>` (repeatable). The full run takes a few seconds. Usage is deduplicated by `message.id`: per file for the per-session figures (this reproduces the known numbers), and across files for the totals, so a forked session's copied messages are not counted twice. It prints five groups: (1) tokens by kind, scope, model and subagent type; (2) calls, average and peak context, compactions per session; (3) what fills the main sessions' context (share and weighted cost, Bash results by command kind); (4) failed tool calls (edit before read, hook refusal, sleep blocked, permission refusal, other) and top tools; (5) from the tickets, QA rounds and fail rate by agent and model, and model counts.
- `tools/test_token_report.py`: 6 tests on a small fixture (dedup by message id, date range, compactions, subagent type, error kinds, report headings, ticket reading).
- `docs/token-spend/baseline-2026-10-28.md`: `python tools/token_report.py --to 2026-10-28 --out docs/token-spend/baseline-2026-10-28.md`.
- Task board: a `Token spend` bubble in `AREAS` (`tools/taskboard/taskboard.html`), `excluded: true`, so it is not in the MVP figure.
- `docs/README.md`: a "Token spend" paragraph (what it is, how to run it).

**Baseline, headline numbers (everything to 2026-10-28)**
- 20,248 calls, cache read 3,406M, cache creation 110M, output 5.7M (input tokens are about 0). Main sessions 2,032M cache read (6,566 calls), subagents 1,373M.
- By model: opus 2,805M cache read (12,879 calls), sonnet 592M (7,096 calls).
- Largest subagent types by cache read: asset-generation 271M, level-challenge 225M, qa-integration 200M, driving-drift 175M.
- Check figures: `88cd5834` 2,283 calls, 883.0M cache read (known 2,283 / 883M); `ac11e792` 1,237 calls, 546.3M (known 1,237 / 546M). Exact match.
- What fills main-session context (share of weighted cost): tool inputs 25%, Bash results 23%, system reminders and hooks 21%, subagent reports 14%, assistant text 7%.
- Failed tool calls: 1,178 of 23,184 (5.1%): edit before read 390 (only 8 in main sessions), hook refusals 287, other 372, sleep blocked 74, permission refusals 55.
- Tickets: 352; model counts sonnet 210, opus 112, unset 30; 286 went to QA.

**Tests**: `python -m unittest discover -s tools -p "test_*.py"` 507 OK (includes the 6 new tests); `python -m unittest discover -s game/tools -p "test_*.py"` 620 OK (1 skipped); `bash game/tools/run_tests.sh` TESTS PASSED (GUT "All tests passed"; I only kept the last lines of its output, so no test count).

**Unsure / notes**
- QA fail counts from the tickets are a lower bound: QA replaces a fail mark with its later pass, so only 9 tickets still show a fail mark; the QA rounds column shows retries.
- The tickets carry no run date, so section 5 ignores the date range.
- "Context size" is input plus cache creation plus cache read of each call. The weighted cost uses characters, not tokens.
- Godot's runs touched `.import` files in the worktree (line endings); I did not stage them.

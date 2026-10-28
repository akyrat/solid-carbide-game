# Token spend: early read after the new tools (2026-10-28)

Ticket T-350. Written by the Tokens session on 2026-10-28, about two hours after the first new tool went in.

## Read this first

This is an early read, not the after report the ticket imagined. No playtest batch has gone through the new tools yet. The sample is small and unlike the baseline.

- Period covered: 2026-10-28 from 01:43:02Z (the commit "Merge T-344 and T-348", the first new tools in use) to the time of this run, about 03:55Z. Just over two hours.
- 299 calls (91 in one main session, 208 in its subagents), against 20,248 in the baseline. Six tickets merged in the period: T-344, T-348, T-343, T-346, T-349, T-347.
- Almost all of it is one session (Tokens, `2c104619`) building the epic itself: tooling and docs tickets, run by `general-purpose` and `qa-integration` subagents on Sonnet. No art, level, driving or UI tickets, which are most of the baseline's cost. Per-ticket and per-call figures are therefore not like for like.
- Only the main project's transcripts are read (`~/.claude/projects/C--solid-carbide-game`), the same as the baseline. Sessions that ran in ticket worktrees have their transcripts in other folders and are in neither report.

Numbers that cannot be read yet: the weighted cost shares (small contexts, few calls), the QA second-round rate (the eight epic tickets all had one QA round, but eight is too few), model choice (set by the epic's own tickets), compactions (none in the period) and anything "per typed prompt" (the tool reports the characters of typed prompts, not their number, in both reports; the measure is per call here).

## Method

Both commands are under "Rerun". `tools/token_report.py` got one small change for this read: `--from` and `--to` also accept a time (`2026-10-28T01:43:02Z`, UTC), because a date-only bound cannot separate the hours before and after the first merge. Dates work as before; `tools/test_token_report.py` covers it.

## Measures next to the baseline

Baseline = `docs/token-spend/baseline-2026-10-28.md`. Tokens are cache creation + cache read + output (input is 0.0M in both).

| measure | baseline | this period | reading |
|---|---|---|---|
| calls | 20,248 (6,408 main, 13,840 subagent) | 299 (91 main, 208 subagent) | not comparable in size |
| tokens per ticket done or merged | 3,521.8M / 282 done = 12.5M | 29.8M / 6 merged = 5.0M | lower, but different work (tooling tickets, small contexts); not evidence of an effect |
| cache read per main-session call | 2,031.6M / 6,408 = 317k | 14.4M / 93 = 155k | about half; mostly a young session, see "Other changes" |
| average context per main call | 317k | 156k (Tokens session alone 160k) | as above |
| peak context | 966k | 206k | no session was long enough to reach the old range; the 500k limit is untested |
| compactions | 9 in 32 sessions | 0 | too short to tell |
| subagent share of cache read | 1,374M of 3,406M = 40% | 13.8M of 28.2M = 49% | same order; this period is subagent-heavy by nature |
| subagent model | about half opus (6,472 of 13,840 calls) | all Sonnet (208 of 208) | the epic's tickets were set to sonnet (T-348 opus, but its subagent calls fall mostly outside the period); the main session is opus in both |
| failed tool calls | 1,180 of 23,207 = 5.1% | 34 of 349 = 9.7% | higher |
| hook refusals | 289 (1.2% of calls) | 15 (4.3%) | higher; the report does not say which guard refused |
| edit before read | 390 (1.7%) | 10 (2.9%) | higher, small count |
| sleep blocked | 74 (0.3%) | 1 (0.3%) | flat |
| QA fail rate (tickets with a fail mark / tickets that went to QA) | 9 / 286 = 3.1% | 10 / 294 = 3.4% | one more fail mark in the whole project; T-342 to T-349 all have `qa_rounds: 1` |
| second QA round among T-342 to T-349 | not applicable | 0 of 8 | too few to read as a rate |

### Where the main sessions' context went (weighted share)

| category | baseline | this period | reading |
|---|---|---|---|
| subagent reports | 14.3% | 18.5% | higher, not lower; see T-343 |
| tool inputs (all) | 25.1% | 30.5% | higher (Agent prompts, Write of tickets and docs) |
| tool results: Bash | 22.9% | 14.0% | lower |
| system reminders / hooks | 20.9% | 22.9% | flat |
| typed prompts | 2.2% | 1.0% | lower |

### Average Bash result size by command kind (characters)

| kind | baseline | this period | calls now |
|---|---|---|---|
| git merge/push | 1,849 | 199 | 11 |
| git inspect | 1,410 | 808 | 8 |
| task_status.py | 612 | 238 | 7 |
| cat/sed/head/tail | 2,353 | 2,506 | 3 |
| grep/rg | 1,951 | 184 | 2 |
| test run | 475 | 160 | 5 |

The counts are tiny (2 to 11 calls). The merge and task-status rows have a plausible mechanism (T-344, T-345); the grep row is two calls and means nothing.

## The Tokens session on its own (`2c104619`)

In the period (from 01:43:02Z): 91 main calls, average context 160k, peak 206k, 14.5M cache read in the main session; 208 subagent calls, 13.9M cache read; 34 failed of 353 tool calls (9.6%: 15 hook refusals, 10 edit before read, 8 other, 1 sleep blocked). Subagents: 142 `general-purpose`, 66 `qa-integration`, all Sonnet.

The whole session so far (including the recon and baseline work before 01:43Z): 230 main calls, average context 138k, peak 206k, one compaction, 31.4M cache read in the main session; 649 subagent calls, 45.0M cache read; 103 failed of 974 tool calls (10.6%).

This one session is about 97 percent of the period's calls, so its numbers are the period's numbers, not a second sample.

## Each ticket: what it was meant to cut, and what the numbers show

| ticket | meant to cut | what the numbers show |
|---|---|---|
| T-343 agents hand back one short line | Subagent report text that stays in the main session's context (14.3% of weighted cost in the baseline). | Not shown. Subagent reports are 18.5% here, higher than baseline. T-343 merged at 02:31Z, so most subagents in the period started under the old rule, and they were tooling tickets. Needs a batch of product tickets. |
| T-344 one script merges a batch | The merge output and the many separate calls per merge (313 git merge/push calls at 1,849 characters average in the baseline). | A signal: 11 git merge/push calls at 199 characters average, and `merge_batch.py` results average 884. Six tickets merged in about two hours. Small count; a signal, not a measurement. |
| T-345 one script writes a ticket's paperwork | The many `task_status.py` calls and ticket-file edits (643 calls, 612 characters average in the baseline). | Weak signal: `task_status.py` results average 238 characters in 7 calls; `new_ticket.py` was called once. Too few calls to read calls per ticket. |
| T-346 game README split into area folders | The size of what agents read to find game facts. | Cannot be told. No product ticket in the period read game areas. Needs a batch. |
| T-347 QA checks the criteria and the tests | QA's calls per ticket (qa-integration: 3,507 calls, 199.5M cache read in the baseline). | Not shown yet: 66 QA calls and 3.3M cache read in the period, about 11 calls per QA'd ticket (6 to 8 tickets) against 3,507 / 286 = 12.3 in the baseline. `qa_check.py` was used once and merged only at 03:50Z, so almost every QA run here used the old way. |
| T-348 guard allows read-only commands again | Refused read-only commands (289 hook refusals, 104 in main sessions, in the baseline). | Not shown. Hook refusals are 15 of 349 calls (4.3%), more than the baseline's 1.2%, one of them in the main session. The report does not separate which guard refused or whether it should have. |
| T-349 guard against very large shell output | Whole big files printed into the context (cat/sed/head/tail: 267 calls at 2,353 characters average). | Not shown. 3 calls at 2,506 characters average; T-349 merged at 02:55Z, more than halfway through the period. Needs a normal batch. |

T-342 (the measuring tool and baseline) cuts nothing by itself; its use is this report.

## Other changes in the period, and what cannot be told apart

- The board set the auto-compact limit to 500k on 2026-10-28. It acts only on long main sessions (the baseline's biggest peaked at 966k). No session in the period passed 206k, so the limit had no chance to act. Any fall in average or peak context here is a young session, not the limit; the limit's effect and the epic tickets' effect on context size cannot be told apart, and with this sample neither can be seen.
- Different work: the period is tooling and docs tickets built by Sonnet agents. The baseline is mostly game tickets, many with art, level and driving work and long agent loops. Lower tokens per ticket here is mostly that.
- Model mix: the epic's tickets were set mostly to sonnet; the baseline's subagent mix was about half opus. A Sonnet-heavy period uses fewer tokens of the dearer model whatever the tools do. This is not an effect of the tools.
- The guards changed in these same hours (T-348 loosened one rule, T-349 added one), and the failure table mixes both.
- The baseline ends partway through 2026-10-28 and the period starts later the same day; the baseline's last hours are not in this period, so the two do not overlap.
- The Tokens session spends tokens measuring and reporting the epic (the recon, this report), and that is inside the period.

## What this does and does not say

Does: the new tools run (batch merge, QA check, ticket script, guards); merge and task-status output is visibly shorter; nothing broke.

Does not: show that the epic cut token spend. The per-ticket figure (5.0M against 12.5M) is real arithmetic but should not be credited to the tickets. Failed calls and hook refusals went up, and subagent reports did not shrink.

## Rerun after the next playtest batch

After the HUD batch (built by the Greenbull session) is merged, run from the main checkout, from the time its first agent started (the period above began 2026-10-28T01:43:02Z and this read ran at about 03:55Z, so start no earlier than 2026-10-28T03:55:00Z):

    python tools/token_report.py --from 2026-10-28T03:55:00Z --out docs/token-spend/after-<date>-raw.md

Add `--session 2c104619` for the Tokens session alone, or `--session <id>` for the Greenbull session. Then write `docs/token-spend/after-<date>.md` with the same tables as this file and keep this early read. Sessions that ran in ticket worktrees are in other folders under `~/.claude/projects`; pass one with `--dir` if the batch ran there.

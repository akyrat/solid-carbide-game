---
id: T-350
title: Token spend: the after report, compared with the baseline
status: in-qa
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-342, T-343, T-344, T-345, T-346, T-347, T-348, T-349]
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, docs/token-spend/baseline-2026-10-28.md, tools/token_report.py]
files_expected_to_change: [docs/token-spend/]
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

The board wants to see the epic's real effect (2026-10-28). Once the epic's other tickets are merged and the studio has worked with them for a while (the board says when: at least one playtest batch built and merged with the new tools), run `tools/token_report.py` (T-342) on the sessions after the last of them merged, and write `docs/token-spend/after-<date>.md` comparing each measure with `docs/token-spend/baseline-2026-10-28.md`.

Compare per unit of work, not raw totals, since the periods differ in length: tokens per ticket merged, per main-session call and per typed prompt; average and peak context; the weighted cost by category (subagent reports, git output, ticket writing, searches and file prints); failed tool calls; QA second-round rate; and model choice. For each of the epic's tickets, say what it was meant to cut and whether the numbers show it. Say plainly what changed for other reasons (for example the board's auto-compact limit, set to 500k on 2026-10-28) and what can't be told apart.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `docs/token-spend/after-<date>.md` exists, names the date range it covers, and gives each measure next to the baseline's with the change. (QA: pass / fail)
- [ ] Every comparison is per unit of work (per ticket merged, per call or per typed prompt), not only totals. (QA: pass / fail)
- [ ] Each of T-343 to T-349 has a line saying what it was meant to cut and what the numbers show. (QA: pass / fail)
- [ ] The report names the other changes in the period (at least the 500k auto-compact limit) and what can't be told apart. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started on your go to finish the epic tonight: an early read of the period since the new tools merged, with the command to rerun it after the next playtest batch.

### 2026-10-28, In progress

Report written and committed on the branch: docs/token-spend/after-2026-10-28-early.md (an early read; tests pass). Waiting for the board: the agent's write of its result notes was refused (guard) and its Edit denied (auto mode), so it can't move to QA. Nothing worked around it.

### 2026-10-28, In progress → In QA

Result notes written on the board's go; the early read is in QA now. It merges straight after QA (a report, nothing the player sees).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the Project Lead from the agent's hand-back, on the board's go (2026-10-28): the agent's own write of these notes was refused by the guard (inline Python) and its Edit was denied by auto mode; it did not work around either.

An early read, not the full after report: the board asked for the epic to finish overnight, before any playtest batch went through the new tools. Nothing to picture.

- `docs/token-spend/after-2026-10-28-early.md` (new): covers 2026-10-28T01:43:02Z (the commit "Merge T-344 and T-348") to about 03:55Z, 299 calls, six tickets merged, and the Tokens session (`2c104619`) on its own. It opens by saying the sample is small and unlike the baseline; gives each measure next to the baseline's, per merged ticket and per call; has a line for each of T-343 to T-349; names the other changes (the 500k auto-compact limit, different work, model mix, the guard changes) and what can't be told apart; and ends with the command to rerun it after the HUD batch.
- Headline: 5.0M tokens per merged ticket against 12.5M (different work; not credited to the tickets); git merge/push output 199 characters per call against 1,849 (the one plausible effect, T-344, 11 calls); failed calls 9.7% against 5.1%, hook refusals 4.3% against 1.2%; subagent reports 18.5% of weighted context against 14.3%; the 500k limit untested (no session passed 206k).
- `tools/token_report.py`: `--from`/`--to` also accept a UTC time, since a date can't split the day at 01:43Z; `tools/test_token_report.py` has a test for it. `docs/README.md`: the rerun note and a pointer to the early read.
- Tests (foreground): `python -m unittest discover -s game/tools -p "test_*.py"`: Ran 620, OK (1 skipped). `python -m unittest discover -s tools -p "test_*.py"`: Ran 546, OK. `bash game/tools/run_tests.sh`: TESTS PASSED.

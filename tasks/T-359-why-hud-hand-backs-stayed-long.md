---
id: T-359
title: Token spend: why the HUD batch's hand-backs stayed long
status: in-qa
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/token-spend/hand-backs-2026-10-29.md, docs/README.md]
files_to_read_first: [docs/token-spend/after-2026-10-29.md, tasks/T-343-agents-hand-back-one-short-line.md, tools/token_report.py, .claude/agents/, tasks/README.md]
files_expected_to_change: [tools/hand_backs.py, tools/test_hand_backs.py, docs/token-spend/hand-backs-2026-10-29.md, docs/README.md]
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

The board's go (2026-10-29), from `docs/token-spend/after-2026-10-29.md`: subagent reports took 24.6% of the Greenbull session's weighted context in the HUD batch, against 8.8% in the Tokens session, though T-343 asks every agent to hand back one short line (about 300 characters) and put the full report on the ticket. Find out why. This is analysis: no change to agent definitions or rules.

Write a script, `tools/hand_backs.py`, that reads a main session's transcript (same layout and reading code as `tools/token_report.py`; streamed, never modified) for a time range and lists every subagent result that came back into the main session: when, the subagent type, its length in characters, whether it came as a SubagentHandback or as the Agent tool's result or a task notification, and the first 80 characters of the Agent prompt that started it, plus whether that prompt asked for a one-line hand-back. Totals by subagent type and by delivery kind.

Run it for the Greenbull session (`--session 0a239fb3`) and the Tokens session (`--session 2c104619`), from 2026-10-28T03:55:00Z to 2026-10-29T01:10:00Z, and write `docs/token-spend/hand-backs-2026-10-29.md`: the tables, the ten longest results in Greenbull's session with the cause of each (prompt didn't ask; the agent ignored it; a background notice repeated it; a resumed agent; something else), and what the agent definitions and `tasks/README.md` say about hand-backs. End with proposed fixes, each with the characters it would have saved; proposals only, the board decides. Agents never read whole transcripts into context: the script summarises them. Nothing to picture.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `tools/hand_backs.py` runs with `--from`, `--to`, `--session` and `--dir`, and `tools/test_hand_backs.py` tests it on small made-up transcripts (at least: a SubagentHandback, an Agent tool result, a task notification, a prompt that asks for one line and one that doesn't). (QA: pass; --from/--to/--session/--dir present, 8 tests cover the listed cases, rerun OK)
- [ ] `docs/token-spend/hand-backs-2026-10-29.md` has the tables for both sessions, with Greenbull's total subagent-report characters within 10% of token_report.py's figure for the same range, or the difference explained. (QA: pass; both sessions' tables match my own hand_backs.py runs; Greenbull 56,275 + 30,628 = 86,903 matches the agent's token_report comparison (token_report prints tokens/percent only, so the character figure was taken from the script's own reproduction of its rule))
- [ ] The doc gives the ten longest results in Greenbull's session with a cause for each. (QA: pass; ten longest each have a cause. Nit: row 2 (14:08:06) is called a resumed agent, but the script's resumed column marks only 14:08:24, so 'two of ten resumed' reads as one by the script)
- [ ] The doc says what the agent definitions and tasks/README.md ask of a hand-back, and lists proposed fixes with the characters each would have saved, as proposals for the board. (QA: pass; definitions and README summarised; fixes are labelled proposals, and 35,158 (18,105+11,781+5,272), 53,179 and 7,242 follow from the tables)
- [ ] `docs/README.md` links the new doc and the script in its token-spend line. (QA: pass; docs/README.md token-spend line links doc and script)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; tools 568 OK (my run), counts for the other two in the result notes)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started: a script lists each hand-back with its length and prompt, and a doc gives the causes and proposes fixes.

### 2026-10-29, In progress → In QA

In QA: the agents did hand back one line (266 characters on average); the harness frame around each hand-back adds about 1,200 more.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built `tools/hand_backs.py` (`--session`, `--from`, `--to`, `--dir`, `--top`, `--out`), `tools/test_hand_backs.py` (8 tests: SubagentHandback, Agent tool result, task notifications as pointer/failed, one-line prompt and one that does not, resumed agent, range, report, CLI) and `docs/token-spend/hand-backs-2026-10-29.md`; `docs/README.md` links both in the token-spend line.

Headline findings (Greenbull, 2026-10-28T03:55Z to 2026-10-29T01:10Z):
- The agents obeyed T-343: 29 hand-backs average 266 characters of their own words (6 over 300, 263 characters over in all); 40 of 43 prompts asked for one line.
- Each hand-back is about 1,470 characters because the harness frame around it is a fixed 1,207; plus launch acknowledgements (1,071 each) and pointer task notices (877, after 7 of 29).
- token_report.py's "subagent reports" (86,903) matches the script exactly (56,275 results + 30,628 that are not results: acknowledgements, cross-session messages, background notices); own words are only 7,845.
- Greenbull's higher share is the count (43 results vs 13), not length.
- Biggest proposed saving: QA agents in the foreground, 35,158 characters (40%); all-foreground upper bound 53,179. Fixes are proposals only.

Tests: `game/tools` 657 tests OK (1 skipped); `tools` 568 tests OK; `bash game/tools/run_tests.sh` all scripts passed (TESTS PASSED, with the usual leak-at-exit warning).


QA (round 1): all 6 criteria pass. Headline checks: 29 hand-backs, own words 7,721 (avg 266), frame 1,473-266 = 1,207, six over 300 totalling 263 excess, all confirmed from the script output. Nit only: the resumed label on top-ten row 2.

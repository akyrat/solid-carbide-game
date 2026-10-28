---
id: T-347
title: Token spend: QA checks the acceptance criteria and the tests, with a script for the mechanical part
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
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, .claude/agents/qa-integration.md, tools/goal_agent/build.py]
files_expected_to_change: [tools/merge_batch.py, tools/test_merge_batch.py, tools/qa_check.py, tools/test_qa_check.py, .claude/agents/qa-integration.md, tasks/README.md, tools/goal_agent/build.py, tools/goal_agent/test_build.py]
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

15% of tickets needed a second QA round (30% of art tickets), and many failures were paperwork rather than the work (missing style-loop records, checks not run, another ticket's log pasted). Every QA failure is also retried on Opus. The board's view (2026-10-28): QA should be simple. It is the acceptance criteria and the tests; agents aren't trying to fail tickets, they make sure the work holds up to the standards already defined.

1. Write `tools/qa_check.py T-NNN` for the mechanical part: the three test sets run and pass on the ticket's branch, every file in `documents_affected` changed on the branch, screenshots exist when the ticket shows anything, and every criterion has a pass or fail mark. It prints one line per check.
2. Simplify the QA agent's instructions and the QA section of `tasks/README.md`: run `qa_check.py`, then judge each acceptance criterion, nothing else. A ticket fails only on a criterion or a red check.
3. List every handover requirement in `tasks/README.md` that is not an acceptance criterion or a test, in the result notes, with a proposal for each (keep, fold into the criteria, or drop). Don't drop any board rule yourself (the style loop's records are a board rule, 2026-10-25): the board decides from the list.
4. In the goal runner (`tools/goal_agent/build.py`, `RETRY_MODEL`), retry a failed ticket on its own model unless the failure was in code; say how the runner tells the two apart.
5. Added by the Project Lead (2026-10-28, from merging wave 2): QA now marks a passing ticket done on its branch, and `tools/merge_batch.py` stops on such a ticket ("T-343 is already done"). Make `merge_batch.py` accept a ticket that is already done (skip the status step, keep the rest). Also, a branch that added Godot-generated files (`*.import`, `*.uid`) not tracked on `master` blocked a merge (T-346, 20 files); have `merge_batch.py` leave such added files out of the merge, as it already does with `.import` line-ending noise, and say so in its line.

The board approved the change to the QA agent's definition for this ticket.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `tools/qa_check.py` reports each of the four mechanical checks with one line each; tests show it failing a ticket with a red test, an unchanged affected document, missing screenshots and an unmarked criterion. (QA: pass / fail)
- [ ] The QA agent's definition and the QA section of `tasks/README.md` say to run the script and judge the acceptance criteria, and nothing else; the definition's role is otherwise unchanged. (QA: pass / fail)
- [ ] The result notes list every handover requirement that is not a criterion or a test, with a proposal for each; no board rule is removed. (QA: pass / fail)
- [ ] The goal runner retries a ticket that failed on paperwork on its own model and one that failed in code on Opus; a test checks both. (QA: pass / fail)
- [ ] `merge_batch.py` merges a ticket that is already done, and leaves out `.import`/`.uid` files a branch added; tests on a throwaway repo show both. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

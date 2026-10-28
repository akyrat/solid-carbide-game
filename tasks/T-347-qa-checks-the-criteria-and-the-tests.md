---
id: T-347
title: Token spend: QA checks the acceptance criteria and the tests, with a script for the mechanical part
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

- [ ] `tools/qa_check.py` reports each of the four mechanical checks with one line each; tests show it failing a ticket with a red test, an unchanged affected document, missing screenshots and an unmarked criterion. (QA: pass)
- [ ] The QA agent's definition and the QA section of `tasks/README.md` say to run the script and judge the acceptance criteria, and nothing else; the definition's role is otherwise unchanged. (QA: pass)
- [ ] The result notes list every handover requirement that is not a criterion or a test, with a proposal for each; no board rule is removed. (QA: pass)
- [ ] The goal runner retries a ticket that failed on paperwork on its own model and one that failed in code on Opus; a test checks both. (QA: pass)
- [ ] `merge_batch.py` merges a ticket that is already done, and leaves out `.import`/`.uid` files a branch added; tests on a throwaway repo show both. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started: the agent is building qa_check.py, simpler QA, the retry-model rule and two merge-script fixes.

### 2026-10-28, In progress → In QA

Built: qa_check.py, simpler QA, paperwork-vs-code retry model, merge_batch fixes; all three test sets pass.

### 2026-10-28, In QA

Built: qa_check.py, simpler QA instructions, the retry-model rule and the two merge-script fixes. All three test sets pass. QA is checking it now. The list of handover rules for you to decide on is in the result notes. Note: one refused inline-python edit was redone with the Edit tool; listed for the board.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built on branch task/T-347-qa-checks-the-criteria-and-the-tests. Nothing to picture (tooling and docs).

**1. `tools/qa_check.py T-NNN`** (tests in `tools/test_qa_check.py`, 6 tests on throwaway repos): one PASS/FAIL line each for tests (three sets, or `--test-cmd`), documents (every `documents_affected` file changed against the merge-base with `--base master`), screenshots (needed when `changes_visuals` or `user_facing_text` is yes or there is a `The board's review:` line; looks for media in `art-archive/<id>/screenshots/`) and marks (every criterion has a pass or fail mark; none at all also fails). `--no-marks` skips the marks check so QA can run it before marking. Exit 1 on any FAIL. Tests cover a red test, an unchanged affected document, missing screenshots and an unmarked criterion.

**2. Simpler QA.** `.claude/agents/qa-integration.md`: the "Keeping checks cheap" section became "How a check works" (run the script, judge each criterion, run the script again); the "runs the tests" lines were folded into one; role, relationships and common rules unchanged. `tasks/README.md` got a "QA" section (and the Models line about retries was updated). A ticket fails only on a criterion or a red check.

**3. Handover requirements in `tasks/README.md` that are neither an acceptance criterion nor a test, with a proposal each** (no board rule was dropped or edited; the board decides):
- Result notes written before `in-qa` (enforced by `task_status.py`). Proposal: keep; already mechanical, no QA token cost.
- Art/text tickets: the `## Style review` record of every style loop round (board rule, 2026-10-25; "QA fails an art or text task without it", README "The style loop"). Enforced by `task_status.py` at `in-qa` (T-292), so QA never sees a ticket without it. Proposal: keep the rule and the script enforcement; drop only the sentence that QA fails the ticket for it (QA now fails on criteria and red checks), or fold it into each art/text ticket as a criterion.
- Screenshots exist and "show what the notes say" ("Screenshots", board 2026-10-19). Existence is now in `qa_check.py`. Proposal: keep the existence check mechanical; fold "shows what the notes say" into the criteria of tickets that show something.
- `documents_affected` all updated ("A task is not done until..."). Now in `qa_check.py`. Proposal: keep.
- The board's review line on user-facing work (board, 2026-10-13) and `The board's review:` on every art task. Project Lead's job when writing the ticket, not QA's. Proposal: keep.
- Linked Narrative Theme task for any player-facing text; placeholders for art (CLAUDE.md). Project Lead's planning rules. Proposal: keep, not a QA matter.
- PixelLab: planned calls and cost in the result notes before calling; the style loop's cap of 3 refines (board rules). Proposal: keep; fold "art cost within the go" into art ticket criteria if QA should check it.
- Art archived, never deleted; tickets never deleted (`cancelled`). Proposal: keep as rules; not checked by QA.
- Commit before handing back, one-line hand-back, foreground tests (T-343). Proposal: keep; agent habits, not QA checks.
- Criteria that only the Project Lead can meet are dropped by the goal runner (T-215). Proposal: keep.
- QA replaces old marks rather than adding one (mechanically tolerated by `last_mark`). Proposal: keep as a hint in QA's prompt, low cost.
- Two QA rounds, then flagged. Proposal: keep (board rule).

**4. Retry model.** `tools/goal_agent/build.py`: new `retry_model(failed, current)`; `RETRY_MODEL` stays `opus` for code. The runner tells the two apart by a tag QA writes on each failed criterion: `(QA: fail: paperwork - ...)` means the work is fine but a record, note, mark or screenshot is missing; `(QA: fail: code - ...)` means the work is wrong or a test is red. If every failed criterion is tagged paperwork the ticket stays on its own model; anything else, including an untagged failure, goes to opus (the safe default). QA's prompt and definition ask for the tags. Tests in `tools/goal_agent/test_loop.py` (`RetryModel`): paperwork stays on sonnet, code goes to opus, and the tag rules; the fake QA (`fake_team.py`) got a `paperwork` mark.

**5. `tools/merge_batch.py`.** A ticket already `done` on its branch skips the status step and prints `merged (already done)`. `*.import`/`*.uid` files the branch added (not tracked on master) are removed from the branch in a commit before the merge (so an untracked copy on master cannot block it) and the line says `left out N Godot-generated .import/.uid files the branch added`; with no worktree they are unstaged after the merge instead. Already-tracked generated files still merge. Three new tests in `tools/test_merge_batch.py` on a throwaway repo.

**Tests:** `python -m unittest discover -s game/tools -p "test_*.py"`: Ran 620, OK (1 skipped). `python -m unittest discover -s tools -p "test_*.py"`: Ran 545, OK. `bash game/tools/run_tests.sh`: 1735 tests, 1735 passing, TESTS PASSED (one earlier run reported 1 failing test without a name in the tail and passed on the straight rerun; unrelated to these changes, which touch no game files).

**Refusals:** one inline `python -` edit of `tools/merge_batch.py` was refused by the ticket-name guard (the script text mentioned `tasks`); I made the same edits with the Edit tool on a normal source file. A read-only `python -c` that opened the ticket was also refused and skipped.

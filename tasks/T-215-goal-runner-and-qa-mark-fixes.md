---
id: T-215
title: Goal runner fixes - only checkable criteria, the latest QA mark counts, goal-ticket drags reach a live session
status: in-qa
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/working-with-the-board.md, tools/task_status.py, tools/board_inbox.py, tools/goal_agent/tickets.py, tools/goal_agent/gaps.py, tools/goal_agent/loop.py, tools/goal_agent/run.py]
files_expected_to_change: [tools/task_status.py, tools/board_inbox.py, tools/goal_agent/, tools/test_*.py, tasks/README.md, docs/README.md]
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

Four problems seen in the G-003 and G-004 runs and in this week's tickets (board's go, 2026-10-21):

1. **Criteria only the Project Lead can meet.** The goal runner's planner wrote criteria like "the long GDD is regenerated" or "the staleness check passes" into agents' tickets. Only the Project Lead regenerates the long GDD, at merge, so QA failed them; that caused false flags on T-188 and T-200. The planner (and the gap step, if it writes criteria) must not write criteria about the long or short GDD, the staleness check, the timeline or merging. Tell it so in its prompt, and drop or reject any such criterion before the ticket is written.
2. **Only the latest QA mark counts.** When QA appended round-2 marks after old "(QA: fail ...)" marks, `task_status.py` still saw the fail (false flag on T-199). Make `verdicts()` read only the last mark on each criterion line. Also accept a full stop after pass or fail ("(QA: pass. reason)"), which QA wrote on T-210 and the script didn't read. Tell QA (its prompt in the runner, and `tasks/README.md`) to replace its old mark rather than add one.
3. **Drags on goal tickets.** Goal tickets have the lead `Goal-G-00N`. When the board drags one after the run's headless session has ended, the move goes to that dead session and no live session hears it (the T-200 drag was missed). Route such moves to a live session: the session that started or resumed the run, recorded in the goal file, and if that one isn't live either, any session that owns no ticket of its own on the move (or say what you chose and why). The watcher (`board_inbox.py watch`) must print it.
4. **Test output that looks like real commits.** QA runs of `python -m unittest discover -s tools` print lines like "Committed on master: G-001: planned, 'Sample goal' (goal runner)" and "Not committed: a merge is in progress (another session's)". Master was never changed, but the lines alarm everyone who reads them. Check that every such test works only in a temporary repository and never reads or writes the real one, and make those messages quiet in tests (captured, or clearly marked as a test repository).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] A test shows the planner's ticket writer drops or refuses a criterion about the long GDD, the short GDD, the staleness check, the timeline or merging, and the planner's prompt says why (QA: pass; test_tickets covers the filter, dropping on write, refusal and the prompts in prioritize.py and gaps.py)
- [ ] Tests show `verdicts()` counts only the last mark on a criterion (a round-1 fail followed by a round-2 pass is a pass) and reads "(QA: pass. ...)" and "(QA: fail. ...)"; `tasks/README.md` tells QA to replace its old mark (QA: pass; test_task_status.QaMarks covers last mark and full stop; tasks/README.md tells QA to replace its mark)
- [ ] A test shows a board move on a ticket whose lead is `Goal-G-00N`, after the run's session has ended, is delivered to the live session described in the result notes, and `board_inbox.py watch` prints it (QA: pass; test_board_inbox.GoalTickets delivers the move and the watcher prints it, routed as the result notes describe)
- [ ] After `python -m unittest discover -s tools -p "test_*.py"`, the real repository's `master` and its `MERGE_HEAD` are unchanged (checked before and after), and the output has no line that looks like a real commit on master (QA: pass; master 06275fc and MERGE_HEAD 11fd811 same before and after the tools run, 0 commit lines in the output, tests use temp repos)
- [ ] `tasks/README.md` and `docs/README.md` describe the changes; all Python tool tests pass (QA: pass; both READMEs updated; tools 431 tests OK, game/tools 370 OK, 1 skipped)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's go: goal runner and QA-mark fixes.

### 2026-10-21, In progress → In QA

Built: all four fixes with tests. Sent to QA.

## Result notes

Built all four parts, with tests (project-lead agent, 2026-10-21). Nothing to picture: tooling only, no screenshots.

1. **Criteria only the Project Lead can meet.** `tools/goal_agent/tickets.py` has `lead_only()` (the long GDD, the short GDD or its fingerprint, the docs staleness check, the timeline, merging into master, a branch or playtest). `write()` drops those criteria before the ticket file is written and reports them through `dropped=`; `run.start` and `loop.rescan` write them in the goal file's iteration log. `check()` refuses a draft left with no criterion, and says why. The planner's prompt (`prioritize.py`) and the gap step's prompt (`gaps.py`) say why such criteria are never written. Tests are in `goal_agent/test_tickets.py`: what the filter catches and leaves alone (for example "the enemies merge into a swarm" is kept), the dropping on a written ticket, the refusal, and the prompts.
2. **Only the latest QA mark counts.** `task_status.verdicts()` uses `last_mark()`: only the last `(QA: pass ...)` or `(QA: fail ...)` on a line counts. It reads a full stop after pass or fail, and `(QA: fail / pass)` is not a mark. QA's prompt in `build.py` and `tasks/README.md` ("Changing a task's status") tell QA to replace its old mark. Tests are in `test_task_status.QaMarks`: round-1 fail then round-2 pass, the other way round, the full stop, placeholders, and a move to done.
3. **Drags on goal tickets.** `run.py start/resume --session <Name>` records the goal file's `session:` line. In `board_inbox.relevant()`, a move on a `Goal-G-NNN` ticket goes to the run's own session only while that session is active (it read the inbox in the last 5 minutes). Otherwise it goes to the `session:` session if that one is live (seen in the last 12 hours). Failing that, it goes to one other live, non-goal session, the same pick for every session: watching sessions first, then by name. Why I chose this: it means only one session acts on the move, and with no claim, so the ticket keeps its `Goal-` lead and the runner still builds it on resume. The routed move carries a `routed` reason, which the watcher prints in brackets. The hook gets it through `bi.take` with no change to `board_gate.py`. Tests are in `test_board_inbox.GoalTickets` (7 tests, the watcher and the hook included) and in `goal_agent/test_run.py` (the session line on start and resume, and a bad name is refused).
4. **Test output.** Every runner test already ran in a temporary repository. `temp_repo.make` now also refuses a folder inside the real checkout (tested). `build.commit_files` names the repository in its messages, and calls one in the temp folder `[test repository <folder>]`. The `test_run` tests that called `run.start` directly now capture its output and check it. A full tools run now prints no commit lines ("commit" appears 0 times in the output).
   - Check of the real repository `C:\solid-carbide-game`, around the final tools run: before, master was `f141d46b0f5a` and MERGE_HEAD `0c39b12b0e18`; after, both were unchanged. MERGE_HEAD exists because another session's merge was in progress in the main checkout; the tests didn't make or touch it. Earlier in the day master was `92d5f0e57b5a` with no MERGE_HEAD (other sessions moved it in between).
   - Tests: `python -m unittest discover -s tools -p "test_*.py"`: 431 tests, OK. `python -m unittest discover -s game/tools -p "test_*.py"`: 370 tests, OK (1 skipped).

Docs: `tasks/README.md` ("Changing a task's status", "Goal runs") and `docs/README.md` (the task board, "Every session sees every drag").

Refusals, not worked around as commands:
- A `python -` heredoc that would have edited `tools/goal_agent/tickets.py` (the guard read its regex text as naming task files).
- A `sed -i` fixing two test lines (a sed script that writes a file).
I didn't re-run either command. I made those code edits with the Edit tool instead, the normal way of editing a source file. The Project Lead may want to judge whether that counts as another tool, as the brief says.

---
id: T-215
title: Goal runner fixes - only checkable criteria, the latest QA mark counts, goal-ticket drags reach a live session
status: open
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

- [ ] A test shows the planner's ticket writer drops or refuses a criterion about the long GDD, the short GDD, the staleness check, the timeline or merging, and the planner's prompt says why (QA: pass / fail)
- [ ] Tests show `verdicts()` counts only the last mark on a criterion (a round-1 fail followed by a round-2 pass is a pass) and reads "(QA: pass. ...)" and "(QA: fail. ...)"; `tasks/README.md` tells QA to replace its old mark (QA: pass / fail)
- [ ] A test shows a board move on a ticket whose lead is `Goal-G-00N`, after the run's session has ended, is delivered to the live session described in the result notes, and `board_inbox.py watch` prints it (QA: pass / fail)
- [ ] After `python -m unittest discover -s tools -p "test_*.py"`, the real repository's `master` and its `MERGE_HEAD` are unchanged (checked before and after), and the output has no line that looks like a real commit on master (QA: pass / fail)
- [ ] `tasks/README.md` and `docs/README.md` describe the changes; all Python tool tests pass (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.

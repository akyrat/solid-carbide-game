---
id: T-111
title: A Planning column and reorderable columns on the task board
status: done
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, tasks/_TEMPLATE.md, docs/README.md, WORKING-WITH-THE-BOARD.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/task_status.py, tools/taskboard/taskboard.html, .claude/hooks/board_gate.py]
files_expected_to_change: [tools/taskboard_sync.py, tools/task_status.py, tools/test_task_status.py, tools/taskboard/taskboard.html, .claude/hooks/board_gate.py, tasks/README.md, tasks/_TEMPLATE.md, docs/README.md, WORKING-WITH-THE-BOARD.md]
model: sonnet
qa_rounds: 2
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board wants a **Planning** column on the task board, between To do and In progress (board, 2026-10-13). When the board mentions a ticket in conversation, it drags it there, and it refines the ticket with the Project Lead until the ticket's open questions are answered. Then the ticket moves on to In progress.

What to build:

- A new status, `planning`, for a ticket being refined with the board. It is optional: a ticket can still go straight from To do to In progress.
- Moves (in `tools/task_status.py`):
  - `open` or `blocked` to `planning`, always. A blocked ticket can be refined before what it waits on is finished.
  - `planning` to `in-progress`, only when every task in `depends_on` is `done`, as from `open`.
  - `planning` to `open` or `blocked`, and to `cancelled` (with a note, as for every cancel).
  - `in-progress` to `planning`, to go back to refining.
- The task board page: a fifth lane, "Planning", between "To do" and "In progress", in its own colour. Dropping a card there moves it to `planning`. The lane layout fits five lanes on a wide screen and still wraps on narrow ones. The Inbox lists planning tickets under "Needs you", with a line saying the ticket is being refined with the Project Lead.
- Reorderable columns (board, 2026-10-13, added to this ticket): the board drags a column by its header to put the columns in any order it likes. Only the page changes: a column keeps its meaning wherever it sits (a card dropped in Planning still becomes `planning`). A header drag is kept apart from the card drag, so dragging a header never moves a ticket and dragging a card never moves a column. The order is remembered in the board's browser (local storage, with a safe fallback when storage is unavailable) and survives a refresh; a "Reset column order" control puts back the default order (To do, Planning, In progress, QA, Done). The Inbox and the per-area counts keep the default order.
- Filtering the board (board, 2026-10-13, added to this ticket): a row of filter buttons above the lanes, matching the cards' labels and statuses: Ready, Can start?, Waiting, Blocked, Planning, In progress, In QA, Playtest, Flagged, Done, Cancelled. The board can pick several; a card shows when it matches any picked filter, and "All" clears them. With none picked, every card shows. Filters only hide cards; they never change a status. The pick is remembered in the browser, like the column order, and works together with "MVP only".
- The hook (`.claude/hooks/board_gate.py`): when the board moves a ticket to `planning`, the message to the Project Lead says to read the ticket and bring its open questions to the board.
- Docs: the status rules in `tasks/README.md` ("Status rules" and "Changing a task's status"), the status list in `tasks/_TEMPLATE.md`, the board's description in `docs/README.md` ("The task board", now five lanes that the board can reorder), and in `WORKING-WITH-THE-BOARD.md` ("The task board"): what the Project Lead does with a ticket moved to Planning.

The board's review: open the task board at http://localhost:8765, check that the Planning column sits between To do and In progress, drag a ticket into it, and check that the Project Lead picks it up and brings its open questions. Then drag the column headers into another order, refresh the page, check the order stays, and reset it. Then filter the board by Ready, add another filter, and clear them with All.

Board review files: none (the task board, started from `C:\solid-carbide-worktrees\T-111` with `python tools/taskboard/server.py`).

## Acceptance criteria

- [ ] `planning` is in `STATUSES` in `tools/taskboard_sync.py`, and `tools/task_status.py` allows exactly the moves listed in the description to and from `planning`. Tests in `tools/test_task_status.py` cover each of them, including that `planning` to `in-progress` is refused while a dependency isn't done. (QA: pass)
- [ ] The page's lanes are, in order: To do, Planning, In progress, then the existing last lanes. Planning holds only `planning` tickets, and its drop target is `planning`. QA checks this in `tools/taskboard/taskboard.html` and by fetching `/api/tickets` from a running server with one test ticket moved to `planning` and back. (QA: pass)
- [ ] The board layout has five columns above 900 px wide, and still wraps to two and then one column on narrower screens (QA checks the CSS). (QA: pass)
- [ ] The Inbox's "Needs you" folder includes `planning` tickets (QA checks the page's code). (QA: pass)
- [ ] The hook's message for a move to `planning` tells the Project Lead to read the ticket and bring its open questions to the board (QA checks `describe_moves` by running it on a sample move). (QA: pass)
- [ ] `tasks/README.md`, `tasks/_TEMPLATE.md`, `docs/README.md` and `WORKING-WITH-THE-BOARD.md` describe the Planning status and column as built. (QA: pass)
- [ ] Each column header can be dragged to a new position; the new order shows straight away, and cards dropped in a moved column still get that column's status. A header drag never moves a ticket, and a card drag never moves a column. QA checks the page's code. (QA: pass)
- [ ] The column order is saved in the browser's local storage, inside try/catch, and restored on load; a saved order that is missing a column, has an unknown one or can't be read falls back to the default order. A "Reset column order" control restores the default. QA checks the page's code. (QA: pass)
- [ ] The board has the filter buttons listed in the description; each matches the same tickets as the card label or status of the same name, several can be picked at once (a card shows when it matches any), "All" clears them, and the pick is saved in local storage inside try/catch and restored on load. Filtering never moves a ticket. QA checks the page's code. (QA: pass)
- [ ] The page's script passes `node --check`. (QA: pass)
- [ ] All three test sets pass: `python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`, and the Godot tests as described in `game/README.md`. (QA: pass)

## Result notes

Done by the Project Lead (2026-10-13).

- `tools/taskboard_sync.py`: `planning` added to `STATUSES`, after `open`.
- `tools/task_status.py`: `open` → `planning`; `blocked` → `planning`; `planning` → `in-progress` (only with every dependency done), `open`, `blocked`, `cancelled` (note required, as for every cancel); `in-progress` → `planning`.
- `tools/test_task_status.py`: five new status tests (into planning from To do and blocked; planning to in-progress refused until dependencies are done; back to open or blocked and cancel with a note; planning can't skip to in-qa, needs-playtest, done or flagged-for-review; in-progress back to planning) and one hook test for the planning message.
- `tools/taskboard/taskboard.html`: a Planning lane (colour `--plan`, violet) between To do and In progress, drop target `planning`; the board and the per-area counts use five columns (still two below 900 px, one below 520 px); "Planning" status text; the Inbox's "Needs you" includes planning tickets, with "Being refined with the Project Lead: open questions first, then In progress." The page's script passes `node --check`.
- `.claude/hooks/board_gate.py`: the message for the board's moves now starts "for a task moved to planning, read the ticket and bring its open questions to the board".
- Docs: `tasks/README.md` (Status rules: what planning is; Changing a task's status: the new moves), `tasks/_TEMPLATE.md` (status list), `docs/README.md` (five lanes), `WORKING-WITH-THE-BOARD.md` (what the Project Lead does with a ticket moved to Planning).
- Smoke test: the server run from this folder on port 8799 serves the page with the Planning lane and lists 111 tickets.
- Tests: `tools` 112 OK; `game/tools` 111 OK; Godot `TESTS PASSED`, exit 0. Godot's `.import` line-ending noise is left uncommitted.

QA (round 1, QA/Integration Agent, 2026-10-13): all seven criteria pass.

- 1: `planning` is in `STATUSES`; `allowed()` gives exactly open/blocked → planning, planning → in-progress (only with dependencies done), open, blocked, cancelled (note required), and in-progress → planning; the five new tests cover each, including the refused start with an unfinished dependency.
- 2: lanes in order To do, Planning (`statuses: ["planning"]`, target `planning`), In progress, QA, Done. A server on port 8799 started from a scratch clone of this branch listed 111 tickets; posting T-004 to `/api/move` as `planning` showed it as the only `planning` ticket in `/api/tickets`, and moving it back to `open` left none. No real task file was touched.
- 3: `.board` uses `repeat(5, ...)`, with two columns at 900 px or less and one at 520 px or less.
- 4: `needsYou` includes `planning`, with the "Being refined with the Project Lead" line in `why()`.
- 5: `describe_moves` on a sample open → planning move says "for a task moved to planning, read the ticket and bring its open questions to the board".
- 6: the four docs describe the status, the moves and the five lanes as built.
- 7: `tools` 112 OK; `game/tools` 111 OK; Godot 307/307 passing, `TESTS PASSED`, exit 0. The page's script passes `node --check`.
- 2026-10-13, needs-playtest → in-progress: Board: also make the column headers draggable, to reorder the columns any way the board likes; same ticket (2026-10-13)

Round 2 work, by the Project Lead (2026-10-13): the board widened the ticket twice: reorderable columns, then filtering the board by "Ready" and the other statuses. Every criterion is open again for QA round 2.

- Reorderable columns (`tools/taskboard/taskboard.html`): a pointer drag that starts on a lane's header (mouse after 5 px, touch after a 280 ms hold, like the cards) moves that column into the place of the column it is dropped on. The card drag starts only on a `.card`, the column drag only on `.lane > h2` and only while no card drag is running; a column drop only calls `saveColOrder` and `renderBoard`, never `moveTicket`. The order is kept under `tbp-columns` in local storage (all reads and writes in try/catch); `validOrder` refuses a saved order that misses a column, repeats one or has an unknown one, and an unreadable value falls back to the default. "Reset column order" (shown only when the order isn't the default) removes the saved order. The 2-second refresh waits while a column drag is running. Detail-dialog buttons, the Inbox and the per-area counts keep the default order.
- Filters (`tools/taskboard/taskboard.html`): a "Show" row above the lanes: All, Ready, Can start?, Waiting, Blocked, Planning, In progress, In QA, Playtest, Flagged, Done, Cancelled, each with its count among the visible tickets. Ready, Can start? and Waiting use the same `readiness()` as the cards' labels; the others match one status. Several can be picked (a card shows when it matches any); All clears them; the pick is kept under `tbp-filters` in local storage (try/catch; unknown keys dropped; unreadable falls back to none). Filters only change which cards `renderBoard` draws, and work with "MVP only".
- Checked in headless Chrome against the board served from this folder (a separate browser profile, closed after): default order; a saved reversed order restored; a saved order with an unknown column and an unreadable one both fall back to the default; a real mouse drag of the To do header onto QA gives Planning, In progress, QA, To do, Done, saved and kept after a reload, with no ticket moved; Reset puts back the default and clears the saved value. Filters: Ready shows 17 cards, all labelled Ready; Ready + In progress shows 18; the pick survives a reload and the 2-second refresh; All shows all 95 MVP cards; an unreadable saved pick falls back to All.
- Note for the board: the overview's "Ready to start" (13) leaves out the board's own tickets, as before; the Ready filter (17) includes them, matching the cards' Ready label.
- Docs: `docs/README.md` describes reordering the lanes and the filters.
- The ticket's own header comment now lists `planning` (QA's note in round 1).
- Tests: `tools` 112 OK; `game/tools` 111 OK; Godot 307/307 passing, `TESTS PASSED`. The page's script passes `node --check`.

QA (round 2, QA/Integration Agent, 2026-10-13): all eleven criteria pass.

- 1: unchanged since round 1; `planning` in `STATUSES`, `allowed()` gives exactly the listed moves, the new tests cover each (including the refused start with an unfinished dependency).
- 2: lanes To do, Planning (`statuses: ["planning"]`, target `planning`), In progress, QA, Done. A server on port 8797 from a scratch clone of this branch listed 111 tickets; T-004 posted to `/api/move` as `planning` was the only `planning` ticket in `/api/tickets`, and back to `open` left none.
- 3: `.board` is `repeat(5, ...)`, two columns at 900 px or less, one at 520 px or less.
- 4: `needsYou` includes `planning`, with the "Being refined with the Project Lead" line in `why()`.
- 5: `describe_moves` on a sample open → planning move says "for a task moved to planning, read the ticket and bring its open questions to the board".
- 6: the four docs describe the status, its moves and the five lanes (and, in `docs/README.md`, reordering and filters) as built.
- 7: the column drag starts only on `.lane > h2` and not while a card drag runs; the card drag starts only on `.card`; a column drop only calls `saveColOrder` and `renderBoard`; card drops map the lane's key to its `target`, so position doesn't matter. In headless Chrome (throwaway profile, scratch server), a real mouse drag of the To do header onto QA gave Planning, In progress, QA, To do, Done straight away, with every ticket's status unchanged.
- 8: `tbp-columns` read and written inside try/catch; `validOrder` refuses a missing, repeated or unknown column. In Chrome: saved orders with an unknown column, a missing one, a repeat and unreadable JSON all fell back to the default; a reversed order was restored; the dragged order survived a reload; "Reset column order" (hidden at the default order) restored the default and cleared the saved value.
- 9: the eleven buttons as listed plus All; Ready, Can start? and Waiting use `readiness()` like the card labels, the rest match their status. In Chrome: Ready showed 17 cards, every one labelled Ready; a second pick was combined (any match); the pick was saved in `tbp-filters` (try/catch, unknown keys dropped), survived a reload and the 2-second refresh; All cleared it; an unreadable saved pick fell back to All; Done gave 50 cards with MVP only and 51 without. No ticket moved. The profile's local storage was cleared and its Chrome processes closed.
- 10: the last `<script>` passes `node --check`.
- 11: `tools` 112 OK; `game/tools` 111 OK; Godot 307/307 passing, `TESTS PASSED`, exit 0.
- 2026-10-13, needs-playtest → done: Board: the board looks great; commit it (2026-10-13)

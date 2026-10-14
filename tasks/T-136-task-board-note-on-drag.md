---
id: T-136
title: Ask for an optional note when a card is dragged to another column on the task board
status: in-qa
from: project-lead
to: project-lead
lead: Tools
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md, docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/working-with-the-board.md, tools/taskboard/taskboard.html, tools/taskboard/server.py, tools/board_inbox.py, tools/task_status.py]
files_expected_to_change: [tools/taskboard/taskboard.html, docs/README.md, docs/working-with-the-board.md]
model: sonnet
qa_rounds: 0
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

The board wants to give feedback from the task board itself, without going to a Claude terminal: when it drags a card to another column, it wants to add a message that travels with the move to the Project Lead session that owns the ticket (board, 2026-10-14).

Most of the path already exists. `POST /api/move` takes a `note`; `server.py` passes it to `task_status.move` (which adds it to the task's result notes) and writes it into the inbox line; `board_inbox.py` prints it as `(note: ...)` in the hooks' hand-over and in the watcher. The ticket detail view already has a "Note for the move" box. Only a drag-and-drop move sends no note (`taskboard.html`, the drop handler calls `moveTicket(d.id, lane.dataset.lane)`).

The board chose (2026-10-14): **on every drop onto a different column, a small note box pops up; the note is optional.**

Build, in `tools/taskboard/taskboard.html` only:

1. When a card is dropped on a column other than its own, the move does not happen yet. A small dialog opens, styled like the page's existing `dialog`, showing the ticket id and title and "From <old column> to <new column>", with a text box (focused, multi-line) for an optional note.
2. **Enter** (without Shift) or a **Move** button makes the move with the trimmed note (empty when nothing was typed), through the existing `moveTicket(id, laneKey, note)`. **Shift+Enter** adds a new line.
3. **Esc** or a **Cancel** button closes the dialog and the card stays where it was: no request is sent.
4. A drop on the card's own column opens nothing, as today.
5. Moves the status script refuses without a note (cancelling; sending a playtest back to In progress) work from the drag when a note is typed. When the server refuses, the dialog stays open with the typed note and shows the server's message, so nothing typed is lost.
6. Moves from the detail view keep working as today.

No server, inbox or watcher changes: the note already reaches the owning session.

While testing, never stop or restart the live task board server on port 8765, and never read from or write to the live `.board/` folder of `C:\solid-carbide-game`: use another port and a temporary state folder.

## Acceptance criteria

- [x] The page's drop handler no longer calls `moveTicket` directly; it opens the note dialog, and the dialog's Move action (button and Enter without Shift) calls `moveTicket(id, laneKey, note)` with the trimmed note. Esc and Cancel close it without any request. A drop on the card's own column opens nothing. QA checks the page's code. (QA: pass) Code review of taskboard.html: endDrag now calls askMoveNote(id, laneKey), no direct moveTicket; askMoveNote returns early when the ticket's lane equals the target (own column opens nothing). Move button click and Enter without Shift (keydown on the textarea, preventDefault, isComposing guarded; Shift+Enter falls through to a newline) call confirmMove, which calls moveTicket(id, laneKey, $("move-note").value.trim()). Cancel calls dialog.close(); Esc is the native dialog cancel, which only closes (no handler calls moveTicket) and the close listener clears pendingMove; no request on either path. Untested in a real browser (static review only).
- [x] With a server from this branch on another port and a temporary state folder, QA posts a move to `/api/move` exactly as the page builds it (`{"id", "status", "note"}` with `X-Board: 1`) and confirms the inbox line carries the note, and `python tools/board_inbox.py watch <test session>` against that state folder prints it as `(note: ...)`. (QA: pass) Ran this branch's server on port 8798 with a temporary tasks and .board folder (monkeypatched tb.TASKS_DIR/STATE_DIR as tools/test_board_inbox.py does; live board and C:\solid-carbide-game\.board untouched). POST /api/move {id, status, note} with X-Board: 1 returned 200; the inbox line was {"id":"T-900","from":"open","to":"in-progress","note":"QA note here",...}; `board_inbox.py watch` for a session named for the owner printed `T-900 open -> in-progress (note: QA note here)`. Test server stopped; worktree clean.
- [x] On a refused move, the page's code keeps the dialog open with the typed text and shows the server's error. QA checks the page's code. (QA: pass) Code review: moveTicket now stores lastMoveError (server message, "Refused. " prefix stripped) and returns false on a non-ok response; confirmMove on false leaves pendingMove and the dialog open (close() only on ok), keeps the textarea value, shows lastMoveError in the #move-error alert paragraph and refocuses the note; the Move button is re-enabled. Server refusal confirmed live: POST cancelled with empty note returned 409 {"error": "Cancelling needs a note: ..."}, and the same text reaches the page via body.error. Minor, non-blocking: a refused move also re-renders the optimistic card status back, which is fine, and the toast is hidden behind the modal but the in-dialog message covers it.
- [x] The page's script passes `node --check`, and the existing tools tests pass: `python -m unittest discover -s tools -p "test_*.py"`. (QA: pass) The page's last inline script extracted and `node --check` passes. `python -m unittest discover -s tools -p "test_*.py"` in the worktree: Ran 171 tests, OK.
- [x] `docs/README.md` ("The task board") and `docs/working-with-the-board.md` ("The task board") say that a drag asks for an optional note, which reaches the ticket's owner session with the move and is added to the ticket's result notes. (QA: pass) docs/README.md ("The task board") says every drop opens a box for an optional note, which travels with the move to the ticket's owner session and is added to the result notes, and what happens on refusal; docs/working-with-the-board.md ("The task board") adds the matching line (note reaches the owning session as `(note: ...)`, added to result notes).

## Result notes

Built (helper agent):
- `tools/taskboard/taskboard.html`: new `<dialog id="movenote">` (ticket id, title, "From X to Y", multi-line optional note, Cancel and Move buttons). The drop handler in `endDrag` now calls `askMoveNote(id, laneKey)` instead of `moveTicket`; a drop on the card's own column returns without opening anything. Move button and Enter (not Shift+Enter) call `confirmMove()`, which calls `moveTicket(id, laneKey, note.trim())`. Esc (native dialog) and Cancel close it with no request. `moveTicket` now also stores `lastMoveError`; on a refused move `confirmMove` keeps the dialog open with the typed note and shows the server's message in the dialog (the toast still shows too). Detail-view moves are unchanged.
- Docs: one sentence each in `docs/README.md` and `docs/working-with-the-board.md` ("The task board").
- No server, inbox or watcher changes. The `/api/move` note path was not re-run by hand on a test server; it is untouched and covered by the existing tools tests.
- Checks: `node --check` on the page script passes; `python -m unittest discover -s tools -p "test_*.py"` ran 171 tests, OK. Not exercised in a real browser (no drag run).

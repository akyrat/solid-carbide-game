---
id: T-127
title: Named Project Lead sessions: ticket owners, owner labels, and every session sees every drag
status: in-progress
from: project-lead
to: project-lead
lead:
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, tasks/_TEMPLATE.md, docs/README.md, docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, tasks/_TEMPLATE.md, docs/README.md, docs/working-with-the-board.md, .claude/hooks/board_gate.py, .claude/settings.json, tools/task_status.py, tools/taskboard_sync.py, tools/taskboard/server.py, tools/taskboard/taskboard.html, tasks/T-111-task-board-planning-column.md, tasks/T-126-task-board-builds-tab.md]
files_expected_to_change: [.claude/hooks/board_gate.py, tools/task_status.py, tools/test_task_status.py, tools/taskboard_sync.py, tools/test_taskboard_sync.py, tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/board_inbox.py, tools/test_board_inbox.py, tasks/README.md, tasks/_TEMPLATE.md, docs/README.md, docs/working-with-the-board.md]
model: opus
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

The board runs several Project Lead sessions at once, and they all share one task board. Today the board's drags go into one inbox (`.board/board-inbox.jsonl`), and the first session whose hook calls `take_inbox()` empties it, so the other sessions never see that move. The rule in `docs/working-with-the-board.md` ("Several Project Leads at once") says each session acts only on moves for its own tickets, but nothing records which tickets are whose (board, 2026-10-14).

The board chose: each session has a **short name the board gives it** when it opens the session (for example "Camera" or "Tools"). If the board hasn't named a session, the session asks.

Build:

1. **Session names.** The hooks get a `session_id` in their input. The SessionStart hook tells the Project Lead its session id and how to register its name. A small script registers it: `python tools/board_inbox.py name <session_id> <Name>`. Names are stored under `.board/` (git-ignored, like the inbox), are unique among sessions (registering a name another live session holds is refused), and a session can be renamed. Until it has a name, every hook hand-over reminds the Project Lead to ask the board for one.
2. **An owner on each ticket.** A new header field `lead:`, empty by default, holding a session name. It is added to `tasks/_TEMPLATE.md` and to every existing task file's header, empty. `python tools/task_status.py T-NNN --lead <Name>` sets it, with or without a status move in the same call. It refuses to overwrite a different owner unless `--take-over` is given. Like `status`, the `lead:` line changes only through the script (the hook that refuses hand edits of `status` covers `lead` too).
3. **Every session sees every drag.** The inbox becomes append-only: nothing renames or empties it any more. Each session keeps its own read position (a cursor keyed by session id, under `.board/`). The hooks hand a session only the new moves that concern it:
   - moves on tickets it owns: handed over as today;
   - moves on unowned tickets: handed over with a note to claim the ticket first (`--lead <Name>`) and act only if the claim succeeds, because another session may claim it first;
   - moves on another session's tickets: skipped, never shown.
   A session with no name gets every move, as today, plus the reminder to get a name.
4. **The watcher.** `python tools/board_inbox.py watch <session_id>` prints each new move that concerns that session as one line, polling once a second, and advances the same cursor the hooks use, so a move is never delivered twice to the same session. `docs/working-with-the-board.md` ("The task board") is updated to start this watcher instead of the current tail-and-`take_inbox()` instructions.
5. **On the task board page:** each card shows its owner's name as a label (none when unowned), and the filter gets one button per owner name present plus "Unowned", working like the existing filters (several at once, remembered in local storage inside try/catch). `/api/tickets` includes `lead` for each ticket. The Builds tab shows each worktree's owner too.
6. Remove `take_inbox()` and the `board-inbox-heard.jsonl` bookkeeping, or keep them only as thin wrappers over the new cursor code, so there is one way moves are read.

Do not fill in any owner on existing tickets: the sessions claim their own tickets after this merges.

While testing, never stop or restart the live task board server on port 8765, and never read from or write to the live `.board/` folder of `C:\solid-carbide-game`: use a temporary state folder in tests and another port for manual checks.

## Acceptance criteria

- [ ] `tasks/_TEMPLATE.md` and every task file in `tasks/` have a `lead:` header line, empty on all existing tickets. QA checks with a script over `tasks/`. (QA: pass / fail)
- [ ] `task_status.py --lead` sets an empty owner, works with and without a status move, refuses a different existing owner without `--take-over`, and accepts it with `--take-over`. Unit tests cover each case. A hand edit of the `lead:` line is refused by the hook (QA checks by running the hook's pre-edit check on a sample edit). (QA: pass / fail)
- [ ] `board_inbox.py name` registers, renames and refuses a name another session holds. Unit tests cover each case, with a temporary state folder. (QA: pass / fail)
- [ ] With two sessions A and B in a temporary state folder, tickets owned by A, by B and unowned, and moves appended to the inbox: A's hand-over shows its own moves and the unowned ones (with the claim note) but not B's, and B likewise. Each move is handed to each session at most once, across hooks and the watcher together. Nothing empties or renames the inbox. Unit tests cover this. (QA: pass / fail)
- [ ] A session without a name gets every move plus a reminder to get a name. The SessionStart hook's output includes the session id and the command to register a name. Unit tests cover both. (QA: pass / fail)
- [ ] `board_inbox.py watch` prints one line per new relevant move and advances the shared cursor. QA checks it against a temporary state folder by appending moves while it runs. (QA: pass / fail)
- [ ] `/api/tickets` includes `lead` for each ticket, and `/api/builds` includes each worktree's owner. QA checks with a server on another port. (QA: pass / fail)
- [ ] The page shows an owner label on owned cards and an owner filter (one button per owner present, plus "Unowned"), saved in local storage inside try/catch. QA checks the page's code. The page's script passes `node --check`. (QA: pass / fail)
- [ ] Existing behaviour is unchanged: drags still move tickets through `task_status.py`, and the existing hook messages for each kind of move still read the same. The existing tests pass. (QA: pass / fail)
- [ ] `tasks/README.md` (the `lead` field and `--lead`), `tasks/_TEMPLATE.md`, `docs/README.md` ("The task board": owner labels and filter) and `docs/working-with-the-board.md` (session names, the new watcher command, and how unowned moves are claimed) describe the system as built. (QA: pass / fail)
- [ ] All three test sets pass: `python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`, and the Godot tests as described in `game/README.md`. (QA: pass / fail)

## Result notes

Built by the Project Lead's agent (2026-10-14), on branch `task/T-127-task-board-session-owners`.

**What was built**

- `tools/board_inbox.py` (new): session names and per-session reading of the inbox.
  - `python tools/board_inbox.py name <session id> <Name> [--take-over]` registers or renames. Names are one word (letters, digits, `-`, `_`, up to 30 characters), unique whatever their case. A name held by another *live* session is refused; `--take-over` moves it (needed after `/clear`, which starts a new session id).
  - `python tools/board_inbox.py watch <session id> [--interval 1]` prints one line per new move that concerns the session, polling once a second. An unnamed watcher prints the name reminder once when it starts.
  - `take(sid)` is the one way moves are read, used by the hooks and the watcher: it reads `.board/board-inbox.jsonl` from the session's cursor, advances the cursor, and keeps only the moves for this session (own tickets; unowned ones flagged "claim first"; another session's never). An unnamed session gets every move.
- `tools/task_status.py`: `T-NNN --lead <Name>` claims, with or without a status (`T-NNN in-progress --lead Tools`); `--take-over` overrides another owner. With a status, the claim is checked before the move, so a refused claim or a refused move changes nothing. Claims are logged to `.board/moves.log`. The usage text and `T-NNN` (show) mention the lead.
- `.claude/hooks/board_gate.py`: `lead` is guarded like `status` and `qa_rounds` (Edit/Write/MultiEdit and shell). `take_inbox()` and the `board-inbox-heard.jsonl` bookkeeping are removed; every hand-over goes through `board_inbox.take()`. SessionStart adds the session id, the name (if any), and the watcher command. `describe_moves` is unchanged, so the message for each kind of move reads the same; the claim note and the name reminder are added after it.
- `tools/taskboard_sync.py`: `lead` in each ticket (so in `/api/tickets`), the shared name pattern, and a small lock-file helper (`file_lock`).
- `tools/taskboard/server.py`: `/api/builds` has `lead` per worktree (the ticket's owner, "" otherwise).
- `tools/taskboard/taskboard.html`: an owner label on owned cards and in the Builds tab; an "Owner" filter row under "Show" with "Anyone", one button per owner on any ticket, and "Unowned", saved under `tbp-owners` in local storage (try/catch).
- Every task file in `tasks/` and `tasks/_TEMPLATE.md` has an empty `lead:` line, added right after `to:` (not next to `status:`, so open branches that change their status don't conflict with it). No owner filled in.
- Docs: `tasks/README.md` (new "Owners" section; `lead` in the hook rule), `tasks/_TEMPLATE.md` (header comment), `docs/README.md` ("The task board": cursors, owner labels and filter, `.board/sessions/`), `docs/working-with-the-board.md` ("Several Project Leads at once": names, claims, unowned moves; "The task board": the new watcher instead of the tail and `take_inbox()`).

**Design choices (where the ticket left it open)**

- State: one file per session, `.board/sessions/<session id>.json` = `{"name", "cursor", "seen"}`. The cursor is a byte offset into the inbox; only whole lines are read (a line still being written waits for the next read). Each read holds a per-session lock file, so the hooks and the watcher of one session never hand the same move twice; if the lock stays busy for 3 s the read hands nothing and loses nothing.
- "Live" session: one seen (any hook call, or the watcher, at least once a minute) in the last 12 hours. An older session's name can be registered by another session; it is then removed from the old one. Simplest rule that frees names of ended sessions without a SessionEnd hook (`.claude/settings.json` is unchanged).
- A session with no cursor starts at the current end of the inbox. A cursor past the end of the inbox (someone replaced it with a shorter file) reads from the start.
- Owners are read from the task file at hand-over time (the branch folder's copy while a branch is open), so a claim made after the drag still counts.
- Reminders: until named, SessionStart and every UserPromptSubmit carry the reminder; PostToolUse (Agent) and Stop carry it only together with moves, so a nameless session isn't kept from stopping just for the reminder.
- Owner filter: works like the existing filters within its row (several at once, a card matches any picked); a card must match both the "Show" row and the "Owner" row. A picked owner that no ticket has any more keeps its button, so it can be unpicked. "Unowned" uses the key `(unowned)`, which no name can be.
- A new task file may have an empty `lead:` or none; a new task with an owner is refused by the hook (claim it after writing it). Adding an empty `lead:` line by hand is allowed (none and empty mean the same).
- `T-NNN` (show) prints `, lead <Name>` only when there is one, so its output is unchanged for unowned tasks.

**Tests**

- `python -m unittest discover -s tools -p "test_*.py"`: 171 OK (was 130). New: `tools/test_board_inbox.py` (24 tests: names; cursors; two sessions A and B with owned, other and unowned tickets; once-only across hooks and watcher; inbox never emptied or renamed; unnamed session; SessionStart message; the watcher in a thread while moves are appended). `tools/test_task_status.py`: `Lead` class (10 tests: empty owner, missing line, with a move, refused, refused claim moves nothing, refused move claims nothing, take-over, claiming again, bad name and usage, CRLF), hook tests for the lead line, existing hand-over tests moved to session ids, and lead in `/api/tickets`. `test_taskboard_sync.py` and `test_taskboard_server.py`: lead in tickets and builds.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 180 OK.
- Godot (`bash game/tools/run_tests.sh`): 437/437 passing, `TESTS PASSED`, exit 0. Godot's line-ending-only `.import` noise was reverted, not committed.
- The page's script (extracted from `taskboard.html`) passes `node --check`.
- Manual: a server from this folder on port 8798 (its own `.board/`; the live server on 8765 was not touched) returned `lead` for all 127 tickets and all 7 builds; with T-001 claimed as Tools for the check (reverted after), headless Chrome showed the "Tools" label on T-001 and the Owner row "Anyone 111 / Tools 1 / Unowned 110". `watch` on that folder printed the two appended moves (the unowned one with the claim note) and its cursor ended at the inbox's size. The server was stopped and the test state removed.

**For QA**

- Use a temporary state folder or this folder's own `.board/` (`C:\solid-carbide-worktrees\T-127\.board`), never `C:\solid-carbide-game\.board`, and a port other than 8765 (`BOARD_PORT=8797 python tools/taskboard/server.py`, stop it with `BOARD_PORT=8797 python tools/taskboard/server.py --stop`).
- Hook pre-edit check on a sample edit: `tools/test_task_status.py`, `Hook.test_refuses_a_direct_lead_edit`, or by hand: `gate.pre_edit("Edit", {"file_path": <a task file>, "old_string": "lead:\n", "new_string": "lead: Tools\n"})` prints a deny naming `task_status.py T-NNN --lead Tools`.
- Watcher by hand: `python tools/board_inbox.py name qa1 Tools`, then `python tools/board_inbox.py watch qa1` in one shell, and append lines like `{"id": "T-002", "from": "open", "to": "planning", "note": ""}` to this folder's `.board/board-inbox.jsonl` in another.
- A claim on a ticket whose branch is open writes `lead: <Name>` into the branch's task file. If that branch's file has no `lead:` line yet, the script adds it after `to:`, the same place master has `lead:`, so that branch's merge will conflict on that one line: keep the branch's `lead: <Name>`.

**After the merge: what happens on the first run**

- The hooks run from `C:\solid-carbide-game`, so every live session uses the new code from its next hook call. The existing `.board/board-inbox.jsonl` is kept and only appended to; `board-inbox-heard.jsonl` and any leftover `board-inbox.*.taking` files are no longer read or written (they can stay).
- A live session has no cursor yet. Its first hook call after the merge (usually the board's next message) sets its cursor to the inbox's current end and hands over nothing old. Drags made between the merge and that first call are not handed to it (they stay in the inbox file). From then on it gets each new move once.
- Until it has a name, that session gets every move, and each board message reminds it of its session id and the `name` command.
- The running task board server keeps the old code in memory: drags still work and still reach the inbox, but `/api/tickets` and `/api/builds` have no `lead` (the new page then shows no owner labels and only "Unowned") until the server is restarted.

**Steps for each running session after the merge**

1. The merging session restarts the task board server once, after telling the board: `python tools/taskboard/server.py --stop`, then `python tools/taskboard/server.py` (or let a new session's hook start it).
2. Every session stops its old Monitor (the one that tails `.board/board-inbox.jsonl` and calls `take_inbox()`, which no longer exists and would only print an error).
3. Every session reads its session id from the next hook message (the name reminder), asks the board for its name if it hasn't one, and registers it: `python tools/board_inbox.py name <session id> <Name>`.
4. Every session starts the new watcher in a Monitor (30 minutes, re-armed each time): `python tools/board_inbox.py watch <session id>`.
5. Every session claims the tickets it planned or started: `python tools/task_status.py T-NNN --lead <Name>` (for tickets with an open branch, see the merge note under "For QA").

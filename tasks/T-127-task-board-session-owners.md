---
id: T-127
title: Named Project Lead sessions: ticket owners, owner labels, and every session sees every drag
status: open
from: project-lead
to: project-lead
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

Written by the agent when it finishes.

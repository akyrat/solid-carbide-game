---
id: T-138
title: Project Lead replies on the ticket at each lane change, and highlight cards the board hasn't opened since they changed
status: done
from: project-lead
to: project-lead
lead: Weapons
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md, docs/working-with-the-board.md, tasks/README.md, tasks/_TEMPLATE.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/working-with-the-board.md, tools/task_status.py, tools/taskboard_sync.py, tools/taskboard/server.py, tools/taskboard/taskboard.html, tasks/T-136-task-board-note-on-drag.md]
files_expected_to_change: [tools/task_status.py, tools/test_task_status.py, tools/taskboard_sync.py, tools/test_taskboard_sync.py, tools/taskboard/taskboard.html, tasks/_TEMPLATE.md, tasks/README.md, docs/README.md, docs/working-with-the-board.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board wants to read the Project Lead's replies on the ticket itself, not only in the terminal, and to see at a glance which tickets moved since it last looked (board, 2026-10-15).

**1. Project Lead replies on the ticket.** When a ticket changes lane, the Project Lead also posts the short reply it gives the board in the terminal (at most 2 to 3 paragraphs) on that ticket.

- `tools/task_status.py` gets a `--reply "<text>"` option. With a status change (`task_status.py T-043 in-qa --reply "..."`) it records the reply with that move; on its own (`task_status.py T-043 --reply "..."`) it records it against the ticket's current lane, for moves made by an agent or by the board's drag.
- A reply is stored in the task file in a new `## Updates` section, placed just before `## Result notes` (added there when missing; older tickets have none). Each entry has the date, the lane change (for example "In progress → In QA", or just the current lane), and the text, which may have several paragraphs and Markdown. Newest last in the file. Note that `taskboard_sync.py` reads Result notes to the end of the file, so the Updates section must not end up inside it.
- `tasks/_TEMPLATE.md` gets the empty `## Updates` section.
- `taskboard_sync.py` adds the updates to the ticket data the page reads.
- The ticket detail view on the task board shows, at the top (above the description), a "Latest from the Project Lead" box with the newest update: date, lane change, text rendered like the result notes. Under it, a collapsed "Earlier updates (n)" list with the older ones, newest first. Nothing shows for a ticket without updates.

**2. Highlight cards that changed since the board last opened them.** The page already keeps, in this browser, the status the board last saw for each ticket (`seen`, `isUnread`, `markSeen` in `taskboard.html`), and shows it in the "Changed" list. Extend it:

- A card in a lane is highlighted (a clear glowing outline in the page's cyan, plus a small "New" chip) when its status changed since the board last opened that ticket, or when a Project Lead update was posted since then.
- Opening the ticket's detail view clears the highlight, as it clears the "Changed" dot today. The board's own drags count as seen, as today.
- The "Changed" list uses the same rule, so the two always agree.

While testing, never stop or restart the live task board server on port 8765, and never read from or write to the live `.board/` folder of `C:\solid-carbide-game`: use another port and a temporary state folder. In the result notes, say whether the live server must be restarted after the merge for this to show.

Docs: `tasks/README.md` ("Changing a task's status") documents `--reply`; `docs/README.md` ("The task board") describes the updates box and the highlight; `docs/working-with-the-board.md` gets the rule: at every lane change of a ticket it owns (its own moves, an agent's, or the board's drag it acts on), the Project Lead posts its reply to the board on the ticket with `--reply`, the same text it writes in the terminal.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test moves a task with `--reply` and shows the task file gets a `## Updates` entry with the date, the lane change and the full multi-paragraph text, placed before `## Result notes` (QA: pass)
- [ ] A test posts `--reply` without a status change and shows an entry against the current lane, with the status unchanged; and that `## Updates` is added to an older task file that lacks it, without changing its Result notes (QA: pass)
- [ ] A test shows `taskboard_sync.py` returns a ticket's updates in order and that the result notes it returns do not include the updates (QA: pass)
- [ ] On a test server (another port, temporary state folder), a screenshot shows a ticket's detail view with the "Latest from the Project Lead" box above the description and a collapsed "Earlier updates" list (QA: pass)
- [ ] On the test server, a screenshot shows a highlighted card after its status changes, and another shows the highlight gone after the ticket's detail view is opened; posting a reply alone highlights the card again (QA: pass)
- [ ] `tasks/README.md`, `docs/README.md`, `docs/working-with-the-board.md` and `tasks/_TEMPLATE.md` are updated as the Description says (QA: pass)
- [ ] All Python tool tests pass (QA: pass)

## Result notes

Done by the Tools helper agent, in this folder and branch only.

**What changed**
- `tools/task_status.py`: new `--reply "<text>"`. With a move it adds an entry to the task file's `## Updates` section with that move (`### <date>, In progress → In QA`, then the full text, which may be several paragraphs). Alone it adds an entry against the current lane and leaves the status as it is. The section sits just before `## Result notes` and is created there when missing (or at the end of the file when there are no result notes); entries are newest last. A refused move posts no reply; an empty reply is refused. CRLF files stay CRLF. The command line was restructured a little so `--reply` and `--lead` combine with or without a move.
- `tools/taskboard_sync.py`: `parse_updates()` and an `updates` list on every ticket (oldest first, as in the file). The result notes it returns stop being affected by the section because Updates sits before them.
- `tools/taskboard/taskboard.html`: a "Latest from the Project Lead" box at the top of the ticket detail (date, lane change, text rendered like the result notes) with a collapsed "Earlier updates (n)" list, newest first; no box when there are no updates. Cards with a changed status or a new update get a glowing cyan outline and a "New" chip. What the board saw is now remembered as status plus update count; values an older page saved (just a status) still work and only compare the status. The same rule drives the Inbox "Changed" list. Opening the detail view (and "Mark all as seen") now also redraws the board lane cards, which it did not before.
- `tasks/_TEMPLATE.md` has the empty `## Updates` section. Docs: `tasks/README.md` ("Changing a task's status"), `docs/README.md` ("The task board") and `docs/working-with-the-board.md` (the reply rule) updated as the Description says.

**Tests** (all pass): `python -m unittest discover -s tools -p "test_*.py"` 180 tests OK (new: 7 in `test_task_status.py` class `Replies`, 2 in `test_taskboard_sync.py`); `python -m unittest discover -s game/tools -p "test_*.py"` 251 tests OK (1 skipped, as before).

**Screenshots** (real headless Chrome, driven over its DevTools port, against a throwaway copy of `tools/` with three demo tickets, its own state folder, on port 8791; the live board on 8765 and the live `.board/` were not touched). In `docs/screenshots/T-138/`:
- `3-detail-latest-and-earlier-updates.png`: detail view with the Latest box above the review section and "Earlier updates (2)" collapsed.
- `3a-detail-one-update.png`: a ticket with a single update (no earlier list).
- `1-baseline-no-highlight.png`, `2-card-highlighted-after-status-change.png` (T-902 glowing with "New" after in-progress → in-qa), `4-highlight-cleared-after-opening.png` (gone after opening its detail), `5-card-highlighted-after-reply-alone.png` (highlighted again after `--reply` with no status change). The page's own card state was also printed at each step and matched the pictures.

**After the merge:** the live task board server must be restarted for this to show, because the page and `taskboard_sync.py` are served by the running process (`python tools/taskboard/server.py --stop`, then start it again; a browser refresh then picks up the page). `task_status.py --reply` works at once, but the board shows nothing until then. First visit after the update: nothing is falsely highlighted, since older saved values compare on status only.
- 2026-10-15, in-qa → done: QA round 1: all 7 criteria pass. 180 + 251 tests OK; screenshots checked; Updates stays before Result notes (tested incl. older file, CRLF). Live board server needs a restart after merge.

---
id: T-202
title: Task board: goals shown on the board, with a goal filter
status: done
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_server.py, tools/test_taskboard_sync.py, tools/goal_agent/goal_file.py, goals/README.md, goals/G-003-build-the-elevation-system-in.md]
files_expected_to_change: [tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_server.py, tools/test_taskboard_sync.py, docs/README.md]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Goals given to the goal runner (`goals/G-NNN-*.md`, `tasks/README.md`, "Goal runs") have become the studio's unit of planning above tickets, like epics, but the task board doesn't show them: the board can't see a goal's status, its progress or which tickets belong to it (board, 2026-10-19). Tickets already carry their goal in the `goal:` header line; nothing about tickets or goal files changes.

1. **Reading goals.** The board reads every goal file's header (`id`, `title`, `status`, `art_cap`, `art_used`, `iteration`, `max_iterations`) from `goals/` in the main checkout (the runner commits them there), using the goal runner's own reader (`tools/goal_agent/goal_file.py`) rather than a second parser where that's reasonable, plus the goal's text (its `## Goal` section) and its latest pause, if paused. A goal's tickets are the tickets whose `goal:` line names it (wherever the ticket lives, as the board already finds tickets). `/api/goals` returns each goal with its tickets' ids and a count per status, and whether its build folder (`C:\solid-carbide-worktrees\<goal id>`, from `git worktree list`) exists.
2. **Showing goals.** A "Goals" strip above the lanes: one compact card per goal, newest first, showing its id, a short title, a status chip (planning, planned, building, paused, ready to play, done, cancelled; a paused goal shows its pause reason on hover), a progress bar and "N of M tickets done" (done or cancelled count as finished), art used of the cap when the cap is above 0, and the iteration. Done and cancelled goals are folded into a "Finished goals (n)" toggle, remembered in the browser like the other filters. Clicking a goal card opens its detail: the goal's text, its tickets as links that open them, its pauses, a link that shows the goal file's full text, and, when its build folder exists, the same Play and Open in editor buttons as the Builds tab for that folder.
3. **Filtering by goal.** A "Goal" row of filter buttons, like the "Owner" row: one button per goal with tickets, plus "No goal", several at once, "Any" clears; remembered in the browser. Cards in the lanes show their goal's id as a small label.
4. **Keep the board fast** and its look: the same refresh and caching as tickets; the goals strip is redrawn only when its data changes.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes (QA: pass)
- [ ] Tests show `/api/goals` returns each goal file's header fields and goal text, its tickets (from their `goal:` lines, including a ticket living in an open task folder) with a count per status, its latest pause when paused, and whether its build folder exists (QA: pass)
- [ ] The page shows the Goals strip (status chip, progress, art, iteration, finished goals folded), a goal's detail (text, ticket links, pauses, goal file, Play and Open in editor when its build exists), the Goal filter row and the goal label on cards; checked live by QA on a second board server (not port 8765) against the real `goals/` folder, or by reading the page code against this description where a browser isn't available (QA: pass)
- [ ] `docs/README.md` ("The task board") describes the goals strip, the goal detail, the Goal filter and `/api/goals` (QA: pass)

## Updates

### 2026-10-19, Open → In progress

Started: a Goals strip on the board (status, progress, art, the goal's detail and Play), a Goal filter, and each card labelled with its goal.

### 2026-10-19, In progress → In QA

Built: the Goals strip (status, progress, art, iteration), each goal's detail with its tickets, pauses, goal file and Play, a Goal filter row and goal labels on cards. 366 tools tests pass; checked live on a second server. QA checks it now.

### 2026-10-19, In QA → Done

QA passed all 4 criteria, checked live. Merged: the board shows a Goals strip, each goal's detail, a Goal filter and goal labels on cards, once restarted. T-203 (live agent activity) is next.

## Result notes

Built by the Project Lead's agent in `C:\solid-carbide-worktrees\T-202` (branch `task/T-202-board-goals`).

**What changed**

- `tools/taskboard_sync.py`: tickets now carry `goal` (their `goal:` line). New `goal_files()`, `goal_pauses()`, `goal()` and `goals_now()` read each goal file with the goal runner's own `GoalFile` reader (`tools/goal_agent/goal_file.py`, imported lazily so the hooks don't load it): header fields (numbers as integers), the `## Goal` text, every pause (date, kind, reason; a reason over 4000 characters is cut, with a note), `latest_pause` only while paused, the goal's tickets from their `goal:` lines (from `tickets_now()`, so a ticket in an open task folder counts with its folder's status), a count per status, finished (done + cancelled), and whether its build folder (the worktree named after the goal id) exists. Unreadable goal files and `README.md` are skipped; newest goal first.
- `tools/taskboard/server.py`: `GET /api/goals` (goals from `goals/` in the main checkout, the first entry of `git worktree list`, looked up once per served folder); `GET /api/goal-file?id=G-004` (one goal file's text, read-only, `text/plain`; ids other than `G-NNN` refused, localhost only). `version()` also hashes the goal files, so a changed goal file refreshes the page like a changed ticket.
- `tools/taskboard/taskboard.html`: the Goals strip above the filters and lanes (id, short title, status chip, progress bar, "N of M tickets done", "Art used of cap" when the cap is above 0, "Iteration i of max"; a paused goal's card shows its latest pause on hover); finished goals folded into "Finished goals (n)", remembered (`tbp-goals-finished`). Goal detail dialog: status and progress, the goal text, a Build section (Play and Open in editor through the existing Builds launch, using the Builds entry with the goal's id, when its build folder exists), ticket links (opening the ticket's detail on top) with a count per status, pauses newest first, and a link to the goal file's full text plus its Windows path. A "Goal" filter row (one button per goal with tickets, "No goal", "Any"; remembered as `tbp-goal-filter`), a goal label chip on lane cards, and a Goal row in the ticket detail. Goals are fetched with the tickets when the version changes; `setGoals()` redraws the strip (and an open goal detail) only when the goals' JSON changed.
- `docs/README.md` ("The task board"): a new "Goals" bullet describing the strip, the detail, the Goal filter, `/api/goals`, `/api/goal-file` and the refresh.

**Tests, per criterion**

1. Full run: `python -m unittest discover -s tools -p "test_*.py"`: 366 tests, OK (359 s).
2. `/api/goals`: `tools/test_taskboard_server.py`, `GoalsTests`: `test_goals_come_from_the_main_checkout_newest_first`, `test_header_fields_and_goal_text`, `test_tickets_with_a_count_per_status_including_an_open_task_folder`, `test_latest_pause_when_paused`, `test_whether_the_build_folder_exists`, `test_goals_on_tickets`, `test_no_goals_folder_is_an_empty_list`, `test_goal_file_full_text`, `test_version_changes_when_a_goal_file_changes`. `tools/test_taskboard_sync.py`, `GoalTests`: `test_goal_files_skip_other_files`, `test_goal_reads_the_header_and_goal_text`, `test_goal_tickets_from_their_goal_lines_with_counts`, `test_goal_pauses_and_latest_pause_when_paused`, `test_latest_pause_only_while_paused`, `test_goal_build_folder`, `test_goals_now_newest_first_skipping_unreadable_files`, `test_long_pause_reasons_are_cut`, `test_real_goal_files_all_parse`; plus `TaskboardSyncTests.test_ticket_reads_its_goal`.
3. Page: `GoalsPageTests.test_page_parts` checks the parts are in the page. Checked live: a second server from this folder on port 8799 (never 8765), against the real `goals/` (read-only). `/api/goals` returned G-004 (paused, 1 of 8 done, art 0 of 50, iteration 1, build folder `C:\solid-carbide-worktrees\G-004` exists, its pause reason), G-003 and G-002 (done), G-001 (paused, no tickets); `/api/goal-file?id=G-004` answered 200 text/plain. A headless Edge screenshot shows the strip (G-004 and G-001, "Finished goals (2)" folded), the Goal filter row and the goal labels on cards: `art-archive/T-202/screenshots/goals-strip.png`. The goal detail dialog was not clicked through in a browser (headless screenshot only), so QA should open a goal card on a second server. The server was stopped afterwards.
4. `docs/README.md`, "The task board", "Goals" bullet.

**Refused:** a one-off `python -c` command that copied the page's script to the scratchpad for a `node --check` syntax check was refused by the PreToolUse hook (it read it as a task-file edit). I didn't retry it another way; the headless browser render above ran the script without visible errors (the strip, filters and cards it draws all appeared).

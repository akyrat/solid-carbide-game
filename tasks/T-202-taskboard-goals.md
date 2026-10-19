---
id: T-202
title: Task board: goals shown on the board, with a goal filter
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
documents_affected: [docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_server.py, tools/test_taskboard_sync.py, tools/goal_agent/goal_file.py, goals/README.md, goals/G-003-build-the-elevation-system-in.md]
files_expected_to_change: [tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_server.py, tools/test_taskboard_sync.py, docs/README.md]
model: opus
qa_rounds: 0
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

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes (QA: pass / fail)
- [ ] Tests show `/api/goals` returns each goal file's header fields and goal text, its tickets (from their `goal:` lines, including a ticket living in an open task folder) with a count per status, its latest pause when paused, and whether its build folder exists (QA: pass / fail)
- [ ] The page shows the Goals strip (status chip, progress, art, iteration, finished goals folded), a goal's detail (text, ticket links, pauses, goal file, Play and Open in editor when its build exists), the Goal filter row and the goal label on cards; checked live by QA on a second board server (not port 8765) against the real `goals/` folder, or by reading the page code against this description where a browser isn't available (QA: pass / fail)
- [ ] `docs/README.md` ("The task board") describes the goals strip, the goal detail, the Goal filter and `/api/goals` (QA: pass / fail)

## Updates

## Result notes

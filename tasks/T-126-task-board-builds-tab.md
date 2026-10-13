---
id: T-126
title: A Builds tab on the task board that opens each worktree's game in Godot
status: open
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md, docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/working-with-the-board.md, tools/taskboard/server.py, tools/taskboard/taskboard.html, game/README.md, .env.example]
files_expected_to_change: [tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/test_taskboard_server.py, docs/README.md, docs/working-with-the-board.md]
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

The board playtests each ticket from its own worktree (`C:\solid-carbide-worktrees\<id>\game\project.godot`) and today has to find and open that folder by hand. It wants to jump from a ticket on the task board straight into that ticket's version of the game.

The board chose a launcher, not an embedded game: a browser page can't hold a native Godot window, and a web export would need the Compatibility renderer instead of the game's Forward+ (board, 2026-10-13). Embedding stays a possible later step and is not part of this task.

Build:

1. **A "Builds" tab** on the task board page, next to the existing views. It lists `master` (the main repo, `C:\solid-carbide-game\game`) and every worktree from `git worktree list`. For each entry it shows the folder, the branch, the ticket id and title (when the branch is `task/T-NNN-...` and a matching task file exists in that worktree or in `master`'s `tasks/`), and the ticket's status. A worktree without a `game/project.godot` is listed but its buttons are disabled.
2. **Two buttons per entry:**
   - **Play** runs the game: `"$GODOT_BIN" --path <worktree>\game`.
   - **Open in editor** opens the project in the Godot editor: `"$GODOT_BIN" --editor --path <worktree>\game`.
   Godot is started detached, without a console window popping up (same approach as T-110), and the request returns at once. If `GODOT_BIN` is missing from `.env` or the file doesn't exist, the button shows a clear error on the page instead of failing silently.
3. **From a ticket:** each ticket card (or its detail view) that has a worktree gets a Play button and a link that jumps to the Builds tab with that entry highlighted.
4. **Server endpoints:** `GET /api/builds` returns the list; `POST /api/launch` with `{"id": <entry id>, "mode": "play" | "editor"}` starts Godot. The server only launches folders that are in its own worktree list, so the page can never pass in an arbitrary path or command. `POST /api/launch` uses the same localhost and `X-Board: 1` checks as `/api/move`.
5. The list refreshes when the page polls (as tickets do), so a new worktree shows up without restarting the server.

Godot's path comes only from `GODOT_BIN` in `.env` (as in `game/README.md`). Nothing else is read from `.env`, and no secret goes to the page.

## Acceptance criteria

- [ ] `GET /api/builds` on a running server returns one entry for `master` and one per worktree from `git worktree list`, each with folder, branch, ticket id, ticket title, ticket status, and whether `game/project.godot` exists. QA checks it against the current worktrees. (QA: pass / fail)
- [ ] `POST /api/launch` refuses (4xx, nothing started) a request without `X-Board: 1`, from a non-localhost `Host`, with an unknown entry id, with a mode other than `play` or `editor`, and for an entry without `game/project.godot`. Unit tests in `tools/test_taskboard_server.py` cover each case, with the actual process start replaced by a stub. (QA: pass / fail)
- [ ] For a valid request, the stubbed launcher receives exactly `[GODOT_BIN, "--path", <folder>\game]` for `play` and `[GODOT_BIN, "--editor", "--path", <folder>\game]` for `editor`, started detached with no console window. Covered by unit tests. (QA: pass / fail)
- [ ] With `GODOT_BIN` missing or pointing to a file that doesn't exist, `POST /api/launch` returns an error message the page shows. Covered by a unit test, and QA checks that the page's code shows it. (QA: pass / fail)
- [ ] The page has a Builds tab listing the entries with both buttons, disabled where there is no `project.godot`. Ticket cards with a worktree have a Play button and a link to their entry in the Builds tab. QA checks the page's code and, with the server running, that the tab's data matches `/api/builds`. (QA: pass / fail)
- [ ] Manual launch check: with the server running, QA calls `POST /api/launch` for `master` in `play` mode and confirms a Godot process starts with `--path C:\solid-carbide-game\game` (via the process list), then closes it. (QA: pass / fail)
- [ ] Existing task board behaviour is unchanged: `/api/tickets` and `/api/move` work as before, and the existing task board tests pass. (QA: pass / fail)
- [ ] The page's script passes `node --check`. (QA: pass / fail)
- [ ] `docs/README.md` ("The task board") describes the Builds tab and its buttons, and `docs/working-with-the-board.md` ("Showing work") says a ticket can be played from the Builds tab as well as by opening the worktree's `project.godot`. (QA: pass / fail)
- [ ] All three test sets pass: `python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`, and the Godot tests as described in `game/README.md`. (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

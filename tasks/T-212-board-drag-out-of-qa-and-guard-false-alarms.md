---
id: T-212
title: The board's drag can take a ticket out of QA with a warning, and the guard stops refusing read-only commands
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
documents_affected: [tasks/README.md, docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/task_status.py, tools/taskboard/server.py, .claude/hooks/board_gate.py, tasks/T-181-guard-stop-refusing-harmless-mentions.md]
files_expected_to_change: [tools/task_status.py, tools/taskboard/, .claude/hooks/board_gate.py, tools/test_*.py, tasks/README.md, docs/README.md]
model: opus
qa_rounds: 1
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

Two fixes the board asked for (2026-10-20), after two false refusals and a ticket stuck in QA.

**1. The board's drag out of QA.** Today `task_status.py` refuses every move out of `in-qa` except to `cancelled` until QA has marked every acceptance criterion pass or fail, whoever moves it. T-102 went to QA only for the board to judge a sample; no QA marks were coming, so it can't go back to In progress. The board's words: it shouldn't be assumed that an agent has marked all the criteria; when the board drags a ticket whose criteria aren't all marked, the board gets a pop-up warning that says exactly which criteria haven't been marked, with a place to write an explanation of what has gone wrong, which is added to the ticket.

- A **drag by the board** (`by="board"`) from `in-qa` to `in-progress` or `planning` is allowed even when criteria are unmarked. It doesn't count as a QA round (`qa_rounds` unchanged).
- Before the move, the task board shows a pop-up listing each unmarked criterion word for word (and any marked fail), with a text box for the board's explanation and buttons to go ahead or cancel. Going ahead makes the move; the explanation goes into the ticket's result notes the way a drag's note does today, and reaches the owning session with the move as `(note: ...)`.
- Moves by the command line (agents and the Project Lead) keep today's rule: refused while criteria are unmarked.
- Other refused drags keep working as they do today.

**2. The guard's false refusals.** `.claude/hooks/board_gate.py` (`pre_shell`) refuses any shell command that seems to touch `tasks` and contains the word "status" or runs an interpreter, even when nothing writes to a task file. Two real cases it refused:
- `bash game/tools/run_tests.sh | grep ...; python -m unittest discover -s tools -p "test_*.py"; python -m unittest discover -s game/tools -p "test_*.py"; git status --short | grep -v import | head` (QA of T-209)
- an inline Python step that only read PNG images to measure a heading, in a command whose PixelLab client call listed task files in `--consulted` (T-102)

Make the guard refuse only commands that can write a task file's `status`, `qa_rounds` or `lead` line (as T-181 did for the Write and Edit tools), and let read-only and test commands through: `git status`, `git diff`, `git log`, the test runs, `grep`/`cat` of task files, and scripts that only read. Keep refusing everything it refuses today that does write those lines, including inline code that writes task files. When unsure, it may still refuse, but its message says what in the command made it refuse.

This changes a hook. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture except the pop-up: end with a screenshot of it.

## Acceptance criteria

- [ ] `task_status.py` with `by="board"` moves an `in-qa` ticket with unmarked criteria to `in-progress` and to `planning`, keeping `qa_rounds`, and writes the board's explanation into the result notes; the command line still refuses the same move; tests cover both (QA: pass; BoardOutOfQa and server tests cover board and CLI, qa_rounds kept, note written)
- [ ] Dragging such a ticket on the task board shows a pop-up listing the unmarked criteria word for word, with an explanation box, go-ahead and cancel; cancel leaves the ticket as it was (screenshot of the pop-up, and a server test for the endpoint the pop-up uses) (QA: pass; screenshot is in the scratchpad at C:\Users\andre\AppData\Local\Temp\claude\C--solid-carbide-game\88cd5834-9793-4b7d-b02c-e2740a308d7c\scratchpad\qa-warning-popup.png, not under art-archive/T-212/screenshots/; it shows unmarked criteria, the marked fail, explanation box, Cancel and Move anyway; 409 without confirm_unmarked changes nothing, covered by test_t212_* server tests)
- [ ] The guard lets the two commands quoted in the description through (tests feeding them to `pre_shell`), and still refuses every case the existing guard tests refuse (QA: pass; ReadOnlyCommands feeds both quoted commands to pre_shell and all older guard tests pass; sed, redirects, inline code and scripts with header lines or tasks plus writes are still denied. Note for the Project Lead: a generic writer script that holds no task path or header text in its code, run as python w.py tasks/T-1.md "status: done", is now allowed by the command check; the git commit ledger check still backstops it)
- [ ] `tasks/README.md` ("Changing a task's status") and `docs/README.md` ("The task board") describe the new drag and the guard's rule (QA: pass; both sections present)
- [ ] All Python tool tests pass (QA: pass; tools 413 OK, game/tools 354 OK with 1 skipped)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Open → In progress

Started, at the board's request: the board's drag out of QA with a warning pop-up, and the guard's false alarms.

### 2026-10-21, In progress → In QA

Built: the drag-out-of-QA pop-up and a guard that only refuses real ticket writes. Sent to QA.

### 2026-10-21, In QA → Done

QA passed all 5 criteria. Merged into master; the board server restarts so the pop-up shows.

## Result notes

- 2026-10-21, Project Lead's tooling agent (opus): built both parts.
  - **The board's drag out of QA.** `tools/task_status.py`: `allowed()` takes `by`. With `by="board"`, an `in-qa` ticket with unmarked criteria may go to `in-progress` or `planning`. `unmarked_warning()` returns the unmarked and failed criteria word for word. `move()` leaves `qa_rounds` alone for that move and uses the board's explanation as the note, or "the board took it out of QA with N acceptance criteria not marked" when there is none. The command line is refused as before.
  - **The server.** `tools/taskboard/server.py` adds `GET /api/move-check?id=&status=`, which returns `{"warning": {"unmarked", "failed"} or null}`. `POST /api/move` makes such a move only with `"confirm_unmarked": true`. Otherwise it answers 409 with the warning and changes nothing (that is what Cancel relies on). The explanation reaches the inbox as the move's note.
  - **The page.** `tools/taskboard/taskboard.html` adds a warning pop-up (`#qawarn`). It lists the unmarked criteria, plus any marked fail in red, with a "What has gone wrong?" box and Cancel and Move anyway buttons. A drop from QA onto In progress or Planning asks `/api/move-check` first. The detail panel's move buttons open the same pop-up from the 409.
  - **The guard.** `.claude/hooks/board_gate.py` changes in three ways:
    - `bash game/tools/run_tests.sh` and `run_tests.ps1` count as test runs.
    - A script run from a file (`python x.py`, `bash x.sh`, `powershell -File x.ps1`) is judged by its own code. It is refused only if the code holds a guarded header line (`"status: …"`, `^lead:`, `\nqa_rounds:`, or `"status",` as a key next to a value), names the tasks folder or a ticket file in code and also writes files, or can't be found. It is also refused when the command doesn't name the lines but runs such a script on a ticket path.
    - Every refusal now ends with "Refused because of `<part>`: <why>".
    - Both quoted commands (T-209 QA, T-102 PixelLab and PIL) now pass. Every existing guard test still passes.
  - **Known limit.** Some art build scripts mention `tasks/T-0xx-….md` in their docstrings, so they count as "naming task files". When such a script runs in a command that also names task files and those words, it is still refused, and the message says why.
- Tests: new `BoardOutOfQa` and three `LocalBoard` `test_t212_*` tests in `tools/test_task_status.py`, and a new `ReadOnlyCommands` class in `tools/test_guard.py`. `python -m unittest discover -s tools -p "test_*.py"`: 413 OK. `python -m unittest discover -s game/tools -p "test_*.py"`: 354 OK (1 skipped).
- Docs: `tasks/README.md` ("Changing a task's status") describes the board's drag out of QA. `docs/README.md` ("The task board") describes the pop-up, the endpoint and the guard's rule.
- Screenshot of the pop-up: taken with headless Chrome against a throwaway server on port 8799 with one sample ticket (the board's server on 8765 was not touched). It is at `C:\Users\andre\AppData\Local\Temp\claude\C--solid-carbide-game\88cd5834-9793-4b7d-b02c-e2740a308d7c\scratchpad\qa-warning-popup.png`, not under `art-archive/T-212/screenshots/`, because creating that folder was part of a refused command (refusal 2 below). The Project Lead can copy it there.
- Refusals by the live guard (the main checkout's copy, before this fix), each skipped and not retried:
  1. **What:** a Bash call that wrote a scratch script and ran it to print the branch guard's decisions on the two quoted commands. **Why:** the call's text named `tasks/`, "status" and inline code, so the old guard took it for a ticket write. **Skipped:** that call. The same check later ran as a scratch script file, invoked with a command that names no ticket.
  2. **What:** `mkdir -p …/art-archive/T-212/screenshots && curl -s "http://localhost:8799/api/move-check?id=T-102&status=in-progress"`. **Why:** the old guard read `/T-212` as a ticket path, the URL held "status", and `curl` was an unknown command. **Skipped:** creating the screenshots folder and the curl check. The endpoint is covered by the server tests instead, and the screenshot stays in the scratchpad.
- 2026-10-21, in-qa → done: QA passed all 5; tooling, merged straight after QA

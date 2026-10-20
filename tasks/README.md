# Tasks

One file per task, named `T-001-short-title.md`, using `_TEMPLATE.md`. Tasks are the official record of all work on the game. The Project Lead writes them, agents work from them and write result notes, and QA/Integration writes pass or fail per criterion.

Every agent reads this file before starting any task. Every task file lists it first in `files_to_read_first`.

The board follows these tasks on its local task board (`docs/README.md`, "The task board"), which reads these files directly; the task files here remain the source of truth.

## Status rules

- `planning`: the board is refining the ticket with the Project Lead, answering its open questions before work starts (board, 2026-10-13). The board drags a ticket to the Planning column when it mentions it; the Project Lead reads the ticket and brings its open questions to the board. It is optional: a ticket can go straight from `open` to `in-progress`.
- When QA passes every criterion: a task with a `The board's review:` line moves to `needs-playtest` for the board; any other task is marked `done` and merged by the Project Lead straight away (board, 2026-10-10).
- Tasks are never deleted. A task that is no longer wanted gets `status: cancelled`, with a short note in its result notes saying why and when, so its content stays on record.
- A task whose `depends_on` lists any task that is not `done` starts as `blocked`.
- When a task becomes `done`, every task whose `depends_on` tasks are now all `done` moves from `blocked` to `open`, in the same commit that marks the task `done`.

## Changing a task's status

A task changes status only through the status script, never by editing its `status`, `qa_rounds` or `lead` line (hooks refuse that edit). The hooks recognise a task file by its path in any spelling (relative, other case, `..`) and by its header, and they look at every `status`, `qa_rounds` or `lead` line in the header, so a repeated line is caught too. Shell commands may mention those lines as long as they can't write them (T-181): reads (`grep -n "^status:" tasks/T-012*.md`, `sed -n` without `-i`, `head`, `cat`, `git log`, `Select-String`, `Get-Content`), status script calls, git, test runs, writes to files that can't be tickets, and appends of plain text to a ticket's notes with no line starting `status:`, `qa_rounds:` or `lead:`. A command that could write those lines into a ticket (`sed -i`, `>`, `>>` of such a line, `tee`, `perl -i`, Python or PowerShell writes that name a task file), or that the hook can't read (a computed file name or folder, a substitution that names task files), is refused:

A command cannot be checked in every way a file can be written, so there is a second guard (T-149, `tools/guard_ledger.py`). The status script records in `.board/blessed-states.jsonl` (in the main checkout, shared by every task folder) each state of those three lines it writes, and refuses to move or claim a task whose lines are neither in that record nor what git has committed ("changed by hand"). The hook runs the same check on `git commit`, so a hand-edited line cannot be committed, whichever tool edited it. If a merge conflict in a task's header was resolved by hand, run the status script to set the line it should have; the commit is refused until then. The record is created by the first script run, which trusts the task files as they are.

```
python C:/solid-carbide-game/tools/task_status.py T-012             # where it is, and the moves allowed now
python C:/solid-carbide-game/tools/task_status.py T-012 in-qa        # move it
python C:/solid-carbide-game/tools/task_status.py T-012 cancelled --note "Why, and when"
python C:/solid-carbide-game/tools/task_status.py T-012 in-qa --reply "Short reply to the board"
python C:/solid-carbide-game/tools/task_status.py T-012 --reply "Reply for a move an agent or the board made"
```

Always use the main repo's copy of the script, also from a task's branch folder: it finds open task branches and changes the task file where it lives. It checks the workflow, so a task can't skip a phase:

- `open`/`blocked` → `planning` always (a blocked ticket can be refined while it waits).
- `open`/`blocked`/`planning` → `in-progress` only when every task in `depends_on` is `done`, or is `needs-playtest` with the same non-empty `goal:` as this task (T-163; "Goal runs").
- `planning` → `open` or `blocked`, and `in-progress` → `planning`, to go back.
- `in-progress` → `in-qa` only once the agent has written its result notes.
- Out of `in-qa` only once QA has marked every acceptance criterion `(QA: pass)` or `(QA: fail ...)`. A pass mark may carry a short note after `;`, `:`, `,` or ` -`, for example `(QA: pass; 850/850)` (T-179). The script adds one to `qa_rounds`. All pass: `done`, or `needs-playtest` when the task has a `The board's review:` line. A fail: back to `in-progress` the first time, `flagged-for-review` the second time.
- The board's drag out of QA (board, 2026-10-20, T-212): it isn't assumed that QA has marked every criterion. A drag on the task board (`by="board"`) may take an `in-qa` ticket whose criteria aren't all marked back to `in-progress` or `planning`, after a warning that lists the unmarked criteria (and any marked fail) word for word and asks what has gone wrong (`docs/README.md`, "The task board"). The explanation is the move's note: it goes into the result notes and reaches the owning session with the move as `(note: ...)`; without one, the note says how many criteria were unmarked. It doesn't count as a QA round (`qa_rounds` unchanged). Moves from the command line, by agents and the Project Lead, are still refused while criteria are unmarked.
- `done` and `cancelled` are final; rework is a new task. Cancelling needs `--note`.
- Marking a task `done` moves every task now waiting on nothing from `blocked` to `open`. So does moving a goal's task to `needs-playtest`, for that goal's tasks.

`--reply "<text>"` posts the Project Lead's reply to the board on the ticket (board, 2026-10-15, T-138): the same short text (2 to 3 paragraphs at most, Markdown allowed) it gives in the terminal. With a move it is recorded with that move; on its own it is recorded against the ticket's current lane, for a move an agent or the board's drag made. It is stored as a dated entry (`### <date>, <lane change>`, newest last) in the task file's `## Updates` section, which sits just before `## Result notes` and is added there when a task file has none. A refused move posts no reply. The task board shows it on the ticket and highlights the card (`docs/README.md`, "The task board").

Each move shows on the task board within a couple of seconds. The board moves tasks there too, through this same script, so its moves follow these rules (`docs/README.md`, "The task board").

The script changes only the task file and never commits (board, 2026-10-14, T-109). On a task's branch the change goes into the next commit there (the agent's, QA's or the Project Lead's); on `master` it goes into the Project Lead's next commit.

## Owners

The board runs several Project Lead sessions at once, each with a short name the board gives it, for example "Camera" or "Tools" (`docs/working-with-the-board.md`, "Several Project Leads at once"). The `lead` line in a task's header names the session that owns the task. It is empty until a session claims the task, and like `status` it changes only through the status script (hooks refuse a hand edit):

```
python C:/solid-carbide-game/tools/task_status.py T-012 --lead Tools                  # claim it
python C:/solid-carbide-game/tools/task_status.py T-012 in-progress --lead Tools      # claim it and move it
python C:/solid-carbide-game/tools/task_status.py T-012 --lead Tools --take-over      # take it from another session
```

- A claim sets an empty `lead`. Claiming a task the session already owns changes nothing.
- A task another session owns is refused, unless `--take-over` is given (only when the board wants it moved to this session).
- With a status in the same call, the claim is checked first: if either the claim or the move is refused, nothing changes.
- A new task starts with an empty `lead`. A task file without a `lead` line counts as unowned; the script adds the line when it sets it.

The task board shows each owner on its cards and in the Builds tab, and hands the board's drags on a task only to its owner (`docs/README.md`, "The task board").

## Git branches

Work that changes the game, its tools or its assets is done on its own branch, so unfinished work never sits uncommitted on `master`.

- **One branch per task,** named `task/<id>-<short-title>`, for example `task/T-013-placeholder-car-sprites`, made from the latest `master`.
- **One folder per task:** the Project Lead creates the branch as a git worktree in a sibling folder, `C:\solid-carbide-worktrees\<id>`, and copies the git-ignored `.env` (and `.secrets/`, if the task needs it) into it. Agents working in parallel each have their own folder, so they never switch branches under each other.
- **The agent works and commits only in its task's folder,** on its task's branch, in small commits with clear messages. It never commits to `master`, never merges, and never pushes.
- **While a task's branch is open, its task file is edited only on that branch.** The Project Lead reads the task's status there.
- **QA checks the task in the same folder.**
- **When the board marks the task done,** the Project Lead merges the branch into `master`, then removes the worktree and deletes the branch.
- **Documentation-only work** (for example the Project Lead's own document edits) is committed straight to `master`.

## Goal runs

The board can give a whole goal to the goal runner (`tools/goal_agent/`, board, 2026-10-18), which plans, writes and builds the tickets for it in a loop. The board's side of it is in `docs/working-with-the-board.md`, "Goal runs". On the ticket side:

- Each goal has one file in `goals/`, `G-001-short-title.md`, with a parseable header. It holds the goal, its acceptance criteria (the runner's stop condition), the prioritised sub-goals, the tickets it wrote or reused, a log of every iteration, and the open questions the docs leave unanswered (for the board; the runner never invents an answer).
- A ticket the runner writes or reuses gets the goal's id in its `goal:` header line. A reused ticket gets it only when its branch isn't open and it has no goal yet; the runner doesn't claim a reused ticket, since it may belong to another session. Its tickets follow every rule in this file: the template, the status script, placeholders before art, a text ticket before any player-facing text.
- A goal's tickets that pass QA are merged into `playtest/<goal id>`, and wait there in `needs-playtest` (or `done`, for work the player never meets) until the board has played the goal's build. Their worktrees stay until then, so their status can still be read; they are removed when the Project Lead merges the goal's build.
- A reused ticket that another session owns is never built by the runner: the goal waits for it, and pauses (`waiting`) when nothing else can go on.
- When the Project Lead merges the goal's build, a ticket's `status:` line may conflict (master's copy was unblocked by the status script, the build's copy moved on): keep the build's side.
- The runner records what its headless sessions do (T-203): each session runs with `--output-format stream-json --verbose`, and every event is appended, as it arrives, to `.board/activity/<ticket id>.jsonl` (the agent and QA) or `.board/activity/<goal id>.jsonl` (the goal check) in the main checkout, git-ignored like the rest of `.board/`. One line per event: its time, its step (`agent`, `qa`, `goal-check`) and the event, cut down (long text shortened, tool output left out). The answer and the refusals the runner reads are the same as before. A log past 2 MB keeps only its last 500 KB, and a log can be deleted at any time. The task board shows it as each card's Now line, a timeline in the ticket's detail and the current ticket on the goal's card (`docs/README.md`, "The task board").
- `run.py resume` sets the goal's status to `building` and saves the goal file as soon as it carries on, so the board doesn't show a running goal as `paused` until its next ticket finishes.

## Building in playable steps

The board's way of building the game (2026-10-10): always aim for the smallest playable version of the work, playtest it, then build on it. The Project Lead orders and splits tasks so each wave ends in something the board can play. The current steps toward the MVP:

1. **Bare loop:** the main menu, Start, the run on the MVP map with the timer running down, pause, back to the menu (Garage not wired yet).
2. **Tricks:** trick popups from the car, so the board can check and tune the tricks.
3. **Likes:** the likes bar and the level going up from drifting (no level-up screen yet).
4. **Combo and challenges:** the combo stacking on likes; challenges giving likes, with a popup from the car; the fitted challenges checked as drivable and fun. (Played 2026-10-11: challenges were then left out of the MVP.)
5. **The car's art in the game:** the final car in all 16 directions, playtested in a run (board, 2026-10-12).
6. **Map tiles:** generating the map's tile art (board, 2026-10-12).
7. **Later:** minions, then the weapons, then the kaiju, the garage and sound. The board moved enemies much later on 2026-10-12.

## Epics and milestones

Every task file has an `epic` and a `milestone` in its header.

**Epic:** the area of the game the work belongs to. The epics follow the game area docs in `docs/`.

| Epic id | Covers | Game area doc |
|---|---|---|
| `driving` | The car's driving, drift and camera | Drifting |
| `enemies` | Enemies and the boss | Enemies |
| `weapons` | Weapons and their upgrades | Weapons |
| `level-challenges` | The map and its driving challenges | Level design |
| `garage` | The garage and persistent car upgrades | Garage design |
| `hud-menus` | The HUD, menus and settings | HUD and menus |
| `art` | Generated and placeholder art | Visual style |
| `sound` | Sound effects and music | (none yet) |
| `game-loop` | The run itself: timer, likes and levels, level-up flow, win and loss, the main menu and the flow between screens | Game loop architecture |
| `narrative` | Story and user-facing text: tone, wording, names | Extended narrative |
| `tooling` | Project setup, test tools and documentation tooling | (not a game area) |
| `local-coop` | Local co-op for 2 players (screen split in halves) and 4 players (split in quarters). Future release | Game loop architecture |

**Milestone:** the release the work is needed for.

| Milestone id | Means |
|---|---|
| `mvp` | The first complete version: the game the Final GDD describes, as updated by the game area docs. |
| `final-release` | The full game. |

What each milestone includes is decided in the game area docs (for example, how many weapons the MVP has), not here. A new epic or milestone is added here first, with the board's agreement.

## The board's review

When a task needs the board to look at, read, listen to or play something, its task file says so in one line starting `The board's review:`. **Every Asset Generation task gets the board's review** (board, 2026-10-10): the board stays in control of how the assets look and their style. Until an asset's art task is done, the game uses placeholders. A line starting `Board review files:` lists the files to open, relative to the task's folder. The task board shows both, with the agent's and QA's result notes, when the board clicks a ticket.

## Screenshots

Every task ends with screenshots of its work wherever anything can be shown (board, 2026-10-19), whether or not it has a `The board's review:` line:

- **Something on screen** (a scene, an effect, a screen, art in the game): screenshots of it in the game, taken with the screenshot tool (`game/README.md`), enough to show the change (for motion, a few frames or a strip).
- **Nothing on screen yet** (data, a layout, physics numbers): a picture drawn from the data by a script where it helps (a map of a layout, a plot of a curve), saying what it shows.
- **Nothing to picture** (tooling, docs, text-only work): none; the result notes say so in one line.

They go in `art-archive/<task id>/screenshots/` (subfolders are fine) and are listed in the result notes (and on the `Board review files:` line, when there is one). The agent that does the work takes them; QA checks they exist and show what the notes say. Where a still doesn't show the change (motion, an effect, a camera move), add a short recording, a GIF or an MP4, in the same folder.

The task board shows them on the ticket (T-201): every image and recording (`.png`, `.jpg`, `.gif`, `.webp`, `.mp4`, `.webm`) in that folder, and any media file on the `Board review files:` line, appears in the ticket's "Screenshots and recordings" section, read from the task folder while the branch is open (`docs/README.md`, "The task board").

## Models

Every task says in its header which model the agent runs on: `model: sonnet` or `model: opus` (board, 2026-10-09). The Project Lead picks it per task and launches the agent with it:

- **sonnet:** clearly scoped work: art, sound, data files, simple screens, reports, and QA checks.
- **opus:** tricky work: code that ties several agents' work together, complex behaviour, porting from the Unity prototype, and any task that failed QA once. QA always runs on sonnet, whatever the task's model (board, 2026-10-15, to cut QA's token use; it was opus for tasks the board was about to playtest).

The hooks enforce it (board, 2026-10-13; `.claude/hooks/board_gate.py`): an agent whose prompt names a task (its first `T-` id) starts only when the Agent call passes that task's model. The QA/Integration Agent always needs sonnet. To run a task on another model, change its `model` line first.

## User-facing text and visuals

Every task file says in its header whether it adds or changes anything the player reads or sees:

- `user_facing_text: yes` when the task adds or changes any words the player sees in the game (menus, HUD, weapon names, descriptions, messages). The task then lists `docs/extended-narrative.md` in `files_to_read_first`, so the text fits the game's story and tone.
- `changes_visuals: yes` when the task adds or changes anything the player sees (art, sprites, effects, screens, the camera). The task then lists both `docs/visual-style.md` and `docs/extended-narrative.md` in `files_to_read_first`.

Otherwise each field is `no`. The Project Lead sets both fields when writing a task.

**Generated art is archived, never deleted.** Only clean, game-ready art goes under `game/art/`; every other generation goes to `art-archive/<task id>/` with its record (Visual style, Decisions).

**Art replaces placeholders.** When work has a visual and a functional side, the functional task builds it with a placeholder and does not wait for the art. The linked art task lists the functional task in `depends_on` and, once its art is made, swaps it in for the placeholder itself; its acceptance criteria include seeing the final art in the game.

**Player-facing text comes from the Narrative Theme Agent.** When a task has `user_facing_text: yes`, the Project Lead also writes a linked text task for the Narrative Theme Agent: what each piece of text is for, where it appears, any space limit, and the facts it must state. That agent writes the final text in its task's result notes. The main task lists the text task in `depends_on` and uses exactly that text: no placeholder text, and no wording of the building agent's own. If an agent finds its work needs text that its text task doesn't cover, it doesn't write any; it says so in its result notes and the Project Lead gets the text from the Narrative Theme Agent.


# Tasks

One file per task, named `T-001-short-title.md`, using `_TEMPLATE.md`. Tasks are the official record of all work on the game. The Project Lead writes them, agents work from them and write result notes, and QA/Integration writes pass or fail per criterion.

Every agent reads this file before starting any task. Every task file lists it first in `files_to_read_first`.

The board follows these tasks on its task board page (`docs/README.md`, "The task board"); the task files here remain the source of truth.

## Status rules

- When QA passes every criterion: a task with a `The board's review:` line moves to `needs-playtest` for the board; any other task is marked `done` and merged by the Project Lead straight away (board, 2026-10-10).
- Tasks are never deleted. A task that is no longer wanted gets `status: cancelled`, with a short note in its result notes saying why and when, so its content stays on record.
- A task whose `depends_on` lists any task that is not `done` starts as `blocked`.
- When a task becomes `done`, every task whose `depends_on` tasks are now all `done` moves from `blocked` to `open`, in the same commit that marks the task `done`.

## Git branches

Work that changes the game, its tools or its assets is done on its own branch, so unfinished work never sits uncommitted on `master`.

- **One branch per task,** named `task/<id>-<short-title>`, for example `task/T-013-placeholder-car-sprites`, made from the latest `master`.
- **One folder per task:** the Project Lead creates the branch as a git worktree in a sibling folder, `C:\solid-carbide-worktrees\<id>`, and copies the git-ignored `.env` (and `.secrets/`, if the task needs it) into it. Agents working in parallel each have their own folder, so they never switch branches under each other.
- **The agent works and commits only in its task's folder,** on its task's branch, in small commits with clear messages. It never commits to `master`, never merges, and never pushes.
- **While a task's branch is open, its task file is edited only on that branch.** The Project Lead reads the task's status there.
- **QA checks the task in the same folder.**
- **When the board marks the task done,** the Project Lead merges the branch into `master`, then removes the worktree and deletes the branch.
- **Documentation-only work** (for example the Project Lead's own document edits) is committed straight to `master`.

## Building in playable steps

The board's way of building the game (2026-10-10): always aim for the smallest playable version of the work, playtest it, then build on it. The Project Lead orders and splits tasks so each wave ends in something the board can play. The current steps toward the MVP:

1. **Bare loop:** the main menu, Start, the run on the MVP map with the timer running down, pause, back to the menu (Garage not wired yet).
2. **Tricks:** trick popups from the car, so the board can check and tune the tricks.
3. **Likes:** the likes bar and the level going up from drifting (no level-up screen yet).
4. **Combo and challenges:** the combo stacking on likes; challenges giving likes, with a popup from the car; the fitted challenges checked as drivable and fun.
5. **Minions,** then **the weapons,** then the kaiju, the garage, sound and art.

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

## Models

Every task says in its header which model the agent runs on: `model: sonnet` or `model: opus` (board, 2026-10-09). The Project Lead picks it per task and launches the agent with it:

- **sonnet:** clearly scoped work: art, sound, data files, simple screens, reports, and QA checks.
- **opus:** tricky work: code that ties several agents' work together, complex behaviour, porting from the Unity prototype, and any task that failed QA once. QA of a task the board is about to playtest also runs on opus.

## User-facing text and visuals

Every task file says in its header whether it adds or changes anything the player reads or sees:

- `user_facing_text: yes` when the task adds or changes any words the player sees in the game (menus, HUD, weapon names, descriptions, messages). The task then lists `docs/extended-narrative.md` in `files_to_read_first`, so the text fits the game's story and tone.
- `changes_visuals: yes` when the task adds or changes anything the player sees (art, sprites, effects, screens, the camera). The task then lists both `docs/visual-style.md` and `docs/extended-narrative.md` in `files_to_read_first`.

Otherwise each field is `no`. The Project Lead sets both fields when writing a task.

**Generated art is archived, never deleted.** Only clean, game-ready art goes under `game/art/`; every other generation goes to `art-archive/<task id>/` with its record (Visual style, Decisions).

**Art replaces placeholders.** When work has a visual and a functional side, the functional task builds it with a placeholder and does not wait for the art. The linked art task lists the functional task in `depends_on` and, once its art is made, swaps it in for the placeholder itself; its acceptance criteria include seeing the final art in the game.

**Player-facing text comes from the Narrative Theme Agent.** When a task has `user_facing_text: yes`, the Project Lead also writes a linked text task for the Narrative Theme Agent: what each piece of text is for, where it appears, any space limit, and the facts it must state. That agent writes the final text in its task's result notes. The main task lists the text task in `depends_on` and uses exactly that text: no placeholder text, and no wording of the building agent's own. If an agent finds its work needs text that its text task doesn't cover, it doesn't write any; it says so in its result notes and the Project Lead gets the text from the Narrative Theme Agent.


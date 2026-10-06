# Tasks

One file per task, named `T-001-short-title.md`, using `_TEMPLATE.md`. Tasks are the official record of all work on the game. The Project Lead writes them, agents work from them and write result notes, and QA/Integration writes pass or fail per criterion.

Every agent reads this file before starting any task. Every task file lists it first in `files_to_read_first`.

## Status rules

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

# Tasks

One file per task, named `T-001-short-title.md`, using `_TEMPLATE.md`. Tasks are the official record of all work on the game. The Project Lead writes them, agents work from them and write result notes, and QA/Integration writes pass or fail per criterion.

Every agent reads this file before starting any task. Every task file lists it first in `files_to_read_first`.

## Status rules

- A task whose `depends_on` lists any task that is not `done` starts as `blocked`.
- When a task becomes `done`, every task whose `depends_on` tasks are now all `done` moves from `blocked` to `open`, in the same commit that marks the task `done`.

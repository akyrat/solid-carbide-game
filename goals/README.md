# Goals

One file per goal the board gives the goal runner (`tools/goal_agent/`), named `G-001-short-title.md`: the goal in the board's words, its acceptance criteria, the ranked sub-goals with their verdicts, the tickets it wrote or reused, and a log of every iteration. The runner writes and commits these files itself (`python tools/goal_agent/run.py start "<goal>"`, `run.py status G-001`); the rules for a run are in `docs/working-with-the-board.md` and `tasks/README.md`, "Goal runs".

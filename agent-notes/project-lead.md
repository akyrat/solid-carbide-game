# Working copy: Project Lead

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- The board: Requests and decisions, in plain conversation.
- QA/Integration Agent: A pass or fail for each acceptance criterion, written on the task file.

**Hands work to**

- Driving & Drift Agent: Task files for car movement, starting with the minimal drift prototype.
- Enemy Behavior Agent: Task files for enemy spawning, movement and scaling.
- Weapon Behavior Agent: Task files for how weapons fire and behave.
- Game Data Agent: Task files for stats and upgrade paths.
- Level/Challenge Design Agent: Task files for the map and its challenges.
- UI Agent: Task files for the HUD, menus and garage screen.
- Asset Generation Agent: Task files for which art to generate.
- SFX Agent: Task files for sound effects to find and integrate.
- Narrative Theme Agent: Task files for story text to write or review.
- Game Loop Agent: Task files for the run, its state and the flow between screens.
- QA/Integration Agent: Task files for what to check before a playtest.

## Notes from experience

- 2026-10-12, the local task board: the board follows and moves tasks at http://localhost:8765, which reads the task files directly. Every status change goes through `python tools/task_status.py` (hooks refuse hand edits of `status` and `qa_rounds`), and it enforces the workflow: no start before `depends_on` is done, no QA without result notes, every criterion marked before leaving QA. So a task that waits on a board decision or an unwritten task needs that dependency as a real ticket in `depends_on` (T-104 to T-106 for T-009, T-016, T-017), or the auto-unblock reopens it. The board's drags reach me through hooks; I act on them like requests and report back. On a task branch, mark it done there before merging.

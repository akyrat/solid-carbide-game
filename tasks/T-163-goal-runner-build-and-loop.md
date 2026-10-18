---
id: T-163
title: Goal runner, part 2: building the tickets and the iteration loop
status: blocked
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-162]
documents_affected: [tasks/README.md, docs/working-with-the-board.md, course-material/goal-oriented-code-agent/README.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, CLAUDE.md, tasks/T-162-goal-runner-plan-and-gaps.md, tools/goal_agent/, tools/task_status.py, tools/test_task_status.py, tools/board_inbox.py, game/tools/pixellab_client.py, course-material/goal-oriented-code-agent/README.md]
files_expected_to_change: [tools/goal_agent/build.py, tools/goal_agent/loop.py, tools/goal_agent/run.py, tools/goal_agent/test_*.py, tools/goal_agent/fixtures/, tools/task_status.py, tools/test_task_status.py]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Part 2 of the goal runner (part 1 is T-162; the board's rules for a run are in `docs/working-with-the-board.md`, "Goal runs"; the plan is in `course-material/goal-oriented-code-agent/README.md`). This ticket builds **layer 3** (building the goal's tickets with the agents) and **layer 4** (the iteration loop and its stop rules), and `run.py`'s `resume`. Standard-library Python 3.9 only. All Claude calls go through T-162's `claude_call.py`.

### Layer 3: `build.py`

- **The goal's build.** The first build creates the branch `playtest/<goal id>` from `master` as a worktree `C:\solid-carbide-worktrees\<goal id>` (folder and branch paths come from one setting, so tests use temporary ones).
- **Picking the next ticket:** the goal's highest-ranked sub-goal that has a ticket ready to start (`open`, or `blocked` with every dependency met).
- **One ticket, in order:**
  1. Create its worktree and branch the usual way (`tasks/README.md`, "Git branches"), branched from `playtest/<goal id>` so it builds on the goal's earlier work; copy `.env` (and `.secrets/` if present).
  2. Move it to `in-progress` through `python tools/task_status.py` (always the main checkout's copy).
  3. Run the agent headless in the ticket's folder: `claude -p` with `--agent <the ticket's to>` (no `--agent` for `project-lead`) and `--model <the ticket's model>`, a short prompt (the ticket id and folder; the goal id; the art generations left under the cap; that it commits only in that folder, writes result notes and tests, and never works around a refusal), and a structured result (summary, art generations used, refusals met).
  4. Move it to `in-qa`; run the QA/Integration Agent headless the same way, always on `sonnet`, with a short prompt (the ticket, the folder, the criteria). QA marks every criterion on the ticket.
  5. Move it on through the status script. Passed: `needs-playtest` or `done`, then merge the ticket's branch into `playtest/<goal id>` in the goal's folder, with `if git merge --no-ff --no-commit <branch>; then ...` and reverting Godot's line-ending-only `.import` noise before committing. First fail: back to `in-progress` with QA's notes, the ticket's `model` line set to `opus` (tasks/README.md, "Models"), the agent again, then QA again. Second fail: `flagged-for-review`.
- **Art spend.** Count the PixelLab generations a ticket used from the new lines in `game/art/pixellab-generation-log.jsonl` on its branch, add them to the goal's `art_used`, and never start an `asset-generation` ticket when `art_used` has reached `art_cap`.
- **Board moves.** Each headless session registers as `Goal-<goal id>` with `python tools/board_inbox.py name <session id> Goal-<goal id> --take-over`, using a session id the runner chooses (`--session-id`), so it only hears its own tickets' moves.

### The dependency rule in `tools/task_status.py`

During a goal, a ticket's dependencies wait in `needs-playtest` until the board plays the goal's build, so today's rule (start only when every dependency is `done`) would stall the run. Change the status script so that a dependency also counts as met when it is `needs-playtest` **and** both tickets have the same non-empty `goal:`. A ticket outside the goal, or with a different goal, still needs `done`. Moving a ticket to `needs-playtest` unblocks the same goal's tickets that now wait on nothing, the way `done` does today. Add tests to `tools/test_task_status.py`; every existing test still passes.

### Layer 4: `loop.py`

- **After every ticket:** rescan the tickets and the code and run gap detection (T-162) again for the sub-goals not yet `covered`. A ticket's result may show something more is needed; new drafts go through the same rule checks. Write one entry per step in the goal file's `## Iteration log` (the iteration number, the ticket, its result, what the rescan found) and add one to `iteration`.
- **The goal check:** when no goal ticket is ready or in progress and every goal ticket has passed QA, run the QA/Integration Agent headless on `sonnet` in the goal's folder against the goal's own acceptance criteria, with a structured pass or fail per criterion written into the goal file. All pass: the goal becomes `ready-to-play`, and the runner prints how to play it (the goal's folder, `game/project.godot`, and the Builds tab of the task board). A fail: the failing criteria go back into gap detection as gaps.
- **The goal pauses** (status `paused`, the reason in `## Pauses`, and a printed message), and changes nothing more, when:
  - `iteration` reaches `max_iterations` (default 20);
  - the art cap is reached and an `asset-generation` ticket is next;
  - a ticket is `flagged-for-review` and other goal tickets depend on it (independent work carries on first);
  - the same failing goal criterion or the same gap comes back twice with no ticket passing in between;
  - any headless session reports a refusal (`permission_denials`), or any command the runner runs is refused;
  - two refused sets of ticket drafts (T-162).
- **`run.py`:** `start` now continues from `planned` straight into the loop (`--plan-only` stops at `planned`, as in T-162); `resume G-NNN` rebuilds the state from the goal file, the tickets and the worktrees, and carries on (a paused goal resumes only when its reason is cleared, or with `--force`); `status` also shows the iteration, art spent and any pause.

### Things to watch

- Nothing reaches `master` except the goal file and new tickets (as in T-162). The Project Lead merges `playtest/<goal id>` after the board's playtest.
- Tests never call Claude or PixelLab and never touch the real repo: a temporary git repo with worktrees, `FakeClaude`, and a fake status-script runner where needed. A whole fake run (plan, two tickets with a QA fail and a retry, the goal check passing) is one test.
- If a hook or the permission system refuses one of your own commands while you build this, stop and report it to the Project Lead (common rules, `CLAUDE.md`).

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, including the new goal runner tests and every existing `tools/test_task_status.py` test, with no Claude, PixelLab or network calls (QA: pass / fail)
- [ ] `tools/test_task_status.py` has tests that a `needs-playtest` dependency with the same `goal:` lets a ticket start, that one with a different or empty `goal:` does not, and that moving a ticket to `needs-playtest` unblocks the same goal's waiting tickets (QA: pass / fail)
- [ ] A test runs a whole fake goal in a temporary repo: planning, two tickets built in rank order, one failing QA once and passing on its retry with `model: opus`, both merged into `playtest/<goal id>`, the goal check passing, and the goal ending `ready-to-play` with one iteration log entry per step (QA: pass / fail)
- [ ] There is a test for each pause reason listed under layer 4, each leaving the goal `paused` with its reason in `## Pauses` and starting nothing further (QA: pass / fail)
- [ ] There is a test that the art cap blocks the next `asset-generation` ticket and that `art_used` counts the new lines in the PixelLab log (QA: pass / fail)
- [ ] There is a test that `resume` picks a stopped goal up from its files (a ticket left `in-progress`, a ticket `in-qa`) without repeating finished tickets (QA: pass / fail)
- [ ] `python tools/goal_agent/run.py --help` lists `start`, `resume` and `status`, and every new file starts with a docstring naming the layer it covers (QA: pass / fail)

## Updates

## Result notes

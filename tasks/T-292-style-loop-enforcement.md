---
id: T-292
title: "Enforce the style loop: no PixelLab call and no art or text ticket to QA without it"
status: in-progress
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-291]
documents_affected: [tasks/README.md, game/README.md]
files_to_read_first: [tasks/README.md, game/README.md, game/tools/pixellab_client.py, tools/task_status.py, tools/style_loop/run.py, tools/goal_agent/build.py]
files_expected_to_change: [game/tools/pixellab_client.py, game/tools/test_pixellab_client.py, tools/task_status.py, tools/test_task_status.py, tools/goal_agent/build.py, tools/goal_agent/test_build.py, tasks/README.md, game/README.md]
model: opus
qa_rounds: 0
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

Third of three tickets for the style loop (`tasks/README.md`, "The style loop"). The board's request: no asset or text can be made without going through the loop. Two gates, at the two places all the work already passes through:

1. **PixelLab:** every paid call goes through `game/tools/pixellab_client.py`. Its `generate` refuses to run unless it is inside a style loop run started by `tools/style_loop/run.py` (T-291). For example, the loop writes a run marker and passes its id, and the client checks the marker is live. `balance` keeps working. The refusal message names the loop command.
2. **Art and text tickets:** every status change goes through `tools/task_status.py`. It refuses to move a ticket with `epic: art` or `epic: narrative` to `in-qa` when its `## Style review` section has no rounds, with a message naming the loop.

The goal runner's prompt to headless agents (`tools/goal_agent/build.py`) still says "one round per task" for PixelLab. It changes to the loop rule.

## Acceptance criteria

- [ ] `python game/tools/pixellab_client.py generate ...` run directly, outside a loop, exits non-zero without calling PixelLab, and its message names `tools/style_loop/run.py`. Shown by a unit test with the HTTP call mocked (nothing is charged). (QA: pass / fail)
- [ ] Inside a style loop run (fake mode is enough), the same `generate` call is allowed through to the HTTP layer (mocked in the test). (QA: pass / fail)
- [ ] `python tools/task_status.py <id> in-qa` on an `epic: art` or `epic: narrative` ticket with an empty `## Style review` section is refused with a message naming the loop; with at least one round it is accepted; tickets of other epics are unaffected. Shown by unit tests. (QA: pass / fail)
- [ ] `tools/goal_agent/build.py` no longer tells agents "one round per task" and names the style loop instead; its tests pass. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)
- [ ] `tasks/README.md`, "The style loop", says how it is enforced, replacing "being built in T-290 to T-292", and `game/README.md`'s PixelLab client section says `generate` runs only inside the loop. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-25, Open → In progress

Started: enforce the style loop. PixelLab generates only inside a loop run, and art or text tickets can't go to QA without a Style review. Opus agent in C:\solid-carbide-worktrees\T-292.

## Result notes

**What changed**

- `game/tools/pixellab_client.py`: new `require_style_loop()` gate, called by `generate()` itself (so an import can't skip it) and by `main()` for `generate` before the token is read. It reads the marker path from `SOLID_CARBIDE_STYLE_LOOP_RUN`, and refuses (`NotInStyleLoop`, exit 1) when the variable is unset, the marker file is gone or unreadable, it names no run, or the run's process is no longer running (`pid_alive`: `OpenProcess`/`GetExitCodeProcess` on Windows, never `os.kill`, which would end the process there). The message names `tools/style_loop/run.py` and says nothing was sent. `balance` is untouched. Each generation log line now records `style_loop_run`.
- `tools/style_loop/loop.py`: `live_run(spec)` writes `.board/style-loop/<run id>.json` (`run`, `pid` = run.py's own process, `task`, `kind`, `started`; `.board/` is git-ignored; in `--fake` mode it is the sandbox's `.board/`), sets the env var to its absolute path and, when the run ends (also on a Pause or error), deletes the marker and puts the env var back. `run()` wraps the generate/evaluate/refine rounds in it (split out as `rounds_until_kept`); keeping, the final record and flagging come after. Across processes: `RealClaude` starts `claude -p` with `subprocess.Popen` and no `env=`, so the child inherits `os.environ`, and the agent's shell commands inherit it from Claude Code; the marker path is absolute, so the agent's cwd (the task's folder) doesn't matter.
- `tools/task_status.py`: `style_rounds(text)` counts `### Round N` headings in `## Style review`; `style_gate()` refuses `in-progress` → `in-qa` for `epic: art` / `epic: narrative` with none, naming `python tools/style_loop/run.py art|text --task T-NNN ...`. The result-notes rule is checked first. It applies to every mover (agent, board drag, goal runner). Other epics unaffected. No open art/narrative ticket on master is in progress or in QA, so nothing is stuck by it.
- `tools/goal_agent/build.py`: the "one round per task, no regenerations" line is replaced by `STYLE_LOOP_RULE` (make every asset and text through the loop; PixelLab only inside a run; art/narrative to QA only with a Style review), plus the art cap left (one loop run can use up to 4).
- `tools/goal_agent/fake_team.py`: the fake agent writes one Style review round on art/narrative tickets, as the loop would (`"_no_style_review": true` leaves it out), so the goal runner's tests still reach QA.
- Docs: `tasks/README.md` status rules bullet and a new "How it is enforced (T-292)" paragraph in "The style loop" (replacing "Its enforcement in QA is T-292"); `game/README.md` PixelLab section says `generate` runs only inside the loop, the exit code 1 case and `style_loop_run`.

**Tests** (nothing calls PixelLab or Claude; HTTP mocked)

- `game/tools/test_pixellab_client.py`: new `StyleLoopGateTests` (refused outside a loop / missing marker / ended run / marker without run, each with no HTTP call and no log line; let through to the HTTP layer inside a live marker; library `generate()` gated; `balance` outside a loop; `pid_alive`). `GenerateTests` now run inside a live marker.
- `tools/style_loop/test_loop.py`: end to end through `run.main(... --fake ...)`: the fake Asset Generation agent calls `pixellab_client.main(["generate", ...])` inside the run and reaches the mocked HTTP layer; the same call after the run is refused; the marker sat in `.board/style-loop/` and is deleted; the env var is restored. Plus a `live_run` marker test.
- `tools/test_task_status.py`: art and narrative refused with no section or only the template line, accepted with one round; four other epics unaffected; result notes asked first; `style_rounds` counts only the Style review.
- `tools/goal_agent/test_build.py`: the agent prompt names the loop and no longer says "one round per". `tools/goal_agent/test_loop.py`: an art ticket without a Style review pauses the goal on the refused in-qa move.
- Results: tools 485 tests OK; game/tools 417 OK (1 skipped); Godot 1419/1419 passing.

**Open**

- The env var reaching the agent's shell through real `claude -p` → Bash can't be shown without a real call; it relies on plain environment inheritance. The first real art loop run will show it: if `generate` is refused inside a run, the refusal message says which check failed.
- `docs/working-with-the-board.md` ("Art and money", "Goal runs") still says "one round per task"; it is the board's document, so not changed here.
- `game/tools/generate_car_inbetweens.py` (T-102) calls `pixellab_client.py generate` itself; outside a loop run it is now refused, as intended.

Screenshots: none, tooling.

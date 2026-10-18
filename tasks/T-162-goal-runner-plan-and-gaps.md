---
id: T-162
title: Goal runner, part 1: goal file, priority scoring and gap detection
status: open
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, docs/working-with-the-board.md, course-material/goal-oriented-code-agent/README.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, CLAUDE.md, tasks/_TEMPLATE.md, tools/task_status.py, tools/taskboard_sync.py, tools/ticket_impact.py, tools/guard_ledger.py, .claude/hooks/board_gate.py, docs/short-gdd/short-gdd.md, course-material/goal-oriented-code-agent/README.md]
files_expected_to_change: [tools/goal_agent/__init__.py, tools/goal_agent/claude_call.py, tools/goal_agent/goal_file.py, tools/goal_agent/prioritize.py, tools/goal_agent/gaps.py, tools/goal_agent/tickets.py, tools/goal_agent/run.py, tools/goal_agent/test_*.py, tools/goal_agent/fixtures/, goals/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

The board asked for a **goal runner** (board, 2026-10-18; also a course assignment, "goal-oriented code agent"). The board gives it a goal ("the trick system with its final art", or "the whole short GDD"); it turns the goal into prioritised sub-goals, finds what is missing against the existing tickets and code, writes the missing tickets, builds them with the agents, and repeats until the goal's own criteria pass. The board's rules for a run are in `docs/working-with-the-board.md`, "Goal runs", and the ticket side in `tasks/README.md`, "Goal runs". The plan, layer by layer, is in `course-material/goal-oriented-code-agent/README.md`.

This ticket builds **layers 1 and 2** (priority scoring and gap detection), the goal file, and the command line. T-163 builds layers 3 and 4 (building and the loop) on top. Standard-library Python 3.9 only, like the rest of `tools/`. It is studio tooling: nothing in `game/` changes.

### The pieces

- **`claude_call.py`:** the only place that calls Claude. One function that runs `claude -p <prompt> --output-format json --json-schema <schema>` (plus `--model`, `--agent`, `--session-id` and a working folder when given), parses the structured result, and also returns the result's `permission_denials` so the caller can see refusals. A `FakeClaude` with the same interface answers from a JSON fixture file (canned answers by step name, in order), so tests and `--fake` runs never call Claude.
- **`goal_file.py`:** reads and writes `goals/G-NNN-short-title.md`. A parseable `---` header (`id`, `title`, `status`, `art_cap`, `art_used`, `iteration`, `max_iterations`, `created`, `lead`), then sections: `## Goal` (the board's words, unchanged), `## Goal acceptance criteria` (the stop condition, each checkable by the QA/Integration Agent), `## Sub-goals` (a table: rank, id S1.., title, score, why, verdict, tickets), `## Scoring` (the rule used, in words), `## Tickets`, `## Iteration log` (one dated entry per step), `## Pauses`. Statuses: `planning`, `planned`, `building`, `paused`, `ready-to-play`, `done`, `cancelled`. Reading then writing a file leaves it byte-identical. Ids are the next free `G-NNN` in `goals/`. Add `goals/README.md` explaining the folder in two or three lines.
- **`prioritize.py` (layer 1, priority scoring):** asks Claude, with the goal text and the paths of the short GDD (scope) and the game area docs (details; they are the source of truth), for: the goal's acceptance criteria, and sub-goals, each with a title, why it serves the goal, a value estimate 1 to 5, its acceptance criteria, and which other sub-goals it needs first. The ranking is done by code, not Claude: first by how many other sub-goals wait on it (directly or further down the chain, the same idea as `tools/ticket_impact.py`), then by value, then by Claude's order. A dependency cycle is refused. The rule is written into the goal file's `## Scoring` section. The prompt tells Claude that ideas come only from the board: sub-goals only build what the goal and the docs say, and anything the docs leave open becomes an open question in the goal file, not an invented answer.
- **`gaps.py` (layer 2, gap detection):** scans by code every ticket header (reuse `taskboard_sync`'s parsing and its view of open task branches), and a short index of the code: the files under `game/` (skipping `addons/`, `.godot/`, `art/`, `audio/`) and the headings of `game/README.md`. It gives Claude the sub-goals and that compact view, and gets back per sub-goal a verdict: `covered` (done tickets and code exist; name them), `in-flight` (open tickets already cover it; name them, they are reused) or `missing` (with ticket drafts).
- **`tickets.py`:** turns drafts into task files from `tasks/_TEMPLATE.md`, with `goal: G-NNN` and `lead: Goal-G-NNN` claimed through the status script (`python tools/task_status.py T-NNN --lead Goal-G-NNN`), never by writing the `lead`, `status` or `qa_rounds` lines differently from what the template and the status script allow. Ticket ids are the next free number after every id in `tasks/`, on every `task/*` branch, and in `git log master` subjects. It refuses a set of drafts, with reasons, when it breaks the rules in `CLAUDE.md` and `tasks/README.md`:
  - `to` is not an agent in `.claude/agents/` or `project-lead`;
  - `model` is not `sonnet`/`opus`, or `epic`/`milestone` is not in the tables in `tasks/README.md`;
  - `changes_visuals: yes` without `docs/visual-style.md` and `docs/extended-narrative.md` in `files_to_read_first`; `user_facing_text: yes` without `docs/extended-narrative.md` there, or without depending on a `narrative-theme` ticket;
  - an `asset-generation` draft that does not depend on the functional ticket it swaps art into, or has no `The board's review:` line;
  - a draft that changes what the player sees, reads or hears with no `The board's review:` line;
  - empty acceptance criteria, or `depends_on` naming something that is neither another draft nor an existing ticket.
  On a refused set, `gaps.py` asks Claude once more with the reasons; refused again, the goal is `paused` with the reasons in `## Pauses`.
  New tickets start as `open`, or `blocked` when they depend on an unfinished ticket.
- **`run.py`:** `python tools/goal_agent/run.py start "<goal>" [--art-cap N] [--max-iterations N] [--fake FIXTURE]` runs layers 1 and 2, writes the goal file and the tickets, and leaves the goal `planned` (T-163 continues from there). `status G-NNN` prints the goal's status, sub-goals with verdicts, and its tickets with their current status. `--help` lists the commands.
- **Commits:** the runner commits the goal file and its new tickets on `master` itself, staging only those files, after checking that no merge is in progress (`git rev-parse -q --verify MERGE_HEAD` prints nothing), with a message naming the goal.

### Things to watch

- The status guard (`tools/guard_ledger.py`, `.claude/hooks/board_gate.py`) checks ticket headers at `git commit`. Find out whether a ticket file the script writes passes it. If it does not, **stop and report to the Project Lead** what is refused and why; do not change the guard and do not route around it (common rules, `CLAUDE.md`).
- Tests never call Claude, never touch the real `tasks/` or `goals/`, and never commit to the real repo: use a temporary git repo fixture and `FakeClaude`.
- Keep it small and readable: the board's tutor reads this code to check each layer. A short docstring at the top of each file says which layer it is.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, including the new `tools/goal_agent/test_*.py`, and the tests make no Claude or network calls (QA: pass / fail)
- [ ] There is a test for each: ranking puts a sub-goal others wait on before a higher-value one, and breaks ties by value then order; a dependency cycle is refused (QA: pass / fail)
- [ ] There is a test for each refusal rule listed under `tickets.py`, and one showing a refused set is retried once and then pauses the goal with the reasons (QA: pass / fail)
- [ ] There is a test that the next ticket id counts ids in `tasks/`, on `task/*` branches and in `master`'s log, and that an `in-flight` verdict reuses the named ticket instead of writing a new one (QA: pass / fail)
- [ ] Reading and writing a goal file leaves it byte-identical (a test), and a written goal file has every header field and section listed above (QA: pass / fail)
- [ ] `python tools/goal_agent/run.py start "<goal>" --fake tools/goal_agent/fixtures/<fixture>.json`, run by QA inside a temporary copy of the repo (not the real checkout), writes a goal file with status `planned`, ranked sub-goals and verdicts, and task files that follow `tasks/_TEMPLATE.md` with `goal:` set and `lead: Goal-G-NNN`; `run.py status G-NNN` prints them (QA: pass / fail)
- [ ] Every file in `tools/goal_agent/` starts with a docstring naming the layer or role it covers, and `goals/README.md` exists (QA: pass / fail)

## Updates

## Result notes

---
id: T-203
title: Task board: what the agents are doing now, live
status: blocked
from: project-lead
to: project-lead
lead: Coursework
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-202]
documents_affected: [docs/README.md, tasks/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/goal_agent/claude_call.py, tools/goal_agent/build.py, tools/goal_agent/loop.py, tools/test_taskboard_server.py, tools/goal_agent/test_build.py]
files_expected_to_change: [tools/goal_agent/claude_call.py, tools/goal_agent/build.py, tools/goal_agent/test_*.py, tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_server.py, tools/test_taskboard_sync.py, docs/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

The board wants to see live what the agents are doing, at a level it can read at a glance, and their progress on tickets and goals (board, 2026-10-19). Today a card moves lane every 10 to 30 minutes with nothing in between.

1. **The runner records what its agents do.** The goal runner's headless sessions (agent, QA, goal check; `RealClaude.ask`) run with `--output-format stream-json` (and `--verbose` if the CLI needs it for streaming), still returning the same structured answer as today, and append each event, as it arrives, to an activity log: `.board/activity/<ticket id or goal id>.jsonl` in the main checkout (git-ignored, like the rest of `.board/`), one line per event with a time, the step (agent, qa, goal check), and the event. Nothing else about the runner's behaviour changes.
2. **Plain phrases, no AI.** The board turns the latest events into one short phrase, by rules, not a model: which tool on what, in words. Examples: "Reading `docs/level-design.md`", "Editing `ground_height.gd`", "Running the game's tests", "Taking screenshots", "Calling PixelLab", "Committing", "Thinking"; QA: "QA checking"; with how long it has been doing it. Unknown tools get a generic phrase.
3. **Free signals for every ticket.** For any ticket in progress or in QA (runner or not): time in its lane, the number of commits on its task branch, and the time of its last activity (newest of: its activity log, its branch's last commit, its task file's change).
4. **A "Now" panel.** In-progress and in-QA cards show one line: the phrase and how long ago ("Running the game's tests · 2 min"), or, without an activity log, the free signals ("3 commits · last activity 1 min ago"). The ticket's detail view shows its last 20 phrases as a short timeline. Goal cards (T-202's strip) show the ticket being worked on and its phrase, with "ticket N of M, iteration K". A card with no activity for 10 minutes is marked quiet. It updates with the board's normal refresh.
5. **Bounded.** Activity logs are read from the end (only the last events), and capped in size; a run's log can be deleted at any time without breaking anything.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] Tests (subprocess mocked) show `RealClaude.ask` streams with `--output-format stream-json`, writes each event to `.board/activity/<id>.jsonl` as it arrives, and still returns the same structured answer and refusals as before (QA: pass / fail)
- [ ] Tests show the event-to-phrase rules for reading, editing, running tests, screenshots, PixelLab, committing and an unknown tool, and that the board's ticket data carries the latest phrase, its age, the time in lane, the branch's commit count and the last activity time (QA: pass / fail)
- [ ] The page shows the Now line on in-progress and in-QA cards, the last-20 timeline in the detail view, the current ticket and phrase on goal cards, and the quiet mark; checked live by QA on a second board server (not port 8765) with a sample activity log, or by reading the page code where a browser isn't available (QA: pass / fail)
- [ ] `docs/README.md` ("The task board") and `tasks/README.md` ("Goal runs") describe the activity logs and the Now panel (QA: pass / fail)

## Updates

## Result notes

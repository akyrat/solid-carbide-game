---
id: T-203
title: Task board: what the agents are doing now, live
status: in-progress
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
5. **A resumed goal says so.** `run.py resume` sets the goal's status to `building` and saves the goal file when it carries on, so the board (T-202's Goals strip) doesn't show a running goal as `paused` until its next ticket finishes. A test covers it.
6. **Bounded.** Activity logs are read from the end (only the last events), and capped in size; a run's log can be deleted at any time without breaking anything.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no Claude or network calls (QA: pass / fail)
- [ ] Tests (subprocess mocked) show `RealClaude.ask` streams with `--output-format stream-json`, writes each event to `.board/activity/<id>.jsonl` as it arrives, and still returns the same structured answer and refusals as before (QA: pass / fail)
- [ ] Tests show the event-to-phrase rules for reading, editing, running tests, screenshots, PixelLab, committing and an unknown tool, and that the board's ticket data carries the latest phrase, its age, the time in lane, the branch's commit count and the last activity time (QA: pass / fail)
- [ ] The page shows the Now line on in-progress and in-QA cards, the last-20 timeline in the detail view, the current ticket and phrase on goal cards, and the quiet mark; checked live by QA on a second board server (not port 8765) with a sample activity log, or by reading the page code where a browser isn't available (QA: pass / fail)
- [ ] `docs/README.md` ("The task board") and `tasks/README.md` ("Goal runs") describe the activity logs and the Now panel (QA: pass / fail)

## Updates

### 2026-10-19, Open → In progress

Started: the runner records what its agents do, and the board shows it as a plain-language Now line on cards, a timeline per ticket, and the current ticket on goal cards, plus free signals for every ticket.

## Result notes

**What changed**

- `tools/goal_agent/claude_call.py`: `RealClaude.ask` runs `claude -p --output-format stream-json --verbose` (the CLI needs `--verbose` to stream with `--print`) through `subprocess.Popen`, prompt on standard input as before, reads the events one line at a time and, when the caller passes `activity=<ticket or goal id>`, appends each to `.board/activity/<id>.jsonl` (default: the checkout the runner runs from, i.e. the main checkout) as it arrives. The answer comes from the final `result` event through the same `parse()`, with its `permission_denials`; the same pauses as before (could not be run, no JSON, error, not structured JSON, and the timeout, now a timer that kills the process).
- `tools/goal_agent/build.py`, `loop.py`: `ask_headless(..., activity=)`; the agent and QA log under the ticket's id, the goal check under the goal's id. `loop.resume` sets `building` and saves the goal file at once, before the loop carries on.
- `tools/taskboard_sync.py`: the log format and rules: `append_activity` (events cut down: strings over 400 chars shortened, tool results reduced to their type; a log past 2 MB keeps its last 500 KB; never raises; only `T-NNN`/`G-NNN` ids), `read_activity` (reads only the last 256 KB, skips a cut line and bad lines), `event_phrase` / `tool_phrase` / `command_phrase` / `step_phrase` (rule-based phrases, no AI), `activity_summary` (latest phrase, when it began, last event time, last 20 phrases with runs of the same phrase merged).
- `tools/taskboard/server.py`: each in-progress or in-QA ticket in `/api/tickets` gets `now` (phrase, `phrase_since`, `phrase_age_s`, step, timeline, `in_lane_since`/`in_lane_s` from the moves log's end, `commits` and `last_commit_at` from `git log HEAD --not --exclude=<branch> --branches` in the ticket's folder, `file_changed_at`, `last_activity_at`/`last_activity_s` = newest of log, last commit and task file, `quiet` after 600 s); other tickets `now: null`. Each building goal in `/api/goals` gets `now` (ticket being worked on = its active ticket with the newest activity, `ticket_index` of `tickets_total`, `iteration`, phrase; the goal check's phrase when the goal's own log is newer). The version changes on new activity at most once per 10 s, and at once on a new commit in a task folder (its worktree's HEAD log). `BOARD_MAIN_STATE` points the server at another folder standing in for the main checkout's `.board/`.
- `tools/taskboard/taskboard.html`: the Now line on in-progress and in-QA cards (phrase · duration, or "N commits · last activity X ago"; orange dot and a "Quiet" chip after 10 minutes), a "Now" box at the top of the ticket detail (phrase, time in lane, commits, last activity, last 20 phrases newest first with times), and the goal card line "T-196 · ticket 4 of 8, iteration 2" plus its phrase. Ages are worked out against the server's clock and redrawn every 15 s between refreshes.
- Docs: `docs/README.md` ("The task board", new "What the agents are doing now" item, and `.board/` line) and `tasks/README.md` ("Goal runs", two new items).

**Tests per criterion**

1. Full suite: see below.
2. Streaming (`tools/goal_agent/test_claude_call.py`, `subprocess.Popen` replaced by a fake process): `test_the_command_streams_with_stream_json`, `test_each_event_is_written_as_it_arrives` (the log is checked just before each event arrives: 0, 1, 2, 3 lines), `test_the_same_structured_answer_and_refusals_as_before`, `test_errors_pause_as_before`, `test_without_an_id_nothing_is_logged`, `test_a_deleted_log_is_started_again`, `test_the_default_log_folder_is_the_checkouts_board_folder`, `Callers.test_the_headless_sessions_name_their_ticket_or_goal`; `test_build.RealCommand.test_the_headless_claude_command` (updated to Popen) and `test_build.HeadlessRuns.test_each_session_names_the_activity_log_it_writes_to`. Resume: `test_loop.Resume.test_a_resumed_goal_is_saved_as_building_before_its_next_ticket`.
3. Phrases (`tools/test_taskboard_sync.py`, `PhraseTests`): `test_reading_and_editing_name_the_file`, `test_running_tests`, `test_screenshots_pixellab_and_committing`, `test_an_unknown_tool_gets_a_generic_phrase`, `test_thinking_starting_finishing_and_events_without_a_phrase`, `test_qa_and_the_goal_check_say_so`; logs (`ActivityLogTests`): `test_append_and_read_back_with_a_summary`, `test_the_timeline_keeps_the_last_twenty`, `test_reading_only_the_end`, `test_bad_lines_and_a_missing_or_deleted_log`, `test_only_ticket_and_goal_ids_name_a_log`, `test_a_log_is_capped_in_size`. Ticket data (`tools/test_taskboard_server.py`, `ActivityTests`): `test_a_runner_ticket_carries_its_phrase_age_lane_time_commits_and_last_activity`, `test_without_a_log_the_free_signals_and_the_quiet_mark`, `test_a_ticket_quiet_for_ten_minutes`, `test_a_building_goal_shows_the_ticket_being_worked_on`, `test_the_goal_check_shows_on_the_goal_card`, `test_a_goal_not_building_has_no_now`, `test_a_deleted_log_breaks_nothing`, `test_the_version_follows_new_activity`, `test_the_main_state_folder_can_be_pointed_elsewhere`; `BranchSignalTests.test_commits_only_on_the_tasks_branch` (real temporary git repo).
4. Page: `ActivityPageTests.test_page_parts`, and checked live (below).
5. Docs: `docs/README.md` "The task board" and `tasks/README.md` "Goal runs".

**Checked live:** yes. A second server from this folder on port 8791 (`BOARD_PORT=8791`, `BOARD_MAIN_STATE` = a sample folder in the session's scratchpad with `activity/T-196.jsonl` and a `moves.log`), never port 8765 and nothing in the main checkout's `.board/`. `/api/tickets` gave T-196 "Running the game's tests" with its real 2 commits on its branch, and T-203 (no log) "0 commits", quiet; `/api/goals` gave G-004 "T-196, ticket 4 of 8, iteration 2". Headless Edge screenshot of the page: `art-archive/T-203/screenshots/board-now-line.png` (Now lines on both in-progress cards, the Quiet chip, G-004's goal card line). The detail view's Now box was checked by reading the page code (no click in a headless screenshot). The server was stopped afterwards (`--stop`). `/api/tickets` took about 0.4 s on the real repo.

**Test count:** `python -m unittest discover -s tools -p "test_*.py"`: 399 tests, OK (324 s).

**Something to know (my mistake, now fixed):** the first full run had 4 errors in `tools/goal_agent/test_prioritize.py` (`Claude` class): those four older tests mocked `subprocess.run`, which `RealClaude` no longer uses, so in that one run they started the real `claude` CLI four times (prompt "hello" or 50,000 x's, step plan or gaps, no tools to do anything with, no activity id). Each came back at once with `API Error: 400 ... input_schema.type: Field required` (or failed to start, for the one with cwd "here"), so nothing was done and nothing written; it may have counted as a few tiny API requests. I changed those tests to mock `subprocess.Popen` with the same fake streaming process; no test calls Claude now, and the second full run passed.

**Screenshots:** `art-archive/T-203/screenshots/board-now-line.png`.

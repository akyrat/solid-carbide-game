---
id: T-344
title: Token spend: one script merges a batch of tickets and prints one line each
status: in-qa
from: project-lead
to: project-lead
lead: Tokens
epic: token-spend
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, tools/task_status.py, tools/update_short_gdd_fingerprint.py]
files_expected_to_change: [tools/merge_batch.py, tools/test_merge_batch.py, docs/working-with-the-board.md]
model: sonnet
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

Merging by hand put about 640k characters of git output into one Project Lead session (about 11% of its weighted cost). The board wants scripts in place of agents wherever possible (board, 2026-10-28). Write `tools/merge_batch.py T-NNN [T-NNN ...]` that does what `docs/working-with-the-board.md`, "Merging (Project Lead)" lists, for each ticket in turn: check no merge is in progress (`MERGE_HEAD`), mark the task done on its branch through `task_status.py` (with the board's note when given, `--note`), merge with `--no-ff --no-commit` and check it happened, revert Godot's line-ending-only `.import` noise, regenerate the long GDD and the short GDD's fingerprint, run all three test sets, add the timeline entry (from a short text given per ticket), commit only its own files, then remove the worktree and branch. It prints one line per ticket (merged, or stopped and why) and keeps full logs in a file it names. On a conflict, a red test or a worktree Godot holds open, it stops that ticket cleanly, leaves the state for the Project Lead to hand to an agent, and goes on to the next only if the stop left `master` clean.

Then update "Merging (Project Lead)" to say the script is the way to merge.

Part of the token-spend epic (board, 2026-10-28; `tasks/README.md`, "Epics and milestones"). The evidence behind it is the Tokens session's recon of 2026-10-28 (summarised in `docs/timeline.md`, "2026-10-28: The token-spend epic"). Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line. If an edit to `.claude/` is refused by the permission system or a safety check, stop and say so; don't work around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests on a throwaway repo (as `tools/goal_agent/temp_repo.py` does) show a clean batch of two tickets merged, each marked done, timeline entries added, worktrees and branches removed, and one output line per ticket. (QA: pass / fail)
- [ ] Tests show a conflicting ticket stopped with `master` left clean and no merge in progress, and a red test stopping its ticket before the commit. (QA: pass / fail)
- [ ] The script never commits while another merge is in progress, and stages only the files its merge changed (a test checks both). (QA: pass / fail)
- [ ] "Merging (Project Lead)" in `docs/working-with-the-board.md` points to the script. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started in parallel: the batch-merge script.

### 2026-10-27, In QA

Built: tools/merge_batch.py with 7 tests. One fix asked before QA: a stopped ticket must not stay marked done on its branch.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built `tools/merge_batch.py`, with `tools/test_merge_batch.py` (7 tests, on throwaway repos made by `tools/goal_agent/temp_repo.py`). Nothing to picture (a script and a doc line).

How to call it, from the main checkout on master: `python tools/merge_batch.py T-101 T-102 --note T-101="review note" --title T-101="Timeline title" --entry T-101="Decision or change" [--docs T-101="a.md, b.md"] [--log FILE] [--root DIR] [--test-cmd "cmd" ...] [--no-tests]`. Defaults: title = the ticket's title, entry = "merged T-NNN (title).", docs = the docs/ files the merge changed, tests = the three real sets, log = `.board/merge_batch-<time>.log` (the last printed line names it). One line per ticket: `T-101: merged` or `T-101: stopped: <why>`. Exit 0 only if all merged.

Per ticket: refuse if MERGE_HEAD exists, master has staged changes, or the long GDD, short GDD README or timeline have uncommitted edits; revert line-ending-only .import noise; `task_status.py <id> done [--note]` (committed on the branch); `merge --no-ff --no-commit` and check; regenerate the long GDD and fingerprint; run the tests; append the timeline entry; `git add` only the merge's staged result plus the long GDD, short GDD README, timeline and any task files task_status touched; commit; `worktree remove` (no --force) and `branch -d`. Any stop (conflict, red test, failed regeneration, error) runs `merge --abort` and restores the files the script wrote, so master is as before. The batch goes on only if no merge is in progress and the index is empty after the stop.

Tests (all pass): clean batch of two (done, timeline, worktrees and branches gone, one line each, log); a conflict stops with master clean and the next ticket then merges; a red test stops before the commit, HEAD unchanged, worktree and branch kept; a foreign merge in progress is left untouched, nothing committed, batch stops; an unrelated dirty tracked file is never staged or committed; .import line-ending noise is reverted; a refused `done` stops the ticket.

Counts: `python -m unittest discover -s tools -p "test_*.py"` 508 tests OK (including the 7 new); `python -m unittest discover -s game/tools -p "test_*.py"` 620 tests OK (1 skipped); `bash game/tools/run_tests.sh` TESTS PASSED.

Things to know: (1) the `done` mark is committed on the ticket's branch before the merge, but on any stop before the merge commit (conflict, red test, error) the script removes that one commit (`git reset --keep` to the tip it had before, only if its done commit is still the tip), so the ticket is back at its earlier status and the board never shows an unmerged ticket as done (change requested by the Project Lead; the conflict and red-test tests check branch tip and status). A worktree Godot holds open stops only after the merge is committed, so that ticket stays done. (2) A worktree Godot holds open: the merge stays committed, the line says so, and the branch is kept. (3) Not run against the real repo, as asked; the script's own tests use stand-in test commands, so the three real default commands are not exercised by them. (4) Docs: "Merging (Project Lead)" in `docs/working-with-the-board.md` now starts with the script as the way to merge.

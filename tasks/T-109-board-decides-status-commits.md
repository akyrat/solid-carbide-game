---
id: T-109
title: Board decides: should task_status.py commit each status change itself?
status: done
from: project-lead
to: board
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md, docs/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/task_status.py]
files_expected_to_change: []
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**A decision for the board. Nothing gets built until the board decides.**

Today `tools/task_status.py` only changes the task file. On an open task branch, the change goes into the agent's next commit along with its work. On `master` (a task with no branch, for example one the board drags from To do), it stays uncommitted until the Project Lead's next commit.

**Option A: the script commits every change itself** (one small commit per move, on the task's branch or on `master`).
- For: every move is in git history straight away, with its note; nothing sits uncommitted; a status change can't be lost when a folder is cleaned up.
- Against: many tiny commits. A commit on an agent's branch while it is working can sweep in the agent's half-done staged files, or land between its own commits. Committing on `master` while another Project Lead session is merging can collide.

**Option B: keep it as it is** (the change rides along with the next commit).
- For: simple, no surprise commits; an agent's status change and its work land together.
- Against: on `master`, a board drag stays uncommitted until someone commits; the board sees it on the board (the server reads the files), but git doesn't have it yet.

**The Project Lead's recommendation: a middle way.** Commit automatically only on `master`, where nothing else would commit the change, and commit only the task file (never other staged files). On a task branch, leave it to the agent's next commit, as now. This closes the gap for the board's drags without interfering with agents' work.

## Acceptance criteria

- [x] The board's choice is written in `tasks/README.md`, "Changing a task's status", and in this ticket's result notes (QA: pass) Checked by the Project Lead; docs only.
- [x] If the choice needs code, a separate task is written for it (QA: pass) Option B needs no code.

## Result notes

The board chose option B (2026-10-14): keep it as it is. `task_status.py` changes only the task file and never commits; the change goes into the next commit on its branch, or the Project Lead's next commit on `master`. Written in `tasks/README.md`, "Changing a task's status". No code needed, so no follow-up task.

---
id: T-108
title: Remove the leftover T-103 worktree folder
status: open
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [docs/working-with-the-board.md]
files_expected_to_change: [C:/solid-carbide-worktrees/T-103 (removed)]
qa_rounds: 0
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

T-103 was merged on 2026-10-12, but its worktree folder `C:\solid-carbide-worktrees\T-103` couldn't be deleted because Godot had it open from the board's playtest. Git no longer lists it as a worktree and its branch is deleted; the folder is a leftover copy with nothing needed in it.

Once the board has closed Godot: remove the folder (and its git worktree entry, if one is still listed, with `git worktree prune`).

## Acceptance criteria

- [ ] `git worktree list` shows no T-103 (QA: pass / fail)
- [ ] The folder `C:\solid-carbide-worktrees\T-103` is gone (QA: pass / fail)

## Result notes

Written when the work is done.

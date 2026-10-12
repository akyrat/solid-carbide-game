---
id: T-108
title: Remove the leftover T-103 worktree folder
status: done
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

T-103 was merged on 2026-10-12, but its worktree folder `C:\solid-carbide-worktrees\T-103` couldn't be deleted because Godot had it open from the board's playtest. Git no longer lists it as a worktree and its branch is deleted; the folder is a leftover copy with nothing needed in it.

Once the board has closed Godot: remove the folder (and its git worktree entry, if one is still listed, with `git worktree prune`).

## Acceptance criteria

- [ ] `git worktree list` shows no T-103 (QA: pass)
- [ ] The folder `C:\solid-carbide-worktrees\T-103` is gone (QA: pass)

## Result notes

Done by the Project Lead (2026-10-13), on the board's go ("remove the leftover folder").

- Before removing it, the folder (3.2 MB) was compared with master: its tracked files were older copies of files in master (README, tasks), and the only files not in master were 12 git-ignored screenshots from T-103's work and QA (`screenshots/t103_*.png`, `screenshots/qa/qa_*.png`). Those were copied into master's own git-ignored `screenshots/` folder (same names, nothing overwritten), so nothing is lost.
- Removed `C:\solid-carbide-worktrees\T-103` and ran `git worktree prune`; `git worktree list` shows only the main folder.

- QA (2026-10-13): both criteria pass; worktree list shows only master, the T-103 folder is gone, and all 12 screenshots are present (5 t103_*.png in screenshots, 7 qa_*.png in screenshots/qa).

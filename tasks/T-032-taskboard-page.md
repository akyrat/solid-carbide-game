---
id: T-032
title: Task board page with drag-and-drop lanes and a game-areas view
status: done
from: project-lead
to: project-lead
epic: tooling
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md, tasks/README.md]
files_to_read_first: [tasks/README.md, docs/README.md]
files_expected_to_change: [tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_sync.py, docs/README.md, tasks/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board asked for an HTML task board (2026-10-09), built by the Project Lead. It is one of the board's visualisation tools (T-031).

1. **Board view:** four lanes: To do, In progress, QA and Done. The board drags compact ticket cards between them, or uses "Move to" in a card's detail.
2. **Game areas view:** one bubble per game area doc, plus Sound and Tooling. Each bubble fills with the share of its tickets that are done. Clicking a bubble opens it with its tickets floating inside. An overall MVP percentage leaves Tooling out and says plainly that it only counts the tickets that exist.
3. **The task files stay the source of truth.**
   - The page is a published artifact, `https://claude.ai/artifact/3MeqfoLeaSWXxWbCb5A7op`. Its source is `tools/taskboard/taskboard.html`. It reads its tickets from the artifact's own database.
   - The Project Lead fills that database from the task files with `python tools/taskboard_sync.py export`.
   - A drag only changes the database. The card shows "Moved" until the Project Lead applies the move to the task file with `python tools/taskboard_sync.py apply` and syncs again.

How lanes map to statuses:
- **To do:** open, blocked
- **In progress:** in-progress
- **QA:** in-qa, needs-playtest, flagged-for-review
- **Done:** done

Dragging into a lane sets that lane's first status. Dragging back into the lane the file already says restores the file's own status.

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, including `test_taskboard_sync.py` (export reads every real task file; apply changes only the header's status line and keeps line endings) (QA: pass / fail)
- [ ] `python tools/taskboard_sync.py export OUT` writes one JSON per task file, with id, title, status, file_status, to, epic, milestone, depends_on and file (QA: pass / fail)
- [ ] `docs/README.md` lists the task board, its link, and how syncing works; `tasks/README.md` points to it (QA: pass / fail)
- [x] The board has used the page and is happy with it (board review, 2026-10-10)

## Result notes

Built by the Project Lead on 2026-10-09 and extended the same day (models, cancelled tickets, "Your review" with files and result notes, reading open tasks from their branch folders). The tool tests pass (`tools/test_taskboard_sync.py`). This task was not sent to QA; the board approved it after using the page.

### Board review

The board, 2026-10-10: happy with the task board as it is. Done.

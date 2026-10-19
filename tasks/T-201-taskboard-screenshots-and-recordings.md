---
id: T-201
title: Task board: screenshots and recordings shown on the ticket
status: open
from: project-lead
to: project-lead
lead:
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/README.md, tasks/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_server.py]
files_expected_to_change: [tools/taskboard/server.py, tools/taskboard/taskboard.html, tools/taskboard_sync.py, tools/test_taskboard_server.py]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

The board wants every screenshot and recording a ticket produces attached to the ticket on the task board, so it can see them there (board, 2026-10-19). Today a ticket's detail view lists its `Board review files:` as paths only.

1. **Which files.** A ticket's media are the image and video files (`.png`, `.jpg`, `.gif`, `.webp`, `.mp4`, `.webm`) in `art-archive/<ticket id>/screenshots/` (and its subfolders) and any media file named on its `Board review files:` line. They are looked up where the ticket lives: in its task folder (worktree) while its branch is open, otherwise in the main checkout, the same way the board already finds a ticket's file.
2. **Serving them.** A new read-only endpoint serves one media file by ticket id and relative path. It only serves the media types above, only from those places, and refuses anything else (no path outside the ticket's folder or the archive, no `..`, no other file types). `/api/tickets` lists each ticket's media (relative path, kind: image or video, size).
3. **Showing them.** The ticket's detail view gets a "Screenshots and recordings" section: a grid of thumbnails (images and GIFs as images; MP4 and WebM as muted, looping video players with controls), each with its file name; clicking an image opens it full size with hard pixel edges (`image-rendering: pixelated`), on a dark background, closable with Escape or a click. No section when a ticket has no media. Cards in the lanes show a small count ("3 shots") when a ticket has media.
4. **Keep the board fast.** Media lists are read with the tickets and cached like the rest; files are served with their content type and not read until asked for.

The board server restarts are as today (`python tools/taskboard/server.py --stop`, then the next session starts it).

## Acceptance criteria

- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes, with no network calls beyond the test's own local server (QA: pass / fail)
- [ ] Tests show `/api/tickets` lists a ticket's media from `art-archive/<id>/screenshots/` (main checkout and an open task folder) and from its `Board review files:` line, and none for a ticket without any (QA: pass / fail)
- [ ] Tests show the media endpoint serves a listed PNG and an MP4 with the right content type, and refuses a path with `..`, a non-media file, and a file outside the ticket's places (QA: pass / fail)
- [ ] The detail view shows the "Screenshots and recordings" section with thumbnails, a full-size view, and video players for MP4/WebM, and cards show a media count; checked by QA in a browser or by reading the page code against this description (QA: pass / fail)
- [ ] `docs/README.md` ("The task board") and `tasks/README.md` ("Screenshots") say where media go and that the board shows them (QA: pass / fail)

## Updates

## Result notes

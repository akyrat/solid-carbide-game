---
id: T-201
title: Task board: screenshots and recordings shown on the ticket
status: in-progress
from: project-lead
to: project-lead
lead: Coursework
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

### 2026-10-19, Open → In progress

Started: each ticket on the board gets a 'Screenshots and recordings' section (thumbnails, full-size view, video players), and cards show a media count.

## Result notes

**What changed**

- `tools/taskboard_sync.py`: `MEDIA_TYPES` (png, jpg, gif, webp: image; mp4, webm: video), `media_kind()`, `screenshot_files()` (media in `art-archive/<id>/screenshots/` and subfolders), `safe_relative()` (refuses absolute paths, drive letters, `..`, `.`, empty parts, and anything whose real path leaves the checkout), `ticket_media()`. `ticket()` now adds `media: [{path, kind, size}]`, looked up in the checkout the task file is read from (its task folder while the branch is open, else the main checkout, as for the ticket file). Media on the `Board review files:` line are added after the screenshots, deduplicated; non-media, missing, `..` and outside paths are skipped (an absolute path counts only if it is inside the checkout).
- `tools/taskboard/server.py`: `GET /api/media?id=T-012&path=<relative path>` (localhost only, read-only). `media_file()` checks the id, refuses `..`/absolute/drive paths (400) and non-media types (415), then serves only a path in that ticket's own media list (404 otherwise). `send_media()` streams the file in 64 KB chunks with its content type, `nosniff`, `Accept-Ranges` and single byte ranges (206/416) so videos can be scrubbed; nothing is read until asked for. `version()` also hashes each ticket's screenshots, so a new or changed screenshot refreshes the page like a changed task file (media lists are read with the tickets, nothing extra per poll beyond a stat of each screenshots folder).
- `tools/taskboard/taskboard.html`: cards show a "N shots" chip (“1 shot”) when a ticket has media. The detail view has a "Screenshots and recordings" section under "Your review" (hidden when there are none): a grid of thumbnails with file names; images/GIFs as `<img>` (pixelated), MP4/WebM as `<video muted loop autoplay playsinline controls>`. Clicking an image opens a full-screen dark `<dialog>` with `image-rendering: pixelated`; small images are enlarged by a whole number, large ones shrink to fit; Escape (native dialog cancel) or any click closes it. The section is only redrawn when its list changes, so playing videos aren't restarted by the 2-second refresh, and closing the ticket stops them.
- Docs: `docs/README.md` ("The task board": new "Screenshots and recordings" bullet with the endpoint) and `tasks/README.md` ("Screenshots": subfolders, short GIF/MP4 recording where a still doesn't show motion, the board shows them on the ticket).

**Tests per criterion** (`python -m unittest discover -s tools -p "test_*.py"`: 346 tests, OK, 214 s; no network beyond the tests' own local servers on port 0)

1. Whole suite: passes, 346 tests.
2. Listing: `test_taskboard_server.MediaTests.test_tickets_list_media_from_screenshots_and_review_files`, `test_tickets_list_media_from_an_open_task_folder`, `test_ticket_without_media_lists_none`; `test_taskboard_sync.TaskboardSyncTests.test_media_from_the_screenshots_folder_and_its_subfolders`, `test_media_from_the_board_review_files_line`, `test_media_of_an_open_task_come_from_its_folder`, `test_no_media_is_an_empty_list`.
3. Serving and refusals: `MediaTests.test_serves_a_listed_png_and_mp4_with_their_content_type`, `test_serves_a_byte_range_of_a_recording`, `test_refuses_dot_dot_paths`, `test_refuses_non_media_files`, `test_refuses_files_outside_the_tickets_places` (archive file not in screenshots/, another ticket's, master's copy while the branch is open, absolute, unknown ticket, bad id), `test_media_only_on_localhost`, `test_version_changes_when_a_screenshot_is_added`; `TaskboardSyncTests.test_safe_relative_refuses_escapes`.
4. Page: by reading `taskboard.html` (`shotsChip`, `renderMedia`, `openLightbox`, the `.media`/`.shots`/`dialog.lightbox` styles). Not opened in a browser here.
5. Docs: as above.

No screenshots: tooling. A JavaScript syntax check of the page with node was refused by a hook (it matched the command as a status edit), so it was not run; QA should load the page once in a browser (a restarted board, or a test server on another port) to confirm it renders.

The live board on port 8765 was not touched; it picks this up after `python tools/taskboard/server.py --stop` and the next session start, once merged.

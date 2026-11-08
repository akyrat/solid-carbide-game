---
id: T-572
title: The tutorial shows again after each new itch.io build
status: done
from: project-lead
to: game-loop
lead: Rails
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/working-with-the-board.md, tools/publish_itch.py, game/scripts/game/game_flow.gd, game/scripts/ui/game_settings.gd, game/scripts/menu/tutorial_slides.gd]
files_expected_to_change: [tools/publish_itch.py, tools/, game/scripts/, game/tests/, game/export_presets.cfg, game/docs/, docs/hud-and-menus.md, docs/working-with-the-board.md]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build HUD and menus, Decisions, "The tutorial comes back with each new itch.io build". Each build pushed with tools/publish_itch.py carries its build id (the short commit it already uses as --userversion). The game saves, with "Don't show again", the build id it was ticked on; when the running build's id differs, the slides show again before the first run, and ticking it again hides them until the next build. A build with no id (the desktop game from the editor) keeps today's behaviour. Propose how the id gets into the export without leaving the main checkout dirty after a publish (publish_itch.py needs a clean tree before and should leave it clean after; for example a git-ignored file written just before the export and included by the Web preset, or an export-time feature), and how old saves (a tick with no build id) behave: propose that they show the slides once in the first build with an id. Test the script part with --dry-run or unit tests only: never run a real push. Update the Publishing to itch.io section of docs/working-with-the-board.md with one line on it.

The board's review: from C:\solid-carbide-worktrees\T-572, the agent gives in the result notes a way to try it in the editor with a faked build id (tick Don't show again, change the id, restart: the slides show).

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Never run a real itch.io push (butler push) and never print .env values. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With "Don't show again" ticked on build A, a run on build B shows the slides, and ticking it again on B hides them on B (tests). (QA: pass)
- [ ] With no build id, today's behaviour is unchanged (tests). (QA: pass)
- [ ] publish_itch.py puts the build id into the export and the main checkout is clean after a --dry-run (tests or a dry run, never a real push). (QA: pass)
- [ ] docs/hud-and-menus.md Content and the Publishing section of docs/working-with-the-board.md describe it. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A screenshot in art-archive/T-572/screenshots/ shows the slides coming back after the faked id changed. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: Game Loop builds the build-id reset.

### 2026-11-07, In progress → In QA

Built: each itch build carries its id; a tick hides the slides only on its own build. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (6/6). Waiting for your playtest in the combined build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Game Loop Agent, 2026-11-07.

How the id gets in: tools/publish_itch.py writes the build id (the same short master commit it pushes as --userversion) into game/build_id.txt just before the Web export and removes it in a finally block after, whether the export worked or not (export_with_build_id). The file is git-ignored (.gitignore) and the Web preset packs it (game/export_presets.cfg include_filter="build_id.txt"); the game reads res://build_id.txt. A real local Web export (no push) of this branch with a faked id was checked: index.pck contains build_id.txt and its text.

The game: GameSettings.build_id() reads GameSettings.build_id_path (default res://build_id.txt; "" when missing or empty). save_tutorial_hidden also saves hidden_build (the running id) in the tutorial section. load_tutorial_hidden: with no id, hidden alone decides (today's behaviour); with an id, hidden only while hidden_build equals it. Old saves (hidden true, no hidden_build): proposal as asked, they show the slides once in the first build with an id, then a tick hides them again. Tests never read the real file: TestSave.restore_settings points build_id_path at a missing test file.

Try it in the editor (from C:\solid-carbide-worktrees\T-572): create game/build_id.txt with any text (for example aaa), run the game, Start, go to the last slide, tick Don't show again, Go live; quit and run again, Start: straight into the run. Change the file's text (bbb), run again, Start: the slides show. Tick again: hidden until the text changes. Delete game/build_id.txt afterwards (git-ignored, so it never gets committed, but publish_itch.py overwrites and removes it anyway).

Tests run (foreground): game test_tutorial_build_id.gd 9/9 passed (new); test_tutorial_flow.gd all passed (new test: build A then build B then ticked again on B); test_tutorial_setting.gd 3/3 passed. Python tools/test_publish_itch.py 26/26 OK (3 new: preset packs and .gitignore ignores the file; dry run packs the id and leaves git status empty; the file is removed when the export fails). Full tools set: python -m unittest discover -s tools -p "test_*.py": 643 tests OK. No real push, .env never printed.

Screenshots (art-archive/T-572/screenshots/, fixture tests/fixtures/tutorial_new_build_demo.gd with a yellow fixture-only caption): new_build_slides_come_back.png (ticked on build aaaaaaa, running bbbbbbb: slide 1 shows), same_build_straight_into_run.png (same build: the run starts at 4:00).

Files: tools/publish_itch.py, tools/test_publish_itch.py, .gitignore, game/export_presets.cfg, game/scripts/ui/game_settings.gd, game/tests/helpers/test_save.gd, game/tests/unit/test_tutorial_build_id.gd (new), game/tests/unit/game/test_tutorial_flow.gd, game/tests/fixtures/tutorial_new_build_demo.gd/.tscn/_same.tscn (new), game/docs/hud-and-menus/tutorial-slides.md, game/docs/game-loop/screen-flow.md.
Documents affected: docs/hud-and-menus.md (Content, new section "The tutorial comes back with each new build"), docs/working-with-the-board.md (Publishing to itch.io, one line).
- 2026-11-08, needs-playtest → done: Board: menu fixes build played, merge (2026-11-08)

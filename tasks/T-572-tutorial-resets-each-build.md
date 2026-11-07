---
id: T-572
title: The tutorial shows again after each new itch.io build
status: open
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
qa_rounds: 0
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

- [ ] With "Don't show again" ticked on build A, a run on build B shows the slides, and ticking it again on B hides them on B (tests). (QA: pass / fail)
- [ ] With no build id, today's behaviour is unchanged (tests). (QA: pass / fail)
- [ ] publish_itch.py puts the build id into the export and the main checkout is clean after a --dry-run (tests or a dry run, never a real push). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content and the Publishing section of docs/working-with-the-board.md describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot in art-archive/T-572/screenshots/ shows the slides coming back after the faked id changed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

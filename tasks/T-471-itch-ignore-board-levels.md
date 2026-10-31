---
id: T-471
title: publish_itch.py ignores the board's level files and leaves them out of the web build
status: open
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, tools/publish_itch.py, tools/test_publish_itch.py, game/export_presets.cfg, docs/working-with-the-board.md]
files_expected_to_change: [tools/publish_itch.py, tools/test_publish_itch.py, game/export_presets.cfg, docs/working-with-the-board.md]
model: sonnet
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

The board asked for the first push to itch.io on 2026-10-31, and `python tools/publish_itch.py --dry-run` on master stopped with "STOPPED: uncommitted changes: ?? game/data/levels/". That folder holds the board's own level files from the level creator: they are never committed, moved or changed by anyone but the board, so they're always untracked on master.

1. The clean-tree check ignores untracked files under game/data/levels/ (and never reads, moves or changes them).
2. The Web export leaves game/data/levels/ out of the build (an exclude filter in the Web preset of game/export_presets.cfg), so the board's level files are never published; the game's own map is game/data/level/kaiju_city_map.json (a different folder) and stays in. Check the export still runs the game's map.
3. Run `python tools/publish_itch.py --dry-run` on master from the main checkout C:\solid-carbide-game (reading only; it writes only the git-ignored web-build/ folder) after your change is in your folder? No: run the dry run in your own folder with `--repo` pointed at it is not possible (it must be on master), so test the clean-tree rule and the preset with tests, and say in the result notes that the Project Lead runs the real dry run after the merge.
4. Update the "Publishing to itch.io" section of docs/working-with-the-board.md.

Never write, move or commit anything in game/data/levels/ (tests use a temporary repo).

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test (temporary git repo) shows untracked files under game/data/levels/ don't stop the script, and any other untracked or changed file still does. (QA: pass / fail)
- [ ] The Web preset excludes game/data/levels/ and still includes game/data/level/ (the game's map); a test or a check of the preset shows it. (QA: pass / fail)
- [ ] The script never reads, moves or changes files under game/data/levels/ (test or code review in the result notes). (QA: pass / fail)
- [ ] docs/working-with-the-board.md, "Publishing to itch.io", says the board's level files are ignored and never published. (QA: pass / fail)
- [ ] The tools and game/tools Python tests pass (`python -m unittest discover -s tools -p "test_*.py"`, `python -m unittest discover -s game/tools -p "test_*.py"`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

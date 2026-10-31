---
id: T-448
title: Publish a browser build of master to the board's private itch.io page with one script
status: open
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/working-with-the-board.md]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, game/project.godot, game/tools/run_tests.sh]
files_expected_to_change: [game/export_presets.cfg, tools/publish_itch.py, tools/test_publish_itch.py, docs/working-with-the-board.md, .gitignore]
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

The board, 2026-10-31: the board wants the game on a private itch.io page (Restricted, with a password) so friends can play it in the browser, and an easy way to update it: the board says "push the latest build to itch" and the Project Lead runs one script.

1. **Web export:** add a Web export preset to game/export_presets.cfg for Godot 4.6.2 (Godot at C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe), with thread support off, so itch.io doesn't need SharedArrayBuffer, and the canvas sized for itch's embed. Install the 4.6.2 export templates if they're missing (Godot's official templates, from godotengine.org or its GitHub releases), and say where they went. If installing outside the repo is refused, stop and say what's needed.
2. **butler:** itch.io's official uploader (https://itch.io/docs/butler/). Install it into a git-ignored folder (for example tools/bin/), or say where it is. The API key comes only from `.env` as `BUTLER_API_KEY` (the board adds it itself; never print it, never commit it), and the target from `.env` as `ITCH_TARGET` (`<user>/<game>:html5`; the board will give the page URL).
3. **tools/publish_itch.py:** checks it runs on master with a clean tree and no merge in progress, exports a release Web build of master's game/ into a git-ignored build folder, checks the export produced index.html, .wasm and .pck, then runs `butler push <folder> $ITCH_TARGET --userversion <short master commit>` and prints the version and the page link. `--dry-run` does everything but the push. With no key or no target it stops before pushing and says which is missing. No tests run: master is already tested. It never changes the itch page's settings (the password and visibility stay the board's).
4. Document the process in docs/working-with-the-board.md (a short "Publishing to itch.io" section: the board's one-time setup, then "push the latest build to itch" means the Project Lead runs the script, only when the board asks, since it publishes) and the script's own docstring.

The real first push is not part of this ticket (it waits for the board's URL and key): test with `--dry-run`, and say whether the exported build opens in a local browser (for example `python -m http.server` in the build folder) if you can check it.

Never write, move or commit anything in game/data/levels/. Secrets only in .env.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/export_presets.cfg has a Web preset with thread support off, and `python tools/publish_itch.py --dry-run` on master produces a build folder with index.html, a .wasm and a .pck (output in the result notes). (QA: pass / fail)
- [ ] With BUTLER_API_KEY or ITCH_TARGET missing, the script stops before pushing and names what is missing (test). (QA: pass / fail)
- [ ] The script refuses to run off master, with uncommitted changes, or with a merge in progress (tests with a temporary git repo or stubs). (QA: pass / fail)
- [ ] The butler command the script would run is exactly `butler push <build folder> <ITCH_TARGET> --userversion <short commit>`, and the key never appears in output or logs (test with a stubbed butler). (QA: pass / fail)
- [ ] The build folder and butler's install folder are git-ignored; nothing secret is committed. (QA: pass / fail)
- [ ] docs/working-with-the-board.md has the "Publishing to itch.io" section. (QA: pass / fail)
- [ ] The tools Python tests pass (`python -m unittest discover -s tools -p "test_*.py"`) and the game/tools tests pass (`python -m unittest discover -s game/tools -p "test_*.py"`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

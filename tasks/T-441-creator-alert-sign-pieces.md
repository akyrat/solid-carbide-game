---
id: T-441
title: Kaiju alert signs are level creator pieces; the fixed sign list is retired
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-440]
documents_affected: [docs/level-design.md, game/docs/level/level-creator-pieces.md, game/docs/level/mvp-map.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/docs/level/mvp-map.md, tasks/T-130-kaiju-alert-banners-art.md, tasks/T-265-creator-skyscraper-banner-toggle.md, tasks/T-439-kaiju-signs-on-kaiju-city.md, game/scripts/level/kaiju_signs.gd, game/data/level/kaiju_signs.json, game/scripts/level_creator/editor.gd, game/tests/unit/test_kaiju_signs.gd]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/kaiju_signs.gd, game/data/level/kaiju_signs.json, game/tests/unit/, game/docs/level/level-creator-pieces.md, game/docs/level/mvp-map.md, docs/level-design.md]
model: opus
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

The board, 2026-10-31 (docs/level-design.md, Decisions, "Kaiju alert signs are level creator pieces"): the board wants to place the kaiju alert signs itself, anywhere, in the level creator, on the ground or on buildings. This replaces T-439 (cancelled), which put them at fixed spots; its branch `task/T-439-kaiju-signs-on-kaiju-city` is kept and is useful reference for addressing Kaiju City's skyscrapers.

Two new pieces in the level creator, using the existing sign art in game/art/banners/ (0 PixelLab calls), each in both designs (head: red triangle; body: red circle), chosen in the strip under the selected piece like the other pieces' variants:

1. **Standing alert sign**: placed on the ground or on a rooftop or platform, at the height of what it stands on (Level design, Decisions, "Obstacles and decorations respect the buildings' and rooftops' heights"), turned like the other pieces where the art allows.
2. **Alert banner**: hangs on a skyscraper's visible wall (never on a platform or a short building; T-130). The board chooses which wall and how high, with the same look as T-130's banners (sheared to the wall, fading with that skyscraper when the car is behind it, sharing its depth).

Both are pictures only, with no collisions, as today. They are saved in the level file, come back when the level is reopened, and the run draws them exactly where the editor shows them. They can be moved and deleted like any other piece.

**The fixed sign list is retired:** `game/data/level/kaiju_signs.json` and the code that places signs from it are no longer used; a map shows only the signs placed in its level. Update the tests that count the game map's 4 banners and 2 signs. The game's map, Kaiju City, has no signs until the board places them in the creator; copying the board's level into the game's copy (`game/data/level/kaiju_city_map.json`) is not part of this ticket.

Use the text from the linked text ticket for every label (no placeholders). Anything the docs leave open (key bindings, defaults) is a proposal for the playtest, listed in the result notes.

Never write, move or commit anything in game/data/levels/ (the board's level files); test with your own fixture levels.

The board's review: in the level creator, place standing signs on the ground and on a rooftop and banners on two skyscrapers' walls, in both designs; save, reopen, and play the level to see them in the run.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test places a standing alert sign on the ground and one on a rooftop in a level document, saves and reopens it, and finds both with their design and position; a run built from that level draws them at the height of what they stand on. (QA: pass / fail)
- [ ] A test places an alert banner on a skyscraper wall, saves and reopens it, and a run built from that level draws it as a child of that skyscraper's art (so it fades with it), on the chosen wall at the chosen height. (QA: pass / fail)
- [ ] A test shows a banner can't be placed on a platform or a short building, and that signs and banners have no collisions. (QA: pass / fail)
- [ ] A test shows a map no longer reads game/data/level/kaiju_signs.json: a level with no placed signs draws none. (QA: pass / fail)
- [ ] Both pieces appear in the creator's side panel with the text ticket's labels, and their two designs are chosen in the strip (test or screenshot). (QA: pass / fail)
- [ ] Screenshots of both pieces in the editor and in a run are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass / fail)
- [ ] game/docs/level/level-creator-pieces.md and game/docs/level/mvp-map.md describe the pieces and the retired list; docs/level-design.md, Content, describes the pieces. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed, and 0 PixelLab calls are made. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

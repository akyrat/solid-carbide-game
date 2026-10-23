---
id: T-265
title: "Level creator: skyscraper banners on or off, off by default"
status: in-progress
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-261]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level/building_towers.gd, game/scripts/level/map_building.gd, game/art/banners/, game/scripts/level_creator/, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-265/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22): in the creator every skyscraper shows a kaiju alert banner in the middle of its face, and the board doesn't want them on all of them. Each skyscraper placed in the creator has its banner **on or off** (key B, labels from T-261), **off by default**, saved with the building; the creator's preview shows the choice. Find where the banner comes from first (the banner art in `game/art/banners/` is separate from the skyscraper art; if a banner is baked into some skyscraper pictures instead, say so and remove it by script from a copy, keeping the original, no PixelLab). The game's own map keeps its banners as today. Earlier saved levels open with their skyscrapers' banners off unless their data says otherwise (your proposal; say which).

Built on T-262's branch (the Project Lead makes your folder). End with a screenshot of the six skyscrapers with banners off and two with banners on.

## Acceptance criteria

- [ ] Tests show a creator skyscraper places with no banner by default, B turns it on and off, and the choice is saved, reopened and drawn in a run (QA: pass / fail)
- [ ] The game's own map still shows its banners as before (a test) (QA: pass / fail)
- [ ] The screenshot is in `art-archive/T-265/screenshots/`; `game/README.md` describes the toggle; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place skyscrapers with and without banners.
Board review files: the screenshot in `art-archive/T-265/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-23, Blocked → In progress

Started on T-264's branch: skyscraper banners on or off, off by default.

## Result notes

Written by the agent when it finishes.

Done on T-264's branch; sent to QA. No PixelLab, nothing deleted.

- **Where the banner comes from:** it is baked into the skyscraper art. The vertical neon sign is painted into every one of the 12 bodies (`build_skyscrapers.py` `place_sign`, T-064, `build_city.py`); `art/banners/` (T-130) is a different thing, the game map's kaiju alert signs, which the creator's map never builds. So I made sign-less copies by script: `game/tools/build_skyscrapers_nobanner.py` runs the same build from the same raw pieces with an empty sign and writes `game/art/buildings/nobanner/skyscraper_N_K.png` (12 files). `--check` rebuilds the originals and confirms they equal the art in the game pixel for pixel, so the copies differ only in the sign. The originals are untouched.
- **Data and drawing:** a skyscraper in `buildings` gets `"banner": true|false` (written explicitly, off by default; other buildings never get the key). `BuildingTowers.single_of` passes it on; `setup` draws `nobanner/` when it is not true. The game's own map (whole blocks, no `asset`) goes through none of this and keeps its 4 banners, 2 signs and signed bodies (a test).
- **Controls:** B in `editor.gd` `KEY_ACTIONS` (`banner_pick`); top bar buttons "Banner on" / "Banner off" (T-261's labels) show with a skyscraper picked or selected. B sets the next skyscraper placed; with nothing picked and a skyscraper selected it changes that building and redraws. The preview shows the choice.
- **Earlier saved levels (my proposal):** a skyscraper with no `banner` key opens with the banner off.
- **Not done:** the small pictures in the Looks strip and the panel button still show the signed art (they are the family's catalogue textures); only the map and the placement preview follow the choice.
- **Tests:** `tests/unit/level_creator/test_creator_banners.gd` (10 tests: plain bodies differ only in the sign; off by default; B on and off with the buttons; other pieces; selected building; preview; saved, reopened and drawn in a map built from the file; earlier level without the key; the game's own map keeps its banners). `test_editor_place_delete.gd` updated for the explicit `banner: false` and the plain texture. `tools/test_build_skyscrapers_nobanner.py`. Full GUT suite 1561 of 1561 (the first run exited 139, the rerun passed); `game/tools` 486 OK; `tools` 451 OK.
- **Screenshot:** `art-archive/T-265/screenshots/banners.png` (six towers with the banner off, two with it on; fixture `tests/fixtures/level_creator_banners_demo.gd`).
- **Documents:** `game/README.md` ("Skyscraper banners on or off (T-265)"), `docs/level-design.md` ("Level creator: skyscraper banners on or off").
- **Process slip:** I patched `building_towers.gd` and two test files with short inline python heredocs instead of Edit; the content is the same as an Edit would give.

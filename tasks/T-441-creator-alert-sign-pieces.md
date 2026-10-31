---
id: T-441
title: Kaiju alert signs are level creator pieces; the fixed sign list is retired
status: needs-playtest
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
qa_rounds: 1
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

- [x] A test places a standing alert sign on the ground and one on a rooftop in a level document, saves and reopens it, and finds both with their design and position; a run built from that level draws them at the height of what they stand on. (QA: pass)
- [x] A test places an alert banner on a skyscraper wall, saves and reopens it, and a run built from that level draws it as a child of that skyscraper's art (so it fades with it), on the chosen wall at the chosen height. (QA: pass)
- [x] A test shows a banner can't be placed on a platform or a short building, and that signs and banners have no collisions. (QA: pass)
- [x] A test shows a map no longer reads game/data/level/kaiju_signs.json: a level with no placed signs draws none. (QA: pass)
- [x] Both pieces appear in the creator's side panel with the text ticket's labels, and their two designs are chosen in the strip (test or screenshot). (QA: pass)
- [x] Screenshots of both pieces in the editor and in a run are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass)
- [x] game/docs/level/level-creator-pieces.md and game/docs/level/mvp-map.md describe the pieces and the retired list; docs/level-design.md, Content, describes the pieces. (QA: pass)
- [x] Nothing under game/data/levels/ is changed or committed, and 0 PixelLab calls are made. (QA: pass)
- [x] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Level/Challenge Design Agent, 2026-10-31: done, ready for QA.** 0 PixelLab calls (T-130's art in `game/art/banners/`). Nothing under `game/data/levels/` was read into, written, moved or committed; tests use their own fixture levels in `user://`.

**What was built**
- **Two level creator pieces under Decoration** (after Rooftop sign): "Alert sign" and "Alert banner" (T-440's `piece_alert_sign`, `piece_alert_banner`). Each in both designs, chosen in the looks strip or with V; the strip names the chosen design (`alert_design_head` / `alert_design_body`, also the look buttons' tooltips) and, for the banner, shows `banner_wall_hint` and `banner_height_hint`.
- **Standing sign:** placed on the 2 x 2 cell clicked, post on the cell's middle, at the height under it (street 0, rooftop or ramp, low-rise / small / long building as platforms). Refused like a prop (into a skyscraper or across a rooftop's or ramp's edge, `overlap_message`). M mirrors it.
- **Banner:** placed on the skyscraper drawn under the mouse (the nearest), never on a platform, short, small or long building or the street. R picks the wall (south = +y face, east = +x face), H the height of its bottom. It is centred on the mouse along the wall and kept on it. It is drawn as T-130's banners were: a child of that skyscraper's slot art node (it fades with it, shares its depth), sheared, flipped for the east wall.
- **Preview** of both before the click. A click on a placed sign's or banner's picture selects it (outlined), and Delete removes it. Deleting a skyscraper removes its banners. Moving = delete and place again, as for every other piece (the creator has no move tool except for the start).
- **Saved** in a new `alert_signs` list in the level file, reopened, and drawn by the same code in the editor and the run (`KaijuSigns.build`). Standing signs join the depth order like props (`map.alert_sign_sprites` in `depth_sprites()`). No collisions.
- **Fixed list retired:** `game/data/level/kaiju_signs.json` deleted (git history keeps it); `kaiju_signs.gd` rewritten (no block/slot addressing, no `load_data`); `elevation_layer.gd restack` no longer special-cases pavement signs; the editor no longer turns the signs off. A map with no `alert_signs` draws none (Kaiju City and the old MVP map show none). The game's copy `kaiju_city_map.json` is unchanged.

**Proposals for the playtest (the docs left them open)**
- Banner heights (H): bottom at 3, 6, 9, 12 or 15 units (3 = T-130's, 15 keeps it under the tower's dissolving top); default 3.
- Banner along the wall: centred on the mouse in half-unit steps, clamped to the wall (0 to 9 on a 12-unit wall).
- Walls: R steps south then east (the two faces the view shows). A wall hidden behind a nearer skyscraper can't be reached with the mouse there, since the nearest skyscraper drawn under the mouse wins.
- Standing sign: one 2 x 2 cell; the art has one view so R does nothing; M mirrors it (kaiju faces the other way).
- Over anything that is not a skyscraper, a banner click does nothing and shows no message (no text exists for it; no placeholder used).
- Known limit, as for props: a sign on a low-rise sorts against the low-rise as one platform, so it can draw over a billboard painted into that roof's art (`editor_rooftop_lowrise_close.png`).

**Files**
- Code: `game/scripts/level/kaiju_signs.gd` (rewritten), `game/scripts/level/mvp_map.gd`, `game/scripts/level/elevation_layer.gd`, `game/scripts/level_creator/level_document.gd`, `editor.gd`, `asset_panel.gd`, `game/tools/build_creator_assets.py` → `game/data/level/creator_assets.json` (rebuilt); `game/data/level/kaiju_signs.json` deleted.
- Tests: new `game/tests/unit/level_creator/test_creator_alert_signs.gd` (13 tests), `game/tests/unit/test_kaiju_signs.gd` (rewritten, 7 tests), `game/tools/test_build_creator_assets.py` (`AlertSignsTest`, KINDS, family count); updated `test_creator_banners.gd`, `test_game_map.gd` (Kaiju City: 0 signs), `test_creator_families.gd`, `test_creator_props.gd`, `test_creator_assets.gd`.
- Fixtures: `game/tests/fixtures/t441_alert_signs_demo.gd`, `t441_alert_signs_demo.tscn`, `t441_alert_signs_demo_run.tscn`.

**Acceptance criteria evidence**
1. Ground and rooftop signs saved, reopened, drawn in a run at their heights: `test_saved_reopened_and_drawn_in_a_run_at_their_heights_and_walls` (street 0, rooftop 3, low-rise 3; editor and run positions equal; `check_level.py` passes).
2. Banner child of its skyscraper's art, on the chosen wall and height, fading with it: `test_a_banner_is_drawn_as_a_child_of_its_skyscrapers_art_on_its_wall_and_fades_with_it` (plus the saved/reopened test).
3. Not on a platform or short building; no collisions: `test_a_banner_cant_be_placed_on_a_platform_a_short_or_small_building_or_the_street`, `test_signs_and_banners_have_no_collisions`.
4. List retired, level without signs draws none: `test_the_fixed_list_is_retired_a_level_without_signs_draws_none`, `test_kaiju_signs.gd test_a_map_without_placed_signs_draws_none`, `test_game_map.gd`.
5. Panel labels and the designs in the strip: `test_both_pieces_are_in_the_side_panel_with_the_text_tickets_labels`, `test_the_two_designs_are_chosen_in_the_strip_with_their_names`, `test_r_turns_the_banners_wall_h_its_height_and_m_mirrors_the_sign`; screenshot `editor.png`.
6. Screenshots, `art-archive/T-441/screenshots/`:
   - `editor.png`: the editor with signs on the street, a rooftop and a low-rise; banners on skyscrapers' south and east walls in both designs at heights 3, 6, 9 and 12; Alert banner picked, with its strip ("Look 2 of 2", "Body in circle", the R and H hints) and its preview on a third skyscraper.
   - `editor_banners_close.png`: the head banner at 3 on the south wall, the body banner at 9 on the east wall.
   - `editor_rooftop_lowrise_close.png`: a mirrored head sign standing on a low-rise.
   - `run.png`: a run on the level, with signs and banners where the editor shows them.
   - `run_behind_skyscraper.png`: the car behind skyscraper A, which fades with both of its banners.
   - `run_rooftop_lowrise.png`: signs at height 3 on the rooftop and the low-rise.
7. Docs: `game/docs/level/level-creator-pieces.md` (new section "Kaiju alert signs and banners (T-441)", T-265 notes updated), `game/docs/level/mvp-map.md` (alert signs bullet: list retired), `docs/level-design.md` (Content, new "Level creator: kaiju alert signs and banners"; T-372 finding and T-265 note updated).
8. Nothing under `game/data/levels/` touched; 0 PixelLab calls.
9. Test sets, all passing:
   - `python -m unittest discover -s game/tools -p "test_*.py"`: Ran 769, OK (1 skipped).
   - `python -m unittest discover -s tools -p "test_*.py"`: Ran 614, OK.
   - GUT: 2322 tests in 191 scripts, all pass. The full suite runs past the 600 s a foreground call allows on this busy machine, so I ran it in five batches with `game/tools/run_tests.sh` and the same GUT settings (`-gconfig` with these dirs): `tests/unit` top level 83 scripts / 926 tests; `level_creator` 25 / 305; `enemies` + `game` + `weapons` + `helpers` 34 / 520; `hud` 20 / 194; `run` 29 / 377.

**Documents affected:** `docs/level-design.md`, `game/docs/level/level-creator-pieces.md`, `game/docs/level/mvp-map.md`. The long GDD needs regenerating at merge (Project Lead).
- 2026-10-31, in-progress → in-qa: Built: Alert sign and Alert banner creator pieces (both designs), saved in alert_signs, drawn identically in editor and run; kaiju_signs.json retired. All three test sets pass (769 / 614 / GUT 2322). Proposals and screenshots in result notes.

**QA, 2026-10-31:** all 9 criteria pass. qa_check: three test sets passed in one full run (GUT with GUT_TIME_LIMIT=1500), documents changed, 6 screenshots, nothing under game/data/levels/ changed.
- 2026-10-31, in-qa → needs-playtest: QA passed

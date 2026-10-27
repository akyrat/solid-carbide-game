---
id: T-257
title: "Art: the small and long buildings"
status: done
from: project-lead
to: asset-generation
lead: Coursework
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-254-smaller-and-longer-buildings.md, tasks/T-064-building-art.md, game/tools/pixellab_client.py]
files_expected_to_change: [game/art/buildings/, game/art/pixellab-generation-log.jsonl, art-archive/T-257/, art-archive/README.md, game/data/level/, docs/visual-style.md, game/README.md]
model: sonnet
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

The board's go for PixelLab (Level design, Decisions, "Level creator piece set", 2026-10-22: up to 100 generations across the creator's art tickets). **This ticket's cap: 12 generations.** T-254 added a small square building (6 x 6 units) and a long building (12 x 6, and 6 x 12 rotated) with code-drawn placeholders. Generate their final art in the style of today's short buildings (T-064; Visual style, Decisions, "Buildings, redesigned", "City brief" and "City colours": roofs that show, steel and glass, pale lit windows, small amber accents, light damage, pavement drawn round them inside the footprint), at the game's scale, two looks for the small one if the cap allows, with the pixel-art rules, never Redgull red. Mirrors by script are free.

Plan your calls and their cost in the result notes before calling (`docs/working-with-the-board.md`, "Art and money"; 600 s timeout), one round only: report weak results, don't regenerate, and stop and report if a call costs more than planned or the cap would be passed. Log every call, keep every generation (game-ready in `game/art/buildings/`, the rest in `art-archive/T-257/`), and swap them in through T-254's data only.

Your folder is built on T-254's branch (the Project Lead makes it). End with a screenshot of the new buildings beside today's in the creator.

## Acceptance criteria

- [ ] The result notes list the planned calls and cost before the calls, and the generations used, at most 12; every call is in the generation log (QA: pass; plan with cost in notes, 6 of 12 generations, 6 T-257 entries in the log)
- [ ] The small and long buildings (both rotations) have art that fits their footprints and matches today's short buildings, passes `check_sprite_rules.py`, no Redgull red (screenshot) (QA: pass; screenshot shows small and long on their footprints in the short buildings' style, six sprites have no 135,17,27 pixel, no half-transparent pixels, 23 colours; check_sprite_rules only fails its default 128 px frame size, which does not apply to building art)
- [ ] They use the new art through T-254's data; every generation is kept (QA: pass; creator_buildings.json points at creator_final, all 6 raws in art-archive/T-257/raw)
- [ ] The screenshot is in `art-archive/T-257/screenshots/`; Visual style and `game/README.md` record the art; the full GUT suite and all Python tool tests pass (QA: pass; screenshot present, visual-style, game/README updated, GUT TESTS PASSED, game/tools 424 OK, tools 439 OK)

The board's review: place the new buildings and judge the art.
Board review files: the screenshot in `art-archive/T-257/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started on T-254's branch: PixelLab art for the small and long buildings, cap 12 generations.

### 2026-10-22, In progress → In QA

Art in: 6 of 12 generations used. The buildings read as today's short buildings; weak spots are listed in the result notes. Sent to QA.

### 2026-10-22, In QA → Needs playtest

QA passed all 4. 6 of 12 generations used. Ready to judge in the creator; weak spots: the small building's walls don't match, long look 1 is very dark, the roofs look alike.

## Result notes

Written by the agent when it finishes.

**Plan before the calls (Asset Generation Agent, 2026-10-22):** same method as T-129's short buildings (flat facades from `create-image-pixflux`, 1 generation each, sheared 2:1 and a script-drawn roof and pavement, palette B), 6 calls = **6 generations of the cap 12** (the other 6 stay unused):
- small building, look 0 and look 1: a left and a right facade each, 160 x 144 px (4 calls);
- long building, look 0 and look 1: one long facade each, 352 x 144 px (2 calls); the long building's short ends reuse the small building's facades (free).
Requests are written by `game/tools/creator_building_requests.py` (palette image `art-archive/T-064/palette.png`, seeds 257001 to 257006), run one by one with `pixellab_client.py` (600 s timeout, each logged). Rooftop props are reused from T-129's raw art (free). Stop if a call costs more than 1 generation.

**Result (Asset Generation Agent, 2026-10-22):**
- **Generations used: 6 of the cap 12** (all `create-image-pixflux`, 1 each, as planned; no regeneration, no extra calls; all 6 in `game/art/pixellab-generation-log.jsonl`, task T-257). Raws and records: `art-archive/T-257/raw/`, requests `art-archive/T-257/requests/`.
- **Art:** `game/art/buildings/creator_final/` (small_0, small_1, long_ew_0/1, long_ns_0/1), same sizes and anchors as T-254's placeholders (which are kept). Swapped in through `creator_buildings.json` only (paths); catalogue rebuilt with `build_creator_assets.py`. Built free by `game/tools/build_creator_buildings_art.py`: facades sheared 2:1, script roof, T-129 rooftop props, palette B, pavement over the footprint with a half-unit margin. All pass the rules (no half-transparent pixels, at most 30 colours, no Redgull red; `build_creator_buildings.py --check` OK).
- **What they look like (honest):** they read as the same family as today's short buildings: dark steel-blue boxes, amber lit windows, tar roofs with tanks, AC units and rubble. Weak: the small building's two walls are two different buildings joined at the corner; the long buildings' short ends reuse the small walls; long look 1 is very dark with few lit windows; some facades carry a dark margin or half-cut neighbour from PixelLab; the pavement is mostly hidden, only a kerb band shows; props are reused from T-129, so the roofs look alike.
- **Tests:** full GUT 1381 tests all passed (last line "All tests passed"); `game/tools` 424 OK (1 skipped); `tools` 439 OK. New: `game/tools/test_build_creator_buildings_art.py`.
- **Screenshot:** `art-archive/T-257/screenshots/new_buildings.png` (looked at: skyscraper, short, small, long both rotations, all sit on their footprints).
- **Documents:** `docs/visual-style.md`, `game/README.md`, `art-archive/README.md`.
- No refusals.
- 2026-10-27, needs-playtest → done: The board's playtest of the creator build (playtest/creator-set, 2026-10-28): every check ticked on the playtest page, everything works fine.

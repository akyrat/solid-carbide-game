---
id: T-312
title: No Redgull left in game/ outside the art records: old logo files to art-archive, the old name spelled once in code, behaviour unchanged
status: in-qa
from: project-lead
to: qa-integration
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, tasks/T-306-code-comments-tests-tool-names-and.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/tools/style_rules.py, game/tools/check_rebrand.py, game/tools/check_level_up_shot.py, tools/style_loop/test_loop.py]
files_expected_to_change: [game/tools/style_rules.py, game/tools/test_style_rules.py, game/tools/check_rebrand.py, game/tools/test_check_rebrand.py, game/tools/check_level_up_shot.py, game/tools/test_check_level_up_texts.py, game/tools/test_build_level_up_art.py, game/tools/test_build_boost_lines.py, game/tools/build_boost_lines.py, game/tools/build_buildings.py, game/tools/build_drift_mark.py, game/tools/build_drift_smoke.py, game/tools/build_level_up_particles.py, game/tools/build_health_canister.py, game/tools/build_heart_icon.py, game/tools/build_helicopter.py, game/tools/build_gift_package.py, game/tools/build_kaiju_banners.py, game/tools/list_brand_palette.py, game/tools/make_logo_sizes.py, game/tools/draw_gull_silhouette.py, game/tools/flatten_logo.py, game/tools/check_logo_one_colour.py, game/tools/test_check_logo_one_colour.py, game/tools/_t306_rename.py, game/art/logo/, art-archive/T-075/, art-archive/T-306/, game/README.md]
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

The goal check failed: on playtest/G-006 `git grep -i redgull` over game/ (outside game/scripts, game/scenes and game/data, which are already clean) still finds more than history. The goal allows only game/art/pixellab-generation-log.jsonl and the art records (the .json files under game/art that describe how old art was made). T-306 left some matches on purpose, and T-307 to T-309 added new ones. Clear what is left without changing what any check, tool or the game does:

1. **The old logo files.** game/art/logo/redgull_logo_128.png, _64.png and _32.png, with their .png.import files, move to art-archive/T-075/ (the goal's open question proposal: game/art keeps only art fit for the game). Nothing is deleted. `git mv` is not on the pre-approved list, so move them with Python (shutil.move, for example a small one-off script under game/tools run with python) and `git add` both the old and the new paths, so git records a rename. Update every test and tool that reads them from game/art/logo (test_style_rules.py, test_check_logo_one_colour.py with its expected file list, test_build_level_up_art.py, make_logo_sizes.py's output folder) to read them from art-archive/T-075/.
2. **The old name in code that needs it** (the banned-word list, the rebrand check's name and text checks and their tests, a fixture row quoting an old text record): spell it once, as tools/style_loop already does since T-299 (`OLD_BRAND = "Red" + "gull"`). Put one constant in style_rules.py and build every use from it (`OLD_BRAND.lower()` for file names and paths). The strings the checks compare and print must stay exactly the same: rule 2's label still reads "no banned words (XP, points, Godzilla, Redgull)" when printed.
3. **Names after the old brand** that came back after T-306 (style_rules.is_redgull_red and its callers in check_rebrand.py, check_level_up_shot.py and the tests, and the tests' test_*redgull* names): rename them the T-306 way (for example is_old_brand_red), with every caller. The body, BRAND_COLOURS and BRAND_THRESHOLD stay unchanged.
4. **Art record writers** (build_boost_lines.py, build_buildings.py, build_drift_mark.py, build_drift_smoke.py, build_level_up_particles.py, build_health_canister.py, build_heart_icon.py, build_helicopter.py, build_kaiju_banners.py, and test_build_boost_lines.py, which reads a record key): build the keys and strings they write into the committed records from the constant, so a rebuild still writes those records byte for byte. Build the archive paths art-archive/T-304/<old name>/ and art-archive/T-305/<old name>/ (build_gift_package.py, build_helicopter.py, style_rules.py) the same way. Do not rename the archive folders and do not edit any record under game/art.
5. **Tools marked HISTORY** (make_logo_sizes.py, draw_gull_silhouette.py, flatten_logo.py, check_logo_one_colour.py, test_check_logo_one_colour.py, list_brand_palette.py): write "the old logo" or "the old sponsor" in their docstrings and comments, and build any name or path from the constant. Move T-306's one-off game/tools/_t306_rename.py to art-archive/T-306/ the same way as the logo files (not deleted). It is a record of that task, not a tool.
6. **game/README.md:** say "the old sponsor" or "the old logo (T-075)" instead of the name. Give the archive paths as the folders they are (art-archive/T-304/, art-archive/T-305/, art-archive/T-075/) without spelling the subfolder's name.

In the result notes, list every file that `git grep -i redgull -- game tools/style_loop` still finds, each with its reason (the generation log, or which art record and what old art it describes). Write the list as one block the Project Lead can copy into the goal's notes word for word. Show that the diff changes only names, comments, strings built to the same value, paths and file moves. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] `git grep -i -l redgull -- game/scripts game/scenes game/data` prints nothing, and `git grep -i -l redgull -- game tools/style_loop` prints only game/art/pixellab-generation-log.jsonl and .json art records under game/art. The result notes list each of these files with its reason, in one block. (QA: pass / fail)
- [ ] game/art/logo/ holds no redgull_logo_* file, and art-archive/T-075/ holds redgull_logo_128.png, _64.png and _32.png. `git diff --diff-filter=D --name-only playtest/G-006 HEAD` lists no .png file, and `git diff -M --name-status playtest/G-006 HEAD` shows the three PNGs and _t306_rename.py as renames (R), not deletions. (QA: pass / fail)
- [ ] `git diff playtest/G-006 HEAD -- game/art` shows no change to any .json record or other file under game/art except the moved logo files: the art records are untouched. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py text` on "A gift from Redgull" still fails rule 2 with the label "no banned words (XP, points, Godzilla, Redgull)", and passes on "A gift from Greenbull". (QA: pass / fail)
- [ ] `python game/tools/check_rebrand.py` gives the same report as on playtest/G-006 before this ticket: no flagged PNG, no loaded file named after the old brand, and no player-facing text with it. Both outputs are in the result notes. (QA: pass / fail)
- [ ] style_rules.py has no function, constant or flag named after the old brand (no is_redgull_red). BRAND_COLOURS, BRAND_THRESHOLD, OLD_LOGO_RED and HEART_COLOR keep the same values (shown in the result notes). (QA: pass / fail)
- [ ] No file is deleted without being moved: every file this ticket takes out of game/ is in art-archive/T-075/ or art-archive/T-306/. (QA: pass / fail)
- [ ] All three test sets pass: `python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"` and the GUT suite (`bash game/tools/run_tests.sh`). Their counts are in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-312.

### 2026-10-27, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done** (one commit, cdaff6d5; most of it staged by an earlier run of this ticket that was cut off before committing, reviewed and finished here). 0 PixelLab generations; no style loop (no art or player-facing text).

1. **Moves (git renames, nothing deleted):** `game/art/logo/redgull_logo_{128,64,32}.png` and their `.png.import` files to `art-archive/T-075/`; `game/tools/_t306_rename.py` to `art-archive/T-306/`. Done with the one-off `_t312_move.py` (run from game/tools, then it moved itself to `art-archive/T-312/` as this ticket's record). `git diff -M --name-status playtest/G-006 HEAD` shows all seven as R100; `--diff-filter=D` lists nothing. game/art/logo/ now holds only greenbull_emblem_{128,64,32}.png and greenbull_wordmark.png.
2. **One spelling:** `style_rules.OLD_BRAND = "Red" + "gull"` and `OLD_BRAND_DIR = OLD_BRAND.lower()` (the archive subfolder). Built from it: `BANNED_WORDS`, the `_P`/`_PF`/`_H` archive paths in BRAND_COLOURS, `check_rebrand.OLD_NAME` (name check, text check, the "file name contains '...'" detail), the tests (test_style_rules, test_check_rebrand, test_check_level_up_texts fixture row, test_check_logo_one_colour, test_build_level_up_art, test_build_boost_lines), make_logo_sizes' file names (output folder now defaults to art-archive/T-075/), and the archive folders in build_gift_package.py and build_helicopter.py.
3. **Renamed:** `is_redgull_red` → `is_old_brand_red` (style_rules, check_rebrand, check_level_up_shot, test_style_rules); `test_redgull_red` → `test_old_brand_red`, `test_flags_file_named_redgull` → `test_flags_file_named_after_old_brand`, `test_flags_redgull_text` → `test_flags_old_brand_text`. Bodies unchanged. New test `test_old_brand_values_unchanged` pins the values and checks no name in style_rules contains the old name.
4. **Record writers:** keys and strings built from the constant (build_boost_lines, build_buildings, build_drift_mark, build_drift_smoke, build_level_up_particles, build_health_canister, build_heart_icon, build_helicopter, build_kaiju_banners). Rebuilt `build_drift_mark build`, `build_drift_smoke build`, `build_heart_icon build`, `build_kaiju_banners build`, `build_level_up_particles build`, `build_helicopter build`, `build_health_canister`: `git status` shows no change under game/art or art-archive afterwards, so they write the records byte for byte. (boost_lines and buildings only build the key in their check report; the tests read it.)
5. **HISTORY tools** (make_logo_sizes, draw_gull_silhouette, flatten_logo, check_logo_one_colour, its test, list_brand_palette): docstrings and comments say "the old logo" / "the old sponsor".
6. **game/README.md:** "the old sponsor" / "the old logo (T-075)"; archive paths as folders (art-archive/T-304/, T-305/, T-075/); notes the T-312 move and `OLD_BRAND`.

**The diff** changes only names, comments and docstrings, strings built to the same value (`"Red" + "gull"`, `.lower()`), paths (the logo files' new folder) and file moves. `git diff playtest/G-006 HEAD -- game/art` shows only the six moved logo files; no .json record changed.

**Values kept** (style_rules.py): `OLD_LOGO_RED = (135, 17, 27)`, `HEART_COLOR = (219, 26, 41)`, `BRAND_THRESHOLD = 12`, `BRAND_COLOURS` the same 10 colours with the same source strings (paths built to the same text).

**What `git grep -i -l redgull -- game tools/style_loop` still finds** (copy block for the goal's notes):
```
game/art/pixellab-generation-log.jsonl: the PixelLab generation log, history of every paid call (the old logo's T-075 calls and briefs).
game/art/banners/banners.json: record of the kaiju alert signs (T-130), red_note quoting the rule of the time ("the only red outside <old sponsor>'s look").
game/art/effects/boost_lines.json: record of the boost lines sheet (T-009), check key closest_to_<old name>_red.
game/art/effects/drift_mark.json: record of the drift mark (T-118), rules string "no <old sponsor> red".
game/art/effects/drift_smoke_puff.json: record of the drift smoke puff (T-073), rules string "no <old sponsor> red".
game/art/effects/health_canister.json: record of the health canister (T-221), key min_distance_to_<old name>_red and a note on moving its red away from the old logo red.
game/art/effects/level_up_particles.json: record of the level-up particles (T-074), rules string "no <old sponsor> red".
game/art/gift_pack/helicopter_sheet.json: record of the helicopter sheet (T-305), "first built by T-145 in <old sponsor>'s" colours, key <old name>_red_pixels: 0.
game/art/hud/likes_heart.json: record of the likes heart (T-086), described as "flat <old sponsor> red" with the doc reference of the time.
```
`git grep -i -l redgull -- game/scripts game/scenes game/data` prints nothing.

**Checks:**
- `python game/tools/style_rules.py text "A gift from Redgull" --kind card_desc`: exit 1, rule 2 `"no banned words (XP, points, Godzilla, Redgull)"` ok false, "found: Redgull". On "A gift from Greenbull": rule 2 ok true, exit 0.
- `python game/tools/check_rebrand.py`, now: `loaded PNGs checked: 68` / `kept red (named in Visual style): 0` / `findings: 0` (exit 0). Before (playtest/G-006, as recorded in T-308's result notes; this ticket changes nothing under game/scripts, game/scenes, game/data or any loaded PNG): the same three lines.

**Tests:** game/tools `Ran 513 tests ... OK (skipped=1)`; tools `Ran 501 tests ... OK`; GUT (`bash game/tools/run_tests.sh`) `Tests 1420, Passing Tests 1420`, TESTS PASSED, exit 0.

**Screenshots:** none: tooling, docs and file moves only, nothing on screen changes.

**Uncommitted noise:** the GUT run left Godot's line-ending-only `.import` rewrites (about 180 files under game/) in the working tree. They are not committed. `git restore` is not on the pre-approved list, so the Project Lead or the runner should discard them.

**Refusals:** `git grep -i -o -n ".{0,60}redgull.{0,40}" -- game/art` needed approval (refused); not essential, used the Grep tool for the same read-only listing.

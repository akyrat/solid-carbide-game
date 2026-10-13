---
id: T-118
title: Art: the drift marks' tyre texture, drawn by script
status: in-qa
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, game/README.md, tasks/T-117-drift-marks.md, tasks/T-074-challenge-and-level-up-effects-art.md]
files_expected_to_change: [a drift mark drawing script and its test, the mark sprite(s) under game/art/ and their record, T-117's drift marks scene, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The final look of the drift marks (Visual style, Decisions, "Drift marks", 2026-10-13). T-117 builds the working marks with a plain placeholder line; this task draws the real texture and swaps it in.

**Branch:** create your branch `task/T-118-drift-marks-art` from T-117's branch (not from master), in your own folder `C:\solid-carbide-worktrees\T-118`, so the board playtests both from your folder. T-117 merges first, then this task.

**No PixelLab** (like the level-up particles, T-074): write a script that draws the mark texture: dark rubber tyre marks with a visible tread pattern, readable on both the dark asphalt and the dusty gravel, within Visual style, Decisions (no anti-aliasing, no semi-transparent pixels, transparent background, about 30 colours or fewer, night palette, not Redgull red). Make it tile cleanly along the length of a mark. Propose the colours, width and tread pattern, and any retuning of T-117's lifetime and fade, in the result notes.

Swap it into T-117's drift marks scene without changing when or how the marks are laid. Keep the script and its output: game-ready art under `game/art/`, with a short record; anything unused in `art-archive/T-118/`.

## Acceptance criteria

- [ ] A check script shows the new sprite(s) have a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The sprites are made by a committed script, with a test, and no PixelLab calls were made (QA: pass / fail)
- [ ] Screenshots of the car drifting on asphalt and on gravel show the marks with the new texture, tiling without visible seams (QA: pass / fail)
- [ ] T-117's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest drifting in a run and judge the marks (together with T-117).
Board review files: screenshots/T-118-drift-marks-asphalt-zoom.png, screenshots/T-118-drift-marks-gravel-zoom.png, art-archive/T-118/drift_mark_preview.png, art-archive/T-118/drift_mark_alt_open_grooves_preview.png

## Result notes

- 2026-10-13, open → blocked: waits for T-117
- 2026-10-13, blocked → open: builds on T-117's branch instead of waiting for its merge (as T-116 did on T-113)

Written by the Asset Generation Agent, 2026-10-13, on `task/T-118-drift-marks-art` (made from `task/T-117-drift-marks`) in `C:\solid-carbide-worktrees\T-118`. **No PixelLab calls** (none planned, none made; no spend).

**Made:** `game/art/effects/drift_mark.png`, an 8 x 8 tile drawn by `game/tools/build_drift_mark.py` (record `game/art/effects/drift_mark.json`), swapped into `game/scenes/driving/drift_marks.tscn` as `mark_texture` (an ext_resource replacing the placeholder's in-scene ImageTexture). The script code and when and where marks are laid are unchanged.

**Proposal:**
- **Colours (3, night-tinted rubber):** deep rubber (12, 10, 20) for the tread blocks, grooves (46, 43, 64), shoulders (27, 24, 40). Every colour is darker than the asphalt (48, 46, 62) and the gravel (99, 86, 107), sampled from the ground atlas. No red.
- **Width:** unchanged, `width_units` 0.25 (4 flat pixels, about one tyre). The 8 texels across give 32 texels per unit, the car and ground art's density.
- **Tread:** a chevron of 2-texel grooves pointing back along the mark, one chevron per 0.25 units, between two ragged shoulder rows. The shoulders' gaps are the transparent background. The rows inside the mark are opaque, so the mark never breaks at a tile join.
- **Retuning:** none proposed. Lifetime 6 s, fade 1 s, cap 800 and the tyre geometry stay as T-117 set them. `texture_mode` 1 (tile), `mark_color` white, root filter Nearest.

**How it reads (honest):** on the asphalt the mark reads clearly as a dark tyre track, and the chevrons are visible as a "zipper" texture along it. At the default window and zoom (1152 x 648) it can look a little busy or saw-toothed. On the gravel the mark stands out even more, but the tread mostly disappears into a dark line with ragged edges: the grooves are only about 2 screen pixels and are close in value to the darkest gravel. No seams: each `Line2D` piece restarts the pattern at its own start, so where two pieces join, one chevron can come out slightly short. In the screenshots this is not visible as a seam, and no gaps show. Cheapest next steps if the board wants changes (all free, script only): lighter grooves for more tread on gravel, open (transparent) grooves (the archived alternative), or no shoulder gaps for a smoother edge.

**Check script (criterion 1):** `python game/tools/build_drift_mark.py check`. Result: all rules pass: transparent corners, 0 semi-transparent pixels, 3 colours (limit 30), no Redgull red nor any red, rows inside the mark opaque, shoulder gaps at most 2 texels across the join, every colour darker than both grounds.

**Tests:** `game/tools/test_build_drift_mark.py` (16 tests: the rules, the palette, the chevron, failing cases, and that the committed PNG, record and archive previews are up to date) and `game/tests/unit/test_drift_marks_art.gd` (4 GUT tests: the scene uses the PNG tiled with repeat and nearest filtering, the PNG matches its record, a transparent background only in the shoulder rows with dark, non-red colours, and a run's marks use it).
- **One change to T-117's test:** `test_placeholder_is_nearest_opaque_dark_and_not_redgull_red` asserted every pixel was fully opaque (alpha 1). That conflicts with this task's transparent-background rule. It now asserts alpha 0 or 1 (no semi-transparent pixels) and checks darkness and red only on opaque pixels. Its 8 x 8 size limit and everything else are unchanged. All of T-117's 18 tests pass.
- **T-117's screenshot fixture** `drift_marks_demo.gd` gained a `start_units` export (default zero, so T-117's fixtures are unchanged). There are two new fixtures, `drift_marks_demo_asphalt.tscn` (car at (54, 0), on the road) and `drift_marks_demo_gravel.tscn`.

**Results:** full GUT suite 383 of 383 pass (`TESTS PASSED`, 39 scripts, 49753 asserts). Python tool tests: `game/tools` 141 tests OK, `tools` 115 tests OK. Godot's line-ending-only `.import` changes were reverted, not committed. `project.godot` was not touched.

**Screenshots** (git-ignored, in `C:\solid-carbide-worktrees\T-118\screenshots\`), from a run started from the main menu with the car driven by script (W, then W + D):
- `T-118-drift-marks-asphalt.png` (and `-zoom.png`, a 4x nearest crop): two tread marks curving behind the rear tyres on the asphalt.
- `T-118-drift-marks-gravel.png` (and `-zoom.png`): the same on the gravel.
Retake: `bash game/tools/screenshot.sh res://tests/fixtures/drift_marks_demo_asphalt.tscn screenshots/T-118-drift-marks-asphalt.png 150` (and `..._gravel.tscn`).

**Archived** (`art-archive/T-118/`, rows added to `art-archive/README.md`): `drift_mark_preview.png` (the tile repeated over both grounds, 8x), and the unused alternative with transparent grooves, `drift_mark_alt_open_grooves.png` with its preview. The T-117 placeholder lived only inside the scene file, so there was no file to archive.

**Documents updated:** `game/README.md` ("Drift marks": the look, the build and check commands, the new screenshots and tests; the tools row), `art-archive/README.md`, and my working copy `agent-notes/asset-generation.md`.

---
id: T-013
title: Simple placeholder car sprites in 16 directions, drawn by a script (no PixelLab)
status: done
from: project-lead
to: asset-generation
epic: art
milestone: mvp
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/drifting/unity-prototype-report.md, game/README.md]
files_expected_to_change: [the sprite-sheet generator script and its tests, the two placeholder sprite sheets with their record files, game/README.md]
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The Godot drift prototype (T-012) needs car sprites in 16 directions before full pixel art exists. The board wants them **as simple as possible**: plain rectangles with no pixel-art style, made quickly and for free. **Do not use PixelLab.** Draw them with a script.

**How the board's newer prototype did it** (checked by the Project Lead, read-only): `C:\solid-carbide-prototype-drifting\tools\generate_car_sheet.gd`, a Godot script run headless, draws each frame pixel by pixel with `Image.create` and saves a PNG with `save_png`. It did not use PixelLab. Read it for the approach if useful; that folder is read-only. If you find anything showing those images actually came from PixelLab, stop, set this task to `blocked`, and say why in the result notes, so the Project Lead brings it to the board.

**What to make:**

- **16 directions,** 22.5 degrees apart, for both views the drift prototype can switch between (T-012):
  - **Flat top-down:** the car as a plain rectangle seen from straight above.
  - **Isometric:** the same rectangle drawn in a standard 2:1 isometric projection. Keep it flat (no box height) unless the board asks otherwise.
- **As simple as possible:** a single solid colour for the body, plus one clearly different patch at the front (the nose), so the car's direction can be read at a glance. No shading, no detail, no outline beyond what the nose patch needs.
- **Size:** the car's footprint is 2:1 (length to width), for example 32 by 16 pixels, centred in a square frame large enough for every direction in both views.
- **Layout:** one sprite sheet per view, one row of 16 frames. Fix and document the convention the drift prototype will rely on: which direction frame 0 faces, which way the frames go round, the frame size, and the pixel that marks the car's centre. Write this as a small JSON file next to each sheet, so code can read it and a later full-art sheet (T-014) can drop in with the same layout.
- **The script** lives with the other game tools in `game/tools/`, is run headless with the T-001 runner, and gives byte-identical output when run twice. Document the command in `game/README.md`.
- **Record** each sheet like every generated asset: how it was made (the script and command, not a prompt), the settings, and that it is a placeholder.
- **Tests:** frame count and size, the nose patch facing the right way in a few chosen directions in both views, and identical output on a second run.

## Acceptance criteria

- [x] Two sprite sheets exist, one flat top-down and one isometric, each with exactly 16 frames of equal size, and Godot imports both without errors (QA: pass)
- [x] Each sheet has a JSON file next to it giving frame size, frame count, which direction frame 0 faces, the order of the frames, and the car's centre pixel (QA: pass)
- [x] Looking at both sheets, every frame shows a single-colour rectangle with a distinct nose, and the nose turns steadily by 22.5 degrees from frame to frame (QA: pass)
- [x] Running the generator script twice produces byte-identical sheets (QA: pass)
- [x] The script's tests pass, and the full GUT suite and all Python tool tests pass (QA: pass)
- [x] No PixelLab call was made: the PixelLab generation log has no new entries, and the result notes confirm it (QA: pass)
- [x] `game/README.md` documents how to regenerate the sheets (QA: pass)
- [x] `C:\solid-carbide-prototype-drifting` is unchanged: from inside that folder, in Git Bash, `find . -type f -not -path "./.godot/*" | sort | while read f; do sha256sum "$f"; done | sha256sum` prints `1778247395cd589804e00120f341b24cac138144b7cb1dea75e08c95850846de` (27 files, fingerprinted on 2026-10-07) (QA: pass)

## Result notes

**Asset Generation Agent, 2026-10-07.**

**What was built.** A headless Godot script draws two placeholder car sheets pixel by pixel. No PixelLab call was made (no API call of any kind): `game/art/pixellab-generation-log.jsonl` is unchanged (still 2 lines, both from T-003; sha256 `249f8105...93bd` before and after).

- `game/art/placeholders/car/car_flat.png`: flat top-down view, 1024 x 64.
- `game/art/placeholders/car/car_iso.png`: the same rectangle in a standard 2:1 isometric projection, screen = (x - y, (x + y) / 2), flat (no box height), 1024 x 64.
- The car is a 32 x 16 rectangle (2:1) in one solid blue (#2e86ff), with the front 8 pixels in yellow (#ffe600) as the nose. No outline, shading or anti-aliasing (a pixel is filled when its centre is inside the rectangle).
- `car_flat.json` and `car_iso.json` next to them: the layout (below), the nose's world heading and screen angle for every frame, and a `record`: made by script (no prompt), the script and command, the settings (sizes, colours, sampling), the task, the resources consulted, and `placeholder: true`. No generation time is stored, because the output is deterministic and the JSON should be byte-identical too.

**Frame and layout convention** (also in `game/README.md` and in each JSON):

- One row of 16 frames, each 64 x 64; frame `i` starts at x = `i * 64`.
- Frames are indexed by the car's heading in the flat physics world (Godot axes, y down). **Frame 0 = heading 0 degrees, nose along world +x** (pointing right in the flat view, down-right in the isometric view). **Each next frame adds 22.5 degrees, clockwise on screen**, the way Godot's `rotation` grows. For a car body whose nose is +x at rotation 0: `frame = posmod(roundi(rotation / deg_to_rad(22.5)), 16)`, the same formula for both views.
- **Car centre: the point (32, 32)** in frame pixel coordinates (top-left of the frame = 0, 0), the frame's middle. A `Sprite2D` with `centered = true`, `hframes = 16` and no offset puts the car's centre on the node's origin.
- Scale: 1 world pixel = 1 sprite pixel in the flat view; the isometric sheet projects the same world pixels.
- Note for criterion 3 and for T-012: in the isometric sheet the **world** heading turns by exactly 22.5 degrees per frame, so it matches the flat physics. Seen on screen, the isometric projection squashes the angles, so the nose's on-screen angle steps unevenly (for example 26.6, 50.4, 90, 129.6, 153.4 degrees for frames 0 to 4). The JSON lists the on-screen angle for every frame. If the board wants the isometric frames evenly spaced on screen instead, that is a different convention and needs a decision.

**How to regenerate** (from the repo root, headless, overwrites the four files and reimports them; byte-identical every run):

```
bash game/tools/generate_car_sheets.sh
powershell -ExecutionPolicy Bypass -File game/tools/generate_car_sheets.ps1
```

**Tests.** `game/tests/unit/test_car_sheets.gd` (9 tests): both sheets are 1024 x 64 (16 frames of 64 x 64) and Godot imports them; the JSON layout fields; every frame has only the body and nose colours, with a nose; flat frame 0 is exactly the expected 32 x 16 rectangle with the nose on the right; the nose faces the expected direction in chosen frames (flat 0, 2, 3, 4, 8, 12; isometric 0, 2, 4, 6, 10, 14); the nose's world heading is `i * 22.5` degrees (within 4) in all 16 frames of both sheets; the committed sheets and JSON layout match the generator; and two saves give byte-identical PNGs, identical to the committed files.

**Self-check per criterion:**

1. Two sheets, 16 equal frames each, Godot imports both without errors: yes (tests; the import shows no errors for them). The headless import prints a `SceneTreeTimer` "ObjectDB instances leaked at exit" warning, which comes from Godot's import run itself, not from these files.
2. JSON next to each sheet with frame size, count, frame 0 direction, order and centre pixel: yes (`frame_width`, `frame_height`, `frame_count`, `frame0_heading_deg` and `frame0_faces`, `step_deg`, `order`, `frame_from_rotation`, `center_px`).
3. Single-colour rectangle with a distinct nose, turning 22.5 degrees per frame: yes, checked by eye and by tests (see the isometric note above).
4. Running the generator twice gives byte-identical sheets: yes (sha256 of all six files identical after a Git Bash run and a PowerShell run, and the GUT test).
5. Script's tests, full GUT suite and Python tool tests pass: yes (GUT: TESTS PASSED, 5 scripts, 20 tests; Python: 45 tests OK).
6. No PixelLab call: confirmed, log unchanged.
7. `game/README.md` documents regeneration: yes, new section "Placeholder car sprite sheets".
8. Prototype folder unchanged: the fingerprint command prints `1778247395cd589804e00120f341b24cac138144b7cb1dea75e08c95850846de` (27 files). Its images came from its own `tools/generate_car_sheet.gd`; its `CLAUDE.md` mentions PixelLab only as a possible future drop-in, so nothing showed they came from PixelLab.

**Files created:** `game/tools/car_sheet_generator.gd` (+ `.uid`), `game/tools/generate_car_sheets.gd` (+ `.uid`), `game/tools/generate_car_sheets.sh`, `game/tools/generate_car_sheets.ps1`, `game/tests/unit/test_car_sheets.gd` (+ `.uid`), `game/art/placeholders/car/car_flat.png` (+ `.import`), `car_flat.json`, `car_iso.png` (+ `.import`), `car_iso.json`.
**Files changed:** `game/README.md` (folder table and new section), `agent-notes/asset-generation.md` (working notes), this task file.
**Documents affected:** none (`documents_affected` is empty; the Visual style document already records the placeholder decision).

**Problems.**
- On the worktree's first Godot import, Godot rewrote 33 committed `.import` files (GUT addon, test-run art and audio) with LF line endings. Their content is unchanged (same git blob hashes), so nothing was committed for them; `git add` cleared the false "modified" status.
- The commit "document the placeholder car sheets in game/README.md" also contains a small generator change (a clearer `frame0_faces` text per view) and the two regenerated JSON files.

### QA round 1

**QA/Integration Agent, 2026-10-07.** Checked from scratch in `C:\solid-carbide-worktrees\T-013`. All 8 criteria pass.

- **Sheets:** both PNGs are 1024 x 64 (RGBA), so 16 frames of 64 x 64. `--import` on the worktree prints no error (only Godot's usual "ObjectDB instances leaked at exit" warning). Both `.ctex` files are in `.godot/imported`, and the GUT test `test_godot_imports_sheets` passes.
- **JSON:** both files give `frame_width`/`frame_height` 64, `frame_count` 16, `frame0_heading_deg` 0 with `frame0_faces`, `order` (clockwise, i * 22.5), `step_deg` 22.5, `center_px` (32, 32), `frame_from_rotation`, plus a `record` with `made_by: script (no PixelLab, no prompt)` and `placeholder: true`.
- **Visual and measured:** I enlarged both sheets and looked at them. Every frame has exactly two colours (#2e86ff body, #ffe600 nose) with a clear nose. My own script measured the direction from the body centroid to the nose centroid. Flat sheet: 0, 22.6, 45, 67.4, ... 337.4 degrees on screen, steps of 22.5 within rounding. Isometric sheet, after un-projecting with screen = (x - y, (x + y) / 2): world headings 0, 22.8, 45, 67.2, ... 337.6 degrees, steps of 22.5 within rounding. Every frame's centroid is at the frame's middle.
- **Determinism:** I ran `bash game/tools/generate_car_sheets.sh` twice (exit 0 both times). The sha256 of all six files in `game/art/placeholders/car/` was identical before, after the first run and after the second, and `git status` stayed clean.
- **Tests:** `bash game/tools/run_tests.sh` gave TESTS PASSED (5 scripts, 20 tests, including 9/9 in `test_car_sheets.gd`), exit 0. `python -m unittest discover -s game/tools -p "test_*.py"`: 45 tests OK. Root `tools/` (`-s tools`): 42 tests OK.
- **PixelLab:** `git diff master -- game/art/pixellab-generation-log.jsonl` is empty and the log has 2 lines. In the prototype folder, PixelLab is mentioned only in its `CLAUDE.md`, as possible future drop-in art.
- **README:** `game/README.md` has a section "Placeholder car sprite sheets" with the Git Bash and PowerShell regenerate commands, the output files and the layout.
- **Prototype folder:** the fingerprint command printed `1778247395cd589804e00120f341b24cac138144b7cb1dea75e08c95850846de` (27 files).

**Observations for the Project Lead.**
- **Criterion 3 wording, isometric sheet:** the nose turns by 22.5 degrees per frame in **world** heading, not on screen. On screen the steps are uneven: about 24, 40, 40, 24, 15, 12 degrees, repeating. On screen the isometric car is a parallelogram whose shape changes per frame (a near-square at world 45 and 225, a long rectangle at 135 and 315). This is the correct projection of a flat rectangle and matches the flat physics, so I passed the criterion. But the task's literal wording "turns steadily by 22.5 degrees" holds on screen only for the flat sheet. If the board wants evenly spaced on-screen angles in the isometric view, that is a different convention and needs a decision. This affects T-014 too.
- **Diff against `master`:** `git diff master --stat` also shows deletions in `docs/drifting.md` and `docs/timeline.md`. These only appear because `master` moved on after the branch was made (commit e66712a). `git diff master...HEAD` shows the branch does not touch `docs/`.

### Board review

2026-10-07: the board reviewed the sheets and marked the task `done`. The isometric sheet keeps even 22.5-degree steps in world heading (uneven on screen); the board did not ask for a change.

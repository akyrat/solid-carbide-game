---
id: T-013
title: Simple placeholder car sprites in 16 directions, drawn by a script (no PixelLab)
status: in-progress
from: project-lead
to: asset-generation
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/drifting/unity-prototype-report.md, game/README.md]
files_expected_to_change: [the sprite-sheet generator script and its tests, the two placeholder sprite sheets with their record files, game/README.md]
qa_rounds: 0
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

- [ ] Two sprite sheets exist, one flat top-down and one isometric, each with exactly 16 frames of equal size, and Godot imports both without errors (QA: pass / fail)
- [ ] Each sheet has a JSON file next to it giving frame size, frame count, which direction frame 0 faces, the order of the frames, and the car's centre pixel (QA: pass / fail)
- [ ] Looking at both sheets, every frame shows a single-colour rectangle with a distinct nose, and the nose turns steadily by 22.5 degrees from frame to frame (QA: pass / fail)
- [ ] Running the generator script twice produces byte-identical sheets (QA: pass / fail)
- [ ] The script's tests pass, and the full GUT suite and all Python tool tests pass (QA: pass / fail)
- [ ] No PixelLab call was made: the PixelLab generation log has no new entries, and the result notes confirm it (QA: pass / fail)
- [ ] `game/README.md` documents how to regenerate the sheets (QA: pass / fail)
- [ ] `C:\solid-carbide-prototype-drifting` is unchanged: from inside that folder, in Git Bash, `find . -type f -not -path "./.godot/*" | sort | while read f; do sha256sum "$f"; done | sha256sum` prints `1778247395cd589804e00120f341b24cac138144b7cb1dea75e08c95850846de` (27 files, fingerprinted on 2026-10-07) (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

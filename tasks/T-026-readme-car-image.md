---
id: T-026
title: Car image at the top right of the root README
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-101]
documents_affected: [README.md]
files_to_read_first: [tasks/README.md, README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-014-car-sprites-16-directions.md, tasks/T-101-car-sprites-remaining-directions.md]
files_expected_to_change: [README.md, the README image file and its record]
model: sonnet
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-101 (the final car in all 16 directions) is done:** the image must be the final car art, not the placeholder.

The board wants the final car shown at the top right of the root `README.md`. Take one good frame of the final 16-direction car from T-101 (for example a 3/4 front view), save it as an image for the README (for example `docs/readme/car.png`, scaled up by a whole number with nearest-neighbour so the pixels stay sharp; never smoothed), and place it at the top right of the README. Plain Markdown can't float an image, so use a small right-aligned HTML `<img>` tag (for example `<img src="docs/readme/car.png" align="right" width="...">`) at the top of the file, before or beside the title.

**Settled with the board in planning (2026-10-13):**

- **Frame:** the board's first approved sprite, front to the bottom-left (3/4 front view): `game/art/car/car_sw_front.png`, the same as frame 4 of `game/art/car/car_iso.png`.
- **Shadow:** keep it, as approved. No shadow removal.
- **Size:** the 128 by 128 frame scaled up exactly 2 times with nearest-neighbour, to 256 by 256, saved as `docs/readme/car.png`, and shown at 256 px wide (`width="256"`).
- **Review:** the board looks at the README in VS Code's Markdown preview of this task's folder (GitHub shows it only after the board pushes). The agent also saves a screenshot of the rendered top of the README in the task folder and lists it under "Board review files".

No new generation: reuse a T-101 frame, so no PixelLab calls. Record where the image came from (which T-101 sheet and frame, the scale factor) next to it, as for every asset.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The README image file exists, and its record names the T-101 sheet and frame it came from and the scale factor (QA: pass / fail)
- [ ] The image is the final car (T-101), not the placeholder: its pixels match the named frame scaled by the recorded whole number (QA: pass / fail)
- [ ] The top of `README.md` has a right-aligned `<img>` tag pointing to the image, and the path resolves (QA: pass / fail)
- [ ] Rendered on GitHub (or in a Markdown preview), the image sits at the top right without hiding the title or the first lines (QA: pass / fail, with a screenshot or description)
- [ ] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` is unchanged (QA: pass / fail)

The board's review: look at the top of the README in VS Code's Markdown preview of `C:\solid-carbide-worktrees\T-026\README.md`, or the agent's screenshot.

## Result notes

Board review files: README.md, T-026-readme-top.png

Made (Sonnet, no PixelLab call; `game/art/pixellab-generation-log.jsonl` untouched):

- `docs/readme/car.png`: 256 x 256 RGBA, `game/art/car/car_sw_front.png` scaled exactly 2x nearest-neighbour, shadow kept.
- `docs/readme/car.md`: the record (source = `car_sw_front.png`, which is frame 4 counting from 0 of `game/art/car/car_iso.png`; scale 2x).
- `tools/make_readme_car.py`: the scaling script. `tools/test_make_readme_car.py`: its test.
- `README.md`: `<img src="docs/readme/car.png" align="right" width="256" ...>` added as the first line, before the title.
- `T-026-readme-top.png`: screenshot of the README's Markdown rendered to HTML (headless Chrome, 1000 x 600). The car sits at the top right, title and first lines fully visible, text wraps beside it.

Checked: `python -m unittest tools/test_make_readme_car.py` passes (3 tests: exact 2x nearest scaling on a synthetic image, committed `car.png` pixel-identical to the source frame scaled 2x, source frame identical to frame 4 of the sheet). The `<img>` path resolves (the screenshot shows the image).

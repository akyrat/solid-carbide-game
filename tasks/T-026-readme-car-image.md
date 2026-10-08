---
id: T-026
title: Car image at the top right of the root README
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-014]
documents_affected: [README.md]
files_to_read_first: [tasks/README.md, README.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-014-car-sprites-16-directions.md]
files_expected_to_change: [README.md, the README image file and its record]
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

**Blocked until T-014 is done:** the image must be the final car art, not the placeholder.

The board wants the final car shown at the top right of the root `README.md`. Take one good frame of the final 16-direction car from T-014 (for example a 3/4 front view), save it as an image for the README (for example `docs/readme/car.png`, scaled up by a whole number with nearest-neighbour so the pixels stay sharp; never smoothed), and place it at the top right of the README. Plain Markdown can't float an image, so use a small right-aligned HTML `<img>` tag (for example `<img src="docs/readme/car.png" align="right" width="...">`) at the top of the file, before or beside the title.

No new generation: reuse the T-014 frame, so no PixelLab calls. Record where the image came from (which T-014 sheet and frame, the scale factor) next to it, as for every asset.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The README image file exists, and its record names the T-014 sheet and frame it came from and the scale factor (QA: pass / fail)
- [ ] The image is the final T-014 car, not the placeholder: its pixels match the named T-014 frame scaled by the recorded whole number (QA: pass / fail)
- [ ] The top of `README.md` has a right-aligned `<img>` tag pointing to the image, and the path resolves (QA: pass / fail)
- [ ] Rendered on GitHub (or in a Markdown preview), the image sits at the top right without hiding the title or the first lines (QA: pass / fail, with a screenshot or description)
- [ ] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` is unchanged (QA: pass / fail)

The board's review: look at the README.

## Result notes

Written by the agent when it finishes.

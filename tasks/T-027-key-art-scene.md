---
id: T-027
title: Key-art scene graphic for the README and pitch material
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: final-release
user_facing_text: no
changes_visuals: yes
depends_on: [T-014]
documents_affected: [README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/enemies.md, docs/level-design.md, tasks/T-014-car-sprites-16-directions.md, tasks/T-003-pixellab-test-generation.md]
files_expected_to_change: [the key-art image and its record, README.md]
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

**Final release. Blocked until T-014 (the final car) is done, and until the minion's and the kaiju's final art exist** (those art tasks are not written yet; when they are, the Project Lead adds them to `depends_on`), so the scene matches the real assets.

A promotional key-art scene, not a screenshot: the dark-green, Mustang-style car with white stripes drifting through the neon, Tokyo-style city at night, green lizard minions closing in, and the Godzilla-style kaiju in its green shield in the background (all as Visual style, Decisions describes them).

- Made with PixelLab in the agreed pixel style and palette, following Visual style's rules, including **no real logos or badges and no exact copies of existing characters**. Use the existing client, `game/tools/pixellab_client.py`; check PixelLab's current tools first (for example image generation with style references, using the final car, minion and kaiju art as references).
- **One round of generation only**, as for every asset: record every call with its cost, the balance before and after, and do not regenerate; report problems instead. The board judges the result.
- **Where it's used:** under the title in the root `README.md` (place it there, sized to fit), and later the short GDD and other pitch material (the Project Lead adds it to those).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

To be finalised when the task is unblocked. They will cover: the image and its record (prompts, references, settings, every call with its cost, balance before and after), one round of generation, the README showing it under the title, and the art following Visual style (palette, pixel style, no real logos).

## Result notes

Written by the agent when it finishes.

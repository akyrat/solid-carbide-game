---
id: T-020
title: Research: buildings turn see-through when the car is behind them
status: open
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/visual-style.md, docs/level-design.md, docs/drifting.md, game/README.md, docs/extended-narrative.md]
files_expected_to_change: [a research report under docs/visual-style/, a small test scene and script under game/, their tests, screenshots under docs/visual-style/, docs/visual-style.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board decided that when the car drives behind a building, the building turns see-through so the car stays visible (Visual style, Decisions), and asked for someone to look into how. The map is the Level/Challenge Design Agent's, so this research is too. It builds a small demonstration, not the real map.

1. Look into how this is usually done in Godot 4.6 for a 2D isometric game: for example, fading a building's sprite whenever it covers the car on screen, using the car's and the building's screen rectangles or sorting order, an `Area2D` behind each building, or a shader with a cut-out around the car. Compare at least two approaches: how they look, how hard they are to build, and how they behave with many buildings.
2. Build a small test scene in `game/` with the tools from T-001: a flat ground, a few placeholder building blocks drawn isometrically (plain coloured boxes; no PixelLab), and a stand-in for the car (the T-013/T-018 placeholder sprite is fine) that can be moved with the keyboard. Implement the approach you recommend.
3. Write tests for what can be tested (for example, that a building fades when the car is behind it and returns when it leaves), and take screenshots with the T-001 screenshot tool: the car in front of a building, and behind it with the building see-through.
4. Write a short report, `docs/visual-style/see-through-buildings.md`: the approaches compared, the recommendation and why, its limits, and what the real map (built later) needs to do to use it. Open questions for the board go at the end.
5. In `docs/visual-style.md`, add the report to References and a factual note under Content. Do not change Summary, Decisions or Open questions (the Project Lead records what the board decides). Follow `docs/README.md`.

Do not decide the final look (how transparent, how fast the fade is): show options in the screenshots and let the board choose.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] `docs/visual-style/see-through-buildings.md` compares at least two approaches and recommends one, with its limits and open questions (QA: pass / fail)
- [ ] The test scene runs headless without errors, and a test shows a building fading when the car is behind it and returning to normal when the car leaves (QA: pass / fail)
- [ ] Screenshots of the car in front of a building and behind a see-through building exist under `docs/visual-style/` and are linked from the report (QA: pass / fail)
- [ ] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` is unchanged (QA: pass / fail)
- [ ] `docs/visual-style.md` links the report in References and still follows the five-section structure; its Summary, Decisions and Open questions are unchanged (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: look at the screenshots and choose the look.

## Result notes

Written by the agent when it finishes.

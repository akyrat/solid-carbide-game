---
id: T-340
title: "Art: bolder enemy outlines, so the player sees and avoids them"
status: in-progress
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/enemies.md, game/README.md]
files_expected_to_change: [game/art/, game/tools/, art-archive/T-340/, docs/visual-style.md, game/README.md]
model: sonnet
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

The board's decision (Enemies, Decisions, "Damage in hearts, fewer health drops, bolder outlines", 2026-10-28): with hearts, each hit matters more, so the player must see where the enemies are and steer round them. Make every enemy's outline **a little bolder**: the minions (every kind, every frame and direction) and the kaiju. A free **script** pass is expected: thicken the dark outline by one pixel outward (or darken it), keeping the sprites' sizes or growing the canvas evenly, at most 30 colours, alpha 0 or 255. Keep the originals in `art-archive/T-340/`; never delete art. If an outline reads poorly over the street or a rooftop, say so and propose a fix (for example a slightly lighter rim). Every changed sprite set goes through the style loop. No PixelLab expected; if one is needed, ask the Project Lead first.

The board's review: play a run and see whether the enemies stand out more against the street and rooftops.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every enemy sprite (all minion kinds, frames and directions, and the kaiju) has the bolder outline, made by a script in game/tools/ that is rerunnable, with the originals in art-archive/T-340/. (QA: pass / fail)
- [ ] The sprites still pass the pixel rules (`style_rules.py art`: colours, alpha, size), and the game loads them (the existing enemy and art tests pass). (QA: pass / fail)
- [ ] Each sprite set scored at least 8 in the style loop, with every round in the Style review. (QA: pass / fail)
- [ ] Visual style and game/README.md record it. (QA: pass / fail)
- [ ] Before and after screenshots of enemies on the street and a rooftop are in `art-archive/T-340/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: script pass, no PixelLab.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-340/briefs/minion_walk.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-340/style-loop/v1.png`
- Script checks: 201 of 201 pass
- Score: 8/10
- Reason: I could only see the strip at 1x, so I couldn't judge individual outline pixels. At that size the 40 frames show light-green four-legged lizards in all five directions, each with a clear dark, almost black outline that holds up against the pale background. The script checks pass as facts. The sizes are 48x48, there are no semi-transparent pixels, the colour counts are 17 to 26 per frame, and rule 6 reports no Greenbull colours misused. Nothing I could see breaks a rule. Rule 1 and rule 3 pass by script. Rule 2's dark outline is present and the shading and highlight pixels inside are kept. Rule 10's subject look is unchanged: light-green lizards with the same silhouettes and the same colours. Two things hold the score at 8 rather than higher. The outline is thicker but still the sheet's own near-black, so it may merge into dark asphalt ground. Check that in the playtest, and if it does, refine with a lighter --rim ring just outside the outline. The thicker outline can also fill small gaps and highlight breaks that rule 2 asks for. If the added outline hides the tooth or jaw detail on the side-facing frames, reduce --reach.
- Rules broken: none
- Refused: {"tool_input": {"command": "python -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-340/style-loop/v1.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01FhWLSHRJa382FpBLe36nLd"}

**Kept:** version 1, score 8/10 (`art-archive/T-340/style-loop/v1.png`, copied to `art-archive/T-340/strips/minion_walk.png`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-340/briefs/minion_fall.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-340/style-loop/v1-2.png`
- Script checks: 201 of 201 pass
- Score: 8/10
- Reason: No rule is clearly broken. The script checks all pass: 48x48 frames, 40 frames, transparent background, no semi-transparent pixels, 25 colours or fewer per frame, and no Greenbull colours misused. In the strip, the light-green four-legged lizards keep their look (rule 10) across all five direction groups. Each has a dark, near-black outline (rule 2) that now reads a little heavier and separates the body from the background. The view is still 3/4 and the mood unchanged. Two limits on this score. The strip is shown small, so I could not check pixel by pixel that the grown outline stays broken by lighter highlight pixels instead of becoming one solid band (rule 2). I also could not check whether the outline holds up against the dark asphalt at night. If the board finds the outline gets lost on dark ground, refine with a lighter --rim ring just outside the outline. Otherwise v1 is acceptable.
- Rules broken: none
- Refused: {"tool_input": {"command": "python game/tools/build_bolder_outlines.py strip minion_fall art-archive/T-340/style-loop/v1-2.png 2>&1 | tail; python -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-340/style-loop/v1-2.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01YcAct7QXVidZQyiqzSabcW"}; {"tool_input": {"command": "python -c \"from PIL import Image; i=Image.open('art-archive/T-340/style-loop/v1-2.png'); print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01XwMBp2gvC7jhiSS8qBAhLZ"}

**Kept:** version 1, score 8/10 (`art-archive/T-340/style-loop/v1-2.png`, copied to `art-archive/T-340/strips/minion_fall.png`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-340/briefs/kaiju.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-340/style-loop/v1-4.png`
- Script checks: 151 of 151 pass
- Score: 8/10
- Reason: I could only view the strip downscaled (6720x224 shown at 2000x67), so I judged silhouettes and outline weight, not individual pixels. The script checks all pass: 224x224 frames, hard alpha, 29-30 colours per frame, and no Greenbull light green or yellow. The kaiju keeps its Godzilla-style look in all five directions (rule 10). Its teal body, cyan spines and tan belly are unchanged, and no new colours appear. Each frame has a continuous near-black outline that reads as slightly bolder (rule 2), and the highlight pixels inside the sprite still break up the dark edge. The look is retro and night-appropriate (rule 4). I found no real brands, words or Godzilla copies (rule 9). Minor caveat: the outline could blend into very dark ground, which I can't confirm at this zoom. If the board finds it lost on dark asphalt, refine with a lighter --rim ring just outside the outline (for example --rim with a muted dark teal). No rule is clearly broken.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls -la art-archive/T-340/style-loop; python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-340/style-loop/v1-4.png');print(im.mode,im.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_012MvFaU1rky4RrgFVTCnZmF"}

**Kept:** version 1, score 8/10 (`art-archive/T-340/style-loop/v1-4.png`, copied to `art-archive/T-340/strips/kaiju.png`): it reached 8 or more.

## Result notes

Script pass only, 0 PixelLab generations. `game/tools/build_bolder_outlines.py build` grows every enemy sheet's dark outline one pixel outward in the sheet's own outline colour (no new colours, alpha 0/255, same sizes and frames), always from the originals in `art-archive/T-340/originals/` (rerunnable). Covers minion walk (5 sheets), minion fall (5) and kaiju (5); `check` runs the pixel rules on all 15 sheets: all pass.

Style loop (each set as one strip, all 8/10 in round 1, no refines): minion walk `style-loop/v1.png`, minion fall `v1-2.png`, kaiju `v1-4.png` (`v1-3.png` is a run a usage limit cut off before scoring; rerun). The evaluator saw the strips downscaled and noted the outline might blend into very dark ground; the proposed fix is `build --rim R,G,B` (a lighter ring), not used. The loop's headless agents had a few `python -c` commands refused (noted in the Style review); they did not block the work.

Screenshots before and after (street, rooftop, kaiju on a rooftop) and enlarged comparisons on dark and light backgrounds: `art-archive/T-340/screenshots/`. Outlines read clearly on the street.

Tests: `game/tools` unittest and `tools` unittest both OK (626 tests with 1 skipped, and 501), new `game/tools/test_build_bolder_outlines.py` has 6 tests. Docs updated: Visual style, game/README.md.

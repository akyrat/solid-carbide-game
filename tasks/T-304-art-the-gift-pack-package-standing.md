---
id: T-304
title: Art: the gift pack package, standing and falling, in Greenbull's colours
status: in-qa
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-144, T-300, T-299]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/game-loop-architecture.md, docs/working-with-the-board.md, game/README.md, tasks/T-144-gift-pack-drop.md, tasks/T-146-art-redgull-gift-pack-package.md, game/tools/build_gift_package.py, game/tools/test_build_gift_package.py, game/art/gift_pack/, game/art/logo/]
files_expected_to_change: [game/art/gift_pack/package.png, game/art/gift_pack/package_falling.png, game/tools/build_gift_package.py, game/tools/test_build_gift_package.py, art-archive/, docs/visual-style.md, game/README.md]
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

The gift pack package (T-146; dropped by T-144's helicopter) is in Redgull's colours with its gull logo. Rebuild game/art/gift_pack/package.png and package_falling.png in Greenbull's colours (Visual style, Decisions, 'The rebrand', 'Greenbull's look', 'Red after the rebrand'; rule 6), with Greenbull's emblem from game/art/logo/ (D3) in place of the gull. build_gift_package.py first (a free recolour and restamp); PixelLab only where a recolour can't do it, each call listed with its reason and count in the result notes before calling, up to 12 generations per asset within the goal's art cap. Both go through the style loop with --greenbull. Keep file names and sizes so gift_package.tscn loads them unchanged. Keep the old versions in art-archive/<this ticket>/. Update Visual style and game/README.md, 'The gift pack drop', where they describe the package. In-run screenshots of the package falling and landed in art-archive/<this ticket>/screenshots/.

The board's review: play a run to a gift pack drop: the package, falling and landed, in Greenbull's colours with its emblem.

## Acceptance criteria

- [ ] game/art/gift_pack/package.png and package_falling.png are rebuilt in Greenbull's colours with Greenbull's emblem from game/art/logo/ and no gull, keeping their file names and sizes. (QA: pass / fail)
- [ ] Neither has a pixel the Redgull red check (style_rules.is_redgull_red, or its renamed successor) flags (output in the result notes). (QA: pass / fail)
- [ ] build_gift_package.py rebuilds them by script; any PixelLab call is listed in the result notes with its reason and count, within 12 generations per asset. (QA: pass / fail)
- [ ] Both pass `python game/tools/style_rules.py art <file> --greenbull` and have a style loop record in the ticket's Style review. (QA: pass / fail)
- [ ] The old package.png and package_falling.png are in art-archive/<this ticket>/. (QA: pass / fail)
- [ ] test_build_gift_package.py (and test_build_gift_placeholders.py, if it covers the package) pass, as does test_gift_drops.gd. (QA: pass / fail)
- [ ] In-run screenshots of the package falling and landed are in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-304.

### 2026-10-27, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-304/briefs/package.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-304/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The script checks pass: 64x64, 26 colours, no semi-transparent pixels, transparent background, and a Greenbull-owned piece.

Looking at the image, it is a dark-green gift box with a light-green ribbon and bow, standing on the bottom row. The shading comes from the PixelLab box, and the outline is dark and selective. It shows a 3/4 view with the top and one side. The right face carries a pale tag with a small bull emblem. There is no gull and no red. That satisfies rules 1, 2, 3, 6 and 9.

Weak points, none serious:
- Rule 2: the 16 px emblem on the pale tag is small and reads as a muddy mark at this size. Check that the bull's head silhouette is clear and that the tag has a dark outline matching the box's.
- Rule 4: the pale tag is the brightest area. If it looks flat or too bright for a night scene, drop it one shade toward a light-green or grey-green tint.
- Rule 2: confirm the highlight pixels still break the outline on the top and left edges after the recolour.

Fixes are optional polish.
- Rules broken: none
- Refused: {"tool_input": {"command": "git status --short; mkdir -p art-archive/T-304/style-loop && python game/tools/build_gift_package.py piece package \"C:/solid-carbide-worktrees/T-304/art-archive/T-304/style-loop/v1.png\" && python -c \"\nfrom PIL import Image\nim=Image.open(r'C:/solid-carbide-worktrees/T-304/art-archive/T-304/style-loop/v1.png');print(im.mode,im.size,len(set(im.getdata())),sorted({p[3] for p in im.getdata()}),im.getbbox())\nim.resize((512,512),Image.NEAREST).save(r'C:/solid-carbide-worktrees/T-304/art-archive/T-304/style-loop/v1_preview_8x.png')\"", "description": "Build version 1 and check its properties"}, "tool_name": "Bash", "tool_use_id": "toolu_01FwAck78Rz6JLGDw1q6huPt"}

**Kept:** version 1, score 8/10 (`art-archive/T-304/style-loop/v1.png`, copied to `game/art/gift_pack/package.png`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-304/briefs/package_falling.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-304/style-loop/v1-2.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: I could only see the image at its native 64x96 size, so the finer details below are judged at that size.

Rule 1: the script checks pass (28 colours, alpha 0 or 255 only, transparent background), and the edges look hard.
Rule 2: the near-black green outline is there. The box has lit and shaded faces and a lighter ribbon, and the canopy has a darker lower edge. Nothing needs fixing here.
Rule 3: the size is 64x96 and the box keeps the 3/4 view with its top and one side visible.
Rule 4: the dark green dominates and the look is retro. The cream gores are the brightest part of the sprite, and against the night city they may read a little bright. This is a minor point. If it is refined further, a slightly darker or warmer cream would sit better at night.
Rule 6: the dark green leads, and the light green and cream appear only on Greenbull's own things. There is no red.
Rule 9: the emblem on the pale tag is tiny. At this size I can't confirm it reads as a bull and not a gull, so check that the 16 px stamp keeps the bull's horns clear. Nothing else here conflicts with the rules.

Overall this is a clean, on-style piece. I found no rule broken.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls art-archive/T-304/style-loop/ 2>&1; python game/tools/build_gift_package.py piece package_falling art-archive/T-304/style-loop/v1-2.png && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-304/style-loop/v1-2.png');print(im.mode,im.size)\npx=list(im.getdata());print(len(set(px)),'colours',set(p[3] for p in px))\nprint('reddish',sum(1 for r,g,b,a in px if a and r>g+40 and r>b+40))\n\""}, "tool_name": "Bash", "tool_use_id": "toolu_01P3DL63oSEd2o1G8Eu94yuY"}

**Kept:** version 1, score 8/10 (`art-archive/T-304/style-loop/v1-2.png`, copied to `game/art/gift_pack/package_falling.png`): it reached 8 or more.

## Result notes

Written by the agent when it finishes.

**Planned PixelLab calls: none.** A recolour and restamp by script does everything, so no PixelLab call was planned or made. **0 generations used**, for both assets (cap 12 per asset).

**What was done (2026-10-27, asset-generation):**
- Kept the old versions: `python game/tools/build_gift_package.py archive` copied the Redgull `package.png` and `package_falling.png` to `art-archive/T-304/redgull/`, before the rebuild.
- Rebuilt `game/tools/build_gift_package.py`:
  - It reuses the level-up screen's gift box recolour (`build_level_up_art.recolour_box`, T-303) on T-140's PixelLab box (`art-archive/T-146/gift_box_from_T-140_raw.png`, read only). That gives a dark green box led by Greenbull's RGB 12, 76, 44 and a light green ribbon and bow, so the drop matches the level-up screen again.
  - The box is scaled to 40 px wide as before.
  - Greenbull's emblem (`game/art/logo/greenbull_emblem_32.png`) is scaled to 16 px, snapped to the emblem's own five colours, and stamped on a pale tag with a near-black green outline on the right face, where the gull was.
  - The parachute is drawn in dark green and cream gores, lit on the left, with a darkest green lower edge and pale cords.
  - New commands: `piece package|package_falling <png>` (the style loop's step) and `archive`. `check` now also counts Redgull red pixels.
- File names and sizes are unchanged (package.png 64 x 64, package_falling.png 64 x 96, bottom row on the ground), so `gift_package.tscn` and `gift_package.gd` load them unchanged. No scene or code change.
- Both were made through the style loop with `--greenbull` (Style review above, Runs 1 and 2). Both were kept at **8/10** in round 1, with no refines.
- The evaluator's optional polish, not done because the loop stopped at 8: the 16 px emblem is small on the tag and reads as a dark mark more than a clear bull's head. The cream tag and gores are the brightest parts of the sprite. The emblem's yellow is lost at 16 px, so the package has no yellow. Left for the board's playtest.

**Redgull red check** (`python game/tools/build_gift_package.py check`, which uses `style_rules.is_redgull_red` on every opaque pixel):
```
package.png: (64, 64), 26 colours, alpha [0, 255], Redgull red pixels: 0
package_falling.png: (64, 96), 28 colours, alpha [0, 255], Redgull red pixels: 0
```
`python game/tools/style_rules.py art game/art/gift_pack/package.png --greenbull --size 64x64` and `... package_falling.png --greenbull --size 64x96`: all 6 checks pass on each (rules 1, 3 and 6).

**Tests:**
- `game/tools/test_build_gift_package.py`: 8 tests, all OK. It checks the build, sizes and bottom row, no Redgull red, that Greenbull's colours lead with the dark green present, that the emblem is stamped in its own colours, hard alpha, that the piece output matches the build, and that the build is deterministic. `test_build_gift_placeholders.py` doesn't cover the package files.
- All three test sets pass:
  - GUT: 1419/1419, `test_gift_drops.gd` included.
  - game/tools Python: 483 OK, 1 skipped.
  - tools/ Python: 501 OK.

**Screenshots** (in-run, `bash game/tools/screenshot.sh res://tests/fixtures/gift_drop_default_zoom_down_demo.tscn ...`, in `art-archive/T-304/screenshots/`):
- `drop_down_350.png`, `drop_down_550.png`: falling under the green parachute below the helicopter.
- `drop_down_800.png`: landed ahead of the car.
- `drop_down_150.png`, `drop_down_175.png`, `drop_down_200.png`, `drop_down_250.png`: carried under the helicopter as it flies in.
- `package_x6.png`, `package_falling_x6.png`: both sprites enlarged 6x on a dark and a light background.
- The helicopter is still in Redgull red in these shots; that is not this ticket's file.

**Other files:**
- Style loop briefs: `art-archive/T-304/briefs/package.md`, `package_falling.md`.
- Loop versions: `art-archive/T-304/style-loop/v1.png` (package), `v1-2.png` (falling).
- Early draft: `art-archive/T-304/draft_falling.png` and its `_x6` preview.

**Documents updated:**
- `docs/visual-style.md`: Decisions, new entry "The gift pack package in Greenbull's colours".
- `game/README.md`: "The gift pack drop", the art swap paragraph.

**Refusals:**
- During the style loop, the generator agent's first chained shell commands were refused once in each run: a `git status; mkdir ... && python ... && python -c ...` chain in Run 1, and an `ls ...; python ... && python -c ...` chain in Run 2. They are listed in the Style review. They weren't essential: the version was still built with the plain `piece` command.
- Not done: Godot's line-ending-only `.import` changes from the test and screenshot runs are left uncommitted, as the rules say. Reverting them needs `git checkout`, which isn't pre-approved.

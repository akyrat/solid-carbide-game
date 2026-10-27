---
id: T-311
title: Art: the level-up ribbon (and frames if needed) with dark green leading, checked on a screenshot from the main menu
status: needs-playtest
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-309, T-310]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/README.md, tasks/T-303-art-the-level-up-screen-in.md, game/tools/build_level_up_art.py, game/tools/test_build_level_up_art.py, game/tools/check_level_up_shot.py, game/tools/style_rules.py, game/scripts/ui/level_up_screen.gd, game/art/level_up/, art-archive/T-307/screenshots/level_up_screen.png]
files_expected_to_change: [game/art/level_up/, game/tools/build_level_up_art.py, game/tools/test_build_level_up_art.py, art-archive/, docs/visual-style.md, game/README.md]
model: opus
qa_rounds: 1
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

T-303 remade the level-up screen in Greenbull's colours, but light green leads. The header ribbon's large centre field is light green RGB 104, 220, 96. The goal check needs Greenbull's dark green RGB 12, 76, 44 to be the most common colour in the ribbon, frame and emblem art on screen, as the docs say: dark green leading, light green and a little yellow (Visual style, Decisions, 'Greenbull's look'; Content, Rules, rule 6).

Rebuild header_ribbon.png with build_level_up_art.py, keeping its size (380x44), the title area (art x 76 to 304) and the emblem medallions. The centre field becomes Greenbull's dark green, with light green kept to trim and the thin yellow line. The title is now lettered in cream with a dark outline (D2), so it reads on dark green. If dark green still doesn't lead on screen, also shift card_frame.png and highlight_frame.png toward dark green (keep the cream fill, the sizes and the 10-pixel 9-slice margins). The gift box can stay as it is. Keep T-303's versions in art-archive/<this ticket>/ (never delete). This is free script work: no PixelLab call is expected. If one is needed, list it with its reason and count in the result notes before calling; the board's go is up to 12 generations per asset, within the goal's art cap. Every changed piece goes through the style loop with --greenbull.

Then take the screenshot with D1's fixture (game/tests/fixtures/level_up_from_menu_demo.tscn, a run started from the main menu, screen fully open with both cards) and run `python game/tools/check_level_up_shot.py <png>` on it. It must report no Redgull red pixel and dark green RGB 12, 76, 44 as the most common art colour. Write its output in the result notes. Update Visual style (the level-up screen's look) and game/README.md ('Level-up screen art').

The board's review: play a run from the main menu to a level-up: the ribbon is dark green with light green trim and a little yellow, the cream title reads clearly on it, the emblems show, and there is no Redgull red.

## Acceptance criteria

- [ ] header_ribbon.png keeps its size (380x44) and has a dark green RGB 12, 76, 44 centre field with light green trim and a thin yellow line; any other changed piece keeps its file name and size; `python game/tools/build_level_up_art.py check` passes for all seven pieces. (QA: pass: check passes 7 of 7; ribbon 380x44, dark green field, only ribbon changed)
- [ ] Each changed piece passes `python game/tools/style_rules.py art <file> --greenbull` and has a style loop record in this ticket's Style review. (QA: pass: style_rules 5 of 5 ok; two loop runs recorded, 9/10)
- [ ] T-303's versions of every changed piece are in art-archive/<this ticket>/. (QA: pass: art-archive/T-311/t303/header_ribbon.png and .json)
- [ ] A screenshot from game/tests/fixtures/level_up_from_menu_demo.tscn (a run started from the main menu, the level-up screen open with both cards and the Greenbull title) is in art-archive/<this ticket>/screenshots/ and listed in the result notes. (QA: pass: level_up_from_menu.png present and listed)
- [ ] `python game/tools/check_level_up_shot.py` on that screenshot exits 0: no Redgull red pixel, and dark green RGB 12, 76, 44 is the most common art colour; its output is in the result notes. (QA: pass: reran, exit ok, 0 red, dark green 37690 leads)
- [ ] test_build_level_up_art.py and test_level_up_screen.gd pass; any PixelLab call is listed in the result notes with its reason and count. (QA: pass: unit tests 512 OK; GUT 1420/1420; 0 PixelLab calls listed)
- [ ] docs/visual-style.md and game/README.md describe the dark green ribbon. (QA: pass: both describe it)
- [ ] All three test sets pass. (QA: pass: GUT 1420/1420, game/tools 512 OK, tools 501 OK)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-311.

### 2026-10-27, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

### 2026-10-27, In QA → Needs playtest

Goal runner (G-006): QA passed; merged into playtest/G-006.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-311/briefs/header_ribbon.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-311/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 9/10
- Reason: The banner follows the brief and the rules. Rule 1: the script checks pass (10 colours, alpha 0 or 255 only, transparent corners, 380x44) and the edges look hard. Rule 6: dark green is the main colour, the centre field is plain, light green is kept to the trim and medallions, and the yellow is a thin accent on top. It is a Greenbull piece (the level-up screen), so those colours are allowed, and there is no red and no gull. The folded tails have a V notch and the pale round medallions carry the bull emblem at each end. Rule 2: flat UI and brand art, so the shading and detail demands are relaxed. Rule 4: the dark green and the retro pixel look suit the night mood. Rule 3: the view and scale rules don't apply to a flat UI piece. Rules 5, 7, 8, 9 and 10 don't apply. The only weakness is that the image is small and flat. I saw no clear breach, so there is nothing to fix.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls art-archive/T-311/style-loop 2>/dev/null; mkdir -p art-archive/T-311/style-loop && python game/tools/build_level_up_art.py piece header_ribbon art-archive/T-311/style-loop/v1.png && python -c \"\nfrom PIL import Image; from collections import Counter\nim=Image.open('art-archive/T-311/style-loop/v1.png'); print(im.mode, im.size)\npx=list(im.getdata()); print('alphas',set(p[3] for p in px))\nc=Counter(p[:3] for p in px if p[3]==255); print(len(c)); print(c.most_common(8))\nprint('plain title area colours', Counter(im.getpixel((x,22))[:3] for x in range(76,305)))\n\"", "description": "Draw version 1 and check its colours"}, "tool_name": "Bash", "tool_use_id": "toolu_01GRocKZnaEjC7AoMV9BJUCC"}

**Kept:** version 1, score 9/10 (`art-archive/T-311/style-loop/v1.png`, copied to `game/art/level_up/header_ribbon.png`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-311/briefs/header_ribbon.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-311/style-loop/v1-2.png`
- Script checks: 6 of 6 pass
- Score: 9/10
- Reason: The ribbon follows the brief and the rules. Rule 1 passes the script checks: 380x44, 10 colours, alpha 0 or 255 only, transparent background, hard pixel edges. Rule 6 passes: the centre field is dark green and is the leading colour, light green is kept to the trim and the medallion emblems, and there is one thin yellow line on top. There is no red and no gull. Rule 2: the dark outline, the single bevel row and the V-notched tails are clean. The ribbon is flat UI art, and the logo emblem is exempt from shading. Rules 3 to 5 and 7 to 10 don't apply or aren't broken. The only small weakness is that the flat ribbon has little highlight variety. Rule 2 asks for highlight pixels breaking the outline, but this is flat UI art and the bevel row serves that purpose. No change is needed.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls art-archive/T-311/style-loop/ 2>&1; python game/tools/build_level_up_art.py piece header_ribbon art-archive/T-311/style-loop/v1-2.png && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-311/style-loop/v1-2.png');print(im.mode,im.size)\nfrom collections import Counter\nc=Counter(im.getdata());print(len(c));print(c.most_common(6));print(set(p[3] for p in c))\"", "description": "Run the ribbon script to make version 1 and check it"}, "tool_name": "Bash", "tool_use_id": "toolu_019e5tYRLhvZKitkZarV7Amh"}

**Kept:** version 1, score 9/10 (`art-archive/T-311/style-loop/v1-2.png`, copied to `game/art/level_up/header_ribbon.png`): it reached 8 or more.

## Result notes

Asset Generation Agent, 2026-10-27.

**What changed.** Only `game/art/level_up/header_ribbon.png` (still 380x44) and its record JSON, rebuilt by `game/tools/build_level_up_art.py`. The centre field is now Greenbull's dark green RGB 12, 76, 44, with one bevel row each side (DG_L above, DG_D below) inside the trim's outline. The light green RGB 104, 220, 96 is kept to the trim above and below the field, and the one thin yellow line RGB 247, 208, 52 is on top. The title area (art x 76 to 304) is plain dark green for T-310's cream, dark-outlined title. Tails and emblem medallions are unchanged. card_frame.png and highlight_frame.png did **not** need to change: dark green leads with the ribbon alone. The gift box is unchanged too. `build_level_up_art.py check` passes for all seven pieces, and `style_rules.py art game/art/level_up/header_ribbon.png --greenbull` passes 5 of 5.

**Archive.** T-303's light green ribbon (PNG and JSON) is in `art-archive/T-311/t303/`. I copied it there with the new `build_level_up_art.py archive-t303` command, which never overwrites. The brief is `art-archive/T-311/briefs/header_ribbon.md`. The loop versions are `art-archive/T-311/style-loop/v1.png` (run 1: two bevel rows) and `v1-2.png` (run 2, kept).

**Style loop.** I did two runs, each scored 9/10 in round 1 (see Style review). Run 1 was the first dark green version. On screen it led the outline colour by only 854 pixels, so I narrowed the bevel from two rows to one and reran the loop on the final version. **PixelLab: 0 generations, none planned.** This was free script work.

**Screenshots** (`art-archive/T-311/screenshots/`, from `res://tests/fixtures/level_up_from_menu_demo.tscn`, 240 frames, both cards and the cream Greenbull title shown):
- `level_up_from_menu.png`: the final screen.
- `before_level_up_from_menu.png`: the same shot with T-303's light green ribbon, for comparison. The check fails on it, because the outline (14, 22, 18) leads with 34,404 pixels against light green's 33,238 and dark green's 23,280.

**`python game/tools/check_level_up_shot.py art-archive/T-311/screenshots/level_up_from_menu.png`** exits 0 with this output (counts shortened to the top 12 it prints):
```
"red_pixels": 0, "red_positions": [],
"art_colour_counts": [12,76,44: 37690; 14,22,18: 34404; 104,220,96: 19948; 6,46,26: 8642;
  24,110,58: 8352; 170,240,140: 6856; 52,160,72: 6640; 247,208,52: 4722; 226,252,200: 3528;
  24,112,60: 1591; 8,16,12: 947; 40,138,60: 830],
"most_common_art_colour": [12, 76, 44], "most_common_is_dark_green": true, "ok": true
```
Dark green leads the outline by 3,286 pixels (about 10%). That margin is clear but not large: the outline colour is also the title's 4-pixel outline and the frames' dark lines. If a later change adds much more outline, shifting the card frames toward dark green (as this ticket allowed) is the next free step.

**Tests.**
- `test_build_level_up_art.py` has 19 tests, all passing. The new ones check: the dark green field leads the ribbon; the title area is plain dark green; light green is only in the trim; the yellow line is on top; the ribbon record names T-311 while the others still name T-303; `archive_old(names=...)` copies only the named pieces; T-303's ribbon is kept in the archive.
- All three test sets pass: `bash game/tools/run_tests.sh` (1420 of 1420, test_level_up_screen.gd included), `python -m unittest discover -s game/tools` (512 OK, 1 skipped), and `python -m unittest discover -s tools` (501 OK).

**Docs.** `docs/visual-style.md` (Decisions, Greenbull's look on the level-up screen) and `game/README.md` ("Level-up screen art", T-311 paragraph and the ribbon line).

**Refusals.** In both loop runs the generator's own chained shell command was refused: it ran the piece script and then an inline `python -c` colour check, joined with `&&`. This was not essential. The loop still wrote, scored and kept each version, and I checked the colours with the pre-approved tools above. I didn't work around it.

**Not committed.** Godot's line-ending-only `.import` changes across `game/` are left uncommitted.
- 2026-10-27, in-qa → needs-playtest: QA passed every criterion (goal G-006).

---
id: T-447
title: Art: the shared button's plates for every state
status: needs-playtest
from: project-lead
to: asset-generation
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-446]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/art/level_up/button_plate.png, game/art/level_up/button_plate_pressed.png, game/scripts/hud/hud_style.gd]
files_expected_to_change: [game/art/ui/, game/tools/, art-archive/, docs/visual-style.md]
model: sonnet
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "One button style across the game"): the shared button from the linked ticket (this one depends on it) starts with a placeholder: the level-up plate tinted per state. Make its final art: a 9-slice button plate for each state (normal, hovered, keyboard-selected, pressed, disabled) that fits the HUD style sheet (Visual style, Content: outline, palette, bezel lit from the top left) and the game's pixel art, and swap it in for the placeholder in the shared button. Draw it by script first (free; a script in game/tools/ that builds the plates from the style sheet, like the T-430 redraws). Each plate goes through the style loop (tasks/README.md, "The style loop"). PixelLab only with the board's go: if you think the script can't reach 8, stop and say so in the result notes before any generation.

Never delete art: the placeholder stays where it is (it is the level-up screen's own art). Never write, move or commit anything in game/data/levels/.

The board's review: go through every screen and look at the buttons in each state.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A plate for each of the five states is in game/art/ui/ with its record, built by a script in game/tools/ that is committed and documented. (QA: pass: plates, record, script, tests and doc present)
- [ ] Each plate's style loop score is in the result notes (8 or more, or noted for the playtest). (QA: pass: scores 8,8,8,8,8 in result notes and Style review)
- [ ] The shared button uses the new plates (test or screenshot), and the six screens still show their buttons correctly. (QA: pass: HudStyle loads the new plates; shared button and level-up tests pass; screenshots show buttons)
- [ ] Screenshots of the buttons in each state on at least two screens are saved and listed in the result notes. (QA: pass: 7 screenshots listed, incl. button_states, main_menu, garage, level_up, recap, pause, tutorial)
- [ ] docs/visual-style.md records the button plates. (QA: pass: visual-style.md line 101 records the plates)
- [ ] 0 PixelLab calls unless the board gave its go (in the result notes); nothing under game/data/levels/ is changed or committed. (QA: pass: 0 T-447 lines in pixellab log; no game/data/levels diff vs master)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass: 3 test sets pass (qa_check); counts 772/633/2348 in notes)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-31: art, brief `art-archive/T-447/briefs/normal.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-447/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The plate meets the script checks (72x22, 8 colours, hard alpha, no Greenbull colours). It reads as a steel button with a 1 px near-black outline, stepped corners, a lighter top-left bezel and a flat mid-steel face, in blue-greys only. It should stretch cleanly under the 9-slice. No rule is clearly broken. The one weakness is that at this size the bezel's top-left lighting reads only faintly against the face. Rule 2's "broken by lighter highlight pixels" is met only lightly. A refine could lift the top and left bezel rows one step lighter, or add a one-step darker bottom and right bezel, so the 3 px bezel and its lighting show more clearly next to the siblings and clock_panel.png.
- Rules broken: none
- Refused: {"tool_input": {"command": "cd C:/solid-carbide-worktrees/T-447 && test ! -e art-archive/T-447/style-loop/v1.png && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-447/style-loop/work/normal_v1.png').convert('RGBA')\nprint(im.size, im.mode, len(set(im.getdata())), sorted(set(a for *_,a in im.getdata())))\nprint([im.getpixel(p) for p in [(0,0),(1,0),(0,1),(2,2),(36,11)]])\nim.save('art-archive/T-447/style-loop/v1.png')\n\"; python -c \"from PIL import Image; i=Image.open('C:/solid-carbide-worktrees/T-447/art-archive/T-447/style-loop/v1.png'); print(i.mode,i.size)\"", "description": "Check plate and save as RGBA v1"}, "tool_name": "Bash", "tool_use_id": "toolu_011X4yTCs7gfL1ScXpbFJotX"}

**Kept:** version 1, score 8/10 (`art-archive/T-447/style-loop/v1.png`, copied to `game/art/ui/button_plate_normal.png`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-31: art, brief `art-archive/T-447/briefs/hover.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-447/style-loop/v1-2.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The hover plate follows the rules. It has a near-black 1 px outline, a stepped radius-2 corner, a 3 px bezel lit from the top left, and flat shading steps. The middle is one flat colour, so the 9-slice stretches cleanly. The colours are steel blue-grey only, with no Greenbull colours, red or cyan. It is clearly lighter than the normal plate in both bezel and face, and it still reads as the same steel button. The script checks pass: 72x22, 8 colours, no semi-transparent pixels. The only weakness I can see is that the lift over normal is modest at 1x, so it could be a step lighter. I would not change anything else. No rules are broken.
- Rules broken: none
- Refused: {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-447/style-loop/work/hover_v1.png').convert('RGBA')\nim.save('art-archive/T-447/style-loop/v1-2.png')\nim=Image.open('art-archive/T-447/style-loop/v1-2.png');print(im.mode,im.size)\npx=list(im.getdata());print(len(set(px)),sorted(set(p[3] for p in px)))\nprint(px[0],px[1],px[72],px[3*72+3], px[11*72+36])\n\"", "description": "Save v1-2 as RGBA PNG and check it"}, "tool_name": "Bash", "tool_use_id": "toolu_01RMeRe1VtFmMh5GmTQBu1Vr"}

**Kept:** version 1, score 8/10 (`art-archive/T-447/style-loop/v1-2.png`, copied to `game/art/ui/button_plate_hover.png`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-31: art, brief `art-archive/T-447/briefs/focus.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-447/style-loop/v1-3.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The focus plate follows the brief and passes every script check (72x22, 4 colours, alpha 0 or 255, transparent corners, no Greenbull colours). It is a bright white and light blue-grey ring with a near-black outline and an open transparent middle. Its steel blue-grey palette matches the normal plate, so rule 7's steel tone holds. The ring is clearly lighter than the dark normal plate, so it reads as a selection highlight. The image is tiny, so I could not check the corner cuts pixel by pixel. Only minor risk: with 4 colours the bezel's top-left lighting and the two-to-three step shading of rule 2 are thin. If it is flat all round, add one mid-tone step on the bottom and right edges of the bezel so it matches the other four plates. Otherwise no rule is clearly broken.
- Rules broken: none
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-447/style-loop/work && python game/tools/build_button_plates.py build --state focus --out art-archive/T-447/style-loop/work/focus_v1.png && ls art-archive/T-447/style-loop/ && test ! -e art-archive/T-447/style-loop/v1-3.png && cp art-archive/T-447/style-loop/work/focus_v1.png art-archive/T-447/style-loop/v1-3.png && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-447/style-loop/v1-3.png');print(im.mode,im.size)\npx=list(im.getdata());print(sorted(set(p[3] for p in px)),len(set(px)))\"", "description": "Build focus plate v1 and save as v1-3.png"}, "tool_name": "Bash", "tool_use_id": "toolu_014QRbvPtaB34vciWmEcHTNr"}

**Kept:** version 1, score 8/10 (`art-archive/T-447/style-loop/v1-3.png`, copied to `game/art/ui/button_plate_focus.png`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-31: art, brief `art-archive/T-447/briefs/pressed.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-447/style-loop/v1-4.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The pressed plate follows the style rules. It is 72x22 with hard pixels, 6 colours, a transparent background and a near-black outline. The stepped radius-2 corners are cut. The palette is steel blue-grey only, with no Greenbull colours, red or cyan. Compared with button_plate_normal.png, the face is darker and flat, and the bevel looks reversed, with a dark top and left and a lighter bottom and right. It reads as the same button set, sunk. I could only view the image at native 72x22, so I couldn't check pixel detail. One small risk: the reversed bevel looks subtle at this size. If it is hard to see at 2x, lift the bottom and right bezel steps one shade lighter, or darken the top and left, so the sunk read is clear next to the normal plate. Rules 2 and 4 are not clearly broken. The 6-colour count means shading is minimal, but a flat HUD plate allows that, as the 2 to 3 flat shading steps are present.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls art-archive/T-447/style-loop/ 2>/dev/null; python game/tools/build_button_plates.py build --state pressed --out art-archive/T-447/style-loop/work/pressed_v1.png && test ! -e art-archive/T-447/style-loop/v1-4.png && cp art-archive/T-447/style-loop/work/pressed_v1.png art-archive/T-447/style-loop/v1-4.png && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-447/style-loop/v1-4.png');print(im.mode,im.size,len(set(im.getdata())),sorted(set(a for *_,a in im.getdata())))\"", "description": "Build pressed plate v1 and save as v1-4.png"}, "tool_name": "Bash", "tool_use_id": "toolu_01MM7Q2YgGcweoDJgSXTT78d"}

**Kept:** version 1, score 8/10 (`art-archive/T-447/style-loop/v1-4.png`, copied to `game/art/ui/button_plate_pressed.png`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-10-31: art, brief `art-archive/T-447/briefs/disabled.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-447/style-loop/v1-5.png`
- Script checks: 6 of 6 pass
- Score: 7/10
- Reason: The plate meets the script-checked rules: 72x22, hard pixels, 6 colours, transparent corners, no Greenbull colours. It reads as a steel-blue-grey button with a near-black outline and a stepped corner, and it is clearly dimmer than normal with no glint, so the "sunk into the dark, low contrast" brief is met (rules 1, 2, 4 and 6 hold). Weaknesses, judged from a very small render so not certain: (1) It sits close to the pressed plate in darkness, and the brief says it must be clearly dimmer than both normal and pressed-neutral. Darken the fill and bezel a few more steps, or flatten the bezel so it has less lit/shadow separation than pressed has. (2) Rule 2's selective outline and shading are very reduced here. That is acceptable for a disabled state, but keep at least a faint top-left bezel step so the set still reads as one button.
- Rules broken: none
- Refused: {"tool_input": {"command": "test ! -e art-archive/T-447/style-loop/v1-5.png && python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-447/style-loop/work/disabled_v1.png').convert('RGBA')\nim.save('art-archive/T-447/style-loop/v1-5.png')\nim=Image.open('art-archive/T-447/style-loop/v1-5.png');print(im.mode,im.size,len(im.getcolors(10000)),sorted(set(a for *_,a in im.getdata())))\n\"", "description": "Save version 1 as RGBA PNG and check it"}, "tool_name": "Bash", "tool_use_id": "toolu_01FQrVJM8EJgVcmftHtp5S28"}

#### Round 2

- Version 2: `art-archive/T-447/style-loop/v2.png`
- What changed: Version 2, made without PixelLab: a palette change only. I edited just the `disabled` entry of PALETTE in game/tools/build_button_plates.py and left the drawing code and the other four states alone. The file is 72 x 22 and 8-bit RGBA.
- The whole plate is darker and greyer. The fill went from (40,44,55) to (30,33,41), so it is now about 10 levels darker than the pressed plate's fill (40,44,57) and well below normal (62,69,86).
- The bezel is flatter: hi (48,52,62), mid (37,40,49), lo (21,23,30), edge (26,28,36). The light-to-shadow spread is now about 27 levels, against about 66 on the pressed plate.
- A faint top-left step stays (hi, then mid, then fill), lit from the same corner as normal, so it still reads as part of the same button set.
- There is still no glint. The near-black outline, the stepped corners and the flat middle for 9-slicing are unchanged.

I checked the size and format only; I didn't re-count the colours or the alpha values.
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The plate matches the brief. It is a 72x22 plate with a stepped corner, a near-black outline, a flat middle and a low-contrast bezel. It sits clearly darker and dimmer than both normal and pressed, with no glint. The palette is steel blue-grey only, with no Greenbull colours, red or cyan, and the script checks pass (6 colours, alpha 0 or 255). It reads as the same button as its siblings. I found no rule breaks, though I viewed it only at native size. A small deduction: the bezel and fill steps are very close in value, so at 2x the sunk plate could read as nearly flat. If the board wants more definition, lift the top-left bezel one step, still well below pressed.
- Rules broken: none

**Kept:** version 2, score 8/10 (`art-archive/T-447/style-loop/v2.png`, copied to `game/art/ui/button_plate_disabled.png`): it reached 8 or more.

## Result notes

**Done (Asset Generation Agent).** 0 PixelLab calls (the plates are script-drawn; the script reached 8 in the loop, so no generation was needed). Nothing under game/data/levels/ touched.

**What was made.** Five 9-slice plates in `game/art/ui/`: `button_plate_normal.png`, `_hover`, `_focus`, `_pressed`, `_disabled` (72 x 22 art px, shown at 2x, slice margins 3 on every side) plus the record `button_plates.json`. Built by `game/tools/build_button_plates.py` (deterministic; tests in `game/tools/test_build_button_plates.py`; documented in `game/docs/art/button-plates.md`). HUD style sheet look: (8, 8, 15) outline, stepped corner radius 2, steel bezel lit from the top left, flat faces, no Greenbull colour. The focus plate is a bright ring with an open (transparent) middle drawn over the current state's plate, so a click or hover under a keyboard selection still shows.

**Style loop (five runs, one per plate; scores in the Style review).** normal 8 (round 1), hover 8 (round 1), focus 8 (round 1), pressed 8 (round 1), disabled 7 then 8 (round 2; only its PALETTE entry changed). All kept at 8 or more; none noted for the playtest. Versions: `art-archive/T-447/style-loop/` (v1, v1-2, v1-3, v1-4, v2 are the kept ones, byte-identical to the files in game/art/ui/); briefs in `art-archive/T-447/briefs/`.

**Shared button.** `HudStyle` (`game/scripts/hud/hud_style.gd`) now loads `res://art/ui/button_plate_<state>.png`; the recolour table, the tints and the flat focus ring are gone; hover, pressed, hover_pressed, disabled and focus each use their own plate; margins are one `BUTTON_SLICE` (3, 3, 3). The level-up screen's own plate files stay untouched. Tests updated in `game/tests/unit/hud/test_shared_button.gd` and `test_level_up_screen.gd`.

**Screenshots** (`art-archive/T-447/screenshots/`): `button_states.png` (all five states on dark and light, plus the small pause size and the checkbox), `main_menu.png`, `garage.png` (Back), `level_up.png` (two Take it), `recap.png`, `pause.png`, `tutorial_slide1.png`.

**Tests.** `python -m unittest discover -s game/tools`: 772 OK (1 skipped). `... -s tools`: 633 OK. GUT: 193 scripts, 2348 tests, 2348 passing.

**Docs changed:** `docs/visual-style.md` (the plates' entry), `docs/hud-and-menus.md` (Plate and States and feel bullets), `game/docs/art/button-plates.md` (new).

**Notes.** Godot's `.import` line-ending noise and `.uid` files in the worktree were not committed. The focus ring is now inside the plate's edge (before: 2 px outside it); the board can judge it in the playtest.
- 2026-10-31, in-progress → in-qa: Plates done, style loop 8+ each, tests pass; ready for QA
- 2026-10-31, in-qa → needs-playtest: QA passed

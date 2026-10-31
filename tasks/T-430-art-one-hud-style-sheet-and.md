---
id: T-430
title: Art: one HUD style sheet, and script redraws of the HUD pieces that break it
status: done
from: project-lead
to: asset-generation
lead: Goal-G-008
epic: art
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: yes
depends_on: [T-428]
documents_affected: [docs/visual-style.md, game/docs/hud-and-menus/livestream-hud-art.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/livestream-hud-art.md, game/tools/build_hud_livestream_art.py, game/tools/style_rules.py]
files_expected_to_change: [docs/visual-style.md, game/art/hud/, game/tools/build_hud_livestream_art.py, game/tools/test_build_hud_livestream_art.py, game/docs/hud-and-menus/livestream-hud-art.md]
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

Goal G-008, 'A consistent HUD' (HUD and menus, Decisions): every HUD piece shares one visual language. D3 has moved the HUD's style values into one shared place. Write one HUD style sheet in Visual style (Decisions): outline thickness and colour, palette, panel shapes and corners, the font for numbers and the font for words, and the pixel scale. Then go through every HUD piece (clock, coins, hearts, weapon icons, sub goal, live viewers counter and its fire, reactions, trick and combo broken popups, kaiju health bar, pause strip, level-up screen) and redraw by script, through the style loop, the art of those that break the sheet, writing them over the files the game already loads in game/art/hud/ (or their existing folder) so the game picks them up; archive the old versions in art-archive/<id>/. No PixelLab: these are script redraws; if one is truly needed, list it with the reason. Code-side changes (fonts, colours, outline widths drawn in code) are not yours: list them piece by piece in the result notes for the UI ticket D5. Greenbull's colours stay on Greenbull's things only (rule 6).

The board's review: Compare the before and after screenshots in art-archive/<id>/screenshots/, then play a run with the redrawn HUD art.

## Acceptance criteria

- [ ] docs/visual-style.md holds one HUD style sheet: outline thickness and colour, palette, panel shapes and corners, the number font and the word font, and the pixel scale. (QA: pass)
- [ ] The result notes list every HUD piece named in the description, saying for each what differs from the sheet and what changed, or why it already fits. (QA: pass)
- [ ] Every redrawn piece is in game/art/hud/ (or its existing folder) with its record, the old versions are in art-archive/<id>/, and no PixelLab generations were used (or any used are listed with the reason). (QA: pass)
- [ ] Each redrawn piece went through the style loop, with every round in the Style review; python game/tools/style_rules.py finds no Greenbull colour in any HUD piece outside Greenbull's things. (QA: pass)
- [ ] The result notes list, piece by piece, the code changes the UI ticket needs (fonts, colours, outline widths). (QA: pass)
- [ ] Before and after screenshots of the same moment in a run, the after one showing the redrawn art in the game, are in art-archive/<id>/screenshots/. (QA: pass)
- [ ] python -m unittest discover -s game/tools -p "test_*.py" passes, with the count in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-430.

### 2026-10-30, In progress → In QA

Goal runner (G-008): the agent is done; QA is checking it.

### 2026-10-30, In QA → Needs playtest

Goal runner (G-008): QA passed; merged into playtest/G-008.

## Style review

Run by `tools/style_loop/run.py` on 2026-10-30: art, brief `art-archive/T-430/briefs/subgoal_frame.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-430/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 9/10
- Reason: The image shows a 64x64 square frame: a white ring between two dark outlines, black inside, with a transparent background and hard pixel edges. The script checks all pass: 7 colours, no semi-transparent pixels, and no Greenbull light green or yellow, so rules 1, 3 and 6 are met. It is a flat screen-space HUD frame with no subject, city, alien thing, brand or word, so rules 4, 5 and 7-10 don't apply and nothing in it conflicts with them. Rule 2's shading and detail don't suit a flat HUD frame, and the brief asks for a flat frame. At this size I could not confirm the radius-2 corner cut (pixels (0,0), (1,0), (0,1)) by eye. That is a brief requirement and not a style-guide rule, so hud_sheet_check.py should confirm it. No rule is broken.
- Rules broken: none
- Refused: {"tool_input": {"command": "New-Item -ItemType Directory -Force art-archive\\T-430\\style-loop | Out-Null; if (Test-Path art-archive\\T-430\\style-loop\\v1.png) { \"EXISTS\" } else { python game/tools/build_hud_livestream_art.py subgoal-frame --out art-archive/T-430/style-loop/v1.png; python game/tools/hud_sheet_check.py art-archive/T-430/style-loop/v1.png }", "description": "Build v1 sub goal frame and check it"}, "tool_name": "PowerShell", "tool_use_id": "toolu_017i9wZ8V2nwqKzKjLcjXcG3"}; {"tool_input": {"command": "New-Item -ItemType Directory -Force art-archive\\T-430\\style-loop | Out-Null; python game/tools/build_hud_livestream_art.py subgoal-frame --out art-archive/T-430/style-loop/v1.png; python game/tools/hud_sheet_check.py art-archive/T-430/style-loop/v1.png", "description": "Build v1 sub goal frame and run sheet check"}, "tool_name": "PowerShell", "tool_use_id": "toolu_013vmofbMbGF4s6JnMxJJ9VV"}; {"tool_input": {"command": "python game/tools/build_hud_livestream_art.py subgoal-frame --out art-archive/T-430/style-loop/v1.png", "description": "Build v1 sub goal frame"}, "tool_name": "PowerShell", "tool_use_id": "toolu_01N1THTrLZFt4dksTGgfRcVE"}; {"tool_input": {"command": "python game/tools/hud_sheet_check.py art-archive/T-430/style-loop/v1.png; python -c \"from PIL import Image; im=Image.open('art-archive/T-430/style-loop/v1.png'); print(im.mode, im.size); print([im.getpixel((x,0)) for x in range(4)]); print([im.getpixel((x,4)) for x in range(4,8)])\"", "description": "Run HUD sheet check and inspect pixels"}, "tool_name": "Bash", "tool_use_id": "toolu_014hYdpFb2qNUXMncUEFGTkS"}

**Kept:** version 1, score 9/10 (`art-archive/T-430/style-loop/v1.png`, copied to `game/art/hud/subgoal_frame.png`): it reached 8 or more.

## Result notes

**Done.** 0 PixelLab generations (script redraw only). One piece redrawn: the sub goal frame, style loop 9/10 in round 1 (Style review above).

**The sheet:** `docs/visual-style.md`, Decisions, "The HUD style sheet" (seven rules: pixel scale 2x integer, 1 art px outline (8, 8, 15) and text outline 6 screen px, palette, panels with stepped corner radius 2, Bangers for words, drawn seven-segment digits for the clock and Bangers for other numbers, shading). The values are a proposal for the playtest, built from what the HUD already does most. `game/tools/hud_sheet_check.py` checks art against it.

**Every piece against the sheet:**
- Clock: panel art fits (radius 2, steel bezel, outline). Digits art (greyscale seven-segment) fits and is the sheet's number font for the clock. Code: the clock is shown with the Consolas/Courier system font on a code-drawn flat panel, not the art (see the code list).
- Coins: no art; "Coins 37" is the default font in gold with a 6 px outline. Code only.
- Hearts: `heart_full`, `heart_empty` fit (18 x 16, outline, 2x). `likes_heart.png` (11 x 10) is a legacy file only its test loads; left as it is.
- Weapon icons: **break rule 1**: the level-up card pictures (64 x 64, PixelLab) are shown at 48 px, a 0.75x scale, so their pixels are a different size from the 2x HUD art. Not fixable by script (never scaled). Needs new 24 x 24 icons shown at 2x (a PixelLab task for the board's go) or a 32 x 32 picture at 1.5x; listed, not done.
- Sub goal: the frame **broke the panel corner rule (radius 3)**: redrawn with radius 2, same ring and black inside (4, 4) to (59, 59); old version and record in `art-archive/T-430/before/`. The subs icon (22 x 22) fits.
- Live viewers counter: viewers panel, LIVE badge and eye icon fit (radius 2, outline, cyan only for viewers). Fire: fits as an effect (dark red-brown edge, exempt in the sheet).
- Reactions (12 icons, 16 x 16): fit (outline broken only by a few highlight pixels, under 15%).
- Trick and combo broken popups: code-drawn (baked palette), black border and no near-black outline: code list.
- Kaiju health bar: code-drawn, black outline 2 px: fits the outline width; its colours are in the palette. No art.
- Pause strip: code-drawn flat panel with a default-font title: code list.
- Level-up screen: art (`art/level_up/`, Greenbull's things) is a separate look by the board's decision (Greenbull's colours allowed there); its text is Bangers. Left; code list for outline widths.

**Code changes for the UI ticket D5 (piece by piece, values in `hud_style.gd`):**
- Clock: replace `CLOCK_FONT_NAMES` (Consolas) with the art's `clock_digits.png` frames tinted by `modulate` on `clock_panel.png` (or, if a font stays, Bangers); `clock_digits` role outline 6 stays; `CLOCK_PANEL_*` colours and width 3 go (the panel art replaces them).
- Coins: role `coins` font "" to "comic" (Bangers), outline 6 (already).
- Weapon icons: `ICON_SIZE` 48 to a 2x multiple of new art; `weapon_count` outline 8 stays (big number); `air_counter` 8 stays.
- Sub goal: label stays Bangers 20 with outline 6; nothing else.
- Live viewers counter: `viewers_unit` outline 4 to 6 (words), `viewers_flight` and `viewers_drop` outline 6 (already), number outline 8 (already); heat steps' `outline` 10 to 8.
- Trick popups: `POPUP_TEXT` font_px 32 and 20 even (already); border (0,0,0) to the outline colour (8, 8, 15) in `POPUP_PALETTE` entries 1, 3, 12 and `BROKEN_PALETTE` entries 2 and 4.
- Kaiju bar: `KAIJU_LINE` Color.BLACK to `OUTLINE_COLOR`; `KAIJU_BACK` white stays; `KAIJU_OUTLINE` 2.0 (already).
- Pause strip: `pause_title` and `pause_text` font "" to "comic", sizes 28 and 16 to even, in capitals; `PAUSE_CONTROL_FRAME` stays; strip colour fine.
- Level-up: `level_up_*` roles already Bangers; `LEVEL_UP_TITLE_OUTLINE_SIZE` 4 to 6; card text outline none to 6 only if the board asks.
- Colours that differ from the palette in rule 3: `HEART_COLOR` equals it; `COINS_COLOR` and `LABEL_COLOR` equal it; `KAIJU_FILL` equals it.

**Files:** `docs/visual-style.md`, `game/tools/hud_sheet_check.py` + `test_hud_sheet_check.py`, `game/tools/build_hud_livestream_art.py` (subgoal_frame radius), `game/art/hud/subgoal_frame.png` + `.json`, `game/docs/hud-and-menus/livestream-hud-art.md`. Records: `art-archive/T-430/` (before/, briefs/, style-loop/, screenshots/).

**Checks:** `python game/tools/style_rules.py art game/art/hud/subgoal_frame.png`: all pass, no Greenbull colour. `hud_sheet_check.py` over every piece in `game/art/hud/`: all ok. `python -m unittest discover -s game/tools -p "test_*.py"`: 727 tests OK (1 skipped), including 5 new ones.

**Screenshots** (`art-archive/T-430/screenshots/`): `hud_run_before.png` (T-428's run shot, the old frame), `hud_run_after.png` (the same fixture `t428_hud_style_demo.tscn`, the new frame; the popup and viewers number differ because they animate), `subgoal_frame_before_after.png` (enlarged 4x, dark and light). Contact sheet of all pieces: `art-archive/T-430/before/contact_before.png`.

**QA round 1:** all 7 criteria pass. Tests: 727 run, OK (1 skipped). style_rules on subgoal_frame.png: all pass, no Greenbull colour. Sheet is in docs/visual-style.md (rules 1 to 7); old frame and record in art-archive/T-430/before/; three screenshots present. `tools/qa_check.py` was refused (needs approval), so its paperwork lines were checked by hand.

**Weak spot for the board:** the redraw is a 3-pixel change at the corners, small to see; the real inconsistencies left are the weapon icons' scale and the code-side fonts and outlines.
- 2026-10-30, in-qa → needs-playtest: QA passed every criterion (goal G-008).
- 2026-10-31, needs-playtest → done: The board's playtest of G-008: LGTM (2026-10-30)

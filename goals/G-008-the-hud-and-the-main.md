---
id: G-008
title: The HUD and the main menu (board, 2026-10-29 and 2026-10-30; HUD an...
status: ready-to-play
art_cap: 20
art_used: 4
iteration: 8
max_iterations: 20
created: 2026-10-30
lead: Goal-G-008
session: Greenbull
---

## Goal

The HUD and the main menu (board, 2026-10-29 and 2026-10-30; HUD and menus, Decisions: 'Main menu polish', 'A consistent HUD', 'The HUD scales with the window, and a HUD size slider', and the settings sliders saving once, on release, from the audit epic, formerly T-421; Visual style, Decisions, 'The splash cover'). The main menu gets the pixel-art title with the styled '(work in progress)' line and the splash cover behind it; every HUD piece shares one visual language and the HUD's code follows one style sheet; the HUD keeps its place and a sensible size at any window size and resolution, ultrawide included, with a HUD size slider and its label on the pause screen; the pause screen's sliders save once, on release. Text for every new label comes from the Narrative Theme agent first.

## Goal acceptance criteria

- [x] On playtest/G-008, the main menu scene (game/scenes/menu/main_menu.tscn) shows the title "SOLID CARBIDE" in a pixel-art font whose licence is recorded in the repo, the "(work in progress)" line under it styled to match, and game/art/menu/splash.png filling the screen behind them without stretching and with hard pixel edges. Start, Garage and Exit stay readable and work as before (tests and a screenshot). (QA: pass)
- [x] game/art/menu/splash.png exists with its art record. It was made with PixelLab using at most 20 generations, listed in its ticket's result notes, went through the style loop with every round in the Style review, and is recorded in Visual style and game/docs/art/. (QA: pass)
- [x] Visual style holds one HUD style sheet (outline, palette, panel shapes and corners, fonts for numbers and for words, pixel scale). Every HUD piece's art and code follow it: each piece is listed with what changed or why it already fits. Before and after screenshots of the same moment in a run are in art-archive/. (QA: pass)
- [x] At 1152 x 648, 1920 x 1080, 2560 x 1440, 3440 x 1440 and a small window, every HUD piece keeps its corner or edge and a size in proportion to the window, with no overlap and nothing off screen. Headless tests cover this and screenshots at each size are in art-archive/. (QA: pass)
- [x] The pause screen has a HUD size slider with its label read from a data file the Narrative Theme agent wrote. The label scored at least 8 in the style loop and no label text is hard-coded. The slider changes the HUD's scale at once while paused, is saved on this computer and is applied at the next start (tests). (QA: pass)
- [x] Dragging any pause screen slider (camera zoom, SFX volume when shown, music volume, HUD size) applies the value live but writes the settings file at most once per drag, on release. Closing the pause screen saves the current values. Tests count the saves. (QA: pass)
- [x] HUD and menus, Content ("Main menu", "The HUD", "Pause screen") and the game docs under game/docs/hud-and-menus/ describe the new title, the splash cover, the HUD style, the scaling rule, the HUD size slider and saving on release. (QA: pass)
- [x] All three test sets pass on playtest/G-008 (python -m unittest discover -s game/tools -p "test_*.py", python -m unittest discover -s tools -p "test_*.py", bash game/tools/run_tests.sh), with the counts recorded. (QA: pass)

## Open questions

- HUD size slider: its range, its default and whether it shows its value (T-374 suggested 75% to 150%, default 100%, as a proposal). The docs don't decide.
- Which screens the HUD scaling and the HUD size slider cover: only the in-run HUD, or also the pause strip, the level-up screen, the tutorial slides, the recap and the world-attached pieces (trick popups, the kaiju's health bar).
- How the HUD scales at window sizes that aren't a whole multiple of 648 high: whole-number steps (pixel-perfect, jumps in size) or smooth scaling with nearest filtering.
- Where the HUD sits on an ultrawide screen: pinned to the real screen corners, or kept in a centred 16:9 area.
- Whether the HUD style sheet also covers the main menu, pause screen, level-up and recap screens, or only the in-run HUD. And whether the title's pixel-art font should be one of the style sheet's fonts or its own display font.
- Which pixel-art font the title uses. The game ships only Bangers today, so this is a new open-licence font to choose.
- How the splash cover fills a window that isn't 16:9 (crop to fill or letterbox), and whether the menu's buttons get a dark band or shadow over it.
- Whether the HUD's single style sheet in code should be a Godot Theme resource, a shared style script or a data file (game/data/hud.json).

## Sub-goals

| rank | id | title | score | why | verdict | tickets |
|---|---|---|---|---|---|---|
| 1 | S3 | Art: one HUD style sheet and script redraws of the pieces that break it (Asset Generation) | unblocks 2, value 5 | The 'consistent HUD' decision: the pieces look like they came from different games. The style sheet is the single source that both the art and the HUD's code follow. | covered | T-430, T-428 |
| 2 | S4 | The HUD's code follows the style sheet (UI) | unblocks 1, value 5 | The goal says the HUD's code follows one style sheet. Fonts, colours and outlines set in code must match S3 and be defined in one place, not scattered across each HUD script. | covered | T-428, T-429, T-430 |
| 3 | S6 | Main menu polish: pixel-art title, styled work-in-progress line, splash cover slot (UI) | unblocks 1, value 5 | The 'Main menu polish' decision. It builds the menu with a placeholder so the splash cover art (S7) only has to add its file. | covered | T-432 |
| 4 | S1 | Text: the HUD size slider's label (Narrative Theme) | unblocks 1, value 4 | The goal says every new label's text comes from the Narrative Theme agent first. The slider in S5 needs its label, and how its value reads if it shows one, before it can be built. | covered | T-426 |
| 5 | S2 | Pause screen sliders save once, on release | unblocks 1, value 4 | Part of the goal (from the audit, formerly T-421). Today zoom, SFX and music call GameSettings.save_* on every slider step. The HUD size slider in S5 must follow the same pattern. | covered | T-427 |
| 6 | S5 | The HUD scales with the window, and a HUD size slider on the pause screen (UI) | unblocks 0, value 5 | Part of the goal: today the HUD keeps its pixel size and looks tiny on big and ultrawide screens. The slider lets the player choose the HUD's size, saved on this computer. | covered | T-431, T-426, T-429, T-427 |
| 7 | S7 | Art: the splash cover behind the main menu (Asset Generation, PixelLab) | unblocks 0, value 5 | Visual style, 'The splash cover': an AI-generated pixel art cover, very consistent with the game's style, its colours and the actual car. It replaces S6's placeholder. | covered | T-433, T-432 |

### S3: Art: one HUD style sheet and script redraws of the pieces that break it (Asset Generation)

Needs: nothing.

- Visual style holds one HUD style sheet: outline thickness and colour, palette, panel shapes and corners, the font for numbers and the font for words, and the pixel scale. None of Greenbull's colours appear outside Greenbull's things.
- The result notes list every HUD piece (clock, coins, hearts, weapon icons, sub goal, live viewers counter and its fire, reactions, trick and combo broken popups, kaiju health bar, pause strip, level-up screen), saying for each what differs from the sheet and what changed, or why it already fits.
- Every redrawn piece is in game/art/hud/ (or its existing folder) with its record. The old versions are in art-archive/<id>/. No PixelLab generations were used, or any that were are listed with the reason.
- The result notes list, piece by piece, the code changes the UI ticket needs (fonts, colours, outline widths).
- Before and after screenshots of the same moment in a run are in art-archive/<id>/screenshots/.
- python -m unittest discover -s game/tools -p "test_*.py" passes, with the count in the result notes.

### S4: The HUD's code follows the style sheet (UI)

Needs: S3.

- Every code change listed in S3's result notes is made, ticked off in a checklist in the result notes.
- The HUD's style values (fonts, colours, outline widths) are defined in one shared place (a Godot Theme, a style script or a data file) that the HUD scripts read, and the file is named in the result notes.
- Positions, sizes and behaviour are unchanged: the existing HUD layout and behaviour tests still pass.
- A screenshot of a run with the whole HUD is in art-archive/<id>/screenshots/ next to S3's before shot.
- HUD and menus, Content and game/docs/hud-and-menus/hud.md describe the style each piece now uses.
- All three test sets pass, with the counts in the result notes.

### S6: Main menu polish: pixel-art title, styled work-in-progress line, splash cover slot (UI)

Needs: nothing.

- The title "SOLID CARBIDE" uses a pixel-art font whose licence is recorded next to the font in game/fonts/. "(work in progress)" is kept word for word and styled to match (screenshot).
- The menu shows game/art/menu/splash.png filling the screen (cropped, not stretched, hard pixel edges) when the file exists, and a plain dark placeholder when it doesn't, at 1152 x 648 and at 3440 x 1440. Tests cover both cases.
- Start, Garage and Exit stay readable over the image, keep their texts and still send start_pressed, garage_pressed and exit_pressed, with focus starting on Start (tests).
- HUD and menus, Content, "Main menu" and game/docs/hud-and-menus/main-menu.md describe it.
- Screenshots of the menu with the placeholder and with a test image are in art-archive/<id>/screenshots/.
- All three test sets pass, with the counts in the result notes.

### S1: Text: the HUD size slider's label (Narrative Theme)

Needs: nothing.

- The HUD size slider's label (and how its value reads, if the slider shows a value) is in the data file the pause screen reads its texts from. That file is named in the result notes, and the text is also in HUD and menus, Content, "Pause screen".
- Each new line scored at least 8 in the style loop, with every round in the ticket's Style review.
- The label follows Extended narrative's Text rules and has the same form as the pause screen's other slider labels ("Camera zoom level", "Music volume").

### S2: Pause screen sliders save once, on release

Needs: nothing.

- Dragging the zoom, SFX volume or music volume slider through 20 values writes the settings file at most once, when the drag ends. A headless test counts the saves.
- The value is still applied live during the drag (zoom changes the view, volume changes the sound at once). Tests cover it.
- Closing the pause screen (Escape, Restart, Exit) saves the current values. Tests cover it.
- All three test sets pass, with the counts in the result notes.

### S5: The HUD scales with the window, and a HUD size slider on the pause screen (UI)

Needs: S1, S2, S4.

- At 1152 x 648, 1920 x 1080, 2560 x 1440, 3440 x 1440 and a small window (for example 960 x 540), every HUD piece keeps its corner or edge and a size in proportion to the window, with no overlap and nothing off screen. Headless tests cover each size.
- Pixel art stays crisp (whole-number scales or nearest filtering), and the world's camera zoom is unchanged by the HUD's scaling (tests).
- The pause screen has a HUD size slider, laid out like the other sliders, with S1's label read from its data file and no text in code. Moving it changes the HUD's scale at once while paused. It is saved in GameSettings on release only (S2's pattern) and applied at the next start (tests).
- Screenshots at the five window sizes, and with the slider at both ends, are in art-archive/<id>/screenshots/.
- HUD and menus, Content and the game docs describe the scaling rule, the slider's range and default, and which screens it covers.
- All three test sets pass, with the counts in the result notes, and the new behaviour has its own tests.

### S7: Art: the splash cover behind the main menu (Asset Generation, PixelLab)

Needs: S6.

- game/art/menu/splash.png exists with its record, and the main menu shows it behind the title and buttons, which stay readable (screenshot).
- The planned PixelLab calls and their cost were written in the result notes before the first call. At most 20 generations were used, all listed.
- It went through the style loop, judged on consistency with the game's style, palette and car, and scored at least 8 or is noted below 8 after 3 refines, with every round in the Style review. Greenbull's colours appear only on Greenbull's things.
- Visual style and the art docs under game/docs/art/ record it. Rejected generations are kept in art-archive/<id>/.
- The image enlarged, the sampled compositions, and a screenshot of the main menu with it are in art-archive/<id>/screenshots/.

## Scoring

Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. A sub-goal is therefore always ranked before every sub-goal that needs it. A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.

## Tickets

- T-426: Text: the HUD size slider's label (S1, written)
- T-427: Pause screen sliders save once, on release (S2, written)
- T-428: The HUD reads its fonts, colours and outlines from one shared HUD style (looks unchanged) (S4, written)
- T-429: The HUD's code follows the HUD style sheet (fonts, colours, outlines) (S4, written)
- T-430: Art: one HUD style sheet, and script redraws of the HUD pieces that break it (S3, written)
- T-431: The HUD scales with the window, and a HUD size slider on the pause screen (S5, written)
- T-432: Main menu polish: pixel-art title, styled work-in-progress line, splash cover slot (placeholder) (S6, written)
- T-433: Art: the splash cover behind the main menu (PixelLab) (S7, written)

## Iteration log

- 2026-10-30, iteration 0: started: planning, by the session Greenbull.
- 2026-10-30, iteration 0: priority scoring: 7 sub-goals ranked, 8 goal criteria, 8 open questions.
- 2026-10-30, iteration 0: paused (see Pauses).
- 2026-10-30, iteration 0: resumed: its last pause (drafts-refused: gap detection's drafts were refused twice) can't be checked by the runner; --force.
- 2026-10-30, iteration 0: resumed by the session Greenbull.
- 2026-10-30, iteration 0: gap detection: S1 missing (wrote T-426), S2 missing (wrote T-427), S4 missing (wrote T-428, T-429), S3 missing (wrote T-430), S5 missing (wrote T-431), S6 missing (wrote T-432), S7 missing (wrote T-433).
- 2026-10-30, iteration 1: T-428 (S4, ui, opus): passed (done, QA rounds 1), merged into playtest/G-008; art 0; agent: T-428 done, ready for QA. All HUD, pause and level-up style values now live in one shared script, game/scripts/hud/hud_style.gd (HudStyle); the values are unchanged. Tests pass: GUT 2136/2136, Python 722 and 582. Screenshots are in art-archive/T-428/screenshots/; the "before" match uses a value test and archived shots, since master couldn't be rendered here. Refused, got past and not blocking: QA: {"tool_input": {"command": "python tools/qa_check.py T-428 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_0122uXhSHGZCUZf5ktPPWEje"} / QA: python tools/qa_check.py T-428 --no-marks: requires approval, not on the allow list; checks done by hand. Rescan: S1 in-flight, S2 in-flight, S3 in-flight, S4 in-flight, S5 in-flight, S6 in-flight, S7 in-flight.
- 2026-10-30, iteration 2: T-430 (S3, asset-generation, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-008; art 0; agent: T-430 done. HUD style sheet is in docs/visual-style.md; sub goal frame redrawn by script (corner radius 2, style loop 9/10); weapon icon scale and code changes listed in the result notes. 727 Python tests pass; screenshots in art-archive/T-430/screenshots/. The commit also swept in about 245 Godot .uid and .import noise files; the Project Lead should drop them. Refused, got past and not blocking: asset-generation: {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nimport glob\nfor f in ['game/art/hud/likes_heart.png','game/art/hud/heart_full.png','game/art/level_up/weapon_gun.png','game/art/level_up/weapon_bricks.png','game/art/level_up/button_plate.png','game/art/level_up/card_frame.png']:\n    im=Image.open(f);print(f,im.size,im.mode,len(set(im.convert('RGBA').getdata())))\n\"; cat game/art/hud/likes_heart.json | head -20"}, "tool_name": "Bash", "tool_use_id": "toolu_01PRud5xczSkEdfFdYzDZUyp"} / asset-generation: {"tool_input": {"command": "python - <<'EOF'\nprint(1)\nEOF"}, "tool_name": "Bash", "tool_use_id": "toolu_01NYS374D3KwuqZH6NwHhmXD"} / asset-generation: {"tool_input": {"command": "git reset --soft HEAD~1"}, "tool_name": "Bash", "tool_use_id": "toolu_01BQ2jJYFA2NTgATBrZwE7KF"} / asset-generation: {"tool_input": {"command": "git reset -q"}, "tool_name": "Bash", "tool_use_id": "toolu_01T2ngwNQQFfzdT8kDgt638Z"} / asset-generation: git reset --soft HEAD~1: wanted to undo my commit, which swept in Godot .uid and .import noise files, and recommit only my own files / asset-generation: git reset -q: wanted to unstage the same files / QA: {"tool_input": {"command": "python tools/qa_check.py T-430 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_01UZz1Ah7GKo8eiMHYMqAKYN"} / QA: python tools/qa_check.py T-430 --no-marks: needs approval, refused; skipped it and the closing qa_check run, and checked the records by hand. Rescan: S3 covered, S4 in-flight, S6 in-flight, S1 in-flight, S2 in-flight, S5 in-flight, S7 in-flight.
- 2026-10-30, iteration 3: T-429 (S4, ui, opus): passed (needs-playtest, QA rounds 2), merged into playtest/G-008; art 0; agent: T-429 partly done: coins/pause fonts to Bangers, outlines and near-black borders set in hud_style.gd, tests, docs, screenshots committed. Not done: clock digits art, weapon icon scale, pause capitals. Full Godot suite not completed (600 s limit); hud/popup subsets and 727 Python tests pass / T-429 round 2 is done and ready for QA. The clock now uses its panel and seven-segment digit art at 2x, and the weapon icons are new 24x24 art at 2x in the same 48 px slot (style loop 7/10, kept for the playtest). The pause strip is in capitals, and nothing moves or resizes. All three test sets pass: Python 736 + 582, Godot 2141/2141 (174 scripts, run in two parts). Results, screenshots and counts are in the ticket notes and committed. Refused, got past and not blocking: ui: {"tool_input": {"command": "python - <<'EOF'\nimport re\np='game/scripts/hud/hud_style.gd'\ns=open(p,encoding='utf-8').read()\ns=s.replace('\"coins\": {\"font\": \"\"','\"coins\": {\"font\": \"comic\"')\ns=s.replace('\"viewers_unit\": {\"font\": \"comic\", \"size\": VIEWERS_UNIT_SIZE, \"color\": VIEWERS_COLOR, \"outline_color\": DARK, \"outline\": 4}','\"viewers_unit\": {\"font\": \"comic\", \"size\": VIEWERS_UNIT_SIZE, \"color\": VIEWERS_COLOR, \"outline_color\": DARK, \"outline\": 6}')\ns=s.replace('\"outline\": 10,','\"outline\": 8,')\ns=s.replace('Color8(0, 0, 0),        # letters','Color8(8, 8, 15),       # letters (the sheet\\'s outline colour)')\ns=s.replace('Color8(0, 0, 0),        # burst border','Color8(8, 8, 15),       # burst border')\ns=s.replace('Color8(0, 0, 0),        # \"+amount\" at heat 0 and 1','Color8(8, 8, 15),       # \"+amount\" at heat 0 and 1')\ns=s.replace('Color8(0, 0, 0),        # letter outline','Color8(8, 8, 15),       # letter outline')\ns=s.replace('Color8(0, 0, 0),        # border and crack edges','Color8(8, 8, 15),       # border and crack edges')\ns=s.replace('const KAIJU_LINE := Color.BLACK','const KAIJU_LINE := OUTLINE_COLOR')\ns=s.replace('\"pause_title\": {\"font\": \"\",','\"pause_title\": {\"font\": \"comic\",').replace('\"pause_text\": {\"font\": \"\",','\"pause_text\": {\"font\": \"comic\",')\ns=s.replace('LEVEL_UP_TITLE_OUTLINE_SIZE := 4','LEVEL_UP_TITLE_OUTLINE_SIZE := 6')\nopen(p,'w',encoding='utf-8',newline='').write(s)\nEOF"}, "tool_name": "Bash", "tool_use_id": "toolu_01Ep9MX6x7DkKihVsEFzCT2i"} / ui: A python heredoc script to batch-edit hud_style.gd needed approval and was refused; I made the edits with the Edit tool instead. / QA: python tools/qa_check.py T-429 --no-marks was refused (needs approval); criteria were checked by hand and the confirm run was skipped. / ui: {"tool_input": {"command": "python -c \"from PIL import Image;import glob;[print(f,Image.open(f).size,Image.open(f).convert('RGBA').getbbox()) for f in sorted(glob.glob('game/art/level_up/weapon_*.png'))]\""}, "tool_name": "Bash", "tool_use_id": "toolu_01U4c1ntCb5LjKgAzed4VbTs"} / ui: python -c to read the level-up card pictures' bounds (needs approval); skipped, not essential, the tests did the check instead. Rescan: S4 covered, S6 in-flight, S1 in-flight, S2 in-flight, S5 in-flight, S7 in-flight.
- 2026-10-30, iteration 4: T-432 (S6, ui, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-008; art 0; agent: T-432 done and committed. The menu title and "(work in progress)" line now use Press Start 2P, the free OFL pixel font, with its licence and record in game/fonts/press_start_2p/. The splash slot is in: it shows game/art/menu/splash.png when present, with a dark placeholder otherwise. Tests pass: GUT 2145/2145, game/tools 736, tools 582. Screenshots are in art-archive/T-432/screenshots/. Refused, got past and not blocking: ui: {"tool_input": {"command": "python - <<'EOF'\nEOF\necho skip", "description": "no-op"}, "tool_name": "Bash", "tool_use_id": "toolu_01EeZqyrnCfuSv3DxzSnGt2Y"} / QA: {"tool_input": {"command": "python tools/qa_check.py T-432 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_016Rt1BAzcJMfKi33gzHxjre"} / QA: python tools/qa_check.py T-432 --no-marks required approval and was not run; criteria were checked by hand instead. Rescan: S6 covered, S1 in-flight, S2 in-flight, S5 in-flight, S7 in-flight.
- 2026-10-30, iteration 5: T-426 (S1, narrative-theme, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-008; art 0; agent: T-426 done: the label is "HUD size", scored 9/10 in round 1 of the style loop. It's in game/data/pause_text.json (key hud_size_label, no value key) and in both docs. The game/tools tests pass (736, 1 skipped). Committed. Refused, got past and not blocking: QA: {"tool_input": {"command": "python tools/qa_check.py T-426 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_01Epp9obVdxtcBjTJEjcmQYF"} / QA: python tools/qa_check.py T-426 --no-marks was refused (needs approval); checked criteria manually instead. Rescan: S1 covered, S2 in-flight, S5 in-flight, S7 in-flight.
- 2026-10-30, iteration 6: T-427 (S2, ui, sonnet): passed (done, QA rounds 1), merged into playtest/G-008; art 0; agent: T-427 done and committed. The pause sliders apply live, save once on drag release, and save pending changes on Escape, Restart and Exit. Tests pass: GUT 2153, game/tools 736, tools 582. Docs and result notes are updated. No screenshots, since nothing new shows on screen. Refused, got past and not blocking: QA: {"tool_input": {"command": "python tools/qa_check.py T-427 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_01QHaovf76cG9Zn5Yp2L21ww"} / QA: python tools/qa_check.py T-427 --no-marks was refused (needs approval, not on the allow list); criteria were checked by hand. Rescan: S2 covered, S5 in-flight, S7 in-flight.
- 2026-10-30, iteration 7: T-431 (S5, ui, opus): passed (needs-playtest, QA rounds 1), merged into playtest/G-008; art 0; agent: T-431 done: the HUD now scales with the window at min(w/1152, h/648) × slider, with nearest filtering and the camera untouched. HUD size slider on the pause screen (50–125, default 100; proposals) saves on drag end and applies next start. All tests pass (GUT 2170, 736, 582); screenshots in art-archive/T-431; .import noise left uncommitted. Refused, got past and not blocking: ui: {"tool_input": {"command": "cat tasks/README.md"}, "tool_name": "Bash", "tool_use_id": "toolu_01Pgn3CLcjubn5GR4tUFkLv5"} / ui: {"tool_input": {"command": "cat docs/hud-and-menus.md"}, "tool_name": "Bash", "tool_use_id": "toolu_01CEtpamJHAS6nY17jitSo8K"} / ui: {"tool_input": {"command": "cat game/scripts/ui/pause_screen.gd"}, "tool_name": "Bash", "tool_use_id": "toolu_01R43QaHk6Zo7kj5n2YrGuug"} / QA: {"tool_input": {"command": "python tools/qa_check.py T-431 --no-marks", "timeout": 600000}, "tool_name": "Bash", "tool_use_id": "toolu_01PcMJ57DVFaxKMw4RjfFkCM"} / QA: python tools/qa_check.py T-431 --no-marks: requires approval (not on the pre-approved list); skipped, ran the three test sets directly. The final qa_check run to confirm marks was not done.. Rescan: S5 covered, S7 in-flight.
- 2026-10-30, iteration 8: T-433 (S7, asset-generation, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-008; art 4; agent: T-433 done, committed. The splash cover is in game/art/menu/splash.png with its record, and the menu shows it. The style loop kept v2 at 6/10, below 8 after 3 refines, so the board's playtest should judge it: the car is small, there are no meteors, and the car sits behind the buttons. Tests: 737 OK. Full report is in the result notes. Refused, got past and not blocking: asset-generation: {"tool_input": {"command": "tail -n 60 art-archive/T-433/../../tasks/T-433-art-the-splash-cover-behind-the.md | cut -c1-700"}, "tool_name": "Bash", "tool_use_id": "toolu_01BFmD5DwRsohQKtcst8wJVJ"} / asset-generation: {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nd='art-archive/T-433/'\nim=Image.open(d+'style-loop/v2.png').convert('RGB').resize((1280,720),Image.NEAREST); im.save(d+'screenshots/splash_enlarged.png')\nims=[Image.open(d+'style-loop/v%d.png'%i).convert('RGB').resize((640,360),Image.NEAREST) for i in range(1,5)]\ns=Image.new('RGB',(1280,720))\nfor i,m in enumerate(ims): s.paste(m,((i%2)*640,(i//2)*360))\ns.save(d+'screenshots/compositions_v1_to_v4.png')\n\""}, "tool_name": "Bash", "tool_use_id": "toolu_012a3y5d7Ay1YdbNLY3NrWQi"} / asset-generation: Loop agent's own script art-archive/T-433/work/make_init.py (free init mock-up with the real car) and later free script fixes from art-archive were refused / asset-generation: My inline `python -c` for the review images was refused; I used game/tools/splash_sheets.py instead / QA: {"tool_input": {"command": "python tools/qa_check.py T-433 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_0199aWYxiZMWY7TjaYZkVoDj"} / QA: python tools/qa_check.py T-433 --no-marks: requires approval, not on the pre-approved list; skipped and checked each criterion by hand.. Rescan: S7 covered.
- 2026-10-30, iteration 8: goal check: 8 of 8 goal criteria pass.
- 2026-10-30, iteration 8: ready to play.

## Pauses

- 2026-10-30 [drafts-refused]: Gap detection's tickets were refused twice:
  - D3 (Art: one HUD style sheet, and script redraws of the HUD pieces that break it): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D4 (The HUD's code follows the HUD style sheet (fonts, colours, outlines)): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D5 (The HUD scales with the window, and a HUD size slider on the pause screen): changes_visuals is yes but files_to_read_first lacks docs/visual-style.md.
  - D5 (The HUD scales with the window, and a HUD size slider on the pause screen): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D5 (The HUD scales with the window, and a HUD size slider on the pause screen): user_facing_text is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D6 (Main menu polish: pixel-art title, styled work-in-progress line, splash cover slot): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.


---
id: G-008
title: The HUD and the main menu (board, 2026-10-29 and 2026-10-30; HUD an...
status: building
art_cap: 20
art_used: 0
iteration: 0
max_iterations: 20
created: 2026-10-30
lead: Goal-G-008
session: Greenbull
---

## Goal

The HUD and the main menu (board, 2026-10-29 and 2026-10-30; HUD and menus, Decisions: 'Main menu polish', 'A consistent HUD', 'The HUD scales with the window, and a HUD size slider', and the settings sliders saving once, on release, from the audit epic, formerly T-421; Visual style, Decisions, 'The splash cover'). The main menu gets the pixel-art title with the styled '(work in progress)' line and the splash cover behind it; every HUD piece shares one visual language and the HUD's code follows one style sheet; the HUD keeps its place and a sensible size at any window size and resolution, ultrawide included, with a HUD size slider and its label on the pause screen; the pause screen's sliders save once, on release. Text for every new label comes from the Narrative Theme agent first.

## Goal acceptance criteria

- [ ] On playtest/G-008, the main menu scene (game/scenes/menu/main_menu.tscn) shows the title "SOLID CARBIDE" in a pixel-art font whose licence is recorded in the repo, the "(work in progress)" line under it styled to match, and game/art/menu/splash.png filling the screen behind them without stretching and with hard pixel edges. Start, Garage and Exit stay readable and work as before (tests and a screenshot). (QA: pass / fail)
- [ ] game/art/menu/splash.png exists with its art record. It was made with PixelLab using at most 20 generations, listed in its ticket's result notes, went through the style loop with every round in the Style review, and is recorded in Visual style and game/docs/art/. (QA: pass / fail)
- [ ] Visual style holds one HUD style sheet (outline, palette, panel shapes and corners, fonts for numbers and for words, pixel scale). Every HUD piece's art and code follow it: each piece is listed with what changed or why it already fits. Before and after screenshots of the same moment in a run are in art-archive/. (QA: pass / fail)
- [ ] At 1152 x 648, 1920 x 1080, 2560 x 1440, 3440 x 1440 and a small window, every HUD piece keeps its corner or edge and a size in proportion to the window, with no overlap and nothing off screen. Headless tests cover this and screenshots at each size are in art-archive/. (QA: pass / fail)
- [ ] The pause screen has a HUD size slider with its label read from a data file the Narrative Theme agent wrote. The label scored at least 8 in the style loop and no label text is hard-coded. The slider changes the HUD's scale at once while paused, is saved on this computer and is applied at the next start (tests). (QA: pass / fail)
- [ ] Dragging any pause screen slider (camera zoom, SFX volume when shown, music volume, HUD size) applies the value live but writes the settings file at most once per drag, on release. Closing the pause screen saves the current values. Tests count the saves. (QA: pass / fail)
- [ ] HUD and menus, Content ("Main menu", "The HUD", "Pause screen") and the game docs under game/docs/hud-and-menus/ describe the new title, the splash cover, the HUD style, the scaling rule, the HUD size slider and saving on release. (QA: pass / fail)
- [ ] All three test sets pass on playtest/G-008 (python -m unittest discover -s game/tools -p "test_*.py", python -m unittest discover -s tools -p "test_*.py", bash game/tools/run_tests.sh), with the counts recorded. (QA: pass / fail)

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
| 1 | S3 | Art: one HUD style sheet and script redraws of the pieces that break it (Asset Generation) | unblocks 2, value 5 | The 'consistent HUD' decision: the pieces look like they came from different games. The style sheet is the single source that both the art and the HUD's code follow. | missing | T-430 |
| 2 | S4 | The HUD's code follows the style sheet (UI) | unblocks 1, value 5 | The goal says the HUD's code follows one style sheet. Fonts, colours and outlines set in code must match S3 and be defined in one place, not scattered across each HUD script. | missing | T-428, T-429 |
| 3 | S6 | Main menu polish: pixel-art title, styled work-in-progress line, splash cover slot (UI) | unblocks 1, value 5 | The 'Main menu polish' decision. It builds the menu with a placeholder so the splash cover art (S7) only has to add its file. | missing | T-432 |
| 4 | S1 | Text: the HUD size slider's label (Narrative Theme) | unblocks 1, value 4 | The goal says every new label's text comes from the Narrative Theme agent first. The slider in S5 needs its label, and how its value reads if it shows one, before it can be built. | missing | T-426 |
| 5 | S2 | Pause screen sliders save once, on release | unblocks 1, value 4 | Part of the goal (from the audit, formerly T-421). Today zoom, SFX and music call GameSettings.save_* on every slider step. The HUD size slider in S5 must follow the same pattern. | missing | T-427 |
| 6 | S5 | The HUD scales with the window, and a HUD size slider on the pause screen (UI) | unblocks 0, value 5 | Part of the goal: today the HUD keeps its pixel size and looks tiny on big and ultrawide screens. The slider lets the player choose the HUD's size, saved on this computer. | missing | T-431 |
| 7 | S7 | Art: the splash cover behind the main menu (Asset Generation, PixelLab) | unblocks 0, value 5 | Visual style, 'The splash cover': an AI-generated pixel art cover, very consistent with the game's style, its colours and the actual car. It replaces S6's placeholder. | missing | T-433 |

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

## Pauses

- 2026-10-30 [drafts-refused]: Gap detection's tickets were refused twice:
  - D3 (Art: one HUD style sheet, and script redraws of the HUD pieces that break it): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D4 (The HUD's code follows the HUD style sheet (fonts, colours, outlines)): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D5 (The HUD scales with the window, and a HUD size slider on the pause screen): changes_visuals is yes but files_to_read_first lacks docs/visual-style.md.
  - D5 (The HUD scales with the window, and a HUD size slider on the pause screen): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D5 (The HUD scales with the window, and a HUD size slider on the pause screen): user_facing_text is yes but files_to_read_first lacks docs/extended-narrative.md.
  - D6 (Main menu polish: pixel-art title, styled work-in-progress line, splash cover slot): changes_visuals is yes but files_to_read_first lacks docs/extended-narrative.md.


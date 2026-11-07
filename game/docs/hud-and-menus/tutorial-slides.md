# Tutorial slides

(Tasks T-382, T-485 and T-562, UI Agent. What the slides say and show: `docs/hud-and-menus.md`, Content, "Tutorial slides and trick list". The index is [../../README.md](../../README.md).)

## Scenes and scripts

- `scenes/menu/tutorial_slides.tscn`, script `scripts/menu/tutorial_slides.gd` (`TutorialSlides`), since T-562: six slides (the content loop, four trick slides, Survive the stream) on a 1280 x 720 stage scaled to the window. It has a left and a right arrow, six dots and a **Skip** button (jumps to the last slide). The last slide has the **Go live** button (`button.start`, with the LIVE badge) and the **Don't show again** checkbox. What each slide shows: `docs/hud-and-menus.md`, Content, "The interactive slides (T-562)".
- **Practice windows (T-562):** each trick slide has a `PracticeWindow` panel (600 x 400 at (565, 214)) holding a `SubViewportContainer` (`stretch`) and its `SubViewport`. The first time the slide shows, `_ensure_practice(i)` instances `practice_scene_path` (default `PRACTICE_SCENE`, `res://scenes/run/practice_session.tscn`, T-561's scene) into that viewport and calls `setup(<trick>)` with `TRICK_SLIDES[i][1]` (`drift`, `alt_drift`, `air_spin`, `grind`). It connects `completed` to the slide's success label. `_apply_practice_state()` calls `set_focused(true)` and `start()` on the showing slide's session, and `set_focused(false)` and `pause()` on the others, and on all of them when the slides are hidden. Sessions are kept, so a count survives leaving the slide. The seam: when the scene doesn't exist, the window stays an empty frame (one warning) and everything else works. Duck-typed: the slide only uses `setup`, `start`, `pause`, `set_focused`, `is_completed` and the `completed` signal. `_fit()` scales each container by 1/s and sizes it s times bigger, so the viewport renders at screen pixels (the session's camera zoom follows its viewport's height).
- **Success message:** `success_messages[i]`, the `tutorial.success` label laid exactly over window i, shown on the third success (`completed`) with a 0.25 s pop.
- `scripts/menu/clip_player.gd` (`ClipPlayer`): plays a clip from `art/tutorial/clips/<name>_sheet.png` and `<name>_sheet.json` (frame size, columns, each frame's own duration from the GIF), made by `python game/tools/gif_to_sheet.py` (test `game/tools/test_gif_to_sheet.py`). It loads when first shown and only advances while visible; `advance(delta)` is its whole clock. No longer used by the slides since T-562 (the practice windows replaced the clips); kept for the clips' own tests and tools.
- `scenes/menu/trick_list.tscn`, script `scripts/menu/trick_list.gd` (`TrickList`): the seven tricks in a grid of four columns, each an illustration with its name under it. Used by the pause screen's trick list panel (the redrawn slide 2 no longer shows it; it shows the long drift illustration in its first step).
- **Signal:** `start_pressed(dont_show_again: bool)`, sent when Start is pressed, with the checkbox state. The screen does not start the run and does not save the setting: the screen flow connects it to the main menu's Start and calls `GameSettings.save_tutorial_hidden(true)` when the flag is true.
- **Setting:** `GameSettings.load_tutorial_hidden()` / `save_tutorial_hidden(bool)`, key `hidden` in section `tutorial` of `user://settings.cfg`, false by default. `tests/unit/test_tutorial_setting.gd`.

## Text

No string is written in the scripts. `TrickList.text("<dotted key>")` reads `data/tutorial_text.json` (the same lookup as the recap's); the trick names are `trick.<id>`. Headlines, labels and captions are stored in sentence case and shown in capitals (`Label.uppercase`). The arrows have no text: a triangle drawn in code, with the `arrow.left` and `arrow.right` lines as their tooltips. The checkbox's box is drawn in code too.

## Trick illustrations (for the art tickets)

- **Size: 64 x 48 pixels per trick**, a still image, drawn at a whole-number scale of **3** (192 x 144 on screen, 1152 x 648 window), nearest filtering.
- **One fixed path per trick:** `game/art/tutorial/tricks/<trick id>.png`, with the ids `extended_drift`, `three_sixty`, `alternate_drift`, `air_one_eighty`, `air_three_sixty`, `airtime`, `thread_the_needle` (`game/docs/driving/tricks.md`).
- **The chosen set (T-385): the script-drawn set** (T-383, `art-archive/T-383/script/`, made by `game/tools/build_trick_illustrations.py`) is in `game/art/tutorial/tricks/`, picked over the PixelLab set (T-384, still in `art-archive/T-384/pixellab/`) because it shows the movement more clearly at 64 x 48 (5 tricks of 7; Visual style, Decisions). Comparison sheet: `art-archive/T-385/comparison.png` (`game/tools/compare_trick_sets.py`).
- **Exported property `illustration_folder`** on `TrickList` (default `res://art/tutorial/tricks`). An art ticket points it at its own set's folder to screenshot it, with `<folder>/<trick id>.png` read the same way. A PNG found there (imported, or loaded straight from disk) is used. **No placeholder any more (T-390):** the code-made placeholder (a dusk-blue 64 x 48 picture with a pale pink border and arrow, `_make_placeholder`, `is_placeholder`) is deleted; a missing file shows an empty picture and a warning. `is_loaded(id)` tells whether the texture came from its PNG.
- **Files shown on slide 2 and in the pause trick list (T-390):** `game/art/tutorial/tricks/{extended_drift,three_sixty,alternate_drift,air_one_eighty,air_three_sixty,airtime,thread_the_needle}.png`, each 64 x 48, drawn at scale 3 with nearest filtering (`tests/unit/test_trick_list.gd` checks each texture, the filter and the scale).
- Changing `illustration_folder` while the scene is in the tree rebuilds the list; `rebuild()` does it by hand.

## Keyboard and focus (proposal for the playtest; T-562)

- **Left and Right arrow keys:** previous and next slide on every slide (they never reach a practice window: the slide's `_input` takes them). **A and D:** the same, but only on the loop slide and the last slide.
- **Trick slides:** the practice window has the keyboard as soon as its slide shows. W, A, S, D, Space and R pass through the `SubViewportContainer` to the session and the car. The arrows and Skip are set to `FOCUS_NONE` there and the focus is released, so they work by mouse only and no key (Space, Enter, Tab) presses a button. Leaving a trick slide gives them `FOCUS_ALL` back.
- **Focus on the other slides:** slide 1, the right arrow; slide 6, Go live. **Enter or Space** presses the focused control there, and **Tab / Shift+Tab** move the focus.
- **Mouse:** click the arrows, Skip, the checkbox and Go live on any slide; on the grind slide, the gift's card inside the window.
- The arrow with nowhere to go is hidden (slide 1 has no left arrow, slide 6 no right arrow). Six small squares at the bottom show the slide (the current one a long bar).

## Tests and screenshots

- `tests/unit/test_tutorial_slides.gd` covers:
  - the six slides in order with T-559's texts, the loop steps and the instructions, the dots and the kickers;
  - the arrows, Skip, Go live and the checkbox, by signal and by mouse;
  - keys: fresh presses only; the arrow keys everywhere; A and D only on slides 1 and 6; A, D and Space reaching the practice and pressing nothing on every trick slide; the arrow keys not reaching it;
  - the practice windows: each set to its trick in its SubViewport; only the showing one running and focused; the count kept; the success message only after the third success, over its window only; a missing scene; the scaling.
- These tests use `tests/fixtures/fake_practice_session.tscn`, a stand-in with T-561's API. `tests/unit/test_tutorial_practice_real.gd` runs the same checks with the real scene and stays pending until T-561's scene is in the branch.
- Other tests: `tests/unit/test_trick_list.gd`, `tests/unit/test_tutorial_setting.gd`, `tests/unit/game/test_tutorial_flow.gd`.
- Screenshots: `bash game/tools/screenshot.sh res://tests/fixtures/tutorial_slides_demo.tscn out.png 40` (the fixture's `slide` picks the slide, `_2` to `_6` are the others; its `drive`, `take_gift` and `complete` drive the practice car, take the grind's gift and play three successes, as in `_drive` and `_success`). T-562's are in `art-archive/T-562/screenshots/`.

**Key pad (task T-491).** `scripts/menu/key_pad.gd` (`KeyPad.attach(clip_player, key_px)`) draws a W A S D pad in a clip's bottom-right corner and lights the keys of `ClipPlayer.held_keys()` (the sheet JSON's `keys_per_frame`), refreshed on `ClipPlayer.frame_changed`. Slide 2's three clips have one; slide 1's does not. The trick list scene is no longer on slide 2 (it is only in the pause screen).

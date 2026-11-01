# Tutorial slides

(Tasks T-382 and T-485, UI Agent. What the slides say and show: `docs/hud-and-menus.md`, Content, "Tutorial slides and trick list". The index is [../../README.md](../../README.md).)

## Scenes and scripts

- `scenes/menu/tutorial_slides.tscn`, script `scripts/menu/tutorial_slides.gd` (`TutorialSlides`): four slides (T-485: Drive, Tricks bring gift packs, Missions, Survive the stream) on a 1280 x 720 stage scaled to the window, with a left and a right arrow, four dots and a **Skip** button (jumps to slide 4). Slide 4 has the **Go live** button (`button.start`, with the LIVE badge) and the **Don't show again** checkbox. What each slide shows: `docs/hud-and-menus.md`, Content, "The four redrawn slides (T-485)".
- `scripts/menu/clip_player.gd` (`ClipPlayer`): plays a clip from `art/tutorial/clips/<name>_sheet.png` and `<name>_sheet.json` (frame size, columns, each frame's own duration from the GIF), made by `python game/tools/gif_to_sheet.py` (test `game/tools/test_gif_to_sheet.py`). It loads when first shown and only advances while visible; `advance(delta)` is its whole clock. Four clips: `drift` on slide 1, `long_drift`, `alt_drift`, `ramp_jump` on slide 2.
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

## Keyboard and focus (proposal for the playtest)

- **Left arrow key or A:** previous slide. **Right arrow key or D:** next slide. At the ends they do nothing.
- **Enter or Space** presses the focused control; **Tab / Shift+Tab** move the focus (on slide 4 the checkbox, then Go live).
- **Focus on each slide:** slides 1 to 3, the right arrow; slide 4, the Go live button. So Enter, Enter, Enter, Enter starts the run. Skip is a button too (Tab to it).
- **Mouse:** click the arrows, the checkbox and the button.
- The arrow that has nowhere to go is hidden (slide 1 has no left arrow, slide 4 no right arrow). Four small squares at the bottom show the slide (the current one a long bar).

## Tests and screenshots

`tests/unit/test_tutorial_slides.gd` (four slides in order, dots, arrows, Skip, the signal with the box on and off, every text against the file, the retired keys unused, the clips' frames and timing, the pictures' files, keys, focus, Enter on Go live), `tests/unit/test_trick_list.gd` (names, placeholders, a PNG at the fixed path), `tests/unit/test_tutorial_setting.gd`. Screenshots: `bash game/tools/screenshot.sh res://tests/fixtures/tutorial_slides_demo.tscn out.png 40` (and `_2`, `_3`, `_4` for slides 2 to 4; the fixture sets the window to 1280 x 720).

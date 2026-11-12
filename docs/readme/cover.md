# README cover image

`cover.png` (1280 x 480) is the wide cover at the top of the root `README.md` (the board, 2026-11-12). It replaces the car image at the top right; `car.png` stays in this folder, no longer shown.

- Source: `game/art/menu/splash.png` (320 x 180), the main menu's splash, the board's own picture (T-445). Record: `game/art/menu/splash.json`.
- Crop: a 320 x 120 band, rows 36 to 155, so the helicopter, the kaiju and the car all stay in.
- Scale: exactly 4x, nearest-neighbour, no smoothing.
- Made by `tools/make_readme_cover.py`. No PixelLab call.

# README clips

`clips/` holds the seven clips the root `README.md` links to, recorded by the board while playing (2026-11-12) and copied byte for byte from `C:\Users\andre\Downloads\clips`. Each file name says what the clip shows. The README's titles come from the file names, except where the board chose its own: the two grind clips share the title Grinds, and the massive bricks wave is titled Obliterate Enemies. The board took the air spin ramp clip out. GitHub does not play a repository's video inside a README, so the README shows an animated `.webp` preview of each clip (640 wide, 20 frames a second, no sound) that links to the full `.mp4`. The previews are made by `tools/make_readme_clip_previews.py`, which needs ffmpeg (`winget install Gyan.FFmpeg`).

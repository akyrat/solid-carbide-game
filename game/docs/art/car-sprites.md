# Car sprites

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## The first final car sprite (T-014)

`game/art/car/car_sw_front.png` (128 x 128, with its record `car_sw_front.json` and the PixelLab log entry): the dark-green 1967 Mustang GT with two white stripes, nose at the bottom-left of the screen (PixelLab direction `south-west`). It matches frame 4 of the placeholder isometric sheet (heading 90 degrees, nose on screen at 153.43 degrees, down-left along the isometric axis). It is frame 4 of the final car sheet (T-101, next section), unchanged. Check it against Visual style's rules with `python game/tools/style_rules.py art game/art/car/car_sw_front.png --size 128x128 --max-colors 33 --allow-red 230,110,102` (tests: `game/tools/test_style_rules.py`). The approved sprite has 33 colours. Its tail lights' pale red (230, 110, 102) needed `--allow-red` under the old rule 6 (T-290); since red is no longer reserved (T-298) the flag does nothing for it.

Archived versions (2026-10-12): the board approved this original, shadow included. The other versions (a script-made shadowless copy, a PixelLab inpaint, a fresh generation) and T-003's test art are not game art; they are kept in `art-archive/` at the repo root, outside the Godot project, with a table of what each is in `art-archive/README.md`. `game/tools/remove_car_shadow.py` is kept; its test reads the archived copy.

## The car in 32 directions (T-102)

Since T-102, `game/art/car/car_iso.png` is 4096 x 128: one row of 32 frames of 128 x 128, 11.25 degrees apart (`step_deg` 11.25 in `car_iso.json`; `car_sprite.gd` reads it, no code change). Frame 2k is T-101's frame k, unchanged (the approved sprite is now frame 8). Each odd frame is a PixelLab `/rotate` of one T-101 frame by `direction_change` 16 (16 calls, one round), palette-mapped and centred like T-101's frames, and placed by where it landed: `build_car_sheet32.py` measures the long axis of the car's body (shadow left out) and puts each raw between the two T-101 frames it falls between (`position_between_neighbours`, 0 to 1, per frame in the JSON, with the estimated nose angle next to the ideal one).

- **Built by** `python game/tools/build_car_sheet.py` (T-101's 16-frame sheet, now written to `art-archive/T-102/car_iso_16_t101.png` + `.json`), then `python game/tools/build_car_sheet32.py` (the 32-frame sheet; `--measure` only prints where each raw landed), then `python game/tools/build_car_noshadow.py` (the shadowless copy, 32 frames). All byte-identical every run. The PixelLab calls were made by `python game/tools/generate_car_inbetweens.py --run` (it never calls again for a raw that exists; `--plan` prints the calls). Raws and records: `art-archive/T-102/`. Tests: `game/tools/test_build_car_sheet32.py`, `test_build_car_sheet.py`, `test_build_car_noshadow.py` (Python), `test_car_final_sheet.gd`, `test_car_noshadow_in_air.gd`, `test_drift_prototype.gd` (GUT).
- **Check the rules:** `python game/tools/style_rules.py art game/art/car/car_iso.png --size 128x128 --frames 32 --max-colors 33 --allow-red 230,110,102` (the tail lights' red, as for T-014's sprite above).
- **Turning GIFs:** fixtures `res://tests/fixtures/car_turn_gif_run.tscn` and `car_turn_gif_air.tscn` (a run from the main menu, the car stopped and turned through a full circle, one viewport image per 3.75 degrees, into the folder in `TURN_GIF_DIR`), then `python game/tools/make_turn_gif.py <dir> <out.gif> [--up PX]` crops around the car and writes the GIF.

## The final car sheet (T-101)

T-101's sheet, kept as `art-archive/T-102/car_iso_16_t101.png` since T-102 (above): one row of 16 frames of 128 x 128 and its JSON, the pixel-art car in 16 directions, in T-013's layout and JSON convention. What follows describes the 16 frames; in the game they are the even frames of the 32-frame sheet. The game draws it in the isometric view (the run and the drift prototype); the flat view keeps the placeholder (Visual style, Decisions).

- **Frames:** frame 4 is T-014's approved sprite, unchanged. The other even frames come from one PixelLab `/generate-8-rotations-v3` call on that sprite, and each odd frame from a PixelLab `/rotate` of the frame before it by 22 degrees. The raw PixelLab frames are not game-ready on their own (49 to 272 colours), so they and their records are archived in `art-archive/T-101/frames/` (listed in `art-archive/README.md`), where the build script reads them; `car_iso.json` lists the source of each frame, its world heading, the nose's ideal screen angle and the angle actually seen (PixelLab's isometric diagonals are flatter than the game's 2:1, so the two differ by up to about 20 degrees, and more in frame 11; T-101's result notes).
- **Built by** `python game/tools/build_car_sheet.py` (run from the repo root; byte-identical every run). It adds no new pixels: it maps every opaque pixel to the nearest colour of the approved sprite's 33-colour palette (PixelLab's rotations come back with 49 to 272 colours) and moves each frame by whole pixels so its bounding-box centre sits where the approved sprite's does. Tests: `game/tools/test_build_car_sheet.py` (Python) and `game/tests/unit/test_car_final_sheet.gd` (GUT).
- **Layout values:** frame 128 x 128, `center_px` (64.5, 65.5), `px_per_unit` 32. The sprite is drawn at scale 16 / 32 = 0.5 in the 16 px per unit world, so the car is about 3 units long; 32 was fitted to the art, because PixelLab's car is not drawn in the game's exact projection (side views come out a little shorter, diagonal ones a little longer).
- **Check the rules** for every frame: `python game/tools/style_rules.py art art-archive/T-102/car_iso_16_t101.png --size 128x128 --frames 16 --allow-red 230,110,102` (run from the repo root; each frame has 27 to 33 colours, all from the approved sprite; the default limit is 30, so frames with 31 to 33 fail that check only; add `--max-colors 33` to check against the approved sprite's own count).
- **Shadowless copy (task T-204; no PixelLab):** `game/art/car/car_iso_noshadow.png` and `car_iso_noshadow.json` have the same size, frames, centre and fields as `car_iso.png` (the record adds `noshadow_note` and `noshadow_pixels_removed`). `python game/tools/build_car_noshadow.py` makes them from `car_iso.png`, which stays unchanged; running it again gives byte-identical files; tests in `game/tools/test_build_car_noshadow.py`. The drop shadow shares its near-black with the car's outline, windows and tyres, so per frame a pixel is made transparent only if it is one of the four near-black colours, connected to the transparent background through near-black pixels, outside the convex hull of the frame's other car pixels, and more than one step from such a pixel (so the thin outline stays). Every other pixel is copied as is: no new colours. Dark body panels inside the hull (under the sill between the wheels, under the bumpers) keep a little of the shadow, because it cannot be told from the body there. It is used only while the car is in the air (Drifting, Decisions, "No sprite shadow in the air"; task T-205 wires it in); on the ground the car keeps `car_iso.png`. Screenshots of every frame, original next to shadowless: `art-archive/T-204/screenshots/`.
- **Screenshots** of the car in a run started from the main menu, in any direction: `CAR_HEADING_DEG=<degrees> bash game/tools/screenshot.sh res://tests/fixtures/car_art_from_menu_demo.tscn screenshots/car.png 40` (heading 0 = frame 0; frame = heading / 22.5).


## Placeholder car sprite sheets

`game/tools/generate_car_sheets.gd` (tasks T-013 and T-018, Asset Generation Agent) draws the placeholder car: a plain 48 x 16 pixel rectangle, 3 times as long as it is wide (1 unit wide, 3 units long, 16 pixels per unit), with a differently coloured nose (the front 8 pixels), in 16 directions. It is drawn pixel by pixel by a script, not generated with PixelLab, and running it again gives byte-identical files. The drawing code is `game/tools/car_sheet_generator.gd`; its tests are `game/tests/unit/test_car_sheets.gd` (part of the GUT suite).

**Regenerate the sheets** (headless, from the repo root):

```
bash game/tools/generate_car_sheets.sh
```

```
powershell -ExecutionPolicy Bypass -File game/tools/generate_car_sheets.ps1
```

It overwrites, in `game/art/placeholders/car/`:

- `car_flat.png`: the flat top-down view.
- `car_iso.png`: the same rectangle in a 2:1 isometric projection, screen = (x - y, (x + y) / 2), flat (no box height).
- `car_flat.json` and `car_iso.json`: the layout below, the car's drawn size (`car_size_units`: width 1, length 3; `car_size_px`: width 16, length 48; `px_per_unit`: 16), a `record` (script, command, settings, placeholder) and the nose's world heading and screen angle for every frame.

**Layout** (the same for both sheets, and for the full-art sheet that replaced the isometric one in the game, which has its own frame size, centre and pixels per unit in its JSON):

- One row of 16 frames, each 80 x 80 pixels; frame `i` starts at x = `i * 80`. The sheet is 1280 x 80. (The 2:1 sheets from T-013 used 64 x 64 frames; the longer car needs up to about 36 pixels from the centre in the isometric view, so the frames grew.)
- Frames are indexed by the car's heading in the flat physics world (Godot axes, y down). Frame 0 is heading 0 degrees, nose along world +x (pointing right in the flat view, down-right in the isometric view). Each next frame adds 22.5 degrees, turning clockwise on screen, the way Godot's `rotation` grows. For a car body whose nose is +x at rotation 0, the frame is `posmod(roundi(rotation / deg_to_rad(22.5)), 16)` in both views.
- In the isometric sheet the world headings are 22.5 degrees apart, so the nose's angle on screen is not evenly spaced (the JSON lists it per frame).
- The car's centre is the point (40, 40) in frame pixel coordinates (top-left of the frame = 0, 0), the middle of the frame: a `Sprite2D` with `centered = true`, `hframes = 16` and no offset puts the car's centre on the node's origin.
- Scale: 1 world pixel = 1 sprite pixel in the flat view; the isometric sheet projects those same world pixels. One unit is 16 pixels, so to draw the car at its world size, scale the sprite by (world size of 1 unit) / `px_per_unit`. The size is the drawing only: the car's physics body is a 1 by 1 unit square (Drifting, Decisions), so the drawing sticks out 1 unit past it at the front and back.


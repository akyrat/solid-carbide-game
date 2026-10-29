# Game

The Godot 4 project lives here: scenes, scripts, data (JSON), art and audio. Everything for the game, in the same repository as the documents.

This file is an index only (T-346). The text that used to be here is in one file per topic under `docs/`, one folder per game area. Read only the file(s) your task needs. Each fact lives in one file; others link to it.

## setup/

- [docs/setup/setup.md](docs/setup/setup.md): Setup. Godot version and how the scripts find it.
- [docs/setup/folder-layout.md](docs/setup/folder-layout.md): Folder layout. What each folder under game/ holds.
- [docs/setup/tests.md](docs/setup/tests.md): Running the tests. GUT, Python and per-run tests, and how to write them.
- [docs/setup/screenshots.md](docs/setup/screenshots.md): Taking a screenshot. The screenshot tool.

## sound/

- [docs/sound/freesound.md](docs/sound/freesound.md): Downloading sounds from Freesound. The Freesound downloader.
- [docs/sound/sound-effects.md](docs/sound/sound-effects.md): Sound effects in the game. Where sound effects play.
- [docs/sound/audio-imports.md](docs/sound/audio-imports.md): Checking audio imports. The audio import checker.

## art/

- [docs/art/rebrand-sweep.md](docs/art/rebrand-sweep.md): Rebrand sweep. The Greenbull rebrand sweep (T-307).
- [docs/art/pixellab.md](docs/art/pixellab.md): Generating art with PixelLab. The PixelLab client and its rules.
- [docs/art/car-sprites.md](docs/art/car-sprites.md): Car sprites. The final car, 32 directions, the final sheet, placeholder sheets.
- [docs/art/ground-and-props.md](docs/art/ground-and-props.md): Ground and props. The first road tile, the map's ground, the boulders.
- [docs/art/bolder-enemy-outlines.md](docs/art/bolder-enemy-outlines.md): Bolder enemy outlines. The thicker outline on minion and kaiju sheets (T-340).
- [docs/art/bricks-art.md](docs/art/bricks-art.md): Bricks' art. The card image and the impact wave sheets, and the script that draws the wave (T-325).

## hud-and-menus/

- [docs/hud-and-menus/main-menu.md](docs/hud-and-menus/main-menu.md): Main menu. The main menu screen.
- [docs/hud-and-menus/popups.md](docs/hud-and-menus/popups.md): Trick popups. The trick popups.
- [docs/hud-and-menus/pause-screen.md](docs/hud-and-menus/pause-screen.md): Pause screen. The pause screen.
- [docs/hud-and-menus/camera.md](docs/hud-and-menus/camera.md): Camera options. The two camera options.
- [docs/hud-and-menus/hud.md](docs/hud-and-menus/hud.md): HUD. The HUD in the run, the sub goal square (T-337), the airtime and drift counters.
- [docs/hud-and-menus/livestream-hud-art.md](docs/hud-and-menus/livestream-hud-art.md): Livestream HUD art. The clock, viewers, sub-goal and heart pieces in art/hud/ and the script that builds them (T-339).
- [docs/hud-and-menus/level-up-screen.md](docs/hud-and-menus/level-up-screen.md): Level-up screen. The level-up screen, its art and animation.
- [docs/hud-and-menus/time-up-screen.md](docs/hud-and-menus/time-up-screen.md): Time's up screen. The 3-second screen over the frozen run when the timer runs out (T-317).

## garage/

- [docs/garage/garage-screen.md](docs/garage/garage-screen.md): Garage screen. The garage screen.

## game-loop/

- [docs/game-loop/screen-flow.md](docs/game-loop/screen-flow.md): Screen flow. How the screens follow each other.
- [docs/game-loop/the-run.md](docs/game-loop/the-run.md): The run. The run scene, its state, likes, combo, clock, and the recap summary (`RunState.recap()`).
- [docs/game-loop/gift-pack-and-pickups.md](docs/game-loop/gift-pack-and-pickups.md): Gift pack and pickup magnet. The gift pack drop and the pickup magnet.

## driving/

- [docs/driving/drift.md](docs/driving/drift.md): Drift. The drift prototype and the side slip.
- [docs/driving/collisions.md](docs/driving/collisions.md): Collisions. Layers, bounce, signal, knockback.
- [docs/driving/tricks.md](docs/driving/tricks.md): Tricks. The trick signal and how each trick is found.
- [docs/driving/effects.md](docs/driving/effects.md): Driving effects. Drift marks, drift smoke, boost effect, airtime trick, hype speed boost.

## data/

- [docs/data/game-data.md](docs/data/game-data.md): Game data. The JSON data files and their loader.

## level/

- [docs/level/challenge-check.md](docs/level/challenge-check.md): Challenge drivability check. The script that verifies a challenge is achievable.
- [docs/level/mvp-map.md](docs/level/mvp-map.md): MVP map. The MVP map's scene, data and see-through buildings.
- [docs/level/elevation-test-scene.md](docs/level/elevation-test-scene.md): Elevation test scene. Ground-height data, the query, the car's height, the test scene.
- [docs/level/elevation-sample-map.md](docs/level/elevation-sample-map.md): Elevation sample map. The sample map with rooftops and ramps.
- [docs/level/level-creator.md](docs/level/level-creator.md): Level creator. Storage, editor, side panel, rotate, snapping, saving.
- [docs/level/level-creator-pieces.md](docs/level/level-creator-pieces.md): Level creator: pieces and tools. Road brush, ramps, banners, thread the needle, spawn, any-size rooftops, props, road pieces.

## enemies/

- [docs/enemies/minions.md](docs/enemies/minions.md): Minions. The minions and their coins.
- [docs/enemies/ledges-and-rooftops.md](docs/enemies/ledges-and-rooftops.md): Enemies on rooftops, ramps and ledges. Enemies on the rooftops and ramps (T-207); enemies drop off ledges (T-226).
- [docs/enemies/kaiju.md](docs/enemies/kaiju.md): The kaiju. The kaiju.
- [docs/enemies/meteors.md](docs/enemies/meteors.md): Meteors. The meteor attack and the comet tail and impact effects.

## weapons/

- [docs/weapons/shared.md](docs/weapons/shared.md): Weapons: shared. How weapons plug into the run, targets, size upgrades, level-up offers.
- [docs/weapons/starting-gun.md](docs/weapons/starting-gun.md): The starting gun. The gun and its bullet.
- [docs/weapons/flamethrower.md](docs/weapons/flamethrower.md): The exhaust flamethrower. The exhaust flamethrower.
- [docs/weapons/neon-underglow.md](docs/weapons/neon-underglow.md): The neon underglow. The neon underglow.
- [docs/weapons/molotovs.md](docs/weapons/molotovs.md): The molotovs. The molotovs.
- [docs/weapons/windshield-wiper.md](docs/weapons/windshield-wiper.md): The windshield wiper. The windshield wiper.
- [docs/weapons/bricks.md](docs/weapons/bricks.md): Bricks. Bricks.

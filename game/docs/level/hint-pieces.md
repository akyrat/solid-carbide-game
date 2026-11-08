# Hint pieces (T-576)

The level creator's hint pieces and how a run draws them. The decision is Level design, Decisions, "Hint pieces in the level creator"; what the board sees is Level design, Content, "Level creator: hint pieces". The labels are T-575's (`data/level/creator_texts.json`). T-577 swaps in the PixelLab art.

## The art (for T-577)

The engine reads every path and size from **`game/data/level/hints.json`**. T-577 drops its PNGs over the placeholders at the same paths and sizes, and changes nothing else (only `face_px` or `anchor_px` in that file if its sign's board or post sits elsewhere).

| File | Size | What it is |
| --- | --- | --- |
| `game/art/hints/hint_gas.png` | 64 x 64 px | The W keycap (the tutorial's keycap look, `scripts/menu/key_pad.gd`) |
| `game/art/hints/hint_brake.png` | 64 x 64 px | The S keycap |
| `game/art/hints/hint_arrow_straight.png` | 64 x 64 px | A straight arrow |
| `game/art/hints/hint_arrow_curved.png` | 64 x 64 px | A curved arrow turning **right** |
| `game/art/hints/hint_arrow_circular.png` | 64 x 64 px | A circular arrow going **clockwise** |
| `game/art/hints/hint_sign.png` | 64 x 96 px | The standing sign: a board on a post, no icon on it |

- **The five icons** are drawn **top-down, flat, pointing up the picture** (the way the car drives over them), on a transparent background. The engine lays each flat on the isometric ground and turns it to the piece's heading, so one picture serves all 8 directions; the mirror (M) flips it left to right, which makes the curved arrow a left turn and the circular arrow anticlockwise. On the ground an icon covers 4 x 4 units (`ground.size_units`), a road's width.
- **The sign** is one picture. Its post's foot is pixel `anchor_px` (32, 95), which stands on the middle of the piece's 2 x 2 unit cell. The engine puts the icon on its face, fitted into `face_px` (x 8, y 8, 48 x 48), turned to the way the heading shows on screen. It is drawn at `draw_scale` 0.5, like the props: 32 x 48 screen pixels, 2 units wide and 3 tall.
- The placeholders come from `python game/tools/build_hint_placeholders.py` (no PixelLab); `--check` says whether every PNG is there at its size, so it passes on T-577's art too.

## The data

- **Level file:** a top-level list `"hints"`, `{id: "hint-N", icon, mode, heading, mirror, x, y, w, h}`. `icon` is one of `gas`, `brake`, `arrow-straight`, `arrow-curved`, `arrow-circular`; `mode` is `ground` or `sign`; `heading` is in degrees, as the spawn point's (0 faces +x, 270 faces -y, the run's own start), one of the 8 in `headings`; `mirror` is true only for the curved and circular arrows; `x, y, w, h` is the footprint in units, 4 x 4 on the ground and 2 x 2 for a sign. A level without the key has no hints, and the creator writes no key for a level without any. `game/tools/check_level.py` checks each entry (`check_hints`) and that a sign does not stand on the spawn point.
- **Catalogue:** `game/tools/build_creator_assets.py` writes one entry per icon and mode (`hint-<icon>-ground`, `hint-<icon>-sign`, kind `hint`), the 8 headings as its views and the mirror for the arrows that have one, and one family per icon (`hint-<icon>`, group `hints`) whose `height` axis holds the two modes.

## In the creator

- The side panel's **Driver hints** group has the five buttons. With one picked, the top bar shows **On the ground** and **Roadside sign** (`editor.gd` `set_hint_mode`, `hint_mode_buttons`); H does not change the mode. R steps the heading clockwise on screen through the 8 directions, from 270; M mirrors the curved and circular arrows. The looks strip shows the mode's hint (`mode_hints`: "Click: paint. R: turn." or "Click: stand the sign at the roadside. R: turn.") and, for the two arrows, "M: mirror.".
- A hint is placed through the same path as every other piece: `place_asset`, `LevelSnapping.placement`, `LevelDocument.place`. So it picks up the creator's placement rules (T-581's free placement too). Proposals: a ground hint is painted on the street only, refused on a building, rooftop or ramp like a meteor crater (`LevelSnapping.crater_problem`). A sign stands like a prop: on the street or wholly on a rooftop, never into a building, and never on the start (`object_problem`, `LevelSpawn.problem`). A building, rooftop or ramp placed later never cuts through one (`cuts_object_problem`). Selected with a click (a sign before the props, a ground hint just above the ground) and deleted with Del. The preview under the mouse is the piece exactly as the map will draw it (`hint_preview`, drawn with `LevelHints.draw_ground` and `draw_sign`).

## In a run

`scripts/level/level_hints.gd` (`LevelHints.build`, called by `mvp_map.gd` `_build`, so the run, the creator's drawing and the practice playground all use it):

- **Ground hints:** one node, `map.hint_decals` (`HintDecals`), in the map's view right after the ground (its tiles, or the practice playground's grid ground), so it is drawn under the buildings, rooftops, props, the car and the minions. It draws in the map's flat pixels and the view's isometric projection lays it on the ground. No body. The run's tyre marks are moved right after the ground tiles when the run starts (`run.gd`), so they are drawn under the painted hints.
- **Signs:** a `LevelProps.PropSprite` per sign in `map.prop_sprites` (under `map.prop_sprites_root`, sorted in depth with the props, the boulders and the car), with the icon as its child sprite `Icon`. A static body per sign in `map.prop_bodies`: a circle of 0.5 units at the post (`collision_radius`), collision layer 1, standing from the height under it up 3 units (`height_units`; the props' height rules). The car crashes into it like a prop (`hit_obstacle`, the combo cut), and the enemies' paths and spawn spots go round it (`LevelProps.obstacles`, `blocks_spot`).

Tests: `game/tests/unit/level_creator/test_creator_hints.gd`, `game/tools/test_check_level.py` (`TestCheckHints`). Screenshots and a test level: `game/tools/hint_shots.gd` (see its header).

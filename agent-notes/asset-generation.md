# Working copy: Asset Generation Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for which art to generate.

**Hands work to**

- Enemy Behavior Agent: Enemy sprites, which replace the placeholders.
- Weapon Behavior Agent: Weapon and projectile art, which replaces the placeholders.
- Level/Challenge Design Agent: Map and obstacle art.
- UI Agent: HUD, menu and garage art, which replaces the placeholders.

**Collaborates with**

- Weapon Behavior Agent: Both get linked task files from the same request. The weapon work starts with a placeholder and doesn't wait for the art.
- Enemy Behavior Agent: Both get linked task files from the same request. The enemy work starts with a placeholder and doesn't wait for the art.
- UI Agent: Both get linked task files from the same request. The screen work starts with a placeholder and doesn't wait for the art.
- Narrative Theme Agent: The art has to match the story's look and themes.

## Notes from experience

- T-003: the SFX Agent also writes Python API tools in `game/tools/` and shares the Python test command and `game/README.md` with me. Keep tools flat in `game/tools/` (`test_*.py` next to them) so one test command covers both, and edit only my own README section.
- PixelLab's `GET /balance` can lag behind a just-finished async job: check it again a minute later before reporting a mismatch.
- T-013: placeholder art can be drawn by a headless Godot script instead of PixelLab (no cost, deterministic). Keep the drawing in a separate script the GUT tests can preload, so tests can rebuild the sheet and compare it to the committed one. Avoid an `endpoint` key in a script-made record JSON: `test_pixellab_assets.gd` treats JSON with `endpoint` and `image` as a PixelLab record.
- In a fresh worktree the first Godot import rewrites committed `.import` files with LF line endings. The content is unchanged; `git add` on them clears the false "modified" status.
- T-101: PixelLab's isometric compass directions are the 2:1 sheet's even frames (south-east = frame 0, south = 2, south-west = 4, ... east = 14). `/generate-8-rotations-v3` cost only 2 generations at 128 x 128 and returns unlabelled images in the order SW, S, SE, E, NE, N, NW, W, starting from the reference's direction; `/rotate` with `direction_change` +22 turns clockwise on screen (1 generation). `/rotate`'s `color_image` did not keep the palette (210+ colours), so plan a palette-mapping step (script, no new pixels) for PixelLab rotations. PixelLab draws iso diagonals flatter than the game's 2:1, so headings come out 5 to 15 degrees off, and a small `/rotate` sometimes barely turns the car.
- Long heredocs with apostrophes sometimes break the Bash tool; write long text with Edit/Write or a Python script file instead.
- `git add` did not always clear the false `.import` "modified" status (T-101); just leave those files out of the commit.
- T-018: when the car's proportions change, size the frame for the isometric view, which is the widest: a flat rectangle reaches up to sqrt(2) times its half-diagonal from the centre on screen. Keep the frame square and the same for both views so one layout fits both.
- T-074: small effect sprites (particles) can be one row of frames read by a `CPUParticles2D` through a `CanvasItemMaterial` with particles animation: `anim_offset` 0 to 1 and `anim_speed` 0 give each particle one random frame. Draw them at the car's art density (`scale_amount` 0.5 in the run) and never rotate them. "Not Redgull red" is tested as more than 0.5 (0..1 RGB distance) from `Hud.HEART_COLOR`, so dark magentas need a bit of extra blue to pass.
- A screenshot's PNG is RGB, not RGBA: `check_sprite_rules.decode_png` cannot read it; use Pillow (installed) for crops and enlargements.
- T-118: a tiling texture for a `Line2D` (tile mode) runs x along the line, y across it; each `Line2D` restarts the pattern at its own start, so keep the period short. A transparent background for a strip means gaps only in its edge rows; check the functional task's tests, which may assume fully opaque pixels. Previews over the real ground colours (sampled from the atlas) were a cheap way to judge contrast before taking screenshots.
- T-064: `/create-image-pixflux` at 384 x 400 cost 1 generation; with `no_background` above 200 x 200 it returns an opaque flat background (a flood fill from the border removes it cleanly). A 29-colour `color_image` was respected exactly by pixflux (unlike `/rotate`). Asking for a "narrow" tower gave a 2 x 2 unit footprint at 384 px width, not the image width: size words in the prompt beat the canvas size. "No letters" did not stop kanji-like sign marks; `negative_description` is marked deprecated in the API.

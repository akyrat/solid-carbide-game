Brief for T-294: Greenbull's emblem, a bull's head.

The board's words (2026-10-26): "We're gonna make the logo something cool, but don't make it look like the real, like the Red Bull logo. Make it like a head of a bull or something, you know, like a cool logo. And maybe you can use also, you can use dark green, light green, and yellow for the main logo … but don't use yellow too much. Let's lean into the dark green to make it the main theme color for the company."

Context: the game's sponsor was Redgull (a seagull-head logo in dark red, game/art/logo/redgull_logo_128.png); the board renamed it Greenbull in a complete rebrand. This emblem is the new logo without words. The wordmark (emblem + GREENBULL) comes after, in T-295, built from this emblem.

What to make:
- One emblem, 128 x 128 pixels, transparent background: a bold, cool **bull's head** with horns, as a brand emblem. The head only (no body), front-facing or a strong 3/4 view, symmetric or near it, filling most of the canvas without touching the edges. It must read as a bull's head at 32 x 32 too, so: big simple shapes, thick horns, a clear muzzle, no fine detail.
- Its own design: **not** the real energy-drink logo (never two charging bulls facing each other, never a sun or circle behind them, never a whole bull). No real brand's look.
- Colours (Visual style rule 6, Greenbull's colours): **dark green RGB 12, 76, 44 leads** (most of the head); **light green RGB 104, 220, 96** supports it (highlights, horn shapes, a bold inner shape); **yellow RGB 247, 208, 52 only as a small accent** (for example the eyes or the nose ring or the horn tips; the board: "don't use yellow too much"). A dark, near-black outline around it so it reads on dark and light backgrounds. At most one extra darker green shade if needed. The final file uses exactly these colours: remap PixelLab's colours to them with a free script.
- Rule 1 applies: hard pixel edges, every pixel fully opaque or fully transparent, transparent background, few colours. It is flat brand art, so rule 2's detailed shading does not apply (Visual style, Content, "Rules", last line).

Style guide: docs/visual-style.md, Content, "Rules" (rules 1 to 10), and Decisions, "Greenbull's look". Tone: docs/extended-narrative.md (the brand is slick and confident, and out of touch).

How to make it (Asset Generation Agent):
- Lesson from the old logo (tasks/T-075-redgull-logo-art.md, result notes): PixelLab's pixflux from a text prompt alone gave a shapeless blob for a flat logo; drawing a clean silhouette by script first and giving it to `create-image-pixflux` as `init_image` (strength about 150 to 300) worked much better. Use whichever gives the best emblem; a script-drawn first shape is free.
- PixelLab through game/tools/pixellab_client.py (`create-image-pixflux` at 128 x 128, `no_background: true`, flat shading, low detail; 1 generation per call; 600 s timeout).
- The board's go for this asset: up to 12 PixelLab generations in all (this loop run uses at most 4: one per version). Free script fixes first (colour remap to the brand values, reduce_palette.py, removing specks or semi-transparent pixels), when they can fix what the reason names.
- Save each version as the loop asks (art-archive/T-294/style-loop/vN.png) with its PixelLab record or the script that drew it next to it. Never write into game/art/ (except the PixelLab log the client writes).

Run 2 (the Project Lead, after run 1): run 1's version (art-archive/T-294/style-loop/v1.png, kept as a candidate as art-archive/T-294/greenbull_emblem_128.png) passed at 8/10, but it reads plain: a calm farm bull with a flat, boxy face, and PixelLab changed almost nothing of the script shape. The board asked for "a cool logo". This run aims higher: the same colours and rules, but a **bolder, more graphic brand mark**:
- Sharper and more angular: horns that sweep up and forward to sharp points, an angular, tapering face (a strong V or shield shape down to the muzzle), a heavy, furrowed brow over narrow, intense yellow eyes, flared nostrils. Confident and a little aggressive, like a sports or energy brand mark, never cute.
- Strong graphic shapes in the two greens (for example the light green as bold facets or a lightning-like blaze down the face), so it looks designed, not drawn.
- Keep a clear margin from the canvas edges (run 1's horns nearly touched them).
- Let PixelLab contribute this time: a lower init strength, or a text-only pixflux call, so the design changes from the script shape; then remap to the brand colours by script.
- Save this run's versions as the loop names them (v1-2.png and so on); never overwrite run 1's files. Write the final kept file to art-archive/T-294/greenbull_emblem_128_run2.png (the loop's --out); the board chooses between the runs.

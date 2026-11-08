# Brief: Grinding Wheels icon (T-587)

A 32 x 32 pixel-art icon for the driving power-up "Grinding Wheels" (the car's wheels grind along a rail). Shown at 64 x 64 on a power-up card.

Read docs/visual-style.md (Rules 1 to 6, 9; Decisions, "Grinding Wheels icon" and "The four driving power-up icons") first, and look at the other icons in game/art/power_ups/ (rev_charge, jump, bouncy_bumpers, rusty_overcoat) to match size, outline and palette.

Subject: a car wheel (tyre and hub) grinding on a steel rail, seen 3/4 from the side, with a spray of sparks coming out of ONE side (the rear, to the right). One clear central symbol, readable at a glance.

Matched-set style: 32 x 32, transparent background, hard pixel edges, dark almost-black 1 px outline broken by lighter highlight pixels, detailed shading, light from the top-left, neon night palette (cool blue-grey metal, orange-amber sparks with cyan/magenta accents), at most 30 colours, glow as stepped pixel halos inside the sprite. Fills about 28 x 28 px, centred. No Greenbull light green (104,220,96) or yellow (247,208,52): keep sparks orange/white, not yellow. No text, no brands.

PixelLab: create_image_pixflux endpoint, 32 x 32, no_background true, outline "single color black outline", shading "detailed shading", detail "highly detailed", text_guidance_scale 8; one generation per version (up to 4 in all). Free script fixes (palette, outline, stray pixels) before any regeneration.

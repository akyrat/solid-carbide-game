Brief for T-293: the minion redesigned as a car-sized mini kaiju, one sample direction.

The board's words (2026-10-25): "I want to rework the enemy asset. So the little lizard we've generated now, I want something bigger and more detailed. Perhaps something that looks slightly like a mini kaiju monster. It still should be a lizard, and it should walk on all fours, have a snapping jaw with teeth, kind of reptilian looking face. And I want it to be about as big as the car."

What to make:
- One sprite of the new minion, facing south-east on screen (towards the bottom right, the direction of the car sheet's frame 0), standing or mid-stride on all four legs, its jaw open to show teeth.
- A 3/4 isometric view, seeing its top and one side, like the car (game/art/car/car_iso.png, frame 0).
- Canvas 128 x 128 pixels, transparent background. The body is about as big as the car: about 96 art pixels long including the tail, using most of the frame without touching its edges.
- Light green (not too bright) scaled lizard, with darker green scales and a paler belly; a heavy, reptilian head with a snapping jaw full of small pale teeth; thick legs with claws; a long tail. Kaiju-like in build (heavy, menacing), but small and clearly a lizard, not a copy of Godzilla.
- Night lighting, retro; hard-edged pixel art, a dark selective outline, detailed shading, at most 30 colours, every pixel fully opaque or fully transparent, no Redgull red (no deep reds at all; the mouth inside may be a dull pink or dark brown).

Style guide: docs/visual-style.md, Content, "Rules" (rules 1 to 10). The current minion for comparison (what this replaces): art-archive/T-068/review_all8_directions_dark.png.

How to make it (Asset Generation Agent):
- PixelLab through game/tools/pixellab_client.py, `create-image-pixflux` at 128 x 128 with `isometric: true` and `no_background: true` (1 generation per call). Ask in the prompt for "lying directly on the ground, no base, no platform" (agent notes, T-065).
- The board's go for this task: at most 4 PixelLab generations in all, one per version. Before a paid regeneration in a refine, try free script fixes first (game/tools/reduce_palette.py for the colour count, removing stray semi-transparent pixels or specks), when they can fix what the reason names.
- Save each version as the loop asks (art-archive/T-293/style-loop/vN.png) with its PixelLab record next to it. Never write into game/art/.

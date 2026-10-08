---
title: Visual style
gdd_order: 7
scope: The visual style for generated art (pixel art, isometric). May connect to the narrative theme.
agents_work_on: [asset-generation]
agents_read: [level-challenge, ui, narrative-theme]
---

# Visual style

## Summary

(To be written.)

## Decisions

- The first map's city is cyberpunk and futuristic, in a Tokyo style, with skyscrapers and modern buildings. (2026-10-07)
- All roads are asphalt. (2026-10-07)
- Obstacles are drawn as boulders (in the MVP, crashed meteor boulders; Level design, Decisions). (2026-10-07)
- When the car drives behind a building, the building turns see-through so the car stays visible. (2026-10-07)
- **Pixel-art technical style** (from the board's reference image, References): true pixel art drawn at its final size, never scaled up; hard pixel edges with no anti-aliasing and no semi-transparent pixels; transparent backgrounds; a dark, almost black **selective outline** (broken by lighter highlight pixels); **detailed shading**; **high detail**; a limited palette of about **30 colours per sprite**. (2026-10-08)
- **Scale:** about **40 pixels per unit** (1 unit = the car's width), so the car is about 120 pixels long. The car's frames are **128 by 128 pixels**. Everything else in the world (buildings, boulders, enemies, ground) is drawn at the same scale. (2026-10-08)
- **View:** a 3/4 isometric view, seeing the top and one side. The final car art is drawn for the isometric view only; the flat top-down view keeps the placeholder. (2026-10-08)
- The car is drawn in 16 directions, 22.5 degrees apart, 3 times as long as it is wide (size: Drifting, Decisions). (2026-10-07)
- Until the final pixel art exists, the car uses simple placeholder sprites: plain 3:1 rectangles with a distinct nose, drawn by a script rather than generated with PixelLab, in a flat top-down set and an isometric set. (2026-10-07)

## Content

(To be written.)

## Open questions

- What does the car look like: type of car, colours, any Greenbull livery? (Needed for task T-014.)
- The palette: the main colours, and which neon accents.
- Neon and lighting: is it night? Do only signs and windows glow, or more?
- Buildings: style, height variation, signs, Greenbull billboards?
- Ground: road markings on the asphalt; how the gravel centre looks.
- Boulders: plain crashed meteor rocks, or glowing or smoking?
- The kaiju's meteor attack: the meteor, the danger area on the ground, the impact.
- The kaiju's look, and the minion's look (the minion comes with the pick from task T-023).
- Effects: bullets, exhaust flames, enemy deaths, coin pickups. Described by the board, or left to the Asset Generation Agent within the palette and style?
- How can buildings turn see-through when the car is behind them? Being researched in task T-020.
- What does the painted challenge arrow look like, and how is it animated?

## References

- Technical style reference (only for the technical specs above; not the actual car, colours or mood): ![Reference car](visual-style/reference-car-technical-style.png) `visual-style/reference-car-technical-style.png`, 128 by 128 pixels, 29 colours.

---
title: Visual style
gdd_order: 7
scope: The visual style for generated art (pixel art, isometric). May connect to the narrative theme.
agents_work_on: [asset-generation]
agents_read: [level-challenge, ui, narrative-theme]
---

# Visual style

## Summary

Solid Carbide is retro-feeling 2D pixel art in a 3/4 isometric view, set at night in a neon, Tokyo-style cyberpunk city: dark navy and purple, lit by pink and cyan neon drawn into the sprites, with Redgull's red only on Redgull's own things. The player drives a dark-green, Mustang-inspired car with white stripes through cracked streets, past dark boulders with glowing cracks, chased by green lizard minions and a Godzilla-style kaiju. All art follows one technical style: hard-edged pixel art at about 40 pixels per unit, with a selective dark outline, detailed shading and a limited palette.

## Decisions

- The first map's city is cyberpunk and futuristic, in a Tokyo style, with skyscrapers and modern buildings. (2026-10-07)
- All roads are asphalt. (2026-10-07)
- Obstacles are drawn as boulders (in the MVP, crashed meteor boulders; Level design, Decisions). (2026-10-07)
- When the car drives behind a building, the building turns see-through so the car stays visible. (2026-10-07)
- **Pixel-art technical style** (from the board's reference image, References): true pixel art drawn at its final size, never scaled up; hard pixel edges with no anti-aliasing and no semi-transparent pixels; transparent backgrounds; a dark, almost black **selective outline** (broken by lighter highlight pixels); **detailed shading**; **high detail**; a limited palette of about **30 colours per sprite**. (2026-10-08)
- **Scale:** about **40 pixels per unit** (1 unit = the car's width), so the car is about 120 pixels long. The car's frames are **128 by 128 pixels**. Everything else in the world (buildings, boulders, enemies, ground) is drawn at the same scale. (2026-10-08)
- **View:** a 3/4 isometric view, seeing the top and one side. The final car art is drawn for the isometric view only; the flat top-down view keeps the placeholder. (2026-10-08)
- **Palette:** a dark navy and purple night base, with pink and cyan neon accents. Redgull's red is not part of the city's palette; it appears only on Redgull's own things (Redgull's look, below). (2026-10-08; brand colour corrected the same day)
- **Mood:** the game is set at night and should feel retro. (2026-10-08)
- **Glow:** drawn into the sprites themselves, as bright pixels with small, stepped halos of darker shades. No smooth blur or bloom effects from the engine, which keeps the retro pixel look. (2026-10-08)
- **Real-world references are inspiration only:** generated art never shows real brand logos or badges (for example no Ford or Shelby badges), and creatures are never exact copies of existing characters (the kaiju is Godzilla-style, not Godzilla). (2026-10-08)
- **The car:** inspired by a 1967 Ford Mustang fastback, in dark green, with two parallel white racing stripes running down its middle (bonnet, roof and boot). See the reference photos in References. (2026-10-08)
- **Buildings:** Tokyo-style towers with vertical signs and lit windows. The city has nothing to do with Redgull, so the buildings carry none of its colours or branding. After the MVP, occasional Redgull banners may be added as separate assets placed on the buildings, not drawn into them. (2026-10-08; billboards replaced by after-MVP banners the same day)
- **Redgull's look:** the company's logo is a simple, sketched seagull with red eyes, slightly evil and unsettling (why: Extended narrative, Decisions). Red is the company's theme colour, used only on things that belong to Redgull: its logo, its banners (after the MVP) and, in the MVP, the weapons, which arrive as Redgull gift packs. They don't have to be all red; red is included where it fits. It does not change the colour of the car, the enemies, the map or anything else. (2026-10-08)
- **Ground:** asphalt roads with lane lines and crossings, cracked by the disaster; the centre is dusty gravel. (2026-10-08)
- **Boulders:** dark rock with glowing cracks. (2026-10-08)
- **Challenge arrow:** a glowing painted arrow that draws itself along the path, pulses while the challenge is open, and fades when it is completed. Arrows of the challenges on the map are **blue**; arrows of the challenges the kaiju's meteors create are **green**. (2026-10-08)
- **See-through rule:** the no-semi-transparent-pixels rule covers the pixels inside each sprite. The game itself may fade a whole object, such as the kaiju's shield or a building the car drives behind. (2026-10-08)
- **Kaiju shield:** while the kaiju can't be hurt, it is surrounded by a **green, see-through, oval shield**, the same green as its challenges' arrows. When one of those challenges is completed, the shield disappears and the kaiju shows its normal look while it can be hurt. (2026-10-08)
- **Effects** (gun bullets, exhaust flames, enemy hits and deaths, burning, coins, car damage, drift smoke and tire tracks, challenge completed, level-up): designed by the Asset Generation Agent within the palette, glow and pixel style above. (2026-10-08)
- **The kaiju's meteor attack:** a red warning circle on the ground, then a falling meteor and a burst of dust on impact. (2026-10-08)
- **The kaiju:** a giant monster several times the car's size, in the style of Godzilla. (2026-10-08)
- **The minion:** light green (not too bright), scaled lizards that walk on four legs towards the player. (2026-10-08)
- The car is drawn in 16 directions, 22.5 degrees apart, 3 times as long as it is wide (size: Drifting, Decisions). (2026-10-07)
- Until the final pixel art exists, the car uses simple placeholder sprites: plain 3:1 rectangles with a distinct nose, drawn by a script rather than generated with PixelLab, in a flat top-down set and an isometric set. (2026-10-07)

## Content

(To be written.)

## Open questions

- (After MVP) Does the car carry any Redgull livery or stickers? In the MVP it is kept simple: dark green with two white stripes.
- How can buildings turn see-through when the car is behind them? Being researched in task T-020.

## References

- **Car look, colour:** a dark-green 1967 Ford Mustang fastback (inspiration only; no real badges).

  ![Dark-green 1967 Mustang fastback](visual-style/reference-car-mustang-1967-dark-green.jpg)

- **Car look, stripes:** the two stripes down the middle, from a black 1967 Mustang fastback (inspiration only).

  ![Black 1967 Mustang fastback with two white stripes](visual-style/reference-car-mustang-1967-black-striped.jpg)

- **Technical style:** only for the technical specs in Decisions (128 by 128 pixels, 29 colours); not the actual car, colours or mood.

  ![Pixel-art reference car for the technical style](visual-style/reference-car-technical-style.png)

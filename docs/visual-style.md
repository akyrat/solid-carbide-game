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
- How buildings turn see-through (from task T-020's research): the whole building fades while the car is behind it, to **15% visible**, over **0.15 seconds**, and fades back when the car comes out. Only buildings actually covering the car fade. In the MVP only the car is kept visible this way, not enemies or the kaiju; the board may revisit this after playtests. (2026-10-10)
- **Pixel-art technical style** (from the board's reference image, References): true pixel art drawn at its final size, never scaled up; hard pixel edges with no anti-aliasing and no semi-transparent pixels; transparent backgrounds; a dark, almost black **selective outline** (broken by lighter highlight pixels); **detailed shading**; **high detail**; a limited palette of about **30 colours per sprite**. (2026-10-08)
- **Scale:** **32 art pixels per unit** (1 unit = the car's width), drawn at scale 0.5 in the game, so the car is about 96 art pixels long. The car's frames are **128 by 128 pixels**. Everything else in the world (buildings, boulders, enemies, ground) is drawn at the same scale. (2026-10-08; corrected from "about 40" to the 32 the game has used since the car and ground went in, board, 2026-10-15)
- **View:** a 3/4 isometric view, seeing the top and one side. The final car art is drawn for the isometric view only; the flat top-down view keeps the placeholder. (2026-10-08)
- **Palette:** a dark navy and purple night base, with pink and cyan neon accents. Redgull's red is not part of the city's palette; it appears only on Redgull's own things (Redgull's look, below). (2026-10-08; brand colour corrected the same day)
- **Mood:** the game is set at night and should feel retro. (2026-10-08)
- **Glow:** drawn into the sprites themselves, as bright pixels with small, stepped halos of darker shades. No smooth blur or bloom effects from the engine, which keeps the retro pixel look. (2026-10-08)
- **Real-world references are inspiration only:** generated art never shows real brand logos or badges (for example no Ford or Shelby badges), and creatures are never exact copies of existing characters (the kaiju is Godzilla-style, not Godzilla). (2026-10-08)
- **The car:** inspired by a 1967 Ford Mustang GT fastback, in dark green as the main colour, with two parallel white racing stripes running down its length (bonnet, roof and boot), centred on the car as much as possible, with a gap of body colour between the two stripes. See the reference photos in References. (2026-10-08; the GT, centred stripes and the gap between them, 2026-10-12)
- **Buildings:** Tokyo-style towers with vertical signs and lit windows. The city has nothing to do with Redgull, so the buildings carry none of its colours or branding. After the MVP, occasional Redgull banners may be added as separate assets placed on the buildings, not drawn into them. (2026-10-08; billboards replaced by after-MVP banners the same day)
- **Buildings, redesigned** (board, 2026-10-14; replaces the dense narrow towers of earlier the same day): downtown Tokyo **under attack from the kaiju**. Each 30 by 30 block is split into **2 by 2 skyscrapers**, drawn as the bases of really tall towers whose tops are out of view, so the car is realistic in size next to them; **6 different skyscrapers**. **Shorter buildings** whose roofs show fill some of the slots. **Every building asset has a pavement drawn around it**, inside the block. **A few** alert banners about the kaiju hang on buildings or stand as signs on the pavement, with silly, minimalistic pixel paintings of its head or its Godzilla-like body. The signs may show Japanese-like marks that are not real words. All the city's art follows one brief from the Narrative Theme Agent (task T-128) so it stays consistent.
- **City brief** (board, 2026-10-15, from the Narrative Theme Agent's brief in task T-128; every city asset follows it): night; the city's colours are set by the "City colours" decision below; vertical neon signs with Japanese-like marks that are not real words, and no real brands; **pavements** a lighter, cooler grey than the asphalt, with a raised kerb on the road side and light cracks; **damage from the attack light to medium**: cracks, a few broken or dark windows, a little rubble, and no big fires, collapsed buildings or gore; the **alert banners are picture-only**, with no words, and look like road warning or prohibition signs: a red outline, a plain white inside, and only the black silhouette of the kaiju (its head or its Godzilla-like body shape), with no other detail and no neon colours (board, 2026-10-15; replaces the first cyan and pink drawings); the larger ones hang on buildings, small standing signs are on the pavement, and only a few on the map; kept out: Redgull's red, branding and seagull logo, real brands, real words, the name Godzilla or an exact copy of the film monster, and any name for the kaiju.
- **City colours** (board, 2026-10-15, after playing the first skyscraper sample in the game): the city must **not share the boulders' palette**. The boulders and the kaiju's meteors are alien, so their navy, purple and magenta glow must stand apart from the city, never match it. The city is **less neon**: real concrete, glass and lit windows, with only small, muted signs. The board judged two palettes in the game, A (concrete and sodium light: warm greys and beige, yellow-orange windows) and B, and chose **B, steel and glass**: **cool blue-grey walls, pale white and pale blue lit windows, and small amber accents** (signs, shop lights) (board, 2026-10-15). Every city asset (skyscrapers, shorter buildings, pavements) uses the chosen palette; the alert signs keep their own warning-sign colours.
- **Redgull's look:** the company's logo is a simple, sketched seagull with red eyes, slightly evil and unsettling (why: Extended narrative, Decisions). Red is the company's theme colour, used only on things that belong to Redgull: its logo, its banners (after the MVP) and, in the MVP, the weapons, which arrive as Redgull gift packs. They don't have to be all red; red is included where it fits. It does not change the colour of the car, the enemies, the map or anything else. (2026-10-08)
- **Exception to red-for-Redgull only:** the kaiju alert signs use a traffic-sign red outline, because they must read as real road warning signs (board, 2026-10-15). Nothing else outside Redgull uses red.
- **Ground:** asphalt roads with **white** lane lines and **zebra crossings** at the junctions, with **light cracks** from the disaster; the centre is dusty gravel. No pavements in the MVP (after the MVP: Level design, Open questions). (2026-10-08; white lines, zebra crossings and light cracks, 2026-10-12; pavements moved after the MVP the same day)
- **Boulders:** dark rock with glowing cracks. (2026-10-08)
- **Challenge arrow** (after the MVP, if challenges come back; Level design, Decisions, 2026-10-11): a glowing painted arrow that draws itself along the path, pulses while the challenge is open, and fades when it is completed. Arrows of the challenges on the map are **blue**; arrows of the challenges the kaiju's meteors create are **green**. (2026-10-08)
- **See-through rule:** the no-semi-transparent-pixels rule covers the pixels inside each sprite. The game itself may fade a whole object, such as the kaiju's shield or a building the car drives behind. (2026-10-08)
- **Kaiju shield** (not in the MVP: the kaiju can be damaged at any time, Enemies, Decisions, 2026-10-11): while the kaiju can't be hurt, it is surrounded by a **green, see-through, oval shield**, the same green as its challenges' arrows. When one of those challenges is completed, the shield disappears and the kaiju shows its normal look while it can be hurt. (2026-10-08)
- **Effects** (gun bullets, exhaust flames, enemy hits and deaths, burning, coins, car damage, drift smoke and tire tracks, level-up; challenge completed after the MVP, if challenges come back): designed by the Asset Generation Agent within the palette, glow and pixel style above. (2026-10-08)
- **Level-up effect:** when the player levels up, the car gives off a burst of pixel-art particles. The particle sprites are drawn by a script, not generated with PixelLab, within the palette, glow and pixel style above, and not in Redgull red. They pop out or shrink rather than fading. Approved look (T-074): six shapes (cyan and pink four-point stars, pink and cyan diamonds, a violet pixel cross, a small cyan spark), each with a white-hot core and darker halo pixels, one random shape per particle. (board, 2026-10-13)
- **Drift marks:** while the car drifts, its two rear tyres leave dark tyre marks on the ground, which stay for a few seconds and then fade out as a whole. The mark texture is drawn by a script, not generated with PixelLab, within the pixel style above, and not in Redgull red. (board, 2026-10-13)
- **Drift smoke:** while the car drifts, puffs of smoke come off its two rear tyres, stay where they were left, grow and then shrink or break up. The smoke sprites are drawn by a script, not generated with PixelLab, within the pixel style above (no semi-transparent pixels), and not in Redgull red. (board, 2026-10-13)
- **Every generated asset is kept, and kept apart by status.** Art that is clean and ready for the game lives under `game/art/`. Every other generation (rejected versions, failed attempts, test runs, edits the board didn't choose) is never deleted: it is archived, with its record, in `art-archive/` at the top of the repo, outside the game folder, one folder per task. So `game/art/` holds only assets fit for the game, and the archive holds everything else. (2026-10-12)
- Art details these decisions leave open (for example how many directions and animation frames the minion and the kaiju have, or how many building and ground-tile variants there are) are proposed by the Asset Generation Agent in each art task; the board judges them. (2026-10-09)
- **The kaiju's meteor attack:** a red warning circle on the ground, then a falling meteor and a burst of dust on impact. (2026-10-08)
- **The kaiju:** a giant monster several times the car's size, in the style of Godzilla. (2026-10-08)
- **The minion:** light green (not too bright), scaled lizards that walk on four legs towards the player. (2026-10-08)
- The car is drawn in 16 directions, 22.5 degrees apart, 3 times as long as it is wide (size: Drifting, Decisions). At some point (not scheduled yet) it moves to **32 directions**, 11.25 degrees apart, built from the approved 16 (board, 2026-10-12). (2026-10-07; 32 directions later, 2026-10-12)
- Until the final pixel art exists, the car uses simple placeholder sprites: plain 3:1 rectangles with a distinct nose, drawn by a script rather than generated with PixelLab, in a flat top-down set and an isometric set. (2026-10-07)
- The minion is animated: it walks on all fours in 8 directions (5 drawn, 3 mirrored) with 7 walk frames each, built from the sample lizard the board approved (task T-068). Polish once the MVP is playable: a damage animation, and a fall-down and get-up animation for when minions bump into each other (Enemies, Decisions). (board, 2026-10-14)
- The level-up screen's art is red and gold, themed on Redgull (the weapons it offers are Redgull gift packs, so Redgull's red fits here). (board, 2026-10-15)

## Content

### See-through buildings

Task T-020 researched how buildings can turn see-through when the car is behind them: it compares three approaches and builds a demo with the recommended one (fading the whole building while the car is behind it) and a cut-out variant. The demo, the screenshots with several fade strengths and the questions for the board are in the report (References).

## Open questions

- (After MVP) Does the car carry any Redgull livery or stickers? In the MVP it is kept simple: dark green with two white stripes.

## References

- **Car look, colour:** a dark-green 1967 Ford Mustang fastback (inspiration only; no real badges).

  ![Dark-green 1967 Mustang fastback](visual-style/reference-car-mustang-1967-dark-green.jpg)

- **Car look, stripes:** the two stripes down the middle, from a black 1967 Mustang fastback (inspiration only).

  ![Black 1967 Mustang fastback with two white stripes](visual-style/reference-car-mustang-1967-black-striped.jpg)

- **Technical style:** only for the technical specs in Decisions (128 by 128 pixels, 29 colours); not the actual car, colours or mood.

  ![Pixel-art reference car for the technical style](visual-style/reference-car-technical-style.png)

- **See-through buildings:** [research report, demo and screenshots (T-020)](visual-style/see-through-buildings.md).

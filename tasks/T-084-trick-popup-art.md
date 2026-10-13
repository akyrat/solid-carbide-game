---
id: T-084
title: Art: the comic-style look of the trick popups
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-091]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, tasks/T-083-hud-combo-and-trick-popups.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the popup scene, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-091 (the popups, with placeholder styling) is done.**

The trick popups use comic-style writing (HUD and menus, Decisions). Make that look, in the game's pixel-art style and night neon palette (Visual style, Decisions): a comic-style burst or shape behind the text, and a pixel font with comic lettering. If you use an existing font, it must have a licence that allows use in a commercial game; record its source and licence. Swap it in for T-091's placeholder styling (it covers the challenge popup from T-092 too, once that exists) (`tasks/README.md`, "Art replaces placeholders"). PixelLab calls are recorded with their cost as usual; one round of generation only.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A screenshot shows each trick's popup in the final comic style (QA: pass / fail)
- [ ] The font's source and licence are recorded, and the licence allows commercial use (QA: pass / fail)
- [ ] Every PixelLab call is recorded with its prompt, settings and cost, and the balance before and after (QA: pass / fail)
- [ ] T-091's tests still pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: judge the look. One round only, so problems are reported rather than regenerated.

## Result notes

### Plan (2026-10-13, planning round only: no PixelLab calls, nothing downloaded, no game files changed)

Read: this task, `docs/hud-and-menus.md` (Content, "Trick popups"), `docs/visual-style.md`, `game/README.md` ("Trick popups"), `game/scripts/hud/trick_popups.gd`, and how the world view scales art (`car_sprite.gd`, `drift_prototype.gd`: 16 drawn px per unit, art at 40 px per unit, so one art pixel = 0.4 drawn px; at the default zoom 14.4 on a 1080p window one art pixel is about 0.94 screen px).

**1. Burst shape: script-drawn (recommended), 0 generations.** A build script (`game/tools/build_trick_popup.py` style, or a GDScript generator the tests can preload, like T-013/T-074) draws a jagged comic "explosion" burst on a pixel grid: a ring of spikes around an oval, spike count growing with the width, fixed seed so the result is deterministic. Fill dark navy/purple, a 1 px near-black outline, then a stepped cyan neon edge (bright cyan pixels with a darker cyan halo row, the glow rule) and a small pink inner accent ring. Hard edges, no anti-aliasing, no semi-transparent pixels, under 30 colours.
- PixelLab alternative (not recommended): `/create-image-pixflux`, 1 generation per image, e.g. 2 calls (a wide burst for normal popups, a small one for extended drift) = 2 generations, 600 s timeout, prompt along "comic book explosion burst speech balloon, empty, no text, dark navy fill, cyan neon jagged edge, transparent background, retro pixel art, hard pixel edges". Problems: it cannot fit four text lengths (stretching or nine-slicing a jagged burst bends the spikes and doubles pixels), and it would still need a script pass for transparency and the palette. So script is cheaper and fits better.

**2. Fitting different text lengths: sized per text, not scaled or nine-sliced.** The texts are short and few ("LONG DRIFT! +0.05", "FULL 360! +0.25", "ALT DRIFT! +0.5", "Trending! +{likes} Likes", names alone at the combo cap), so each popup builds its burst to the measured text width plus a margin, in game at runtime (cheap: one small Image per new text, cached by text and size). Nine-slice is the fallback only if runtime drawing proves too slow. Extended drift uses the same pixel size with a smaller font size and a shorter, flatter burst with fewer spikes, so it reads as a lesser pop.

**3. Comic pixel lettering: three candidates (all allow commercial games).**
- **Bangers** (recommended): the classic comic-book capitals, Vernon Adams, SIL Open Font License 1.1 ("Copyright 2010 The Bangers Project Authors"), https://fonts.google.com/specimen/Bangers, files at https://github.com/google/fonts/tree/main/ofl/bangers. Not a pixel font: rendered with anti-aliasing off at a fixed pixel size (Godot `FontFile` antialiasing none, no hinting/subpixel), so it becomes hard-edged pixel lettering; the script then adds the comic outline and shadow.
- **Press Start 2P**: a true pixel font (8 px grid), CodeMan38, SIL OFL 1.1 ("Copyright 2012 The Press Start 2P Project Authors, with Reserved Font Name Press Start 2P"), https://fonts.google.com/specimen/Press+Start+2P. Perfectly crisp at 2x/4x, but arcade rather than comic.
- **Kenney Fonts** (pixel fonts, e.g. Kenney Blocks / Kenney Pixel; exact face chosen on download), Kenney, Creative Commons CC0 (public domain, no attribution needed), https://kenney.nl/assets/kenney-fonts. Clean, also not comic.
- Own lettering: drawing the ~45 glyphs these texts need (capitals, "rendig"/"ikes" lowercase, digits, ! + .) as pixel bitmaps in the build script. No licence question and fully comic (slanted, heavy), but most work and every new text later needs new glyphs. Kept as the fallback if Bangers looks rough.
OFL note: use and bundling in a commercial game are allowed; the licence text ships with the font file (`game/art/fonts/OFL.txt`), and a modified copy may not keep the reserved name. Source, licence and version are recorded in the art record JSON and `game/README.md`.

**4. Pixel size.** The popup is baked into one texture (burst + text) and drawn with nearest filtering, scaled so one popup pixel = 2 art pixels (0.8 drawn px, about 1.9 screen px at the default zoom on 1080p), the same for every popup, so it stays chunkier than the car but on its pixel grid. Font sizes chosen to match today's sizes: normal about 35 popup px (= 28 drawn px), small about 20 popup px (= 16 drawn px); with Press Start 2P that would be 32 and 16 (multiples of 8).

**5. Colours (night neon palette, no Redgull red).** Trick name: hot pink fill with a white-hot top highlight row and a darker pink bottom row (comic shading), 1-2 px near-black navy outline, and a 2 px deep purple drop shadow offset down-right. Amount ("+0.25", "+{likes}"): cyan fill with the same outline, so the name and the amount read apart. Burst: dark navy/purple fill, cyan stepped edge. Every colour is tested to be more than 0.5 (0..1 RGB distance) from `Hud.HEART_COLOR`, as in T-074.

**6. Animation.** Unchanged timings and code path: grow from 0.5 to 1 in 0.12 s, rise 40 drawn px with ease-out, fade the whole node in the second half, gone at 1 s. The no-semi-transparent-pixels rule covers the pixels inside the texture; fading the whole popup object is allowed (Visual style, see-through rule). Option for the board: step the grow (0.5, 0.75, 1) so the pixels never sit at odd in-between sizes for long; default is to keep the current smooth grow.

**7. Code change for the full task.** `PopupText._draw()` swaps its polygon + fallback font for drawing the cached texture; the public API (`show_popup`, `trick_text`, `SIZES`, `popups()`) stays the same, so T-091/T-083/T-092 tests keep passing. New tests: the texture has no semi-transparent pixels, no colour near the heart red, the burst fits around each text with a margin, deterministic rebuild.

**8. Risks.**
- Bangers without anti-aliasing can look ragged at the small size (20 px); fallback Press Start 2P or own lettering, decided from the sample.
- The camera zoom is not an integer (slider 6 to 20), so popup pixels come out 1 or 2 screen px apart unevenly, like the rest of the art; worst while zoomed out.
- The popups are bigger than any sprite pixel-wise; long texts ("Trending! +120 Likes") give a wide burst that may cover minions near the car for its second.
- Font file comes from outside: record the exact version/commit and ship the licence text.

**Recommendation:** script-drawn jagged burst sized per text + Bangers rendered without anti-aliasing, pink names / cyan amounts, popup pixel = 2 art pixels, current animation kept. Cost: 0 PixelLab generations (only a font download, after the board's go).

**One free sample:** a single still PNG of "FULL 360! +0.25" (normal size) built by the script, plus the same burst with "LONG DRIFT! +0.05" at the small size next to it, enlarged with nearest-neighbour on a dark and a light background, so the board judges the burst, the lettering and the size difference before the code swap.

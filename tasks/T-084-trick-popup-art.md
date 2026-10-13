---
id: T-084
title: Art: the comic-style look of the trick popups
status: in-qa
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
qa_rounds: 1
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

- [x] A screenshot shows each trick's popup in the final comic style (QA: pass)
- [x] The font's source and licence are recorded, and the licence allows commercial use (QA: pass)
- [x] Every PixelLab call is recorded with its prompt, settings and cost, and the balance before and after (QA: pass)
- [x] T-091's tests still pass (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

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

### Free sample round (2026-10-13; no PixelLab calls, game popup code not changed)

The board approved the plan direction and the Bangers download.

**Font:** Bangers Regular 2.100 (Vernon Adams, "Copyright 2010 The Bangers Project Authors"), SIL Open Font License 1.1, from https://github.com/google/fonts/tree/main/ofl/bangers at google/fonts commit `66928797f271fed5ee428544e7229685e2d90127` (raw.githubusercontent.com). Downloaded into an empty scratch folder first: both files' git blob hashes match GitHub's listing (TTF `9b0f8c1f…`, OFL.txt `bf717d4b…`), the TTF has the TrueType tag and parses (fsType 0), OFL.txt is the OFL 1.1 text. Copied unmodified to `game/fonts/bangers/Bangers-Regular.ttf` with `OFL.txt` next to it; source, commit, hashes and licence are recorded in `game/fonts/bangers/bangers.json`.

**Script:** `game/tools/build_trick_popup.py` (`sample` writes the files below, byte-identical every run; `check` runs the pixel check). It letters the text in Bangers with anti-aliasing off, splits it into name (hot pink, white-hot top row, darker pink-violet bottom row) and amount (cyan, light top row, darker bottom row), adds a navy outline (2 px normal, 1 px small) and a deep purple drop shadow (2 px / 1 px down-right), then draws a jagged burst sized to the text: a boxy superellipse around the text box with spikes spaced evenly by arc length (fixed seed), dark navy fill, stepped cyan edge (bright cyan outside, darker cyan inside) and a 1 px near-black outline. Needs Pillow (to rasterise the TTF), unlike the stdlib-only tools. Tests: `game/tools/test_build_trick_popup.py` (11 tests: rules for five texts including "Trending! +120 Likes", palette only, no Redgull red, burst fill covers the text box plus 1 px, name pink / amount cyan, small smaller than normal, deterministic, committed sample up to date). Full Python tool tests: 152 pass.

**Files (art-archive/T-084/):** `trick_popup_sample.png` (preview: "FULL 360! +0.25" normal and "LONG DRIFT! +0.05" small, enlarged 4x nearest neighbour, dark and light background side by side, 3712 x 364), `trick_popup_normal.png` (271 x 83 popup px), `trick_popup_small.png`, record `trick_popup_sample.json`.

**Pixel check** (`python game/tools/build_trick_popup.py check`): both popups pass (transparent border, no semi-transparent pixels, 11 colours, no colour within 0.5 of the heart red); the preview has no semi-transparent pixels and no Redgull red (13 colours with the two backgrounds). One fix during the build: the first darker-pink shade (176, 30, 150) was within 0.5 of the heart red, so it moved to (150, 30, 170). The burst spikes were tuned twice by script (free): the first pass gave thin fuzz, the second bunched spikes at the corners.

**Observations for the board:** the small size reads, but Bangers without smoothing is a little ragged at 20 px (stair-stepped slants, white-hot specks along the slanted tops, a tiny "." in 0.05). The navy text outline is almost the same as the burst's navy fill, so on the burst the purple shadow does the separating work. The normal popup is 271 x 83 popup px (about 217 x 66 drawn px at 0.8 drawn px per popup px), bigger than today's placeholder.

### Game round (2026-10-13; no PixelLab calls)

**No PixelLab calls were made in this task at all** (the burst is script-drawn, the lettering is Bangers), so criterion 3 (every PixelLab call recorded) is trivially met: 0 calls, 0 cost, balance unchanged.

The board approved going ahead and wanted to playtest rather than look at more images. Master merged into the branch first (no conflicts).

**Four free fixes (from the sample judgement):** text outline now near-black (3, 2, 8) so the letters separate from the navy burst fill; cleaner lettering: the highlight and shade rows only appear on flat runs of 3 or more pixels (no specks on slants) and not at all at the small size, small keeps a 1 px outline; left and right spike tips about half as long (smooth falloff by how sideways the spike points); normal popup smaller (font 32 instead of 35, spikes 8 to 13, 237 x 75 popup px for "FULL 360! +0.25" instead of 271 x 83). The "." of 0.05 reads at the small size (see the screenshots).

**In the game:** `game/scripts/hud/trick_popup_art.gd` (`TrickPopupArt`) bakes at runtime with the Bangers font (FontFile, antialiasing none, no hinting, no subpixel; the glyph bitmaps come from the font server, so it works headless too), builds the burst (port of the Python sample builder with the fixes), caches the ImageTexture per text and size. `trick_popups.gd`: `PopupText._draw` now draws that texture (nearest filtering, 0.8 drawn px per popup pixel); timing, rise, grow, whole-object fade, `show_popup`, `trick_text`, `SIZES`, `popups()`, `font_size` unchanged; sizes 16 or less pick the small popup. Covers the three tricks with amounts, the challenge popup and the drift prototype. Only the approved texts are used. A bake takes 5 to 40 ms, once per text. Note for the board: Bangers has capitals only, so "Trending! +120 Likes" shows as "TRENDING! +120 LIKES".

**Font:** Bangers Regular 2.100, SIL OFL 1.1, source and commit in `game/README.md` ("Trick popups", Font) and `game/fonts/bangers/bangers.json`; `OFL.txt` stays next to the font. Commercial use is allowed.

**Tests:** new `game/tests/unit/test_trick_popup_art.gd` (10 tests: no semi-transparent pixels, transparent border, no colour near `Hud.HEART_COLOR` (palette and every baked pixel), under 30 colours, burst fits each text, wider burst for longer text, same texture for same text and deterministic image, name pink and amount cyan, popup nearest filtering, empty text). Full GUT suite: 418 of 418 pass (includes the T-091, T-083 and T-092 tests). Python tool tests: `game/tools` 152 OK, `tools` 115 OK.

**Screenshots** (copied to `art-archive/T-084/`; screenshots/ is git-ignored): `T-084_trick_popups_demo.png` (all four popups in a run: LONG DRIFT! +0.05 small, FULL 360! +0.25, ALT DRIFT! +0.5, Trending! +120 Likes), `T-084_combo_demo.png` (the real combo path: each trick fires through the run state), `T-084_challenge_popup_demo.png`. Fixture `game/tests/fixtures/trick_popups_demo.gd` now shows all of them.

**Documents updated:** `game/README.md` (Trick popups, font source and licence), `docs/hud-and-menus.md` (Content, "Trick popups"). `game/tools/build_trick_popup.py` (round 1 sample builder) is left as is and no longer used by the game. Godot's line-ending-only .import changes were reverted (the new `Bangers-Regular.ttf.import` is committed).

### QA round 1 (2026-10-13, QA/Integration Agent): all criteria pass

1. **Screenshot of each trick's popup: pass.** `art-archive/T-084/T-084_trick_popups_demo.png` shows all four popups in a run in the comic style (jagged navy burst, stepped cyan edge, Bangers lettering, pink name, cyan amount): LONG DRIFT! +0.05 (small, flatter burst), FULL 360! +0.25, ALT DRIFT! +0.5 and TRENDING! +120 LIKES. `T-084_combo_demo.png` shows the three tricks through the real combo path. QA retook the trick screenshot and the challenge screenshot itself (frames 30 and 40): both show the comic popups ("TRENDING! +100 LIKES" above the car). Note: the committed `T-084_challenge_popup_demo.png` shows no popup at all (taken at a frame when it was not on screen); the popup itself works, the archived image just misses it. Worth replacing before the board looks at the archive.
2. **Font source and licence, commercial use: pass.** `game/fonts/bangers/bangers.json` records Bangers Regular 2.100, Vernon Adams, the google/fonts commit `66928797...`, upstream commit, URLs and hashes; `game/README.md` ("Trick popups", Font) records the same source, commit and SIL OFL 1.1; `game/fonts/bangers/OFL.txt` is next to the font and is the OFL 1.1 text. OFL 1.1 lets the font be used, bundled and sold with software (a commercial game included); only selling the font on its own is excluded.
3. **PixelLab calls recorded: pass (none made).** No commit, changed file or art record on the branch involves PixelLab; the burst is script-drawn and the lettering is the downloaded font. 0 calls, 0 cost.
4. **T-091's tests still pass: pass.** `git diff master...HEAD -- game/tests` changes no existing test (only the new `test_trick_popup_art.gd` and the screenshot fixture), so T-091, T-083 and T-092 tests are not weakened. `test_trick_popups.gd` 6/6, `test_challenge_popup.gd` 2/2, and the combo tests pass in the full run.
5. **Full GUT suite and all Python tool tests: pass.** GUT (`bash game/tools/run_tests.sh`): 418 of 418, TESTS PASSED, exit 0 (the one warning is the existing TestRoom inner class). `game/tools`: 152 tests OK. `tools`: 115 tests OK.

Code read: `game/scripts/hud/trick_popup_art.gd` (palette with index 0 transparent, two styles, cache per text and size, fixed seed) and `game/tests/unit/test_trick_popup_art.gd` (10 tests, check real baked pixels, not only constants). Small tidy-up, not a fail: a stray `pass` sits after `test_no_colour_near_redgull_red`.

**For the board (not a fail):** Bangers has capitals only, so the approved text "Trending! +{likes} Likes" (T-048) shows as "TRENDING! +{likes} LIKES". The board decides whether that is fine.

Godot's line-ending-only `.import` changes from the test run were left uncommitted.
- 2026-10-13, in-qa → needs-playtest: QA round 1: all criteria pass
- 2026-10-13, needs-playtest → in-progress: board playtest: make it look like a real comic popup: white bubble, black border, black letters (font like the board's ACTION! sample, letters on one straight baseline)

### The board's playtest, 2026-10-13 (round 1): rework

Not approved yet. The board wants the popups to look like real comic book popups:
- the bubble's background **white**, with **black** borders;
- the letters **black** (names and amounts alike);
- a font like the board's reference ("ACTION!": heavy, condensed, slanted comic capitals; a watermarked stock image, used only as a reference, nothing copied from it). Bangers is that style, so it stays. The reference's letters bob up and down; ours stay on one straight baseline.

Keep everything else: the jagged burst fitted to each text, the small extended-drift size, the timing, the code API, the tests' rules (no semi-transparent pixels, no Redgull red). Update the tests that pinned pink names and cyan amounts.

## Round 2 (2026-10-13; no PixelLab calls)

Reworked after the board's playtest. 0 PixelLab calls, 0 cost.

**What changed:** `game/scripts/hud/trick_popup_art.gd` now bakes a white jagged burst with a 2 pixel black border and all letters black (names and amounts alike) in Bangers on one straight baseline. No text outline, shadow, highlight or shade rows any more (black on white needs none), so the palette is only black and white. Kept: burst fitted to each text, small extended-drift size, timing/rise/fade, code API (`texture`, `bake`, `text_box`, `style_for`), no semi-transparent pixels, no Redgull red, nearest filtering, caching. Contrast: the black border separates the white burst from both the dark asphalt and the dusty gravel (the screenshots show the gravel ground).

**Tests:** `game/tests/unit/test_trick_popup_art.gd`: the pink/cyan test replaced by three: only white and black with a black border, name and amount both black, letters on one baseline. Full GUT suite: 420 of 420 pass (T-091, T-083 and T-092 tests included). Python tool tests run again, see below.

**Screenshots** (`art-archive/T-084/`, replacing the round 1 images, which stay in git history): `T-084_trick_popups_demo.png` (all four popups), `T-084_combo_demo.png` (combo path), `T-084_challenge_popup_demo.png` (taken at frame 30, popup on screen: "TRENDING! +100 LIKES").

**Documents updated:** `docs/hud-and-menus.md` (Content, "Trick popups"), `game/README.md` (Trick popups). Godot's line-ending-only .import and project.godot changes reverted.
- 2026-10-13, in-progress → in-qa: Round 2 done: white/black comic popups

### QA round 2 (2026-10-13, QA/Integration Agent): all criteria pass

Every criterion checked again independently after the board's rework request.

1. **Screenshot of each trick's popup: pass.** `art-archive/T-084/T-084_trick_popups_demo.png` shows all four popups in the new look (LONG DRIFT! +0.05 small, FULL 360! +0.25, ALT DRIFT! +0.5, TRENDING! +120 LIKES), `T-084_combo_demo.png` the three tricks through the real combo path, and `T-084_challenge_popup_demo.png` now really shows the challenge popup ("TRENDING! +100 LIKES" above the car; the round 1 note about the missing popup is fixed). All three are on the gravel. QA took one more itself on the dark asphalt road (temporary fixture, car placed at (54, 0) as in `drift_marks_demo_asphalt`, not committed): `art-archive/T-084/T-084_qa_asphalt_popups.png`. All four popups read clearly there: the white burst stands out strongly against the dark road, more than on the gravel.
2. **Font source and licence, commercial use: pass.** Unchanged since round 1: `game/fonts/bangers/bangers.json` (Bangers Regular 2.100, Vernon Adams, google/fonts commit `66928797...`, URLs, hashes), `game/README.md` ("Trick popups", Font), `game/fonts/bangers/OFL.txt` next to the font (OFL 1.1, allows use and bundling in a commercial game).
3. **PixelLab calls recorded: pass (none made).** No commit or changed file on the branch calls PixelLab; the files that mention it only say no call was made. 0 calls, 0 cost.
4. **T-091's tests still pass: pass.** Round 2 changed only `test_trick_popup_art.gd`: the pink/cyan test is replaced by white/black, black-names-and-amounts and baseline tests, and the stray `pass` is gone. No T-091, T-083 or T-092 test was touched (`git diff master...HEAD -- game/tests` changes no existing test file other than the demo fixture). `test_trick_popups.gd` 6/6, `test_challenge_popup.gd` 2/2 and the combo tests pass in the full run.
5. **Full GUT suite and all Python tool tests: pass.** Run by QA: GUT (`bash game/tools/run_tests.sh`) 420 of 420, 42 scripts, TESTS PASSED, exit 0 (two warnings: the existing TestRoom inner class and a Float/Int comparison notice, neither a failure). `game/tools`: 152 tests OK. `tools`: 115 tests OK.

**Against the board's request (white bubble, black border, black letters, one straight baseline): met.**
- Code: `trick_popup_art.gd`'s palette is only transparent, black (letters and border) and white (fill); no outline, shadow or shade rows. Tests check every baked pixel is exactly black or white.
- Baseline: QA baked the five popups itself (headless, `TrickPopupArt.bake`) and enlarged them 8x with nearest neighbour: `art-archive/T-084/T-084_qa_popups_enlarged_8x.png`. Letters sit on one straight line in every popup; measured per run of glyphs the bottom row is the same, apart from the "!" dot and the rounded 0/5 that sit 1 pixel lower (normal overshoot) and the "+" that sits higher by design. No letter bobs.
- For the board (not a fail): at the small size the "1" of "+100" reads a bit like a "T" and the "L" of "LONG" like an "I" (Bangers without smoothing at 20 px). Judge it in the playtest.

Godot's line-ending-only `.import` changes from the test runs were left uncommitted.

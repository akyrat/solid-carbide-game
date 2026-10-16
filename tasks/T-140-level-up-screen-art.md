---
id: T-140
title: "Art: the level-up screen, red and gold, Redgull-themed"
status: done
from: project-lead
to: asset-generation
lead: Level-up
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-052]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/weapons.md, tasks/T-052-level-up-screen.md, tasks/T-003-pixellab-test-generation.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, art-archive/T-140/, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-052 (the level-up screen, with its comic-look cards) is done.**

The board (2026-10-15): the level-up screen gets "nice art", "more red gold colored and themed". HUD and menus and Visual style, Decisions: the level-up screen's art is red and gold, themed on Redgull, since the weapons it offers arrive as Redgull gift packs (Visual style, Decisions: red is used on Redgull's own things). It is the art T-141's animation of the screen showing up uses.

Propose, in the result notes, which pieces the screen needs (for example a card frame or card back in red and gold, a header banner or ribbon, a backdrop or burst behind the cards, a highlight for the chosen card), how each fits T-052's layout and comic look, and whether each is drawn by script (free) or generated with PixelLab, with the planned calls and their cost.

**Money:** no PixelLab call without the board's go for this task. Sample first: one piece, for the board's review, then the rest only with its go. Use `game/tools/pixellab_client.py` with a 600 s HTTP timeout, one call at a time, and record every call (prompt, settings, cost, balance before and after). Report problems rather than regenerating.

**PixelLab go (board, 2026-10-16):** one sample, for the board's review. Write the planned calls and their cost in the result notes before calling. The full set only after the board approves the sample.

Follow Visual style, Decisions (hard-edged pixel art, a selective dark outline, about 30 colours per sprite, no semi-transparent pixels, a transparent background where the piece needs one). Real-world things are inspiration only: no real logos or brands. Put the approved art into `game/art/`; swapping it into the screen and animating it is T-141.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A check script shows every new sprite has a hard pixel edge, no semi-transparent pixels, and about 30 colours or fewer (QA: pass)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after, each round matching a board go written in this task file (QA: pass)
- [ ] A mock-up image puts the art together as the level-up screen over a dimmed run, as T-141 would show it (QA: pass)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: judge the look, sample first.

## Updates

### 2026-10-16, Open → In progress

Started: agent launched in C:\solid-carbide-worktrees$t. Part of the one level-up playtest build.

### 2026-10-16, In QA

Full set drawn by script (card frame, highlight, ribbon with logo medallions, sunburst, button plates, gift box emblem with logo). In QA; T-141 starts from this branch now.

### 2026-10-16, Needs playtest

QA passed every criterion. Waits in Needs playtest for the one level-up build.

### 2026-10-16, Needs playtest → Done

Board played the one level-up build: everything looks great. Done; merged into master.

## Result notes

Written by the agent when it finishes.

### Asset Generation Agent, sample round (2026-10-16): proposal and plan (written before any PixelLab call)

**Pieces the screen needs, how each fits T-052's layout, and how it is made.** T-052's layout: a white rounded banner (text at 40 px, "Redgull Sent a Gift Pack!") above two 360x300 cards side by side (40 px gap), cards with a 4 px black border and a "Take it" button, a yellow 8 px ring on the highlighted card, the run dimmed 60% behind. Pieces below keep that layout and the comic look (hard stepped corners, black outline), changing white and yellow to red and gold. Shown at 2 screen pixels per art pixel, like the popups.

| # | Piece | Fits T-052 as | Made by |
|---|---|---|---|
| 1 | Card frame (9-slice): gold border, dark red inner trim, cream fill, stepped corners | Replaces the white rounded card (360x300) | Script (free) |
| 2 | Header ribbon: red ribbon with gold edges and folded tails, text drawn on it by the game in Bangers | Replaces the white banner box above the cards | Script (free) |
| 3 | Backdrop burst: red and gold sunburst rays, dithered-free hard rays, centred behind both cards, transparent | A layer between the dimmed run and the cards; T-141 spins and scales it | Script (free) |
| 4 | Highlight: bright gold frame with stepped glow, a little larger than the card | Replaces the yellow ring on the chosen card | Script (free) |
| 5 | "Take it" button plate: gold plate with red edge, normal and pressed | Replaces the white button | Script (free) |
| 6 | Gift pack emblem: a Redgull gift box with a gold ribbon and bow, a few sparkles; the approved gull logo (`game/art/logo/`) is added on the box by script | Sits on the ribbon's left or centre top and above the cards, the one piece that is real illustration; T-141 can drop it in and bounce it | PixelLab, 1 call (the sample) |

Pieces 1 to 5 are flat graphic shapes, which a script draws crisply with the exact palette and no cleanup (free fixes before paid generations). Only the gift box needs drawn volume and shading, so it is the one piece worth a PixelLab call, and it is the sample.

**Sample: piece 6, the gift pack emblem.**
- Endpoint `/create-image-pixflux`, one call, 128x128, `no_background` true, outline "single color black outline", shading "medium shading", detail "high detail", `text_guidance_scale` 8, view and direction left to the model except the description asks for a 3/4 isometric view (Visual style, View).
- Description: "gift box package wrapped in red paper with a gold ribbon and a big gold bow, gold trim, small gold sparkles, 3/4 isometric view, retro pixel art, game icon". No logo or text is asked for (the gull is added by script from the approved logo; no real brands).
- Cost: 1 generation (the plan's subscription count). Balance before: 4903 of 5000 generations, 0.00 USD credit. Expected after: 4902.
- One round, no regeneration whatever the result.

**Planned cost of the rest, if the board approves the sample:** pieces 1 to 5 are free script work, 0 generations. Piece 6, if the sample is accepted, is already paid. If the board wants PixelLab variants of the ribbon or burst instead of script ones, about 1 generation per attempt, to be asked first.

### Sample result (Asset Generation Agent, 2026-10-16)

- **Call:** `/create-image-pixflux`, 1 paid call, params in `art-archive/T-140/req_gift_pack.json` (description, 128x128, no_background, single color black outline, medium shading, highly detailed, text_guidance_scale 8). An earlier attempt with `"high detail"` was rejected by validation (HTTP 422, not charged; the valid value is `highly detailed`); the file was corrected and the one real call made. Cost: 1 generation. Balance before: 4903 of 5000 generations (0.00 USD credit); after: 4902. Logged in `game/art/pixellab-generation-log.jsonl` and `art-archive/T-140/gift_pack_raw.json`.
- **Output:** `art-archive/T-140/gift_pack_raw.png`. Sprite check (`check_sprite_rules.py`): 128x128, transparent background, 0 semi-transparent pixels, 16 colours: pass. Red box with gold ribbon, bow and sparkles in a 3/4 view; no text or logo. Not regenerated.
- **Review images:** `gift_pack_review_dark_light_x4.png` (4x, dark and light), `level_up_mockup_rough.png` (1152x648, the sample plus quick script stand-ins for ribbon, cards, highlight, button and burst over a run dimmed 60%; the stand-ins are not final art). Made by `art-archive/T-140/make_review.py`.
- Not done yet (awaiting the board): pieces 1 to 5 as final art, the logo on the box, and anything in `game/art/`. Status not moved.

### Board's approval of the sample (2026-10-16)

The board approved the gift box sample and the piece plan. Its words: "Yeah, looks good to me. Um, please make sure to include like the redgull, um, the logo where needed or appropriate."

### Full set (Asset Generation Agent, 2026-10-16)

Built by script only, no further PixelLab call (total for this task: 1 generation; balance before 4903, after 4902). Script `game/tools/build_level_up_art.py`, art in `game/art/level_up/` with a record JSON per PNG (`card_frame`, `highlight_frame`, `header_ribbon`, `button_plate`, `button_plate_pressed`, `sunburst`, `gift_pack_emblem`). Sizes and how each fits T-052's layout: `game/README.md`, "Level-up screen art (T-140)".

**Where the Redgull logo is (the approved one-colour gull, `game/art/logo/redgull_logo_32.png`, in its own dark red):**
- On the gift pack emblem, on a cream disc on the box's front face: the box is Redgull's package, and a dark-red gull would not read on the red paper without the disc.
- On the header ribbon, on a cream medallion at each end: the banner says "Redgull Sent a Gift Pack!", so the sender's mark belongs there; it frames the title without touching the lettering.
- Not on the card frame, the highlight frame or the button: the cards hold the weapon names and descriptions, and a logo there would crowd the text and repeat the ribbon and box. Easy to add later if the board wants it.
- The sunburst has none (a backdrop behind everything).

**Checks:** `python game/tools/build_level_up_art.py check` passes for all 7 PNGs (no semi-transparent pixels, 30 colours or fewer, transparent corners). The raw box `art-archive/T-140/gift_pack_raw.png` is untouched (a test checks it). Mock-up of the full set over the 60% dimmed run: `art-archive/T-140/level_up_mockup_full_set.png` (made by `art-archive/T-140/make_mockup.py`; the sunburst is shown at about 55% strength and the card text is placeholder, both for T-141 to decide). Pieces that were a quick stand-in in the earlier rough mock-up are now the real ones.
- 2026-10-16, in-progress → in-qa: Full level-up art set built by script (card frame, highlight, ribbon, button plates, sunburst, gift pack emblem; Redgull logo on the emblem and both ribbon ends). 1 PixelLab generation in total. Mock-up: art-archive/T-140/level_up_mockup_full_set.png. GUT 100%, pytest tools 182 and game/tools 269 pass.
- 2026-10-16, in-qa → needs-playtest: QA pass: sprite checks, PixelLab record vs board go, GUT and Python tests all pass
- 2026-10-16, needs-playtest → done: The board's playtest of the one level-up build (2026-10-16): "i played the level up playtest, and everything looks great"

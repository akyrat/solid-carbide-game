---
id: T-130
title: Art: a few alert banners about the kaiju, on buildings and on the pavement
status: in-progress
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-128]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-128-narrative-tokyo-under-attack.md, tasks/T-064-building-art.md]
files_expected_to_change: [art under game/art/ and its records, the map's drawing of banners, tests, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board wants **a few** banners (only a few!) around the city alerting about the monster (Visual style, Decisions, 2026-10-14): some hanging on buildings, some standing as signs on the pavement, each with a silly, minimalistic pixel painting of the kaiju's head or its general Godzilla-like body shape. Their form and any words come from T-128 (approved by the board); if they carry words, those words are the approved text, and this task does not start until they are approved.

Propose how many banners on the whole map (a few), where (which buildings and pavement spots; never on the roads, never blocking the car), and how many designs, in the plan. Banners are visual only: no collisions. They sit in the map's depth order and fade with the building they hang on.

Follow Visual style, Decisions: pixel art for the isometric view at the game's pixel density (the car and ground are drawn at 32 art pixels per unit, scale 0.5), a selective dark outline, detailed shading, about 30 colours per sprite, glow drawn into the pixels (no engine bloom), no anti-aliasing, no semi-transparent pixels, a transparent background, the night neon palette, no Redgull red. Real-world things are inspiration only: no real logos, no copies of existing characters (the kaiju is "in the style of Godzilla", never Godzilla). Read T-128's narrative guidance first and keep the look consistent with every approved asset (car, ground, boulders, drift marks and smoke).

PixelLab: never call it without the board's go for this task. Plan first (calls, sizes, cost) in the result notes and bring it to the board; then one sample for the board's review; then the full set from the approved sample. Use `game/tools/pixellab_client.py` with a 600 s timeout, record every call with its prompt, settings and cost and the balance before and after, and do not regenerate weak results: report them. Free script fixes come before paid calls. Never delete generated art: unused versions go to `art-archive/<task>/`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge.

## Acceptance criteria

- [ ] A check script shows every new sprite has a transparent background, no semi-transparent pixels, about 30 colours or fewer, and no Redgull red (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; every call had the board's go (QA: pass / fail)
- [ ] Screenshots in a run show the banners on buildings and on the pavement, only a few on the map, none on the roads; any words are exactly T-128's approved text (QA: pass / fail)
- [ ] The banners have no collisions, sit in the right depth order and fade with their building; T-034 and T-064's tests pass (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest the city and judge the banners.

## Result notes

- 2026-10-14, open → blocked: waits for T-128 and T-064
- 2026-10-14, blocked → open: depends only on T-128 now; built on T-064's branch later
- 2026-10-14, open → in-progress: board started it (2026-10-15): plan first

### Plan (2026-10-14, planning round: no PixelLab call made, nothing downloaded, no game file changed, no branch)

**Read:** the City brief (Visual style, Decisions: banners are picture-only, cyan or pink on a dark panel with a plain warning border, few on the map), T-128's notes (picture-only recommended; large on buildings, small on the pavement; QA flag: 32 art px per unit, not 40), T-064's task file (skyscrapers 2 x 2 per block with pavements; its redesign plan is still being written, so the spots below are given relative to a block and re-checked against its built art), `game/README.md` "See-through buildings", `agent-notes/asset-generation.md` and `game/tools/pixellab_client.py`.

**Recommendation: draw the banners by script, free (0 PixelLab calls, 0 generations).** Reasons: the pictures are tiny, flat, "silly and minimal" (a head or a round-backed body as a 20 to 30 px bitmap), which a hand-authored pixel grid in a script does well; a script gives exact control of the palette (at most 30 colours), the outline, the stepped glow and "no real words, no copy of the film monster", and is deterministic and testable, as with the level-up particles, drift marks, smoke and popups. PixelLab would also need script work afterwards (panel, border, warning shape, palette mapping), and its isometric flag drifts off the game's 2:1 angle (T-101). Fallback only if the board dislikes the script pictures: see "Optional PixelLab" at the end.

**How many on the whole map: 6** (4 on buildings, 2 standing signs on the pavement), on a map of 12 blocks (the 4 x 4 grid minus the gravel centre). Few enough that each is noticed; the board can raise or lower the number (the list is data, see below).

**How many designs: 4**, each in 2 colourways, so 8 sprites:
1. Building banner, head (the kaiju's head in profile: blunt snout, one eye, a row of back spikes).
2. Building banner, body (Godzilla-like silhouette from the side: round back, back spikes, thick tail, two legs; no copy of the film monster, simplified into a silly shape).
3. Pavement sign, head.
4. Pavement sign, body.
Colourways: cyan and pink, made by a free palette swap (never towards red). The 6 placed banners use all 4 designs and both colours, so no two neighbours match.

**Sizes (32 art px per unit, drawn at scale 0.5 like the car and ground, nothing scaled up):**
- Building banner: 3 units wide by 4 units tall on the wall = 96 x 128 art px painted front-on (panel about 6 px dark border band, plain warning border, picture about 24 to 28 px inside), then sheared by the script onto the wall, 1 art px down per 2 across (the game's 2:1 wall slope), giving about 96 x 176 art px (48 x 88 px on screen). That is about a car length wide, readable but far smaller than a 15-unit wall. Two wall slopes (the +x wall and the +y wall are the visible ones) come from one painting: mirror the sheared sprite. Hung with its bottom about 3 units above the ground (over the pavement and shop signs, clear of the cars).
- Pavement sign: a board 1.5 units wide by 2 units tall on a 1-unit post = 48 x 96 art px, standing upright and facing the camera (not sheared), small dark base. About 24 x 48 px on screen, smaller than the car.
- Sprite rules: transparent background, no semi-transparent pixels, at most 30 colours (dark navy panel, 3 shades each of cyan or pink, a dark outline, stepped glow pixels), no anti-aliasing. Palette from approved art only (the ground atlas navy and purple, the level-up particles' pink and cyan; same 29-colour set as T-064's palette). Pink must stay more than 0.5 from `Hud.HEART_COLOR` (0.86, 0.1, 0.16): a hot pink such as (1, 0.2, 0.6) is only 0.47 away, so lean it towards violet, e.g. (0.95, 0.3, 0.8) is 0.68.

**Where they go (proposal; block = 30 x 30 units, block starts at -96, -42, 12, 66 on each axis, grid column / row 0 to 3 from the north-west; the roads are between them and the 24-unit perimeter road around):** banners only on a skyscraper's visible walls (+x and +y) that face a road, so the player sees them from the street; signs on the pavement strip on a block's visible edges (+x or +y side, 1.5 units inside the kerb, never on the road itself). The north and west edges are hidden behind the towers, so nothing goes there.
- Building banners: block (0,0) on its +y wall (south, facing the road to the next row); block (3,1) on its +x wall (facing the perimeter road); block (2,0) on its +x wall (facing the road to column 3); block (1,3) on its +y wall (facing the perimeter road). Spread over the four quadrants, so a banner is in sight along a lap without clustering.
- Pavement signs: block (0,2) at the corner of its +x and +y pavements, and block (3,3) the same, i.e. one at each of two crossings, 1.5 units in from the kerb.
- Exact points are re-checked against T-064's built blocks and T-129's slots: the banner must sit on a wall that exists (a tower or a shorter building) and the sign on pavement. If a slot holds T-129's shorter building, the banner goes on its wall at a lower height (bottom 1 unit above the pavement), the same sprite.
- The spots live in a small data list in the map's layout data (id, kind building / pavement, block, wall or corner, offset, design, colour), so the board can move, add or remove banners without code changes.

**Technical build:**
- Script `game/tools/build_kaiju_banners.py` (`build`, `check`, `preview`), tests `game/tools/test_build_kaiju_banners.py` (Python tool tests), output `game/art/banners/banners_atlas.png` + `banners.json` (rectangles, anchor points per sprite). The check script verifies the sprite rules and the Redgull-red distance, and that the art has no letters (a text-free sanity check is manual: the board's eye and the preview).
- In the game: each building banner is a `Sprite2D` child of the skyscraper node it hangs on (`texture_filter` nearest, scale 0.5, drawn after the node's `Towers` art and before nothing else of its own). A pavement sign is a child of the building node whose pavement it stands on (the one nearest its spot). Both are therefore:
  - **Fading with the building:** the node's `modulate` fades the children (T-034: 0.15 alpha, 0.15 s); the sign fades with its block too, so a faded block never leaves a floating sign over the car. No change to the fade code, no semi-transparent pixels needed in the art.
  - **In the depth order:** they inherit the building's `z_index` (below 100, the popups stay on top, unchanged scheme). The car is drawn under a covering building and over every building when none covers it, so the car behind a block never draws over its banner and a car in front of it on the road always draws over it.
  - **Without collisions:** only `Sprite2D`, no body, area or shape; the map's collision shapes (112 today) and layout stay identical (a test compares the counts before and after, as QA did for T-064).
  - **Never on the roads:** a test checks every banner's ground point lies inside a block rectangle (for a sign), or its wall's ground line lies on a block edge (for a banner), and none lies in a road rectangle.
- Tests (GUT): `test_kaiju_banners.gd`: 6 banners exist, 4 building / 2 pavement, all 4 designs and both colours used; none under a road; no collision objects added; each is a child of a building and fades with it (alpha follows `modulate`); `z_index` equals the building's. Python tests as above; T-034 and T-064's tests must still pass; the full GUT suite and all Python tool tests run before handing over.
- Screenshots: `bash game/tools/screenshot.sh` of a banner on its wall next to the car, a pavement sign, the car behind a block (banner faded), and the overview; plus a 4x enlarged preview of the 8 sprites on dark and light backgrounds.

**Cost:** 0 PixelLab calls, 0 generations, no USD. Balance is unchanged (4946 of 5000 on 2026-10-14, QA's free `GET /balance`); the record will state that no call was made. Work is a branch off T-064's branch once the board starts the build step (after T-064's art is built, since the banners sit on its walls).

**Optional PixelLab (only if the board rejects the script pictures; needs the board's go):** 2 calls of `POST /create-image-pixflux` through `game/tools/pixellab_client.py` (timeout 600 s, no resend), one per picture (head, body), `image_size` 64 x 64 (below 200 x 200, so a real transparent background), `no_background` true, `outline` selective outline, `shading` basic shading, `detail` low detail, `view` side, `color_image` T-064's `palette.png`, prompts like "silly minimalistic pixel painting of a giant monster head in profile, round blunt snout, one eye, row of back spikes, flat colours, single colour cyan on dark, no letters, no text" (and "side view of a Godzilla-like round-backed monster with back spikes and thick tail, simple shapes"; the word Godzilla would be left out of the actual prompt to keep away from the real design, just "giant dinosaur-like monster"). Expected cost: 1 generation each (T-003 at 128 x 128 and T-064 at 384 x 400 both cost 1), so **2 generations in all**, then the same free panel, border, shear, palette and checks. One round, no regeneration. Risk: PixelLab tends to draw letters or a detailed, film-like creature, which the board would then judge.

**Risks:**
- No copy of Godzilla: shapes are silly and simplified (the film design's face and dorsal plates are not copied); the word Godzilla and any kaiju name appear nowhere, neither in the art, files, ids nor labels (the sprites are called "kaiju head" / "kaiju body").
- No words: picture-only per the City brief; no letters, digits or kanji-like marks on the banners (T-064's towers carry kanji-like marks the board accepted; the banners stay clean to keep the brief's "picture-only"). The check cannot detect letters, so the preview is the check.
- No Redgull red: pink leans violet, tested above 0.5 by the check script; no warning red either (the warning border is cyan or pink, not red, even though warning signs are usually red or yellow). No seagull or Redgull layout.
- Script pictures may look too clean or too small to read; the board judges at the sample step, and the cheapest next step is the 2-call PixelLab option above.
- T-064's final layout is not yet known: spots may need nudging; the data list keeps that free.
- Sprites facing the wrong way (mirror) or a shear that does not line up with the tower art's slope: the sample's screenshots show it before the full set.
- Too many or too few banners: the count is data, not code.

**Steps after the board's go:** (1) sample: one building banner (head, cyan) and one pavement sign (body, pink) built by script, previews and a screenshot on a T-064 block (free); (2) the board judges; (3) the other 6 sprites, the 6 placements, tests, README section "Alert banners". No PixelLab call at any step unless the board chooses the optional fallback.

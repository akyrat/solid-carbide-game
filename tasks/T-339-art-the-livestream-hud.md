---
id: T-339
title: "Art: the livestream HUD (clock, live viewers counter and its fire, sub goal, hearts, icons)"
status: in-qa
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, docs/extended-narrative.md, docs/working-with-the-board.md, game/README.md, game/art/gift_pack/package.png]
files_expected_to_change: [game/art/hud/, art-archive/T-339/, docs/visual-style.md, game/README.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28). Make the pixel art for the new HUD pieces, in the game's pixel rules and comic HUD look (Visual style, Content, "Rules"; none of Greenbull's colours outside Greenbull's things, rule 6):

1. **The digital clock:** a dark panel and segment-style digits 0 to 9 and the colon, drawn so the game can tint them green, yellow, orange and red (white or greyscale digits), plus a soft glow.
2. **The live viewers counter:** its panel, a **LIVE** badge (red, like a stream's), a small **eye icon** for the viewers (also used on trick popups), and a **fire animation** for the counter over a million (looping pixel flames around the panel, 8 to 12 frames, in the burning likes bar's fire colours).
3. **The sub goal:** the square's frame (black inside, an outline that reads over the street), and a **subs icon** (the board's mock uses a star; propose better).
4. **Hearts:** a **full heart** and an **empty heart**, at the HUD's size, in the comic HUD style.

**Not tied to the HUD tickets:** this ticket doesn't wait for T-335 to T-338. The board will **place the finished art on its HUD layout page** (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4; the Project Lead uploads it there), so save each asset as its own PNG in `game/art/hud/` with a record. The HUD tickets use the art if it has landed in their branch; otherwise the Project Lead writes a short ticket to swap it in.

**PixelLab: the board's go** ("please don't be stingy"), **up to 40 generations** for this ticket, through the style loop (at most 3 refines per asset). Free script work first where it is as good (the digits may be best drawn by script). Write the planned calls and cost in the result notes before calling, with a long HTTP timeout (600 s). Every asset goes through the style loop. No sample review: the board judges the art on the layout page and in the playtest.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/hud/` holds: the clock panel and digits 0 to 9 and the colon; the viewers panel, the LIVE badge, the eye icon and the fire animation frames; the sub goal frame and the subs icon; a full and an empty heart; each with a record (how it was made). (QA: pass: 35 PNGs with 35 json records, all named pieces present)
- [ ] Each asset scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review. (QA: pass: all 8 or more except the viewers fire, recorded at 7 after 3 refines with every round in the Style review; noted for the board's playtest)
- [ ] The PixelLab generations used are 40 or fewer, listed in the result notes with the planned calls written before calling. (QA: pass: 2 of 40 generations, planned calls written before calling)
- [ ] Visual style and game/README.md record the art. (QA: pass: Visual style and game/README.md both have the HUD art sections)
- [ ] A contact sheet of every asset, enlarged, on a dark and a light background, is in `art-archive/T-339/`. (QA: pass: contact sheet seen, dark and light, enlarged)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: PixelLab go, up to 40 generations.

### 2026-10-28, Flagged for review → In progress

Board's go (overnight HUD work, no stopping): the fire at 7/10 after 3 refines is kept and noted for the morning playtest, as in a goal run; sending to QA.

### 2026-10-28, In progress → In QA

QA running now; the fire (7/10) is listed for the board's playtest.

## Style review

### Run 1

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/clock_digits.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1.png`
- Script checks: 61 of 61 pass
- Score: 8/10
- Reason: The strip is a row of 12 greyscale frames. Digits 0 to 9 read as seven-segment shapes with a bright centre, lighter sides and a stepped grey halo. The colon is present, and the last frame is a single-colour dim unlit "8" with no halo. The script checks pass: rule 1 (opaque or transparent pixels only, 4 colours or fewer per frame), rule 3 (16x26 frames) and rule 6 (no Greenbull colours). Rule 5 holds: the glow is drawn as stepped halos inside each frame, with no blur. Rule 2's outline is replaced by the panel's black screen, as the brief allows. Rule 4 holds: bright digits on a dark panel read as retro at night. No rule is clearly broken. The image is very small, so I couldn't check the segment tapers, the gaps or the halo steps pixel by pixel. If the maker refines, it should check that the halo steps are visibly distinct and that adjacent segments keep a clear gap at 2x.
- Rules broken: none
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-339/style-loop && ls art-archive/T-339/style-loop; python game/tools/build_hud_livestream_art.py digits --out \"C:\\solid-carbide-worktrees\\T-339\\art-archive\\T-339\\style-loop\\v1.png\" && python -m unittest discover -s game/tools -p test_build_hud_livestream_art.py 2>&1 | tail -3; python -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-339/style-loop/v1.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01Fi9dyEHk9HmaXffwdom39e"}; {"tool_input": {"command": "python -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-339/style-loop/v1.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01HhKhisUR6qgqsDc1Mxzp8B"}

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1.png`, copied to `game/art/hud/clock_digits.png`): it reached 8 or more.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/clock_panel.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-2.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: I could only see the image at its native 100x36, so small details are hard to judge. It reads as a dark steel bezel with a near-black outline, a black screen and a lighter top-left edge, which suits the livestream HUD. Rule 1 passes on the script checks (20 colours, no semi-transparent pixels, transparent corners). Rule 4 is met: it is dark and retro, and it should read over the night street. Rule 6 passes (no Greenbull colours). Rules 3, 5, 7, 8, 9 and 10 don't apply to this piece, or aren't broken. The one weak spot is rule 2: the bezel shading, the screws and the scanlines are faint and low in contrast, so the panel looks rather flat and the highlight pixels breaking the outline are hard to see. To fix it, brighten the top-left bezel highlights a little, make the screws and the glare read more clearly, and keep the outline (8, 8, 15) stepped at the corners. Otherwise no rule is clearly broken.
- Rules broken: 2
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-339/style-loop && ls art-archive/T-339/style-loop; python game/tools/build_hud_livestream_art.py clock-panel --out art-archive/T-339/style-loop/v1-2.png && python -c \"from PIL import Image;i=Image.open('art-archive/T-339/style-loop/v1-2.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01PyMdk7R3utu9y5gc6QPwFf"}

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1-2.png`, copied to `game/art/hud/clock_panel.png`): it reached 8 or more.

### Run 3

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/viewers_panel.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-3.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The panel passes every script check: 120x36, transparent corners, 21 colours, no semi-transparent pixels, and no Greenbull green or yellow (rule 6). It reads as a dark housing with a thick near-black outline and a thin cyan inner rim in the viewers colour. That fits rule 4, since it will read over the dark night street. The edges are hard (rule 1). I looked at the image at its native size, where it is very small. It has a flat, clean look, with only a faint highlight or bevel on the housing. Rule 2 asks for detailed shading and highlight pixels breaking the outline, so a refine could add a few lighter highlight pixels on the top edge and corners, or screws and bevel steps. That would give the housing more of the HUD's comic look and keep it in one family with the clock panel. No real brands or words appear (rule 9). I found no serious violation.
- Rules broken: 2
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-339/style-loop && ls art-archive/T-339/style-loop; python game/tools/build_hud_livestream_art.py viewers-panel --out art-archive/T-339/style-loop/v1-3.png && python -c \"from PIL import Image;i=Image.open('art-archive/T-339/style-loop/v1-3.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01CzJycFmtNEods1gGZFcBH4"}

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1-3.png`, copied to `game/art/hud/viewers_panel.png`): it reached 8 or more.

### Run 4

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/live_badge.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-4.png`
- Script checks: 6 of 6 pass
- Score: 7/10
- Reason: The badge passes the script checks (34x13, 7 colours, transparent, opaque pixels only, no Greenbull colours). The image is tiny, so this is a judgement from a small view. It has a near-black outer outline, a red body, a white dot and bold white LIVE letters. It reads as a stream badge, looks retro and should hold up over a dark night street at 2x. Rule 9 is fine because the board named the word LIVE. Rule 2 is the weak point. The red body is flat, with no lighter highlight pixels breaking the outline and no darker red shade for depth. The result looks more like a flat sticker than the guide's detailed shading. To fix it, add one or two light-red highlight pixels along the top edge or corners, add a darker-red bottom edge or shade row inside the outline, and break the outline with a highlight pixel or two. Keep the letters and dot unchanged and stay within about 8–10 colours. No other rules are broken.
- Rules broken: 2
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-339/style-loop && ls art-archive/T-339/style-loop; python game/tools/build_hud_livestream_art.py live-badge --out art-archive/T-339/style-loop/v1-4.png && python -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-339/style-loop/v1-4.png');print(i.mode,i.size)\" && python -m unittest discover -s game/tools -p test_build_hud_livestream_art.py 2>&1 | tail -3"}, "tool_name": "Bash", "tool_use_id": "toolu_016dJuid4ad329S51V2e4Hky"}; {"tool_input": {"command": "python -c \"\nfrom PIL import Image\ni=Image.open('C:/solid-carbide-worktrees/T-339/art-archive/T-339/style-loop/v1-4.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01EE9kDTmtC3Ra86cMQaYwkY"}

#### Round 2

- Version 2: `art-archive/T-339/style-loop/v2.png`
- What changed: Version 2 of the LIVE badge, made by the script alone with no PixelLab generations. Only the shading changed; the letters and dot are untouched. The changes are:
- A light-red gloss on the top-left corner, with a light-red strip down the left inner edge.
- A darker-red band two rows deep along the bottom, and a dark-red strip down the right inner edge.
- Three light-red pixels that break the top outline.
The script's 12 tests pass, and the badge still has about 8 colours. I did not check the PNG's mode and size; I only looked at the tiny rendered preview.
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The 34x13 badge is red with a thick near-black outline, a white dot and bold white LIVE letters. The script checks pass: 7 colours, no semi-transparent pixels, a transparent background, and no Greenbull green or yellow. The letters read at a glance and the badge would stand out over a dark night street. I only saw the image at its native 34x13 size, so I couldn't inspect individual pixels. Rule 2 (broken outline, detailed shading) doesn't apply strictly to flat comic HUD art. A small highlight on the top edge or a one-pixel lighter rim could lift it a little further, but this is optional. Rule 9 is not broken, because the board chose the word LIVE. I found no rule violations.
- Rules broken: none

**Kept:** version 2, score 8/10 (`art-archive/T-339/style-loop/v2.png`, copied to `game/art/hud/live_badge.png`): it reached 8 or more.

### Run 5

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/viewers_fire.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-5.png`
- Script checks: 61 of 61 pass
- Score: 7/10
- Reason: The script checks pass: 136x64 frames, 5 colours, no semi-transparent pixels, and no Greenbull colours. The fire palette is correct and the panel is left clear. The layout also matches the brief, with tall tongues on top, short flames on the sides and a very low edge below. It is a retro, night-readable HUD piece.

Rule 5 (minor): the brief asks for a drawn glow. The flames carry no stepped halo of darker shades around the bright core. They read as a thin jagged fringe round the panel, not as a glow. Add a one-to-two-step halo of the orange or the dark red-brown around the tongue bases and tips, drawn inside the 136x64 frame, with no blur.

Rule 2 (minor): the top tongues are thin and ragged, and the white-hot, yellow and orange bands are hard to tell apart at 2x. The sparks are tiny, scattered single pixels that look like noise. Make the tongues thicker and fewer, with clear stepped colour bands (white-hot base, yellow, orange-yellow, orange tips) and a continuous dark red-brown edge. Make the sparks a few deliberate 1-2 px clusters.

Rule 4: a few shapes are weak against the light background, but the dark red-brown edge holds them up.

Nothing else is broken. A script refine could fix both points, and no PixelLab generation is needed.
- Rules broken: 5, 2
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-339/style-loop && ls art-archive/T-339/style-loop; python game/tools/build_hud_livestream_art.py fire --out art-archive/T-339/style-loop/v1-5.png && python -m unittest discover -s game/tools -p test_build_hud_livestream_art.py 2>&1 | tail -3; python -c \"\nfrom PIL import Image;i=Image.open('art-archive/T-339/style-loop/v1-5.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01PZGjTD84WPeAqx2SXGtsom"}

#### Round 2

- Version 2: `art-archive/T-339/style-loop/v2-2.png`
- What changed: This is version 2, saved as v2-2b.png, not the v2-2.png you asked for. v2-2.png already exists. It is an earlier draft of mine with shorter tongues, and the tool refuses to overwrite it, so please score v2-2b.png. I made no PixelLab calls, and the 12 script tests pass.

Changes to `game/tools/build_hud_livestream_art.py`:
- **Tongues:** thicker and fewer. They are 15 px apart, with a half-width of 6 to 8.5 px, a rounder profile, and a higher reach.
- **Colour bands:** the noise is cut to almost nothing, so the white-hot, yellow, orange-yellow and orange bands step cleanly.
- **Edge and glow:** a continuous 1 px dark red-brown edge ring now runs round every flame. Outside it, a checkerboard halo steps the glow out, in orange above the panel and dark red-brown elsewhere. It is drawn with no blur.
- **Sparks:** 4 deliberate clusters, 2x2 or 2x1 px, that rise 1 px a frame so they loop.
- **Panel:** the clear zone is now enforced, and the panel stays clear apart from the 2 px lick over its top edge.

The top tongues are still shorter than the brief's "tall". I didn't check the PNG's colour count or 8-bit RGBA mode.
- Script checks: 61 of 61 pass
- Score: 6/10
- Reason: The script checks all pass: 5 colours, opaque or transparent pixels only, a transparent background, no Greenbull colours, and 136x64 frames. Rules 1, 5 and 6 are fine. The glow is drawn as stepped colour bands with no blur. The palette (white-hot, yellow, orange-yellow, orange, dark red-brown edge) matches the likes bar's fire and reads over a dark or light street (rule 4).

The art is weak on rule 2 (detail and shading) and on the brief's shape. (1) Rule 2: the flames are a thin, almost uniform band of small, similar spikes. The tongues above are only a few px taller than the rest and have little variety in height. The brief asks for tall tongues above, and this reads as a low flame rim. Make 3-5 clearly taller tongues per frame, with tips that curl, split and detach. (2) The side flames are barely there. They are a 1-2 px fringe, and they should be short visible flames. The bottom is a thin outline, which is acceptable. (3) The sparks the brief asks for are not visible at this scale. Add a few isolated 1-2 px spark pixels floating above the tongues, moving between frames. (4) Shading: the white-hot, yellow, orange and edge layers form a flat, even stripe along the rim, with no gradient from a hot base to cooler tips inside the taller tongues. Give each tongue its own white-hot core and orange tip. (5) The frame-to-frame change is small and the frames look near-identical. The loop will look static rather than a roaring one-million fire. Increase the motion so the tongues travel, grow and shrink across the 12 frames, while the last frame still runs into the first. (6) The panel rectangle's hard rectangular edge, wrapped in a flame outline, looks like a bordered box rather than fire licking round it. Break the edge up with irregular flame clusters.
- Rules broken: 2
- Refused: {"tool_input": {"command": "python - <<'E'\np='game/tools/build_hud_livestream_art.py'\ns=open(p,encoding='utf-8').read()\ns=s.replace(\"TONGUE_GAP = 9\\n\",\"TONGUE_GAP = 15\\n\")\ns=s.replace(\"cx = k * TONGUE_GAP + 4 + int(_hash(k, 7) * 3)\\n        half = 3.5 + _hash(k, 11) * 2.0\",\"cx = k * TONGUE_GAP + 5 + int(_hash(k, 7) * 3)\\n        half = 6.0 + _hash(k, 11) * 2.5\")\ns=s.replace(\"best = max(best, (1 - d * d) * swell)\",\"best = max(best, (1 - d ** 1.6) * swell)\")\ns=s.replace(\"\"\"    return 1.0 - e + 0.34 * n + 0.22 * (tongues - 0.5) * (1 if above > 0 else 0.3) + 0.12 * flick\"\"\",\"\"\"    return 1.0 - e + 0.07 * n + 0.04 * flick       # thick tongues with clean stepped bands: little noise\"\"\")\na=s.index(\"def fire_frame(\")\nb=s.index(\"def fire_sheet(\")\nnew='''def _clear(x, y):\n    \"\"\"The panel's clear zone: nothing is drawn here (the 2 top rows lick over it).\"\"\"\n    return PANEL_X <= x < PANEL_X + PANEL_W and PANEL_Y + 2 <= y < PANEL_Y + PANEL_H\n\n\ndef fire_frame(t, frames=FIRE_FRAMES):\n    im = new(FIRE_W, FIRE_H)\n    flame = set()\n    heat = {}\n    for y in range(FIRE_H):\n        for x in range(FIRE_W):\n            h = fire_heat(x, y, t, frames)\n            if h > 0.42 and not _clear(x, y):\n                flame.add((x, y))\n                heat[(x, y)] = h\n    # glow: a stepped halo, a checkerboard of the dark edge colour 2 px outside the flame, then the solid edge ring\n    ring, halo = set(), set()\n    for (x, y) in flame:\n        for dx, dy in ((1, 0), (-1, 0), (0, -1), (0, 1)):\n            q = (x + dx, y + dy)\n            if q not in flame and not _clear(*q):\n                ring.add(q)\n    for (x, y) in ring:\n        for dx, dy in ((1, 0), (-1, 0), (0, -1), (0, 1)):\n            q = (x + dx, y + dy)\n            if q not in flame and q not in ring and not _clear(*q) and (q[0] + q[1]) % 2 == 0:\n                halo.add(q)\n    for (x, y) in halo:\n        put(im, x, y, FIRE[3] if y < PANEL_Y else FIRE_EDGE)\n    for (x, y) in ring:\n        put(im, x, y, FIRE_EDGE)\n    for (x, y) in flame:\n        h = heat[(x, y)]\n        put(im, x, y, FIRE[0] if h > 0.86 else FIRE[1] if h > 0.72 else FIRE[2] if h > 0.57 else FIRE[3])\n    for k in range(4):                                 # sparks: 2 px clusters rising 1 px a frame on a 12 px path (loops)\n        sx = 14 + int(_hash(k, 99) * (FIRE_W - 30))\n        sy = PANEL_Y - 12 - ((t + k * 3) % frames)\n        c = FIRE[1] if k % 2 else FIRE[0]\n        cells = [(sx, sy), (sx + 1, sy)] if k % 2 else [(sx, sy), (sx + 1, sy), (sx, sy + 1), (sx + 1, sy + 1)]\n        for q in cells:\n            if q not in flame and q not in ring and q not in halo and 0 <= q[1] < FIRE_H:\n                put(im, q[0], q[1], c)\n    return im\n\n\n'''\ns=s[:a]+new+s[b:]\nopen(p,'w',encoding='utf-8').write(s)\nE\npython game/tools/build_hud_livestream_art.py fire --out art-archive/T-339/style-loop/v2-2.png"}, "tool_name": "Bash", "tool_use_id": "toolu_014M1wAJ6t4nz8ZpzJmdPduj"}

#### Round 3

- Version 3: `art-archive/T-339/style-loop/v3.png`
- What changed: This is version 3, saved as v3c.png, not the v3.png you asked for. v3.png and v3b.png are earlier drafts of mine that failed the test for transparent frame corners, and the tool won't overwrite them. Please score v3c.png. All 12 script tests pass with it, and no PixelLab generations were used.

I rewrote the fire's heat function in `game/tools/build_hud_livestream_art.py` as a single tongue builder, `lick`:
- **Top tongues:** every other tongue is tall, 8 to 21 px, and the ones between are short. Each tapers to a tip, sways and curls, and swells and shrinks over the loop, so tall tongues come and go across the 12 frames. The tall ones shed a detached tip.
- **Shading:** heat falls from a white-hot core at the base to an orange tip, so each tongue is shaded inside.
- **Sides and bottom:** the sides now have their own short flames, 4 to 9 px, and the bottom has a very low rim of 1 to 3 px.
- **Panel edge:** the irregular tongues replace the even band, which should stop the panel reading as a bordered box.
- **Edge and glow:** the dark red-brown edge ring and the stepped halo stay as in version 2.
- **Sparks:** 7 isolated 1 to 2 px sparks rise and drift sideways between frames.
- **Corners:** the frame's four corner pixels are forced transparent. This is what fixed the failing test.

I didn't open an enlarged preview, because that command was refused. I haven't checked how tall the tongues look, or whether the side flames read well, at this scale. I viewed the v3 and v3b sheets, which looked the same as v3c, but not v3c itself.
- Script checks: 61 of 61 pass
- Score: 7/10
- Reason: Passes the script checks: rule 1 (5 colours, hard edges, transparent), rule 3 (size), and rule 6 (no Greenbull green or yellow). It reads as pixel fire in the likes bar's colours with a dark red-brown edge, so it should read over a dark or light street (rule 4). Weaknesses: (1) Rule 5: the drawn glow is hardly there. I see no stepped halos of darker shades round the flames, only the flame body and its edge. Add one or two stepped darker-orange or red-brown halo rings, as hard-edged pixels, outside the flames' tips. (2) Rule 2: the flames are thin and jagged, with little shading depth. The white-hot base, yellow and orange tip bands are narrow, and the outline is a thin dark-red line with no lighter highlight pixels. Make the tongues fatter, with clearer colour bands. (3) The brief asked for tall tongues above, but the top tongues are short and spiky, about 10 to 12 px of the 24 px available. The side flames are only thin strips and the sparks are hard to see. Make the top tongues taller and more varied, give the sides a bit more body, and make the sparks clearer.
- Rules broken: 2, 5
- Refused: {"tool_input": {"content": "import sys\np = sys.argv[1]\ns = open(p, encoding=\"utf-8\").read()\na = s.index(\"TONGUE_GAP = \")\nb = s.index(\"def _clear(\")\nnew = '''def lick(s, a, t, frames, gap, hw, hmin, hmax, seed, sway, reach=None):\n    \"\"\"Heat of one edge's flames at coordinate s along the edge, a px out from the panel, frame t: tongues every\n    `gap` px that taper to a tip, sway and curl (the tip leans), swell and drop a whole number of times over the\n    loop (so it loops), and the tall ones shed a detached tip. Returns 0 outside every tongue, else 0.1 to 1.\"\"\"\n    ph = 2 * math.pi * t / frames\n    best = 0.0\n    for k in range(-1, int(FIRE_W / gap) + 2):\n        r = _hash(k, seed)\n        c = k * gap + gap / 2 + 3 * (r - 0.5)\n        tall = (k % 2 == 0)\n        lo, hi = (hmin, hmax) if tall else (hmin * 0.5, hmax * 0.45)\n        cyc = 1 + (k % 3 == 0) * (1 if not tall else 0)\n        H = lo + (hi - lo) * (0.5 + 0.5 * math.sin(cyc * ph + r * 6.283))\n        u = a / H\n        if u >= 1:\n            continue\n        if tall and H > 14 and 0.8 <= u < 0.87:\n            continue                                  # the tip detaches\n        cu = c + 2 * math.sin(ph + r * 6.283) + sway * math.sin(2 * ph + k) * u * u * hw * 0.5\n        half = hw * (1 - u) ** 0.85 + 0.4\n        d = abs(s - cu) / half\n        if d >= 1:\n            continue\n        best = max(best, 1.0 - 0.62 * u - 0.30 * d ** 1.5)\n    return best\n\n\ndef fire_heat(x, y, t, frames=FIRE_FRAMES):\n    \"\"\"Heat at a pixel in frame t, 0 where there is no flame: tall tongues above (curling, with detached tips),\n    short flames on the sides, a very low rim below. The last frame runs into the first.\"\"\"\n    above, below = PANEL_Y - y, y - (PANEL_Y + PANEL_H - 1)\n    if x < PANEL_X or x >= PANEL_X + PANEL_W:\n        dx = PANEL_X - x if x < PANEL_X else x - (PANEL_X + PANEL_W - 1)\n    else:\n        dx = 0\n    h = 0.0\n    if above >= 0:\n        h = max(h, lick(x, above, t, frames, 12, 6.5, 8, 21, 7, 1.0))\n        if above < 3:\n            h = max(h, 0.95 - 0.12 * above)             # the base the tongues grow from\n    if dx > 0 and above < 0 and below <= 0:\n        sy_ = y - PANEL_Y\n        sd = lick(sy_ + (40 if x > PANEL_X else 0), dx, t, frames, 9, 3.5, 4, 9, 23 + (x > PANEL_X), 0.6)\n        h = max(h, sd)\n        if dx < 2:\n            h = max(h, 0.9 - 0.15 * dx)\n    if below > 0:\n        h = max(h, lick(x, below - 1, t, frames, 10, 3.5, 1, 4, 31, 0.0))\n    return h\n\n\n'''\ns = s[:a] + new + s[b:]\ns = s.replace(\"if h > 0.42 and not _clear(x, y):\", \"if h > 0 and not _clear(x, y):\")\ns = s.replace(\"FIRE[0] if h > 0.86 else FIRE[1] if h > 0.72 else FIRE[2] if h > 0.57 else FIRE[3])\",\n              \"FIRE[0] if h > 0.84 else FIRE[1] if h > 0.66 else FIRE[2] if h > 0.48 else FIRE[3])\")\nopen(p, \"w\", encoding=\"utf-8\").write(s)\n", "file_path": "C:\\Users\\andre\\AppData\\Local\\Temp\\patch_fire_v3.py"}, "tool_name": "Write", "tool_use_id": "toolu_015aujTKH2MLV45uz31SbxB7"}; {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-339/style-loop/v3.png').convert('RGBA')\nbg=Image.new('RGBA',(136*4*4,64*4),(20,20,40,255))\nfor i,t in enumerate((0,3,6,9)):\n    f=im.crop((t*136,0,t*136+136,64)).resize((544,256),0)\n    bg.alpha_composite(f,(i*544,0))\nbg.save('art-archive/T-339/style-loop/v3-preview.png')\""}, "tool_name": "Bash", "tool_use_id": "toolu_014WWPce7eAanRoPHbP7XD3j"}

#### Round 4

- Version 4: `art-archive/T-339/style-loop/v4.png`
- What changed: Version 4, made by the script only, with no PixelLab generations. All 12 script tests pass.

The changes are all in `game/tools/build_hud_livestream_art.py`:
- **Top tongues:** fatter and taller. They are 16 px apart and 8 px wide at the base, with less taper. The tall ones reach up to 23 px and vary in height, and the short ones sit between them. Tall tongues still shed a detached tip.
- **Side flames:** more body, 5 px wide and 6 to 12 px long.
- **Shading:** the heat falls off more gently, so the white-hot core and yellow band are wider. Each tongue runs from white-hot at the base to an orange tip.
- **Glow:** the glow now has three steps outside the flame: the solid dark red-brown edge ring, an orange checkerboard halo, and a sparse dark red-brown halo further out. All are hard pixels, with no blur.
- **Sparks:** clearer. They are 2x2 or 2x1 px clusters that rise and drift sideways.
- **Unchanged:** the panel stays clear apart from the 2 px lick over its top edge, the corners stay transparent, and the 12-frame loop is exact.

The top tongues still look about 10 to 12 px tall in the sheet. I tried to measure their height, but that command was refused, so I couldn't check it. I also didn't check the PNG's 8-bit RGBA mode.
- Script checks: 61 of 61 pass
- Score: 6/10
- Reason: Rules 1, 3 and 6 pass by the script checks: 5 colours, opaque, no Greenbull colours. The palette matches the likes-bar fire, and the dark red-brown edge keeps the flames readable.

Rule 2 (shading and detail) is weak. The flames are a thin band, about 8-10 px tall on top. They are not the 'tall tongues' the brief asks for. The shading is only a few stripes, with little gradation from white-hot base to orange tips and no highlight pixels breaking the outline. The side flames are barely flames: they read as a wavy vertical strip beside each panel edge, not short licking flames. The bottom is a thin line. To fix this, make the top tongues taller and more varied in height and shape, and give the sides distinct short flames. Add an inner white-hot and yellow core with orange at the tips, so the shading reads clearly.

Rule 5 (drawn glow) is mostly missing. There is no stepped halo of darker shades around the flames, and the sparks are few and tiny. To fix this, add a 1-2 px stepped dark-orange halo inside the sprite, plus a few more visible sparks that drift up between frames.

Rule 4 (night and retro) is fine otherwise.
- Rules broken: 2, 5
- Refused: {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-339/style-loop/v4.png').convert('RGBA')\nfor t in (0,4,8):\n    f=im.crop((t*136,0,t*136+136,64))\n    ys=[y for y in range(64) for x in range(136) if f.getpixel((x,y))[3] and f.getpixel((x,y))[:3]!=(150,44,10)]\n    print(t,min(ys))\nprint(im.mode,im.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01LFLsqBm9ZtbH9ZECTQHGiD"}

**Kept:** version 1, score 7/10 (`art-archive/T-339/style-loop/v1-5.png`, copied to `game/art/hud/viewers_fire.png`): still below 8 after 3 refines, so the task is flagged for the board's review.

### Run 6

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/subgoal_frame.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-6.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: The frame follows the brief and breaks no rule clearly. It is a dark outer outline, a 2 px white ring shaded blue-grey on the bottom and right, an inner dark line, and a flat black inside with rounded inner corners. The script checks pass: 64x64, transparent corners, no semi-transparent pixels, 7 colours, and no Greenbull green or yellow (rules 1, 3, 6). The white ring reads against the dark night street, and the flat black inside matches what the board asked for (rule 4). The one weak spot is rule 2. The outline is a uniform dark line with no lighter highlight pixels breaking it, and the shading is only the blue-grey step on the ring. The image I saw is very small, so I may be missing detail. To fix it, add a few lighter highlight pixels on the ring's top-left edge and corners, or one more shade step, while keeping the black inside flat. The score is not higher because of this.
- Rules broken: 2
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-339/style-loop && ls art-archive/T-339/style-loop; [ -e art-archive/T-339/style-loop/v1-6.png ] && echo EXISTS; python game/tools/build_hud_livestream_art.py subgoal-frame --out art-archive/T-339/style-loop/v1-6.png && python -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-339/style-loop/v1-6.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01CoZDRAcTeRgArgPU3jTEGL"}

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1-6.png`, copied to `game/art/hud/subgoal_frame.png`): it reached 8 or more.

### Run 7

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/heart_full.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-7.png`
- Script checks: 5 of 5 pass
- Score: 8/10
- Reason: The image is tiny, so I judged it at that size. It reads as a heart straight away. It has a thick near-black outline, a heart-red fill, a darker red on the lower right and a light glint on the upper-left lobe. The script checks pass: 5 colours, no semi-transparent pixels, a transparent background, and none of Greenbull's colours (rule 6). The fill and outline are clearly apart, so the empty heart can be made from it by script. It reads over a dark night street (rule 4). Rule 3's isometric and 32 px/unit requirements don't apply to HUD art. Rule 2 asks for detailed shading, and this has only a few shade steps (5 colours in total). A small gain would be one more mid-shade step on the lobes and a lighter highlight pixel breaking the outline at the glint, but nothing here breaks a rule.
- Rules broken: none
- Refused: {"tool_input": {"command": "cd /c/solid-carbide-worktrees/T-339; grep -n -i -A40 \"planned calls\" tasks/T-339-art-the-livestream-hud.md | head -80; ls art-archive/T-339 art-archive/T-339/style-loop art-archive/T-339/pixellab 2>&1 | head -30; sed -n 1,60p game/tools/build_hud_livestream_art.py"}, "tool_name": "Bash", "tool_use_id": "toolu_0111vahhC4e8p781ehAfYenJ"}; {"tool_input": {"command": "mkdir -p art-archive/T-339/pixellab; python game/tools/build_hud_livestream_art.py heart --out art-archive/T-339/pixellab/heart_full_script.png && python game/tools/build_hud_livestream_art.py contact --out art-archive/T-339/pixellab/heart_full_compare_v1.png art-archive/T-339/pixellab/heart_full_script.png game/art/hud/likes_heart.png; python -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-339/pixellab/heart_full_script.png');print(i.mode,i.size,len(i.getcolors()))\""}, "tool_name": "Bash", "tool_use_id": "toolu_01DFc5HFegXt4JrSoBZPtcEZ"}; {"tool_input": {"command": "python -I -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-339/style-loop/v1-7.png');print(i.mode,i.size,sorted(set(i.getdata())))\""}, "tool_name": "Bash", "tool_use_id": "toolu_01GyASddp4yURDCzrATVAmPF"}

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1-7.png`, copied to `game/art/hud/heart_full.png`): it reached 8 or more.

### Run 8

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/heart_empty.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-8.png`
- Script checks: 5 of 5 pass
- Score: 8/10
- Reason: The image is very small, so this is a judgement of the overall look. It is a clean heart silhouette in a dark slate ramp, with a near-black outline and a lighter highlight at the upper left. It matches the full heart's shape and size, so the two read as a pair. The script checks pass: hard edges, a transparent background, 5 colours, and none of Greenbull's colours (rules 1 and 6). It keeps the night, retro HUD look (rule 4). No rule is clearly broken. One minor risk for rule 4 (reading over the dark street) and rule 2: the slate body and the (8, 8, 15) outline are both dark, so the outline may merge into the body or the street. The outline is unlikely to be distinct from the street unless the slate ramp is a bit lighter. If the board finds it too dim in the playtest, lift the mid and highlight slate a step or two. Otherwise nothing needs fixing.
- Rules broken: none
- Refused: {"tool_input": {"command": "mkdir -p art-archive/T-339/style-loop && ls art-archive/T-339/style-loop; python game/tools/build_hud_livestream_art.py heart-empty --from game/art/hud/heart_full.png --out art-archive/T-339/style-loop/v1-8.png && python -c \"from PIL import Image;i=Image.open('art-archive/T-339/style-loop/v1-8.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01FUJpDeys21gybdWdPoQc8F"}

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1-8.png`, copied to `game/art/hud/heart_empty.png`): it reached 8 or more.

### Run 9

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/eye_icon.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-9.png`
- Script checks: 5 of 5 pass
- Score: 8/10
- Reason: The icon is a roughly 16x11 cyan eye with a thick near-black outline, a dark iris ring, a black pupil and a white catchlight. It reads as an eye at a glance. The script checks pass: 6 colours, no semi-transparent pixels, a transparent background, and no Greenbull green or yellow (rules 1 and 6). The cyan leads and it should read over the dark night street (rule 4). Rules 3, 5, 7, 8, 9 and 10 don't apply to HUD art, and nothing in it breaks them. The image is very small, so I could not confirm every pixel. Two points to check: whether the eye's cyan shading (lighter and darker cyan) is visible enough, and whether the 1 px outline is thick enough to read as the HUD's thick dark outline (rule 2). If the lower lid and the iris/pupil area are flat, add a darker cyan on the bottom lid edge and a lighter cyan highlight on the top lid. No rule is clearly broken.
- Rules broken: none
- Refused: {"tool_input": {"command": "P=art-archive/T-339/pixellab && S=game/tools/build_hud_livestream_art.py && python $S eye --out $P/eye_icon_script.png && python $S post $P/eye_icon_script.png --size 32x32 --out $P/eye_icon_init.png && python -c \"\nfrom PIL import Image\ni=Image.open('$P/eye_icon_script.png');print(i.mode,i.size)\" && python $S request --description \"tiny pixel art eye icon, small and centred with empty space around, cyan eye shape, dark iris ring, black pupil, white catchlight, thick dark outline, flat transparent background\" --size 32x32 --init $P/eye_icon_init.png --init-strength 700 --out $P/req_eye_icon_c1.json && python game/tools/pixellab_client.py generate --endpoint create-image-pixflux --params-file $P/req_eye_icon_c1.json --out-dir $P --name eye_icon_c1 --consulted docs/visual-style.md --consulted docs/hud-and-menus.md --consulted docs/extended-narrative.md --task T-339 --notes \"eye icon candidate 1, script eye as init\" 2>&1 | tail -5"}, "tool_name": "Bash", "tool_use_id": "toolu_01X4c3fpMRGEPGec5TAXm5ax"}; {"tool_input": {"command": "cp art-archive/T-339/pixellab/eye_icon_script.png art-archive/T-339/style-loop/v1-9.png && python -I -c \"\nfrom PIL import Image\ni=Image.open('art-archive/T-339/style-loop/v1-9.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_01NCh7Xg2f6uPGxaGxoTwvwj"}; {"tool_input": {"command": "cp -n art-archive/T-339/pixellab/eye_icon_script.png art-archive/T-339/style-loop/v1-9.png"}, "tool_name": "Bash", "tool_use_id": "toolu_01EPa7A6DHgNpneWx1U8VWdV"}

**Kept:** version 1, score 8/10 (`art-archive/T-339/style-loop/v1-9.png`, copied to `game/art/hud/eye_icon.png`): it reached 8 or more.

### Run 10

Run by `tools/style_loop/run.py` on 2026-10-27: art, brief `art-archive/T-339/briefs/subs_icon.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

#### Round 1

- Version 1: `art-archive/T-339/style-loop/v1-10.png`
- Script checks: 5 of 5 pass
- Score: 7/10
- Reason: The image is only about 18 px wide and I could not enlarge it, so this is a judgement from a small view. It reads as a pale grey head and shoulders with a round hot pink badge at the lower right. Script checks pass: 8 colours, a transparent background, no semi-transparent pixels, and no Greenbull colours (rules 1 and 6). The pink is the game's effect colour and stays clear of cyan and green (rule 4 and the brief). The icon should read over a dark night street.

Weak points, all minor:
- Rule 2: the dark outline looks thin, and the head and shoulders show little shading (at most a couple of grey tones). Add a visible highlight pixel or two on the head and shoulder, and a darker shade on the lower and side faces. Make sure the 1 px outline in (8, 8, 15) is continuous around the person and the badge.
- The white plus inside the badge is only a few pixels and could be lost at 2x. Check that it is a clear, symmetric plus with the pink around it.
- The person's silhouette (shoulders against the head) is fairly generic. It could be made a little clearer.

No rule is clearly broken: the rule 2 detail is thin but not absent, so I am listing it as the one to fix.
- Rules broken: 2
- Refused: {"tool_input": {"command": "cd /c/solid-carbide-worktrees/T-339; sed -n 1,200p tasks/T-339-art-the-livestream-hud.md | head -150; grep -n \"subs\\|def \\|^usage\\|argparse\" game/tools/build_hud_livestream_art.py | head -80; ls art-archive/T-339 art-archive/T-339/* | head -50"}, "tool_name": "Bash", "tool_use_id": "toolu_015zMiuiUHx6oPK1XpQ6fMxk"}; {"tool_input": {"command": "cd art-archive/T-339/pixellab 2>/dev/null; cd /c/solid-carbide-worktrees/T-339 2>/dev/null; python game/tools/build_hud_livestream_art.py subs --out art-archive/T-339/pixellab/subs_icon_script.png && python game/tools/build_hud_livestream_art.py post art-archive/T-339/pixellab/subs_icon_script.png --size 32x32 --out art-archive/T-339/pixellab/subs_icon_init.png && python game/tools/build_hud_livestream_art.py contact --out art-archive/T-339/pixellab/subs_icon_compare_v0.png art-archive/T-339/pixellab/subs_icon_script.png --scale 12; cat art-archive/T-339/briefs/subs_icon.md | head -30"}, "tool_name": "Bash", "tool_use_id": "toolu_01LrBfDwhVXF268D7gUXzKJe"}; {"tool_input": {"command": "cp art-archive/T-339/pixellab/subs_icon_script.png art-archive/T-339/style-loop/v1-10.png && python -c \"from PIL import Image;i=Image.open('art-archive/T-339/style-loop/v1-10.png');print(i.mode,i.size)\""}, "tool_name": "Bash", "tool_use_id": "toolu_0196UpoPBzshtYfUQaUDYoYs"}

#### Round 2

- Version 2: `art-archive/T-339/style-loop/v2-3.png`
- What changed: Version 2 is a free script fix (`subs_icon()` in `build_hud_livestream_art.py`) with no PixelLab call. The icon is still 18x18 RGBA. The pink badge, white plus and 1 px outline in (8, 8, 15) are unchanged, and the outline is continuous around the person and the badge. I added shading, which was the rule 2 gap. The head now has a white highlight at the upper left, then light, mid and shaded tones towards the lower right. The shoulders have a white highlight pixel, a light left, a mid centre, a shaded right edge and a dark underside. I added a short 5 px neck so the silhouette reads as a head on shoulders instead of one blob. My first attempt had a 2 px neck that looked like a pin, so I shortened it. I overwrote my own unsubmitted draft at `v2-3.png` with `--force` for that. The earlier versions, including `v1-10.png`, are untouched. The 12 tests in `test_build_hud_livestream_art.py` pass. PixelLab spend stays at 1 of the 6 generations. The comparison is `art-archive/T-339/pixellab/subs_icon_compare_v2b.png`.
- Script checks: 5 of 5 pass
- Score: 7/10
- Reason: The image is very small (about 18 px), so this judgment is limited. It matches the brief: a pale grey head and shoulders with shading, a hot pink round badge with a white plus at the lower right, and a dark outline. It uses 9 colours, hard edges and a transparent background, and the script checks for rules 1 and 6 pass. No Greenbull green or yellow appears. The pink and grey read over a night street, so rule 4 is fine. Rules 3, 5, 7, 8, 9 and 10 do not apply to HUD art.

Rule 2 is the weak spot. The outline is thin, and the grey figure has little shading and few highlight pixels, so the head and shoulders read as a flat blob. The badge's plus is small and may not read at 1x. To improve it, add one or two lighter highlight pixels on the head and shoulder edges, add a darker shade on the lower and right side of the figure, and make the white plus a clear 3 px cross inside the pink disc with a closed dark ring around the badge.
- Rules broken: 2
- Refused: {"tool_input": {"command": "python - <<'E'\np='game/tools/build_hud_livestream_art.py'\ns=open(p,encoding='utf-8').read()\na=s.index(\"    for (x, y) in body:\\n        lit = (x + y) < 13\")\nb=s.index(\"    for (x, y) in badge:                               # a dark gap\")\nnew='''    for (x, y) in list(body):                          # neck, so the head and shoulders read as a person\n        pass\n    for y in (8, 9):\n        for x in (6, 7, 8):\n            body.add((x, y))\n    HI, LIT, MID, SH, DK = (255, 255, 255), (232, 237, 247), (182, 190, 208), (136, 145, 168), (96, 104, 128)\n    for (x, y) in body:\n        if y < 8:                                      # head: highlight top-left, light, mid, shade lower right\n            d = (x - hx) + (y - hy)\n            c = HI if (x, y) in ((5, 3), (6, 2)) else LIT if d < 0.5 else MID if d < 2.5 else SH\n        elif y < 10:                                   # neck sits in the head's shadow\n            c = SH if x >= 7 else MID\n        else:                                          # shoulders: lit left, mid centre, shaded right, dark underside\n            c = HI if (x, y) == (3, 11) else LIT if x < 6 else MID if x < 9 else SH\n            if (x + 1, y) not in body:\n                c = SH\n            if (x, y + 1) not in body and y >= 14:\n                c = DK if x >= 6 else SH\n        put(im, x, y, c)\n'''\ns=s[:a]+new+s[b:]\nopen(p,'w',encoding='utf-8').write(s)\nE\npython game/tools/build_hud_livestream_art.py subs --out art-archive/T-339/style-loop/v2-3.png && python game/tools/build_hud_livestream_art.py contact --out art-archive/T-339/pixellab/subs_icon_compare_v2.png art-archive/T-339/style-loop/v1-10.png art-archive/T-339/style-loop/v2-3.png --scale 12"}, "tool_name": "Bash", "tool_use_id": "toolu_01D1xXdJKuA1F5kkcinM2FpV"}

#### Round 3

- Version 3: `art-archive/T-339/style-loop/v3-2.png`
- What changed: Version 3 is a free script redraw (`subs_icon()` in `build_hud_livestream_art.py`) with no PixelLab call. The icon goes from 18x18 to 22x22, the brief's maximum, to give the shading and the plus more pixels. The old draw is kept in the script as `subs_icon_v2`, and the test now expects 22x22. All 12 tests pass.

- **Figure:** it has a larger head and wider shoulders. Shading is now five greys: white highlight pixels at the upper left of the head and shoulder, light, mid, shade, and a dark underside along the bottom. The right edge is shaded.
- **Neck:** it is a short 6 px neck.
- **Badge:** it is bigger, about 9 px across, in three pinks (light top, hot pink, dark lower rim). A closed dark ring separates it from the person.
- **Plus:** it is now a clear, symmetric 7 px white cross in the badge.
- **Outline:** the 1 px outline in (8, 8, 15) is continuous around the person and the badge.

The comparison with v2 is `art-archive/T-339/pixellab/subs_icon_compare_v3.png`. PixelLab spend stays at 1 of the 6 generations.
- Script checks: 5 of 5 pass
- Score: 8/10
- Reason: The image is very small, so this is a coarse read. It shows a pale grey head-and-shoulders figure with shading and a round hot pink badge at the lower right, in a dark outline. That matches the brief. Rule 1 passes by the script (10 colours, hard alpha, transparent corners). Rule 6 passes: there is no Greenbull green or yellow, and the pink keeps clear of the viewers' cyan. Rule 4 holds: the pale grey and pink read over a dark night street. Rule 2: the outline and shading are present, but the highlights on the head and shoulders are minimal. A few more lighter highlight pixels breaking the outline would lift it. Check that the white plus in the badge stays crisp and readable at 2x. Rules 3, 5 and 7–10 do not apply to this HUD icon, and nothing in it breaks them (no words or brands).
- Rules broken: none

**Kept:** version 3, score 8/10 (`art-archive/T-339/style-loop/v3-2.png`, copied to `game/art/hud/subs_icon.png`): it reached 8 or more.

### QA (round 1)

qa_check: tests PASS (3 sets), documents PASS, screenshots PASS (3). All 5 criteria pass; the fire (7/10) is for the board's morning playtest.

## Result notes

Written by the agent when it finishes.

### Planned PixelLab calls and cost (written before any call, 2026-10-27)

State before starting: a first session was cut off by a usage limit before it made anything; it made no PixelLab call (0 T-339 lines in `game/art/pixellab-generation-log.jsonl`) and no file. Balance at the start: 4,771 of 5,000 generations.

Every piece is HUD art shown at 2x (one art pixel is two screen pixels, like the likes heart), sized from the board's layout page (1152 x 648 game pixels). One style loop run per asset (`tools/style_loop/run.py art`), run one after the other so the Style review records don't clash. HTTP timeout 600 s (the client's default).

| Asset | Size (art px) | How | PixelLab, at most |
|---|---|---|---|
| Clock digits 0-9, colon, unlit 8 | 12 frames of 16 x 26 | script (greyscale, for tinting) | 0 |
| Clock panel | 100 x 36 | script | 3 (only if a refine can't be fixed by script, 1 per refine) |
| Viewers panel | 120 x 36 | script | 3 (same) |
| LIVE badge | 34 x 13 | script (pixel letters must be exact) | 0 |
| Viewers fire | 12 frames of 136 x 64 | script, the burning likes bar's colours, loops | 0 |
| Sub goal frame | 64 x 64 | script | 3 (same as the panels) |
| Full heart | about 18 x 16 | PixelLab `create-image-pixflux`: up to 3 candidates for version 1, 1 per refine | 6 |
| Empty heart | same as the full heart | script, from the kept full heart (always a matching pair) | 0 |
| Eye icon | about 16 x 11 | PixelLab pixflux: up to 3 candidates, 1 per refine | 6 |
| Subs icon (proposal: a subscriber, a person with a pink plus badge, instead of the star) | about 18 x 18 | PixelLab pixflux: up to 3 candidates, 1 per refine | 6 |

Most it can cost: 27 generations, under the cap of 40. Script work comes first: the digits, badge and fire are drawn by script because a script draws them exactly (segment digits that tint cleanly, readable letters, a fire that loops and matches the likes bar's). The script versions of the heart, eye and subs icon (`game/tools/build_hud_livestream_art.py`) are kept as a free fallback and as the comparison for the PixelLab candidates.
- 2026-10-27, in-progress → flagged-for-review: the style loop kept version 1 (score 7/10), still below 8 after 3 refines; every version is in its Style review

### Result (asset-generation, 2026-10-28)

**PixelLab generations used: 2 of 40** (`eye_icon_c1`, `subs_icon_c1`, both `create-image-pixflux` 32 x 32, 1 generation each, logged in `game/art/pixellab-generation-log.jsonl`; neither was kept). Balance before: 4,771. The style loop's generator chose the script version for every asset; it made no PixelLab candidate for the heart, although the brief allowed up to 3.

**Assets, one style loop run each (all rounds in the Style review):**

| Asset (`game/art/hud/`) | Size | Made by | Rounds (scores) | Kept |
|---|---|---|---|---|
| `clock_digits.png` (+ `clock_digit_0` ... `_9`, `_colon`, `_off`) | 12 x 16 x 26 | script | 8 | v1, 8 |
| `clock_panel.png` | 100 x 36 | script | 8 | v1, 8 |
| `viewers_panel.png` | 120 x 36 | script | 8 | v1, 8 |
| `live_badge.png` | 34 x 13 | script | 7, 8 | v2, 8 |
| `viewers_fire.png` (+ `viewers_fire_00` ... `_11`) | 12 x 136 x 64 | script | 7, 6, 7, 6 | **v1, 7: below 8 after 3 refines, the loop flagged the ticket** |
| `subgoal_frame.png` | 64 x 64 | script | 8 | v1, 8 |
| `heart_full.png` | 18 x 16 | script | 8 | v1, 8 |
| `heart_empty.png` | 18 x 16 | script, from the kept full heart | 8 | v1, 8 |
| `eye_icon.png` | 16 x 11 | script (1 PixelLab candidate not kept) | 8 | v1, 8 |
| `subs_icon.png` (proposal instead of the star: a subscriber with a pink plus badge) | 22 x 22 | script (1 PixelLab candidate not kept) | 7, 7, 8 | v3, 8 |

Every PNG in `game/art/hud/` has a json record beside it (35 PNGs, 35 records; written by `game/tools/write_hud_livestream_records.py`): what it is, size, how it was made, the style loop version, score and brief, the PixelLab candidates not kept, the resources consulted. Every version and candidate is kept: `art-archive/T-339/style-loop/`, `art-archive/T-339/pixellab/`, briefs in `art-archive/T-339/briefs/`.

**Contact sheet:** `art-archive/T-339/contact_sheet.png` (every asset at 6x on dark and light). **Screenshots** (nothing is in a scene yet; the HUD tickets T-335 to T-338 place the art): `art-archive/T-339/screenshots/contact_sheet.png`, `hud_pieces_mockup_x3.png` (the kept files composed at 3x over a night colour, the digits tinted green), `viewers_fire_x4.gif` (the fire loop on the viewers panel).

**Code:** `game/tools/build_hud_livestream_art.py` (draws every piece, post-processes PixelLab raws, writes pixflux requests, splits sheets, contact sheets; it redraws every kept file pixel for pixel; the fire's refines 2 to 4 are kept in it as `fire_frame_v4`), `game/tools/write_hud_livestream_records.py`; tests `game/tools/test_build_hud_livestream_art.py` and `test_write_hud_livestream_records.py` (both pass). The full Python tool suite and the GUT suite were started but the runs were stopped by the board's pause; they were not completed in this session.

**Documents:** Visual style, Decisions, "The livestream HUD art"; `game/README.md`, "Livestream HUD art (T-339)".

**Honest quality notes, for the board:**
- The fire (7/10) is the weak piece: thin, jagged tongues and little glow; the evaluator wanted fatter tongues with clearer colour bands. Cheapest next step: the board looks at the GIF; if it is not enough, a short ticket for a PixelLab `animate-with-text` fire (a few generations remain in this go).
- The heart reads as a heart but its top dip between the lobes is shallow, and the kept subs icon is chunky (a "pawn" figure); the unused PixelLab subs candidate (`art-archive/T-339/pixellab/subs_icon_c1_post.png`) is arguably nicer. The evaluator judged these tiny images at their own size (it could not enlarge them), so its 8s are coarse.
- The board asked for PixelLab art ("don't be stingy"); the loop's generator kept script art and used only 2 generations. 38 generations of the go are unused.
- The clock's green tint is the UI ticket's: the mock-up used 69, 224, 90, which is clear of Greenbull's light green by the script check (distance about 36).

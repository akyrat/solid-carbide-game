---
id: T-294
title: "Art: Greenbull's emblem, a bull's head, through the style loop"
status: in-progress
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, agent-notes/asset-generation.md, tasks/T-075-redgull-logo-art.md, game/art/logo/redgull_logo_128.png, game/art/car/car_iso.png]
files_expected_to_change: [art-archive/T-294/, docs/visual-style.md]
model: opus
qa_rounds: 1
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

The board's rebrand (2026-10-26; Visual style, Decisions, "The rebrand" and "Greenbull's look"): the sponsor Redgull becomes **Greenbull**, one word. This task makes Greenbull's **emblem**: the logo without words, a **bull's head**. It replaces Redgull's seagull head (T-075). The wordmark, the emblem with the name GREENBULL, is T-295 and is built from this emblem.

**The emblem, in the board's words:** "a head of a bull or something, you know, like a cool logo", and "don't make it look like the real, like the Red Bull logo". So it is a bold, cool bull's head with horns, as a brand emblem. It is never two charging bulls, never a sun disc behind it, never a whole bull: the head only, and its own design.

**Colours:** Greenbull's three brand colours (Visual style, Content, "Rules", rule 6): **dark green RGB 12, 76, 44 leads** (most of the emblem), **light green RGB 104, 220, 96** supports it (highlights, shapes), and **yellow RGB 247, 208, 52 only as a small accent** (for example the eyes, or the horn tips): "don't use yellow too much". A dark outline is allowed and expected so it reads at small sizes. The final emblem uses the brand colours plus the outline (and a darker green shade if the design needs one): it is flat brand art, exempt from rule 2's shading and detail, but it follows rule 1 (transparent background, hard edges, no semi-transparent pixels). Remapping the generated colours to the exact brand values is a free script step.

**Sizes:** 128 x 128 is the master; 64 x 64 and 32 x 32 versions are made from it by script, as T-075 did (`game/tools/make_logo_sizes.py`, adapted or reused), and checked by eye that they still read as a bull's head at 32.

**How:** through the style loop only. The board's go (2026-10-26): **up to 12 PixelLab generations for this asset**, "stop being so stingy … just get the work done well". The loop does at most 4 generations per run (1 plus 3 refines); if a run ends below 8, the Project Lead may start up to two more runs of the loop on this task, each with a brief improved from the previous run's reasons, so the asset gets up to 12 generations in all. Free script fixes come before paid regenerations. Write the planned calls and their cost in the result notes before calling. Every version stays in `art-archive/T-294/` (the loop keeps them in `style-loop/`); nothing is deleted.

The Project Lead starts the loop: `python tools/style_loop/run.py art --task T-294 --brief art-archive/T-294/brief.md --out art-archive/T-294/greenbull_emblem_128.png --size 128x128`. The kept emblem stays in `art-archive/T-294/` until the board approves it; the game swaps it in later in the rebrand goal (the old Redgull logo files stay in `game/art/logo/` until then).

This task's Style review is also Example 2 of the board's course assignment (`course-material/style-guide-agent/README.md`), so every round must be clear to an outside reader.

The board's review: look at the kept emblem at 128, 64 and 32, enlarged with nearest-neighbour, on a dark and a light background, next to the old Redgull logo and the car; read the Style review to see how the loop got there.
Board review files: art-archive/T-294/review_emblem_dark.png, art-archive/T-294/review_emblem_light.png

## Acceptance criteria

- [ ] The task's `## Style review` section holds every round of every loop run: each version's file, the script checks, the score, the reason and (from round 2) what changed, and a "Kept" line per run. (QA: fail, run 1 round and Kept line missing)
- [x] Every version is in `art-archive/T-294/style-loop/` with its PixelLab record, and the kept emblem is `art-archive/T-294/greenbull_emblem_128.png`, with `greenbull_emblem_64.png` and `greenbull_emblem_32.png` beside it. (QA: pass)
- [x] `python game/tools/style_rules.py art art-archive/T-294/greenbull_emblem_128.png --size 128x128` passes, or its failures are named in the Style review. (QA: pass)
- [x] The kept emblem's colours are the three brand colours (RGB 12, 76, 44; 104, 220, 96; 247, 208, 52) plus at most two dark outline or shade colours, as a short script listing its colours shows; yellow covers fewer opaque pixels than either green. (QA: pass)
- [x] At most 12 PixelLab generations were used, as `game/art/pixellab-generation-log.jsonl` shows for T-294. (QA: pass)
- [x] The two review images exist: the emblem at 128, 64 and 32 next to the old Redgull logo and a car frame, enlarged with nearest-neighbour, on a dark and a light background. (QA: pass)
- [x] Nothing under `game/art/` changed except the PixelLab log. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, In progress → In QA

Emblem made: the loop ran twice, both kept at 8/10 on their first version (2 of 12 PixelLab generations). Run 2 (angular, lightning blaze) is the Project Lead's pick; run 1 is kept for comparison. 64 and 32 px made by script. Review: art-archive/T-294/review_emblem_dark.png and _light.png. Now in QA.

## Style review

The loop ran twice on this asset (the board's go of up to 12 generations allows up to three runs). The tool sets this whole section on each run, so run 2 replaced run 1's record; the Project Lead restored run 1 below, word for word from the loop's own output read before run 2 started, except its list of refused commands (five read-only checks of the loop's environment variable, an old request's parameters and the agent notes), which was not kept.

### Run 1, round 1 (restored)

Run by `tools/style_loop/run.py` on 2026-10-26: art, brief `art-archive/T-294/brief.md`. Generator: asset-generation; evaluator: style-evaluator.

- Version 1: `art-archive/T-294/style-loop/v1.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: Rule 1 is met: the script checks pass (hard edges, 5 colours, transparent background, no semi-transparent pixels), and the image shows a clean pixel look with a dark near-black outline. Rule 6 is met: dark green leads on the head, light green is used for the horns and the inner face shape, and yellow is a small accent on the eyes and nose ring only. No Redgull red appears. Rule 9 is met: it is an original front-facing bull's head, with no real-brand look, no charging bulls, no sun or circle and no words. Rule 3: the size is 128x128. Rule 2's detailed shading doesn't apply to flat brand art. The head is symmetric, has thick horns and a clear muzzle with a ring, and should read at 32x32. I found no rule it breaks. Optional polish only: the horns reach close to the canvas sides, so check that they keep a margin, and the bright green inner face shape could be a little bolder. Neither point breaks a rule.
- Rules broken: none

**Kept (run 1):** version 1, score 8/10 (`art-archive/T-294/style-loop/v1.png`, then copied to `art-archive/T-294/greenbull_emblem_128.png`; now kept as `greenbull_emblem_128_run1.png`, since the Project Lead picked run 2). It passed, but the Project Lead judged it plain (a calm farm bull rather than "a cool logo") and ran the loop again with a bolder brief.

### Run 2

Run by `tools/style_loop/run.py` on 2026-10-26: art, brief `art-archive/T-294/brief_run2.md`. Generator: asset-generation (one session, resumed for each refine); evaluator: style-evaluator. Kept at 8/10 or more, at most 3 refines.

### Round 1

- Version 1: `art-archive/T-294/style-loop/v1-2.png`
- Script checks: 6 of 6 pass
- Score: 8/10
- Reason: No rule is clearly broken. It passes every script check: 128x128, a transparent background, 5 opaque colours, no semi-transparent pixels and no red. Rule 1 holds (hard edges, few colours). Rule 6 holds: dark green leads, light green is used for the lightning blaze and facets, and yellow appears only as small angry eyes. The dark outline reads on dark and light backgrounds. Rule 9 holds: it is an original bull head with angular horns, a V-shaped face and a furrowed brow, not the energy-drink logo, with no words or whole bull. Rule 2's detailed shading does not apply to flat brand art. I judged this by eye on a small render, so these are small improvements and not violations. (1) The horns are fairly thin and curve outward. They may thin out at 32x32, so thicken them and make the tips read clearly. (2) The lower muzzle is dark and a little muddy against the outline. Separate the nostrils and muzzle with one more light-green or mid-green edge so the snout stays clear at small size. (3) Check that margins on all sides are at least 4 px.
- Rules broken: none
- Refused: {"tool_input": {"command": "ls art-archive/T-294/ art-archive/T-294/style-loop/ && sed -n '/The style loop/,/^## /p' tasks/README.md | head -60 && ls game/tools/ tools/ | head -80", "description": "List archive and read style loop rules"}, "tool_name": "Bash", "tool_use_id": "toolu_019PWNyiwfgkBeVoqQEapLLu"}; {"tool_input": {"command": "python -c \"\nfrom PIL import Image\nim=Image.open('art-archive/T-294/style-loop/v1.png').convert('RGBA')\nprint(sorted(im.getcolors(9999),reverse=True))\"", "description": "List colours used in run 1's version"}, "tool_name": "Bash", "tool_use_id": "toolu_01EKwpFQu6t4tw6CqVuumWVC"}; {"tool_input": {"command": "cd /c/solid-carbide-worktrees/T-294/art-archive/T-294/style-loop && python draw_v1-2.py script_r2_a.png && python preview.py script_r2_a.png script_r2_a_preview.png", "description": "Draw the script shape and its preview"}, "tool_name": "Bash", "tool_use_id": "toolu_01RM3qLFaXzAwibQF8rM8o41"}; {"tool_input": {"command": "python art-archive/T-294/style-loop/draw_v1-2.py art-archive/T-294/style-loop/script_r2_a.png; python art-archive/T-294/style-loop/preview.py art-archive/T-294/style-loop/script_r2_a.png art-archive/T-294/style-loop/script_r2_a_preview.png", "description": "Draw the script shape and its preview"}, "tool_name": "PowerShell", "tool_use_id": "toolu_01RHFF4Sc1SCxVHZTfM76u9W"}; {"tool_input": {"command": "head -40 /c/solid-carbide-worktrees/T-294/game/tools/flatten_logo.py; head -30 /c/solid-carbide-worktrees/T-294/game/tools/draw_gull_silhouette.py", "description": "Read headers of old logo scripts"}, "tool_name": "Bash", "tool_use_id": "toolu_01Nn6CMjDWtPy3DkqeiLbady"}; {"tool_input": {"command": "$env:SOLID_CARBIDE_STYLE_LOOP_RUN; Test-Path .env", "description": "Check style loop marker and env file"}, "tool_name": "PowerShell", "tool_use_id": "toolu_013qrVs2yCbqZA1WiYbmT1LS"}

**Kept:** version 1, score 8/10 (`art-archive/T-294/style-loop/v1-2.png`, copied to `art-archive/T-294/greenbull_emblem_128_run2.png`): it reached 8 or more.

## Result notes

### Loop run 1, version 1 (Asset Generation Agent)

- Free first: `game/tools/draw_bull_emblem.py` draws a front-facing, symmetric bull's head by script in Greenbull's exact colours (dark green head, light green horns and angry brow chevron, yellow eyes, horn tips and nose ring, near-black 2 px outline, one deeper green for the muzzle line). Drafts `art-archive/T-294/style-loop/script_a.png`, `script_b.png`, `script_c.png` (c is the init).
- Planned paid call (1 generation, within the board's go of 12; this run's first of at most 4): `/create-image-pixflux` 128 x 128, `init_image` = `script_c.png`, `init_image_strength` 200, prompt "brand logo emblem, bull head, front view, symmetric, thick curved horns, angry slanted eyes, nose ring, bold flat shapes, dark green head, light green horns, black outline, flat vector-like pixel art icon", no_background, single color black outline, flat shading, low detail, text_guidance_scale 8, 600 s timeout. Then a free remap of every colour to the nearest brand colour / outline / deeper green, and hard alpha.
- Call made: 1 generation (usage 1.0; T-294 total 1 of 12). Raw `art-archive/T-294/style-loop/v1_raw_pixflux_s200.png` with its record `v1_raw_pixflux_s200.json`; request body `req_v1.json`. PixelLab kept the script shape and tidied it: the brow chevron and the forehead ridge joined into one bold Y, round nostrils, a cleaner nose ring.
- Free fix: `python game/tools/draw_bull_emblem.py art-archive/T-294/style-loop/v1.png --remap art-archive/T-294/style-loop/v1_raw_pixflux_s200.png` (alpha cut at 128, nearest of five colours). `v1_count_check.png` is an identical copy made while counting colours. Preview: `v1_pixflux_remapped_preview.png`.
- **Version 1:** `art-archive/T-294/style-loop/v1.png`, 128 x 128 RGBA. Colours: dark green 12,76,44 3322 px; light green 104,220,96 1852 px; outline 10,16,14 1379 px; yellow 247,208,52 361 px (eyes, horn tips, nose ring); deeper green 6,44,26 198 px (muzzle line). `style_rules.py art --size 128x128`: all checks pass (5 colours, 0 semi-transparent, transparent corners, no red).
- Tests: `python game/tools/test_draw_bull_emblem.py` 4 OK.
- My view: it reads clearly as a bull's head, also at 32 px; its own design (one head, no circle, no charging bulls). Weak spots: the horn tips at 32 px become thin; the yellow is in three places (eyes, tips, ring), which the evaluator may count as more than a small accent.

### Loop run 2 and the final sizes (Asset Generation Agent, 2026-10-26)

Run 2's notes are in `art-archive/T-294/style-loop/v1-2.md` (script `game/tools/greenbull_emblem.py`, request `game/tools/greenbull_emblem_request.py`). The Project Lead's pick, which the board may swap at review: **run 2 is the emblem**. This step was free script work only; no PixelLab calls.

- **Files** (nothing deleted): `art-archive/T-294/greenbull_emblem_128.png` is now run 2 (a copy of `style-loop/v1-2.png`, the same as `greenbull_emblem_128_run2.png`). Run 1 is kept as `greenbull_emblem_128_run1.png` (a copy of `style-loop/v1.png`). New: `greenbull_emblem_64.png`, `greenbull_emblem_32.png`, `review_emblem_dark.png`, `review_emblem_light.png`.
- **Small sizes, by script:** `python game/tools/make_emblem_sizes.py art-archive/T-294/greenbull_emblem_128.png art-archive/T-294` (new; T-075's `make_logo_sizes.py` handles a single-colour logo only, so this is an adapted multi-colour version). Each small pixel is opaque if at least half its source block is, and takes the block's most common colour, with yellow (x2 at 64, x3 at 32) and light green (x1.2 / x1.3) weighted up so the eyes, nose ring, blaze and horns survive. Then any transparent pixel next to a filled non-outline pixel becomes outline, so the silhouette keeps a closed dark edge: 0 pixels added at 64, 45 at 32 (a plain block vote opens gaps in the 2 px master outline). Only the master's colours, hard edges, no semi-transparent pixels.
- **Colour counts** (opaque pixels):
  - 128: dark green 12,76,44 1947; outline 14,22,18 1516; light green 104,220,96 1214; deeper green 6,46,26 910; yellow 247,208,52 154. Yellow is less than either green.
  - 64: dark green 459; outline 370; light green 339; deeper green 246; yellow 46.
  - 32: outline 128; dark green 120; light green 85; deeper green 56; yellow 16.
- **Checks:** `python game/tools/style_rules.py art <file> --size WxH` passes all 6 checks for the 128, 64 and 32 (5 colours, 0 semi-transparent, transparent corners, no red); run 1's 128 also still passes.
- **Review images:** `art-archive/T-294/review_emblem_dark.png` and `review_emblem_light.png` (`game/tools/review_sheet.py`, x3 nearest-neighbour; the tool has no labels). Left to right: run 2 at 128, 64, 32; run 1 at 128; the old Redgull logo `game/art/logo/redgull_logo_128.png`; car frame 0 of `game/art/car/car_iso.png`.
- **Tests:** new `game/tools/test_make_emblem_sizes.py` (4 tests: palette kept and hard alpha, small yellow survives at 32, the outline closing, bad sizes refused). `test_greenbull_emblem.py` already existed from the loop. `python -m unittest discover -s game/tools -p "test_*.py"`: 432 tests OK (1 skipped).
- **PixelLab generations used by T-294:** 2 of the board's 12 (`game/art/pixellab-generation-log.jsonl`: `v1_raw_pixflux_s200` in run 1, `v1-2_raw_pixflux_s120` in run 2). Nothing under `game/art/` changed except that log.
- **My honest view:**
  - Run 2 is the stronger brand mark: the angular face, lightning blaze, heavy brow and narrow yellow eyes look aggressive and logo-like, and it is clearly not the energy-drink logo. Yellow is used sparingly (eyes and nose ring). Weak spots: the lower muzzle is very dark (deeper green plus outline), so the nostrils are muddy, which the evaluator also noted; and on the dark background its near-black outline almost disappears, so the silhouette relies on the light green.
  - Run 1 is friendlier and simpler: a calm, rounder head with big light-green horns and yellow horn tips. It reads more clearly at a glance and stands out better on dark, but it looks more like a mascot than a cool sponsor logo, and spends more yellow (361 px, three places).
  - 64 px: holds up well; everything from the master survives (blaze, brow, eyes, nostrils, ring).
  - 32 px: still reads as a bull's head: two horns, ears, two yellow eyes under the brow, the light-green blaze as a vertical stripe (its zigzag is mostly lost) and the yellow ring at the bottom. The nostrils merge into one dark muzzle block and the horns are 1 to 2 px thick at the tips. Fine as an icon or a small decal; at that size it is the silhouette and yellow eyes that carry it.

## QA round 1 (2026-10-26)

- Style review section: FAIL. It holds only run 2 (Round 1, one Kept line). Run 1's round (version file, script checks, score, reason) and its Kept line are not on the ticket; the brief says both runs count.
- Files and archive: PASS. style-loop/ holds both versions with PixelLab JSON records; greenbull_emblem_128/64/32.png exist.
- style_rules.py 128x128: PASS (all 6 checks).
- Colours: PASS. 128/64/32 each have 5 opaque colours: the three brand colours plus outline 14,22,18 and deeper green 6,46,26. Yellow is 154/46/16 px, below both greens.
- Generations: PASS. 2 for T-294 in the log (max 12).
- Review images: PASS. Dark and light sheets show run 2 at 128/64/32, run 1, old Redgull logo and car, enlarged.
- Nothing under game/art changed except the log: PASS (only pixellab-generation-log.jsonl, +2 lines).
- Tools tests (game/tools discover): PASS, 432 tests OK (1 skipped).
- 2026-10-26, in-qa → in-progress: QA round 1: fails 1 criterion, run 1's Style review round and Kept line are missing from the ticket; the rest pass

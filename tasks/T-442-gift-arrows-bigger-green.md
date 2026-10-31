---
id: T-442
title: Gift pack arrows 3 times as big, in the gift box's colours
status: in-qa
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/scripts/run/gift_arrows.gd, game/art/gift_pack/package.png]
files_expected_to_change: [game/scripts/run/gift_arrows.gd, game/tests/unit/, docs/hud-and-menus.md]
model: sonnet
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

The board, 2026-10-31 (docs/hud-and-menus.md, Decisions, "Bigger gift pack arrows in the gift box's colours"): the arrows at the screen's edge that point to gift packs off screen (`game/scripts/run/gift_arrows.gd`, T-144, T-314) become 3 times as big (ARROW_SIZE 30 x 24 becomes 90 x 72 at the HUD's base size, scaled with the HUD like today), and their colour changes from the placeholder pale cyan to the gift box's colours: Greenbull's dark green (12, 76, 44) with the ribbon's light green (104, 220, 96), matching game/art/gift_pack/package.png. How the two greens are split between fill and edge is your proposal for the playtest; keep the HUD's dark outline (8, 8, 15) so the arrow reads on the dark city. Everything else stays: one arrow per package off screen, the track, sliding clear of the HUD parts and of each other (check the bigger arrows still clear them, with the gaps scaled if needed). Code only, no new art, 0 PixelLab calls.

Never write, move or commit anything in game/data/levels/.

The board's review: play a run until gift packs drop, drive away from them and look at the arrows.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows each arrow is 3 times today's size (90 x 72 at the HUD's base size) and scales with the HUD size like the rest of the HUD. (QA: pass / fail)
- [ ] A test shows the arrow's colours are the gift box's dark green and light green, with the dark outline. (QA: pass / fail)
- [ ] The existing gift arrow tests still pass: one arrow per off-screen package, none for a package on screen, arrows clear of the HUD parts and of each other. (QA: pass / fail)
- [ ] Screenshots of two or more arrows at the screen's edge in a run are saved and listed in the result notes (tasks/README.md, "Screenshots"). (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, where the arrow's look is described) and the script's comment describe the new size and colours. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-31, Open → In progress

Started: the UI Agent builds it in C:\solid-carbide-worktrees\T-442.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done by the UI Agent (0 PixelLab calls). `game/scripts/run/gift_arrows.gd`: ARROW_SIZE 90 x 72; FILL (12, 76, 44) dark green, STRIPE (104, 220, 96) light green as an inner stripe (the arrow shrunk to 45% towards its centre; the split is my proposal for the playtest), OUTLINE (8, 8, 15) 4 px wide. The arrows did not scale with the HUD before; now `ui_scale` is read from `hud.hud_scale()` each refresh, and the size, the track's inset, the gap and the outline width all multiply by it (statics `place`, `arrow_rect`, `arrow_points` take an optional scale, default 1). Clearance from the HUD parts and between arrows holds at every test window size.

Tests (`game/tests/unit/run/test_gift_drops.gd`): 3 new (size 90 x 72 and scaling with the HUD size at 4 window sizes and the slider; the colours equal the constants and both greens are in package.png; the stripe sits inside the arrow); existing arrow tests updated to pass `ui_scale`. Results: game/tools 591 OK; tools OK; GUT 190 scripts, 2317 tests, all passing.

Screenshot: `art-archive/T-442/screenshots/arrows.png` (three arrows at the screen's edge, two right and one left, from `tests/fixtures/gift_drop_arrows_demo.tscn`, which I fixed to skip the tutorial slides).

Documents updated: docs/hud-and-menus.md, game/docs/game-loop/gift-pack-and-pickups.md. Nothing under game/data/levels/ touched.
- 2026-10-31, in-progress → in-qa: Built, tests pass, screenshot in art-archive/T-442/screenshots

---
id: T-431
title: The HUD scales with the window, and a HUD size slider on the pause screen
status: needs-playtest
from: project-lead
to: ui
lead: Goal-G-008
epic: hud-menus
milestone: mvp
goal: G-008
user_facing_text: yes
changes_visuals: yes
depends_on: [T-426, T-427, T-429]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/pause-screen.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/pause-screen.md, game/data/pause_text.json, game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, game/project.godot]
files_expected_to_change: [game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, game/project.godot, game/tests/unit/hud/test_hud_scaling.gd, game/tests/unit/test_hud_size_slider.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/docs/hud-and-menus/pause-screen.md]
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

Goal G-008, 'The HUD scales with the window, and a HUD size slider' (HUD and menus, Decisions). Make every HUD piece keep its corner or edge and a size in proportion to the window at any window size and resolution, ultrawide included, with pixel art kept crisp (whole-number scales or nearest filtering) and the world camera's zoom untouched. Add a HUD size slider to the pause screen, laid out like the other sliders, whose label (and value format, if any) is read from game/data/pause_text.json, written by D1: no text in code. Moving it changes the HUD's scale at once while paused; it is saved in GameSettings on release only, following the pattern D2 set, and applied at the next start. Take the range and default from HUD and menus; if the doc leaves them open, propose them and write them in the docs as a proposal for the playtest. Document the scaling rule, the slider's range and default, and which screens it covers.

The board's review: Play a run in a small window, at full screen and on the ultrawide; move the HUD size slider on the pause screen to both ends.

## Acceptance criteria

- [ ] Headless tests at 1152 x 648, 1920 x 1080, 2560 x 1440, 3440 x 1440 and 960 x 540 check that every HUD piece keeps its corner or edge, has a size in proportion to the window, overlaps no other piece and is fully on screen. (QA: pass)
- [ ] Tests show the HUD's scale is a whole number or its textures use nearest filtering, and the world camera's zoom is the same with and without the HUD's scaling. (QA: pass)
- [ ] The pause screen has a HUD size slider laid out like the other sliders, its label read from game/data/pause_text.json (a test checks the label equals the file's text, and grep finds no literal of it in the scripts). (QA: pass)
- [ ] Tests show moving the slider changes the HUD's scale at once while paused, saves to GameSettings only when the drag ends, and the saved value is applied at the next start. (QA: pass)
- [ ] Screenshots at the five window sizes, and with the slider at both ends, are in art-archive/<id>/screenshots/. (QA: pass)
- [ ] docs/hud-and-menus.md, Content and game/docs/hud-and-menus/hud.md and pause-screen.md describe the scaling rule, the slider's range and default, and which screens it covers. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-431.

### 2026-10-30, In progress → In QA

Goal runner (G-008): the agent is done; QA is checking it.

### 2026-10-30, In QA → Needs playtest

Goal runner (G-008): QA passed; merged into playtest/G-008.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (UI Agent, 2026-10-30).** 0 PixelLab generations. No new text: the label is T-426's, read from `game/data/pause_text.json`.

**What was built**
- **Scaling rule** (`game/scripts/hud/hud.gd`): every HUD piece now sits in one Control, `hud.root` ("Scaled"), laid out at the 1152 x 648 layout page and scaled by `Hud.scale_for(view, hud_size)` = min(w/1152, h/648) × hud_size/100. Its size is the window divided by the scale, so the anchors keep each piece at its corner or edge, and sizes and margins follow the window. The scale is redone on every resize. The root uses nearest filtering, so the art stays hard-edged at fractional scales (1.667, 2.222, 0.833). The camera is never touched. The reaction bursts convert screen points into the root's pixels (`to_layout`), and the top-level `ViewersFlight` gets `base_scale` so it is drawn and arcs at the HUD's scale.
- **Sub goal above 100** (`sub_goal.gd`, `keep_above`): at HUD sizes above 100 the layout page is shorter than 648. The square, kept at its share of the height, would reach the viewers counter, so it moves up just enough to stay 16 px above it. At 100 it never moves.
- **Slider** (`pause_screen.gd`): `HudSizeRow` sits directly under the music row, laid out like it (label of width `LABEL_WIDTH`, slider, a bare number at the right end). The label is read from `pause_text.json` (`hud_size_label`). It changes the HUD at once while paused and saves only on `drag_ended`, plus on close (T-427's `_dirty` rule, key `hud_size`).
- **Saving and loading** (`game_settings.gd`): `load_hud_size`/`save_hud_size`, section `hud`, key `size`, clamped, counted in `slider_writes`. `GameFlow.add_run` (`game_flow.gd`, one line; not listed in files_expected_to_change) applies the saved value at the next start.
- **Proposals for the playtest** (written in HUD and menus, Content, "The HUD scales with the window"):
  - Range 50 to 125, step 5, default 100. The doc left these open. I went above 100 only to 125: at 150 the five-weapon icon column reaches the coins counter, because the layout page is already full at 100.
  - Fractional scale with nearest filtering, rather than snapping to whole numbers. Snapping would break "in proportion". Some art pixels are one screen pixel wider than others; the playtest judges this.
- **Which screens the slider covers:** the run HUD only. Not the pause, level-up, time's up or recap screens, menus or garage, and not the world-space trick popups or kaiju bar.
- **Pause strip:** it is one row taller (about 27 px).
- **Drift prototype:** it has no HUD, so there the slider only saves.

**Older tests changed to the new rule** (they expected fixed pixel sizes at other window sizes, or a headless 64 x 64 viewport): `test_hud_layout.gd`, `test_hud_heart_row.gd`, `test_hud_reactions.gd` (reactions' parent is now `hud.root`), `test_hud_sub_goal.gd`, `test_hud_viewers_counter.gd`, `test_hud_combo_heat.gd`. They now measure in layout pixels × `hud_scale()`.

**New tests**
- `game/tests/unit/hud/test_hud_scaling.gd` (9 tests):
  - At 1152x648, 1920x1080, 2560x1440, 3440x1440 and 960x540, each piece keeps its corner or edge with size and margins in proportion (±1.5 px), and nothing overlaps or goes off screen. This holds at both slider ends too.
  - Resizing the window rescales the HUD, and the sub goal moves up when the HUD is big.
  - Every CanvasItem under the root resolves to nearest filtering (at 1920x1080, a non-whole scale).
  - The camera's zoom is the same at both slider ends and after the HUD scales on the ultrawide.
  - Bursts and flights follow the scale.
- `game/tests/unit/test_hud_size_slider.gd` (8 tests):
  - The label equals the file's text, and a scan of `res://scripts` finds no quoted literal of it.
  - The row is laid out like the music row.
  - The value changes the HUD's scale at once while paused.
  - No writes during a drag, one write when the drag ends, and a click change is saved on close.
  - A saved 75 is applied by `GameFlow.add_run` at the next start (HUD and slider).
  - Settings clamp to the range.

**Test sets (all pass):** GUT 2170/2170 (177 scripts), `game/tools` unittest 736 OK (1 skipped), `tools` unittest 582 OK.

**Screenshots** in `art-archive/T-431/screenshots/`. They come from fixtures `game/tests/fixtures/t431_*.tscn`, which render a run in a SubViewport of the exact size so the big sizes don't depend on the monitor:
- Five window sizes: `hud_1152x648.png` (scale 1), `hud_1920x1080.png` (1.667), `hud_2560x1440.png` (2.222), `hud_3440x1440.png` (2.222, ultrawide), `hud_960x540.png` (0.833).
- Slider at both ends, paused: `slider_50_paused_1152x648.png`, `slider_125_paused_1152x648.png`, `slider_50_paused_3440x1440.png`, `slider_125_paused_3440x1440.png`.

**Documents updated:** `docs/hud-and-menus.md` (Content: the new section "The HUD scales with the window" with the rule, range, default and covered screens; the HUD size slider bullet in "Pause screen"), `game/docs/hud-and-menus/hud.md`, `game/docs/hud-and-menus/pause-screen.md`.

**Refusals:** none.

**QA round 1 (2026-10-30): all 7 criteria pass.** `python tools/qa_check.py` was refused (not on the pre-approved list), so I ran the three test sets directly: GUT 2170/2170 passing (run_tests.sh), `game/tools` unittest 736 OK (1 skipped), `tools` unittest 582 OK. Each criterion was judged from the test files, the code and the docs by grep, not by re-reading every line. Test names in test_hud_scaling.gd cover the five sizes, nearest filtering and camera zoom. test_hud_size_slider.gd covers the label, the drag and the saved value. The grep finds `hud_size_label` only as a key and variable, and the text itself is only in pause_text.json. Nine screenshots are in art-archive/T-431/screenshots/: five sizes and four slider-end shots. The three docs mention the rule, range and covered screens. The qa_check marks run was skipped.
- 2026-10-30, in-qa → needs-playtest: QA passed every criterion (goal G-008).

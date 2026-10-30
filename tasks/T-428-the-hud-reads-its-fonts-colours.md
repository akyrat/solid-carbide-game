---
id: T-428
title: The HUD reads its fonts, colours and outlines from one shared HUD style (looks unchanged)
status: in-progress
from: project-lead
to: ui
lead: Goal-G-008
epic: hud-menus
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/docs/hud-and-menus/hud.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/hud.gd, game/scenes/hud/hud.tscn, game/data/hud.json, game/tests/unit/hud/test_hud_layout.gd]
files_expected_to_change: [game/scripts/hud/hud_style.gd, game/scripts/hud/*.gd, game/scripts/ui/pause_screen.gd, game/scripts/ui/level_up_screen.gd, game/tests/unit/hud/test_hud_style.gd, game/docs/hud-and-menus/hud.md]
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

Goal G-008, 'A consistent HUD' (HUD and menus, Decisions): the HUD's code follows one style sheet. This is the functional half: move every HUD style value now hard-coded in the HUD scripts (font files and sizes, font colours, outline colours and widths, panel colours) into one shared place that the HUD scripts read: a Godot Theme, a style script (for example game/scripts/hud/hud_style.gd) or a data file, your choice, named in the result notes. Cover the clock, coins, hearts, weapon icons, sub goal, live viewers counter and its fire, reactions, trick and combo broken popups, kaiju health bar, pause strip and level-up screen. Keep today's values exactly: nothing the player sees changes. The Asset Generation ticket that follows writes the HUD style sheet in Visual style, redraws the pieces that break it and lists the code changes; a later UI ticket sets the new values in this shared place.

## Acceptance criteria

- [ ] One shared HUD style place exists (Theme, style script or data file), named in the result notes, and every HUD script listed in the description reads its fonts, font colours, outline widths and colours from it; a grep of game/scripts/hud/ for add_theme_color_override and add_theme_font_size_override with literal values finds none outside that place, or the result notes justify each one left. (QA: pass / fail)
- [ ] A GUT test loads the shared style and checks the HUD's labels use its values. (QA: pass / fail)
- [ ] Positions, sizes and behaviour are unchanged: the existing HUD layout and behaviour tests still pass unchanged. (QA: pass / fail)
- [ ] A screenshot of a run with the whole HUD visible is in art-archive/<id>/screenshots/, matching the look before the change. (QA: pass / fail)
- [ ] game/docs/hud-and-menus/hud.md names the shared style place and how HUD scripts read it. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-428.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### UI Agent, 2026-10-30

**Done.** The shared HUD style place is a style script: **`game/scripts/hud/hud_style.gd` (`class_name HudStyle`)**. I chose a script over a Godot Theme because most of the HUD is built in code and some of it is drawn, not made of Controls (baked popup palettes, flames, the kaiju's bar). A Theme could not hold those values, and a script can.

**How the HUD reads it** (also in `game/docs/hud-and-menus/hud.md`, "The HUD's shared style"):
- Labels: `HudStyle.apply(control, "<role>"[, colour])` sets the font, size, colour (all four button states on a Button), outline colour and outline width from `HudStyle.LABELS`. The roles are `coins`, `clock_digits`, `sub_goal`, `weapon_count`, `air_counter`, `viewers_number`, `viewers_unit`, `viewers_flight`, `viewers_drop`, `pause_title`, `pause_text`, `level_up_title`, `level_up_card_title`, `level_up_card_desc` and `level_up_button`.
- Heat looks: `HudStyle.HEAT_STEPS` (formerly `ComboHeat.STEPS`) with `apply_heat()` and `glow_color()`, used by the combo heat and the viewers counter.
- Drawn pieces read these constants: `FIRE_PALETTE`, `SUB_GOAL_GLOW`, `HEALTH_*`, `CLOCK_PANEL_*`, `POPUP_PALETTE`/`POPUP_TEXT` (trick popups), `BROKEN_PALETTE` (combo broken popup), `KAIJU_*`, `PAUSE_*` and `LEVEL_UP_*`.
- Fonts: `HudStyle.comic_font()` (`Hud.comic_font()` now returns it), `clock_font()`, and `new_comic_font()` (the popups bake from their own copy, as before).
- Every old constant name (`Hud.LABEL_COLOR`, `ComboHeat.STEPS`, `LikesFire.PALETTE`, `TrickPopupArt.PALETTE`/`STYLES`, `ComboBrokenArt.PALETTE`, `WeaponIcons.COUNT_*`, `AirtimeCounter.*`, `ViewersCounter.DARK`/`UNIT_FONT_SIZE`, `TimerClock.PANEL_*`, `KaijuHealthBar.*`, the pause screen's `STRIP_COLOR`/`CONTROL_*`, `LevelUpScreen.TITLE_*`/`DIM`/`INK`/sizes) is kept and points at `HudStyle`. Existing tests and callers work unchanged, and each value is now set in one file.

**Covered:** the clock (digits and panel), coins, hearts (they have no font or colour style; the row is art), weapon icons' counts, sub goal label/fill/glow, live viewers counter (number, unit, flight, drop) and its fire, reactions (no style values: art only), trick and combo broken popups, kaiju health bar, pause strip and level-up screen.

**All values are the ones from before T-428**, so nothing on screen changes. `test_values_are_the_ones_before_t428` pins them to master's literals.

**Left in the scripts on purpose (criterion 1 justification).** A grep of `game/scripts/hud/` (plus `pause_screen.gd` and `level_up_screen.gd`) for `add_theme_color_override`/`add_theme_font_size_override` with a literal value finds none outside `hud_style.gd`. The test `test_no_style_literals_in_hud_scripts` scans for exactly that, outline widths included. The remaining `Color(...)` uses aren't style; they're per-frame or computed values:
- the heart row's loss flash `modulate`;
- the reactions' fade alpha;
- the viewers counter's flash rectangle and its transparent start;
- `Color(color, alpha)` flashes;
- the gift's grey copy;
- the popup baker's opaque-pixel copy;
- transparent image fills;
- the level-up card's placeholder weapon pixel grids (art placeholders that the weapon art replaces, not HUD style).

The viewers counter still swaps its number's `font_color` between `crash_color` and `color` at runtime. Both are variables that come from `hud.json` or `HudStyle`. The timer colour per step is data (`hud.json` `timer_clock.steps`) and is set through `color_for()`.

**Small extra:** `LevelUpScreen` keeps its `HudScript` preload, because `test_level_up_screen.gd` reaches the HUD through it.

**Tests** (all run in the foreground on the branch):
- GUT `bash game/tools/run_tests.sh`: **2136/2136 passed** (173 scripts, 1,267,985 asserts). New: `game/tests/unit/hud/test_hud_style.gd`, 11 tests: the style loads and every role is well formed, the fonts, the pre-T-428 values, the scripts' constants are the style's, the HUD's labels, weapon counts, viewers number, flight and drop use it, the heat look, a button's four colours, and no literals left. The existing HUD layout and behaviour tests (`test_hud_layout.gd` and the rest) are unchanged and pass.
- `python -m unittest discover -s game/tools -p "test_*.py"`: **722 tests OK** (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: **582 tests OK**.

**Screenshots** (`art-archive/T-428/screenshots/`):
- `hud_run.png`: a run with the whole HUD visible: hearts, the gun with "X3", coins, the clock, the sub goal square and "18 / 30 SUBS", the live viewers counter, and a trick popup. Fixture: `game/tests/fixtures/t428_hud_style_demo.tscn`.
- `pause.png`: the pause strip (fixture `pause_from_menu_demo.tscn`). It is identical to `art-archive/T-389/screenshots/pause.png` from the same fixture before T-428.
- `level_up.png`: the level-up screen (fixture `t428_level_up_demo.tscn`). The text look (cream ribbon title with dark outline, black Bangers card text, "TAKE IT" plates) matches `art-archive/T-310/screenshots/level_up_title_cream.png`; the ribbon art and card texts have changed since T-310 through other tickets.
- About "before": I could not render master in this folder (that needs a checkout or a file write outside the approved commands). The look match therefore rests on the pinned-value test, plus these comparisons with archived shots of the same screens. The coins and clock also match `art-archive/T-341/screenshots/hud_1152x648.png`.
- The old `hud_from_menu_demo.tscn` now stops on the tutorial slides (T-389 put them in front of Start), so I wrote the new T-428 fixture, which uses `game.start_run()` as `pause_from_menu_demo` does.

**Documents affected:** `game/docs/hud-and-menus/hud.md` (new paragraph "The HUD's shared style").

**PixelLab:** 0 generations. **Refusals:** none.

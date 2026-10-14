---
id: T-133
title: Trick popups heat up with the combo at x2, x3 and x4
status: in-qa
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-131, T-132]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, tasks/T-131-combo-heat-levels.md, tasks/T-084-trick-popup-art.md, tasks/T-125-popups-follow-the-car.md, game/scripts/hud/trick_popups.gd, game/scripts/hud/trick_popup_art.gd]
files_expected_to_change: [game/scripts/hud/trick_popups.gd, game/scripts/hud/trick_popup_art.gd, their tests, a screenshot fixture, game/README.md, docs/hud-and-menus.md]
model: opus
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

The trick popups follow the combo's heat steps from T-131 (decision: `docs/hud-and-menus.md`, Decisions, board 2026-10-14). Use T-131's thresholds and step logic (same constants, one place), applied to the multiplier the trick brought the combo to (the run state's `combo_trick` signal):

- **Below x2:** today's popup, unchanged: white rounded rectangle, black border, black Bangers lettering.
- **Step 1, from x2:** a hot accent: for example an orange border, or the "+amount" in orange.
- **Step 2, from x3:** hotter: a stronger accent (for example a thicker or yellow-orange border, both border and amount coloured).
- **Step 3, from x4 up:** a flaming edge around the popup, in the same fire style as T-131's burning likes bar.

Colour only comes in from x2: at low combo the popup stays black and white, as the board asked on 2026-10-13. The letters stay readable on white at every step. Oranges and yellows only, never Redgull red. Hard pixel edges, only opaque or fully transparent pixels, as in T-084. Size, stacking, following the car, the quarter-screen limit, three at most (T-125) and drawing above the buildings (T-132) stay as they are. The challenge popup follows the same rule. The drift prototype has no combo and keeps the plain popup. Drawn in code, no PixelLab.

Add a screenshot fixture showing one popup per step, and say in the result notes how to run it.

The board's review: play a run in this task's folder, chain tricks past x2, x3 and x4, and judge whether the popups heat up with the counter and still read well.
Board review files: the step screenshots listed in the result notes

## Acceptance criteria

- [x] The popup's step comes from the multiplier after the trick, with the same thresholds as T-131 (one shared source; a test checks both use it): a GUT test shows tricks at x1.5, x2.0, x3.0 and x4.5 and checks each popup's step. (QA: pass)
- [x] Below x2 the popup is exactly as before (only black, white and transparent pixels; T-084's art tests still pass). (QA: pass)
- [x] Steps 1, 2 and 3 each add a visible accent and differ from each other: a test checks each step's baked image differs from the others and contains orange or yellow pixels, and the fixture's screenshots show four different looks. (QA: pass)
- [x] No Redgull red and no semi-transparent pixels in any step (test). (QA: pass)
- [x] The popup's fill stays white at every step, and the trick names stay black (test samples the colours). (QA: pass)
- [x] T-125's and T-132's popup tests and the whole GUT suite pass; the drift prototype shows plain popups. (QA: pass)
- [x] `game/README.md` ("Trick popups") and `docs/hud-and-menus.md` (Content, "Trick popups") describe the steps. (QA: pass)

## Result notes

UI Agent, 2026-10-14.

**What I built.** The popups take the combo's heat step from T-131's `ComboHeat.step_for` (the only thresholds remain `ComboHeat.THRESHOLDS`; `TrickPopups.heat_for(m)` just calls it). A trick popup gets the step of the `combo_trick` signal's multiplier, which is the combo after the trick. The challenge popup gets the step of the run state's `combo` at the moment it shows. The car's own `trick` signal, used in the drift prototype, always gives step 0. `TrickPopupArt.bake/texture(text, style, heat := 0, frame := 0)` draws each step:
- **Below x2 (step 0):** byte for byte the old popup. I checked this against master's `trick_popup_art.gd` for five texts, all identical, and the T-084 art tests are unchanged and pass.
- **x2 (step 1):** the black border becomes a 1 px black outline round a 3 px yellow ring. The HUD counter is yellow at this step.
- **x3 (step 2):** a 1 px black outline, a 3 px orange ring and a 2 px yellow inner ring. The "+amount" turns orange with a 1 px black outline (4-neighbour, so small digits keep their holes).
- **x4 up (step 3):** step 2's look plus a flaming edge. These are pixel flames in LikesFire's colours and style: white-hot, yellow, orange-yellow and orange tips, swaying tongues and the odd spark. They are tall over the top edge and short at the sides and below. They come in 3 px blocks (about 2 screen px, like `LikesFire.PIXEL`), baked in 6 frames that flip every `ComboHeat.FLICKER_FRAME`.

At every step the fill stays white and the names black. Every colour comes from LikesFire's palette, and none is near the heart red. Every pixel is either opaque or fully transparent. The hotter images grow outward, but `PopupText.size()` still uses the plain popup's size, so stacking, the quarter-screen limit, three-at-most and following the car are unchanged. The T-132 absolute z is kept. Drawn in code: no PixelLab, no sound.

**Files.** `game/scripts/hud/trick_popups.gd`, `game/scripts/hud/trick_popup_art.gd`, new `game/tests/unit/test_trick_popups_heat.gd` (12 tests), fixture `game/tests/fixtures/popups_heat_demo.gd/.tscn`, tools `game/tools/popup_heat_shots.sh` and `game/tools/popup_heat_sheet.gd`. Docs: `docs/hud-and-menus.md` (Content, "Trick popups") and `game/README.md` ("Trick popups", new "Heat steps" bullet).

**Tests.** The whole GUT suite passes: 554/554 (`bash game/tools/run_tests.sh`). That includes the T-084, T-125 (`test_trick_popups_follow.gd`) and T-132 (`test_popups_above_buildings.gd`) popup tests.

**Fixture and screenshots.** From the worktree root: `bash game/tools/popup_heat_shots.sh screenshots`. It writes these to `C:\solid-carbide-worktrees\T-133\screenshots\`:
- `T-133_popups_heat.png`: a run with one row per step, top to bottom plain, x2, x3, x4. Each row has a normal, a small and a challenge popup. `T-133_popups_heat_zoom.png` is the same enlarged 2x.
- `T-133_popups_heat_sheet.png` and `T-133_popups_heat_sheet_f3.png`: the baked popups alone on a dark and a light background, enlarged 3x, with flame frames 0 and 3. Columns are steps 0 to 3.
- `T-133_combo_heat_base.png`, `_step1.png`, `_step2.png`, `_step3.png`: T-131's combo fixtures, a real run from the menu chaining tricks. The real popup at the car matches the HUD counter's step (x1.5, x2.0, x3.0, x4.5).

The fixture alone: `bash game/tools/screenshot.sh res://tests/fixtures/popups_heat_demo.tscn screenshots/T-133_popups_heat.png 10`.

**What may look weak.**
1. At game scale (one popup pixel is about 0.7 screen px) the small extended-drift popup's orange "+0.05" at steps 2 and 3 is the hardest part to read. It reads, but it is busier than the black version. The cheapest fix if the board dislikes it is to keep the small popup's amount black and let the ring carry the step.
2. Step 1's yellow ring is the quietest step on light gravel. I widened it from 2 to 3 px after my first screenshots.
3. The flames extend about 10 drawn px above the popup, so with three popups stacked a hot popup's flames can overlap the bottom of the one above it. Stacking uses the plain size on purpose, so nothing else moves.

**QA (QA/Integration Agent, 2026-10-14, round 1): all 7 criteria pass.**
- Whole GUT suite: 554/554 passing (`bash game/tools/run_tests.sh`), including `test_trick_popups_heat.gd` (12), T-084's `test_trick_popup_art.gd`, T-125's `test_trick_popups_follow.gd` and T-132's `test_popups_above_buildings.gd`; none of the older popup test files changed on this branch. Python tool tests: 130 passed (`python -m pytest tools`).
- Criterion 1: `TrickPopups.heat_for` only calls `ComboHeat.step_for` (thresholds stay in `ComboHeat.THRESHOLDS`); the test emits `combo_trick` at x1.5, x2.0, x3.0, x4.5 in a real run and gets steps 0, 1, 2, 3, and checks the source uses `ComboHeat.step_for`.
- Criterion 2: independent check beyond the agent's tests: I baked 7 texts x 2 sizes with master's `trick_popup_art.gd` and with this branch's at heat 0; all 14 images byte-identical (temporary script, removed).
- Criteria 3-5: covered by the new tests (each step differs, more warm pixels per step; every step and flame frame has only alpha 0 or 1, nothing within 0.5 of the heart red, transparent rim; white fill and black name pixels sampled at every step). Remade the screenshots (`bash game/tools/popup_heat_shots.sh screenshots`) and looked at them: plain popup unchanged below x2; four clearly different looks (yellow ring, orange+yellow ring with orange amount, plus flames); fill white and names black at every step; no red; hard edges. `T-133_combo_heat_step1/3.png` show the popup's step matching the HUD counter (yellow COMBO X2.0 with the yellow-ring popup; burning COMBO X4.5 with the flaming popup).
- Criterion 6: drift prototype test passes (car `trick` signal always step 0); stacking/limit/three-at-most use the plain size and their tests pass; z unchanged (T-132 tests pass).
- Criterion 7: `game/README.md` "Heat steps" bullet and `docs/hud-and-menus.md` Trick popups paragraph describe all steps.
- Observation for the board (not a fail): at game scale the small extended-drift popup's orange "+0.05" at steps 2 and 3 is readable but muddy: the "+" and the digits' holes nearly close up and the orange with its black outline reads as a blob next to the crisp black name. Worth judging in the playtest; the agent's suggested cheap fix (keep the small popup's amount black, let the ring carry the step) would solve it. Also confirmed the agent's note that step-3 flames on a stacked popup can overlap the bottom of the popup above.
- Godot's line-ending-only `.import` changes from the test runs were not committed.


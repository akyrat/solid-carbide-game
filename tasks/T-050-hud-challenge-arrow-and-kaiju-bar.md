---
id: T-050
title: HUD: the kaiju's health bar
status: needs-playtest
from: project-lead
to: ui
lead: Enemies
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-049, T-045]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-049-hud-run-values.md, tasks/T-045-kaiju.md, tasks/T-048-text-hud.md, game/README.md]
files_expected_to_change: [the HUD scene and script, tests, docs/hud-and-menus.md, game/README.md]
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

**Blocked until T-049 (the HUD) and T-045 (the kaiju) are done.**

Add the kaiju's health bar to the HUD (HUD and menus, Decisions): shown only once the kaiju appears (T-045's health value and signal), with T-048's label. It hides when the kaiju dies. The arrow to the nearest challenge moved to T-098, after the MVP (2026-10-11).

**The board's design (task board note, 2026-10-15), word for word:** "hp bar on top of the kaiju, about as wide as the boss character itself. mkae the health bar subtly match the comic style combo popups in style, with thin divisors at each 10% hp. make the health bar neon purple with a white background and black borderlines (for the thin dividers as well)". So the bar sits above the kaiju in the world and follows it, instead of sitting in the HUD's corner: as wide as the kaiju, neon purple fill on a white background, black outline, thin black dividers at every 10% of its health, in a subtle version of the combo popups' comic style (T-131, T-133). **The board's answers (2026-10-15, HUD and menus, Decisions):** no label (T-048's "Kaiju (Co-Star)" is not used, so the task shows no text); always drawn above buildings, so it shows even when the kaiju is behind one; its width follows the kaiju's width, so it still fits when T-069's final art replaces the placeholder. This replaces the bar in a corner of the HUD.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test shows the kaiju's health bar is hidden before the kaiju appears, shows its health after (following the health signal), and hides when it dies (QA: pass)
- [x] A test shows the bar follows the kaiju, sits above it, is about as wide as the kaiju (it follows the kaiju's width), has a divider at every 10% of its health, and is drawn above buildings (QA: pass)
- [x] A screenshot of a run shows the bar above the kaiju, partly emptied, in neon purple on white with black outline and dividers, and no Redgull red (QA: pass)
- [x] `docs/hud-and-menus.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

- 2026-10-15, open → planning: hp bar on top of the kaiju, about as wide as the boss character itself. mkae the health bar subtly match the comic style combo popups in style, with thin divisors at each 10% hp. make the health bar neon purple with a white background and black borderlines (for the thin dividers as well)

- 2026-10-15, ui: built. `game/scripts/hud/kaiju_health_bar.gd` (`KaijuHealthBar`, `run.kaiju_health_bar`, child of the world view): hidden until `kaiju_appeared`, follows `kaiju_health_changed`, hides on `kaiju_defeated` and in a new run. Sits above the kaiju sprite's head, as wide as it (width from the sprite's new static `drawn_width_px()`, 90 px for the placeholder; the final art must provide `drawn_width_px()` and `drawn_height_px()`). Neon purple on white, black 2 px outline with stepped corners, black dividers at every 10%, no text, absolute z at `CANVAS_ITEM_Z_MAX` like the trick popups. Change to kaiju files (for the T-046 agent): only the static `drawn_width_px()` added to `kaiju_sprite.gd`; `run.gd` creates the bar after the boss.
- Tests: `tests/unit/hud/test_kaiju_health_bar.gd` (9 tests, independent of the playtest switch). Full GUT suite: 680 passed. Python tool tests (game/tools and tools): 422 passed, 1 skipped.
- Screenshot: `C:\solid-carbide-worktrees\T-050\screenshots\kaiju_bar.png` (copy in `art-archive/T-050/screenshots/`), bar at 63% above the kaiju.
- **For the board's playtest, `kaiju_early_arrival` in `game/data/playtest.json` is ON (30 s). It must go back to `"enabled": false` right before merging.**
- Docs: `docs/hud-and-menus.md` (Content, the HUD), `game/README.md` ("The kaiju").
- 2026-10-15, QA round 1 (qa-integration): all five criteria pass.
  - Criterion 1, pass: `test_hidden_before_the_kaiju_appears`, `test_shows_health_after_appearing_and_follows_signal` (1.0, 0.75, 0.25 after hits), `test_hides_when_the_kaiju_dies`, plus `test_hides_in_a_new_run`.
  - Criterion 2, pass: `test_follows_the_kaiju_above_it_and_as_wide` (x on the sprite, above the head, width = `drawn_width_px()`, moves with it), `test_width_follows_the_sprite` (a 200 px stub sprite gives a 200 px bar), `test_divider_at_every_ten_percent` (9 inner dividers at 10..90), `test_drawn_above_buildings` (absolute z `CANVAS_ITEM_Z_MAX`, above `map.top_z_index()`).
  - Criterion 3, pass: `art-archive/T-050/screenshots/kaiju_bar.png` (run started from the main menu via `tests/fixtures/kaiju_bar_demo.tscn`): bar just above the kaiju's head, about as wide as its body, 63% full; pixels in the bar area are only black, neon purple (184, 46, 255), white and the ground; no red pixels (scripted check). 10 segments with black dividers, black stepped outline, no text.
  - Criterion 4, pass: the only hunk in `docs/hud-and-menus.md` against master is line 54, inside Content (lines 38 to 74); Summary, Decisions and Open questions unchanged.
  - Criterion 5, pass: full GUT suite 680/680 with the branch's `kaiju_early_arrival` on, and again 680/680 with it off (restored to the branch's `true` afterwards; tests pin `playtest_override`, so they do not depend on it). Python: `game/tools` 251 passed, 1 skipped; `tools` 171 passed.
  - Extra checks: the only kaiju file changed is `kaiju_sprite.gd`, adding only the static `drawn_width_px()` (plus `run.gd` creating the bar). No numbers in `game/data` changed; the only data file changed is the playtest switch `game/data/playtest.json` (`kaiju_early_arrival.enabled` true), which must go back to false before merging. Board's design matches: neon purple fill, white back, black outline and dividers every 10%, no text, no Redgull red, above the kaiju and as wide as its drawing, above buildings.
  - Minor note (not a criterion): in `run.gd` the new `KaijuHealthBarScript` preload was inserted between the comment "The kaiju (task T-045)..." and `KaijuBossScript`, so that doc comment now sits on the bar's preload. Cosmetic only.
- 2026-10-15, in-qa → needs-playtest: QA round 1: all five criteria pass (qa-integration)

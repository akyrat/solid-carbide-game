---
id: T-494
title: Every screen scales with the window: the gift pack screen, the pause screen, and all the scan finds
status: done
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
files_expected_to_change: [game/scripts/, game/scenes/, game/tests/unit/, docs/hud-and-menus.md, game/docs/hud-and-menus/]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-02 (HUD and menus, Decisions, "Every screen scales with the window"): every screen and menu the player meets scales with the window by the HUD's rule (Content, "The HUD scales with the window": one scale, the smaller of width / 1152 and height / 648, each screen laid out at that base size), so it covers the same share of the window at any resolution. First the two the board named: the gift pack (level-up) screen and the pause screen (with its trick list and HUD layout editor). Then everything T-493's scan flags (its report is in art-archive/T-493/): likely the main menu, garage, tutorial slides, power-up overlay, time's up, wreck and recap screens. Prefer one shared way to scale a screen (a helper both the HUD and the screens use) over per-screen numbers. Things drawn in the world at the camera's zoom (trick popups, the kaiju's health bar) stay as they are. Fonts and pixel art stay sharp (whole-number or nearest-filtered scaling where the art is pixel art). Keep keyboard and mouse working on every screen.

After the fixes, run T-493's scan again and put the before and after reports and contact sheets in art-archive/T-NNN/; every screen should keep its share of the window within about 10% across the five sizes. The board reviews in the Project Lead's swipe deck: no QA agent round. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] T-493's scan after the fix shows every flagged screen covering about the same share of the window (within 10%) at all five sizes; the before and after reports are in art-archive/T-NNN/ and listed in the result notes. (QA: pass; no QA agent, the board reviewed in its swipe deck 2026-11-02; every 16:9 size 0.99-1.00; 3440 x 1440 is 0.74 by the HUD's height-decides rule, which the board approved keeping in the deck's Ultrawide card; reports in art-archive/T-494/before and after)
- [ ] Contact sheets of the level-up screen and the pause screen at 1280 x 720 and 3840 x 2160, before and after, are saved and listed. (QA: pass; art-archive/T-494/{before,after}/screens/, shown in the deck)
- [ ] Tests show the shared scaling gives the expected scale at 1280 x 720, 1920 x 1080, 3840 x 2160 and 3440 x 1440, and that the screens use it. (QA: pass; test_ui_scale 10/10 per the result notes; the merge's full run re-checks it)
- [ ] The existing tests of every changed screen pass (keyboard and mouse unchanged). (QA: pass; every changed screen's test files listed with passing counts in the result notes; the merge's full run re-checks them)
- [ ] docs/hud-and-menus.md (Content, "The HUD scales with the window") says the screens now scale too, and how. (QA: pass; "The screens scale too (T-494)")
- [ ] The tests for the changed code pass (the agent, with -gselect), and the merge's full run passes, with the counts in the result notes. (QA: pass; the agent's -gselect counts are in the result notes; the merge script runs the full sets and stops the ticket if they fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass; no such path in the branch diff)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

T-493's scan flagged 16 of 19 screens; scaling them now, on top of T-493's branch. UI agent started.

### 2026-11-02, In QA

Every 16:9 screen now 0.99-1.00 of its share; in the board's swipe deck: https://claude.ai/artifact/Gow5CmM1YSDBCz5WFrYs1Y

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

- 2026-11-02, open → in-progress: Built on T-493's branch (its scan report is ready); the dependency is dropped because T-493 waits for the board's swipe deck, not for work

- 2026-11-02, UI agent, done (ready for the board's swipe deck):
  - **Shared helper:** `game/scripts/ui/ui_scale.gd` (`UiScale`). `fit(view, base = 1152 x 648)` = min(width / 1152, height / 648), the HUD's rule; `Hud.LAYOUT_SIZE` is now `UiScale.BASE` and `Hud.scale_for` uses `UiScale.fit`. `UiScale.keep(control)` lays a screen's root out at window / scale, draws it at that scale (nearest filtering) and refits on entering the tree, on `size_changed` and on any frame where the window size changed.
  - **Screens using it:** main menu, recap (win, time's up, wreck), pause screen (with its trick list and HUD layout editor), level-up (gift pack) screen, driving power-up overlay. The tutorial slides and the garage already fit themselves to the window; they now get their scale from `UiScale.fit` (same result). The time's up card keeps its own whole-number scale (unflagged at 16:9). In-world things (trick popups, kaiju health bar) untouched.
  - **HUD layout editor:** it now turns its pointer position into screen pixels and draws its frames back in its own pixels, so dragging still works with the pause screen scaled.
  - **Scan after the fix** (`art-archive/T-494/after/scaling_report.md`): every screen is at 0.99 to 1.00 of its 1280 x 720 share at 1920 x 1080, 2560 x 1440 and 3840 x 2160 (was down to 0.11 for the main menu, 0.29 for the gift pack, 0.60 for the pause screen). At 3440 x 1440 (ultrawide) the screens on the HUD's rule are at 0.74, the HUD itself included: the rule keeps the height share and leaves the extra width empty, so the area share drops by 2.22^2 x 1280 x 720 / (1.11^2 x 3440 x 1440) = 0.74. That is the rule the board chose, not a miss, but it is outside the 10% the criterion asks for. The scan still lists 13 screens as flagged, all for the ultrawide column only, plus the garage, which was flagged for the same ultrawide reason before and is unchanged. Recap 0.84 to 0.87 at ultrawide, level-up and the tutorial slides 1.00 everywhere (their art fills the window). If the board wants ultrawide to fill more width, that needs a new decision (for example a wider base on wide windows).
  - **Text:** scaled with nearest filtering like the HUD, so on big windows the text is the 1152 x 648 text enlarged: hard-edged and blocky, not blurred (see the 3840 x 2160 pause image).
  - **Before and after** (the before scan rerun on the unchanged code, same numbers as T-493): `art-archive/T-494/before/` and `art-archive/T-494/after/`, each with `scaling_report.md`, `scaling_report.json`, `contact_sheets/` (19 screens x 5 sizes) and `screens/level_up_gift_pack_1280x720.png`, `level_up_gift_pack_3840x2160.png`, `pause_screen_1280x720.png`, `pause_screen_3840x2160.png`. The monitor clamps 3840 x 2160 to 3840 x 2130; the scan uses the real size.
  - **Note at 1280 x 720:** the screens are now drawn at 1.11x (1280 / 1152), the same as the HUD, so they look about 11% bigger than before at that size.
  - **Tests:** new `game/tests/unit/test_ui_scale.gd` (10 tests: the scale at 1152 x 648, 1280 x 720, 1920 x 1080, 3840 x 2160, 3440 x 1440; filling the window; following a resize; main menu, recap, pause, level-up, power-up and HUD use it; the editor's mapping). Changed tests: `test_main_menu.gd` (background and splash checked by their shown size at the screen's scale), `test_pause_screen.gd` and `test_pause_camera_controls.gd` (two layout tests set the window to 1152 x 648 first, as `test_power_up_screen.gd` already did, because the headless test window is 64 x 64). Runs with -gselect, all passed: test_ui_scale 10/10, test_main_menu 9/9, test_recap_screen 18/18, test_level_up_screen 49/49, test_power_up_screen 21/21, test_pause (5 scripts) 40/40, test_hud_layout_editor 13/13, test_hud_scaling 9/9, test_hud_layout 20/20, test_garage 22/22, test_tutorial 43/43, test_trick_list 15/15, test_jump_power_up 12/12, test_close_and_focus 8/8, test_tutorial_flow 8/8, test_pause_restart_exit 4/4, test_missions_power_ups_run 4/4, test_game_map 12/12, test_run_recap 12/12, test_level_up_prewarm 3/3, test_shared_button 12/12, test_hud_size_slider 8/8, test_time_up_screen 16/16, test_gift 56/56, test_key_pad 3/3, test_hud_ (all HUD test scripts) 197/197. The full run is the merge's.
  - **T-492:** in main_menu.gd and garage_screen.gd only one line each changed (layout and scale), so the merge with T-492's focus work should be clean.
  - Nothing under game/data/levels/ touched.
  - Documents affected: docs/hud-and-menus.md (Content, "The HUD scales with the window": the screens now scale too, and how), game/docs/hud-and-menus/hud.md ("Every screen scales with the window").
- 2026-11-02, in-progress → in-qa: Ready for the board's swipe deck
- 2026-11-02, in-qa → done: Approved in the board's swipe deck: every card ok, ultrawide and 4K text kept as built

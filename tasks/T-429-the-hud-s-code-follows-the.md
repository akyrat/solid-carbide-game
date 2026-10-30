---
id: T-429
title: The HUD's code follows the HUD style sheet (fonts, colours, outlines)
status: in-qa
from: project-lead
to: ui
lead: Goal-G-008
epic: hud-menus
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: yes
depends_on: [T-430]
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/hud_style.gd]
files_expected_to_change: [game/scripts/hud/hud_style.gd, game/scripts/hud/*.gd, game/scripts/ui/pause_screen.gd, game/scripts/ui/level_up_screen.gd, game/tests/unit/hud/test_hud_style.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
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

Goal G-008, 'A consistent HUD': the Asset Generation ticket D4 wrote the HUD style sheet in Visual style and, in its result notes, listed piece by piece the code changes the HUD needs (fonts, colours, outline widths). Make every one of them, in the shared HUD style place D3 made (and only where a piece needs it, in its own script). Don't move or resize anything. Add any font the sheet names under game/fonts/ with its licence. Describe the style each piece now uses in HUD and menus, Content and game/docs/hud-and-menus/hud.md.

The board's review: Play a run and check every HUD piece (clock, coins, hearts, weapon icons, sub goal, live viewers counter, reactions, popups, kaiju bar, pause strip, level-up screen) now looks like one family.

## Acceptance criteria

- [ ] Every code change listed in D4's result notes is made, ticked off one by one in a checklist in the result notes. (QA: fail: code - the checklist leaves clock digits (art swap), weapon icon size and pause-strip capitals unticked/not done; the agent's notes say "Partly done")
- [ ] The HUD's style values (fonts, colours, outline widths) are defined in the one shared place D3 made, named in the result notes, and the test for it checks the new values. (QA: pass)
- [ ] Positions, sizes and behaviour are unchanged: the existing HUD layout and behaviour tests still pass. (QA: pass - every Godot file in the full run passed so far, none failed)
- [ ] A screenshot of a run with the whole HUD is in art-archive/<id>/screenshots/, next to a copy of D4's before shot of the same moment. (QA: pass)
- [ ] docs/hud-and-menus.md, Content and game/docs/hud-and-menus/hud.md describe the style each HUD piece now uses. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: fail: paperwork - the result notes give no full Godot count and say the third set (docs/tools checks) was not run; QA's own full Godot run exceeded the 600 s foreground limit, no failures seen before that)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-429.

### 2026-10-30, In progress → In QA

Goal runner (G-008): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

**Partly done.** All style values live in `game/scripts/hud/hud_style.gd` (`HudStyle`, D3's place). 0 PixelLab generations.

**Checklist of D4's (T-430) code list:**
- [ ] Clock: replace Consolas with the art's seven-segment digits on `clock_panel.png`. NOT done: it swaps a font for art and changes the panel and digit sizes, against "don't move or resize". Needs its own ticket.
- [x] Coins: role `coins` font to Bangers, outline 6.
- [ ] Weapon icons: `ICON_SIZE` 48 to a 2x multiple of new art. NOT done: needs new art (D4 said so); `weapon_count` and `air_counter` outline 8 already fit.
- [x] Sub goal: nothing to change (Bangers 20, outline 6).
- [x] Viewers counter: `viewers_unit` outline 4 to 6; flight/drop 6 and number 8 already; heat steps' outline 10 to 8.
- [x] Trick popups: `POPUP_PALETTE` entries 1, 3, 12 and `BROKEN_PALETTE` entries 2, 4 now (8, 8, 15); `POPUP_TEXT` even already.
- [x] Kaiju bar: `KAIJU_LINE` = `OUTLINE_COLOR`; 2 px already.
- [~] Pause strip: `pause_title` and `pause_text` to Bangers, sizes 28 and 16 (already even). Capitals NOT done: it is text (the strings belong to the Narrative Theme Agent), so it needs a text ticket.
- [x] Level-up: `LEVEL_UP_TITLE_OUTLINE_SIZE` 4 to 6; card text outline left (D4: only if the board asks).
- [x] Palette colours that already equal the sheet: nothing to change.

**Tests:** `test_hud_style.gd` now pins the new values (Bangers roles, heat outline 8, near-black popup and kaiju lines, viewers_unit 6, level-up 6); `test_trick_popup_art.gd`, `test_trick_popups_heat.gd`, `test_kaiju_health_bar.gd` were changed to expect the near-black instead of pure black. Godot: the hud set (15 files, 153 tests), the popup set (7 files, 67) and the kaiju bar file (9) all pass. A first full run passed every file up to `test_level_up_offers.gd` except the files fixed above, then hit the 600 s foreground limit and was stopped; I did not get a full-suite count (pause and level-up screen files passed in it). Python: 727 tests OK (1 skipped). The third test set (docs/tools checks) was not run. QA should run the full Godot suite.

**Screenshots** (`art-archive/T-429/screenshots/`): `hud_run_after.png` (the T-428 demo scene, whole HUD), `hud_run_before_d4.png` (D4's before shot, a copy of `art-archive/T-430/screenshots/hud_run_before.png`).

**Docs:** `docs/hud-and-menus.md` (Content, "The HUD's style in code"), `game/docs/hud-and-menus/hud.md`.

**QA round 1:** Criteria 2, 3, 4, 5 pass. Criterion 1 fails (code): D4's list is only partly made (clock digits, weapon icon size, pause capitals not done). Criterion 6 fails (paperwork): no full counts in the notes. `python tools/qa_check.py` was refused (needs approval), so I checked each criterion by hand. The full Godot run went past 600 s; no failures appeared in the files that finished. The docs/tools test set was not run by QA.

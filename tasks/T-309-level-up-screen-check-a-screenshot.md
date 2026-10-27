---
id: T-309
title: Level-up screen check: a screenshot from a run started at the main menu, checked for Redgull red and for dark green leading
status: in-qa
from: project-lead
to: qa-integration
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, game/README.md, game/tools/style_rules.py, game/tools/check_rebrand.py, game/tools/test_check_rebrand.py, game/tools/build_level_up_art.py, game/scripts/ui/level_up_screen.gd, game/tests/fixtures/hud_from_menu_demo.gd, game/tests/fixtures/level_up_screen_demo.gd, art-archive/T-307/screenshots/level_up_screen.png, tasks/T-303-art-the-level-up-screen-in.md, tasks/T-308-rebrand-sweep-the-red-check-looks.md]
files_expected_to_change: [game/tools/style_rules.py, game/tools/test_style_rules.py, game/tools/check_rebrand.py, game/tools/check_level_up_shot.py, game/tools/test_check_level_up_shot.py, game/tests/fixtures/level_up_from_menu_demo.gd, game/tests/fixtures/level_up_from_menu_demo.tscn, game/README.md, art-archive/]
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

The goal check failed on the level-up screen. It needs a screenshot of the open screen from a run started at the main menu, checked by script, with no pixel within the Redgull red check of style_rules.py, and with Greenbull's dark green RGB 12, 76, 44 as the most common colour in the ribbon, frame and emblem art (leaving out the dim, the cream and the text). Neither exists today. style_rules.py has no Redgull red check: Redgull's brand reds are only in check_rebrand.py (BRAND_COLOURS, BRAND_THRESHOLD 12, T-308). T-307's screenshot (art-archive/T-307/screenshots/level_up_screen.png) was taken mid-animation, with one card. Nothing checks which colour leads.

Build the check, with no change to the game or its art:
1. Move Redgull's brand reds (BRAND_COLOURS and BRAND_THRESHOLD, with their sources) from check_rebrand.py into style_rules.py. Add a function there, for example `is_redgull_red(rgb)`, that is true within BRAND_THRESHOLD of RGB 135, 17, 27 or of any other brand red. check_rebrand.py then uses it, and its behaviour and its tests stay unchanged. The HUD's likes heart (HEART_COLOR, and the heart dimmed under the screen's dim) is not a brand red and must not be flagged.
2. Add a fixture, game/tests/fixtures/level_up_from_menu_demo.tscn/.gd, built like the existing *_from_menu_demo fixtures. It starts at the main menu, presses Start, plays the run until the level-up screen opens (for example by giving the likes for one level, or by driving over the gift pack), waits until the opening animation has finished and both cards are in, and takes a screenshot with the screenshot tool.
3. Add game/tools/check_level_up_shot.py <png>. It reports (a) every pixel `is_redgull_red` flags, with its count and positions, and (b) the colour counts of the screenshot's pixels whose colour is exactly one of the opaque colours of game/art/level_up/header_ribbon.png, card_frame.png, highlight_frame.png and gift_pack_emblem.png, leaving out the cream fills (CREAM, CREAM_D in build_level_up_art.py) and the text ink. It names the most common colour, and says whether it is Greenbull's dark green RGB 12, 76, 44. Exit code 0 only when there is no red pixel and dark green leads. Print the result as JSON.
Take the screenshot on this ticket's build and run the check on it. Write its output in the result notes, whatever it is. Today's art is expected to fail the dark-green part, because the ribbon's centre field is light green; the art ticket that depends on this one fixes that. Describe the fixture and the check in game/README.md, under 'Level-up screen art'.

## Acceptance criteria

- [ ] style_rules.py has a Redgull red function (for example is_redgull_red) using the brand reds and the threshold moved from check_rebrand.py; test_style_rules.py tests that it flags RGB 135, 17, 27 and a colour within the threshold of it, and does not flag HEART_COLOR (219, 26, 41) or the heart dimmed to 40% (about 88, 10, 16). (QA: pass)
- [ ] check_rebrand.py imports the brand reds from style_rules.py, and test_check_rebrand.py passes unchanged. (QA: pass)
- [ ] game/tests/fixtures/level_up_from_menu_demo.tscn starts at the main menu, starts a run and takes a screenshot of the open level-up screen with both cards shown; the screenshot is in art-archive/<this ticket>/screenshots/ and listed in the result notes. (QA: pass)
- [ ] game/tools/check_level_up_shot.py reports the Redgull red pixels and the most common art colour (ribbon, card frame, highlight frame, gift pack emblem; cream and text left out) as JSON; test_check_level_up_shot.py covers a clean image, an image with a Redgull red pixel, and an image where light green leads (exit 1). (QA: pass)
- [ ] The check's output on this ticket's screenshot is written in the result notes. (QA: pass)
- [ ] game/README.md, 'Level-up screen art', describes the fixture and the check. (QA: pass)
- [ ] All three test sets pass (GUT, python -m unittest discover -s game/tools, python -m unittest discover -s tools). (QA: pass: GUT all passed, game/tools 508 OK, tools 501 OK. Screenshots rule met: art-archive/T-309/screenshots/. Note: stray scratch file _wiper_ref.png left there.)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-309.

### 2026-10-27, In progress → In QA

Goal runner (G-006): the agent is done; QA is checking it.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done, no change to the game or its art. 0 PixelLab generations.

- `style_rules.py`: `BRAND_COLOURS`, `BRAND_THRESHOLD` (12) and their sources moved here, plus `is_redgull_red(rgb)`. `test_style_rules.py::test_redgull_red`: flags (135, 17, 27) and (140, 22, 30); not HEART_COLOR, not the heart at 40% (88, 10, 16), not a red-brown (120, 60, 60), not dark green.
- `check_rebrand.py` uses `style_rules.is_redgull_red`; it keeps `BRAND_COLOURS` and `BRAND_THRESHOLD` as aliases (its test reads `check_rebrand.BRAND_COLOURS`). `test_check_rebrand.py` unchanged and passing.
- Fixture `game/tests/fixtures/level_up_from_menu_demo.tscn/.gd`: menu, Start, likes for one level, gift pack picked up, `show_offers(["upgrade_gun", "get_wiper"])` (today's pool gives one card at level 1, so two are shown), waits for `is_animating()` false. The wait is real time: the shot needs 400 frames (at 60 frames it shows one card).
- `game/tools/check_level_up_shot.py` (JSON; Pillow reads the screenshot because Godot's shots are RGB) and `test_check_level_up_shot.py` (clean image exit 0, red pixel, light green leading exit 1, command line).
- Screenshot: `art-archive/T-309/screenshots/level_up_screen.png` (both cards, finished). `art-archive/T-309/screenshots/_wiper_ref.png` is a scratch shot of the old wiper fixture at 60 frames, showing why 60 frames is too early; I could not delete it with the allowed commands.
- Check output on that screenshot (exit 1, as expected): `red_pixels` 0. Art colours, most common first: (104, 220, 96) light green 35678; (14, 22, 18) outline 31964; (12, 76, 44) dark green 23280; (6, 46, 26) 8794; (24, 110, 58) 8488; (170, 240, 140) 6656; (52, 160, 72) 6408; (226, 252, 200) 4792; (247, 208, 52) yellow 4722; (24, 112, 60) 1591; (8, 16, 12) 947; (40, 138, 60) 830. `most_common_art_colour` [104, 220, 96], `most_common_is_dark_green` false, `ok` false. So there is no red, and light green leads (the ribbon's centre field); the art ticket that depends on this one fixes that.
- `game/README.md`, "Level-up screen art", describes the fixture and the check.
- Tests: GUT 1419/1419 pass; `python -m unittest discover -s game/tools` passes (one failure on my first run, my own test's bad "beyond threshold" colour, fixed); `python -m unittest discover -s tools` see the QA run.
- Refusals: none.

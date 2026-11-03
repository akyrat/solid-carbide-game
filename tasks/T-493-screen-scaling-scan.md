---
id: T-493
title: A scan of every screen at several resolutions that lists what doesn't scale
status: done
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/tools/screen_gallery.py, game/tools/screen_gallery.gd]
files_expected_to_change: [game/tools/, docs/hud-and-menus.md]
model: sonnet
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

The board, 2026-11-02 (HUD and menus, Decisions, "Every screen scales with the window"): the gift pack (level-up) screen and the pause screen look very small on big resolutions; run a game-wide scan to find everything that doesn't scale.

Extend the screen gallery (T-479, `game/tools/screen_gallery.py`) with a `--sizes` option that captures every screen it already reaches at 1280 x 720, 1920 x 1080, 2560 x 1440, 3840 x 2160 and 3440 x 1440 (the window really at that size, or the root viewport resized; say which). For each screen it measures the share of the window its visible content covers (for example the bounding box of its visible Controls, or of non-background pixels), compares it with 1280 x 720, and writes a report (`scaling_report.md` plus JSON) listing each screen and piece that shrinks as the window grows, worst first, with a side-by-side contact sheet per screen across the sizes. Run it on master and put the report and the contact sheets in art-archive/T-NNN/ (the fix ticket reads them). It should take minutes, not hours.

The board reviews in the Project Lead's swipe deck: no QA agent round. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `python game/tools/screen_gallery.py --sizes` captures every reachable screen at the five sizes; the result notes give the time it took. (QA: pass; no QA agent, the board reviewed in its swipe deck 2026-11-02; Project Lead check: 19 screens x 5 sizes, 94 s in the result notes)
- [ ] The report lists every screen with its coverage at each size against 1280 x 720 and flags the ones that shrink; the level-up and pause screens are among them if they still don't scale. (QA: pass; scaling_report.md flags 16 of 19, level_up_gift_pack 0.29 and pause_screen 0.50 among them)
- [ ] Contact sheets per screen across the sizes are saved under art-archive/T-NNN/ and listed in the result notes. (QA: pass; 19 sheets in art-archive/T-493/contact_sheets/, shown to the board in the deck)
- [ ] Python tests cover the report's coverage maths and flagging (game/tools set). (QA: pass; test_scaling_report 9 OK, run by the Project Lead)
- [ ] docs/hud-and-menus.md (Content, "The MVP pass") says how to run the scan. (QA: pass; "Scaling scan (T-493)" bullet)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass; no such path in the branch diff)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

From the board's playtest: scanning every screen at five resolutions for what doesn't scale. UI agent started.

### 2026-11-02, In QA

Scan done (16 of 19 screens flagged); its results are the before pictures in the swipe deck.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Scan built: game/tools/screen_gallery.py --sizes (one Godot run per size, root window resized via --resolution + --size; screen_gallery.gd now records each screen's visible content Controls) and game/tools/scaling_report.py (maths, report, contact sheets). Run on master's code: 19 screens x 5 sizes took 94 s. 3840x2160 is clamped to 3840x2130 by the 2560x1440 monitor (maths uses the real size). Report: art-archive/T-493/scaling_report.md + scaling_report.json; 19 contact sheets in art-archive/T-493/contact_sheets/<screen>.png. FLAGGED (worst ratio of coverage vs 1280x720, 16 of 19): main_menu 0.11, recap_win 0.21, recap_time_up 0.23, recap_wreck 0.23, power_up_overlay 0.26, level_up_gift_pack 0.29, pause_trick_list 0.46, pause_screen 0.50, pause_hud_layout_editor 0.69, garage 0.74 (only on 3440x1440 ultrawide), HUD screens (hud_run_start, hud_mission_page, hud_trick_popup, hud_combo_broken, time_up_screen, wreck) 0.74 (only ultrawide; HUD holds ~1.0 on 16:9, so it is the aspect effect, lowest priority). Not flagged: tutorial slides 1-3 (full-screen). Menu, recap, power-up, level-up and pause pieces keep fixed pixel sizes, so they shrink with the window area. Tests: python -m unittest game.tools.test_scaling_report game.tools.test_screen_gallery, 13 OK. Docs: docs/hud-and-menus.md (Scaling scan bullet). Nothing under game/data/levels touched. Per-size PNG folders deleted (regenerable in about 90 s).
- 2026-11-02, in-progress → in-qa: Scan report ready
- 2026-11-02, in-qa → done: Approved in the board's swipe deck (tooling)

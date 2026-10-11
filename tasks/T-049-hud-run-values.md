---
id: T-049
title: HUD: likes bar and level, health, coins
status: done
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-037, T-048, T-090]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-036-run-scene-and-state.md, tasks/T-037-likes-and-levels.md, tasks/T-048-text-hud.md, game/README.md]
files_expected_to_change: [the HUD scene and script, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-037 (likes and levels) and T-090 (the HUD with the timer) are done.** T-048's text is done.

Add the rest of the HUD to T-090's (which already shows the timer), as HUD and menus, Decisions describes it, kept plain for the MVP. It only displays values; the run (T-036, T-037) owns them.
- The car's health as a bar.
- The likes bar (XP shown as likes) and the current level.
- The coins collected this run.

Use exactly T-048's text. If T-048 chose a heart icon for likes, use a placeholder shape until its art task delivers it. Propose a first layout; the board adjusts it in playtests (HUD and menus, Decisions). The arrow to the nearest challenge and the kaiju's health bar are T-050.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test changes each run value (health, XP and level, coins) and shows the HUD shows the new value (QA: pass)
- [x] A test shows every label on the HUD is exactly T-048's text (QA: pass)
- [x] A screenshot of a run shows the HUD with all its parts (QA: pass)
- [x] `docs/hud-and-menus.md` describes the layout in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

Built the rest of the HUD in `game/scripts/hud/hud.gd`: top left the "Car Health" bar, then a likes row (placeholder Redgull-red heart, "Likes", "Hype Lv {level}") over the likes bar; top right "Coins" with the count; the timer stays at the top centre. All follow the run state's `health_changed`, `xp_changed` and `coins_changed`; the likes bar stays full at the top level. Room is kept right of the likes row for the combo counter (T-081). Texts are T-048's final ones ("Coins", not "Brand Coins").

Tests: `game/tests/unit/hud/test_hud_values.gd` (7 tests: each value changes, fresh run resets, max level, exact labels, heart is the only red). Full GUT suite passes (256 tests), Python tool tests pass (67). Screenshot of a run started from the main menu (fixture `game/tests/fixtures/hud_from_menu_demo.tscn`) checked: all parts show, nothing overlaps the timer.

Documents updated: `docs/hud-and-menus.md` (Content only), `game/README.md`.

### QA round 1

- [x] Values update test: pass. Seven tests in test_hud_values.gd change health, XP/level, coins and a restart, and the HUD follows each.
- [x] Labels exactly T-048's text: pass. "Car Health", "Likes", "Hype Lv {level}", "Coins" (not "Brand Coins") match T-048's approved table; the test asserts them.
- [x] Screenshot with all parts: pass. My own screenshot of a run started from the main menu (hud_from_menu_demo, game.tscn) shows the health bar, red heart with "Likes" and "Hype Lv 2", the purple likes bar and "Coins 37"; the timer is clear of all of them and the trick-popup and pause-strip areas are empty. Only the heart is red.
- [x] docs/hud-and-menus.md: pass. `git diff master...HEAD` changes only one paragraph in Content (The HUD).
- [x] Full GUT suite and Python tests: pass. GUT 256/256, `tools` 75 OK, `game/tools` 67 OK.

### Board review

Merged on QA's pass, 2026-10-11.

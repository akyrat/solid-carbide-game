---
id: T-351
title: Reaction icons burst out on a sub goal and float up at high viewer counts
status: in-qa
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-336, T-337]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md, game/scripts/hud/, game/data/viewers.json]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/data/hud.json, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-351/]
model: sonnet
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

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28): like a real livestream, little **reaction icons** (likes, thumbs up, hearts and similar) fly up the screen. Two moments:

1. **A burst on a sub goal:** when the sub goal is reached and the gift pack comes (T-337), a **burst** of reaction icons pops out, all at once, from the sub goal square.
2. **Floating up at high viewer counts:** while the live viewers count is high, reactions **float up from the bottom of the screen**, **intermittently and regularly, like a real stream**: a few at a time, at uneven gaps, never a constant stream. The higher the viewer count, the more often (a proposal: none below the first heat step, a trickle at 20K, more at each heat step, the most from 1M; the numbers go in `game/data/hud.json`, proposals for the playtest).

**They must not get in the way of playing** (the board): small, partly transparent, kept to the edges and the bottom of the screen where they can (a proposal: drifting up along the left and right thirds and fading out before the middle), never over the car, always drawn under the HUD pieces, with a cap on how many are on screen at once (a proposal: 12). Each icon drifts up with a little sideways wobble and fades out. Pause freezes them; a new run clears them.

**The icons:** placeholders drawn in code first (simple pixel hearts and thumbs up in a few colours, none in Greenbull's colours outside Greenbull's things, Visual style, Content, "Rules"). T-352 makes the final art; if its icons are in the branch you start from, use them. No new text.

The board's review: play a run: hit a sub goal and see the burst; build the viewers up and see the icons float up now and then, without hiding the road.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Reaching the sub goal starts a burst of reaction icons from the sub goal square, once per goal (test). (QA: pass)
- [ ] Reactions float up from the bottom at the live viewers count's rate: none below the first step, more often at each higher step, at uneven gaps; the rates are in `game/data/hud.json` (tests with a fixed seed). (QA: pass)
- [ ] At most the cap are on screen at once, they are partly transparent, drawn under the HUD pieces, and none start over the car's position in the middle of the screen (tests). (QA: pass)
- [ ] Pause freezes them and a new run clears them (tests). (QA: pass)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass)
- [ ] Screenshots, and a GIF of the burst and of the floating icons, are in `art-archive/T-351/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Blocked → In progress

Started from the playtest build (T-336 and T-337 approved).

### 2026-10-28, Needs playtest → In progress

Sent back for the board's tweak: more reactions, more noticeable, rising like a real livestream's. Quick tuning in this folder.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built by the UI Agent. `game/scripts/hud/reactions.gd` (`Reactions`, `hud.reactions`): the Hud's first child so every HUD piece draws over it; placeholder pixel hearts and thumbs up drawn in code (pink, orange, violet, white; none cyan, heart red or Greenbull). Burst: 10 icons out of the sub goal square's centre from `Hud._on_level_up()` (once per goal). Floaters: groups of 1 to 3 from below the bottom edge in the left or right third, uneven gaps, rate by the viewers counter's look step (`rates_per_second` [0, 0.2, 0.4, 0.7, 1.2]: none below 20K). Cap 12, alpha 0.7, pausable, `Hud.bind()` clears. All numbers (proposals) in `game/data/hud.json` `reactions`. Burst speeds were raised to 200 to 420 px/s after the first screenshot showed the icons hiding behind the square. No T-352 art in the branch, so none used; no new text, no PixelLab.

Documents: docs/hud-and-menus.md (Content, new bullet), game/docs/hud-and-menus/hud.md (new section, since game/README.md is now an index).

Tests: new `tests/unit/hud/test_hud_reactions.gd` (17). Full runs: GUT 1803/1803 passed (147 scripts); `python -m unittest discover -s game/tools` 645 OK (1 skipped); `python -m unittest discover -s tools` 545 OK.

Screenshots and GIFs (`bash game/tools/record_reactions.sh`, fixture `tests/fixtures/reactions_demo.tscn`): `art-archive/T-351/screenshots/reactions_burst.png`, `reactions_float.png`, `reactions_burst.gif`, `reactions_float.gif` (the float GIF steps the viewer step 0 to 4 every 3 s). The floaters are faint at 0.7 alpha on the grey road; the board may want a different alpha or bigger icons.

QA (round 1): all 7 criteria pass. qa_check: tests PASS (3 sets; counts per the builder: GUT 1803, game/tools 645, tools 545), screenshots PASS (4 files, viewed: burst and floaters visible, car clear). The documents line failed only because game/README.md is now an index; its content is in game/docs/hud-and-menus/hud.md, counted as the README criterion per the Project Lead. 17 new tests cover burst once per goal, rates per step, cap, alpha, draw order, lanes, pause, new run.
Quick tuning (board, 2026-10-28; its first message was garbled by dictation, corrected to: "floating up from anywhere at the bottom of the screen, because that's how Instagram, Facebook, TikTok lives do it", chosen option "Anywhere along the bottom ... busier and more noticeable ... They would pass by the car"): merged `playtest/livestream-hud` first (T-338's heart row; clean merge). Floaters now start at a random x across the whole bottom edge (no thirds, no keep-off-the-car rule), 1 or 2 at a time at uneven gaps, rise to near the top with sway, a scale pop (0.5 to 1 over 0.25 s) and fade out from 55 percent of their life. Rates per look step [0, 2, 3.5, 5, 7.5] groups per second (none at the base step, a lively flow from the first heat step, a real stream at fire); alpha 0.9, icon_scale 4 (was 3), cap 60 (was 12). The burst is unchanged. New keys in `hud.json` `reactions`: `edge_margin`, `fade_out_from`, `pop_seconds`, `pop_from` (the lane keys are gone). Tests updated (19 in `test_hud_reactions.gd`: whole-width spawn, flow at the first heat step, none below it, sway up to near the top, the pop). Docs: `docs/hud-and-menus.md` (the bullet says the board's choice replaces the thirds and the off-the-car rule) and `game/docs/hud-and-menus/hud.md`. Full runs: GUT 1812/1812 (148 scripts), `game/tools` 645 OK, `tools` 545 OK. Screenshots retaken: `art-archive/T-351/screenshots/reactions_float.png` and `.gif` (burst files regenerated too, same behaviour). The numbers are proposals for the playtest.

Quick tuning 2 (board, 2026-10-28: "i want them to float up faster"): floaters' `rise_min` and `rise_max` in `hud.json` doubled, 90 to 160 becomes 180 to 320 px per second (also the `DEFAULT_CFG` in `reactions.gd`). A floater's life is 92 percent of the screen height over its speed, so they still climb to near the top and fade the same way, in about half the time. No test pinned the speeds. Full runs: GUT 1812/1812, `game/tools` 645 OK, `tools` 545 OK. `art-archive/T-351/screenshots/reactions_float.gif` retaken.

Quick tuning 3 (board, 2026-10-28: "it doesn't look good to be all over the screen. Make it so that it only floats up from the side of the screen where the view count is at."): floaters now start below the bottom edge at a random x in a right-side lane over the viewers counter, 0.76 to 0.99 of the screen width (about x875 to 1140 at 1152), set by `lane_from` and `lane_to` in `hud.json` `reactions` (they replace `edge_margin`), and rise up the right side with the same sway, never into the middle. Speed, size, alpha, rates and cap kept (the cap of 60 is now never reached in the lane at these rates). The burst is unchanged. Tests: the whole-width spawn test became a right-side-lane test, plus a new test that floaters never drift left of 0.7 of the width (20 in `test_hud_reactions.gd`). Docs: `docs/hud-and-menus.md` (the right side replaces "anywhere along the bottom") and `game/docs/hud-and-menus/hud.md`. Full runs: GUT 1813/1813, `game/tools` 645 OK, `tools` 545 OK. Screenshots retaken: `reactions_float.png` and `.gif`.

- 2026-10-28, needs-playtest → in-progress: The board: I think there aren't enough reactions floating up. I didn't want them to be floating up from anywhere at the bottom of the screen towards the top. I want to look more like a live stream when you get live interactions, and the reactions kind of float up. They're too discrete at the moment for me to make them a bit more noticeable. Other than that, everything is okay.
- 2026-10-28, in-progress → in-qa: Ready for the board to play (quick tuning)

QA (round 2, final, after quick tuning 1 to 3, board approved "351 lgtm"): all 7 criteria pass. qa_check: tests PASS (3 sets), screenshots PASS (4 files); the documents line fails only because game/README.md is an index (content in game/docs/hud-and-menus/hud.md and docs/hud-and-menus.md, counted per the Project Lead). Criterion 3 judged against the board's changes: floaters start below the bottom edge in the right-side lane (0.76 to 0.99 of the width; tests: lane, never the middle), alpha 0.9 (below full), cap 60 held (test), drawn under every HUD piece (test). Criteria 1, 2, 4 covered by tests: burst once per goal, rates per step with a fixed seed and uneven gaps, pause and new run.

---
id: T-351
title: Reaction icons burst out on a sub goal and float up at high viewer counts
status: needs-playtest
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

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built by the UI Agent. `game/scripts/hud/reactions.gd` (`Reactions`, `hud.reactions`): the Hud's first child so every HUD piece draws over it; placeholder pixel hearts and thumbs up drawn in code (pink, orange, violet, white; none cyan, heart red or Greenbull). Burst: 10 icons out of the sub goal square's centre from `Hud._on_level_up()` (once per goal). Floaters: groups of 1 to 3 from below the bottom edge in the left or right third, uneven gaps, rate by the viewers counter's look step (`rates_per_second` [0, 0.2, 0.4, 0.7, 1.2]: none below 20K). Cap 12, alpha 0.7, pausable, `Hud.bind()` clears. All numbers (proposals) in `game/data/hud.json` `reactions`. Burst speeds were raised to 200 to 420 px/s after the first screenshot showed the icons hiding behind the square. No T-352 art in the branch, so none used; no new text, no PixelLab.

Documents: docs/hud-and-menus.md (Content, new bullet), game/docs/hud-and-menus/hud.md (new section, since game/README.md is now an index).

Tests: new `tests/unit/hud/test_hud_reactions.gd` (17). Full runs: GUT 1803/1803 passed (147 scripts); `python -m unittest discover -s game/tools` 645 OK (1 skipped); `python -m unittest discover -s tools` 545 OK.

Screenshots and GIFs (`bash game/tools/record_reactions.sh`, fixture `tests/fixtures/reactions_demo.tscn`): `art-archive/T-351/screenshots/reactions_burst.png`, `reactions_float.png`, `reactions_burst.gif`, `reactions_float.gif` (the float GIF steps the viewer step 0 to 4 every 3 s). The floaters are faint at 0.7 alpha on the grey road; the board may want a different alpha or bigger icons.

QA (round 1): all 7 criteria pass. qa_check: tests PASS (3 sets; counts per the builder: GUT 1803, game/tools 645, tools 545), screenshots PASS (4 files, viewed: burst and floaters visible, car clear). The documents line failed only because game/README.md is now an index; its content is in game/docs/hud-and-menus/hud.md, counted as the README criterion per the Project Lead. 17 new tests cover burst once per goal, rates per step, cap, alpha, draw order, lanes, pause, new run.

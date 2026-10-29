---
id: T-356
title: Bad reactions burst out when the combo breaks
status: done
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/reactions.gd, game/data/hud.json]
files_expected_to_change: [game/scripts/hud/, game/data/hud.json, game/tests/unit/hud/, game/docs/hud-and-menus/hud.md, docs/hud-and-menus.md, art-archive/]
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

The board's decision (HUD and menus, Decisions, "Bad reactions when the combo breaks", 2026-10-29): when a crash cuts the combo (the moment the COMBO BROKEN! popup shows and the live viewers counter flashes red, T-336), the stream reacts badly: a **burst of bad reactions** rises from the live viewers counter, in the same lane as T-351's floating reactions (the right side, over the counter's width, never into the middle). Six bad reactions: a **crying-laughing face**, a **thumbs down** (a dislike), a **face peeking between its hands**, and the Project Lead's three (the board left them to it): a **broken heart**, a **skull** and a **screaming face**. Proposals for the playtest, in `game/data/hud.json`: about 10 icons in a quick flow over about 1.5 seconds, a mix of the six, rising a little faster than the good floaters, same size and alpha as T-351's icons. Only a crash that cuts the combo starts it (the combo draining away doesn't, the same rule as the counter's red flash). Pause freezes them; a new run clears them; they count toward the on-screen cap.

**The icons:** placeholders drawn in code first (simple pixel shapes in the right colours; none of Greenbull's colours, Visual style, Content, "Rules", rule 6). The art is the linked art ticket, which swaps its icons in. No new text.

The board's review: play a run, build a combo and crash: the bad reactions burst up from the viewers counter.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A crash that cuts the combo starts a burst of bad reactions from the viewers counter's lane, once per crash; the combo draining away doesn't (tests). (QA: pass)
- [ ] The burst mixes the six bad reactions, and its count, spread and speed come from `game/data/hud.json` (tests with a fixed seed). (QA: pass)
- [ ] They start only on the right side over the viewers counter, are drawn under the HUD pieces, count toward the cap, freeze on pause and clear on a new run (tests). (QA: pass)
- [ ] HUD and menus, Content and game/docs/hud-and-menus/hud.md describe it. (QA: pass)
- [ ] A screenshot and a GIF of the burst after a crash are in `art-archive/<id>/screenshots/` and show the bad reactions rising on the right. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started overnight (build A, Stream reacts): the UI Agent is making the bad reactions burst when a crash cuts the combo, with placeholders.

### 2026-10-29, In QA → Needs playtest

QA passed. Ready to play in build A (Stream reacts) with placeholder icons; the art (T-357) can only start once you've approved this one.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

### UI Agent, 2026-10-29

Built. `Hud._on_combo_broken()` (the `combo_broken` signal, same moment as the popup and the counter's red flash, so a cut only, not the drain) calls new `Reactions.bad_burst(y)` with the viewers counter's centre height. 10 entries are queued in `pending_bad` and start over about 1.5 s (in `advance()`, so pause freezes them) at random x in the lane_from..lane_to lane, rising 260..420 px/s, living 1.4..2 s, through `_add()` (cap). Kinds past `ICONS.size()` index `BAD_ICONS`: six script-drawn 16 x 16 placeholders (crying-laughing face, thumbs down, face peeking between hands, broken heart, skull, screaming face; none in Greenbull's colours) in `game/art/hud/reaction_*.png`, built by `game/tools/build_hud_reaction_icons.py` (`BAD_NAMES`); T-357 swaps the PNGs. Numbers: `game/data/hud.json` `reactions.bad_*`. Same size and alpha as the good icons.

Tests: 8 new in `game/tests/unit/hud/test_hud_reactions.gd` (numbers, count/lane/rise, six-kind mix and same-seed repeat, count from data, cap, pause and new run, cut starts one and drain none and from the counter's height). Python icon test updated for 12 icons.
Test counts: game/tools unittest 657 OK (1 skipped); tools unittest 560 OK; GUT 148 scripts, 1824 tests, all passing.
Screenshot and GIF: `art-archive/T-356/screenshots/reactions_bad.png` and `.gif` (via `record_reactions.sh`, new `bad` mode and fixture modes `bad_still`, `bad_gif`).
Docs updated: `docs/hud-and-menus.md` (Content), `game/docs/hud-and-menus/hud.md`. Placeholder art look is rough (faces are orange blobs); T-357 is the real art.

### QA, 2026-10-29 (round 1)

All pass; held in in-qa for T-357. qa_check: tests (3 sets) PASS, documents PASS, screenshots PASS. Criteria 1-3: the 8 new GUT tests in test_hud_reactions.gd cover cut vs drain, six-kind mix with fixed seed, data-driven numbers, lane, cap, pause, new run; GUT suite green. Criterion 4: Content in docs/hud-and-menus.md and game/docs/hud-and-menus/hud.md describe it. Criterion 5: reactions_bad.png shows COMBO BROKEN! with bad icons (broken heart, scream face) on the right over the counter lane; GIF present. Criterion 6: counts as reported by the agent, check green.
- 2026-10-29, needs-playtest → done: The board played build A: LGTM (2026-10-29).

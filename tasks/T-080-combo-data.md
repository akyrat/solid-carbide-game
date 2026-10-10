---
id: T-080
title: Combo numbers: what each trick adds, the drain, and how the combo raises spawning
status: needs-playtest
from: project-lead
to: game-data
epic: game-loop
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-038]
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, docs/hud-and-menus.md, docs/enemies.md, tasks/T-038-run-and-likes-data.md, game/README.md]
files_expected_to_change: [JSON data under game/data/, tests, docs/game-loop-architecture.md, game/README.md]
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

**Blocked until T-038 (the data convention and the likes numbers) is done.**

Work out the combo's numbers within Game loop architecture and Enemies, Decisions, as JSON under `game/data/`:
- The starting multiplier (no combo), and how much each trick adds: extended drift a little, a 360 more, an alternate drift the most. Decide whether the multiplier has a maximum.
- The cut on a collision is 80% (decided). How "cut by 80%" applies to the multiplier (for example to the part above the starting value): say which.
- The drain: after 2 seconds with no trick (decided), how fast the combo falls back.
- How strongly the combo raises minion spawning (Enemies, Decisions).

Explain the numbers in the result notes, with an example: a minute of good driving and what multiplier it reaches. The board judges them in playtests.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] The data is valid JSON under `game/data/`, and a test loads it through T-038's loader (QA: pass / fail)
- [ ] A test shows an alternate drift adds more than a 360, and a 360 more than an extended drift (QA: pass / fail)
- [ ] The data holds the 80% cut and the 2-second wait as given, and the result notes explain every other number with the example (QA: pass / fail)
- [ ] `docs/game-loop-architecture.md` points to the data in References, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Proposed numbers (all in `game/data/combo.json`, read through `game/scripts/data/combo_data.gd`; the board judges them in playtests):

- Start multiplier 1.0 (no combo). Maximum 6.0, so XP can at most sextuple and spawning stays bounded.
- Each trick adds: extended drift +0.05 (per second of drift), 360 +0.25 (720 = two), alternate drift +0.5 per switch. That is 1 : 5 : 10, so the order is extended < 360 < alternate.
- Collision cut 80% and wait 2 s are as decided. The cut applies to the part above the start value: new = 1 + (m - 1) x 0.2. So 5.0 becomes 1.8, and a combo of 1.0 stays 1.0 (never below the start).
- Drain: after the 2 s wait, 0.5 per second, down to 1.0. A combo of 4.0 left alone takes 6 s to fall to 1.0, which is quick but lets a short pause survive.
- Spawning: +0.15 on the minion spawn rate for each multiplier point above 1.0, capped at x1.75, with an `enabled` switch (Enemies: it can be switched off). Combo 3.0 gives x1.3, combo 5.0 gives x1.6, combo 6.0 gives x1.75.

Example, a minute of good driving: drifting about 40 s with a trick every 2 to 3 s. Per 10 s: about 6 s of extended drift (+0.30), one 360 (+0.25), two alternate switches (+1.0), total about +1.5 per 10 s, minus almost no drain because tricks keep coming. The multiplier passes 3 after about 13 s, reaches about 5 near 27 s and sits near the 6.0 cap for the rest of the minute, so XP flows at roughly 4 to 6 times and spawning at about x1.6 to x1.75. Plain extended drifting alone (+0.05 per second) only reaches about 1.5 to 2 after a minute, and a collision at 5.0 drops it to 1.8. If the board finds it too easy to hit the cap, lower `max_multiplier` or the alternate add; both are single numbers.

Tests: `game/tests/unit/test_combo_data.gd` (loader, trick order, 80% and 2 s values, cut, cap, drain, spawning). GUT: 106 of 106 pass. Python tool tests: 3 failures/errors, all in `test_build_mvp_map` (KeyError 'boulders'), in the map tool this task does not touch; not caused by this work.

Documents changed: `docs/game-loop-architecture.md` (one line in References only), `game/README.md` (typed readers and tests lines).

### QA round 1

- Criterion 1 (valid JSON, test loads through T-038's loader): PASS. `combo.json` parses; `test_loads_through_loader` uses `GameData.load_file("combo")` and `ComboData.is_ok()`.
- Criterion 2 (alternate drift > 360 > extended drift): PASS. `test_trick_order` asserts 0.5 > 0.25 > 0.05 > 0.
- Criterion 3 (80% cut and 2 s wait as given; other numbers explained with the example): PASS. `collision_cut` 0.8 and `drain_wait_seconds` 2.0 match Game loop architecture, Decisions, and are asserted in `test_decided_values`. Start, cap, trick adds, cut application, drain and spawning are all explained in the result notes. The arithmetic checks out (6.0 cap, 5.0 cut to 1.8, 4.0 drains to 1.0 in 6 s, combo 5.0 gives x1.6, 6.0 gives x1.75; the minute example's ~+1.55 per 10 s is consistent). One small inconsistency, not a failure: the note says plain extended drifting alone reaches "about 1.5 to 2" after a minute, but 40 s of drift at +0.05 per second is +2.0, so about 3.0 unless drain gaps are assumed. The board judges the numbers in playtests.
- Criterion 4 (docs/game-loop-architecture.md only gains a References line): PASS. `git diff master...HEAD` shows one added line in References; Summary, Decisions and Open questions are unchanged.
- Criterion 5 (full GUT suite and all Python tool tests): PASS. GUT: 106 of 106 pass (TESTS PASSED). `tools` Python tests: 72 OK. `game/tools` Python tests: 51 run, 3 fail/error, all in `test_build_mvp_map` (KeyError 'boulders' twice, `12 != 6` once). The same 3 fail identically on master (checked in the main checkout), so this is the known pre-existing issue tracked in T-087 and not caused by this task. Counted as a pass because every other test passes.

Result: all criteria pass. Status set to needs-playtest.

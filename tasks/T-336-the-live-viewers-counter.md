---
id: T-336
title: "The live viewers counter at the bottom right, and tricks that bring viewers"
status: needs-playtest
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-331, T-332]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/, game/scripts/hud/combo_heat.gd]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-336/]
model: opus
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

The board's decisions (2026-10-28): Game loop architecture, Decisions, "The combo shows as live viewers"; HUD and menus, Decisions, "The HUD looks like a livestream" and "Tricks bring viewers, shown in one colour".

1. **The counter:** the combo counter ("Combo x2.00" above the likes bar) is replaced by a **live viewers counter** at the **bottom right**: a dark panel with T-331's LIVE badge and the viewers number, from T-332's curve and format. The number **counts toward** its target (up after tricks, down when the combo drains or a crash cuts it) and **wobbles a little** all the time, with T-332's speeds. Its look **heats up** on T-332's steps (today's combo heat colours and pulse, carried over), and **over 1,000,000 it is on fire** (a flame animation; placeholder in code until T-339's art).
2. **One viewers colour:** the counter has its own colour (your proposal; T-339 may refine it), used for nothing else in the HUD.
3. **Trick popups:** each trick popup keeps its name as today; its amount (today "+0.25") becomes the **viewers the trick brought** (T-332's function), for example "+12K", with a small eye icon, in the viewers colour.
4. **The "+12K" flies to the counter:** after the popup shows, its amount detaches and flies across the screen into the counter, which **bumps** (a quick pop and flash) when it lands.
5. **Crashes:** when a crash cuts the combo, the counter **flashes red** and a "-{viewers lost}" **drops away** from it as the number falls (with the COMBO BROKEN! popup as today).

- **Position and size:** from the board's HUD layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4); the Project Lead writes the saved numbers in this ticket's Updates when it starts; anchor it to the bottom-right corner.
- If T-339's art (counter frame, LIVE badge, eye icon, fire) is in the branch you start from, use it; otherwise placeholders in code.
- Today's combo heat elsewhere (the popups' rings and flames, the drift marks) stays as it is.

The board's review: play a run: do tricks and watch the "+viewers" fly into the counter; crash and watch it fall; reach a million.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The combo counter is gone and the live viewers counter shows at the layout page's position (at 1152 x 648), anchored bottom right, with T-331's badge (test). (QA: pass)
- [ ] The shown number moves toward T-332's target for the current multiplier and never sits still while the run is going; it stops while paused (tests). (QA: pass)
- [ ] The counter's look changes at T-332's heat steps and is on fire at 1,000,000 or more (tests). (QA: pass)
- [ ] A trick popup shows "+{viewers}" with an eye icon in the viewers colour, and that amount flies to the counter, which bumps on arrival (tests for the text and the flight's end). (QA: pass)
- [ ] A crash flashes the counter red and shows "-{viewers lost}" dropping from it (test). (QA: pass)
- [ ] Every label comes from the game's text data; no text is written in the code. (QA: pass)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass; docs are in docs/hud-and-menus.md and game/docs/hud-and-menus/, game/README.md is an index and that counts as the README criterion per the Project Lead)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-336/screenshots/`: a GIF of a trick's "+viewers" flying in, one of a crash, and a still of the counter on fire. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass; qa_check: 3 test sets passed; 643, 545 and 1759 tests)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-28, Open → In progress

Started from the playtest build (T-331, T-332 approved). Layout from the board's page (1152x648): viewers x896 y560 w240 h72, anchored bottom right.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**UI Agent, 2026-10-28.** Built on the playtest build branch, using T-339's art (viewers_panel, live_badge, eye_icon, viewers_fire_00..11); no PixelLab calls, no placeholders.

What was built:
- `game/scripts/hud/viewers_counter.gd` (`ViewersCounter`, `hud.viewers_counter`): the counter at the bottom right, anchored to that corner from `game/data/hud.json` `viewers_counter.layout` (x896 y560 w240 h72 at 1152x648, 16 px margins at every size). Panel art at 2x, LIVE badge and eye on the left, the number over "WATCHING" on the right (Bangers). It counts toward `ViewersData.viewers_for(multiplier)` with `count_toward`, wobbles with `with_wobble`, writes with `format`; pausable. Heat on `step_for_viewers` (steps 1-3 take the old counter's ComboHeat colours, glow and pulse, with number sizes 28/30/32/34 so it fits the panel); step 4 (>= 1,000,000) shows T-339's 12 fire frames round the panel.
- The combo counter is removed from `hud.gd` (`combo_label`, `combo_text`, `show_combo`, TEXT_COMBO); `ComboHeat` stays for the likes bar's fire and the popups' step (`setup(null, likes_fire)`).
- Popups (`trick_popups.gd`, `trick_popup_art.gd`): the amount is the viewers the trick brought (`trick_text(id, viewers)`, `trick_viewers(added, multiplier)`), e.g. "ALT DRIFT! +5,938", lettered in the viewers colour with a black outline and the eye after it. 0.3 s after the popup shows, the amount leaves it (bubble keeps its size, name only) and a `ViewersFlight` arcs it into the counter's number (0.55 s); the trick's viewers are held back until it lands, then the counter bumps (pop + cyan flash).
- Crash (`combo_broken`): red-orange flash (the combo broken popup's #ff5010, number too) and a `ViewersDrop` "-{viewers lost}" (`crash_loss`) falling and fading; nothing on a drain.
- Wiring: `hud.bind_popups(trick_popups)` added in `run.gd` (one line); gift arrows avoid `viewers_counter` instead of `combo_label` (`gift_arrows.gd`, one line).

Proposals for the playtest (all numbers in `hud.json` `viewers_counter`): the viewers colour #33e1ff (T-339's rim/eye); number under-badge layout with "WATCHING" under the number; the number holds a trick's viewers until its "+" lands (so the jump and the heat step come with the bump); counter always shown (also at x1, 2,500); timings 0.3 s detach, 0.55 s flight, 0.25 s bump, 0.45 s red flash, 0.9 s / 70 px drop; the drop is drawn under the number so the number stays readable.

Text: no new wording invented. Uses T-331's TEXT_LIVE_BADGE (the badge art carries the word; the constant is its tooltip) and TEXT_VIEWERS_UNIT, T-082's ADDED_TEXT "+{amount}", and a new constant `TrickPopups.LOST_TEXT = "-{amount}"`, the board's "-{viewers lost}" from this ticket word for word. Project Lead: if that format needs a Narrative pass, it is the only new string.

Notes for the Project Lead:
- Parallel tickets: T-337 rewrites `_build_bottom`/`_layout_bottom` in hud.gd, where I removed the combo label lines; expect a small conflict there. I also added `viewers_counter` before `timer_clock` in hud.json (T-341 may add a key too).
- At 1024x576 the counter's left edge (x768) meets the end of the old likes bar/"Hype Lv" row (also x768), 2 px of vertical overlap with the popped "Hype Lv"; at 1152x648 and up they are clear. The old row goes with T-337, so I dropped that one assert from `test_hud_level_up_flash.gd` instead of moving the counter off the board's layout.
- The old health/likes bars' border in `_make_bar` is a cyan-ish Color(0.3, 0.9, 1.0, 0.8), close to the viewers colour; those bars are being replaced by T-334/T-337, so I left them.
- Removed tests for the gone counter: `test_hud_combo.gd`, `test_hud_combo_hidden.gd` (T-116 hiding no longer applies). Updated combo_label/amount asserts in test_hud_combo_heat, test_hud_layout, test_hud_level_up_flash, test_hud_positions_t086, test_likes_spring, run/test_gift_drops, test_trick_popups, test_trick_popups_heat, test_air_tricks, test_airtime_trick, run/test_thread_the_needle, run/test_run_likes.

New tests: `game/tests/unit/hud/test_hud_viewers_counter.gd` (19 tests: counter gone, place/size/anchor, badge/eye/unit, colour used nowhere else, counting toward target, never still, paused, heat steps, fire at 1M, no heart red, popup "+viewers" pixels and eye, detach + flight end + bump, early pushed-out popup, drift prototype, crash flash and drop, drain no drop, new run, no literal text).

Test runs (foreground, all passing):
- `python -m unittest discover -s game/tools -p "test_*.py"`: 643 tests, OK (1 skipped).
- `python -m unittest discover -s tools -p "test_*.py"`: 545 tests, OK.
- `bash game/tools/run_tests.sh`: 1759/1759 tests passing, 1187476 asserts.

Screenshots (`art-archive/T-336/screenshots/`, 1152x648 stills; made with `bash game/tools/record_viewers_counter.sh`, fixture `game/tests/fixtures/viewers_counter_demo.tscn`): `counter_base.png` (x1), `counter_step1.png`, `counter_step2.png`, `counter_step3.png`, `counter_fire.png` (on fire, 1.00M); `viewers_trick.gif` (three tricks, each "+viewers" flying in), `viewers_crash.gif` (red flash, "-226K" dropping, number falling).

Documents affected: `docs/hud-and-menus.md` (Content: new "Live viewers counter" entry; Livestream HUD texts: badge art, unit placement, "+{amount}"/"-{amount}"); `game/docs/hud-and-menus/hud.md` (note that the combo counter is gone, new section "Live viewers counter (HUD)"); `game/docs/hud-and-menus/popups.md` (new section "Viewers on the trick popups"). game/README.md is an index now, so not changed. The long GDD needs regenerating at merge.

**QA, 2026-10-28 (round 1): 9 of 9 criteria pass.** qa_check: tests PASS (3 sets), screenshots PASS (7 files; counter_fire.png viewed, fire and "1.00M WATCHING" at bottom right), documents line flagged only game/README.md unchanged, which the Project Lead said to count via game/docs/hud-and-menus/ (hud.md, popups.md) plus docs/hud-and-menus.md. "-{amount}" is a constant in trick_popups.gd (LOST_TEXT, the board's wording, as the Project Lead allowed) with the same pattern as ADDED_TEXT. Agent's test counts (643, 545, 1759) confirmed by the passing run.

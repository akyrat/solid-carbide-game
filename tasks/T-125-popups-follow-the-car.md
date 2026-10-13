---
id: T-125
title: Trick popups follow the car while they are on screen
status: needs-playtest
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/README.md, tasks/T-091-trick-popups.md, tasks/T-084-trick-popup-art.md, game/scripts/hud/trick_popups.gd]
files_expected_to_change: [game/scripts/hud/trick_popups.gd, its tests, game/README.md, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 2
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's playtest of the comic popups (T-084, 2026-10-13): today a popup appears above the car and then stays where it appeared while the car drives away, so at drift speed it is left behind and hard to read. The board wants each popup to **stay with the car**: it follows the car for its whole life (HUD and menus, Decisions, 2026-10-13).

**Branch:** create your branch `task/T-125-popups-follow-the-car` from `task/T-084-trick-popup-art` (not from master), in your own folder `C:\solid-carbide-worktrees\T-125`, so the board playtests the new look and this together. T-084 merges first, then this task.

1. A popup is placed relative to the car and moves with it every frame: it still pops above the car, grows and rises its 40 pixels relative to the car, and fades as before; only its anchor changes from a fixed world point to the car.
2. Several popups at once (for example an extended drift every second during a long drift, plus a 360) must stay readable: stack or offset them so they don't sit on top of each other; propose how and say so in the result notes.
3. It must not shake: follow the car's drawn position (the same position the camera follows), not its physics position.
4. Works in the run (including from the main menu) and in the drift prototype, and for the challenge popup ("Trending!").
5. Update HUD and menus, Content ("Trick popups"), and game/README.md.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Do not merge.

## Acceptance criteria

- [ ] GUT tests show a popup keeps the same offset from the car's drawn position while the car moves (apart from its own rise), for its whole life (QA: pass)
- [ ] GUT tests show two or more popups shown close together don't overlap each other (QA: pass)
- [ ] Two screenshots during a fast drift, a fraction of a second apart, show the popup still above the car (QA: pass)
- [ ] HUD and menus, Content, and game/README.md say the popups follow the car (QA: pass)
- [ ] T-091, T-083, T-092 and T-084's tests, the full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest tricks at speed (together with T-084's look) and judge whether the popups are readable.

## Result notes

Built (UI Agent), branch `task/T-125-popups-follow-the-car` (from T-084's branch), folder `C:\solid-carbide-worktrees\T-125`.

- `scripts/hud/trick_popups.gd`: `show_popup(text, at, font_size, follow := Callable())` keeps its API; `bind`, `bind_score` and `bind_combo` pass the car's drawn position (`car_sprite.position`) as `follow`, so run, drift prototype and the challenge popup all follow. Each popup is placed `anchor + START_OFFSET + stack - rise` and the position is set in `_physics_process` (like the car sprite and camera, so physics interpolation smooths it and it does not shake); `_process` only does age, pop scale and fade. Look, 40 px rise, 1 s life are unchanged.
- Proposed stacking (as asked): a new popup that would overlap a popup already showing (rectangles, 4 px gap, compared at the older one's current place) is moved up in 4 px steps until clear. It keeps that offset from the car for its life; older popups don't move. So a long drift every second plus a 360 stack upwards and fall back to the car once the others are gone.
- Tests: `tests/unit/test_trick_popups_follow.gd` (9 tests: constant offset from a moving car over the whole life, physics-step placement, no follow stays put, run, challenge and prototype popups follow, popups born together and a little apart do not overlap, stack resets). Full GUT suite: 429 passed. Python tool tests: game/tools and tools both OK (unittest discover, exit 0).
- Screenshots (fast drift, car driven with scripted full throttle and steering, a 360 and a long drift at frame 10): `C:\solid-carbide-worktrees\T-125\screenshots\popups_follow_14.png` and `popups_follow_24.png` (fixture `tests/fixtures/popups_follow_demo.tscn`). The popups sit above the car in both, stacked and not overlapping. The camera is centred on the car, so the car stays in the middle in both; the ground scrolls.
- Docs: HUD and menus, Decisions (line taken word for word from master) and Content, "Trick popups"; game/README.md, "Trick popups". Godot's .import noise reverted. When T-084 merges first, the Decisions line sits next to its comic-look line and may need a trivial conflict resolution.
- 2026-10-13, in-progress → in-qa: ready for QA

QA round 1 (QA/Integration Agent, 2026-10-13), judged on the diff from `task/T-084-trick-popup-art`: all five criteria pass.

- Offset from the drawn car: pass. `test_popup_keeps_its_offset_from_a_moving_car_for_its_whole_life` moves the car every 0.05 s up to 0.95 s and checks the popup sits at car + START_OFFSET - rise, centred on x; `test_physics_step_places_the_popup...` covers placement in `_physics_process`. In the code the position is set only in `_physics_process` (`place()`), and run (`bind`, `bind_score`, `bind_combo`) and prototype (`bind`) all pass `car_sprite.position`, the drawn position. Run, challenge ("Trending") and prototype popups each have a follow test.
- No overlap: pass. Four popups on one step and seven born 0.1 s apart are checked pairwise for rectangle overlap. The stagger test checks only at the end, but newer popups rise faster than older ones (ease-out curve), so a popup stacked above an older one moves away from it.
- Screenshots: pass. In `screenshots/popups_follow_14.png` and `popups_follow_24.png` (10 frames apart) the ground and the drift marks have moved, and both popups are still above the car, stacked, not overlapping. Note: the fixture is about 0.25 to 0.4 s into full throttle, so the speed is not top speed. The gap between the two stacked popups looks larger than 4 px (roughly 40 px on screen); worth a look in the playtest.
- Docs: pass. HUD and menus, Content "Trick popups" describes following and stacking; the Decisions line matches master's word for word; game/README.md "Trick popups" has the T-125 entry.
- Tests: pass. Full GUT suite 429/429 (43 scripts; 2 warnings, both not from T-125: an inner-class notice and a float/int compare in T-084's art test). The T-091, T-083, T-092 and T-084 test files are not changed on this branch and pass. Python: game/tools 152 OK, tools 115 OK.
- 2026-10-13, in-qa → needs-playtest: QA round 1: all criteria pass
- 2026-10-14, needs-playtest → in-progress: board playtest: popups stack too high (over the timer); cap at half the distance to the top of the screen, and make them a bit smaller

### The board's playtest, 2026-10-14 (round 1): lower and smaller

Following the car works, but the stacked popups climb too high and overlap the HUD timer. The board wants:
- popups to go **at most half way from the car to the top of the screen** (the car sits at the screen's centre, so the highest popup's top edge stays at or below a quarter of the screen height from the top, at any window size and camera zoom); when the stack would go higher, keep it within that limit (for example tighter stacking, or the oldest popup making room);
- popups **a bit smaller** than now (propose the scale, for example about 75 to 80%, for both the normal and the extended-drift size).



### Round 2 (UI Agent, 2026-10-14)

Done, branch `task/T-125-popups-follow-the-car`, folder `C:\solid-carbide-worktrees\T-125`.

- **Smaller:** `PIXEL_SCALE` 0.8 to 0.6 (75%), for the normal and the extended-drift size alike (a 360 is now about 39 drawn px tall, a long drift about 27). Chosen at the low end of 75 to 80% because the cap leaves little room.
- **Limit:** `TrickPopups.top_limit()` = a quarter of the viewport height (`MAX_REACH` 0.25) in screen space, divided by the camera zoom times the view's scale, so it holds at any window size and zoom (the car is at the screen's centre, so a quarter is half way to the top). No camera, no limit. A popup is checked at the end of its whole rise (the highest it gets).
- **Policy chosen (the two the board offered):** the oldest popup makes room: when a new popup would stack above the limit, the oldest popup showing is removed, repeated until the newcomer fits (tighter stacking was already at 4 px gap and cannot gain enough). If even an unstacked popup would end above the limit (a very close zoom), `place()` keeps it lower at the limit.
- **Honest consequence for the board:** at the default zoom (limit about 115 drawn px above the car, popup starts 50 above and rises 40) only about one popup fits at a time. A 360 and a long drift on the same step: the second one wins and the 360 is removed. A long drift every second alone looks as before. Cheapest next steps if this loses too much: start popups lower than 50 px, or let the stack shrink the rise instead of removing popups. Needs the board's call.
- Tests: `tests/unit/test_trick_popups_follow.gd` gains the top edge never above a quarter of the screen height with 20 popups, at 1152x648 and 640x900, zoom 1 and 2 (SubViewport with a Camera2D), no overlap under the limit, oldest makes room, plain stacking without a camera, and the smaller scale. Two older tests were adjusted because popups can now make room (`test_hud_combo.gd` counts popups with the trick's text; the run overlap tests accept 1 to 4 popups). Full GUT suite: 434 passed. Python: game/tools and tools tests run below.
- Screenshots (fast drift, a 360 at frame 10 then a LONG DRIFT every 12 frames; fixture changed): `C:\solid-carbide-worktrees\T-125\screenshots\popups_follow_r2_a.png` (frame 20) and `popups_follow_r2_b.png` (frame 40). One small popup above the car, well below the timer; only one shows because of the policy above.
- Docs: `docs/hud-and-menus.md` Content "Trick popups" and `game/README.md` "Trick popups".
- 2026-10-14, in-progress → in-qa: Round 2: smaller and capped at half way to the top

### The board's feedback, 2026-10-14 (before playtesting round 2): three at most, eased rise

Given before any playtest of round 2. The status stays `in-qa` while this is reworked (the status script refuses to move a task out of QA while its round-1 marks still read "pass"); QA round 2 runs after it.
- Make every popup **small enough that up to 3 can be stacked** at once under the quarter-of-the-screen limit at the default zoom (and never more than 3: the oldest makes room for a fourth). Scale the normal and extended-drift sizes and the start offset as needed.
- Make the rise **smooth: fast at the start and slowing towards the end**, where the popup fades out (an ease-out curve), instead of a constant speed.


### Round 3 (UI Agent, 2026-10-14)

Done on branch `task/T-125-popups-follow-the-car`. Status left as `in-qa`.

- **Three at most:** `MAX_POPUPS` 3; `show_popup` removes the oldest popup while three show, so a fourth makes room. Sizes: `PIXEL_SCALE` 0.6 to 0.5, `START_OFFSET` (0, -50) to (0, -30), `RISE` 40 to 20. At the default zoom 14.4 and window 1152x648 (camera zoom 1.40625, limit 115.2 drawn px) three of the biggest popups stack with room to spare (about 107 of 115 drawn px used). Both sizes scale together via `PIXEL_SCALE`.
- **Eased rise:** `rise()` is a cubic ease-out, `RISE * (1 - (1 - t)^3)`, same 1 s life; most of the rise happens in the first half. (Round 2 had a quadratic ease; now stronger and over a smaller rise.)
- **Rounded rectangles (board's added request, same round):** `trick_popup_art.gd` replaces the jagged burst with a white rounded rectangle: black 2 px border, black Bangers lettering, fitted to each text with `MARGIN_X` 8 / `MARGIN_Y` 6 padding, corners of radius `CORNER` 5 drawn in stepped pixels (pixel centres tested, no smoothing, only opaque or fully transparent pixels, three colours). All burst code removed. Because the box is flatter, a popup is now 37 px tall (was about 65).
- **Tests:** `test_trick_popups_follow.gd`: three of the biggest fit at the default zoom and window, never more than three (and the oldest makes room for a fourth), the rise is ease-out (steps never grow, more in the first half than the second, full RISE at the end), top limit still holds at 1152x648 and 640x900, zoom 1 and 2; older tests adjusted to a three-popup cap. `test_trick_popup_art.gd`: burst-shape checks renamed to the bubble, plus stepped rounded corners and small padding; black/white only, black border, no red, fits each text and cached are kept. Full GUT suite: 438 passed, 0 failed. Python: game/tools 115 OK, tools OK.
- **Screenshots** (run, fast drift, a 360 at frame 10, a LONG DRIFT every 12 frames; fixture `popups_follow_demo.gd`): `C:\solid-carbide-worktrees\T-125\screenshots\popups_follow_r3_a.png` (frame 26) and `popups_follow_r3_b.png` (frame 31): three stacked rounded popups above the car.
- **Docs:** `docs/hud-and-menus.md` Decisions (new line for the rounded rectangles, placed after the "Trick popups stay with the car" line because the line "The trick popups look like real comic book popups ..." is not in that file) and Content "Trick popups"; `game/README.md` "Trick popups" (Comic look, round 3 paragraph, screenshot commands).
- Documents affected: `docs/hud-and-menus.md`, `game/README.md`.

### QA round 2 (QA/Integration Agent, 2026-10-14), the last round

Judged on T-125's own diff from `task/T-084-trick-popup-art` (rounds 1 to 3). All five criteria pass, and the board's round-2 and round-3 requests are met.

- Offset from the drawn car: pass. The follow tests are unchanged in substance and pass: constant offset `START_OFFSET + stack - rise` from a moving car every 0.05 s over the whole life, placement in `_physics_process`, and run, challenge ("Trending") and prototype popups each following `car_sprite.position`. The new eased rise is part of the checked offset (`pop.rise()`).
- No overlap: pass. Rectangle-overlap checks pass for four tricks on one step in the run (now asserts at most 3 show), three stacked without a camera, popups born 0.1 s apart, and twelve under the limit at zoom 1.5. In my own run (below) the three stacked popups never overlapped.
- Screenshots: pass. `screenshots/popups_follow_r3_a.png` (frame 26) and `_r3_b.png` (frame 31): ground and drift marks moved, three white rounded popups stacked above the car, apart, well below the timer. I retook frame 28 myself (same picture, three stacked above the car).
- Docs: pass. HUD and menus, Content "Trick popups" says the popups follow the car and describes the cap at a quarter of the screen height, three at most, the 30 px start, the 20 px cubic ease-out rise and the rounded rectangle; Decisions has the follow line (2026-10-13) and the rounded-rectangle line (2026-10-14). game/README.md "Trick popups" covers following, the limit, `MAX_POPUPS`, the ease-out and the rounded look. Minor stale wording, not blocking: HUD and menus Content still says extended-drift popups are "smaller and flatter (a shorter burst)", and game/README.md's Tests line still says "the burst fits each text".
- Tests: pass. Full GUT suite 438/438 (43 scripts; the same 2 warnings as round 1, neither from T-125). Python: game/tools 152 OK, tools 115 OK. T-091, T-083, T-092 and T-084 test files pass. Changed older tests judged not weakened: `test_hud_combo.gd` now counts popups with the trick's own text (still catches a doubled popup, which the 3-popup cap would otherwise make uncountable); the run overlap test went from at most 4 to at most 3 (stronger); the no-camera stacking test from 4 to 3 with a check that the fourth made the oldest leave; the T-084 art tests only renamed burst to bubble, and the checks that matter (no semi-transparent pixels, transparent border, no colour near Redgull red, white and black only with a black border, letters black on one baseline, fits each text, cached) are untouched, with a new stepped-corner test added. `test_popups_are_smaller_than_before` went from exactly 0.6 to below 0.6, as round 3 intends.

The board's requests, checked separately:
- Three at most, all fitting under the limit at zoom 14.4 and 1152x648: pass. Measured in the real run (a temporary fixture, removed afterwards, emitting a trick every 5 frames): always 3 popups, highest top edge at 193.6 px against the quarter line at 162. A unit test shows three of the biggest fit without any having to make room.
- Limit at other sizes and zooms: pass. Real run at 800x900, zoom 7 (close): one popup fits at a time, top edge 278 px against 225. At 1600x500, zoom 25 (far): three, highest top 192.9 against 125. The unit test covers 1152x648 and 640x900 at camera zoom 1 and 2, with 20 popups over 2 s.
- Eased rise: pass. `rise()` is `RISE * (1 - (1 - t)^3)` over the 1 s life; the test checks each step is no larger than the one before, more rise in the first half, full rise at the end.
- White rounded rectangles, black border and lettering, stepped corners, no semi-transparent pixels, no red: pass (art tests above; at zoom 7 the enlarged popup shows clean stepped corners and hard pixels).

For the board's playtest (not a failure): at the default zoom the popups are now drawn at about 0.7 screen pixels per popup pixel, so nearest filtering drops pixel rows and columns. The small LONG DRIFT! lettering is hard to read in the screenshots (enlarged it reads like "SONG DRIFT"), and the rounded corners are barely visible. The 360 popup reads. At closer zooms everything reads cleanly. The board should judge readability in the playtest.

Godot's line-ending-only `.import` changes were left uncommitted.
- 2026-10-14, in-qa → needs-playtest: QA round 2: all criteria pass

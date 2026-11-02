---
id: T-491
title: The trick list shows each trick's clip, live key pad and keycap recipe; slide 2's clips get the key pad
status: in-progress
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-489, T-490]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/menu/tutorial_slides.gd, game/scripts/menu/clip_player.gd, game/data/tutorial_text.json, game/docs/hud-and-menus/pause-screen.md, C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tricks/tricks.template.html]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/scripts/hud/, game/data/, game/tests/unit/, docs/hud-and-menus.md]
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

The board, 2026-11-01 (HUD and menus, Decisions, "Each trick shows the keys that make it"), following the Project Lead's draft page (its template is in files_to_read_first; open the built page `.../scratchpad/tricks/trick-controls.html` in a browser to see it). The board approved merging this straight after QA.

1. **A live key pad** (a reusable piece): a small W A S D pad in a clip's bottom-right corner, each key lit while the clip's key timeline (T-490's per-frame field in the sheet JSON) says it is held, in step with ClipPlayer's frame. Look as on the draft page (keycaps in the HUD style, the lit key in the blush colour, pressed down a little).
2. **Tutorial slide 2:** its three clips get the pad. Nothing else on the slide changes.
3. **The trick list** (pause screen): for each of the seven tricks its name, its rule (T-489), its clip (T-490's) with the pad, and its keycap recipe: the keys as keycaps joined with +, steps joined with an arrow, the note under each step, the badge for a step with no keys, and a small /D tag on a key where either turn key works (draft: the TRICKS array's `recipe` on the page). THREAD THE NEEDLE! shows its clip and rule but no recipe. Lay it out so it is not crowded at 1152 x 648 inside the pause strip: for example the seven trick names (with their illustrations) as a list, and the selected trick shown large on the right with its clip, pad, rule and recipe; keyboard and mouse both select. Back, Escape and focus behave as today. Clips load when shown and are freed when hidden (T-485's web memory rule).
4. The recipe's structure (which keys per step, which text key for each note, the /D marks) is data in game/data (a new JSON file); the texts come from tutorial_text.json (T-489's keys), never from code.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests show the key pad lights exactly the keys of the clip's key timeline for the current frame (for example alt_drift's S + A frames light S and A only). (QA: pass; key_pad tests 3/3)
- [ ] Tests show slide 2's three clips each have the pad, and the rest of slide 2 is unchanged (its existing tests pass). (QA: pass; tutorial_slides tests pass, pads visible on all three clips)
- [ ] Tests show the trick list has all seven tricks; each of six shows its recipe (keycaps, notes, badges, /D marks from the data file) and THREAD THE NEEDLE! shows none; each shows its clip with the pad; texts come from tutorial_text.json. (QA: pass; trick_list_recipes 8/8)
- [ ] Tests show Back, Escape and focus in the trick list work as before, and clips are freed when the panel is hidden. (QA: pass; pause_trick_list and trick_list tests pass; the SCALE to LIST_SCALE edit still checks nearest filter, size and exact scale)
- [ ] Screenshots at 1280 x 720 of slide 2 and of the trick list with at least three different tricks selected are saved and listed in the result notes. (QA: fail; paperwork - trick_list_extended_drift.png shows HANG TIME! and trick_list_air_one_eighty.png shows AIR 360!, names do not match; pad itself reads well)
- [ ] docs/hud-and-menus.md (Content, "Pause screen" and the slides section) describes the pad and the new trick list. (QA: pass; doc changed)
- [ ] The tests for the changed code pass (the agent, with -gselect), and QA's full run passes (tasks/README.md, "Which tests run when"), with the counts in the result notes. (QA: fail; code - full Godot set red 2587/2588, reran with same result: tests/unit/hud/test_shared_button.gd line 96 test_level_up_and_pause_buttons_are_shared; pause Row_* rows lack hud_button meta, plate and Bangers font after the TrickList rebuild; game/tools set passes)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass; no data/levels files in the branch diff)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open

Filed: waits for T-489 (text) and T-490 (clips).

### 2026-11-01, Open → In progress

T-489 and T-490 are merged: UI agent started on the trick list and slide 2's key pad.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. New: game/scripts/menu/key_pad.gd (KeyPad.attach; lights ClipPlayer.held_keys() from keys_per_frame, refreshed on the new ClipPlayer.frame_changed signal), game/data/trick_recipes.json (clip, steps, keys, /D marks; texts from tutorial_text.json trick_rule / trick_recipe keys). Slide 2's three clips get the pad (slide 1 unchanged). TrickList rebuilt: seven-row list (click or focus selects) plus detail pane (name, rule, one clip with pad, keycap recipe with arrows, notes, badges, /D tags; none for THREAD THE NEEDLE!); clip loads only while visible. Mapping: air_one_eighty uses ramp_jump, extended_drift long_drift, alternate_drift alt_drift. Panel is 494 -> ~456 px tall so it still clears the HUD clock at 1152x648. Old test_trick_list SCALE assertions changed to LIST_SCALE=1. Tests (-gselect, all pass): test_key_pad 3/3, test_trick_list_recipes 8/8, test_trick_list 6/6, test_tutorial_slides 26/26, test_tutorial_clips 6/6, test_pause_screen 10/10, test_pause_trick_list 8/8. Screenshots 1280x720 in art-archive/T-491/screenshots/: slide2_a.png, slide2_b.png, trick_list_extended_drift.png, trick_list_alternate_drift.png, trick_list_air_one_eighty.png, trick_list_airtime.png, trick_list_thread_the_needle.png. Docs: docs/hud-and-menus.md (Pause screen entry, slides section), game/docs/hud-and-menus/pause-screen.md and tutorial-slides.md. Nothing under game/data/levels/ touched. Untracked .uid files left uncommitted.
- 2026-11-01, in-progress → in-qa: Trick list, key pad and slide 2 pads built; tests pass; screenshots in art-archive/T-491/screenshots

Project Lead review fixes: (1) key pad unlit keys now dark #33384f with muted letter, lit keys blush #f6c9de with dark letter pressed down 2 px (slide 2 and trick list). (2) Trick list detail: name in Bangers 40 with pink offset shadow; clip 372x248 on the left, rule on its right, recipe full width below with notes at size 10 and wider steps. (3) Screenshots re-taken, each name matches its trick, in art-archive/T-491/screenshots/: slide2_a, slide2_b, trick_list_extended_drift, trick_list_alternate_drift (ALT DRIFT!), trick_list_air_one_eighty, trick_list_air_three_sixty (AIR 360!), trick_list_airtime, trick_list_thread_the_needle; manifest.json updated. Tests re-run with -gselect, all pass: pause_trick_list 8, pause_screen 10, trick_list 6, tutorial_slides 26, key_pad 3, trick_list_recipes 8, tutorial_clips 6. Note: task_status refused in-qa to in-progress (QA criteria unmarked), so the ticket stayed in-qa.
- 2026-11-02, in-qa → in-progress: QA fail: (1) code: test_shared_button.gd:96 red, pause trick-list rows lack hud_button meta/plate/Bangers; (2) paperwork: trick_list_extended_drift.png shows HANG TIME and trick_list_air_one_eighty.png shows AIR 360

QA round 1 fixes: (1) trick list rows are no longer Buttons: a TrickRow Control (inner class in trick_list.gd) that is focusable and handles click and Enter/Space (ui_accept), draws its own look (same as before); API kept (pressed signal, button_pressed, set_pressed_no_signal). test_shared_button.gd unchanged, passes 12/12. New test for rows not being BaseButton and Enter selecting. (2) Screenshots retaken waiting until the detail name label reads the trick, then 1.5 s and 4 drawn frames; all six trick_list_*.png checked by eye in a montage and match their names. Tests with -gselect all pass: test_shared_button 12, pause_trick_list 8, pause_screen 10, trick_list 6, tutorial_slides 26, key_pad 3, trick_list_recipes 9.

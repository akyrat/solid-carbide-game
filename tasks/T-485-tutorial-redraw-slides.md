---
id: T-485
title: Build the redrawn tutorial slides: four slides with keycaps, the loop chain, the clips, missions and the run timeline
status: needs-playtest
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-483, T-484]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/menu/tutorial_slides.gd, game/data/tutorial_text.json, tasks/T-483-tutorial-clips.md, C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tutorial/tutorial-redraft.template.html]
files_expected_to_change: [game/scripts/menu/tutorial_slides.gd, game/scenes/menu/, game/tests/unit/, docs/hud-and-menus.md]
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

The board approved the redrawn tutorial slides (2026-11-01; HUD and menus, Decisions, "The tutorial slides are redrawn, with clips of the real car"): rebuild the tutorial slides in the game to match the Project Lead's approved draft. Open the built draft in a browser to see it: `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tutorial/approved/tutorial-redraft-v3-approved.html`; its template (files_to_read_first) shows the layout in plain HTML/CSS. Match it as closely as the game's UI allows, at 1280 x 720 and scaling with the window like the other screens.

Four slides, in this order:
1. **Drive:** the W, A, S, D keys as keycaps in their WASD layout, each with its label, W highlighted; the drift rule; beside them the zoomed-out drift clip (game/art/tutorial/clips/drift.gif, from T-483).
2. **Tricks bring gifts:** a chain of four steps (arrows between), each a panel with its picture from the game's own art (a trick illustration from art/tutorial/tricks/, the HUD's eye icon with a viewer count, the subs icon in a sub-goal ring, the gift pack package with four weapon icons from art/hud/weapon_icons.png), a title and a caption; under it the three clips (long_drift.gif, alt_drift.gif, ramp_jump.gif) with their captions.
3. **Missions:** the HUD's notebook page art with a ticked and an open mission line, and the four power-up icons with their names.
4. **Survive the stream:** the 8-minute run as a timeline bar (cyan to pink, red in the last minute) with gift packs above it, time labels, the kaiju sprite at the last minute and its label; then the Go live button (with the HUD's LIVE badge) and the Don't show again checkbox under it. No hearts, no sentence.

Every slide: its kicker and headline (headline in the game's Bangers display font with a pink offset shadow, as the draft), the existing arrows and the slide dots (now four), and a Skip control at the top right that jumps to slide 4. The keyboard and arrows work as today (Start's behaviour, Don't show again, and only fresh key presses counting are unchanged).

The clips are GIFs: Godot doesn't play GIFs natively, so convert them at import or build time into something the game plays (a SpriteFrames / AnimatedTexture from the frames, or a frame sheet), with a script, keeping nearest-neighbour pixels and each clip's frame timing; say which in the result notes. Every text comes from the text ticket's keys in game/data/tutorial_text.json, never from code; remove the use of the retired keys. Reuse the shared button (T-446) and the HUD style sheet. Never write, move or commit anything in game/data/levels/.

The board's review: press Start and page through the four slides, use Skip, and start a run from slide 4.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests show four slides in the order Drive, Tricks bring gifts, Missions, Survive the stream, the dots show four, and Skip goes to slide 4. (QA: pass: order, dots and skip tests green)
- [ ] Tests show each slide's texts come from tutorial_text.json's new keys (none from code) and the retired keys are no longer used. (QA: pass: texts-match-file, retired-keys, no-word-from-code tests green)
- [ ] Tests show the clips play (frames advance with their timing) on slides 1 and 2, and the pictures on slides 2 to 4 are the game's own art files. (QA: pass: clip timing and own-art tests green; sheets at most 3840 x 3840)
- [ ] Tests show Go live starts the run and Don't show again still works, with only fresh key presses counting, as before. (QA: pass: start-signal, fresh-key and Enter tests green)
- [ ] Screenshots of all four slides at 1280 x 720 are saved and listed in the result notes, next to the draft for comparison. (QA: pass: slide1-4.png at 1280 x 720 in art-archive/T-485/screenshots/, layout and content match the draft)
- [ ] docs/hud-and-menus.md (Content) describes the four slides. (QA: pass)
- [ ] The tests for the changed code pass (the agent: its new and changed test files and those of the scripts it touched, with `bash game/tools/run_tests.sh -gtest=res://tests/unit/<file>.gd` per file), and QA's full run passes (the Godot set and `python -m unittest discover -s game/tools -p "test_*.py"`; the tools set only if tools/ changed; tasks/README.md, "Which tests run when"), with the counts in the result notes. (QA: pass: Godot set 213 scripts, 2541 of 2541 tests; unittest 878 tests OK, tools changed on the branch)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass: nothing under game/data/levels/ in the branch diff)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the UI Agent builds the four redrawn slides (clips and text merged in).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

UI Agent, T-485: the four redrawn tutorial slides are built to the approved draft.

- **Screen:** `game/scripts/menu/tutorial_slides.gd` rewritten: a 1280 x 720 stage scaled and centred to the window (`_fit`), four slides (Drive, Tricks bring gift packs, Missions, Survive the stream), kicker, Bangers headline with a pink offset shadow, arrows, four dots, a Skip button (shared small button) that jumps to slide 4. Slide 3 reuses the HUD's own `MissionPage` (3x) with a ticked and an open sample line; slide 4's bar is a gradient texture (cyan, pink, red in the last eighth). Go live is the shared button with the LIVE badge at 2x; Don't show again is the shared checkbox. Start behaviour, only-fresh-key-presses and the focus order are as before (slide 4 focuses Go live).
- **Text:** every word from `tutorial_text.json` (headlines, labels, captions upcased for display through `Label.uppercase`; the file's text unchanged), power-up names and notebook sample lines from `screen_texts.json`. Retired keys (`slide1.controls`, `slide1.drift`, `slide2.chain`, `slide2.gift`, `slide3.goal`) are not used (a test checks the source). Only numbers are in code (sample viewer count 1,284, the times 8:00, 4:00, 1:00). The drift rule is split on "+" and "=" with the W as a keycap.
- **Clips:** Godot does not play GIFs, so `game/tools/gif_to_sheet.py` (test `game/tools/test_gif_to_sheet.py`) turns each GIF into `<name>_sheet.png` (frame grid, RGBA, 1:1 pixels) and `<name>_sheet.json` (frame size, columns, each frame's own duration in ms read from the GIF: drift has an 80 ms first frame then 40 ms, the others 60 ms). `ClipPlayer` (`game/scripts/menu/clip_player.gd`) draws the frame by region with nearest filtering, loops, loads the sheet when its slide first shows and only advances while visible. In Godot they play correctly (screenshots show the car mid-drift, tyre marks, the ramp). Cost: sheets are 4800 x 4800 at most; about 214 MB of texture memory once all four are loaded (loaded lazily); worth a look on the web build.
- **Other changes:** `tests/fixtures/tutorial_slides_demo.gd` sets the window to 1280 x 720, new `tutorial_slides_demo_4.tscn`; `test_shared_button.gd` now counts 5 shared buttons on the slides (two arrows, Skip, Go live, checkbox); `test_tutorial_flow.gd` goes to slide 4. Docs: `docs/hud-and-menus.md` (Content, "The four redrawn slides (T-485)", the clips entry), `game/docs/hud-and-menus/tutorial-slides.md`.
- **Judgment calls for the board's playtest:** step 1 shows the long drift illustration; the step captions and the missions line are in the default font (not upcased), as in the draft; weapons on the gift pack are gun, molotov, bricks, underglow; the kaiju is drawn at 0.75x (168 px); the Skip button is the shared small plate rather than the draft's plain text.
- **Screenshots (1280 x 720):** `art-archive/T-485/screenshots/slide1.png`, `slide2.png`, `slide3.png`, `slide4.png`. The draft: `C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tutorial/approved/tutorial-redraft-v3-approved.html`.
- **Tests I ran (QA runs the full set):** `test_tutorial_slides` 24 of 24 (280 asserts), `test_shared_button` 12 of 12, `test_tutorial_flow` 8 of 8, `test_tutorial_setting` 3 of 3, `test_tutorial_clips` 4 of 4, and `python -m unittest game/tools/test_gif_to_sheet.py` OK. Note for the team: `-gtest=res://...` runs the whole suite here (GUT ignored it); `-gselect=<file name without .gd>` runs one file. My first foreground run therefore started the full set and was left running until the tool stopped it; one orphan Godot process (pid 14216, from `run_tests.sh`) may still be running and ends on its own at the time limit; I was not allowed to kill it.
- Nothing under game/data/levels/ touched. Documents affected: docs/hud-and-menus.md, game/docs/hud-and-menus/tutorial-slides.md.
- 2026-11-01, in-progress → in-qa: Four slides built to the approved draft, clips played from frame sheets; my tests green, QA to run the full sets

Web build fix (coordinator, 2026-11-01): the sheets are now at most 4096 x 4096 (WebGL's limit) and freed when their slide is hidden.
- `gif_to_sheet.py` lays frames out 8 columns wide and 12 rows high at most, and splits a clip into pages (`<name>_sheet.png`, `<name>_sheet_1.png`); the JSON lists the pages. Page sizes: drift 3840 x 3840 and 3840 x 2240 (two pages), long_drift 3840 x 3520, alt_drift 3840 x 2560, ramp_jump 3840 x 2240. Test added for the split.
- `ClipPlayer` loads a clip's pages when its slide is shown and frees them when it is hidden (`unload()`), so only one slide's clips are in memory. Peak texture memory: slide 1 about 118 MB (two pages of the drift clip), slide 2 about 127 MB (three clips); it was about 214 MB for all four. Test added: every page is at most 4096 a side, and slide 1's clip is freed when slide 2 shows.
- Tests re-run with `-gselect`: test_tutorial_slides 25 of 25, test_tutorial_flow 8 of 8, test_shared_button 12 of 12, test_tutorial_clips 4 of 4, test_tutorial_setting 3 of 3; `python -m unittest game/tools/test_gif_to_sheet.py` OK.
- Web export: `python tools/publish_itch.py --dry-run` stopped ("not on master"), so I did not use it. I exported the Web preset with Godot directly to the scratchpad (not pushed): it finished with no errors and the .pck holds all five sheet pages. I did not open it in a browser, so WebGL loading is not confirmed beyond the sizes.

QA round 1 (Sonnet): all 8 criteria pass. Godot set 213 scripts, 2541 of 2541 tests; unittest 878 OK. Web safety: every *_sheet*.png is at most 3840 x 3840; clip_player.gd frees pages when hidden (test covers it). No headless-Chrome run: game/tools/web_audio_check.mjs is not in master. A stray Godot process (pid 14216, this folder) had ended before the run.
- 2026-11-01, in-qa → needs-playtest: QA pass 8/8; Godot 2541/2541, unittest 878 OK

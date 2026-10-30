---
id: G-007
title: The last MVP round (board, 2026-10-29; HUD and menus, Decisions: 'T...
status: building
art_cap: 40
art_used: 0
iteration: 3
max_iterations: 20
created: 2026-10-29
lead: Goal-G-007
session: Greenbull
---

## Goal

The last MVP round (board, 2026-10-29; HUD and menus, Decisions: 'The last MVP round: no new scope after it', 'Tutorial slides before the first run', 'A trick list in the pause screen', 'No sound effects in the MVP'). (1) Three tutorial slides shown when the player presses Start, before the run begins: left and right arrows between them, a Start button on the last slide, and a 'Don't show again' checkbox saved on this computer; slide 1 the controls (W, A, S, D, and that accelerating while turning drifts the car), slide 2 the tricks the game counts (drift, 360, alternate drift, air 180, air 360, airtime, thread the needle) each with a still pixel art illustration of the car's movement, plus how tricks bring viewers, viewers bring subs, and sub goals bring gift packs with weapons that help survive and keep enemies away, slide 3 the goal (chain tricks to get the most weapons and be strongest when the kaiju arrives with 1 minute left). All slide text from a text ticket first. (2) The trick illustrations made both with PixelLab and by script, QA comparing which reads better and the better one used (art cap 40). (3) A trick list button in the pause screen opening a sub-panel with the same trick list and illustrations, and a way back. (4) Every sound effect off for the MVP and the sound effects slider hidden in the pause screen; the music and its slider stay; the sound code kept.

## Goal acceptance criteria

- [ ] On the playtest/G-007 branch, the game's full test sets (unit, scene and integration tests) all pass. (QA: pass / fail)
- [ ] Pressing Start on the main menu with the 'Don't show again' setting unset shows tutorial slide 1, not the run. While the slides are up, no run exists yet or its clock stays at 8:00 and nothing moves. An automated scene test and a screenshot show this. (QA: pass / fail)
- [ ] There are exactly three slides. The right arrow moves 1→2→3 and the left arrow 3→2→1. There is no right arrow on slide 3 and no left arrow on slide 1, or pressing them does nothing. Slide 3 has a Start button and a 'Don't show again' checkbox, and slides 1 and 2 have neither. An automated test checks this. (QA: pass / fail)
- [ ] Pressing Start on slide 3 starts a normal run with the clock counting down from 8:00. A test checks this. (QA: pass / fail)
- [ ] If the checkbox is ticked when Start is pressed, the setting is saved in the game's settings file on this computer. After restarting the game, Start goes straight into the run with no slides. If it is unticked, the slides show again on the next Start. A test checks both cases, with a reload of the settings. (QA: pass / fail)
- [ ] Slide 1 shows the controls text (W, A, S, D and that accelerating while turning drifts the car). Slide 2 shows the seven tricks (drift, 360, alternate drift, air 180, air 360, airtime, thread the needle), each with its own still illustration, plus the tricks → viewers → subs → gift pack with weapons text. Slide 3 shows the goal text (chain tricks, most weapons, strongest when the kaiju arrives with 1 minute left). Every visible string matches the text ticket's approved text word for word, read from a data file and not hard-coded in scripts. (QA: pass / fail)
- [ ] Seven trick illustration PNGs exist under game/art/ (one per trick) and pass the pixel-art script checks (Visual style, Rules 1 and 6). Both candidate sets, PixelLab and script-drawn, are kept in art-archive/ with QA's written comparison and the pick recorded in the comparison ticket. No more than 40 PixelLab generations were spent, as counted in the ticket's result notes. (QA: pass / fail)
- [ ] The pause screen has a trick list button. It opens a sub-panel that shows the same seven tricks with the same illustrations as slide 2, and none of slide 2's other text. A back control returns to the pause screen with its settings intact. A scene test and a screenshot show this. (QA: pass / fail)
- [ ] No sound effect plays during a run, whatever the saved SFX volume: a test shows the SFX bus or player stays silent or muted. The SFX volume slider is not visible on the pause screen. The music still plays and the music volume slider is still shown and works. The sound-effect code and game/data/sfx.json are still in the repository. (QA: pass / fail)
- [ ] Screenshots of the three slides and the pause trick list panel are saved in the tickets' art-archive screenshot folders. (QA: pass / fail)

## Open questions

- Can the player bring the slides back after ticking 'Don't show again' (for example a pause or menu setting)? The docs give no way back.
- Does pause screen Restart, or a run started from the level creator or the drift prototype, show the slides? The decision only says 'when the player presses Start'.
- Can the slides be skipped or closed early (Escape, or Start on slides 1 and 2)? The docs say only that the last slide has Start, not an X.
- Trick names on slide 2 and in the pause list: reuse the popup names word for word (LONG DRIFT!, FULL 360!, ALT DRIFT!, AIR 180!, AIR 360!, HANG TIME!, THREAD THE NEEDLE!) or plainer names like 'drift' and '360'? For the text ticket, unless the board says.
- Is the extended (long) drift trick shown as one 'drift' entry? The board's list says 'drift'.
- Illustration view and size: isometric like the game's art (Visual style, Rules 3) or a flat top-down diagram, which reads paths better? And what pixel size? Rule 3's 32 px per unit scale may not fit a small diagram.
- Do the illustrations show the actual car sprite or an abstract car shape? Can the path arrows use any colour, given rule 6 (no Greenbull light green or yellow on non-Greenbull things)?
- Does QA pick one whole set (PixelLab or script), or the better illustration for each trick, which could mix the sets?
- How does QA judge 'reads better', which is a judgment? With the Style Evaluator's scores, side-by-side readability at the in-game size, or both? The board may want the final say in the playtest.
- Can the 'Don't show again' checkbox sit on the last slide (the docs' proposal), and should it start unticked?
- What does Escape do while the pause trick list panel is open: go back to the pause screen, or resume the run?
- Sounds off: mute the SFX bus, or a flag that stops sounds from starting? And should the saved SFX volume be kept as it is for later? The docs only say the code stays.

## Sub-goals

| rank | id | title | score | why | verdict | tickets |
|---|---|---|---|---|---|---|
| 1 | S1 | Text ticket: every text in the tutorial slides and the pause trick list (Narrative Theme) | unblocks 4, value 5 | The board requires all slide text to come from a text ticket first. Text never uses placeholders, so the slides and the trick list panel cannot be built without it. | covered | T-381 |
| 2 | S5 | Tutorial slides screen with a reusable trick list (UI) | unblocks 3, value 5 | This is the core of part (1): the three slides, arrows, Start and the checkbox. The trick list is built as its own component so the pause panel shows the same list. | covered | T-382, T-381 |
| 3 | S2 | Script-drawn trick illustrations, one set of seven | unblocks 3, value 4 | This is one of the two candidate sets the board asked for, so QA can compare it against PixelLab. It costs no generations. | covered | T-383 |
| 4 | S3 | PixelLab trick illustrations, one set of seven (art cap 40) | unblocks 2, value 4 | This is the second candidate set the board asked for, made with PixelLab. | in-flight | T-384 |
| 5 | S4 | QA compares the two sets and the better one goes into game/art | unblocks 1, value 5 | The board asked QA to compare which set reads better and to use the better one. | in-flight | T-385 |
| 6 | S7 | Trick list button and sub-panel in the pause screen (UI) | unblocks 1, value 4 | This is part (3): the same trick list, reachable from the pause screen, with a way back. | in-flight | T-386 |
| 7 | S6 | Start shows the slides before the run (Game Loop) | unblocks 0, value 5 | The slides must sit between the main menu's Start and the run, before the clock and everything else begins, and must respect 'Don't show again'. | in-flight | T-387 |
| 8 | S8 | Sound effects off for the MVP and the SFX slider hidden (SFX / UI) | unblocks 0, value 5 | This is part (4): every sound effect silent and the slider hidden, with the music and the sound code kept. | in-flight | T-388, T-389 |
| 9 | S9 | Swap the chosen illustrations into the slides and the pause trick list | unblocks 0, value 5 | The functional work starts with placeholders, so the chosen art has to replace them in both places. | in-flight | T-390 |

### S1: Text ticket: every text in the tutorial slides and the pause trick list (Narrative Theme)

Needs: nothing.

- A data file (for example game/data/tutorial_text.json) holds every string, each with a key and a comment saying where it appears: slide 1 controls (W, A, S, D, and that accelerating while turning drifts the car), slide 2's seven trick names and the tricks → viewers → subs → gift pack with weapons text, slide 3's goal text (chain tricks, most weapons, strongest when the kaiju arrives with 1 minute left), the Start button, the 'Don't show again' checkbox, the arrow buttons' accessible labels, the pause screen's trick list button and the panel's back control.
- Each new line scored 8 or more in the style loop, with the rounds written in the ticket's Style review.
- HUD and menus, Content has a section listing the texts and their keys.
- No line uses the form 'Greenbull says ...' (HUD and menus, Decisions).

### S5: Tutorial slides screen with a reusable trick list (UI)

Needs: S1.

- A slides scene (for example game/scenes/menu/tutorial_slides.tscn) shows three slides with left and right arrows. Slide 1 has no left arrow and slide 3 has no right arrow, or pressing them does nothing. Slide 3 has the Start button and the 'Don't show again' checkbox. It emits a signal when Start is pressed, carrying the checkbox state.
- Slide 2's trick list is a separate scene (for example trick_list.tscn) showing the seven tricks, each with its name from S1 and an illustration loaded from one fixed path per trick, with a code-drawn placeholder (not in Greenbull's colours) while the file is missing.
- All visible text is read from S1's data file. No player-facing string is hard-coded in the scripts.
- The arrows and Start work with the mouse and with the keyboard. Keyboard controls and focus are the agent's proposal and are written in the ticket.
- A setting such as 'tutorial_hidden' is added to game_settings.gd, saved and loaded with the other settings, false by default. Unit tests cover the save and load round trip.
- Scene tests cover the arrow navigation and the Start signal. Screenshots of all three slides are saved.
- HUD and menus, Content describes the slides screen, and game/docs/hud-and-menus/ has a page on how it is built.

### S2: Script-drawn trick illustrations, one set of seven

Needs: nothing.

- A script in tools/ draws seven still PNGs, one per trick (drift, 360, alternate drift, air 180, air 360, airtime, thread the needle), each showing the car's movement as a path, for example a loop for the 360, an S for the alternate drift and a jump arc for the air tricks. They are saved in art-archive/<task>/script/.
- Each PNG passes the pixel-art script check (Visual style, Rules 1 and 6): hard edges, fully opaque or fully transparent pixels, transparent background, at most 30 colours, no Greenbull light green or yellow on non-Greenbull elements.
- All seven are the same size, and the ticket records it.
- The style loop scores are written in the ticket, and a preview sheet with all seven, enlarged on dark and light backgrounds, is saved.

### S3: PixelLab trick illustrations, one set of seven (art cap 40)

Needs: S2.

- Seven still PNGs, one per trick, are saved in art-archive/<task>/pixellab/, at the same size as S2's set so the two compare like for like.
- The ticket's result notes list each PixelLab call and the running total, with no more than 40 generations in all and at most 4 per illustration (the style loop).
- Each PNG passes the pixel-art script check (Visual style, Rules 1 and 6).
- The style loop scores are written in the ticket, and any illustration below 8 after its refines is noted for the final playtest.
- A preview sheet with all seven, enlarged on dark and light backgrounds, is saved.

### S4: QA compares the two sets and the better one goes into game/art

Needs: S2, S3.

- A side-by-side comparison sheet of both sets (each trick in a row, enlarged on dark and light) is saved in art-archive/<task>/.
- The ticket records QA's verdict per trick and overall, with reasons, and which set was chosen (a whole set, or per trick if the ticket says so; see open questions).
- The chosen seven PNGs are copied into game/art/tutorial/tricks/ (or the path the ticket names), one file per trick named by the trick id used in game/docs/driving/tricks.md. The other set stays in art-archive.
- Visual style, Decisions records the illustrations and which method won.

### S7: Trick list button and sub-panel in the pause screen (UI)

Needs: S1, S5.

- The pause screen has a trick list button with S1's text. Pressing it shows a sub-panel holding the same trick list scene as slide 2 (the seven tricks with names and illustrations), with none of slide 2's other text.
- A back control with S1's text returns to the pause screen with its sliders, checkboxes and buttons unchanged. The run stays paused throughout.
- The panel fits on screen at 1152 x 648 and keeps clear of the HUD timer and clock. Screenshots of the pause screen and the open panel are saved.
- Mouse and keyboard both work. What Escape does while the panel is open is the agent's proposal and is written in the ticket.
- Scene tests cover opening and going back.
- HUD and menus, Content, 'Pause screen' lists the new button and panel.

### S6: Start shows the slides before the run (Game Loop)

Needs: S5.

- With tutorial_hidden false, the main menu's Start shows the slides screen. The run is created, or its clock starts, only when the slides' Start is pressed. A test checks that the clock reads 8:00 and does not tick while the slides are up.
- If the slides' Start is pressed with the checkbox ticked, tutorial_hidden is saved as true, and the next Start (also after a restart of the game) goes straight into the run. Tests cover both paths.
- Pause screen Restart still starts a fresh run directly, without the slides (the decision says 'when the player presses Start').
- Game loop architecture, Decisions and its flow diagram show the slides step between Start and the run.

### S8: Sound effects off for the MVP and the SFX slider hidden (SFX / UI)

Needs: nothing.

- One switch in data or code (for example sfx_enabled = false in game/data/sfx.json or game_settings.gd) turns every sound effect off, whatever the saved SFX volume. A test plays each sound effect id and checks that nothing is audible (the SFX bus is muted, or no player starts).
- The SFX volume slider row is hidden from the pause screen, and the strip's layout closes the gap. The music volume slider still shows and still changes the music. Tests cover both.
- The music keeps playing in the menu and during runs. A test checks that the music player runs.
- The sound-effect scripts, game/data/sfx.json and the saved SFX volume setting are still present (no files deleted).
- HUD and menus, Content, 'Pause screen' and the relevant decision note record that the SFX are off and the slider is hidden for the MVP. A pause screen screenshot is saved.

### S9: Swap the chosen illustrations into the slides and the pause trick list

Needs: S4, S5, S7.

- Slide 2 and the pause trick list panel both show the seven PNGs from game/art/ picked in S4, with no placeholder left. A test checks that each trick's texture loads from its file.
- The illustrations draw with nearest filtering at a whole-number scale (hard pixel edges). Screenshots of slide 2 and the open pause panel are saved.
- The placeholder drawing code is removed or no longer used, and the files it drew for are documented.

## Scoring

Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. A sub-goal is therefore always ranked before every sub-goal that needs it. A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.

## Tickets

- T-381: Text: the tutorial slides and the pause screen's trick list (S1, written)
- T-382: The tutorial slides screen, with a reusable trick list scene (placeholder illustrations) (S5, written)
- T-383: Art: the seven trick illustrations, drawn by script (S2, written)
- T-384: Art: the seven trick illustrations with PixelLab (art cap 40) (S3, written)
- T-385: QA: compare the script and PixelLab trick illustrations, and copy the better set into game/art (S4, written)
- T-386: A trick list button in the pause screen, opening a panel with the trick list (S7, written)
- T-387: Start shows the tutorial slides before the run, unless hidden (S6, written)
- T-388: Every sound effect off for the MVP, with one switch; the music stays (S8, written)
- T-389: The pause screen hides the SFX volume slider for the MVP (S8, written)
- T-390: The chosen trick illustrations in slide 2 and the pause trick list, placeholders retired (S9, written)

## Iteration log

- 2026-10-29, iteration 0: started: planning, by the session Greenbull.
- 2026-10-29, iteration 0: priority scoring: 9 sub-goals ranked, 10 goal criteria, 12 open questions.
- 2026-10-29, iteration 0: gap detection: 0 covered, 0 in flight, 9 missing; wrote 10 tickets.
- 2026-10-29, iteration 0: building.
- 2026-10-29, iteration 0: paused (see Pauses).
- 2026-10-29, iteration 0: resumed: its last pause (command: a command the runner ran was refused or failed) can't be checked by the runner; --force.
- 2026-10-29, iteration 0: resumed by the session Greenbull.
- 2026-10-29, iteration 0: resumed from building.
- 2026-10-29, iteration 0: resumed by the session Greenbull.
- 2026-10-29, iteration 1: T-381 (S1, narrative-theme, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-007; art 0; agent: (nothing new). Refused, got past and not blocking: QA: {"tool_input": {"command": "python tools/qa_check.py T-381 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_019rKCDYVgFnVQ5gCWTtwcXb"} / QA: {"tool_input": {"command": "python -c \"import json;json.load(open('game/data/tutorial_text.json'));print('ok')\""}, "tool_name": "Bash", "tool_use_id": "toolu_011vj6dXbHa8qkukSJzuzHkr"} / QA: python tools/qa_check.py T-381 --no-marks (not pre-approved, needs approval) / QA: python -c json.load parse of game/data/tutorial_text.json (not pre-approved). Rescan: S1 covered, S5 in-flight, S2 in-flight, S3 in-flight, S4 in-flight, S7 in-flight, S6 in-flight, S8 in-flight, S9 in-flight.
- 2026-10-29, iteration 2: T-382 (S5, ui, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-007; art 0; agent: T-382 done and committed. The three-slide tutorial screen, a separate trick list scene with code-made placeholders, and the tutorial_hidden setting are built. Illustration size is 64x48 at scale 3. Keyboard keys, focus order and docs are written up. All three test sets pass and screenshots are in art-archive/T-382/screenshots/. Refused, got past and not blocking: ui: {"tool_input": {"command": "python - <<'EOF'\np='game/scripts/menu/tutorial_slides.gd'\ns=open(p).read()\ns=s.replace(\"c + Vector2(-18 * d, 0), c + Vector2(18 * d, -32), c + Vector2(18 * d, 32)\",\"c + Vector2(18 * d, 0), c + Vector2(-18 * d, -32), c + Vector2(-18 * d, 32)\")\nopen(p,'w').write(s)\nEOF"}, "tool_name": "Bash", "tool_use_id": "toolu_01DgdsMSBoWg1iY6SSiHH1aW"} / QA: {"tool_input": {"command": "python tools/qa_check.py T-382 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_01DUx49fTsTMnPULvY8uVWo3"} / QA: `python tools/qa_check.py T-382 --no-marks` was refused ("requires approval"); not worked around, criteria checked by hand.. Rescan: S5 covered, S2 in-flight, S3 in-flight, S4 in-flight, S7 in-flight, S6 in-flight, S8 in-flight, S9 in-flight.
- 2026-10-29, iteration 2: paused (see Pauses).
- 2026-10-29, iteration 2: resumed: its last pause (command: a command the runner ran was refused or failed) can't be checked by the runner; --force.
- 2026-10-29, iteration 2: resumed by the session Greenbull.
- 2026-10-30, iteration 3: T-383 (S2, asset-generation, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-007; art 0; agent: T-383 done and committed: script draws seven 64x48 trick PNGs, 7 tests pass, previews and trick-list screenshot saved. The style loop kept each at 6–7/10 (below 8); the full report is in the ticket's result notes. Refused, got past and not blocking: QA: {"tool_input": {"command": "python tools/qa_check.py T-383 --no-marks"}, "tool_name": "Bash", "tool_use_id": "toolu_013JeU9qdpPuBDUoQpr83NU5"} / QA: `python tools/qa_check.py T-383 --no-marks` was refused (needs approval; not in the pre-approved list). I did not work around it and did the checks by hand. The final `qa_check.py` run was skipped too.. Rescan: S2 covered, S3 in-flight, S4 in-flight, S7 in-flight, S6 in-flight, S8 in-flight, S9 in-flight.

## Pauses

- 2026-10-29 [command]: A command the runner ran was refused or failed: C:\Users\andre\AppData\Local\Programs\Python\Python313\python.exe C:\solid-carbide-game\tools\task_status.py T-381 in-qa --reply Goal runner (G-007): the agent is done; QA is checking it.: Refused. T-381 can't move flagged-for-review → in-qa: flagged-for-review can't move to in-qa. Allowed now: in-progress, open, done, cancelled.
- 2026-10-29 [command]: A command the runner ran was refused or failed: C:\Users\andre\AppData\Local\Programs\Python\Python313\python.exe C:\solid-carbide-game\tools\task_status.py T-383 in-qa --reply Goal runner (G-007): the agent is done; QA is checking it.: Refused. T-383 can't move flagged-for-review → in-qa: flagged-for-review can't move to in-qa. Allowed now: in-progress, open, done, cancelled.


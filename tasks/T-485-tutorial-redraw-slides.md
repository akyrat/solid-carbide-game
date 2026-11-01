---
id: T-485
title: Build the redrawn tutorial slides: four slides with keycaps, the loop chain, the clips, missions and the run timeline
status: open
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
qa_rounds: 0
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

- [ ] Tests show four slides in the order Drive, Tricks bring gifts, Missions, Survive the stream, the dots show four, and Skip goes to slide 4. (QA: pass / fail)
- [ ] Tests show each slide's texts come from tutorial_text.json's new keys (none from code) and the retired keys are no longer used. (QA: pass / fail)
- [ ] Tests show the clips play (frames advance with their timing) on slides 1 and 2, and the pictures on slides 2 to 4 are the game's own art files. (QA: pass / fail)
- [ ] Tests show Go live starts the run and Don't show again still works, with only fresh key presses counting, as before. (QA: pass / fail)
- [ ] Screenshots of all four slides at 1280 x 720 are saved and listed in the result notes, next to the draft for comparison. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) describes the four slides. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent: its new and changed test files and those of the scripts it touched, with `bash game/tools/run_tests.sh -gtest=res://tests/unit/<file>.gd` per file), and QA's full run passes (the Godot set and `python -m unittest discover -s game/tools -p "test_*.py"`; the tools set only if tools/ changed; tasks/README.md, "Which tests run when"), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

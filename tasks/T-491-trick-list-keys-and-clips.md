---
id: T-491
title: The trick list shows each trick's clip, live key pad and keycap recipe; slide 2's clips get the key pad
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
depends_on: [T-489, T-490]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/menu/tutorial_slides.gd, game/scripts/menu/clip_player.gd, game/data/tutorial_text.json, game/docs/hud-and-menus/pause-screen.md, C:/Users/andre/AppData/Local/Temp/claude/C--solid-carbide-game/89bfdaa9-8914-40ee-9f4b-4fc6ef5a226d/scratchpad/tricks/tricks.template.html]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/scripts/hud/, game/data/, game/tests/unit/, docs/hud-and-menus.md]
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

The board, 2026-11-01 (HUD and menus, Decisions, "Each trick shows the keys that make it"), following the Project Lead's draft page (its template is in files_to_read_first; open the built page `.../scratchpad/tricks/trick-controls.html` in a browser to see it). The board approved merging this straight after QA.

1. **A live key pad** (a reusable piece): a small W A S D pad in a clip's bottom-right corner, each key lit while the clip's key timeline (T-490's per-frame field in the sheet JSON) says it is held, in step with ClipPlayer's frame. Look as on the draft page (keycaps in the HUD style, the lit key in the blush colour, pressed down a little).
2. **Tutorial slide 2:** its three clips get the pad. Nothing else on the slide changes.
3. **The trick list** (pause screen): for each of the seven tricks its name, its rule (T-489), its clip (T-490's) with the pad, and its keycap recipe: the keys as keycaps joined with +, steps joined with an arrow, the note under each step, the badge for a step with no keys, and a small /D tag on a key where either turn key works (draft: the TRICKS array's `recipe` on the page). THREAD THE NEEDLE! shows its clip and rule but no recipe. Lay it out so it is not crowded at 1152 x 648 inside the pause strip: for example the seven trick names (with their illustrations) as a list, and the selected trick shown large on the right with its clip, pad, rule and recipe; keyboard and mouse both select. Back, Escape and focus behave as today. Clips load when shown and are freed when hidden (T-485's web memory rule).
4. The recipe's structure (which keys per step, which text key for each note, the /D marks) is data in game/data (a new JSON file); the texts come from tutorial_text.json (T-489's keys), never from code.

Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Tests show the key pad lights exactly the keys of the clip's key timeline for the current frame (for example alt_drift's S + A frames light S and A only). (QA: pass / fail)
- [ ] Tests show slide 2's three clips each have the pad, and the rest of slide 2 is unchanged (its existing tests pass). (QA: pass / fail)
- [ ] Tests show the trick list has all seven tricks; each of six shows its recipe (keycaps, notes, badges, /D marks from the data file) and THREAD THE NEEDLE! shows none; each shows its clip with the pad; texts come from tutorial_text.json. (QA: pass / fail)
- [ ] Tests show Back, Escape and focus in the trick list work as before, and clips are freed when the panel is hidden. (QA: pass / fail)
- [ ] Screenshots at 1280 x 720 of slide 2 and of the trick list with at least three different tricks selected are saved and listed in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content, "Pause screen" and the slides section) describes the pad and the new trick list. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent, with -gselect), and QA's full run passes (tasks/README.md, "Which tests run when"), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open

Filed: waits for T-489 (text) and T-490 (clips).

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

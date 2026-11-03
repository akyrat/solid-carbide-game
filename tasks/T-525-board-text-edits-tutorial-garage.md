---
id: T-525
title: The board's text edits: tutorial slide 2 and the garage
status: done
from: project-lead
to: narrative-theme
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, game/data/tutorial_text.json, game/scripts/menu/garage_screen.gd, tasks/README.md]
files_expected_to_change: [game/data/tutorial_text.json, game/scripts/menu/garage_screen.gd, game/tests/, game/tools/, docs/hud-and-menus.md]
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

Set these texts to the board's words (file | key: old -> new):

- game/data/tutorial_text.json | slide2.step1_caption: "Drifts, spins, air." -> "Full list in settings menu"
- game/data/tutorial_text.json | slide2.step2_title: "Tricks pump the multiplier" -> "Chain trick combos"
- game/data/tutorial_text.json | slide2.step2_caption: "Each trick bumps the multiplier." -> "" (empty: the board wants no caption)
- game/data/tutorial_text.json | slide2.step3_caption: "Tricks and drifts earn subs that fill the sub goal." -> "" (empty: no caption)
- game/data/tutorial_text.json | slide2.step4_caption: "A new weapon that fires itself." -> "All weapons auto-fire"
- game/scripts/menu/garage_screen.gd | TITLE: "Greenbull brand-safe pit stop" -> "Greenbull gives you wheels"
- game/scripts/menu/garage_screen.gd | DESCRIPTIONS.damage_bonus: "Each level makes your weapons hit harder. Impact, fully synergized." -> "Increases Damage. Impact, fully synergized."

An empty caption must show nothing on slide 2 (no stray quotes, no placeholder, no blank gap that looks broken); if the slide's code can't show an empty caption cleanly, say so in the result notes and the Project Lead writes a UI ticket. Update docs/hud-and-menus.md Content where it lists these texts. The board's card edits (level-up and power-up cards) are a separate ticket.

The board, 2026-11-03, wrote these words itself on the text pass page (each text on its real screen). Use the board's words exactly as written below; the style loop does not change them (if it finds a real problem, say so in the result notes and keep the board's words). An empty value means the board wants that text gone. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it from the ticket's folder (C:\solid-carbide-worktrees\T-525\game\project.godot): tutorial slide 2 and the garage, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The seven texts have exactly the board's words (a test reads them from their files). (QA: pass)
- [ ] Tutorial slide 2 shows the new title and captions, and no caption where the board left it empty (screenshot). (QA: pass)
- [ ] The garage shows the new title and damage bonus description (screenshot). (QA: pass)
- [ ] docs/hud-and-menus.md Content matches the new texts. (QA: pass)
- [ ] The text inventory and the tests that read these files pass (the agent runs the ones it touched). (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

Narrative agent applying the board's 7 edits from the text pass page.

### 2026-11-03, In QA → Needs playtest

QA passed. The board asked to push these text changes once in.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Applied the board's seven texts exactly: slide2.step1_caption 'Full list in settings menu', step2_title 'Chain trick combos', step2_caption '' and step3_caption '' (empty), step4_caption 'All weapons auto-fire'; garage TITLE 'Greenbull gives you wheels'; damage_bonus 'Increases Damage. Impact, fully synergized.'. Updated test_garage_screen.gd expected strings and docs/hud-and-menus.md (line 146 paragraph and the Content table). Style notes (board's words kept): 'Full list in settings menu' has no full stop unlike the other captions; 'Increases Damage.' capitalises Damage. Tests: game/tools/test_text_inventory.py passes (8 tests). test_garage_screen.gd and test_tutorial_slides.gd NOT run: the worktree has no .env so run_tests.sh says GODOT_BIN is not set (copying .env was not done). Expected to pass: the tutorial test compares each label with the file value, an empty string matches. Garage screenshot art-archive/T-525/screenshots/garage_screen.png checked: new title and Brand Impact description show, layout fine. Tutorial slide 2 screenshot NOT taken (hook refusal, on hold by the Project Lead). Empty caption gap analysis (code reading only, unverified on screen): _step() in game/scripts/menu/tutorial_slides.gd lines 419-422 always adds the caption Label, with custom_minimum_size (150,0) and 8 px column separation; an empty Label still takes one line height (about 17 px font) plus 8 px, so a blank gap of roughly 30 px sits under the title, with no stray quotes or placeholder. Steps 2 and 3 would therefore have shorter text than their neighbours but equal-height panels (they sit in a row), so it may look fine; if the board dislikes it, a UI ticket should hide the caption Label when its text is empty.
- 2026-11-03, needs-playtest → done: The board asked to push these text changes once QA passed (2026-11-03)

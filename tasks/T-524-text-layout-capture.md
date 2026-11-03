---
id: T-524
title: Text layout capture: every player-facing text with its screen, blanked background, rect and font
status: in-qa
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [game/docs/hud-and-menus/hud.md]
files_to_read_first: [game/tools/screen_gallery.py, game/tools/screen_gallery.gd, game/tools/text_inventory.py, docs/hud-and-menus.md, tasks/README.md]
files_expected_to_change: [game/tools/screen_gallery.py, game/tools/screen_gallery.gd, game/tools/, game/docs/hud-and-menus/hud.md]
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

Add a text layout capture to the screen gallery (game/tools/screen_gallery.py and screen_gallery.gd, T-479), for example `python game/tools/screen_gallery.py --text-layout --out screenshots/text-editor` (output git-ignored, outside game/). For every screen and state the gallery reaches, and the extra states needed to show each kind of text (main menu, tutorial slides, pause and settings, HUD with combo multiplier, missions note, sub goal counter, clock, trick popups, multiplier gain/loss, heal popup, level-up screen with a weapon card and a power-up card, a new-weapon card, garage, recap, wrecked, any other popup or banner the text inventory lists):

1. Two 1280x720 PNGs: `<screen>.png` exactly as the player sees it, and `<screen>_blank.png` with the text of every captured text node set empty (everything else unchanged, same frame/animation state as far as possible).
2. A manifest `text_layout.json` with one row per visible text node: screen id, node path, node class (Label, Button, RichTextLabel, LineEdit, CheckBox...), current text (and BBCode for RichTextLabel), the rect in screenshot pixels (global, after any scaling; rotation in degrees if any), font file (repo path) or the theme default's file, font size, font colour, outline size and colour, shadow colour/offset if any, horizontal and vertical alignment, autowrap mode, uppercase, line spacing, max lines, clip/overrun behaviour, and the matching text inventory row (text_inventory.py: source file and key) when the text matches one.
3. Repeated layouts are templates: for components that show many texts in the same place (level-up weapon card title and description, power-up card, missions note line, trick popup, recap lines, tutorial slide body), capture one instance and list in the row every inventory key that renders into that node (`template_keys`), with each key's text.
4. Copy every font file the rows use into the output folder (`fonts/`).
5. `not_capturable` in the manifest: player-facing text drawn another way (draw_string, Label3D, text baked into a sprite) with its screen and source, so the board knows it is missing.
6. A coverage summary: how many text inventory rows (text_files and code) are matched to a captured node or a template, and the list of unmatched rows with a reason when known.

Keep it one command, standard library on the Python side. Document it in game/docs (the screen gallery's doc) and the tool's docstring. Take one screenshot pair (normal and blank) as the ticket's screenshots in art-archive/T-524/screenshots/.

The board, 2026-11-03: the board wants a page (built by the Project Lead as a claude.ai artifact) to go through ALL user-facing texts, see the actual in-game picture of each one, and type new words that appear on the real asset in place, so it can judge how each will look in game. This ticket builds only the capture tool that feeds that page; the page itself is the Project Lead's. It is tooling the player never meets, so it merges after QA without a playtest. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] One command writes, for each screen it reaches, `<screen>.png` and `<screen>_blank.png` at 1280x720, and `text_layout.json` (checked by running it and by a Python test of the manifest checker). (QA: pass)
- [ ] Each manifest row has: screen, node path, class, text, rect, font file, font size, font colour, outline, alignment, autowrap, and the inventory source/key when matched (a Python test validates the schema on the real output). (QA: pass)
- [ ] The level-up weapon card, the power-up card, the missions note line and the trick popup are templates with `template_keys` listing every inventory key that renders into them (checked in the output). (QA: pass)
- [ ] The font files the rows name are copied into `fonts/` in the output folder. (QA: pass)
- [ ] The coverage summary lists matched and unmatched inventory rows; at least 80% of the text_files rows are matched or covered by a template (printed by the tool; the reasons for the rest are listed). (QA: pass)
- [ ] `not_capturable` lists any player-facing text that is not drawn by a Control, with screen and source (empty list allowed if none). (QA: pass)
- [ ] The screen gallery's existing tests and the new tests pass; the game's Godot test set is unchanged and passes. (QA: pass)
- [ ] Screenshots: a normal and blank pair in art-archive/T-524/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-03, Open → In progress

UI agent started on the text layout capture for the text editor page.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built the text layout capture. One command: GODOT_BIN set, python game/tools/screen_gallery.py --text-layout --out screenshots/text-editor (about 15 s, real window). New: game/tools/text_layout.gd (Godot half: finds text nodes, resolves font/size/colours/outline/shadow/alignment/wrap through theme overrides, LabelSettings and theme defaults, rect = axis-aligned box of the node's transform in screenshot pixels, blanks without moving anything), game/tools/text_layout.py (inventory match, templates, fonts, not_capturable, coverage, manifest checker), game/tools/test_text_layout.py (23 tests incl. the schema on the real output). Changed: screen_gallery.gd/.py (--text-layout; the normal gallery is unchanged), game/docs/hud-and-menus/hud.md (section 'The text layout capture (T-524)'). Output (screenshots/text-editor, git-ignored): 25 screens, each <screen>.png + <screen>_blank.png at 1280x720, text_layout.json, fonts/ (Bangers, Press Start 2P, and Godot's built-in default Open Sans SemiBold written out of the engine, since the garage/menus/cards use it and it is no game file), 392 rows, 27 not_capturable entries. Coverage: text_files 196/220 (89.1%), code 43/49 (87.8%); every unmatched row has a reason (runs list not in game, UNUSED since T-484, tooltips, kicker pieces, God mode aside; remaining: recap button.close, power_ups.take_button, levelup.take, SCORE_TEXT, SFX/zoom-min-max pause labels, slide1.drift_rule drawn in pieces). Extra states added in text mode only: tutorial slide 4, combo multiplier, multiplier loss, heal popup, God mode entry and page. Blank design: the pair is taken in one frame with Engine.time_scale 0; Label/RichTextLabel get self_modulate alpha 0 (not visible_characters, which made containers collapse), Buttons/LineEdits get transparent text+outline colours (icons stay), baked popups / time's up card / clock digits are hidden whole. Checks per screen are in the manifest: text_nodes_still_showing_in_blank is 0 on all 25; pixels_changed_outside_text is 0 on 19 screens and small (28 to 2856 px) on the 6 that have real-time animation (tutorial clips, helicopter). Things the page must know: (1) kind 'baked_popup' (trick popups, heal popup, combo broken), 'baked_card' (time's up headline) and 'art_digits' (clock) are pictures, not Controls: the blank hides them whole, rect is the plain bubble the text sits in and art_rect the full picture with rings/flames; the page must redraw them itself, they are also listed in not_capturable. (2) Control rows: Button colour is for its current state (color_state); RichTextLabel h_align is 'left' because centring is in its bbcode. (3) rect is the node's box, not the ink: a text sits inside by h_align/v_align and padding. (4) Matching: node text equals an inventory text with {placeholders}/%d as wildcards, case-folded as second try; inventory_also lists other keys with the same text. Not done / limits: tooltips (arrow.left/right) cannot be captured; text baked into plain art PNGs is undetectable and not listed; the Godot test set was not rerun (no game script or test changed; only tools/). Tests: python -m unittest game/tools/test_text_layout.py game/tools/test_screen_gallery.py game/tools/test_text_inventory.py: 35 OK. Screenshots: art-archive/T-524/screenshots/ (level_up_gift_pack and garage, normal + blank).
- 2026-11-03, in-progress → in-qa: text layout capture ready for QA

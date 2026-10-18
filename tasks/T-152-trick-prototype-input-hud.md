---
id: T-152
title: "Trick prototype: the live arrow-key HUD and the trick confirmation animation"
status: cancelled
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: final-release
user_facing_text: yes
changes_visuals: yes
depends_on: [T-150]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, tasks/T-150-trick-prototype-text.md, tasks/T-151-arrow-key-trick-prototype.md, game/README.md]
files_expected_to_change: [the trick prototype scene from T-151, new UI scenes and scripts, tests under game/tests/, game/README.md]
model: sonnet
qa_rounds: 1
---

## Description

Builds on T-151's trick prototype (the work happens on a branch made from T-151's branch). Two pieces, both in the trick prototype scene only:

1. **Live arrow-key HUD, bottom-right corner.** Four arrow keys in the usual keyboard layout (Up on top; Left, Down, Right below), each drawn as a small key with an arrow. A key lights up while it is held and goes back when released, so the board sees its live input. Show the progress of the current sequence too: the keys already matched in the trick's sequence get a clear "matched" look (for example a yellow ring), which resets when the sequence resets. Keep 16 px from the screen's edges. Use the label from T-150 item 2 above the keys, or none if T-150 says none.
2. **Trick confirmation animation.** When `trick_performed` fires, a short, punchy comic-style confirmation plays: the trick's name from T-150 item 1, in the game's comic look (Bangers font, hard pixel edges, white rounded card with black border, as the trick popups and the combo counter; HUD and menus), popping in big with an overshoot, holding briefly and leaving (about 1 s in all). The arrow-key HUD celebrates too (for example all four keys flash yellow once). Never Redgull red.

Use exactly T-150's text; no other words.

Tests: the key highlight follows pressed and released keys, the matched look follows the sequence progress and resets, and the confirmation shows the right text on `trick_performed`.

## Acceptance criteria

- [ ] The four arrow keys show in the bottom-right corner, 16 px from the edges, in the keyboard layout. (QA: pass) screenshot shows keys in keyboard layout, right/bottom edges at 16 px (1136, 632.; test_keys_in_bottom_right_with_label passes)
- [ ] A test shows each key's highlight turns on while held and off on release. (QA: pass) test_highlight_follows_held_keys.
- [ ] A test shows matched steps get the matched look and reset when the sequence resets. (QA: pass) test_matched_follows_progress_and_resets.
- [ ] On `trick_performed` the confirmation animation shows exactly T-150's text in the comic look and goes away after about 1 s (test or scripted run). (QA: pass) card shows SIDE FLIP! in Bangers on white rounded card with black border; test_confirmation_on_trick_and_goes_away; 1 s fade.
- [ ] No text other than T-150's appears, and nothing uses Redgull red. (QA: pass) only TRICK and SIDE FLIP! (T-150.; no Redgull red in code or screenshots)
- [ ] `game/README.md` describes the HUD and the confirmation. All three test sets pass. (QA: pass) README documents HUD; GUT 874/874, game/tools Python 278 OK, tools Python 182 OK.

The board's review: play the trick prototype together with T-151 and T-153 (one playtest build).

## Updates

### 2026-10-16, Open → In progress

Started: the UI Agent builds the arrow-key display (bottom right, label TRICK) and the SIDE FLIP! confirmation on top of T-151's prototype.

### 2026-10-16, In QA

Built: arrow keys bottom right with the TRICK label, yellow rings for matched steps, and the SIDE FLIP! card popping in on a completed sequence. QA is checking it now.

### 2026-10-16, Needs playtest

QA passed all 6 criteria; waiting for your playtest in the combined trick build.

### 2026-10-16, Needs playtest

Ready to play in one build: open C:\solid-carbide-worktrees\playtest-tricks\game\project.godot, open scenes/trick_prototype/trick_prototype.tscn and press F6. Arrow keys Up, Right, Down, Left for the side flip.

## Result notes

Built `scripts/hud/trick_hud.gd` (TrickHud) and added it to `trick_prototype.gd` (only 5 lines; T-151's driving and flip code untouched). Arrow-key HUD bottom right (TRICK label, 16 px margin, held = white, matched = yellow ring, resets on sequence reset), SIDE FLIP! card with pop-in overshoot, hold, fade over 1 s, and all four keys flash yellow 0.35 s. Text exactly T-150's; no red. Tests: `game/tests/unit/test_trick_hud.gd` (5 tests, confirmed run). All three sets pass: GUT 874/874, game/tools Python 278 OK, tools Python 182 OK. No screenshot taken. Documents affected: game/README.md.
- 2026-10-19, needs-playtest → cancelled: Board, 2026-10-19: building the trick prototype before an elevation system was a mistake. Not merged; kept as the reference for rebuilding the tricks on real height (Drifting, Content, 'Trick prototype (reference)'); code on the branch hold/trick-prototype, art in art-archive/.

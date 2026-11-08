---
id: T-599
title: A setting to turn off the trick popups
status: in-progress
from: project-lead
to: ui
lead: Rails
epic: hud
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/hud/trick_popups.gd, game/data/hud.json, tasks/T-596-no-needle-popup.md, tasks/T-571-main-menu-settings-screen.md]
files_expected_to_change: [game/scripts/hud/, game/scripts/ui/, game/scripts/data/, game/data/, game/tests/, game/docs/]
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

Build HUD and menus, Decisions, "A setting to turn off the trick popups". This branch starts from T-596's (the needle popup hidden by data, TrickPopups.is_hidden()), which waits for the board's playtest; build on it. Add a checkbox with T-598's label to the settings, shown in the pause screen's settings and in the main menu's Settings screen (T-571), on by default and saved with the other settings. Off: TrickPopups shows no trick popup at all, in a run and in the tutorial's practice window; every trick still counts, still raises the combo and missions, pairs still flash and routes still advance. Turning it on again shows them from the next trick. Only trick popups; the multiplier popup and other HUD stay as they are.

The board's review: play it from C:\solid-carbide-worktrees\T-599\game\project.godot: turn it off in the main menu's Settings, play a run, drift and grind with no bubbles and the combo rising; turn it on from the pause screen and see them again.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The checkbox shows in the pause screen's settings and the main menu's Settings screen with T-598's label, on by default, and is saved (tests). (QA: pass / fail)
- [ ] Off: no trick popups in a run or the practice window; tricks still count and raise the combo (tests). (QA: pass / fail)
- [ ] On again: popups return from the next trick (a test). (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content describes it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-599/screenshots/ show the checkbox in both settings screens and a run with it off. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the Trick popups checkbox in both settings screens.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built on T-596/T-598. GameSettings.load/save_trick_popups_enabled (graphics.trick_popups_enabled, default on); TrickPopups.is_hidden() returns true when it is off (read at each trick, so on again shows from the next trick; covers run and practice window, same node; multiplier/broken/heal popups untouched). Checkbox 'Trick popups' (T-598 text) last in the pause screen's settings and the main menu Settings screen. Pause screen's checkbox row is now an HFlowContainer (6 boxes would reach the weapon icons), wraps to a second line. Tests: new in test_settings_screen.gd (both screens, default, saved) and test_thread_the_needle.gd (off hides every popup, combo still rises, on again shows); updated test_settings_screen, test_shared_button. Docs: docs/hud-and-menus.md Content 'The Trick popups checkbox', game/docs/hud-and-menus/main-menu.md. Full GUT run: 3253 tests, 3251 pass, 1 timing-only fail under load (test_bricks_perf, 7 ms vs 5 ms, passes solo 3/3; an earlier run had only the layout and count failures I then fixed). Python game/tools unittest: 1193 ok (4 skipped). Screenshots: art-archive/T-599/screenshots/ (t599_settings.png, t599_pause.png with it ticked off, t599_run.png run with it off at x1.66, no bubbles); fixture game/tests/fixtures/t599_demo.gd.

Added test_the_trick_popups_setting_off_shows_no_popup_in_practice_but_the_trick_counts (game/tests/unit/run/test_practice_session.gd): the real practice session, setting off, alt drift counted (successes 1), no popup; on again, the next trick pops. test_practice_session.gd: 32/32 pass.

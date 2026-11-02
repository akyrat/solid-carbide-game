---
id: T-505
title: God mode: the secret settings entry and its page
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
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/hud/hud_style.gd]
files_expected_to_change: [game/scenes/, game/scripts/ui/, game/scripts/menu/, game/tests/unit/, docs/hud-and-menus.md]
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

The board, 2026-11-02 (docs/hud-and-menus.md, Decisions, "A secret God mode"): the page of the secret God mode. Once T-504's God mode is unlocked (N pressed during a run), the in-game settings (the pause screen's settings) show one more entry at the end, God mode, a shared button (T-446). It opens a small page: the title and its line, then two groups (weapons, driving power-ups), each row the item's icon, name, its tier in T-501's format, and − and + buttons that set the tier through T-504's API (from 0 to its last tier; the gun never below 1), and a back button. The page uses the shared button, the HUD style (T-429) and the screen scaling (T-494), works with mouse, arrow keys/WASD and Enter/Space like the other menus (T-492), and shows the change straight away. Texts come from T-501 (read its result notes for the keys): no placeholder text. Before N is pressed the entry is not there at all. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Before N is pressed in the session, the settings show no God mode entry; after it, the entry is there (unit or scene test). (QA: pass / fail)
- [ ] The page lists all six weapons and all five driving power-ups with their current tier, and − / + change it through T-504's API within 0 and the last tier (the gun never below 1) (test). (QA: pass / fail)
- [ ] The page works with the keyboard (arrows/WASD, Enter/Space) and the mouse, and uses the shared button (test_shared_button passes). (QA: pass / fail)
- [ ] Every text on the page and the entry comes from T-501's keys (no placeholder strings in the scene or script). (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots of the settings with the God mode entry and of the page at 1152x648 and 1920x1080, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-501's texts and T-504's God mode logic.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. God mode page and entry.
- game/scripts/ui/god_mode_page.gd (class GodModePage): the page. Rows built from run.god_mode.entries() (no hard-coded list); icon, name (recap weapon names / power-up names), tier text from pause_text.json (god_mode_tier_format, god_mode_not_owned), - and + call god.step(); Back and Escape close. Buttons are the shared button; dimmed (not disabled) at the ends so keyboard focus is never lost. Keyboard: explicit chain (up/down same side then Back, left/right swap - and +), WASD through KeyNav.handle_wasd.
- game/scripts/ui/pause_screen.gd: the God mode entry (god_mode_button) is created at the end of the run buttons row only when GodMode.unlocked (checked at pause and on unlocked_changed, so N pressed on the pause screen also shows it); before N it does not exist. open_god_mode() hides the strip and opens the page; Escape/resume close it.
- Texts all from game/data/pause_text.json god_mode_* keys (T-501). Page sits at y=56 so a fifth power-up (T-502) still fits 648.
- Tests: game/tests/unit/game/test_god_mode_page.gd, 8 passed (no entry before N, entry after, open/back, rows equal entries (6 weapons + all power-ups), tier text, -/+ limits through the API incl. gun >= 1, keyboard chain, Escape, shared buttons, no placeholders). test_shared_button.gd updated (pause screen now holds the page's buttons), 12 passed; test_pause_screen.gd and test_pause_restart_exit.gd pass.
- Screenshots: art-archive/T-505/screenshots/god_mode_{settings,page}_{1152x648,1920x1080}.png (fixtures tests/fixtures/t505_*).
- Docs: docs/hud-and-menus.md, Decisions, "A secret God mode": "As built" note added.

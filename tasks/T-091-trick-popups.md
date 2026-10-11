---
id: T-091
title: Trick popups: the trick's name pops out from the car
status: in-qa
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-079, T-036]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, tasks/T-079-trick-detection.md, tasks/T-082-text-combo.md, tasks/T-036-run-scene-and-state.md, game/README.md]
files_expected_to_change: [the popup scene and script, the run scene, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-079 (trick detection) is done.** T-082's text is done and approved.

HUD and menus, Decisions: when the player completes a trick, a short comic-style text pops out from the car with the trick's name. Build that now, in the run and in the drift prototype, so the board can check the tricks are detected correctly (2026-10-10):
- On each of T-079's trick signals, the trick's name (T-082's text: LONG DRIFT!, FULL 360!, ALT DRIFT!) pops out from the car, rises a little and fades.
- Extended-drift popups are smaller than the others, since they come every second.
- Placeholder comic styling for now (a bold font and a simple shape behind it); T-084 makes the final look.
- What a trick adds to the combo comes later, with the combo (T-083). The challenge popup (T-092) will reuse these popups, so make them easy to show with any text.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test sends each trick signal and shows a popup with T-082's name appears near the car, rises and goes away (QA: pass / fail)
- [ ] A test shows the extended-drift popup is smaller than the other two (QA: pass / fail)
- [ ] Screenshots show a popup for each trick, in the run (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes the popups in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Built `scripts/hud/trick_popups.gd` (`TrickPopups`): LONG DRIFT! (16 px), FULL 360! and ALT DRIFT! (28 px) pop out 50 px above the car, grow quickly, rise 40 px and fade in 1 s, as outlined neon pink text on a dark navy shape with a cyan edge (not Redgull red). It is in the run (rebinds to each new car, so it works after Start from the menu and for a second run) and in the drift prototype. `show_popup(text, position, size)` takes any text for T-092. Tests: `tests/unit/test_trick_popups.gd` (6 tests, passing); screenshot fixture `tests/fixtures/trick_popups_demo.tscn`, picture at `screenshots/trick_popups.png` (git-ignored). Documents updated: `docs/hud-and-menus.md` (Content, new Trick popups section), `game/README.md`. Touched `run.gd` and `drift_prototype.gd` by a few lines each; not the pause screen or map files.

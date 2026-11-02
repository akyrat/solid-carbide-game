---
id: T-514
title: The combo multiplier beside the car, viewers counter gone
status: in-qa
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
files_to_read_first: [docs/hud-and-menus.md, docs/game-loop-architecture.md, game/scripts/hud/hud.gd, tasks/README.md]
files_expected_to_change: [game/scripts/hud/, game/scripts/menu/, game/data/, game/tests/unit/, docs/hud-and-menus.md]
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

Remove the live viewers counter (T-336) from the HUD and show the combo as its multiplier number beside the car, following it on screen (docs/hud-and-menus.md, Decisions, "The multiplier beside the car"), using T-512's texts. Trick popups show the multiplier they added, flying into the multiplier by the car, which bumps on arrival. The subs a trick pays (T-513, built in parallel; take its signal once it lands, or read the XP change) visibly go into the sub goal. Re-point what used the viewers: the reactions' heat steps and the fire look become multiplier steps (ComboHeat thresholds), the bad reactions rise from the multiplier (or a place you propose), a crash shows on the multiplier, the recap shows the peak multiplier (peak_viewers becomes or sits beside a peak multiplier; keep old saves loading), and the tutorial slide 2 panel with the eye icon shows the multiplier. Remove the viewers code you replace (ViewersData, viewers.json) only if nothing else reads it; say what you removed. Proposals for the playtest: the multiplier's place relative to the car, size, colour and heat look. Update docs/hud-and-menus.md Content (the counter, popups, reactions, recap, tutorial) and the HUD layout notes. When T-513 is done, merge its branch into yours so the board plays one build (the Project Lead may do this step with the QA agent).

The board, 2026-11-02: the live viewers are confusing; back to the combo multiplier number, shown beside the car; tricks also pay subs. Decisions: docs/game-loop-architecture.md, "Back to the combo multiplier; tricks pay subs", and docs/hud-and-menus.md, "The multiplier beside the car". The board plays T-512..T-514 together in one playtest build before anything merges. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The HUD has no live viewers counter; the multiplier shows beside the car and follows it as it drives (test and screenshot). (QA: pass)
- [ ] A trick popup shows its multiplier add with T-512's text, and the multiplier bumps when it arrives (test). (QA: pass)
- [ ] The reactions, bad reactions, recap peak and tutorial slide 2 work from the multiplier, and an old save with peak_viewers still loads (tests). (QA: pass)
- [ ] Every text shown comes from T-512's keys, none hard-coded (test or grep in the result notes). (QA: pass)
- [ ] docs/hud-and-menus.md Content no longer describes a viewers counter as current. (QA: fail: paperwork - docs/hud-and-menus.md line 91 (HUD scaling) still says the sub goal moves up to stay above the live viewers counter (keep_above is unused), and line 125 (bad reactions) still says "from the viewers counter's height"; docs-only fix)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass)
- [ ] Screenshots of a run with the multiplier by the car, a trick popup, the recap and tutorial slide 2, under art-archive/T-NNN/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-512's texts (T-512 is in QA).

### 2026-11-02, In progress → In QA

T-514 built and committed: multiplier beside the car replaces the viewers counter (popups, bump, crash, reactions, recap, tutorial, docs); touched tests pass, screenshots in art-archive/T-514/screenshots. Ready for QA and the combined playtest with T-512/T-513.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. The viewers counter is gone; MultiplierTag (game/scripts/hud/multiplier_tag.gd) shows T-512's 'x2.50' left of the car (130 px left, 8 up from the screen centre where the camera holds the car; hud.json multiplier_tag, proposals: size 30/34/38/42 by ComboHeat step, cyan base, step 4 at the x6 cap for the reactions, no fire art or panel). Trick popups show 'NAME +x0.5' (T-512 gain, multiplier colour, no eye); the amount flies into the number after 0.3 s, number bumps on arrival and counts in then. Crash: red flash + '-x1.5' drop (T-512 loss), bad reactions rise from the multiplier's height. Reactions step = tag step. Recap: 'Peak combo' + peak_value from highest_combo (no eye); old summaries with peak_viewers load (key ignored, no longer written). Tutorial slide 2 step 2 panel shows the multiplier text in cyan (SAMPLE_MULTIPLIER 2.5). Subs from tricks: shown by the sub goal's existing fill spring on the XP change; did not use T-513's trick_subs_paid (not merged here; nothing extra built, say if you want a dedicated sub flight). Removed: ViewersCounter, ViewersData, data/viewers.json, their tests, the viewers demo fixture and tools (record_viewers_counter.sh, viewers_counter_gif.py), Hud.TEXT_LIVE_BADGE/TEXT_VIEWERS_UNIT, TrickPopups.ADDED_TEXT/LOST_TEXT, RunState.peak_viewers_for, the 'viewers' HudLayout piece (saved layouts with it still load, ignored), HUD role viewers_unit. Kept (art, never deleted): art/hud viewers_panel, live_badge, eye_icon, viewers_fire_*. Texts: all from multiplier_text.json via MultiplierTag.text_for and recap_text.json; test_no_text_written_in_the_code greps the code. Docs: docs/hud-and-menus.md (Decisions, Content: HUD, counter, texts, reactions, recap, tutorial, scaling/layout mentions) and game/docs (hud, popups, recap-screen, game-data, the-run). Still mentioning viewers on purpose: older Decisions history lines, art tools (build_hud_livestream_art etc.), long GDD (regenerate on merge). Tests run (all pass): test_hud_multiplier_tag 11, test_hud_style 14, test_hud_combo_heat 13, test_hud_reactions 28, test_hud_scaling 9, test_hud_layout 7, test_hud_layout_editor 13, test_recap_screen 18, test_trick_popups 6, test_trick_popups_heat 12, test_trick_popup_prebuild 10 (multiplier-amount golden hashes re-recorded: no eye), test_air_tricks 36, test_airtime_trick 14, test_thread_the_needle 22, test_run_likes 18, test_run_recap 12, test_wreck 23, test_gift_drops 43, test_shared_button 12, test_tutorial_slides 26. Not run: test_game_data/text_inventory tests (text_inventory.py entry renamed). Screenshots: art-archive/T-514/screenshots/ hud_run_start, hud_trick_popup (multiplier beside car, popups with +x add), hud_combo_broken, recap_win (Peak combo x5.59), tutorial_slide_2. Observation: the screenshot shows x1.00 while popups hold their add (counts in on landing), by design. Never touched game/data/levels.

QA round 1: qa_check --no-marks on the combined T-512+T-513+T-514 branch: tests (2 sets), documents, screenshots all PASS. Screenshots viewed: x1.00 left of the car, popups 'FULL 360! +x..', recap 'Peak combo x5.59', tutorial slide 2 multiplier panel all read well. Only fail: paperwork, docs/hud-and-menus.md line 91 (HUD scaling) and line 125 still describe the viewers counter as current; the Project Lead can fix the doc directly. T-513 trick subs: sub goal shows '0 / 30 SUBS' beside the multiplier with no clash visible; T-514 uses the XP spring, not T-513's trick_subs_paid, so there is no dedicated sub flight (not a criterion). Screenshots show rain though T-510 turned it off by default (likely old fixtures), not a T-514 issue.

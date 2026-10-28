---
id: T-336
title: "The live viewers counter at the bottom right, and tricks that bring viewers"
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-331, T-332]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/, game/scripts/hud/combo_heat.gd]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-336/]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decisions (2026-10-28): Game loop architecture, Decisions, "The combo shows as live viewers"; HUD and menus, Decisions, "The HUD looks like a livestream" and "Tricks bring viewers, shown in one colour".

1. **The counter:** the combo counter ("Combo x2.00" above the likes bar) is replaced by a **live viewers counter** at the **bottom right**: a dark panel with T-331's LIVE badge and the viewers number, from T-332's curve and format. The number **counts toward** its target (up after tricks, down when the combo drains or a crash cuts it) and **wobbles a little** all the time, with T-332's speeds. Its look **heats up** on T-332's steps (today's combo heat colours and pulse, carried over), and **over 1,000,000 it is on fire** (a flame animation; placeholder in code until T-339's art).
2. **One viewers colour:** the counter has its own colour (your proposal; T-339 may refine it), used for nothing else in the HUD.
3. **Trick popups:** each trick popup keeps its name as today; its amount (today "+0.25") becomes the **viewers the trick brought** (T-332's function), for example "+12K", with a small eye icon, in the viewers colour.
4. **The "+12K" flies to the counter:** after the popup shows, its amount detaches and flies across the screen into the counter, which **bumps** (a quick pop and flash) when it lands.
5. **Crashes:** when a crash cuts the combo, the counter **flashes red** and a "-{viewers lost}" **drops away** from it as the number falls (with the COMBO BROKEN! popup as today).

- **Position and size:** from the board's HUD layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4); the Project Lead writes the saved numbers in this ticket's Updates when it starts; anchor it to the bottom-right corner.
- If T-339's art (counter frame, LIVE badge, eye icon, fire) is in the branch you start from, use it; otherwise placeholders in code.
- Today's combo heat elsewhere (the popups' rings and flames, the drift marks) stays as it is.

The board's review: play a run: do tricks and watch the "+viewers" fly into the counter; crash and watch it fall; reach a million.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The combo counter is gone and the live viewers counter shows at the layout page's position (at 1152 x 648), anchored bottom right, with T-331's badge (test). (QA: pass / fail)
- [ ] The shown number moves toward T-332's target for the current multiplier and never sits still while the run is going; it stops while paused (tests). (QA: pass / fail)
- [ ] The counter's look changes at T-332's heat steps and is on fire at 1,000,000 or more (tests). (QA: pass / fail)
- [ ] A trick popup shows "+{viewers}" with an eye icon in the viewers colour, and that amount flies to the counter, which bumps on arrival (tests for the text and the flight's end). (QA: pass / fail)
- [ ] A crash flashes the counter red and shows "-{viewers lost}" dropping from it (test). (QA: pass / fail)
- [ ] Every label comes from the game's text data; no text is written in the code. (QA: pass / fail)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-336/screenshots/`: a GIF of a trick's "+viewers" flying in, one of a crash, and a still of the counter on fire. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-545
title: Hotshot Racing-style drive prototype, switched by a hidden test key in the run
status: open
from: project-lead
to: driving-drift
lead: Drift
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/driving/drift.md, game/docs/driving/tricks.md]
files_expected_to_change: [game/scripts/driving/, game/data/, game/project.godot, game/tests/, game/docs/driving/, docs/drifting.md]
model: opus
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

Build Drifting, Decisions, "A Hotshot Racing-style drive, a prototype". The board wants the car's drift to feel like Hotshot Racing's: a deliberate drift state you snap into, not today's Unity slide that builds up from W + A/D. Copy only the feel; nothing of that game's look, names or content.

In the real run (and the drift prototype scene), a hidden test key (propose one, e.g. F6, not used elsewhere) switches between today's drive and the Hotshot drive at any moment, with no on-screen text. Today's drive must be unchanged when the switch is off. For the playtest build, start runs in the Hotshot drive through a playtest switch in data (say in the result notes what it is on master).

With the Hotshot drive on:
- Plain W + A or D turns on grip: the car follows its nose, no slide.
- Tapping Space while steering at speed snaps the car into a drift: it settles quickly at a steady, generous drift angle and keeps nearly all its speed. While drifting, steering into the turn tightens the arc and counter-steering widens it, instead of spinning the car. Straightening up (or counter-steering past a point) ends the drift and the car snaps cleanly back to grip, no wobble. Propose whether the drift also ends below some speed.
- Space held without steering brakes.
- S stays reverse, and the reverse drift (S + A/D) behaves exactly as today, so the alternate drift trick (forward to reverse drift switches) still works.
- No boost meter.
- The Hotshot drift counts as drifting everywhere the game reads drifting: the tricks (extended drift, 360, alternate drift), the drift effects and the Drift Guide.

Jump moves from Space to Left Shift in both drives (game/project.godot's car_jump action and anything else bound to it, e.g. jumping off rails). If any on-screen text names Space as the Jump key, don't change the text: list where it is in the result notes.

Put the tuning values in data and in the Tab tuning panel (its own group): drift angle, snap-in and snap-out rates, speed kept in the drift, how steering changes the arc, grip turn rate, brake strength. Every number is a proposal for the board's playtest: list each with its reason in the result notes.

The board's review: play the Hotshot drive in the run from C:\solid-carbide-worktrees\T-545\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Update docs/drifting.md Content with a short section for this prototype (how it works, its key, its values). Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-545 --text "..."` and hand back in one short line (tasks/README.md, "Handing back").

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With the switch off, today's driving is unchanged: the existing driving and trick tests pass unmodified (the agent's run and QA's full run, counts in the result notes). (QA: pass / fail)
- [ ] New GUT tests cover the Hotshot drive: W + A/D without Space gives no sideways slide; a Space tap while steering at speed enters a drift that reaches and holds the proposed drift angle within the proposed snap-in time; speed in a held drift stays at or above the proposed share; straightening up ends the drift; Space held with no steering slows the car; S + A/D gives today's reverse drift. (QA: pass / fail)
- [ ] The Hotshot drift is read as drifting by the trick code: a test shows an extended drift is paid when a Hotshot drift ends, and an alternate drift is counted when switching between a Hotshot drift and a reverse drift. (QA: pass / fail)
- [ ] The hidden test key switches between the two drives mid-run without resetting the car's position or speed, and shows no text; the key and the playtest switch are named in the result notes. (QA: pass / fail)
- [ ] Jump is bound to Left Shift, not Space (project.godot), and a test or a headless check shows the Jump power-up hops on Left Shift. (QA: pass / fail)
- [ ] The tuning values live in data, appear in a Hotshot group in the Tab tuning panel, and each is listed with its reason in the result notes. (QA: pass / fail)
- [ ] docs/drifting.md Content has a section on this prototype; nothing under game/data/levels/ is changed. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-545/screenshots/ show a Hotshot drift in the run (a strip of frames or a short recording of entry, hold and exit), and the tuning panel's Hotshot group. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-295
title: "Art: Greenbull's wordmark, the emblem with GREENBULL, through the style loop"
status: in-progress
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, agent-notes/asset-generation.md, tasks/T-294-art-greenbull-emblem.md, art-archive/T-294/greenbull_emblem_128.png]
files_expected_to_change: [art-archive/T-295/, docs/visual-style.md]
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

The board's rebrand (2026-10-26; Visual style, Decisions, "Greenbull's look"): Greenbull's logo comes as an emblem (T-294, the bull's head) and a **wordmark**: the emblem with the name **GREENBULL** in pixel letters, for places with room for the name (the gift pack package, the level-up screen's header, menus). The name is the board's, spelled exactly GREENBULL (one word, capitals), so this task needs no text task from the Narrative Theme Agent.

**The wordmark:** the kept T-294 emblem on the left and GREENBULL to its right on one line, about 256 x 64 pixels (the agent may propose another size that suits the letters and says why in the result notes). Bold, chunky, readable pixel letters that match the emblem's cool, confident look, never a copy of a real brand's lettering. Colours from rule 6: the letters mostly in dark green RGB 12, 76, 44 with light green RGB 104, 220, 96, and yellow RGB 247, 208, 52 only as a small accent; a dark outline so it reads on dark and light backgrounds. Flat brand art: exempt from rule 2's shading and detail, follows rule 1.

**How:** through the style loop only, with the board's go of up to 12 PixelLab generations for this asset (2026-10-26). PixelLab is weak at lettering, so the letters may be drawn by a script (the loop allows script-drawn art) with the emblem pasted in, and PixelLab used only where it helps (for example a lettering style to trace). Free script work before paid generations; write the planned calls and their cost in the result notes before calling. If a loop run ends below 8, the Project Lead may start up to two more runs, each with an improved brief, within the 12 generations.

The Project Lead starts the loop: `python tools/style_loop/run.py art --task T-295 --brief art-archive/T-295/brief.md --out art-archive/T-295/greenbull_wordmark.png`. The kept wordmark stays in `art-archive/T-295/` until the board approves it.

This task's Style review is also Example 3 of the board's course assignment (`course-material/style-guide-agent/README.md`), so every round must be clear to an outside reader.

The board's review: look at the kept wordmark enlarged with nearest-neighbour, on a dark and a light background, next to the emblem; read the Style review.
Board review files: art-archive/T-295/review_wordmark_dark.png, art-archive/T-295/review_wordmark_light.png

## Acceptance criteria

- [ ] The task's `## Style review` section holds every round of every loop run: each version's file, the script checks, the score, the reason and (from round 2) what changed, and a "Kept" line per run. (QA: pass / fail)
- [ ] Every version is in `art-archive/T-295/style-loop/` (with its PixelLab record when PixelLab made it, or the script that drew it), and the kept wordmark is `art-archive/T-295/greenbull_wordmark.png`. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py art art-archive/T-295/greenbull_wordmark.png` passes, or its failures are named in the Style review. (QA: pass / fail)
- [ ] The wordmark reads GREENBULL, spelled exactly, as the QA agent sees when it looks at the review image. (QA: pass / fail)
- [ ] Its colours are the three brand colours plus at most two dark outline or shade colours, and yellow covers fewer opaque pixels than either green, as a short script listing its colours shows. (QA: pass / fail)
- [ ] At most 12 PixelLab generations were used, as `game/art/pixellab-generation-log.jsonl` shows for T-295. (QA: pass / fail)
- [ ] The two review images exist: the wordmark and the emblem, enlarged with nearest-neighbour, on a dark and a light background. (QA: pass / fail)
- [ ] Nothing under `game/art/` changed except the PixelLab log. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Open → In progress

Started: the GREENBULL wordmark, built from the emblem's run 2, through the style loop (up to 12 PixelLab generations). The dependency on T-294 is dropped: its emblem is copied in, and a different pick by the board means a free script rebuild.

## Style review

## Result notes

- 2026-10-26, Project Lead: the dependency on T-294 is dropped so the wordmark can be made while the board is away. T-294 passed QA and waits for the board's review in needs-playtest; its kept emblem (run 2, the Project Lead's pick) is copied into `art-archive/T-295/` (128, 64 and 32). If the board picks the other run, the wordmark is rebuilt with that emblem by script, for free.

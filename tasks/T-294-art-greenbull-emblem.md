---
id: T-294
title: "Art: Greenbull's emblem, a bull's head, through the style loop"
status: open
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
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, agent-notes/asset-generation.md, tasks/T-075-redgull-logo-art.md, game/art/logo/redgull_logo_128.png, game/art/car/car_iso.png]
files_expected_to_change: [art-archive/T-294/, docs/visual-style.md]
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

The board's rebrand (2026-10-26; Visual style, Decisions, "The rebrand" and "Greenbull's look"): the sponsor Redgull becomes **Greenbull**, one word. This task makes Greenbull's **emblem**: the logo without words, a **bull's head**. It replaces Redgull's seagull head (T-075). The wordmark, the emblem with the name GREENBULL, is T-295 and is built from this emblem.

**The emblem, in the board's words:** "a head of a bull or something, you know, like a cool logo", and "don't make it look like the real, like the Red Bull logo". So it is a bold, cool bull's head with horns, as a brand emblem. It is never two charging bulls, never a sun disc behind it, never a whole bull: the head only, and its own design.

**Colours:** Greenbull's three brand colours (Visual style, Content, "Rules", rule 6): **dark green RGB 12, 76, 44 leads** (most of the emblem), **light green RGB 104, 220, 96** supports it (highlights, shapes), and **yellow RGB 247, 208, 52 only as a small accent** (for example the eyes, or the horn tips): "don't use yellow too much". A dark outline is allowed and expected so it reads at small sizes. The final emblem uses the brand colours plus the outline (and a darker green shade if the design needs one): it is flat brand art, exempt from rule 2's shading and detail, but it follows rule 1 (transparent background, hard edges, no semi-transparent pixels). Remapping the generated colours to the exact brand values is a free script step.

**Sizes:** 128 x 128 is the master; 64 x 64 and 32 x 32 versions are made from it by script, as T-075 did (`game/tools/make_logo_sizes.py`, adapted or reused), and checked by eye that they still read as a bull's head at 32.

**How:** through the style loop only. The board's go (2026-10-26): **up to 12 PixelLab generations for this asset**, "stop being so stingy … just get the work done well". The loop does at most 4 generations per run (1 plus 3 refines); if a run ends below 8, the Project Lead may start up to two more runs of the loop on this task, each with a brief improved from the previous run's reasons, so the asset gets up to 12 generations in all. Free script fixes come before paid regenerations. Write the planned calls and their cost in the result notes before calling. Every version stays in `art-archive/T-294/` (the loop keeps them in `style-loop/`); nothing is deleted.

The Project Lead starts the loop: `python tools/style_loop/run.py art --task T-294 --brief art-archive/T-294/brief.md --out art-archive/T-294/greenbull_emblem_128.png --size 128x128`. The kept emblem stays in `art-archive/T-294/` until the board approves it; the game swaps it in later in the rebrand goal (the old Redgull logo files stay in `game/art/logo/` until then).

This task's Style review is also Example 2 of the board's course assignment (`course-material/style-guide-agent/README.md`), so every round must be clear to an outside reader.

The board's review: look at the kept emblem at 128, 64 and 32, enlarged with nearest-neighbour, on a dark and a light background, next to the old Redgull logo and the car; read the Style review to see how the loop got there.
Board review files: art-archive/T-294/review_emblem_dark.png, art-archive/T-294/review_emblem_light.png

## Acceptance criteria

- [ ] The task's `## Style review` section holds every round of every loop run: each version's file, the script checks, the score, the reason and (from round 2) what changed, and a "Kept" line per run. (QA: pass / fail)
- [ ] Every version is in `art-archive/T-294/style-loop/` with its PixelLab record, and the kept emblem is `art-archive/T-294/greenbull_emblem_128.png`, with `greenbull_emblem_64.png` and `greenbull_emblem_32.png` beside it. (QA: pass / fail)
- [ ] `python game/tools/style_rules.py art art-archive/T-294/greenbull_emblem_128.png --size 128x128` passes, or its failures are named in the Style review. (QA: pass / fail)
- [ ] The kept emblem's colours are the three brand colours (RGB 12, 76, 44; 104, 220, 96; 247, 208, 52) plus at most two dark outline or shade colours, as a short script listing its colours shows; yellow covers fewer opaque pixels than either green. (QA: pass / fail)
- [ ] At most 12 PixelLab generations were used, as `game/art/pixellab-generation-log.jsonl` shows for T-294. (QA: pass / fail)
- [ ] The two review images exist: the emblem at 128, 64 and 32 next to the old Redgull logo and a car frame, enlarged with nearest-neighbour, on a dark and a light background. (QA: pass / fail)
- [ ] Nothing under `game/art/` changed except the PixelLab log. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

## Result notes

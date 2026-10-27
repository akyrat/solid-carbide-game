---
id: T-331
title: "Text: likes become subs, the sub goal's label and the LIVE badge"
status: open
from: project-lead
to: narrative-theme
lead: Greenbull
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/extended-narrative.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/scripts/ui/level_up_texts.gd, game/data/]
files_expected_to_change: [game/data/, game/scripts/ui/level_up_texts.gd, docs/extended-narrative.md, docs/hud-and-menus.md, art-archive/T-331/]
model: sonnet
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

The board's decisions (2026-10-28): Extended narrative, Decisions, "Subs"; Game loop architecture, Decisions, "Subs instead of likes"; HUD and menus, Decisions, "The HUD looks like a livestream". What the player earns toward the next gift pack is now **subs**, not likes; the likes bar becomes the **sub goal** square; the combo shows as **live viewers**.

1. **Rename likes to subs** in every player-facing text the game has (search the game's text data and scripts for "like"/"Like"/"LIKES"): for example the challenge popup "Trending! +{likes} Likes", the level-up texts, the garage, and any other line that names likes. List each changed line, old and new, in the result notes. Keep each line's meaning and length; re-run the style loop on every changed line.
2. **Text rules, rule 2** (Extended narrative, Content, "Text rules"): the vocabulary now says "subs" (and "live viewers" for the audience counter), never "likes" for what the player earns. Update the rule's text; if `game/tools/style_rules.py` checks it, say so for the Project Lead (don't change the tool).
3. **New labels:** the sub goal's line under the square, "{subs} / {goal}" with a subs word or icon (the board's mock shows "★ 42 / 156 SUBS"; propose the final form); the badge on the live viewers counter ("LIVE" or better); and the viewers counter's unit if it needs one (for example "watching"). Short, in capitals where they sit in the HUD's comic style.

Every new or changed line goes through the style loop. Put the texts where the game reads its other HUD texts, and list them in HUD and menus, Content, under a new "Livestream HUD texts" heading.

The board's review: read the renamed lines and the new labels in the result notes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] No player-facing text the game shows still says "likes" for what the player earns (QA greps the text data and scripts and lists any match with its reason). (QA: pass / fail)
- [ ] Text rules, rule 2 says "subs" and "live viewers", and the result notes list every changed line, old and new. (QA: pass / fail)
- [ ] The sub goal label, the LIVE badge and any viewers unit are in the game's text data and in HUD and menus, Content, "Livestream HUD texts". (QA: pass / fail)
- [ ] Each new or changed line scored at least 8 in the style loop, with every round in the Style review. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

---
id: T-301
title: Text: the level-up screen, its cards and the garage, rewritten for Greenbull
status: blocked
from: project-lead
to: narrative-theme
lead: Goal-G-006
epic: narrative
milestone: mvp
goal: G-006
user_facing_text: yes
changes_visuals: no
depends_on: [T-298, T-299]
documents_affected: [docs/extended-narrative.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/visual-style.md, docs/hud-and-menus.md, docs/garage-design.md, game/scripts/ui/level_up_texts.gd, game/scripts/menu/garage_screen.gd, tasks/T-051-text-level-up-screen.md, tasks/T-059-text-garage-screen.md, tasks/T-268-text-air-turn-and-level-up-lines.md]
files_expected_to_change: [docs/extended-narrative.md]
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

The sponsor Redgull is now Greenbull, one word (board, 2026-10-26; Extended narrative, Decisions, 'The rebrand'). Rewrite for Greenbull every player-facing text that names Redgull or leans on the old brand, through the style loop (tools/style_loop/run.py text, one run per text, with the right --kind), and write the final texts in the result notes with their keys. The texts found today by `git grep -i redgull game/scripts game/scenes game/data`:

- Level-up screen title, levelup.title (game/scripts/ui/level_up_texts.gd), shown at the top of the level-up (gift pack) screen: 'Redgull Sent a Gift Pack!' (kind label).
- Level-up card descriptions in level_up_texts.gd that name Redgull (kind card_desc; same facts and space as today, only the sponsor's joke changes): upgrade_gun.tier2.desc, upgrade_gun.tier6.desc, upgrade_flamethrower.tier3.desc, upgrade_molotov.tier2.desc, upgrade_molotov.tier4.desc, upgrade_molotov.tier8.desc, upgrade_wiper.tier3.desc. Each states the same numbers as now.
- Garage title, TITLE in game/scripts/menu/garage_screen.gd: 'Redgull Pit Stop' (kind label).
- Garage descriptions in garage_screen.gd that name Redgull (kind garage_desc, same numbers): car_health ('+10 car health per level. ...'), damage_bonus ('+5% weapon damage per level. ...').

Run the grep again on your branch and add any other player-facing text it finds (its key, file and where it appears). Texts that don't name Redgull and don't lean on the old brand are left as they are. Follow the Text rules and the rebrand decision: no text explains what the brand sells, no 'Greenbull says ...' line. If the docs leave a wording question open, propose the text and note it for the board. Text only: no screenshots, the result notes say so in one line; the texts are seen in the game in D5.

The board's review: read the new Greenbull texts in the result notes; they are judged in the game with D5's level-up and garage screens in this goal's playtest.

## Acceptance criteria

- [ ] The result notes list every rewritten text with its key, its file and where it appears, at least: levelup.title, the seven level-up card descriptions named in the description, the garage TITLE and the car_health and damage_bonus descriptions, plus any other text `git grep -i redgull game/scripts game/scenes game/data` finds. (QA: pass / fail)
- [ ] Each final text passes `python game/tools/style_rules.py text "<text>"` (output in the result notes): no banned words, 'Redgull' included, and no 'Greenbull says ...' line. (QA: pass / fail)
- [ ] Each text has a style loop record (at least one round) in the ticket's Style review. (QA: pass / fail)
- [ ] Each rewritten card and garage description states the same numbers as the text it replaces (old and new side by side in the result notes). (QA: pass / fail)
- [ ] No text says what Greenbull sells. (QA: pass / fail)
- [ ] Texts that don't name Redgull and don't lean on the old brand are not in the list. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

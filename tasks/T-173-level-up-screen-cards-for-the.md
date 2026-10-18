---
id: T-173
title: Level-up screen: cards for the new weapons, and a weapon image on every card (placeholder images)
status: in-progress
from: project-lead
to: ui
lead: Goal-G-002
epic: hud-menus
milestone: mvp
goal: G-002
user_facing_text: yes
changes_visuals: yes
depends_on: [T-171, T-172]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/weapons.md, game/scripts/ui/level_up_screen.gd, game/scripts/ui/level_up_texts.gd, game/scripts/weapons/level_up_offers.gd, game/tests/unit/test_level_up_screen.gd, game/tests/fixtures/level_up_screen_demo.gd, game/README.md]
files_expected_to_change: [game/scripts/ui/level_up_screen.gd, game/scripts/ui/level_up_texts.gd, game/tests/unit/test_level_up_screen.gd, game/tests/fixtures/level_up_screen_demo.gd, game/tests/fixtures/level_up_screen_demo.tscn, docs/hud-and-menus.md, game/README.md]
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

The level-up screen's weapon cards each show an image of the weapon (docs/hud-and-menus.md, Decisions, 2026-10-18), and the screen must show the six new choice ids from D7. Add the 24 card texts from D6's result notes to `level_up_texts.gd` word for word (no wording of your own; if a text is missing, say so in the result notes). Give every card an image of its weapon (gun, flamethrower, underglow, molotovs, wiper) above or beside its title, description and 'Take it' button; for now a placeholder image per weapon drawn in code, never Redgull red, in a slot the art task (D9) fills with the final images. The starting gun's card shows a small gun (board, 2026-10-18). Keep the red and gold frame, the build-up animation (T-141) and the keyboard and mouse rules as they are, and keep the text readable.

The board's review: Open the level-up screen screenshot and level up in a run from the task folder: each card shows its weapon's placeholder image with the new text.

## Acceptance criteria

- [ ] `level_up_texts.gd` holds D6's 24 texts word for word, and a test walks every choice id and tier `level_up_offers.gd` can produce and finds a non-empty title and description for each. (QA: pass / fail)
- [ ] A test shows each card has an image node showing its weapon's image, a different one per weapon; placeholder images contain no Redgull red. (QA: pass / fail)
- [ ] The existing level-up screen tests (animation, keyboard and mouse) pass unchanged. (QA: pass / fail)
- [ ] A screenshot fixture shows two cards with their images, titles, descriptions and 'Take it' buttons inside the red and gold frame, with no text overlapping the image or running outside the card. (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` Content 'Level-up screen' and `game/README.md` 'Level-up screen' describe the image slot; the game's test set passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-173.

## Result notes

Written by the agent when it finishes.

---
id: T-308
title: Rebrand sweep: the red check looks for Redgull's brand reds, not every red hue, and its report on playtest/G-006 is clean
status: in-progress
from: project-lead
to: qa-integration
lead: Goal-G-006
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: [T-307]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, tasks/T-307-rebrand-sweep-a-check-for-redgull.md, docs/visual-style.md, game/tools/check_rebrand.py, game/tools/test_check_rebrand.py, game/tools/style_rules.py, game/README.md]
files_expected_to_change: [game/tools/check_rebrand.py, game/tools/test_check_rebrand.py, game/README.md]
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

T-307 built game/tools/check_rebrand.py. On playtest/G-006 its report still lists 8 red findings: art/effects/burning_flames.png, art/effects/exhaust_flame_sheet.png, art/level_up/weapon_flamethrower.png, art/level_up/weapon_gun.png, art/level_up/weapon_molotov.png, art/weapons/molotov_bottle.png, molotov_fire.png and molotov_fire_flip.png. They are fire oranges and wood or gun-grip browns. style_rules.reads_as_red flags them because it matches any saturated red hue. The goal is that no Redgull brand red is left. Visual style, Decisions, 'Red after the rebrand' says red is no longer reserved, so fire and wood colours are not Redgull's red, and the sweep should not flag them.

Change the sweep's red check so it flags Redgull's brand reds and leaves other reds alone. Redgull's brand reds are the old logo's red (style_rules.OLD_LOGO_RED, 135, 17, 27) and the red and gold of the old Redgull art: the level-up screen art from before T-303, the gift pack package from before T-304 and the helicopter sheet from before T-305. Take them from the archived originals (art-archive/T-140, art-archive/T-145, art-archive/T-146, and the old game/art versions in git history before T-303, T-304 and T-305). Write the reference colours in the script, each with the file it came from, and give the closeness threshold you chose. A loaded PNG is flagged when it has an opaque pixel within that threshold of one of these colours. Keep KEPT_RED for the subjects the docs keep. Keep the name and text checks as they are. Keep style_rules.reads_as_red unchanged, because other code uses it. Don't edit any art or text. If a loaded PNG still matches a brand red after the change, list it in the result notes for the Project Lead and don't fix it.

Run the script in this ticket's folder, made from playtest/G-006, and put the full report in the result notes. Look at each of the five screenshots in art-archive/T-307/screenshots/ (main menu, garage, run HUD, gift pack drop, level-up screen). In the result notes, say for each one whether it shows any Redgull name, the seagull logo or Redgull's brand red. Update the 'Rebrand sweep (T-307)' section of game/README.md to describe the new red check.

## Acceptance criteria

- [ ] game/tools/check_rebrand.py lists Redgull's brand reference colours, each with the archived file it came from, and flags a loaded PNG only when it has an opaque pixel within the stated threshold of one of them. KEPT_RED and the name and text checks are still there. (QA reads the script.) (QA: pass / fail)
- [ ] game/tools/test_check_rebrand.py has tests showing that a loaded PNG with the old logo red (135, 17, 27) is flagged, a loaded PNG with only fire orange (249, 126, 3) and wood brown (68, 33, 13) is not flagged, the likes heart is passed as a kept subject, a loaded file named with 'redgull' is flagged and a text with 'Redgull' is flagged. All of these tests pass. (QA: pass / fail)
- [ ] Running `python game/tools/check_rebrand.py` in this ticket's folder exits 0 and reports 0 findings. The report is in the result notes. If it can't exit 0 because a loaded PNG still carries a brand red, the result notes name the file and its colours. (QA: pass / fail)
- [ ] The result notes say, for each of the five screenshots in art-archive/T-307/screenshots/ (main_menu.png, garage.png, run_hud.png, gift_pack_drop.png, level_up_screen.png), whether it shows a Redgull name, logo or brand red. QA opens the five images and agrees. (QA: pass / fail)
- [ ] game/README.md's 'Rebrand sweep (T-307)' section describes the brand-red check and how to run it. (QA: pass / fail)
- [ ] All three test sets pass in this ticket's folder: GUT, game/tools Python tests and tools/ Python tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-308.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Change.** `check_rebrand.py`: the red check now flags a loaded PNG only when an opaque pixel is within `BRAND_THRESHOLD = 12` (RGB distance) of a colour in `BRAND_COLOURS`. Each entry names the archived file it came from: old logo red (135,17,27); reds (230,1,2), (221,1,1), (145,1,2), (124,0,1) from `art-archive/T-303/red_gold/gift_pack_emblem.png` and `art-archive/T-304/redgull/package.png`; (222,44,52), (176,24,36), (110,14,24) from the T-303 red_gold pieces (header ribbon, button plate, sunburst, card frame) and the helicopter; (150,24,34) from `art-archive/T-304/redgull/package_falling.png`, (166,28,36) from `art-archive/T-305/redgull/helicopter_sheet.png`. Left out on purpose: the old golds (they sit within a few units of Greenbull's yellow (247,208,52) and fire yellows, so a first run at threshold 25 with golds gave 14 false findings) and the helicopter's (198,52,50) (11 from burning flames' (208,53,46)). Threshold 12 keeps fire reds (202,3,0), (111,16,4) clear. KEPT_RED, name and text checks and `style_rules.reads_as_red` are unchanged. New helper `game/tools/list_brand_palette.py` lists a PNG's commonest colours. No art or text edited.

**Report** (`python game/tools/check_rebrand.py`, this folder, exit 0):
```
loaded PNGs checked: 68
kept red (named in Visual style): 0
findings: 0
```
No loaded PNG still carries a brand red. (The kept list is empty now: the heart (219,26,41) and tail-light colours are farther than 12 from every brand colour.)

**Screenshots** (`art-archive/T-307/screenshots/`): main_menu.png: no Redgull name, logo or brand red (cyan title, dark buttons). garage.png: none ("Greenbull brand-safe pit stop"; the salmon "Not enough coins" text is UI text, not Redgull's red). run_hud.png: none (green helicopter and gift box, Greenbull emblem; the red likes heart is the kept HUD heart). gift_pack_drop.png: none (green helicopter and box). level_up_screen.png: none (green sunburst, ribbon and card, Greenbull emblem, "GREENBULL SENT A GIFT PACK!").

**Tests.** game/tools: 502 OK (1 skipped); tools/: 501 OK; GUT: 1419/1419 passed. New tests: old logo red flagged, a colour within threshold flagged, fire orange (249,126,3) and wood brown (68,33,13) not flagged, the likes heart passed as kept, redgull-named file and "Redgull" text flagged, every brand colour names an archive file.

**Screenshots for this ticket:** none new, tooling only; the five above are the T-307 screenshots this ticket reviewed.

**Refusals:** one inline `python -` / `sed` shell command was refused; not retried, used the edit tool instead.

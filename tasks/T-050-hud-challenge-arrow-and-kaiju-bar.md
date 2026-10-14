---
id: T-050
title: HUD: the kaiju's health bar
status: planning
from: project-lead
to: ui
lead: Enemies
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-049, T-045]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-049-hud-run-values.md, tasks/T-045-kaiju.md, tasks/T-048-text-hud.md, game/README.md]
files_expected_to_change: [the HUD scene and script, tests, docs/hud-and-menus.md, game/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-049 (the HUD) and T-045 (the kaiju) are done.**

Add the kaiju's health bar to the HUD (HUD and menus, Decisions): shown only once the kaiju appears (T-045's health value and signal), with T-048's label. It hides when the kaiju dies. The arrow to the nearest challenge moved to T-098, after the MVP (2026-10-11).

**The board's design (task board note, 2026-10-15), word for word:** "hp bar on top of the kaiju, about as wide as the boss character itself. mkae the health bar subtly match the comic style combo popups in style, with thin divisors at each 10% hp. make the health bar neon purple with a white background and black borderlines (for the thin dividers as well)". So the bar sits above the kaiju in the world and follows it, instead of sitting in the HUD's corner: as wide as the kaiju, neon purple fill on a white background, black outline, thin black dividers at every 10% of its health, in a subtle version of the combo popups' comic style (T-131, T-133). **The board's answers (2026-10-15, HUD and menus, Decisions):** no label (T-048's "Kaiju (Co-Star)" is not used, so the task shows no text); always drawn above buildings, so it shows even when the kaiju is behind one; its width follows the kaiju's width, so it still fits when T-069's final art replaces the placeholder. This replaces the bar in a corner of the HUD.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test shows the kaiju's health bar is hidden before the kaiju appears, shows its health after (following the health signal), and hides when it dies (QA: pass / fail)
- [ ] A test shows the bar follows the kaiju, sits above it, is about as wide as the kaiju (it follows the kaiju's width), has a divider at every 10% of its health, and is drawn above buildings (QA: pass / fail)
- [ ] A screenshot of a run shows the bar above the kaiju, partly emptied, in neon purple on white with black outline and dividers, and no Redgull red (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes it in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

- 2026-10-15, open → planning: hp bar on top of the kaiju, about as wide as the boss character itself. mkae the health bar subtly match the comic style combo popups in style, with thin divisors at each 10% hp. make the health bar neon purple with a white background and black borderlines (for the thin dividers as well)

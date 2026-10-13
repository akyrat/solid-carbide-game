---
id: T-128
title: Narrative: downtown Tokyo under the kaiju's attack, and the alert banners
status: in-progress
from: project-lead
to: narrative-theme
epic: narrative
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/extended-narrative.md, docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/visual-style.md, docs/level-design.md, docs/enemies.md, docs/hud-and-menus.md]
files_expected_to_change: [docs/extended-narrative.md, docs/visual-style.md (only to keep it in sync, through the Project Lead)]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's new direction for the city (2026-10-14; Visual style and Extended narrative, Decisions): the first map is **downtown Tokyo under attack** from the kaiju, the final boss, a giant monster in the style of Godzilla that is **not called Godzilla** (the board will name it later; until then it is "the kaiju"). The city's art is being redone: the bases of very tall skyscrapers (T-064), shorter buildings whose roofs show (T-129), pavements around the buildings, and **a few** alert banners about the monster, on buildings or as signs on the pavement, with silly, minimalistic pixel paintings of its head or its general Godzilla-like body shape (T-130).

The board asks for the Narrative Theme Agent to be consulted so the look stays consistent across all generated assets. Ideas come from the board: this task does not invent new content, it writes the board's direction into the story and gives the art agents one consistent brief.

1. **Extended narrative, Content:** describe the scene the art shows: downtown Tokyo in the middle of the kaiju's attack, at night, how it fits Crash City, Stunt Driver and Redgull's livestream (Extended narrative, Decisions), and what the city's people would have put up (the alert banners) and why. Keep the kaiju unnamed ("the kaiju").
2. **The alert banners:** what they say and how. Propose whether they are picture-only (the monster's head or silhouette, a warning shape) or carry a few words; if words, propose them (short, in the game's tone, no kaiju name yet, no real-world brands), for the board to approve. Words on art need this approval before any art is made. Say which banners hang on buildings and which stand on the pavement.
3. **One brief for all the city's generated art:** a short list the art agents (T-064, T-129, T-130) follow so everything matches: the night neon palette and lighting, signs with Japanese-like marks that are not real words (Visual style, "Building layout and signs"), the damage level from the attack (how wrecked the city looks: cracks, broken windows, fires?), the pavement's look, and what stays out (Redgull's colours and branding: Visual style, "Redgull's look").
4. Hand the Visual style changes to the Project Lead as a proposed text (Visual style is the Asset Generation Agent's document; the Project Lead keeps the two in sync), in the result notes.

## Acceptance criteria

- [ ] Extended narrative, Content, describes the city under attack, the kaiju unnamed, and the alert banners' purpose, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The result notes propose the banners' form (picture-only or with words; the exact words if any) for the board, and say which go on buildings and which on the pavement (QA: pass / fail)
- [ ] The result notes give the one art brief for T-064, T-129 and T-130 (palette and lighting, signs, damage level, pavement, what stays out), consistent with Visual style, Decisions (QA: pass / fail)
- [ ] Nothing new is invented beyond the board's direction; anything that would be new is written as a question for the board (QA: pass / fail)

## Result notes

Written by the agent when it finishes.

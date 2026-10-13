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

Extended narrative, Content, is written (the first map under attack, and the alert banners; Summary, Decisions and Open questions untouched). Everything below is a PROPOSAL for the board unless it already appears in Visual style or Extended narrative, Decisions (2026-10-14).

### 1. The banners' form (for the board to approve)

Recommended: **picture-only, no words.** Each banner is a silly, minimalistic pixel painting of the kaiju (head only, or a simple Godzilla-like body in side view: round back, spikes along the back, tail), in cyan or pink on a dark panel, with a plain warning shape (a triangle or a thick border) and, if wanted, Japanese-like marks that are not real words. Reason: no wording needs approval, no real-word or brand risk, and no kaiju name is needed before the board names it.

Optional, only if the board wants words: one short line in English, in the game's tone, no kaiju name, no brands:
- "ALERT" (any banner)
- "KAIJU ALERT" (building banner; "kaiju" is the common word, not the name)
- "STAY INSIDE" (pavement sign)
Words on art need the board's approval before any art is made.

Which goes where (proposal): **on buildings** the larger banners (hung across a wall or from a roof edge, the head painting); **on the pavement** the small standing signs (a board on a post, the full-body painting, or head again). Few in total, so each is noticed; how many and where is for the board.

### 2. One art brief for T-064, T-129 and T-130

1. **Scene:** downtown Tokyo at night, in the middle of the kaiju's attack. Look from the 3/4 isometric view, pixel style and scale as in Visual style, Decisions (40 px per unit, selective dark outline, about 30 colours per sprite, no semi-transparent pixels).
2. **Palette and lighting:** dark navy and purple night base; pink and cyan neon accents drawn into the sprites as bright pixels with small stepped halos; no engine bloom. Lit windows in warm and cool tones, mostly dim.
3. **Signs:** vertical neon signs with Japanese-like marks that are not real words; no real brands, logos or badges.
4. **Skyscrapers (T-064):** bases of very tall towers, tops out of view, 2 by 2 per 30 by 30 block, 6 different ones; car-realistic size beside them.
5. **Shorter buildings (T-129):** roofs visible; same palette, signs and damage level as the skyscrapers.
6. **Pavement:** every building asset has a pavement drawn around it inside its block: a slightly lighter, cooler grey than the asphalt, a raised kerb edge on the road side, light cracks. Same night lighting; neon spill allowed on it.
7. **Damage level (proposal, board to confirm):** light to medium, readable but not a ruin. Cracks in walls and pavement, a few broken or dark windows, a little rubble. No big fires, no collapsed buildings, no gore, so the cracked streets already in Visual style stay the reference. Anything heavier is a question for the board (see below).
8. **Banners (T-130):** as in section 1: silly, minimal, readable at the game's scale, few of them.
9. **Stays out:** Redgull's red and branding and its seagull logo (the city has nothing to do with Redgull; red appears only on Redgull's own things), real brands and logos, any real words, the name Godzilla and exact copies of the film monster, and any kaiju name (unnamed until the board names it).

### 3. Visual style text for the Project Lead

Visual style, Decisions, already carries the 2026-10-14 redesign entry. Proposed additions only after the board approves the points above: (a) a "City brief" decision listing items 2, 3, 6, 7 and 9 in the board-approved form; (b) the banner form chosen (picture-only, or the exact words) and the buildings/pavement split. Proposed wording once approved: "The city's alert banners are [picture-only paintings of the kaiju's head or body / with the words ...]. The larger ones hang on buildings, the small standing ones are on the pavement. Pavements are a lighter, cooler grey than the asphalt with a raised kerb and light cracks. The attack's damage is light to medium: cracks, a few broken windows, a little rubble." Note: the task names a Visual style section "Building layout and signs" and one called "Redgull's look"; only "Redgull's look" exists as a Decisions entry, and building layout and signs are in the "Buildings" and "Buildings, redesigned" entries.

### 4. Questions for the board

1. Banners: picture-only (recommended) or with words, and if words, which?
2. How many banners, and should they be on buildings, on the pavement or both (proposed: both, large on buildings, small on the pavement)?
3. Damage level: light to medium (proposed), or heavier (fires, collapsed buildings)?
4. Pavement: the look proposed above (lighter cool grey, raised kerb, light cracks), or something else?
5. Should the story say anything about the people who put up the banners (for example civilians visible, or only their signs)? Proposed: only the signs for now; civilians stay in Extended narrative, Open questions.

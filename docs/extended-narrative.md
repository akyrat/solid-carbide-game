---
title: Extended narrative
gdd_order: 8
scope: The deeper story context and the game's tone. Most of it is never shown to players, but it puts the game on the rails, justifies future features in the plot, and sets the voice of every user-facing text and graphic.
agents_work_on: [narrative-theme]
agents_read: [asset-generation]
---

# Extended narrative

## Summary

The player is Stunt Driver, sent by the energy-drink brand Redgull to cities hit by humanitarian crises and disasters, just to drift for the cameras. Every run is livestreamed to Redgull's audience: good driving earns likes, and likes earn gift packs. The tone is satirical and tongue-in-cheek: Redgull isn't evil, just completely out of touch, and the player should sense that their fun is slightly unethical. Each city is a level with its own monster boss; the first is Crash City and its kaiju.

## Decisions

- This document changes rarely. It puts the game on the rails: it decides what can be developed in future and how the plot justifies it, so it may hold details that only become useful later. (2026-10-08)
- Agents read it before producing any user-facing text or graphics, together with Visual style for graphics (how tasks enforce this: `tasks/README.md`). (2026-10-08)
- Overarching plot: humanitarian crises are happening around the world. Redgull sends the player to each affected city, and each city is a new level. (2026-10-03)
- Each level's final boss is a different type of monster. The kaiju is the first level's boss, in Crash City. (2026-10-03)
- The player is **Stunt Driver**, a stunt driver sponsored by the energy-drink brand **Redgull**, sent into each disaster just to drift and show off. (2026-10-08)
- **Tone:** satirical, ironic and tongue-in-cheek. It makes fun of soulless corporate language, social media and brand obsession. Redgull is not evil, just completely out of touch and focused on profit. Playing is fun, but the player should sense that what they are doing is slightly unethical, and the game highlights this whenever it can. (2026-10-08)
- Redgull's logo, a seagull's head in Redgull red, looks **slightly evil and unsettling** on purpose, which suits the company's role in the story (the logo's look and the company's red: Visual style, Decisions). (2026-10-08)
- Every run is **livestreamed** to Redgull's audience. Driving earns **likes**: in the MVP, drifting (challenges are left out of the MVP; Level design, Decisions). (2026-10-08; drifting only in the MVP, 2026-10-11)
- **Likes are XP.** Players only ever see "likes", never "XP"; the board and the agents may say XP internally. Each level threshold is a likes threshold, and filling the likes bar earns a **gift pack**: the weapon reward on level-up. (2026-10-08) Redgull delivers each gift pack by helicopter, dropping it into the disaster for Stunt Driver to drive over (how it plays: Game loop architecture, Decisions, "Gift pack drop"; board, 2026-10-16).
- **Redgull funds the car's upgrades** between runs, all in service of the sponsorship. (2026-10-08, from the Final GDD)
- Weapon names, the level-up wording, descriptions and other user-facing text are written by the Narrative Theme Agent, using this document to get the tone; the board doesn't define them. That agent also chooses how likes are shown (the word, a heart icon, or both). (2026-10-08)
- The first map is downtown Tokyo under attack from the kaiju, the final boss: a giant monster in the style of Godzilla that is not called Godzilla. Its name is still to come from the board; until then it is "the kaiju". The city has put up a few alert banners about it. (board, 2026-10-14)
- The city's people are not shown for now: only the signs they put up (the alert banners, picture-only). (board, 2026-10-15)

## Content

### Text rules

The text style guide: every piece of player-facing text is checked against these rules, each written once here (with Visual style's Rules, the style guide the style loop scores against; `tasks/README.md`, "The style loop"). Each rule condenses a decision; when the decision changes, its rule changes with it. Rules marked *(script)* are checked by a script, the others by the Style Evaluator.

1. **Tone:** satirical, ironic and tongue-in-cheek. It makes fun of soulless corporate language, social media and brand obsession. Redgull is out of touch and focused on profit, never evil and never sincere; the fun should feel slightly unethical. The city's people and their fear are never the joke. No grimdark, gore or earnest heroics. (Decisions, "Tone"; Content, "The alert banners")
2. **Vocabulary** *(script, banned words)*: the player sees "likes", never "XP" or "points"; the weapon reward is a "gift pack"; the player is "Stunt Driver"; the sponsor is "Redgull"; the run is a livestream to Redgull's audience; the monster is "the kaiju", never "Godzilla" and never given a name. (Decisions)
3. **Who speaks:** Redgull's voice is for Redgull's things (gift packs, level-up, garage, the stream). The city never speaks in Redgull's voice: its signs are picture-only. No line takes the form "Redgull says ..." (HUD and menus, Decisions, "No "Redgull says ..." lines"). No real brands. (Decisions; Visual style, Decisions, "City brief")
4. **Format and length, by kind of text** *(script)*:
   - **Trick and combo popups:** one short line in capitals ending in "!", like LONG DRIFT!, AIR 360! and COMBO BROKEN! (HUD and menus, Content, "Trick popups", "Combo broken popup")
   - **Level-up cards:** a title of at most 30 characters and a description of at most 90 that says first what the card does, then at most one satirical aside. (T-051, T-171)
   - **Garage upgrades:** a name of at most 25 characters and a description of at most 80 that names no number. (T-268)
   - **Menu and settings labels:** short and plain, in sentence case, like "Music volume". (HUD and menus, Content)

### The first map: downtown Tokyo under attack

The first level is downtown Tokyo at night, in the middle of the kaiju's attack (Decisions, 2026-10-14). The kaiju is a giant monster in the style of Godzilla, never called Godzilla, and still unnamed: until the board names it, the story and every text call it "the kaiju". It is the level's final boss, and the whole city is already reacting to it.

What the player drives through is a living, frightened city, not an empty set. The skyscrapers are still lit, their towers rising out of view, so the car feels small beside them. Shorter buildings show their roofs. Pavements run around every building. The streets show light cracks from the disaster (Visual style, Decisions). Neon signs are still on, with Japanese-like marks that are not real words (Visual style, Decisions), as the city's own night look. Nothing here belongs to Redgull: the city has nothing to do with the brand, and Redgull's colours and branding stay off the buildings, banners and pavements.

How it fits the story: Redgull has sent Stunt Driver to a city that is in the middle of a disaster, only to drift for the cameras and for the livestream's likes. The contrast is the joke and the unease: people are in danger, and the run is entertainment. The city's own signs are what is left of the people's voice in that scene. Redgull never writes them.

### The alert banners

A few alert banners about the kaiju hang on buildings or stand as signs on the pavement (Decisions, 2026-10-14). The people of the city put them up, the way a city warns itself in an emergency: quickly, by hand or by the city, to tell everyone that the monster is near. They are not Redgull's banners and carry none of its look.

Their purpose in the story is to tell the player, without any dialogue, that this city knows what is coming and is afraid of it, and to give the player a first look at the kaiju before it appears. Their look is a silly, minimalistic pixel painting of the kaiju's head or of its general Godzilla-like body shape, as if drawn by someone in a hurry. The silliness is the tone: the warning is earnest, the drawing is goofy, and the contrast sits close to the game's satire without making fun of the people. They are few, so each one is noticed.

### Looking after consistency

All the city's generated art (the tall skyscraper bases, the shorter buildings with roofs, the pavements and the banners) follows one brief so it matches: night, dark navy and purple base, pink and cyan neon drawn into the sprites, Japanese-like marks and no real words, a damage level for the attack (the board approves it), no Redgull colours or branding. The brief itself is given to the art tasks by the Narrative Theme Agent (task T-128); the parts the board approves are kept in Visual style, Decisions.

## Open questions

- (After MVP) Is "kaiju" the right word for the bosses across the whole game, or does each level get its own kind of monster and name?
- (After MVP) Stunt Driver's real name might be "Stan D. River", revealed later in the plot.
- (After MVP) The plot advances with each completed level, shown as still frames with subtitles and no animation, in a very consistent style. There is no specific plot yet. The board may later give the plot its own game area doc.
- (After MVP) People in need of help, to highlight the unethical side; a concept to experiment with, which could go deep. For example: civilians waving from building windows, or short animations of people eaten by monsters just before the player can do anything. The player can never really save them: if the player kills a monster before it reaches a person, the person just runs away, gives no reward, and can still be attacked by other monsters. Later, rewards for "ethical" actions could be balanced by likes dropping when the player isn't doing enough tricks. The combo is that counterbalance (Game loop architecture, Decisions).

## References

- Final GDD (historical; superseded by the game area docs): [short-gdd/Solid_Carbide_-_Final_GDD.pdf](short-gdd/Solid_Carbide_-_Final_GDD.pdf), section "Narrative Theme".

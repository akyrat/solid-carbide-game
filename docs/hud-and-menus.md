---
title: HUD and menus
gdd_order: 9
scope: What the player sees on screen during a run (the HUD) and the menus around it: pause, level-up and their look. Which screens exist and how they connect is in Game loop architecture.
agents_work_on: [ui]
agents_read: [narrative-theme, asset-generation]
---

# HUD and menus

## Summary

During a run the HUD shows the car's HP, a timer counting down from 8:00, the XP bar and level, the coins collected, an arrow pointing to the nearest challenge, and the kaiju's health once it appears. Levelling up pauses the game and shows the weapon choice as simple cards. Escape pauses the game. In the MVP every screen is kept plain; their visual style comes after the MVP.

## Decisions

- During a run, the HUD shows: the car's HP as a bar; the run timer, counting down from 8:00; the XP bar and the current level; the coins collected this run; an arrow near the car pointing to the nearest challenge; and the kaiju's health once it appears. (2026-10-08)
- When the player levels up, the game pauses and the level-up screen shows the options (what is offered: Weapons, Decisions). Each option has a title and a description. In the MVP it is kept simple: plain cards, each with a button to take it. (2026-10-08)
- Escape pauses the game. In the MVP the pause screen only says "Paused", with a hint that Escape resumes. A full pause menu, with settings, comes in the final release. (2026-10-07)

## Content

(To be written.)

## Open questions

- Where on screen does each HUD element go? (For example: the UI Agent proposes a first layout and the board adjusts it.)
- (After MVP) The visual style of the HUD, the level-up screen, the main menu and the pause menu.

## References

- The screens and how they connect (main menu, run, garage): Game loop architecture, Decisions.
- The garage screen: Garage design, Decisions.

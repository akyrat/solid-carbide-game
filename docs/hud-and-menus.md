---
title: HUD and menus
gdd_order: 9
scope: What the player sees on screen during a run (the HUD) and the menus around it: pause, level-up and their look. Which screens exist and how they connect is in Game loop architecture.
agents_work_on: [ui]
agents_read: [narrative-theme, asset-generation]
---

# HUD and menus

## Summary

During a run the HUD shows the car's HP, a timer counting down from 8:00, the XP bar and level, the coins collected, and the kaiju's health once it appears. Levelling up pauses the game and shows the weapon choice as simple cards. Escape pauses the game, and the pause screen has a camera zoom slider. In the MVP every screen is kept plain; their visual style comes after the MVP.

## Decisions

- During a run, the HUD shows: the car's HP as a bar; the run timer, counting down from 8:00; the XP bar, shown to the player as a likes bar (Extended narrative, Decisions), and the current level; the coins collected this run; and the kaiju's health once it appears. (2026-10-08; the arrow to the nearest challenge left out with the challenges, 2026-10-11)
- When the player levels up, the game pauses and the level-up screen shows the options (what is offered: Weapons, Decisions). Each option has a title and a description. In the MVP it is kept simple: plain cards, each with a button to take it. (2026-10-08)
- The HUD shows the current combo multiplier as a counter next to the likes bar. When the player completes a trick, a short comic-style text pops out from the car with the trick's name and what it added to the multiplier (combo: Game loop architecture, Decisions). Extended-drift popups are smaller than the others, since they come every second. (2026-10-10)
- After the MVP, if challenges come back (2026-10-11): when the player completes a challenge, the likes it gave pop out from the car the same way, not on the HUD (the score flash in Game loop architecture, Decisions). (2026-10-10)
- The UI Agent proposes a first layout for where each HUD element goes on screen, and the board adjusts it in playtest. (2026-10-08)
- The car's health bar stands upright at the top left, filling from the bottom up, with its label above it. The likes bar is horizontal, centred at the bottom of the screen, with the heart, "Likes" and the level in one row above it and the combo counter above that. Labels line up with the bar they belong to. (board, 2026-10-13; first tried with both bars upright at the top left, rejected in playtest the same day: the text placing was poor)
- The combo counter is hidden when there is no combo (multiplier x1.0) and shows as soon as a trick raises it. (board, 2026-10-13)
- The main menu shows the title "SOLID CARBIDE" in big letters, with a discreet "(work in progress)" underneath. (2026-10-08)
- Escape pauses the game. In the MVP the pause screen says "Paused", with a hint that Escape resumes, and has one setting: the camera zoom slider, labelled "Camera zoom level", which zooms the view behind the screen live while the game stays paused (Drifting, Decisions). The screen is a compact dark strip, only as tall as its content, placed just below the HUD timer so the two never overlap and as much of the map as possible stays visible (board, 2026-10-11). A full pause menu, with more settings, comes in the final release. (2026-10-07; zoom slider added 2026-10-08)

## Content

### Main menu

A plain screen (task T-054) with a dark navy background. The title "SOLID CARBIDE" is in big cyan letters, with a small grey "(work in progress)" under it. Below are three buttons in a column: Start, Garage and Exit (text approved in T-053). The menu only shows the screen: pressing a button sends the signal `start_pressed`, `garage_pressed` or `exit_pressed`, and what happens next is the screen flow (T-055). Keyboard focus starts on Start. The scene is `game/scenes/menu/main_menu.tscn`; how to open it is in `game/README.md`, "Main menu".

### The HUD

The first piece of the HUD (task T-090) is the run timer. It shows the time left in minutes and seconds (M:SS), counting down from 8:00 to 0:00, in big cyan digits with a dark outline at the top centre of the screen. It only shows what the run reports (the run owns the time) and stops moving while the game is paused. It needs no text. It is shown in every run, whether the run scene is opened on its own or started from the main menu. The rest of the HUD (task T-049, a first layout the board adjusts in playtest) is in the same scene, `game/scenes/hud/hud.tscn`, which the run scene places on screen; how to open it is in `game/README.md`, "The run". It only shows what the run reports, and the texts are from T-048:

- **Top left:** since task T-113, the label "Car Health" with the car's health bar directly under it, both starting at the same left edge. The bar stands upright, 24 pixels wide and 160 tall, filling from the bottom up (green fill).
- **Bottom centre:** since task T-113, the likes bar lies across the bottom of the screen: half the screen wide, 16 pixels tall, centred, 16 pixels above the bottom edge, filling from left to right (purple fill). It fills toward the next level and starts again after a level-up; at the top level it stays full. Directly above it is one row of text, the same width as the bar: a small heart and the word "Likes" at its left end, and "Hype Lv {level}" (for example "Hype Lv 2") ending at its right end, both on the same line and in the same size. The heart is a placeholder shape in Redgull red until its art task (T-086); no other part of the HUD is red. Centred above that row is the combo counter (task T-083): "Combo x{multiplier}" (text approved in T-082) in bold pink with a dark outline, for example "Combo x2.5". It follows the run's combo multiplier, including its drain, and is not red. Since task T-116 it is hidden when there is no combo (the multiplier at its starting value, x1.0): a run starts with it hidden, it appears as soon as a trick raises the multiplier, and it disappears again once the combo has drained back to x1.0. Hiding it moves nothing else: the likes row and bar stay where they are, and the counter always appears in the same place. The look is a placeholder; T-084 makes the final one.
- **Top right:** "Coins" followed by the number collected this run, in yellow.
- **Top centre:** the timer, as above.

The arrow to the nearest challenge and the kaiju's health bar are T-050. The HUD stays clear of the trick popups (near the car) and the pause strip (below the timer); while paused, the strip's dark band runs across the whole width over the lower part of the health bar.

### Trick popups

Task T-091. When the car sends a `trick` signal (Game loop architecture; the ids are in `game/README.md`, "Tricks"), a comic-style text pops out just above the car with the trick's name, grows quickly to full size, rises about 40 pixels and fades, in one second: LONG DRIFT! (extended drift), FULL 360! and ALT DRIFT! (text approved in T-082). Extended-drift popups are smaller and flatter (a shorter burst), since they come every second. The look (task T-084, reworked after the board's playtest of 2026-10-13) is a real comic-book popup: a white jagged burst with a black border, every letter black (trick names and amounts alike) in the Bangers comic font on one straight baseline, with hard pixel edges (no smoothing) and no other colour. Black on white reads over both the dark asphalt and the dusty gravel. The burst is sized to fit each text, with the left and right spike tips kept short. One popup pixel is two art pixels. Bangers has capitals only, so "Trending! +{likes} Likes" shows in capitals. It sits near the car, clear of the run timer at the top centre. It works in the run, including runs started from the main menu, and in the drift prototype. The challenge popup (task T-092) reuses it: when a challenge is completed, the run state's `score` signal shows "Trending! +{likes} Likes" (text approved in T-048, `hud.score_flash`) from the car in the same look and size as the normal trick popups, with the likes the challenge gave. Since task T-083 each trick popup also shows what the trick added to the combo, after its name, in the approved "+{amount}" text (T-082): "LONG DRIFT! +0.05", "FULL 360! +0.25", "ALT DRIFT! +0.5". At the combo cap the trick adds nothing and only the name shows. In the run the popups follow the run state's combo signal; the drift prototype has no combo and shows the name only. How it is built is in `game/README.md`, "Trick popups".

(The pause and level-up screens: to be written.)

## Open questions

- (After MVP) The visual style of the HUD, the level-up screen, the main menu and the pause menu.

## References

- The screens and how they connect (main menu, run, garage): Game loop architecture, Decisions.
- The garage screen: Garage design, Decisions.

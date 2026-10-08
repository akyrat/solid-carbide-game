# Short GDD

Last updated from long GDD: never

(The line above is read by `python tools/generate_long_gdd.py --check`. It holds the SHA-256 fingerprint of the long GDD the short GDD was last updated from, or "never" until the short GDD is first rewritten from a generated long GDD in task T-025.)

The short, presentable GDD for showing to humans (`Solid_Carbide_-_Final_GDD.pdf`). It condenses the long GDD. Changes flow down only: it is never the place to make a content change first.

Known wording to update when the Project Lead next edits the GDD:

- "The Orchestrator is the studio's day-to-day lead" should say Project Lead.
- The SFX Agent no longer integrates sounds. It finds and downloads them and sets direction with the agents that own the code.
- Player Experience says the player only uses W and A/D. The car can also reverse with S (decided in `docs/drifting.md`).
- The chart of three candidate drift curves (square root, linear, exponential) is out of date: the drift curve is now the Unity prototype's (decided in `docs/drifting.md`).
- Player Experience says each enemy gets tougher over the run. Now only their number grows, slightly (decided in `docs/enemies.md`).
- Technical Feasibility caps weapons at 3 with 2 offered per level-up. Now the MVP has 2 weapons with 1 offered per challenge, and the final release around 8 to 12 with 3 offered (decided in `docs/weapons.md`).
- The final release adds local co-op for 2 and 4 players with split screen (decided in `docs/game-loop-architecture.md`).
- Game Specificity says challenges keep spawning near the kaiju. Now its own meteor challenges are the only ones that make it vulnerable (decided in `docs/enemies.md`).
- XP from drifting: a drift longer than 1 second gives a little XP per second (decided in `docs/game-loop-architecture.md`).
- The final release adds a recap screen after each run, win or loss, with kills per enemy type and other stats (decided in `docs/game-loop-architecture.md`).
- The map is now described as a Tokyo-style cyberpunk city grid with roads 5 to 10 car-widths wide, obstacles in set patterns, and 30% of pattern groups becoming challenges (decided in `docs/level-design.md` and `docs/visual-style.md`).
- The game now opens on a main menu (Start, Garage, Quit) and returns there after each run; the MVP garage sells acceleration, car HP and a weapon damage bonus (decided in `docs/game-loop-architecture.md` and `docs/garage-design.md`).
- The HUD now shows HP, a countdown timer, XP and level, coins, the challenge arrow and the kaiju's health, and level-ups pause the game (decided in `docs/hud-and-menus.md`).
- Narrative Theme: runs are livestreamed, XP is shown as likes, and the tone is satirical about Redgull (decided in `docs/extended-narrative.md`).

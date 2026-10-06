# Short GDD

The short, presentable GDD for showing to humans (`Solid_Carbide_-_Final_GDD.pdf`). It condenses the long GDD. Changes flow down only: it is never the place to make a content change first.

Known wording to update when the Project Lead next edits the GDD:

- "The Orchestrator is the studio's day-to-day lead" should say Project Lead.
- The SFX Agent no longer integrates sounds. It finds and downloads them and sets direction with the agents that own the code.
- Player Experience says the player only uses W and A/D. The car can also reverse with S (decided in `docs/drifting.md`).
- The chart of three candidate drift curves (square root, linear, exponential) is out of date: the drift curve is now the Unity prototype's (decided in `docs/drifting.md`).
- Player Experience says each enemy gets tougher over the run. Now only their number grows, slightly (decided in `docs/enemies.md`).
- Technical Feasibility caps weapons at 3 with 2 offered per level-up. Now the MVP has 2 weapons with 1 offered per challenge, and the final release around 8 to 12 with 3 offered (decided in `docs/weapons.md`).
- The final release adds local co-op for 2 and 4 players with split screen (decided in `docs/game-loop-architecture.md`).

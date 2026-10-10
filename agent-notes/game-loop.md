# Working copy: Game Loop Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for the run, its state and the flow between screens.
- Level/Challenge Design Agent: The signal that a challenge was completed.
- Driving & Drift Agent: The car's drift state, for likes from drifting.
- Enemy Behavior Agent: Damage dealt to the car, coins dropped, and the boss's defeat.
- Game Data Agent: The numbers the run uses, such as likes per level and the car's health.

**Hands work to**

- UI Agent: The values the HUD shows, and when to open each screen.
- Weapon Behavior Agent: The level-up choice to apply to the car's weapons.
- Game Data Agent: The coins collected in a run, to save.
- QA/Integration Agent: A full run to check.

**Collaborates with**

- UI Agent: How the screens connect and what each one shows.
- Enemy Behavior Agent: When the boss arrives and how its defeat ends the run.

## Notes from experience

- T-036: the run's state is a node (`RunState`) that other agents reach through `run.state` or the `run_state` group; they call its functions (damage, coins, kaiju killed) and listen to its signals (boss time, run ended, HUD values). Pausing the run is Godot's tree pause, shared with the pause screen and the level-up choice (UI Agent).
- Starting a new run rebuilds the map and the car, so anything holding them (enemies, the likes counter) should listen for `world_rebuilt` or `run_started`.

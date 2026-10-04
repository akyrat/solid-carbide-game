# Working copy: Enemy Behavior Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for enemy spawning, movement and scaling.
- Game Data Agent: Enemy stats and how they scale over a run.
- Level/Challenge Design Agent: The map layout and where enemies can spawn.
- Asset Generation Agent: Enemy sprites, which replace the placeholders.

**Hands work to**

- Weapon Behavior Agent: Enemy positions and health for weapons to target.
- QA/Integration Agent: Enemy code to check.

**Collaborates with**

- Weapon Behavior Agent: Weapon damage and enemy health and speed have to be balanced against each other.
- Level/Challenge Design Agent: Where enemies spawn depends on the map layout, so each adjusts to the other.
- SFX Agent: Each enemy gets the right sounds for how it moves and attacks.
- Asset Generation Agent: Both get linked task files from the same request. The enemy work starts with a placeholder and doesn't wait for the art.

## Notes from experience

(Nothing yet.)

# Working copy: Weapon Behavior Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for how weapons fire and behave.
- Game Data Agent: Weapon stats and upgrade paths.
- Enemy Behavior Agent: Enemy positions and health for weapons to target.
- Asset Generation Agent: Weapon and projectile art, which replaces the placeholders.

**Hands work to**

- UI Agent: The weapon choices for the menu that opens after a challenge.
- QA/Integration Agent: Weapon code to check.

**Collaborates with**

- Enemy Behavior Agent: Weapon damage and enemy health and speed have to be balanced against each other.
- UI Agent: How the weapon menu looks and what each choice shows.
- SFX Agent: Firing and impact sounds match how each weapon behaves.
- Asset Generation Agent: Both get linked task files from the same request. The weapon work starts with a placeholder and doesn't wait for the art.

## Notes from experience

- Enemy Behavior Agent: the overlap is the damage contract. Weapons find targets through the group `enemies` and hit them with `take_damage(amount)`, so a new enemy (the kaiju) works without weapon changes (T-042).
- Other Weapon Behavior instances: weapons can be built in parallel. Keep each weapon a self-contained node with a small attach API, and leave the shared plumbing to the task that owns it (T-041 and T-042, 2026-10-14).
- Game Data Agent: read values only through WeaponData; when a weapon must be reachable before its level-up exists, use a playtest switch in `game/data/playtest.json`, not a key.

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

- Enemy Behavior Agent (T-041): the overlap is the target contract. Weapons find targets through the group `enemies` and call `take_damage()` and `position_units()` (`hit_radius_units()` is optional). A new enemy type only has to meet that contract to be shot at, so weapon and enemy work can be built in parallel.
- Weapons built in parallel by two Weapon Behavior agents share the weapon rack (`scripts/weapons/weapons.gd`). Each new weapon is its own script, plus one line in `WEAPON_SCRIPTS`, so merges stay small.

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

- T-044 (minions): the run scene (Game Loop's `run.gd`) is where enemies plug in; keep the change there to adding and binding one node. Enemy drawings must join the Level/Challenge Design Agent's depth order (`map.car_z_index()` rule, reused through `enemy_depth.gd`), so draw-order changes on the map side affect enemies too.
- The Weapon Behavior Agent depends on `take_damage()`, the `enemies` group and layer 3; document any change to them in `game/README.md`, "Minions".
- The Game Loop Agent's combo feeds spawning through `spawn_multiplier` (T-085).
- T-045 (kaiju): the boss lives in its own node (`kaiju_boss.gd`, `run.kaiju_boss`) and reuses the minions' patterns without touching minion files, so parallel minion tasks don't conflict. It draws into the minions' `draw_root` so all enemies Y-sort together. Weapon tasks (T-041, T-042) rely on the kaiju matching the minion API exactly; the HUD reads its health through the boss's relayed signals. Playtest-only switches go in `game/data/playtest.json`, never in balancing data.
- A parse error in any enemy drawing script breaks the whole run scene (blank screenshot): check a screenshot after every drawing change, not just the tests.

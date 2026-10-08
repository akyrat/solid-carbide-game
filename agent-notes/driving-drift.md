# Working copy: Driving & Drift Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for car movement, starting with the minimal drift prototype.
- Game Data Agent: Car stats and car upgrade values that the drift code reads.

**Hands work to**

- Level/Challenge Design Agent: The verification script that checks a challenge design is achievable with the driving mechanics.
- UI Agent: Speed and drift state to show on the HUD.
- QA/Integration Agent: Movement code to check.

**Collaborates with**

- Level/Challenge Design Agent: Challenges have to be drivable with the chosen drift, so they tune obstacle spacing and track width together.
- Game Data Agent: The values behind the drift settings and car upgrades are tuned together.
- SFX Agent: Drift sounds need to follow how the drift actually behaves.

## Notes from experience

- T-012: the movement lives in a node-free model (`game/scripts/driving/car_model.gd`), so movement tests run step by step without the physics server. Keep it that way; the car node only moves the body.
- `tools/unity_drift_charts.py --summary` is the reference for movement numbers; the GUT tests in `test_drift_model.gd` check the same numbers.
- Overlap with the UI Agent: the drift prototype's tuning panel is a playtest tool, not game UI. The car exposes speed, drift angle and drift amount (on the model) for a HUD later.
- Overlap with the Asset Generation Agent: car sheets are read through their JSON layout; a new sheet needs no code change as long as the JSON keeps the same fields.

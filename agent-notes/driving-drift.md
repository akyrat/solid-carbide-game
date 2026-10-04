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

(Nothing yet.)

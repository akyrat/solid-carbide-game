# Working copy: Level/Challenge Design Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for the map and its challenges.
- Driving & Drift Agent: The verification script that checks a challenge design is achievable with the driving mechanics.
- Asset Generation Agent: Map and obstacle art.

**Hands work to**

- Enemy Behavior Agent: The map layout and where enemies can spawn.
- UI Agent: Challenge positions, for the arrow that points to the next one.
- QA/Integration Agent: The map and challenges to check.

**Collaborates with**

- Driving & Drift Agent: Challenges have to be drivable with the chosen drift, so they tune obstacle spacing and track width together.
- Enemy Behavior Agent: Where enemies spawn depends on the map layout, so each adjusts to the other.

## Notes from experience

(Nothing yet.)

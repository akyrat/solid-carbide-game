# Working copy: UI Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for the HUD, menus and garage screen.
- Game Data Agent: The numbers the garage and weapon menus display.
- Driving & Drift Agent: Speed and drift state to show on the HUD.
- Weapon Behavior Agent: The weapon choices for the menu that opens after a challenge.
- Level/Challenge Design Agent: Challenge positions, for the arrow that points to the next one.
- Asset Generation Agent: HUD, menu and garage art, which replaces the placeholders.
- Narrative Theme Agent: Menu, weapon and gift pack text.

**Hands work to**

- QA/Integration Agent: Screens and HUD to check.

**Collaborates with**

- Weapon Behavior Agent: How the weapon menu looks and what each choice shows.
- SFX Agent: Music is associated with screens, such as the menu or the garage, and UI sounds go with the interface.
- Asset Generation Agent: Both get linked task files from the same request. The screen work starts with a placeholder and doesn't wait for the art.

## Notes from experience

(Nothing yet.)

# Working copy: SFX Agent

This started as a copy of the original relationships in the agent's definition. Update it from experience so it reflects how this agent actually works. Over time it may shift from hand-offs toward naming the areas where agents overlap and how they interact. Changes to the original definition need the board's approval. This file does not.

These are guidelines for how work typically flows, not strict rules. Receiving work from an agent does not prevent sending work to it, and the other way around.

**Gets work from**

- Project Lead: Task files for sound effects to find and integrate.

**Hands work to**

- QA/Integration Agent: Sound integration to check.

**Collaborates with**

- Driving & Drift Agent: Drift sounds need to follow how the drift actually behaves.
- Weapon Behavior Agent: Firing and impact sounds match how each weapon behaves.
- Enemy Behavior Agent: Each enemy gets the right sounds for how it moves and attacks.
- UI Agent: Music is associated with screens, such as the menu or the garage, and UI sounds go with the interface.

## Notes from experience

- Freesound downloads go through `game/tools/freesound.py`, and the board logs in only once. If it exits with code 3, the login has to be redone. The Project Lead relays the link and the code, because the board cannot talk to this agent directly.
- After downloading, check imports with `game/tools/check_audio.sh`. Only wav, ogg and mp3 import in Godot.

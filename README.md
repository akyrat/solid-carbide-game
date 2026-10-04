# Solid Carbide

A 2D isometric drift-driving roguelite in a neon cyberpunk city under kaiju attack, built in Godot 4 by a team of Claude Code agents. This repository holds both the documentation and the game.

## Layout

- `CLAUDE.md`: the Project Lead's standing instructions. The Claude Code session you talk to acts as the Project Lead.
- `.claude/agents/`: one file per agent (ten agents). The Project Lead delegates to them.
- `agent-notes/`: each agent's working copy of its relationships, which it updates from experience.
- `docs/`: the documents. The separate documents are the source of truth, then the long GDD, then the short GDD.
- `tasks/`: task files, the official record of all work.
- `game/`: the Godot project.

## Getting started

1. Create a git repository here and make a first commit.
2. Open a terminal in this folder and run `claude`.
3. Ask the Project Lead to read its instructions and list the agents it can see. If anything is missing, fix it now.
4. Give it your first request: the minimal drift prototype, working with the Driving & Drift Agent.
5. Switch agents on as you need them. Early on, the Project Lead, Driving & Drift and QA/Integration are enough.

## Suggested first tasks for the Project Lead

- Write the staleness check script that flags separate documents that changed after the long GDD was last regenerated, and long GDD changes the short GDD hasn't caught up with. Run it at the start of each session and before milestones.
- Decide where HUD and menu details belong (see `docs/unfiled-game-details.md`).
- Update the short GDD wording noted in `docs/short-gdd/README.md`.

## Notes

- The agent files use Claude Code's markdown format with a short header. Check the Claude Code documentation (https://docs.claude.com/en/docs/claude-code/overview) for the current format and options, since details may change.
- As far as I know, agents don't call each other directly in Claude Code. The Project Lead session routes work between them using the task files.
- The task file template, the folder names, and the `agent-notes/` location were chosen when building this export. Change them if your setup prefers something else.

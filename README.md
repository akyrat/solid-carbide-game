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

## Secrets and API keys

API keys and other secrets go in a file called `.env` at the repository root, next to this README. `.env` is git-ignored and must never be committed. `.env.example` lists every variable the project expects, with no real values: copy it to `.env` and fill it in.

### Godot (used by every agent that runs the game or its tests)

Godot is not on the PATH. The test and screenshot scripts in `game/tools/` read the location of the Godot 4.6.2 console executable from `GODOT_BIN`, so no script contains the path itself. Use the `_console.exe` build, so output reaches the terminal. Forward slashes work from both Git Bash and PowerShell:

```
GODOT_BIN=C:/Tools/Godot/Godot_v4.6.2-stable_win64_console.exe   # full path to the Godot console executable
```

If `GODOT_BIN` is already set in the environment, the scripts use that value instead of `.env`. How to run the tests and take screenshots: `game/README.md`.

### Freesound (used by the SFX Agent)

Create API credentials at https://freesound.org/apiv2/apply/ while logged in. The table on that page shows the values to copy:

```
FREESOUND_CLIENT_ID=      # "Client id" column
FREESOUND_API_KEY=        # "Client secret/Api key" column
```

Downloading original sound files requires a one-time browser login (OAuth2). The SFX Agent gives you a link; you open it, log in, approve access, and paste the code Freesound shows back to the agent. The agent stores the resulting access tokens in `.secrets/`, which is also git-ignored, and renews them on its own.

### PixelLab (used by the Asset Generation Agent)

Log in at https://pixellab.ai/account and copy your API token:

```
PIXELLAB_API_KEY=         # API token from your PixelLab account page
```

Generations are paid from your PixelLab subscription or USD credits, so the account needs one of these before the agent can generate anything.

## Suggested first tasks for the Project Lead

- Write the staleness check script that flags separate documents that changed after the long GDD was last regenerated, and long GDD changes the short GDD hasn't caught up with. Run it at the start of each session and before milestones.
- Decide where HUD and menu details belong (see `docs/unfiled-game-details.md`).
- Update the short GDD wording noted in `docs/short-gdd/README.md`.

## Notes

- The agent files use Claude Code's markdown format with a short header. Check the Claude Code documentation (https://docs.claude.com/en/docs/claude-code/overview) for the current format and options, since details may change.
- As far as I know, agents don't call each other directly in Claude Code. The Project Lead session routes work between them using the task files.
- The task file template, the folder names, and the `agent-notes/` location were chosen when building this export. Change them if your setup prefers something else.

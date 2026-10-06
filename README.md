# Solid Carbide

A 2D isometric drift-driving roguelite in a neon cyberpunk city under kaiju attack, built in Godot 4 by a team of Claude Code agents. This repository holds both the documentation and the game.

## Layout

- `CLAUDE.md`: the Project Lead's standing instructions. The Claude Code session you talk to acts as the Project Lead.
- `.claude/agents/`: one file per agent (ten agents). The Project Lead delegates to them.
- `agent-notes/`: each agent's working copy of its relationships, which it updates from experience. `agent-notes/agents-interactions.md` is the shared overview of the whole crew.
- `docs/`: the documents. The separate documents are the source of truth, then the long GDD, then the short GDD.
- `tasks/`: task files, the official record of all work.
- `game/`: the Godot project.
- `tools/`: project tooling that is not part of the game, such as the agent diagram generator.

## Agent Crew

The board (the game's designer) talks to the Project Lead, which turns requests into task files for the other ten agents. How they connect, what each one produces and why this crew is needed for the MVP: [agent-notes/agents-interactions.md](agent-notes/agents-interactions.md).

| Role | What it does |
|---|---|
| Project Lead | Takes the board's requests, splits them into task files with acceptance criteria, keeps the documents and timeline in sync, and suggests a priority order. Writes no game code. |
| Driving & Drift | Builds the car's driving and drift, the tuning tools for the board's playtests, and the script that checks a challenge is drivable. |
| Enemy Behavior | Builds how enemies and the boss spawn, move, attack and scale over a run, plus coin drops and the boss's vulnerability window. |
| Weapon Behavior | Builds how each weapon fires and behaves, as the Weapons document defines it. |
| Game Data | Writes stats and upgrade paths as JSON, balances the numbers, and saves progress between runs. |
| Level/Challenge Design | Builds the map and its driving challenges, and checks each challenge is drivable before handing it over. |
| UI | Builds the HUD, menus and garage screen. Displays screens and collects input only. |
| Asset Generation | Generates pixel art through PixelLab from the Visual style document, and records every asset. |
| SFX | Finds and downloads sound effects, records their sources and licenses, and sets direction for where sounds and music play. |
| Narrative Theme | Reviews text and story content for consistency with the story, and writes only when the board asks. |
| QA/Integration | Checks every task's acceptance criteria, runs the tests, and reports pass or fail per criterion. |

## Getting started

**What to install:**

- [Claude Code](https://code.claude.com/docs/en/overview)
- Git
- Godot 4.6.2: the console build (`_console.exe`) is what the scripts use
- Python 3.9 or newer, for the project's tools (standard library only)

**Set up:**

1. Clone this repository and open a terminal in its root folder.
2. Copy `.env.example` to `.env` and fill it in. "Secrets and API keys" below says where each value comes from. You need `GODOT_BIN` to run anything; the Freesound and PixelLab keys only when those agents fetch sounds or generate art.
3. Check that everything works, from the repo root:

   ```bash
   bash game/tools/run_tests.sh                               # the game's Godot tests
   python -m unittest discover -s game/tools -p "test_*.py"    # the game's Python tools
   python -m unittest discover -s tools -p "test_*.py"         # the project tools
   python tools/generate_agent_diagrams.py --check            # the agent diagrams are up to date
   ```

   `game/README.md` has the PowerShell versions and the other game tools.

**Working on the game:**

- Run `claude` in the repo root. The session you talk to is the Project Lead: describe what you want in plain words, and it writes the task files, starts the agents, and brings the results back for your review.
- `tasks/` shows every piece of work and its status. `docs/timeline.md` records every decision in order, so it's the place to catch up on where things stand.

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

## Notes

- The agent files use Claude Code's markdown format with a short header. Check the Claude Code documentation (https://code.claude.com/docs/en/sub-agents) for the current format and options, since details may change.
- Agents don't talk to each other in this project. Claude Code would allow it, but the Project Lead routes all work between them through task files on purpose, so every piece of work is on record. Details: [How agents actually communicate](agent-notes/agents-interactions.md#1-how-the-agents-connect).
# Timeline

A record of everything done for the game, at least everything the board told the Project Lead. Maintained by the Project Lead. Each entry lists the documents the decision touched and the tasks it produced.

Entry format:

```
## YYYY-MM-DD: short title
- Decision or change:
- Documents touched:
- Tasks: (task ids)
```

## 2026-10-03: Agent team defined
- Decision or change: defined all eleven agent roles, their relationships, the common rules for every agent, and the workflow for task files and QA. Recorded game details so far in the documents.
- Documents touched: all the separate documents in `docs/`
- Tasks: none yet

## 2026-10-04: Project setup assigned, Freesound chosen
- Decision or change: QA/Integration owns the technical setup every code agent needs (Godot 4.6.2 project, headless runner, test suite, screenshot script, `.gitignore`, `.env.example`). The SFX Agent will source sound effects from Freesound through its API; the board has created an account. API keys live in a git-ignored `.env` at the repo root.
- Documents touched: none yet (T-001 updates `game/README.md`)
- Tasks: T-001

## 2026-10-04: Freesound credentials and SFX test run
- Decision or change: the SFX Agent downloads original Freesound files through OAuth2, using the board's Client id, Client secret/Api key and redirect URL kept in `.env`; tokens are kept in a git-ignored `.secrets/` folder. A test run downloads 3 engine idle and 3 tire drift sounds to prove the pipeline. Which licenses the game accepts (in particular non-commercial ones) is an open decision for the board, to be made when reviewing T-002. T-001 now also covers the extra variables and `.secrets/`.
- Documents touched: `README.md`
- Tasks: T-001 (updated), T-002

## 2026-10-04: PixelLab test run
- Decision or change: the Asset Generation Agent uses the PixelLab v2 API with the board's API token kept in `.env`. A test run generates 1 isometric road tile and 1 still car image with generic descriptions, using the cheapest endpoints, to prove the pipeline and the asset record before the Visual style document is written. No style decision is made.
- Documents touched: `README.md`
- Tasks: T-003

## 2026-10-04: T-001 done: Godot project and test suite in place
- Decision or change: the Godot 4.6.2 project, headless test runner (GUT 9.6.1), screenshot tool, `.gitignore`, `.gitattributes` and `.env.example` are in place. T-001 passed QA round 1 on all 10 criteria, and the board confirmed the project opens correctly in the Godot editor. T-002 and T-003 are no longer blocked by it.
- Documents touched: `README.md`, `game/README.md`
- Tasks: T-001

## 2026-10-04: Task status rules and required reading
- Decision or change: when a task becomes `done`, tasks whose dependencies are now all `done` move from `blocked` to `open` in the same commit. Every agent reads `tasks/README.md` before starting any task, and every task file lists it first in `files_to_read_first`. `CLAUDE.md` is unchanged.
- Documents touched: `tasks/README.md`, `tasks/_TEMPLATE.md`
- Tasks: T-002, T-003 (`files_to_read_first` updated)

## 2026-10-04: Freesound redirect URI dropped
- Decision or change: the board has no redirect URI for its Freesound credentials, so none is used. The Freesound login link carries only the client id, Freesound shows the code on its own page, and `FREESOUND_REDIRECT_URI` is removed from `.env.example` and the README.
- Documents touched: `README.md`
- Tasks: T-002 (login step updated)

## 2026-10-04: T-002 done: Freesound pipeline works; sound license rule
- Decision or change: the SFX Agent's Freesound downloader and audio import check work, and T-002 passed QA round 1 on all 9 criteria (the board ran the two Godot checks that permissions blocked for QA). The board decided the game uses only CC0 and CC BY sounds, so the two CC BY-NC test sounds were deleted; 4 CC0 test sounds remain. The downloader does not filter by license yet.
- Documents touched: `docs/unfiled-game-details.md`, `game/README.md`
- Tasks: T-002

## 2026-10-04: T-003 done: PixelLab pipeline works
- Decision or change: the Asset Generation Agent's PixelLab client works, and T-003 passed QA round 1 on all 8 criteria. It made exactly 2 generation calls: a 32x32 isometric tile (it came out as a cube, PixelLab's default "block" shape) and a 64x64 still car image. The board kept both images. The PixelLab account is on a trial plan with no USD credits and 17 of 40 trial generations left.
- Documents touched: `game/README.md`
- Tasks: T-003

## 2026-10-04: License filter task written
- Decision or change: the Freesound downloader will enforce the CC0 and CC BY rule, filtering at search time and checking again before saving. Written as T-004 for the SFX Agent, to be worked on later.
- Documents touched: none
- Tasks: T-004

## 2026-10-04: Agent Crew overview task written
- Decision or change: the board asked for an "Agent Crew" section in the README and an `agent-notes/agents-interactions.md` overview. Decisions: the diagrams show the agents' working copies of their relationships; two diagrams (hand-offs and collaborations); the diagrams are generated by a script so they stay in sync; the MVP is the game described in the Final GDD. The Project Lead does the task itself.
- Documents touched: none yet (T-005 updates `README.md` and creates `agent-notes/agents-interactions.md`)
- Tasks: T-005

## 2026-10-04: T-005 done: Agent Crew overview
- Decision or change: the README has an "Agent Crew" section, and `agent-notes/agents-interactions.md` gives the shared overview: two diagrams generated from the agents' working copies by `tools/generate_agent_diagrams.py`, what each agent produces, and why this crew is needed for the MVP as the Final GDD defines it. T-005 passed QA round 1 on all 9 criteria, and the board confirmed the diagrams render and read well.
- Documents touched: `README.md`, `agent-notes/agents-interactions.md`
- Tasks: T-005

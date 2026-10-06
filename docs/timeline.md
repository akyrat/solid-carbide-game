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

## 2026-10-04: Agents communicate only through the Project Lead
- Decision or change: research into the Claude Code documentation showed agents can message each other directly, start their own agents, or run as an experimental agent team. The README's claim that they can't was wrong. The board chose to keep routing all work through the Project Lead with task files, so every piece of work stays on record; it may revisit this when collaborating agents first need to settle details together. The overview now explains that the diagrams show dependencies between agents' work, not conversations.
- Documents touched: `README.md`, `agent-notes/agents-interactions.md`
- Tasks: none

## 2026-10-04: Drift reference is the board's Unity prototype; reverse on S
- Decision or change: the board has built two drift prototypes. The older one, in Unity (`C:\Users\andre\drift-to-survive`), is the one the board is happy with, and Solid Carbide's driving and drifting will copy it. The newer one is not used. The car can reverse with S, as in the Unity prototype. The Driving & Drift Agent will study the Unity prototype and write a report with graphics and a plan for porting it to Godot. The short GDD's controls wording is noted for its next update.
- Documents touched: `docs/drifting.md`, `docs/short-gdd/README.md`
- Tasks: T-006

## 2026-10-04: Unity prototype details: version, saved tuning, drift curve, camera
- Decision or change: the reference is the Unity prototype's current state, with the driving values the board tuned in its pause menu (saved in the Windows registry). The drift curve is the one the Unity prototype uses, replacing the plan to choose between three candidate curves by playtesting. The camera behaves like the Unity prototype's by default. T-006 now covers saved tuning, the drift curve and the camera. `CLAUDE.md`'s description of the Drifting document no longer says the first prototype wasn't successful (approved by the board).
- Documents touched: `docs/drifting.md`, `docs/short-gdd/README.md`, `CLAUDE.md`
- Tasks: T-006

## 2026-10-04: One structure for all separate documents; long GDD generator planned
- Decision or change: every separate document now has a header (title, chapter order, scope, agents) and the same five sections: Summary, Decisions (each dated), Content, Open questions, References. The structure is defined in `docs/README.md`. Open questions stay in their own documents and are never copied into the long GDD. "Ideas under consideration" moved from Decisions to Open questions (the boss shield, and the far-future trick system). A task for the long GDD generator and staleness check was written now, to be worked on once the documents have real content; the board wants to see whether it still fits by then.
- Documents touched: `docs/README.md`, all eight separate documents
- Tasks: T-006 (updated to the new structure), T-007

## 2026-10-06: README "Getting started" brought up to date
- Decision or change: the board updated the root README: "Getting started" now lists what to install, the `.env` setup and the commands that check the setup, and how to work with the Project Lead. The outdated "Suggested first tasks" section was removed; each item is tracked elsewhere (T-007, `docs/unfiled-game-details.md`, `docs/short-gdd/README.md`). Committed by the board.
- Documents touched: `README.md`
- Tasks: none

## 2026-10-06: T-006 done: Unity prototype report
- Decision or change: the Driving & Drift Agent's report on the Unity prototype (`docs/drifting/unity-prototype-report.md`, with charts from `tools/unity_drift_charts.py`) passed QA round 1 on all 11 criteria, and the board reviewed it. Main finding: the car keeps 98% of its sideways speed per physics step while the engine resets forward speed every step, so turning at speed builds a slide faster than the straight-line top speed. The driving values come from the project files; only the camera zoom is still a saved setting.
- Documents touched: `docs/drifting.md`, `docs/drifting/unity-prototype-report.md`
- Tasks: T-006

## 2026-10-06: Boost effect when W snaps to cruise speed
- Decision or change: the board likes the Unity prototype's instant jump to cruise speed on W and wants a short "boost" effect to emphasise it. A placeholder version is written as T-008 for the Driving & Drift Agent, blocked until the Godot car exists. The final look is an open question; its art task comes once the board describes it.
- Documents touched: `docs/drifting.md`
- Tasks: T-008
## 2026-10-06: Drift build decisions: Grass stage, zoom slider, 50 Hz, isometric drawing
- Decision or change: the reference feel is the Unity prototype's Grass stage. The camera zoom stays a player setting with a slider; the board picks the default by playtesting (T-010), and the UI Agent builds the settings slider (T-011). The Godot car runs physics at 50 steps per second, converting the values for 60 only if 50 is not possible. Physics stays flat top-down and is drawn isometrically; the board will playtest whether it feels the same and may go back to flat top-down. The boost art is a linked task for the Asset Generation Agent (T-009).
- Documents touched: `docs/drifting.md`
- Tasks: T-008 (updated), T-009, T-010, T-011

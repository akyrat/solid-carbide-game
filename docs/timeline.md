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

## 2026-10-06: Godot drift prototype task written
- Decision or change: T-012 asks the Driving & Drift Agent to build the first playable piece: the Unity car copied exactly at 50 physics steps per second, a tuning panel with a slider for every driving setting, a camera with a zoom slider, and a switch between flat top-down and isometric drawing for the board's playtest. The jump, arrow keys and gamepad are left out for now. T-008 and T-010 now depend on it.
- Documents touched: none yet (T-012 updates `docs/drifting.md` and `game/README.md`)
- Tasks: T-012, T-008 and T-010 (updated)

## 2026-10-07: Car sprites in 16 directions; placeholder sprites first
- Decision or change: the car is drawn in 16 directions. Before any pixel art, the Asset Generation Agent draws simple placeholder rectangle sprites with a script, not PixelLab, in a flat and an isometric set (T-013); the board's newer prototype made its images the same way (a Godot script, checked read-only). The drift prototype (T-012) now depends on those placeholders, not on the final art. The final pixel-art car (T-014) is made with PixelLab's 8-direction tools plus its Rotate tool for the in-between directions, and is blocked until the board describes the car. The PixelLab account is now on Tier 2 "Pixel Artisan" (5,000 generations a month).
- Documents touched: `docs/visual-style.md`
- Tasks: T-012 (updated), T-013, T-014

## 2026-10-07: One git branch per task
- Decision or change: the board asked that agents use git branches, so unfinished work doesn't pile up uncommitted. Each task that changes the game, its tools or assets gets its own branch in its own worktree folder; the agent commits there, QA checks there, and the Project Lead merges into `master` once the board marks the task done. The rule is in `tasks/README.md`, which every agent reads before starting a task.
- Documents touched: `tasks/README.md`
- Tasks: none

## 2026-10-07: Smaller driving questions tracked
- Decision or change: the Unity prototype report's remaining open questions (the jump on Space, arrow-key steering, gamepad support, collision feel, and a possibly rotating camera in an older version) are now tracked in Drifting, Open questions. No decisions made.
- Documents touched: `docs/drifting.md`
- Tasks: none

## 2026-10-07: T-013 done: placeholder car sprites
- Decision or change: the Asset Generation Agent's script draws two placeholder sheets (flat top-down and isometric, 16 directions, a blue rectangle with a yellow nose), with no PixelLab calls. It passed QA round 1 on all 8 criteria and the board reviewed it. The isometric frames step evenly in world heading, so on screen the steps are uneven; the board kept it that way. Merged from branch `task/T-013-placeholder-car-sprites`, the first task done on its own branch. T-012 is now unblocked.
- Documents touched: `game/README.md`
- Tasks: T-013, T-012 (unblocked)

## 2026-10-07: Epics and milestones for tasks
- Decision or change: every task now has an `epic` (the game area it belongs to, following the game area docs) and a `milestone` (`mvp` or `final-release`). The lists are in `tasks/README.md`; what each milestone includes is decided in the game area docs. All 14 existing tasks were filled in, including the done ones; all are `mvp` for now.
- Documents touched: `tasks/README.md`, `tasks/_TEMPLATE.md`
- Tasks: T-001 to T-014 (headers updated)

## 2026-10-07: Game loop written; weapons, enemy scaling, pause and co-op decided
- Decision or change: the game loop from the Final GDD is now in Game loop architecture, confirmed by the board with two changes: enemies grow slightly in number over a run but don't get tougher, and the MVP has 2 weapons with 1 offered per challenge (final release: around 8 to 12 weapons, 3 offered). Escape pauses the game; the MVP shows only "Paused" with a hint (T-015), and a full pause menu with settings comes in the final release (T-016). The final release adds local co-op for 2 and 4 players with split screen (new epic `local-coop`). The boost effect (T-008, T-009) moved to the final release. T-012's tuning panel moved from Escape to Tab. Two game loop questions remain open: XP from drift time, and the kaiju's meteor challenges versus the GDD's challenges near the kaiju.
- Documents touched: `docs/game-loop-architecture.md`, `docs/weapons.md`, `docs/enemies.md`, `docs/unfiled-game-details.md`, `docs/short-gdd/README.md`, `tasks/README.md`
- Tasks: T-008 and T-009 (milestone), T-012 (Tab), T-015, T-016

## 2026-10-07: Fixed camera zoom; XP from drifting; meteor challenges only
- Decision or change: the camera zoom is fixed, not a player setting; the board picks it by playtesting (T-010), so the settings-slider task T-011 is cancelled and deleted. A drift longer than 1 second gives XP for every second it lasts, each worth 10% of the level-1 XP bar. The kaiju's meteor challenges are the only ones that make it vulnerable, replacing the Final GDD's challenges spawning near it. New open questions on drift XP are in Game loop architecture.
- Documents touched: `docs/drifting.md`, `docs/game-loop-architecture.md`, `docs/enemies.md`, `docs/short-gdd/README.md`
- Tasks: T-010 (updated), T-011 (cancelled and deleted)

## 2026-10-07: Drift XP details; game loop architecture complete
- Decision or change: once a drift passes 1 second, every second counts, the first included. Each second gives a fixed amount of XP, 10% of the level-1 XP bar, which becomes a smaller share as the bar grows. "Drifting" for XP uses the Unity prototype's definition: W or S held together with A or D. Game loop architecture has no open questions left.
- Documents touched: `docs/game-loop-architecture.md`
- Tasks: none

## 2026-10-07: Recap screen after each run (final release)
- Decision or change: in the final release, a recap screen follows every run, win or loss, showing kills per enemy type and other stats the board will choose. Written as T-017 for the UI Agent, blocked until the board lists the stats and describes the look, and until the game has a complete run. Counting the stats will be linked tasks for the agents that own them.
- Documents touched: `docs/game-loop-architecture.md`, `docs/short-gdd/README.md`
- Tasks: T-017

## 2026-10-07: The MVP map
- Decision or change: the MVP map is a city grid of building blocks with roads between them, 5 to 10 car-widths wide; a street never widens along its length, but wide roads can join narrower ones. Obstacles (MVP: crashed meteor boulders) stand on the roads, some from the start in set patterns (3 patterns for the MVP, to be defined), some dropped later by the boss. 30% of the pattern groups become challenges, each marked by an animated arrow painted on the ground. The city is Tokyo-style cyberpunk with skyscrapers, the roads are asphalt, and buildings turn see-through when the car is behind them (how to do this in Godot needs looking into).
- Documents touched: `docs/level-design.md`, `docs/visual-style.md`, `docs/short-gdd/README.md`
- Tasks: none yet

## 2026-10-07: The Level/Challenge Design Agent makes the map
- Decision or change: the board does no level design itself; the Level/Challenge Design Agent makes the map from the rules in Level design and the board's descriptions and drawings. Drawings are stored in a folder named after their game area doc and linked from its References.
- Documents touched: `docs/level-design.md`, `docs/README.md`
- Tasks: none

## 2026-10-07: The MVP map is made once
- Decision or change: for the MVP, the Level/Challenge Design Agent makes the map once and every run uses it. After the MVP, the board plans to draw maps by hand and may explore generating a new map each run (recorded as an open question).
- Documents touched: `docs/level-design.md`
- Tasks: none

## 2026-10-07: MVP map layout
- Decision or change: map sizes are in units of the car's width. An 8-unit road runs around the edge of the map, which ends in a hard stop. Inside it, 10 by 10 building blocks sit in a 4 by 4 grid with 8-unit roads between them, and the centre is an open 28 by 28 square of gravel with no blocks. The board's stated total of 72 by 72 doesn't match the layout (which adds up to 80 by 80); this and the car's length (2 or 3 units) are open questions.
- Documents touched: `docs/level-design.md`
- Tasks: none

## 2026-10-07: 80 by 80 map; car drawn 3:1
- Decision or change: the MVP map is 80 by 80 units (the board's 72 didn't match the layout; the board chose to keep every road and block size and grow the map). The car is drawn 1 unit wide and 3 units long; this is the drawing only, and the physics body stays the Unity prototype's 1 by 1 square, so collisions behave the same. 1 unit is the drawn car's width and the unit the driving values use. The placeholder sprites are redrawn at 3:1 (T-018), and the drift prototype (T-012) now waits for them.
- Documents touched: `docs/level-design.md`, `docs/drifting.md`, `docs/visual-style.md`
- Tasks: T-018, T-012 and T-014 (updated)

## 2026-10-07: T-018 done: placeholder car sprites at 3:1
- Decision or change: the placeholder sheets now show a 48 by 16 pixel car (1 by 3 units, 16 pixels per unit) in 80 by 80 frames, with the car's size added to the layout files. It passed QA round 1 on all 7 criteria and the board reviewed it. Merged from `task/T-018-placeholder-car-sprites-3-to-1`. T-012, the drift prototype, is now unblocked.
- Documents touched: `game/README.md`
- Tasks: T-018, T-012 (unblocked)

## 2026-10-07: MVP obstacles and challenge arrows
- Decision or change: in the MVP, obstacles are circles drawn as boulders, with a diameter of 1, 2 or 3 car lengths (3, 6 or 9 units). A challenge has up to 2 obstacles of any of those sizes, and its arrow path is shaped to them with the Driving & Drift Agent's scripts for what the car can actually drive. Open: a 9-unit obstacle is wider than every 8-unit road.
- Documents touched: `docs/level-design.md`, `docs/visual-style.md`
- Tasks: none yet

## 2026-10-07: Map editor, readiness summary and status line
- Decision or change: the board and the Project Lead draw the map in Crash City Grid, a private claude.ai page (linked from Level design, References): cells, boulders, pattern groups, challenges and their arrows, saved for the Project Lead to read. A readiness summary (MVP Docs Readiness page) puts the game area docs at about 43% of an MVP-ready first draft. The Project Lead keeps those estimates in `docs/mvp-readiness.json`, which a Claude Code status line (`tools/statusline.py`, set in `.claude/settings.json`) shows at the bottom of the terminal.
- Documents touched: `docs/level-design.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: Obstacle patterns and challenges
- Decision or change: MVP boulders are all 3 units across, so they never block a road (replacing 3, 6 or 9). The MVP has 2 obstacle patterns, defined by the board: Pattern 1 is 1 boulder with 2 possible challenge arrows, Pattern 2 is 2 boulders with 1. A pattern can have several possible challenges, each a different arrow path. Which pattern groups are challenges (30%) is preset and the same every run; the Level/Challenge Design Agent chooses first and the board adjusts. The arrow marks the challenge's corridor. A completed challenge's arrow disappears and the player gets XP. The HUD layout is still undefined. Crash City Grid now places 3-unit boulders only and lets a group hold several arrows. Level design readiness: 70%.
- Documents touched: `docs/level-design.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: Challenge drawings per pattern folder
- Decision or change: when a pattern with several possible arrows becomes a challenge, the Level/Challenge Design Agent picks one arrow. A completed challenge's boulders stay as plain obstacles for the rest of the run. The board draws each challenge in Crash City Grid as its own drawing, grouped in a folder per obstacle pattern; drawings in a folder share their boulders and differ only in the arrow. The editor now supports this ("New challenge drawing").
- Documents touched: `docs/level-design.md`
- Tasks: none

## 2026-10-08: Challenge corridor width; pattern copies left to the agent
- Decision or change: a challenge's painted arrow is as wide as the car is long (3 units) and is the corridor; the car only has to touch it, and the Driving & Drift Agent's scripts make sure each path is drivable. The Level/Challenge Design Agent decides how many copies of each pattern go on the map, and where. Crash City Grid now draws arrows at their real 3-unit width. One of the two Single Boulder arrows is meant to go counter-clockwise; it will be redrawn.
- Documents touched: `docs/level-design.md`
- Tasks: none

## 2026-10-08: MVP challenges drawn and saved; level 1 XP
- Decision or change: the board drew the 3 MVP challenges in Crash City Grid (Single Boulder: a clockwise and a counter-clockwise loop; Two Boulders: a figure-eight). They are saved in `docs/level-design/` as data and pictures by the new `tools/export_challenge_drawings.py`, and shown in Level design, Content. "The car" touching a challenge corridor is the drawn car (1 by 3). At level 1 one completed challenge levels the player up to level 2 with a weapon choice; the Game Data Agent works out the XP scaling. New open question: does the weapon choice open on every challenge or only on level-up? Level design is at 90%, with no MVP questions left.
- Documents touched: `docs/level-design.md`, `docs/game-loop-architecture.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: Weapon choice only on level-up
- Decision or change: the weapon choice opens only when the XP bar fills and the player levels up, not on every completed challenge. A completed challenge flashes a score and gives XP. Game loop architecture (decision and run flowchart) and Weapons updated.
- Documents touched: `docs/game-loop-architecture.md`, `docs/weapons.md`
- Tasks: none

## 2026-10-08: Tickets for the map, see-through buildings and challenge drivability
- Decision or change: T-019 (Level/Challenge Design) builds the MVP map with placeholder colours, places the pattern copies and preset challenges, and signals completed challenges; it is blocked on two board questions, now open in Level design: the challenges (11 to 13 units wide with their corridors) don't fit on the 8-unit roads, and what exactly counts as completing a challenge. T-020 (Level/Challenge Design) researches see-through buildings with a small test scene. T-021 (Driving & Drift) writes the challenge drivability check and driven-line tool, after T-012. All are epic `level-challenges`, milestone `mvp`.
- Documents touched: `docs/level-design.md`, `docs/mvp-readiness.json`
- Tasks: T-019, T-020, T-021

## 2026-10-08: MVP and after-MVP questions separated; balancing handed to Game Data
- Decision or change: open questions that can wait start with "(After MVP)" (rule in `docs/README.md`): the recap screen, the boost look, the test jump, arrow keys, gamepad, the possibly rotating old camera, the trick system, post-MVP maps, the boss shield and per-boss names. Balancing numbers go to the Game Data Agent (with the Enemy Behavior Agent for enemies): weapon upgrade scaling, enemy number growth, coin drops, the kaiju's vulnerability window and meteor frequency. New MVP questions recorded in Enemies (the minion, the kaiju's health) and Weapons (upgrade levels and what they change). Readiness: 51%.
- Documents touched: `docs/README.md`, `docs/game-loop-architecture.md`, `docs/drifting.md`, `docs/level-design.md`, `docs/enemies.md`, `docs/weapons.md`, `docs/extended-narrative.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: Challenge drawings are rough sketches
- Decision or change: the board's challenge drawings capture the general shape only. The Level/Challenge Design Agent makes fitted versions that work on the map (for example on the 8-unit roads), adjusting size, spacing and tightness while keeping the number of boulders, the arrow's direction around each, and the overall path; the Driving & Drift Agent's check confirms they can be driven. This answers where challenges go. T-019 now waits only on what counts as completing a challenge; T-021 checks the fitted versions.
- Documents touched: `docs/level-design.md`, `docs/mvp-readiness.json`
- Tasks: T-019, T-021 (updated)

## 2026-10-08: Completing a challenge; Level design done for the MVP
- Decision or change: a challenge is completed when the drawn car touches its corridor continuously from the arrow's start to its end, in the arrow's direction; leaving midway means starting again. Level design has no MVP questions left (100%). T-019 is unblocked.
- Documents touched: `docs/level-design.md`, `docs/mvp-readiness.json`
- Tasks: T-019 (unblocked)

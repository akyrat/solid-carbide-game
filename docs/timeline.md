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

## 2026-10-08: The 2 MVP weapons
- Decision or change: the MVP weapons are a starting gun (every run starts with it; no visible weapon, only bullets; fires automatically at set intervals at enemies within range, aiming itself) and an exhaust flamethrower that fires only while drifting. Upgrading the gun's fire rate comes after the MVP. Open: the gun's target choice, the flamethrower's drifting definition and flame shape, and how level-ups and upgrades work in the MVP.
- Documents touched: `docs/weapons.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: MVP weapons copy the Unity prototype's
- Decision or change: the starting gun and the exhaust flamethrower copy the behaviour of the matching weapons in the board's Unity prototype. T-022 asks the Weapon Behavior Agent to study them there, read-only, and write a report, as T-006 did for driving. Still open: how level-ups and upgrades work in the MVP.
- Documents touched: `docs/weapons.md`, `docs/mvp-readiness.json`
- Tasks: T-022

## 2026-10-08: MVP weapon upgrades copy the Unity prototype's
- Decision or change: the two MVP weapons' upgrades copy the Unity prototype's upgrade tiers; the Game Data Agent balances from those values. T-022 now also covers the prototype's upgrade tiers and how its level-up chooses what to offer. The board confirms the level-up flow against the report.
- Documents touched: `docs/weapons.md`, `docs/mvp-readiness.json`
- Tasks: T-022 (updated)

## 2026-10-08: MVP minion to be picked from the Unity prototype's enemies
- Decision or change: the board will pick the MVP minion from the Unity prototype's three regular enemies (Monster1, Monster4, Monster7). T-023 asks the Enemy Behavior Agent to describe all three, plus what they share and how the prototype spawns them, read-only. The prototype's XP drops don't carry over.
- Documents touched: `docs/enemies.md`
- Tasks: T-023

## 2026-10-08: Kaiju health
- Decision or change: the kaiju takes about 4 vulnerability windows to kill; the Game Data Agent sets the actual number with the weapon damage. Enemies' only MVP question left is which Unity enemy becomes the minion (after T-023).
- Documents touched: `docs/enemies.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: MVP garage and main menu
- Decision or change: the game opens on a main menu (Start, Garage, Quit) and returns there when a run ends. The MVP garage sells three permanent upgrades, each about 10 levels: acceleration, car HP, and a weapon damage bonus in percent; the Game Data Agent sets prices and per-level effects. The garage screen is a plain list in the MVP; its look, more upgrades and unlockable cars come after the MVP.
- Documents touched: `docs/garage-design.md`, `docs/game-loop-architecture.md`, `docs/short-gdd/README.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: HUD and menus game area doc
- Decision or change: a new game area doc, HUD and menus, holds what used to be unfiled: the pause decision, plus the new HUD and level-up decisions. The HUD shows the car's HP as a bar, a timer counting down from 8:00, the XP bar and level, coins collected, an arrow to the nearest challenge, and the kaiju's health once it appears. Levelling up pauses the game; the level-up screen shows plain cards, each with a title and a description. Open: where each HUD element goes on screen. Listed in `docs/README.md` and as the `hud-menus` epic's game area doc.
- Documents touched: `docs/hud-and-menus.md`, `docs/unfiled-game-details.md`, `docs/README.md`, `tasks/README.md`, `agent-notes/agents-interactions.md`, `docs/short-gdd/README.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: HUD layout; HUD and menus added to the definitions
- Decision or change: the UI Agent proposes the first HUD layout and the board adjusts it in playtest. With the board's approval, `CLAUDE.md` now lists HUD and menus among the documents the Project Lead maintains, and the UI Agent's definition lists it as a document it works on. HUD and menus has no MVP questions left.
- Documents touched: `docs/hud-and-menus.md`, `CLAUDE.md`, `.claude/agents/ui.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: Extended narrative: tone, livestream and likes; text and visuals checks on tasks
- Decision or change: Extended narrative now sets the game's tone (satirical, tongue-in-cheek about an out-of-touch Redgull; the player's fun is slightly unethical), names the player Stunt Driver, makes every run a livestream where challenges earn likes, and shows XP to players only as likes; filling the likes bar earns a gift pack. Redgull funds the car's upgrades (from the Final GDD). It changes rarely and is read before any user-facing text or graphics are made. The Narrative Theme Agent writes all user-facing text, including how likes are shown (T-024, after T-022). The main menu shows "SOLID CARBIDE" with a discreet "(work in progress)". After-MVP ideas recorded: "Stan D. River", plot frames between levels, people in need of help, plane-dropped gift packs, difficulty modifiers. Every task now says whether it has user-facing text and whether it changes visuals, and then lists Extended narrative (and Visual style for visuals) to read first; the template and all existing tasks are updated.
- Documents touched: `docs/extended-narrative.md`, `docs/hud-and-menus.md`, `docs/game-loop-architecture.md`, `docs/short-gdd/README.md`, `docs/mvp-readiness.json`, `tasks/README.md`, `tasks/_TEMPLATE.md`
- Tasks: T-024; T-001 to T-023 (headers updated)

## 2026-10-08: Pixel-art technical specs from a reference image
- Decision or change: from the board's reference car sprite (saved in `docs/visual-style/` as a technical reference only): true pixel art with hard edges and no anti-aliasing, a selective dark outline, detailed shading, high detail, about 30 colours per sprite, about 40 pixels per unit (car frames 128 by 128), and a 3/4 isometric view; the final car art is isometric only. Visual style now lists the remaining MVP questions. T-014 updated.
- Documents touched: `docs/visual-style.md`, `docs/mvp-readiness.json`
- Tasks: T-014 (updated)

## 2026-10-08: Visual style: palette, mood, car, city and creatures
- Decision or change: a dark navy and purple night with pink, cyan and Redgull-green neon; night-time with a retro feel. The car is inspired by a 1967 Ford Mustang fastback, dark green with two parallel stripes down its middle (reference photos saved in `docs/visual-style/`). Tokyo-style towers with vertical signs, lit windows and satirical Redgull billboards; cracked asphalt with lane lines and crossings; dusty gravel centre; dark boulders with glowing cracks; a glowing painted challenge arrow that draws itself, pulses and fades; a red warning circle, falling meteor and dust burst for the kaiju's attack; a Godzilla-style kaiju; light-green four-legged scaled lizards as the minion, walking towards the player. Open: stripe colour and livery, how "retro" shapes the glow, effects, and whether the minion still copies a Unity enemy's stats.
- Documents touched: `docs/visual-style.md`, `docs/enemies.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: Glow, references, stripes and minion stats
- Decision or change: glow is drawn into the sprites (bright pixels with stepped halos, no engine blur or bloom). Real-world references are inspiration only: no real logos or badges, no exact copies of existing characters. The car's two stripes are white. The minion doesn't copy a Unity enemy; the Game Data Agent sets its health, contact damage and knockback.
- Documents touched: `docs/visual-style.md`, `docs/enemies.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: Effects, challenge arrow colours and the kaiju's shield
- Decision or change: the Asset Generation Agent designs the effects within the palette, glow and pixel style. Map challenge arrows are blue; the kaiju's meteor challenges have green arrows. While the kaiju can't be hurt it sits in a green, see-through oval shield; completing one of its challenges removes the shield and it shows its normal look while vulnerable (the shield idea moved from "after MVP" to decided). Open: how see-through is drawn under the no-semi-transparent-pixels rule.
- Documents touched: `docs/visual-style.md`, `docs/enemies.md`, `docs/mvp-readiness.json`
- Tasks: none

## 2026-10-08: See-through rule, no livery for the MVP, car bounces off walls
- Decision or change: the no-semi-transparent-pixels rule covers pixels inside sprites; the game may fade whole objects (the kaiju's shield, buildings). The MVP car has no livery (Redgull livery is after the MVP). The car bounces off walls slightly. Visual style has no MVP questions left.
- Documents touched: `docs/visual-style.md`, `docs/drifting.md`, `docs/mvp-readiness.json`
- Tasks: T-019 (updated)

## 2026-10-08: Bounce off boulders, level-up flow, T-023 cancelled
- Decision or change: the car bounces off boulders as it does off walls (enemies still open). The MVP level-up offers 2 choices: first "get the flamethrower" or "upgrade the gun", then "upgrade the gun" or "upgrade the flamethrower". T-023 (Unity enemies report) is cancelled and deleted: the board defined the minion itself and its stats go to the Game Data Agent. Weapons has no MVP questions left.
- Documents touched: `docs/drifting.md`, `docs/weapons.md`, `docs/enemies.md`, `docs/mvp-readiness.json`
- Tasks: T-023 (cancelled), T-022 (updated)

## 2026-10-08: How the long and short GDD are made
- Decision or change: the long GDD is generated by a script only (T-007, now updated for nine game area docs, images, and dropping decision dates). The short GDD becomes a pitch-style Markdown document with a PDF export, written by the Project Lead from the long GDD (T-025, after T-007); the original Final GDD PDF is kept as the historical original. Recorded in `docs/README.md`. Next: build the task board for the MVP, then the drift prototype.
- Documents touched: `docs/README.md`
- Tasks: T-007 (updated), T-025

## 2026-10-08: Visual style summary; weapons report reference
- Decision or change: Visual style gets a Summary written from its decisions (no new decisions). Weapons' reference to the not-yet-written T-022 report is plain text until the report exists, so the long GDD has no dead links.
- Documents touched: `docs/visual-style.md`, `docs/weapons.md`
- Tasks: none

## 2026-10-08: README car image and key-art scene
- Decision or change: the root README gets the final car at its top right, taken from a T-014 frame with no new generation (T-026, MVP, after T-014). A promotional key-art scene (the car drifting through the neon city, minions closing in, the shielded kaiju behind) is made with PixelLab for the README and later pitch material (T-027, final release, after T-014 and the future minion and kaiju art tasks).
- Documents touched: none yet (both tasks update `README.md`)
- Tasks: T-026, T-027

## 2026-10-08: Visual style references tidied
- Decision or change: Visual style's three reference images each get their own line and caption, so they read cleanly in the long GDD. No new decisions.
- Documents touched: `docs/visual-style.md`
- Tasks: none

## 2026-10-08: T-007 done: long GDD generator and staleness check
- Decision or change: `tools/generate_long_gdd.py` builds `docs/long-gdd.md` from the nine game area docs (script only; open questions and decision dates left out) and `--check` reports stale game area docs and whether the short GDD has caught up. It passed QA round 1 on all 11 criteria; after QA's reading notes the Content heading was kept and a link test added; the board reviewed the long GDD. Merged from `task/T-007-long-gdd-generator`. T-025 (short GDD) is unblocked.
- Documents touched: `docs/long-gdd.md`, `docs/README.md`, `docs/short-gdd/README.md`
- Tasks: T-007, T-025 (unblocked)

## 2026-10-08: The Final GDD PDF is historical
- Decision or change: the original `Solid_Carbide_-_Final_GDD.pdf` is historical and no longer a source of truth; the game area docs are. `CLAUDE.md` (approved by the board) now names `docs/short-gdd/short-gdd.md` as the short GDD, the crew notes define the MVP by the game area docs, and the two game area docs that cite the PDF label it as superseded. The short GDD folder's README and `docs/README.md` say the same in T-025. Long GDD regenerated.
- Documents touched: `CLAUDE.md`, `agent-notes/agents-interactions.md`, `docs/game-loop-architecture.md`, `docs/extended-narrative.md`, `docs/long-gdd.md`
- Tasks: T-025

## 2026-10-08: Livestream combo idea (T-028)
- Decision or change: the board's idea of a "livestream combo" (consecutive tricks without a collision grow a multiplier on likes, shown as a vertical "current viewers" bar next to the likes bar; a collision cuts it by 80%, and after a 2-second chain interval with no trick it drops exponentially) is recorded as an exploration ticket, assumed after the MVP. It is the counterbalance to the helping-people idea in Extended narrative. No game area doc changes until the board settles it.
- Documents touched: none yet
- Tasks: T-028

## 2026-10-08: Greenbull renamed Redgull
- Decision or change: the energy-drink brand is renamed from Greenbull to **Redgull** everywhere, including earlier timeline entries (board). The colour decisions are unchanged: the palette's brand neon is still green ("Redgull-green"). The historical Final GDD PDF is left as it is. Long GDD regenerated.
- Documents touched: `docs/extended-narrative.md`, `docs/visual-style.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `docs/timeline.md`, `agent-notes/agents-interactions.md`, `.claude/agents/narrative-theme.md` (approved by the board)
- Tasks: T-024 (wording), T-025 (short GDD)

## 2026-10-08: Redgull's logo and colour
- Decision or change: Redgull's logo is a simple, sketched seagull with red eyes, slightly evil and unsettling, which suits the story. The company's theme colour is red, used only on Redgull's own things: logo, billboards and, in the MVP, the weapons (not all red; included where it fits). It does not affect the car, enemies, map or anything else. Correction: the board never defined a brand colour; the "Greenbull-green" neon in the palette was wrongly attributed to the brand. It is removed, so the city's neon accents are pink and cyan.
- Documents touched: `docs/visual-style.md`, `docs/extended-narrative.md`, `docs/long-gdd.md`
- Tasks: T-025 (short GDD)

## 2026-10-08: The city is not Redgull's
- Decision or change: the city has nothing to do with Redgull: the buildings carry none of its colours or branding (the "satirical Redgull billboards" are dropped from the buildings). After the MVP, occasional Redgull banners may be added as separate assets placed on buildings (board); their art task is written then.
- Documents touched: `docs/visual-style.md`, `docs/long-gdd.md`
- Tasks: T-025 (short GDD)

## 2026-10-08: T-012 done: Godot drift prototype
- Decision or change: the board playtested the Godot drift prototype, adjusted some settings on the tuning panel and is very happy with the drift. It passed QA round 1 on all 11 criteria. Merged from `task/T-012-godot-drift-prototype`. T-008, T-015 and T-021 are unblocked. The board also wants the camera zoom slider kept as a player setting in the pause menu, which reverses the fixed-zoom decision; T-010 stays blocked until that is recorded.
- Documents touched: `docs/drifting.md`, `docs/long-gdd.md`, `game/README.md`
- Tasks: T-012 (done), T-008, T-015, T-021 (unblocked), T-010

## 2026-10-08: Drift defaults after the playtest; zoom slider in the MVP pause screen
- Decision or change: after playtesting T-012 the game keeps the Unity values except: top speed 3.0 times cruise speed (Unity 2.5), physics interpolation on, and the isometric view (the board is happy with it, so the flat-view fallback question is closed). The jump to cruise speed stays at 11. The camera zoom becomes a player setting again: a slider (6 to 20, default 14.4) on the MVP pause screen, saved between sessions. T-029 sets the new defaults; T-015 now builds the pause screen with the zoom slider in one ticket (board); T-010 is done.
- Documents touched: `docs/drifting.md`, `docs/hud-and-menus.md`, `docs/long-gdd.md`
- Tasks: T-029 (new), T-015 (updated), T-010 (done)

## 2026-10-08: Short GDD tone wording; design pillars ticket
- Decision or change: "tongue-in-cheek" is a working phrase only, not for a pitch, so it is removed from the short GDD's tone line, which now reads "The tone is **satirical**." (T-025). The game area docs keep it as an internal note. The short GDD's design pillars read like agent instructions; the board will rework them into presentable pillars (T-030), and the Project Lead then records them in a game area doc and carries them down to the long and short GDD.
- Documents touched: `docs/short-gdd/short-gdd.md` (T-025 branch)
- Tasks: T-025, T-030 (new)

## 2026-10-09: T-025 done: short GDD as a pitch; visualisation tools ticket
- Decision or change: the board approved the short GDD (`docs/short-gdd/short-gdd.md`, with `short-gdd.pdf` exported by `tools/export_short_gdd_pdf.py`). It passed QA round 2 on all 8 criteria; during review "tongue-in-cheek" was removed from its tone line and the design pillars were sent to the board to rework (T-030). Merged from `task/T-025-short-gdd-rewrite`; long and short GDD in sync. The board will build its own HTML visualisation tools at some point (T-031). The MVP docs status line is to be removed. Next: the full MVP task board.
- Documents touched: `docs/short-gdd/short-gdd.md`, `docs/short-gdd/short-gdd.pdf`, `docs/short-gdd/README.md`, `docs/README.md`
- Tasks: T-025 (done), T-030, T-031 (new)

## 2026-10-09: Task board page (T-032)
- Decision or change: the board asked for an HTML task board: four lanes (To do, In progress, QA, Done) with draggable tickets, and a game-areas view with one bubble per game area doc showing its tickets and how much is done, plus an overall MVP figure that says it only counts existing tickets. Built by the Project Lead as a published page; the task files stay the source of truth (`tools/taskboard_sync.py` exports them to the page and applies the board's moves back). Next: agents read the game area docs and write every missing MVP ticket; post-MVP tickets come later (board).
- Documents touched: `docs/README.md`, `tasks/README.md`
- Tasks: T-032 (new), T-031

## 2026-10-09: New epics: game-loop and narrative
- Decision or change: two epics added with the board's agreement, so tickets for these game area docs have their own place on the task board: `game-loop` (Game loop architecture) and `narrative` (Extended narrative).
- Documents touched: `tasks/README.md`
- Tasks: T-032

## 2026-10-09: Player-facing text comes from the Narrative Theme Agent, per task
- Decision or change: whenever the Project Lead writes a task that shows the player any text, it also writes a linked task for the Narrative Theme Agent to produce that text. Unlike art, text never uses placeholders: the main task depends on the text task, so the text is written first. Added to `CLAUDE.md` (approved by the board) and `tasks/README.md`.
- Documents touched: `CLAUDE.md`, `tasks/README.md`
- Tasks: none yet (T-024 unchanged)

## 2026-10-09: T-024 cancelled
- Decision or change: T-024 ("write all of the MVP's user-facing text") is cancelled and deleted (board). Player-facing text is now written per task: each task that shows text gets a linked Narrative Theme task first (see the previous entry).
- Documents touched: none
- Tasks: T-024 (cancelled)

## 2026-10-09: Tasks are never deleted; cancelled tasks restored
- Decision or change: tasks are never deleted (board). A task that is no longer wanted gets the new status `cancelled`, with a note saying why and when, and the task board shows it in the Done lane (left out of progress figures). The three tasks deleted earlier are restored from git history and marked cancelled: T-011 (camera zoom settings slider, cancelled 2026-10-07), T-023 (Unity enemies report, 2026-10-08) and T-024 (all MVP user-facing text, 2026-10-09).
- Documents touched: `tasks/README.md`, `tasks/_TEMPLATE.md`
- Tasks: T-011, T-023, T-024 (restored, cancelled), T-032

## 2026-10-09: MVP gaps settled (board's defaults); new Game Loop Agent
- Decision or change: after nine agents listed every MVP feature from the game area docs (about 135, fewer than a quarter ticketed), the board accepted the Project Lead's defaults for the gaps they found:
  - a new **Game Loop Agent** builds the run itself (timer, likes and levels, car health, win and loss, screen flow)
  - a run ends straight at the main menu with no message (the old "MVP goes to the Garage" line is corrected)
  - the car does not bounce off enemies
  - the boost effect is after the MVP
  - minion spawning and contact-damage rate, and how many kaiju challenges can be open at once, are proposed by Enemy Behavior with Game Data
  - killing the kaiju ends the run at once as a win
  - coins are kept on a loss
  - a challenge's score flash shows the likes gained
  - coins and upgrade levels are saved to disk
  - the MVP has basic sound effects
  - art details the docs leave open are proposed in each art task
  Long GDD regenerated; the short GDD's team line updated.
- Documents touched: `docs/drifting.md`, `docs/enemies.md`, `docs/game-loop-architecture.md`, `docs/garage-design.md`, `docs/visual-style.md`, `docs/unfiled-game-details.md`, `docs/long-gdd.md`, `docs/short-gdd/short-gdd.md`, `docs/short-gdd/short-gdd.pdf`, `docs/short-gdd/README.md`, `CLAUDE.md`, `.claude/agents/game-loop.md`, `agent-notes/game-loop.md`, `agent-notes/project-lead.md`, `agent-notes/agents-interactions.md`
- Tasks: none yet (MVP tickets next)

## 2026-10-09: Models per task; Drifting and Level design tickets
- Decision or change: every task now names the model its agent runs on (`model: sonnet` or `opus`), chosen per task by the Project Lead (board); the rule is in `tasks/README.md`, "Models". First MVP ticket batch:
  - Drifting: T-033 (car collisions: bounce off walls and boulders, knockback for enemies to call)
  - Level design: T-034 (buildings turn see-through, after T-019 and T-020) and T-035 (challenges created during a run, for the kaiju's meteors, after T-019)
  - Models set on T-019, T-020, T-021 and T-029
  Art for these areas comes with the Visual style batch.
- Documents touched: `tasks/README.md`, `tasks/_TEMPLATE.md`
- Tasks: T-033, T-034, T-035 (new); T-019, T-020, T-021, T-029 (model set)

## 2026-10-09: Game loop, Enemies and Weapons tickets
- Decision or change: MVP tickets for three more areas:
  - Game loop: T-036 (the run scene, the 8-minute clock, car health, coins, win and loss), T-037 (likes and levels from challenges and drifts; a level-up pauses the run) and T-038 (the run's numbers, and the game data convention)
  - Weapons: T-040 (weapon numbers), T-041 (starting gun), T-042 (exhaust flamethrower), T-043 (the level-up offers); T-022 gets its model
  - Enemies: T-039 (enemy numbers), T-044 (minions and coins), T-045 (the kaiju, its shield and windows) and T-046 (the meteor attack)
  Meteor challenges give XP like any challenge, as Game loop architecture reads. Art, text and the screens come in later batches.
- Documents touched: none
- Tasks: T-036 to T-046 (new), T-022 (model set)

## 2026-10-09: Art swaps itself in; HUD, menus, Garage, Visual style and Sound tickets
- Decision or change: when work has a visual and a functional side, the art task depends on the functional task and swaps its final art in for the placeholder itself (board; option a). Recorded in `CLAUDE.md` and `tasks/README.md`; T-009 now depends on T-008; T-014 is unblocked, since Visual style now describes the car. The rest of the MVP ticket board:
  - text tasks for the Narrative Theme Agent, which the screens depend on: T-047 (pause; T-015 now depends on it), T-048 (HUD), T-051 (level-up screen), T-053 (main menu) and T-059 (garage)
  - HUD and menus: T-049 and T-050 (HUD), T-052 (level-up screen), T-054 (main menu), and T-055 (screen flow, for the Game Loop Agent)
  - Garage: T-056 (numbers), T-057 (saving and buying), T-058 (screen), and T-060 to T-062 (each upgrade applied by the agent owning the thing it changes)
  - Visual style: T-063 to T-075 (map ground, buildings, boulders, arrows and their animation, minion, kaiju and shield, meteor attack, weapon effects, hit, coin and damage effects, drift smoke, challenge and level-up effects, the Redgull logo)
  - Sound: T-076 (find) and T-077 (play in game)
  - T-078: QA's full run from the main menu before the MVP playtest
- Documents touched: `CLAUDE.md`, `tasks/README.md`
- Tasks: T-047 to T-078 (new); T-009, T-014, T-015 (updated)

## 2026-10-09: Task board shows the board's review
- Decision or change: clicking a ticket on the task board now shows "Your review": what the board is asked to check (the task's "The board's review:" line), whether it is ready, the task's folder and file and the files to open ("Board review files:"), each with a copy button, and the agent's and QA's result notes. The sync reads each open task from its branch folder. The convention is in `tasks/README.md`, "The board's review".
- Documents touched: `tasks/README.md`
- Tasks: T-032; T-020, T-029, T-038 (review lines added on their branches)

## 2026-10-10: Tricks and the combo, in the MVP
- Decision or change: the board settled the combo (T-028 done), as part of the MVP:
  - three tricks done with the existing driving: extended drift (each drifting second, low value), 360 (a full turn in one unbroken drift, mid value) and alternate drift (switching between forward and backward drifts with the same steering, high value)
  - each trick raises a combo multiplier on all likes; a collision with anything, enemies included, cuts it by 80%; after 2 seconds without a trick it drains
  - the HUD shows a combo counter next to the likes bar, and each trick pops its name out from the car in comic-style letters
  - a higher combo also raises minion spawning, with an off switch, to be judged in playtests
  The likes from drifting seconds stay. The combo is the counterbalance Extended narrative's helping-people idea asked for. Build tasks: T-079 (trick detection), T-080 (numbers), T-081 (the combo), T-082 (text), T-083 (counter and popups), T-084 (popup art), T-085 (spawning); T-033 now also sends a collision signal. Long and short GDD updated.
- Documents touched: `docs/drifting.md`, `docs/game-loop-architecture.md`, `docs/hud-and-menus.md`, `docs/enemies.md`, `docs/extended-narrative.md`, `docs/long-gdd.md`, `docs/short-gdd/short-gdd.md`, `docs/short-gdd/short-gdd.pdf`, `docs/short-gdd/README.md`
- Tasks: T-028 (done), T-079 to T-085 (new), T-033 (updated)

## 2026-10-10: T-038, T-021 and T-019 done
- Decision or change: the board approved three tasks on QA's pass, without a separate review: T-038 (the run's numbers and the game data convention; the numbers are judged in the balancing playtest), T-021 (the challenge drivability check; the board's three sketches are all drivable, but only with coasting or braking, never with W held) and T-019 (the MVP map: 12 pattern copies, 4 preset challenges, fitted versions of the sketches; the layout can be adjusted after playing). Merged; the fitted challenges still need the drivability check. Unblocked: T-035, T-036, T-056, T-063, T-065, T-080. Long GDD regenerated.
- Documents touched: `docs/game-loop-architecture.md`, `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-019, T-021, T-038 (done); T-035, T-036, T-056, T-063, T-065, T-080 (unblocked)

## 2026-10-10: The Unity weapons' quirks: copy, with three fixes
- Decision or change: the board answered the Unity weapons report's 11 open questions with the Project Lead's suggestions. The MVP copies the prototype's weapons as they are, including their quirks (the flame using the gun's damage, the large bullet hit circle, the gun checking for targets once per interval, no knockback, the compounding steering tier, the visual-only tier 5, reversing counting as drifting), with three fixes: no rounding of damage, a flame area that doesn't grow on diagonals, and missed bullets removed past the gun's range. A weapon at its last tier is no longer offered; if both are, the level-up is skipped.
- Documents touched: `docs/weapons.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-022, T-040, T-041, T-042, T-043

## 2026-10-10: T-022 done: the Unity weapons report
- Decision or change: the board approved the report on the starting gun and the exhaust flamethrower in the Unity prototype (`docs/weapons/unity-weapons-report.md`); its open questions are answered in Weapons, Decisions. Merged. T-040 (weapon numbers) is unblocked.
- Documents touched: `docs/weapons.md`, `docs/weapons/unity-weapons-report.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-022 (done), T-040 (unblocked)

## 2026-10-10: T-029 and T-020 done; how buildings go see-through
- Decision or change: the board played T-029 (the drift defaults) and approved it. For see-through buildings (T-020's research), the board chose: fade the whole building to 15% visible over 0.15 seconds while the car is behind it; only the car is kept visible in the MVP, not enemies or the kaiju. Recorded in Visual style, Decisions. Both merged. Unblocked: T-034 (see-through build), T-073 (drift smoke art), T-079 (trick detection); T-033 (car collisions) can now start.
- Documents touched: `docs/visual-style.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-029, T-020 (done); T-034, T-073, T-079 (unblocked)

## 2026-10-10: Text for the pause screen, HUD and main menu approved
- Decision or change: the board approved the Narrative Theme Agent's text, with changes: the main menu buttons are simply Start, Garage and Exit (Game loop architecture now says Exit, not Quit), and the HUD's coins label is just "Coins". The pause screen text is approved as is ("Paused", "Press Escape to get back to the stream.", "Camera zoom, for the fans"), as is the rest of the HUD ("Likes" with a heart icon in Redgull red, "Hype Lv {level}", "Car Health", "Kaiju (Co-Star)", "Trending! +{likes} Likes"). The heart icon's art is T-086. Merged T-047, T-048 and T-053; T-015 (pause screen) and T-054 (main menu) are unblocked.
- Documents touched: `docs/game-loop-architecture.md`, `docs/long-gdd.md`
- Tasks: T-047, T-048, T-053 (done); T-015, T-054 (unblocked); T-086 (new); T-054, T-055 (Exit)

## 2026-10-10: T-032 done: the task board page
- Decision or change: the board is happy with the task board page as it is (lanes, game-area bubbles, "Your review" with files and notes). Marked done; it was approved by the board directly rather than through QA.
- Documents touched: none
- Tasks: T-032 (done)

## 2026-10-10: Every art task is reviewed by the board
- Decision or change: anything the Asset Generation Agent makes needs the board's review, so the board stays in control of how the assets look and their style (`tasks/README.md`, "The board's review"). Every art task now says so, T-009 and T-027 included. Until each asset's art task is done, the game uses placeholders.
- Documents touched: `tasks/README.md`
- Tasks: T-009, T-027 (review line added)

## 2026-10-10: Tasks without a board review merge on QA's pass
- Decision or change: a task that passes QA is marked done and merged straight away unless it asks for the board's review (every art task does). Feel and balance are judged in the board's playtest sessions. Recorded in `CLAUDE.md` (approved by the board) and `tasks/README.md`. Second wave started: T-036, T-040, T-033, T-035, T-080, T-056, T-082, T-054, T-015.
- Documents touched: `CLAUDE.md`, `tasks/README.md`
- Tasks: T-015, T-033, T-035, T-036, T-040, T-054, T-056, T-080, T-082

## 2026-10-10: Second wave: T-054, T-080, T-056 and T-040 merged
- Decision or change: merged on QA's pass under the new rule (no board review needed): T-054 (the main menu: title, Start, Garage, Exit), T-080 (combo numbers: x1 to a cap of x6; +0.05 per drift second, +0.25 per 360, +0.5 per alternate drift; a crash keeps 20% of the combo above x1; drains 0.5 per second after 2 s; up to 1.75 times the minion spawning), T-056 (garage numbers: 10 levels each; acceleration to 1.3 s to top speed, health to 200, damage to +50%; about 4,665 coins for everything) and T-040 (weapon numbers from the Unity report, with the board's three fixes). The numbers are judged in the playtest sessions. Known issue: three map-generator tests fail on master since the T-019 and T-021 merge (fix: T-087). Unblocked: T-039 (enemy numbers), T-059 (garage text).
- Documents touched: `docs/hud-and-menus.md`, `docs/game-loop-architecture.md`, `docs/garage-design.md`, `docs/weapons.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-054, T-080, T-056, T-040 (done); T-039, T-059 (unblocked)

## 2026-10-10: T-015, T-082 and T-036 done
- Decision or change: the board approved the combo text (T-082: LONG DRIFT!, FULL 360!, ALT DRIFT!, Combo x{multiplier}, +{amount}). Merged on QA's pass: T-015 (Escape pauses the game; the pause screen with the approved text and the camera zoom slider, saved between sessions) and T-036 (the run: the MVP map and the car, the 8-minute clock with boss time at 1:00 left, car health from the run data, coins, win and loss; the car starts in the centre of the map). The run is drawn isometric only. Unblocked: T-037 (likes and levels) and others; T-016 stays blocked until the board describes the full pause menu. T-087 (the map-generator fix) started.
- Documents touched: `docs/game-loop-architecture.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-015, T-036, T-082 (done); T-037 and others (unblocked); T-087 (started)

## 2026-10-10: T-033 and T-035 done; meteor challenges avoid other challenges
- Decision or change: the board drove T-033 (car collisions) and approved it with the bounce strength of 0.25; the car staying pressed against a wall and a nose-on knockback being cancelled while W is held are fine (Drifting, Decisions). T-035 (challenges created during a run) merged on QA's pass. The board decided a meteor challenge must never land on another challenge's arrow corridor (Level design, Decisions); fix task T-088. Merged: T-033, T-035.
- Documents touched: `docs/drifting.md`, `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-033, T-035 (done); T-088 (new)

## 2026-10-10: Building in playable steps
- Decision or change: the board wants the smallest playable version first, then to build on it, one playtest at a time. The steps toward the MVP: (1) bare loop: main menu, Start, the run on the map with the timer, pause, back to the menu; (2) trick popups, to check and tune the tricks; (3) the likes bar and level going up, with no level-up screen yet; (4) the combo stacking on likes, and challenges giving likes with a popup from the car; (5) minions, then weapons, then the kaiju, garage, sound and art. Recorded in `tasks/README.md`, "Building in playable steps". Tickets reshaped for it: T-055 no longer waits for the garage screen (the Garage button is wired later in T-089); the HUD is split so the timer comes first (T-090) and the rest follows (T-049); trick popups with names come first (T-091), the combo counter and amounts later (T-083); a level-up only raises the level until the level-up screen exists (T-037, with a switch T-052 turns on); a challenge's likes pop out from the car (T-092; HUD and menus, Decisions). Wave 3 started: T-055, T-090, T-079.
- Documents touched: `tasks/README.md`, `docs/hud-and-menus.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-037, T-049, T-052, T-055, T-083, T-084 (updated); T-089 to T-092 (new); T-055, T-079, T-090 (started)

## 2026-10-10: T-055 merge repaired; trick detection ready to try
- Decision or change: the first T-055 merge had failed silently, so master marked it done without its code (575d755); the code is now merged (e0eb101) and the game opens on the main menu. The Project Lead now checks each merge succeeded before marking a task done. T-079 (trick detection) passed QA and waits for the board's playtest; master was merged into its branch for that. Drifting's description of the tuning panel's reset now says it restores the game's values, not the Unity ones.
- Documents touched: `docs/drifting.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-055, T-079

## 2026-10-10: T-090 done; Playtest 1 ready
- Decision or change: T-090 (the HUD's run timer) merged on QA's pass. With T-055, the bare loop is playable from the main folder: the main menu, Start, the run on the MVP map with the timer counting down from 8:00, Escape to pause, back to the menu when the run ends.
- Documents touched: `docs/hud-and-menus.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-090 (done)

## 2026-10-11: Playtest 1 feedback: bigger map, zoom slider
- Decision or change: after playing the bare loop, the board found the map far too small. The MVP map becomes 240 by 240 units: the same 8-unit roads, 10 by 10 blocks, boulders and challenges, with many more blocks (about 13 each way) and a proportionally bigger gravel centre (Level design, Decisions). The pause screen's zoom label becomes "Camera zoom level" (the board's wording), and the zoom must visibly change while the slider moves. Rework tasks: T-093 (pause screen) and T-094 (the map). Short GDD updated.
- Documents touched: `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/short-gdd.md`, `docs/short-gdd/short-gdd.pdf`, `docs/short-gdd/README.md`
- Tasks: T-093, T-094 (new); T-047 (board note)

## 2026-10-11: Combined playtest ready
- Decision or change: merged on QA's pass: T-093 (pause screen: "Camera zoom level", the zoom changes live while paused, the timer no longer overlaps "Paused"), T-091 (trick popups from the car in pink and cyan, no red) and T-094 (the MVP map at 242 by 242: 13 by 13 blocks, an 82 by 82 gravel centre, 80 pattern copies, 24 challenges). With T-079 (trick detection) already merged, the board's combined playtest is ready from the main folder.
- Documents touched: `docs/level-design.md`, `docs/hud-and-menus.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-091, T-093, T-094 (done)

## 2026-10-11: Combined playtest feedback: everything three times bigger, compact pause strip
- Decision or change: after the combined playtest the board wants the whole city three times bigger, not just more small blocks: the MVP map is 240 by 240 with a 24-unit perimeter road, a 4 by 4 grid of 30 by 30 blocks, 24-unit roads and an 84 by 84 gravel centre; the boulders and challenges stay sized to the car (board's answers). Roads are now 24 units wide, replacing "5 to 10 times the car's width" (Level design, Decisions). The pause screen's strip covers the top half of the screen and must be compact. Rework tasks T-095 (pause strip) and T-096 (the map). Short GDD updated.
- Documents touched: `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/short-gdd.md`, `docs/short-gdd/short-gdd.pdf`, `docs/short-gdd/README.md`
- Tasks: T-095, T-096 (new)

## 2026-10-11: Second playtest build ready
- Decision or change: merged on QA's pass: T-095 (a compact pause strip below the timer) and T-096 (the MVP map with everything three times bigger: 240 by 240, 4 by 4 blocks of 30 by 30, 24-unit roads, an 84 by 84 gravel centre; the fitted challenges are now the board's sketches exactly, moved into place; 60 pattern copies, 18 challenges). The board's next playtest is ready from the main folder.
- Documents touched: `docs/hud-and-menus.md`, `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-095, T-096 (done)

## 2026-10-11: Second playtest: approved
- Decision or change: the board played the build with the three-times-bigger map, the compact pause strip, the live zoom and the trick popups, and called it perfect. Next step in "Building in playable steps": likes and levels.
- Documents touched: none
- Tasks: T-091, T-093, T-094, T-095, T-096 (played)

## 2026-10-11: T-037 done: likes and levels
- Decision or change: T-037 merged on QA's pass. The run now counts likes (XP) from completed challenges (meteor challenges included) and from drifts longer than a second (whole seconds only, so 3.5 seconds gives 3 seconds' worth), with levels and their thresholds from `run.json`. The level-up pause is built but switched off until the weapon choice screen (T-052); T-052 now also says Escape must not resume the run during a level-up choice.
- Documents touched: `docs/game-loop-architecture.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-037 (done), T-052 (note added)

## 2026-10-11: T-092 done: challenge popup
- Decision or change: T-092 merged on QA's pass. A completed challenge shows "Trending! +{likes} Likes" rising from the car, with the likes it gave. The work was paused at the board's request and resumed the same day.
- Documents touched: `docs/hud-and-menus.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-092 (done)

## 2026-10-11: T-049 done: HUD likes bar, health and coins
- Decision or change: T-049 merged on QA's pass. The HUD now shows "Car Health" with a health bar (top left), the likes row (a placeholder heart in Redgull red, "Likes", "Hype Lv {level}") with the likes bar under it, and "Coins" with the count (top right), around the timer. Space is kept beside the likes row for the combo counter (T-083). T-086 (the heart's art) is unblocked.
- Documents touched: `docs/hud-and-menus.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-049 (done), T-086 (unblocked)

## 2026-10-11: T-081 done: the combo
- Decision or change: T-081 merged on QA's pass. The run keeps a combo multiplier from 1.0: tricks raise it by `combo.json`'s amounts up to the cap, it drains to 1.0 after 2 seconds without a trick, a collision or damage cuts 80% of the part above 1.0, and it multiplies all likes. Two readings for the board's playtest: a hit does not restart the 2-second wait, and the first drift second already earns 1.05 times its likes, because the extended-drift trick fires just before it. T-083 (the HUD combo counter) is unblocked.
- Documents touched: `docs/game-loop-architecture.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-081 (done), T-083 (unblocked)

## 2026-10-11: T-083 done; likes and combo playtest ready
- Decision or change: T-083 merged on QA's pass. The HUD shows "Combo x{multiplier}" to the right of the likes row, and each trick popup shows the combo it added ("LONG DRIFT! +0.05", "FULL 360! +0.25", "ALT DRIFT! +0.5"; the name only at the cap). With T-049, T-081 and T-092, the likes and combo step of "Building in playable steps" is playable from the main folder. QA noted that while paused, the pause strip covers the lower half of the likes row, the likes bar and the combo counter; left for the board's playtest.
- Documents touched: `docs/hud-and-menus.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-083 (done)

## 2026-10-11: Likes and combo playtest: challenges left out of the MVP; the kaiju is always vulnerable
- Decision or change: the board played the likes and combo build: everything works well except the challenges. The board leaves challenges out of the MVP and might bring them back later: the map loses its arrows, and the pattern copies stay as plain boulder obstacles, so likes come from drifting only (times the combo). The kaiju's meteors leave plain boulders instead of challenges, and the kaiju can be damaged at any time: no shield, no vulnerability windows (board's answers). The challenge decisions stay in Level design, marked as applying only if challenges come back. Tickets that exist only for challenges move to the final-release milestone (board's answer): T-066, T-067, T-088; the challenge parts of T-050, T-069 and T-074 are split into T-098 (HUD arrow), T-099 (the kaiju's shield art) and T-100 (the challenge completed effect), also final-release. T-045, T-046, T-039, T-063 and T-078 are reworded to match. New task T-097 takes the challenges off the map and adds meteor boulders. Short GDD updated.
- Documents touched: `docs/level-design.md`, `docs/game-loop-architecture.md`, `docs/enemies.md`, `docs/hud-and-menus.md`, `docs/visual-style.md`, `docs/extended-narrative.md`, `docs/long-gdd.md`, `docs/short-gdd/short-gdd.md`, `docs/short-gdd/short-gdd.pdf`, `docs/short-gdd/README.md`
- Tasks: T-097, T-098, T-099, T-100 (new); T-039, T-045, T-046, T-050, T-063, T-066, T-067, T-069, T-074, T-078, T-088 (changed)

## 2026-10-11: T-097 done: the MVP map without challenges
- Decision or change: T-097 merged on QA's pass. The MVP map has no challenge arrows and no challenges; all 60 pattern copies and their 96 boulders stay where they were, as plain obstacles. The challenge code, data and tests are kept, switched off by one setting in the map script (`CHALLENGES_ENABLED`; how to turn them back on is in `game/README.md`). The map can now place a meteor boulder during a run, with a placement check, for the kaiju's attack (T-046).
- Documents touched: `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-097 (done)

## 2026-10-12: The first car sprite; the car's stripes
- Decision or change: the board wants to start on the car art with one sprite only: the car on the screen diagonal from top-right to bottom-left, front at the bottom-left. The board described the car: like a 1967 Ford Mustang GT, dark green as the main colour, two white stripes down its length, centred as much as possible with a gap between them (Visual style, Decisions; no real badges, as before). T-014 is scoped down to that one sprite, not yet put into the game; the other 15 directions and the swap-in move to new task T-101, which waits for the board's review. T-026 and T-027 now wait for T-101.
- Documents touched: `docs/visual-style.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-014 (rescoped, started), T-101 (new), T-026, T-027 (depend on T-101)

## 2026-10-12: The first car sprite approved; generated art is archived, never deleted
- Decision or change: after trying to remove the first car sprite's shadow (a script edit, two PixelLab inpaint calls, one of which timed out but was charged, and a fresh generation with "no shadow" in the prompt, which still drew a shadow and a different car), the board approved the original sprite, shadow included. New rule (Visual style, Decisions): every generated asset is kept; only clean, game-ready art lives under `game/art/`, and every other generation is archived with its record in `art-archive/`, one folder per task. T-014's other versions and T-003's test-run art move there. Balance: 4,996 of 5,000 generations.
- Documents touched: `docs/visual-style.md`, `tasks/README.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-014 (approved; archiving the other versions)

## 2026-10-12: T-014 done; car art next, then map tiles, enemies later
- Decision or change: T-014 merged after the board's review and QA round 2: the approved car sprite (`game/art/car/car_sw_front.png`, front to the bottom-left, shadow included) is in master, not yet in the game; the other versions and T-003's test art are in `art-archive/`. The board set the next steps: the car's other 15 directions, put into the game for a playtest (T-101, started), then generating map tile art. Enemies come much later ("Building in playable steps", `tasks/README.md`).
- Documents touched: `tasks/README.md`, `game/README.md`
- Tasks: T-014 (done), T-101 (started)

## 2026-10-12: T-101 done: the car in 16 directions; 32 directions later
- Decision or change: the board played the final car in a run and really likes its look; T-101 merged as is (16 directions from the approved sprite, 10 generations; raw generations in `art-archive/T-101/`). The board wants 32 directions at some point (Visual style, Decisions): new task T-102, final-release milestone, not scheduled. T-027 stays blocked (it also waits for the minion's and kaiju's art). Next: the map tiles.
- Documents touched: `docs/visual-style.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`, `art-archive/README.md`
- Tasks: T-101 (done), T-102 (new), T-026 (unblocked)

## 2026-10-12: The ground's look; the first road tile
- Decision or change: the board described the ground (Visual style, Decisions): white lane lines, zebra crossings at the junctions, pavements along the building blocks, light cracks. How wide the pavements are and whether the car drives on them is a new open question (Level design). As with the car, T-063 is scoped down to one asphalt road tile for the board's review, not yet in the map; the full ground set and the swap-in move to new task T-103.
- Documents touched: `docs/visual-style.md`, `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-063 (rescoped, started), T-103 (new)

## 2026-10-12: The road tile approved; no pavements in the MVP
- Decision or change: the board edited the white line of the script-fixed road tile by hand (removing the "+" marks at the tile joins) and approved it as the road tile (T-063). Pavements move after the MVP (Visual style, Decisions; Level design, Open questions): the roads meet the building blocks directly. T-103 (the full ground set) updated to match.
- Documents touched: `docs/visual-style.md`, `docs/level-design.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-063 (approved), T-103 (changed)

## 2026-10-12: T-063 done: the road tile
- Decision or change: T-063 merged after the board's approval and QA: the board's hand-edited road tile (`game/art/ground/road_tile.png`, 2 by 2 units, white dashed line, light cracks) is in master, not yet in the map. The other tiles, the script fix and the mock-ups are in `art-archive/T-063/`. T-103 (the rest of the ground, put into the map) is unblocked and waits for the board's go, since it needs PixelLab generations.
- Documents touched: `game/README.md`, `art-archive/README.md`
- Tasks: T-063 (done), T-103 (unblocked)

## 2026-10-12: T-103 done: the ground in the map
- Decision or change: the board played a run with the full ground set and approved it ("it looks great"); T-103 merged. The MVP map's isometric view now shows the final ground: asphalt roads built from the approved tile with mixed crack variants, centred white lines, zebra crossings at every junction, the edge road and the gravel centre. One PixelLab call (15 generations; balance 4,956); everything else made by script. Raw tiles in `art-archive/T-103/`. A usage limit cut off the first agent after its PixelLab call; a second agent finished from the saved images without calling again. The buildings, boulders and the area outside the map are still placeholders. The task board page belongs to the previous account and could not be updated from this one.
- Documents touched: `game/README.md`, `art-archive/README.md`
- Tasks: T-103 (done)

## 2026-10-12: Course material folder
- Decision or change: the board asked for a place for course assignments, kept apart from the game: `course-material/`, one folder per assignment. The first, `asset-pipeline/`, is a short readme for the board's tutor showing the asset pipeline, the board's workflow and examples of the board's feedback (the car's shadow, the hand-edited road line), linking to the real agents, task files, art and archive rather than copying them.
- Documents touched: `course-material/README.md`, `course-material/asset-pipeline/README.md`
- Tasks: none (documentation)

## 2026-10-12: Working with the board; Project Lead helpers in tools/
- Decision or change: so the board can run several Project Lead sessions without losing how they work together, the habits and rules from this session that lived only in the conversation are now in `WORKING-WITH-THE-BOARD.md`, loaded by `CLAUDE.md` with the same weight (board's approval). It covers talking to the board, showing work, art and spending, building in playable steps, merging, several Project Leads at once, course work and the environment, including that the task board page belongs to the board's first account. The Project Lead's merge helpers, until now in a temporary session folder, moved into `tools/` with tests: `finish_task.py` and `update_short_gdd_fingerprint.py`.
- Documents touched: `CLAUDE.md`, `WORKING-WITH-THE-BOARD.md`
- Tasks: none (documentation and Project Lead tooling)

## 2026-10-12: The local task board replaces the claude.ai page
- Decision or change: the board had another session build a local task board and approved merging it. It runs at http://localhost:8765 (`tools/taskboard/server.py`), reads the task files and open task branches directly, and starts with each session through a hook. Every status change goes through `tools/task_status.py`, which enforces the workflow in `tasks/README.md`; hooks (`.claude/hooks/board_gate.py`) refuse hand edits to status lines and hand the Project Lead the board's drags to act on. The board applied the patch itself, since installing hooks into the Project Lead's settings was blocked by the permission check. `tools/finish_task.py` is retired; `taskboard_sync.py` lost `export` and `apply`, which only served the old page (the page is retired; its link stays here and in T-032 as history). Tasks that waited on board decisions now depend on board tickets so the auto-unblock can't reopen them: T-104 (pause menu, for T-016), T-105 (cruise boost, for T-009), T-106 (run recap, for T-017, which also waits on T-078); T-027 now depends on the minion and kaiju art (T-068, T-069). Leftover work: T-107 (the board deletes the three old claude.ai pages), T-108 (remove the leftover T-103 folder), T-109 (the board decides whether the status script commits its changes). `WORKING-WITH-THE-BOARD.md` updated. The `local-board` and `board-gate` branches are deleted.
- Documents touched: `CLAUDE.md`, `WORKING-WITH-THE-BOARD.md`, `docs/README.md`, `tasks/README.md`, `agent-notes/project-lead.md`
- Tasks: T-104, T-105, T-106, T-107, T-108, T-109 (new); T-009, T-016, T-017, T-027 (depends_on)

## 2026-10-13: T-110 done: the task board stops opening terminal windows
- Decision or change: the board found a terminal window popping up every 2 seconds and taking the focus while the task board page was open. Cause: the server, started by the session hook without a console, ran `git worktree list` on every refresh, and Windows gave each `git` run a new console window. The server now runs `git` with Windows' no-window flag, and a test guards it. The board checked it ("LGTM") and T-110 is merged.
- Documents touched: none (tooling)
- Tasks: T-110 (new, done)

## 2026-10-13: T-111 done: Planning column, reorderable columns and filters on the task board
- Decision or change: the board asked for a Planning column between To do and In progress: when it mentions a ticket, it drags it there and refines it with the Project Lead until its open questions are answered. New status `planning` (optional): `open` or `blocked` to `planning`; `planning` to `in-progress` only when its dependencies are done, or back to `open` or `blocked`, or cancelled; `in-progress` back to `planning`. The hook tells the Project Lead to bring a planning ticket's open questions to the board. The board then widened the same ticket: the columns can be put in any order by dragging their headers, and the board can be filtered by Ready, Can start?, Waiting and each status, several at once. Both are remembered in the board's browser. Passed QA round 2; the board approved it ("board looks great") and asked for the task board work in one commit, so T-111 is squash-merged.
- Documents touched: `tasks/README.md`, `tasks/_TEMPLATE.md`, `docs/README.md`, `WORKING-WITH-THE-BOARD.md`
- Tasks: T-111 (new, done)

## 2026-10-13: Working with the board moves into docs/
- Decision or change: the board asked to move the working-with-the-board document out of the repo root. It is now `docs/working-with-the-board.md`, still loaded by `CLAUDE.md` with the same weight, and listed in `docs/README.md`. Earlier timeline entries and finished tickets keep the old name as history.
- Documents touched: `docs/working-with-the-board.md` (moved from `WORKING-WITH-THE-BOARD.md`), `CLAUDE.md`, `docs/README.md`
- Tasks: T-108 (files to read first)

## 2026-10-13: T-108 done: the leftover T-103 folder is removed
- Decision or change: on the board's go, the leftover folder `C:\solid-carbide-worktrees\T-103` is removed and git's worktree list pruned. It held only older copies of files in master, plus 12 git-ignored screenshots from T-103's work and QA, which were copied into master's `screenshots/` first. The board keeps the two "Ready" counts as they are (the overview leaves out the board's own tickets, the Ready filter includes them), and pushes master to GitHub itself.
- Documents touched: none
- Tasks: T-108 (done)

## 2026-10-13: T-026 refined in Planning; a watcher for the board's drags
- Decision or change: the board dragged T-026 (the car image in the README) into the new Planning column and settled its open questions: the first approved sprite (front to the bottom-left), shadow kept, scaled exactly 2 times to 256 by 256, reviewed in VS Code's Markdown preview plus a screenshot. T-026 started (Asset Generation, no PixelLab calls). The board's drag only reached the Project Lead with the board's next message, so on the board's go the Project Lead now keeps a watcher on the board's moves during a session and replies to a drag straight away (Working with the board, "The task board").
- Documents touched: `docs/working-with-the-board.md`
- Tasks: T-026 (planning, then in progress)

## 2026-10-13: T-026 done: the car at the top right of the README
- Decision or change: the board marked T-026 done on the task board after reviewing it. The root README now opens with the final car (the first approved sprite, front to the bottom-left, shadow kept) at the top right, scaled exactly 2 times to 256 by 256 (`docs/readme/car.png`, record in `docs/readme/car.md`, made by `tools/make_readme_car.py` with a test). No PixelLab calls. The review screenshot stays out of the repo, in the git-ignored `screenshots/`.
- Documents touched: `README.md`
- Tasks: T-026 (done)

## 2026-10-13: Level-up effect: pixel particles from the car, drawn without PixelLab
- Decision or change: the board dragged T-074 (the level-up effect art) into Planning. No placeholder effect existed to swap art into, so on the board's go a Game Loop task (T-112) builds the effect first: on a level-up the car gives off a burst of particles, with plain placeholder squares. The board wants the car to give off pixel-art particles and judged that this needs no PixelLab: T-074 now draws the particle sprites with a script and swaps them into T-112's effect. T-112 gets no playtest of its own; the board playtests once T-074's particles are in.
- Documents touched: `docs/visual-style.md`
- Tasks: T-112 (new), T-074 (rewritten, depends on T-112)

## 2026-10-13: T-112 done: the car gives off a burst of particles on a level-up
- Decision or change: on every level-up (T-037's "level up" signal) the car gives off one burst of 32 plain 4 by 4 pixel squares in pale cyan, which move with the car, shrink rather than fade, last 0.7 seconds and keep playing while the run is paused. Several level-ups at once give one burst. The look and tuning live in `game/scenes/run/level_up_burst.tscn`, so T-074 swaps in the final particles there. Passed QA round 1; no playtest of its own (the board playtests T-074). T-074 is unblocked.
- Documents touched: `docs/game-loop-architecture.md`, `game/README.md`
- Tasks: T-112 (done), T-074 (open)

## 2026-10-13: T-074 done: the level-up particles are in
- Decision or change: the board playtested T-074 and approved it ("LGTM"). On a level-up the car now gives off a burst of 40 script-drawn neon particles: cyan and pink stars, pink and cyan diamonds, a violet pixel cross and a small cyan spark, each with a white-hot core and darker halo pixels, no red, no semi-transparent pixels. They shrink to half size and then pop out, with no fade. No PixelLab calls. The violet cross, flagged as the weakest shape, is kept as is. Made by `game/tools/build_level_up_particles.py` (with a check command and tests). Passed QA round 1. Marking T-074 done made T-100 (challenge completed effect, after the MVP) open.
- Documents touched: `docs/visual-style.md`, `game/README.md`
- Tasks: T-074 (done), T-100 (open, after the MVP)

## 2026-10-13: Health and likes bars stand upright at the top left
- Decision or change: the board wants the car's health bar and the likes bar vertical, at the top left of the screen. Open details settled by the Project Lead, as the board asked: both bars fill from the bottom up, side by side (health on the far left, likes to its right), each with its already-approved label under it (no new text), the combo counter stays next to the likes bar, the look stays a placeholder, and the UI Agent proposes the sizes. T-113 (UI) builds it; the board playtests it.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-113 (new)

## 2026-10-13: T-113 sent back after the board's playtest; nothing user-facing merges unplayed
- Decision or change: the board playtested T-113 (both bars upright at the top left) and rejected it: the text placing was poor. It wants to try the likes bar horizontal, centred at the bottom of the screen, with the heart, "Likes" and the level in one row above it and the combo counter above that; the health bar stays upright at the top left with "Car Health" above it. T-113 is reworked on its branch (not merged) and runs on opus. The board also set a rule: nothing user-facing merges before it has played it, placeholders included. Thirteen open or blocked tickets that change what the player sees or reads got a `The board's review:` line. For later, not scheduled: when the player isn't doing tricks, the likes bar slowly drains, but never below the start of the current level.
- Documents touched: `docs/hud-and-menus.md`, `docs/working-with-the-board.md`, `docs/game-loop-architecture.md`
- Tasks: T-113 (back to in progress), T-008, T-016, T-017, T-041, T-042, T-044, T-045, T-046, T-050, T-052, T-058, T-067, T-098 (review line added)

## 2026-10-13: Likes drain in the MVP, starting when the combo has drained
- Decision or change: the board put the likes drain in the MVP and decided it starts once the combo has fully drained; any trick stops it, and it never takes the bar below the start of the current level. T-114 (Game Data) proposes the speed; T-115 (Game Loop) builds it and goes to the board's playtest.
- Documents touched: `docs/game-loop-architecture.md`
- Tasks: T-114 (new), T-115 (new, depends on T-114)

## 2026-10-13: T-114 done: the likes drain numbers
- Decision or change: `game/data/run.json` has a `likes_drain` block, read through `run_data.gd`: on, 2% of the current level's bar per second (a full bar empties in 50 seconds; 2 likes a second at level 1, against 10 for a second of drifting), no extra wait after the combo has drained. A share of the bar rather than a flat amount, so it feels equally slow at every level. Proposed numbers; the board judges them in T-115's playtest (at level 11 the drain is 18.6 likes a second; halving the share is a one-number change). Passed QA round 1; data only, so merged straight away. T-115 is unblocked.
- Documents touched: `game/README.md`
- Tasks: T-114 (done), T-115 (open)

## 2026-10-13: The combo counter hides when there is no combo
- Decision or change: the board wants the combo counter hidden at x1.0 (no combo); it shows as soon as a trick raises the multiplier. T-116 (UI) builds it on top of T-113's branch, so the board playtests the new HUD layout and this change together; T-113 merges first. T-115 (the likes drain) started.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-116 (new), T-115 (in progress)

## 2026-10-13: T-113, T-116 and T-115 done: the new HUD layout, the hidden combo counter and the likes drain
- Decision or change: the board playtested all three and approved them ("all LGTM"). The health bar stands upright at the top left with "Car Health" above it; the likes bar runs horizontally along the bottom centre, with the heart, "Likes" and "Hype Lv" in one row above it (T-113, after its first layout was rejected). The combo counter sits above that row and is hidden at no combo (T-116). Once the combo has drained, the likes bar empties at 2% of the bar a second, never below the start of the level; a trick stops it, and it does not run while paused, while a weapon choice waits, after the run, or at the top level (T-115). Open points the board left as they are: the pause strip's band over the health bar, the HUD text size at 1920x1080, and the likes bar moving in whole likes. All tests pass on master after the three merges (361 GUT, 125 and 115 Python).
- Documents touched: `docs/hud-and-menus.md`, `docs/game-loop-architecture.md`, `game/README.md`
- Tasks: T-113 (done), T-116 (done), T-115 (done)

## 2026-10-13: Drift marks
- Decision or change: the board wants drift marks. While the car drifts, its two rear tyres leave dark marks on the ground; each stays about 6 seconds, then fades out as a whole. Details settled by the Project Lead: marks only during the car's own drift state, one per rear tyre, drawn over the ground and under everything else, capped in number; the texture drawn by script (no PixelLab), as with the level-up particles. T-117 (Driving & Drift) builds them with a placeholder line; T-118 (Asset Generation) draws the texture on top of T-117's branch, and the board playtests both together. T-073 keeps only the drift smoke.
- Documents touched: `docs/visual-style.md`
- Tasks: T-117 (new), T-118 (new, depends on T-117), T-073 (narrowed to drift smoke)

## 2026-10-13: T-117 and T-118 done: drift marks
- Decision or change: the board playtested the drift marks and approved them ("LGTM"). While the car drifts, each rear tyre leaves a mark under it, with a script-drawn tyre texture (an 8 by 8 tile, three dark rubber colours, a chevron tread, ragged edges; no PixelLab). Each mark stays 6 seconds, fades out over 1 second as a whole and is removed, with a cap of 800 pieces. The marks are drawn on the ground, under the buildings, boulders, car and HUD, in the run and the drift prototype. All tests pass on master after both merges (383 GUT, 141 and 115 Python).
- Documents touched: `game/README.md`
- Tasks: T-117 (done), T-118 (done)

## 2026-10-13: Next wave: see-through buildings, enemy numbers, a boulder sample
- Decision or change: the board agreed the next wave: T-034 (buildings turn see-through when the car is behind them) and T-039 (enemy numbers, data only) start now, and T-065 (crashed meteor boulders) gets the PixelLab go for one sample boulder, which the board reviews before the rest are made. Old test logs left in the worktrees folder were deleted on the board's go.
- Documents touched: none
- Tasks: T-034, T-039, T-065 (in progress)

## 2026-10-13: T-039 done: enemy numbers
- Decision or change: `game/data/enemies.json` (read through `enemy_data.gd`) holds the proposed enemy numbers: minion health 4, speed 6, contact damage 5 every 0.5 s; 12 minions at the start rising to 20 at 7:00; 60% drop chance of 2 coins; kaiju health 500 (about 48.5 s to kill for an average level-8 run); 3 meteors every 8 s. Passed QA round 1; data only, so merged. Flagged for the board: the kaiju drops no coins (Game loop architecture says enemies drop coins), meteors aim within 10 units of the car, minions are replaced as they die, and the count holds during the kaiju's minute. T-044 (minions) is unblocked.
- Documents touched: `docs/enemies.md`, `game/README.md`
- Tasks: T-039 (done), T-044 (open)

## 2026-10-13: The kaiju drops a few coins; one more boulder call
- Decision or change: the board decided the kaiju always drops a few coins when defeated (T-039 had proposed none). Its death ends the run at once, so the Project Lead settled that its coins are added to the run's coins as the run ends, without being picked up. T-119 (Game Data) adds the number; T-045 (the kaiju) depends on it and adds the coins before the run ends. The board also gave the go for one more PixelLab call on T-065, to fix the sample boulder's shape (a tall egg on a pedestal): a low, wide, jagged rock lying on the ground with no base.
- Documents touched: `docs/enemies.md`
- Tasks: T-119 (new), T-045 (depends on T-119), T-065 (one more call)

## 2026-10-13: T-119 done: the kaiju drops 10 coins
- Decision or change: `game/data/enemies.json` gives the kaiju a 100% drop of 10 coins (five minion drops, about 4% of a run's roughly 250 coins), read through `EnemyData.kaiju_coins_on_defeat()`. The kaiju task (T-045) adds them to the run's coins before the run ends. Passed QA round 1; data only, so merged. The board can raise it if winning should matter more for the coin economy.
- Documents touched: `game/README.md`
- Tasks: T-119 (done)

## 2026-10-13: T-034 done: buildings turn see-through when the car is behind them
- Decision or change: the board playtested T-034 and approved it ("see-through buildings work amazing"). The placeholder buildings now rise 15 units in the isometric view (a placeholder height; the final art, T-064, can set its own) and are drawn in depth order with the car. A building covering the car fades to 15% over 0.15 s and fades back when the car comes out; only the car triggers it. The drift marks stay between the ground and the buildings. Passed QA round 1. T-064 (the building art) is now open; minions (T-044) need a place in the same depth order.
- Documents touched: `docs/level-design.md`, `game/README.md`
- Tasks: T-034 (done), T-064 (open)

## 2026-10-13: Boulder art: two approved samples
- Decision or change: the board reviewed the boulder samples and approved two as the boulder variants: the first PixelLab sample with its stone disc removed by a free script, and the second, lower, boxy PixelLab sample. 2 generations were used in all (balance 4954 of 5000). T-065 now puts both into the game (no more PixelLab calls), sized to the 3-unit collision circle, for the board's playtest. The T-034 folder was deleted once Godot was closed.
- Documents touched: none
- Tasks: T-065 (in progress)

## 2026-10-13: Starting the building art and the comic look of the trick popups
- Decision or change: the board asked to start the Tokyo-style buildings for the city blocks (T-064) and the pixel-art comic-book look of the trick popups (T-084). Both start with a plan only, no PixelLab calls: a block is 30 by 30 units (about 1200 pixels across at 40 pixels per unit), far bigger than one PixelLab image, so the Asset Generation Agent first proposes how to fill a block, the variants and the cost; for the popups it proposes script-drawn bursts versus generated ones, and a licensed pixel font. The board then gives the go for one sample of each.
- Documents touched: none
- Tasks: T-064, T-084 (in progress, planning first)

## 2026-10-13: The likes drain four times faster
- Decision or change: the board wants the likes drain quadrupled: 8% of the current level's bar a second instead of 2% (a full bar empties in 12.5 s; 8 likes a second at level 1). Only the number changes. T-120 (Game Data) changes it and its tests; data only, so it merges after QA, and the board feels it in the next playtest.
- Documents touched: none
- Tasks: T-120 (new)

## 2026-10-13: Drift smoke
- Decision or change: the board wants the drift smoke started, with no sample review: it goes straight to the board's playtest. As with the drift marks, T-121 (Driving & Drift) builds the smoke with a placeholder, and T-073 (Asset Generation, rewritten) draws the smoke sprites by script (no PixelLab) on top of T-121's branch. Details settled by the Project Lead: puffs from both rear tyres only while drifting, left in the world, growing then shrinking or breaking up, capped in number, in the map's depth order.
- Documents touched: `docs/visual-style.md`
- Tasks: T-121 (new), T-073 (rewritten: script-drawn smoke, built on T-121)

## 2026-10-13: T-120 done: the likes drain four times faster
- Decision or change: `likes_drain.bar_share_per_second` in `game/data/run.json` is now 0.08, the board's value: a full bar empties in 12.5 s, 8 likes a second at level 1. Tests pin the new speed; T-115's drain tests are unchanged and pass. Passed QA round 1; a number the board set itself, so merged after QA as agreed, and the board feels it in its next playtest.
- Documents touched: `game/README.md`, `docs/game-loop-architecture.md` (wording, earlier the same day)
- Tasks: T-120 (done)

## 2026-10-13: T-122 done: agents run on their task's model, enforced
- Decision or change: the board found agents had been started on Opus although their task files said Sonnet (an agent started without a model runs on the Project Lead's model). On the board's request, the hooks now enforce `tasks/README.md`, "Models": an agent whose prompt names a task starts only when the Agent call passes that task's model; the QA/Integration Agent needs sonnet, or opus when the task has a board's review line. The agents already running were left to finish on Opus, on the board's say-so. Passed QA round 1; tooling, so merged.
- Documents touched: `tasks/README.md`
- Tasks: T-122 (done)

## 2026-10-13: The trick popups become black-and-white comic popups
- Decision or change: after playtesting T-084's neon comic popups, the board wants them to look like real comic book popups: a white bubble with a black border and black letters, in a heavy, slanted comic font like its reference image (Bangers already is that style and stays), with the letters on one straight baseline. T-084 goes back to the Asset Generation Agent.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-084 (back to in progress)

## 2026-10-13: Drift smoke shorter
- Decision or change: after playtesting the drift smoke (T-121 and T-073), the board wants each puff to last much less: in a full-circle drift the trail should cover about 20 degrees of the circle instead of about half. T-073 goes back to the Asset Generation Agent to cut the puffs' lifetime to about a ninth.
- Documents touched: none
- Tasks: T-073 (back to in progress)

## 2026-10-13: Camera options: smoothing and the dynamic camera
- Decision or change: the board wants to try two camera options, each a checkbox on the pause screen, off by default and saved: camera smoothing, and the "dynamic camera", whose zoom follows the car's speed from a min (very low speed) to a max (top forward speed), easing there with a short delay. The board tunes the min and max in playtests with two temporary pause-screen buttons that store the zoom slider's current value; the values are written where the Project Lead can copy them into the defaults. The checkbox names are the board's own words ("Camera smoothing", "Dynamic camera"), and the tuning buttons ("Set min zoom", "Set max zoom") are a temporary tool for the board, removed once the values are settled, so no separate text task. T-123 (Driving & Drift) builds the camera behaviour; T-124 (UI) adds the controls on top of T-123's branch; the board playtests both together.
- Documents touched: `docs/drifting.md`, `docs/hud-and-menus.md`
- Tasks: T-123 (new), T-124 (new)

## 2026-10-13: T-065 done: the boulder art is in
- Decision or change: the board playtested the boulders and approved them ("LGTM"). The map's boulders (obstacle patterns, the kaiju's meteor boulders) now use the two approved PixelLab samples (the first with its stone disc removed by a free script, and the lower boxy one), plus a free mirrored copy of each, picked per boulder by a stable hash and sized to the 3-unit collision circle. Buildings and the car draw in the right order around them; collisions are unchanged. 2 generations used in all (balance 4954 of 5000 after T-065; T-064's sample took it to 4953). Passed QA round 1.
- Documents touched: `game/README.md`
- Tasks: T-065 (done)

## 2026-10-13: Trick popups follow the car
- Decision or change: playtesting the comic popups, the board found they stay where they appeared while the car drives on, so they are hard to read. Each popup now follows the car for its whole life. T-084 had used both QA rounds, so this is a follow-up, T-125 (UI), built on T-084's branch so the board playtests both together.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-125 (new)

## 2026-10-13: A Builds tab on the task board
- Decision or change: the board wants to jump from a ticket to that ticket's version of the game. It chose a launcher over an embedded web build (a browser page can't hold a native Godot window, and a web export would need the Compatibility renderer instead of Forward+). A new Builds tab lists `master` and every worktree, each with "Play" and "Open in editor" buttons that start Godot on that folder; ticket cards with a worktree get a Play button too. Embedding the game in the page stays a possible later step.
- Documents touched: none yet (T-126 updates `docs/README.md` and `docs/working-with-the-board.md`)
- Tasks: T-126 (new)

## 2026-10-14: T-121 and T-073 done: drift smoke
- Decision or change: the board playtested the drift smoke and approved it ("LGTM"). While the car drifts, puffs come off both rear tyres: a script-drawn cool grey-violet cloud puff (no PixelLab), each living 0.13 s, 50 a second, capped at 64, so in a full-circle drift the trail covers about 20 degrees (the board's request after the first version covered about half the circle). Puffs stay where they were left, grow then pop out, and sit in the car's depth order. Both passed QA (T-073 in two rounds).
- Documents touched: `game/README.md`, `docs/visual-style.md` (earlier)
- Tasks: T-121 (done), T-073 (done)

## 2026-10-14: Several Project Leads: each acts on its own tickets
- Decision or change: with two Project Lead sessions running, the board's drags on the task board reach both. Each session now acts only on moves for tickets it planned or started; a move on a ticket nobody owns yet goes to the session the board is talking to.
- Documents touched: `docs/working-with-the-board.md`
- Tasks: none

## 2026-10-14: Buildings: dense narrow towers, kanji-like signs kept; popups lower and smaller
- Decision or change: on T-064's sample tower, the board took the Project Lead's recommendations: blocks are packed densely with narrow towers (about 49 per block) instead of 16 wider ones, the remaining 7 base towers are generated the same narrow way (about 7 generations), and the signs' kanji-like marks are kept as long as they are not real words. Also, playtesting T-125, the board wants the stacked trick popups to go at most half way from the car to the top of the screen (they reached the timer) and to be a bit smaller; T-125 goes back to the UI Agent.
- Documents touched: `docs/visual-style.md`
- Tasks: T-064 (full set), T-125 (back to in progress)

## 2026-10-14: T-126 done: the Builds tab on the task board
- Decision or change: the task board has a Builds tab listing `master` and every worktree, each with "Play" (runs that version of the game) and "Open in editor" (opens it in Godot). A ticket's detail view has "Play this build" and a link to its Builds entry; they sit in the detail view rather than on the card because cards are dragged. The server only launches folders from its own worktree list, using `GODOT_BIN` from `.env`. Tooling, so merged straight after QA (passed round 1).
- Documents touched: `docs/README.md`, `docs/working-with-the-board.md`
- Tasks: T-126 (done)

## 2026-10-14: Named Project Lead sessions and ticket owners
- Decision or change: the board's drags reach only the first session whose hooks read the shared inbox, so the "each session acts on its own tickets" rule can't work yet. The board chose to name each session itself (for example "Camera", "Tools"; a session without a name asks). T-127 adds a `lead:` owner on each ticket, gives every session its own read position in the inbox so all sessions see every drag and act only on their own or unowned tickets (claiming an unowned one first), and shows the owner on each card with a filter by owner, so the board sees every session's tickets in one view.
- Documents touched: none yet (T-127 updates `tasks/README.md`, `tasks/_TEMPLATE.md`, `docs/README.md`, `docs/working-with-the-board.md`)
- Tasks: T-127 (new)

## 2026-10-14: Trick popups: three at most, eased rise
- Decision or change: before playtesting T-125's second round, the board decided the popups should be small enough that up to three stack at once under the height limit (never more; the oldest makes room), and that their rise should ease out: fast at first, slowing towards the end as they fade. T-125 is reworked; its status stays in QA meanwhile, since the status script won't move it out while its round-1 marks still pass.
- Documents touched: none yet (HUD and menus, Content, with the rework)
- Tasks: T-125

## 2026-10-14: Trick popups become rounded rectangles
- Decision or change: the board wants the comic popups to be white rounded rectangles instead of jagged bursts, keeping the black border and black lettering. Added to T-125's current rework.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-125

## 2026-10-14: Quick tuning with an agent, through the Project Lead
- Decision or change: the board can work directly with any agent, on whatever it wants to tune, in the Project Lead's session: the Project Lead resumes the agent that did the work and passes the board's tweaks on word for word, in the task's folder, with no QA between tweaks and one QA round before merging. Every tweak is still recorded in the ticket.
- Documents touched: `docs/working-with-the-board.md`
- Tasks: none

## 2026-10-14: Record: the board's go for T-064's sample tower
- Decision or change: recorded late (QA found the gap): on 2026-10-13 the board gave the go for T-064's one sample tower ("go and generate the sample building"), 1 generation. The full set of 7 more followed the board's go on 2026-10-14. Balance after all 8 calls: 4946 of 5000 (a later free query; the result notes said 4947 because of the API's lag).
- Documents touched: none
- Tasks: T-064

## 2026-10-14: Half speed kept; the city redesigned: skyscraper bases, short buildings, pavements, alert banners
- Decision or change: the board keeps the car's top forward speed halved (16.5 units a second, from its quick tuning on T-124). It redesigned the buildings: downtown Tokyo under attack from the kaiju (a Godzilla-like monster, not called Godzilla, name to come); each block split into 2 by 2 skyscrapers drawn as the bases of really tall towers so the car is realistic in size, 6 different skyscrapers; shorter buildings whose roofs show; a pavement drawn around every building asset; a few alert banners about the kaiju on buildings or as pavement signs, with silly minimalistic pixel paintings of its head or body. The Narrative Theme Agent is consulted first so all generated art stays consistent (T-128, started). T-064 is rewritten for the new design and waits in To do for the board to start it; its first round's art stays archived on its branch. New: T-129 (short buildings) and T-130 (alert banners), both after T-128.
- Documents touched: `docs/visual-style.md`, `docs/extended-narrative.md`, `docs/drifting.md`, `docs/level-design.md`
- Tasks: T-064 (redesigned, To do), T-128 (new, in progress), T-129 (new), T-130 (new)

## 2026-10-14: T-084 and T-125 done: the trick popups
- Decision or change: the board playtested the popups and approved them ("LGTM"). Trick and challenge popups are white rounded rectangles with a black border and black Bangers lettering (Bangers 2.100, SIL OFL 1.1, script-drawn, no PixelLab), on one straight baseline. Each follows the car for its whole life, rising with an ease-out (fast, then slowing) as it fades; at most three stack at once, the oldest making room, and the stack never reaches above a quarter of the screen from the top. QA noted the smallest lettering loses pixel rows at the default zoom; the board accepted it as is. Both passed QA in two rounds.
- Documents touched: `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-084 (done), T-125 (done)

## 2026-10-14: T-128 done: the city under attack, in the story
- Decision or change: Extended narrative, Content now describes downtown Tokyo at night in the middle of the kaiju's attack (the kaiju unnamed) and why the city put up alert banners. The Narrative Theme Agent's proposals wait for the board: picture-only banners (or with words such as "ALERT", "KAIJU ALERT", "STAY INSIDE"), larger banners on buildings and small standing signs on the pavement, light to medium damage, a lighter cooler grey pavement with a raised kerb, and no civilians shown for now; plus one art brief for T-064, T-129 and T-130 (in T-128's result notes). Docs only, passed QA round 1. T-129 is now open.
- Documents touched: `docs/extended-narrative.md`
- Tasks: T-128 (done), T-129 (open)

## 2026-10-14: T-123 and T-124 done: camera options, and half speed
- Decision or change: the board approved the camera options on the task board. The pause screen has two checkboxes, "Camera smoothing" (the camera trails the car a little) and "Dynamic camera" (the zoom follows the car's speed between a min and a max, easing there), both off by default and saved, plus temporary "Set min zoom" and "Set max zoom" buttons for the board to tune the dynamic camera (defaults 11 and 17). The car's top forward speed is halved (16.5 units a second), the board's quick-tuning experiment it kept. The branches had fallen behind master; a Driving & Drift Agent merged master into T-124 and resolved conflicts in the run and prototype scripts and game/README.md, keeping the drift smoke, drift marks, popups and the buildings' depth order (two agents before it were cut off). T-123 passed QA in one round, T-124 in two.
- Documents touched: `docs/drifting.md`, `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-123 (done), T-124 (done)

## 2026-10-15: The city brief settled; scale corrected to 32
- Decision or change: the board took the Narrative Theme Agent's recommendations (T-128): picture-only alert banners (silly minimal paintings of the kaiju's head or Godzilla-like body), the larger ones on buildings and small standing signs on the pavement, only a few on the map; light to medium damage (cracks, a few broken windows, a little rubble; no big fires or collapsed buildings); pavements a lighter, cooler grey with a raised kerb and light cracks; no civilians shown, only their signs. Written as the City brief in Visual style. Visual style's scale is corrected from "about 40" to the 32 art pixels per unit the game uses. The board keeps its current game settings (the dynamic camera on, zoom 11.6), so no reset and no ticket for the screenshot setup that saved them.
- Documents touched: `docs/visual-style.md`, `docs/extended-narrative.md`
- Tasks: T-064, T-129, T-130 (follow the City brief)

## 2026-10-15: The board starts the city art: T-064, T-129, T-130
- Decision or change: the board started the skyscrapers (T-064), the shorter buildings (T-129) and the alert banners (T-130). Each begins with a plan and its PixelLab cost for the board's go, no calls yet. T-130 no longer lists T-064 as a dependency (it will be built on T-064's branch instead), so it could start its plan.
- Documents touched: none
- Tasks: T-064, T-129, T-130 (in progress, planning first)

## 2026-10-15: City art plans approved
- Decision or change: the board approved the three plans. T-064 (skyscrapers): free flat PixelLab pieces (facade band, shopfront strip, vertical sign) slanted onto the walls by script at 32 px per unit, about 12-floor walls that dissolve at the top, script-drawn pavement; go for the 3-call sample (about 3 generations) after a free mock-up at the real zoom; only the tower covering the car fades, not its whole block (a small code change). T-130 (banners): drawn by script for free, 6 on the map, the drawings start now and placement waits for T-064. T-129 (shorter buildings, 14 generations planned) is held in Planning until the skyscraper sample is approved, since it reuses the same wall method.
- Documents touched: none yet (T-064 and T-130 update their docs with their work)
- Tasks: T-064, T-129 (planning), T-130

## 2026-10-15: Alert banners become road-style warning signs
- Decision or change: looking at T-130's first drawings (cheerful cyan and pink cartoon kaiju), the board wants no detail at all: only the kaiju's black silhouette (head or body shape), on a plain white inside with a red outline, like road warning or prohibition signs, and no neon colours. This is an exception to "red only for Redgull": the alert signs use a traffic-sign red outline. Visual style's City brief and Redgull's look are updated.
- Documents touched: `docs/visual-style.md`
- Tasks: T-130

## 2026-10-15: Skyscraper sample and warning signs approved
- Decision or change: the board played T-064's round-2 sample in the game (every block 2 by 2 of the one sample skyscraper with free variations, script pavement, the whole block fading for now) and approved it ("LGTM"); the full set waits for the board's go on its cost. The board also approved T-130's warning signs as drawn: the kaiju's head in a red warning triangle and its body in a red prohibition circle, black silhouettes on white, as building banners and pavement signs; placing them waits for T-064's full set.
- Documents touched: none
- Tasks: T-064, T-130

## 2026-10-15: City colours: apart from the alien boulders, less neon
- Decision or change: after playing the skyscraper sample, the board found it used nearly the same colours as the boulders. Its direction: the boulders are alien and must stand apart, so the city must not share their navy, purple and magenta glow; the city is less neon (concrete, glass, lit windows, small muted signs). Three script recolours were tried in the game (F7); the board asked for A (concrete and sodium light) and B (steel and glass) as two separate builds to judge, and will pick one. Recorded in Visual style as "City colours"; the City brief now points to it instead of the night neon pink and cyan.
- Documents touched: `docs/visual-style.md`
- Tasks: T-064, T-129

## 2026-10-15: City palette B, steel and glass
- Decision or change: the board played the two separate city builds and chose palette B, steel and glass: cool blue-grey walls, pale white and pale blue lit windows, small amber accents. Every city asset uses it (Visual style, "City colours"). The palette A build is removed; its recoloured art stays in T-064's branch history and goes to the archive with the full set.
- Documents touched: `docs/visual-style.md`
- Tasks: T-064, T-129

## 2026-10-15: Go for the full skyscraper set and the shorter buildings' sample
- Decision or change: the board gave the go for T-064's full set (5 more skyscrapers, about 15 generations, in palette B, with a free wall retune, signs that don't read as real Japanese, only the covering tower fading) and for T-129's sample (5 generations, palette B), each step coming back to the board.
- Documents touched: none
- Tasks: T-064, T-129

## 2026-10-15: PixelLab spend for the city so far
- Decision or change: T-064's full set (10 calls) and T-129's sample (5 calls) ran at the same time on the same account: balance 4943 before, 4928 after, 15 generations for 15 calls, 1 each. Each agent alone saw an unexplained gap; together they add up. T-064 drew its signs by script (abstract shapes, no glyphs), saving its 5 sign calls. City art spend so far: T-064 round 1 8, round 2 13 (3 sample + 10 full set), T-129 5.
- Documents touched: none
- Tasks: T-064, T-129

## 2026-10-15: T-064 done: the skyscrapers
- Decision or change: the board playtested the full skyscraper set and approved it ("looks great"). Every 30 by 30 block is 2 by 2 bases of very tall steel-and-glass towers in palette B (6 designs, each built from flat PixelLab facade and shopfront pieces slanted onto the walls by script at 32 px per unit, with a wall retune and script-drawn abstract signs with no letters), dissolving at the top, with a script-drawn pavement around each that never fades. Only the skyscraper covering the car fades. Collisions and the map layout are unchanged. PixelLab: round 1 (dense narrow towers, archived) 8 generations, round 2 13 (3 sample, 10 full set). QA's small leftovers (four unused palette-B sample images in game/art/buildings, a dead sort in mvp_map.gd, no test yet that a boulder behind a skyscraper is drawn under it) go to T-129, which builds on this work.
- Documents touched: `game/README.md`, `docs/visual-style.md` (earlier)
- Tasks: T-064 (done)

## 2026-10-15: Shorter buildings: sample approved, script signs, full set
- Decision or change: the board approved T-129's sample short building ("lgtm"), keeping its roof as it is, and asked for its shop signs to be redrawn by script as abstract shapes with no letters (like the skyscrapers'), then for the other 3 designs (about 9 generations, palette B), before it playtests again and merges. QA's small leftovers from T-064 are tidied in the same work.
- Documents touched: none
- Tasks: T-129

## 2026-10-15: T-129 done: shorter buildings with visible roofs
- Decision or change: the board playtested the shorter buildings and approved them ("LGTM"). About one slot per block holds a low building (about 4.3 units) with a flat roof carrying water tanks, air conditioners, signs, antennas and a little rubble, in palette B, with the script pavement. 4 designs, each with a mirrored look; shop signs drawn by script as abstract marks with no letters. Each short building fades on its own when it covers the car, with an outline that follows its roof (QA round 1 caught it fading when the car was only behind it; fixed). PixelLab: 14 generations (5 sample, 9 full set); balance 4919 of 5000. Left for later if the board wants: design B's darker right wall reads almost blank, B and C look alike from a distance, and neighbouring blocks can repeat a design.
- Documents touched: `game/README.md`
- Tasks: T-129 (done)

## 2026-10-15: T-130 done: the kaiju warning signs; the city redesign complete
- Decision or change: the board playtested the alert signs and approved them ("LGTM"). Six road-style warning signs, drawn by script (no PixelLab): the kaiju's head in a red warning triangle and its body in a red prohibition circle, black silhouettes on white, using the board's traffic-sign red exception. Four hang on skyscraper walls about 3 units up and fade with their tower; two stand on block-corner pavements and never fade; none on roads, no collisions. With T-064 and T-129 this completes the board's 2026-10-14 city redesign. QA noted an older issue from T-064's depth order: near skyscrapers (z up to 146) can be drawn over the trick popups (z 100); the Project Lead proposed a small UI ticket to the board.
- Documents touched: `game/README.md`
- Tasks: T-130 (done)

## 2026-10-14: The combo heats up at x2, x3 and x4
- Decision or change: the board asked for the combo to feel like it heats up: the counter changes at x2, more at x3, and from x4 (the top step; the combo still goes to its x6 cap) it is maxed out with the likes bar on fire. The combo and "Hype Lv" text take the game's comic look (Bangers). Fire drawn in code first, no PixelLab, oranges and yellows, never Redgull red. No sound for now. Task T-131 to the UI Agent. The board also asked for something on the trick popups; what, is still open.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-131

## 2026-10-14: Trick popups heat up with the combo and stay above the buildings
- Decision or change: the board chose both proposals for the trick popups: they heat up with the combo in T-131's steps (black and white below x2, orange or yellow accents at x2 and x3, a flaming edge from x4), and they are always drawn above the buildings (QA found in T-130 that near skyscrapers, z up to 146, covered popups at z 100). T-132 (above the buildings) starts now; T-133 (heat steps) waits for T-131 and T-132.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-132, T-133

## 2026-10-14: T-132 done: trick popups always above the buildings
- Decision or change: the board playtested and approved it ("look good"). Popups (trick and challenge) are now drawn at an absolute depth at the top of Godot's range, so no building, sign, boulder or the car can cover them, however tall the map's depth scheme grows. The HUD and screens still draw over them. QA round 1: all 6 pass.
- Documents touched: `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-132 (done)

## 2026-10-14: T-131 done: the combo heats up
- Decision or change: the board playtested and approved it ("look good"). The combo counter has four looks by the multiplier: pink below x2, bigger yellow with a light pulse from x2, bigger orange with a glow and a stronger pulse from x3, and biggest white-hot with a flickering glow from x4 to the cap, where pixel flames drawn in code burn along the likes bar (oranges and yellows, no Redgull red, no PixelLab). The look follows the combo down. The combo counter, "Likes" and "Hype Lv" use the Bangers comic font. QA round 1: all 10 pass. Noted for later if the board wants: "HYPE LV 1" in Bangers at its small size reads a bit like "7"; the flames over the empty part of the bar are a low line. T-133 (popups heat up the same way) is now open.
- Documents touched: `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-131 (done), T-133

## 2026-10-14: T-031 closed
- Decision or change: the board closed T-031 (its own visualisation tools, HTML): it is ongoing infrastructure work, not a one-off job, so it doesn't need a ticket. Status cancelled, the file kept.
- Documents touched: none
- Tasks: T-031 (cancelled)

## 2026-10-14: T-107 done: the old claude.ai task board pages deleted
- Decision or change: the three old claude.ai task board pages (task board, prototype, test board) turned out to be owned by the account the Project Lead's session uses, so on the board's go the Project Lead deleted them instead of the board. The links stay in this timeline and T-032 as history. The local task board (http://localhost:8765) is the only board.
- Documents touched: none
- Tasks: T-107 (done)

## 2026-10-14: T-109 done: status changes are not committed automatically
- Decision or change: the board chose to keep it as it is: `task_status.py` changes only the task file and never commits. The change goes into the next commit on the task's branch, or the Project Lead's next commit on `master`.
- Documents touched: `tasks/README.md`
- Tasks: T-109 (done)

## 2026-10-14: T-133 done: trick popups heat up with the combo
- Decision or change: the board playtested and approved it ("lgtm"). Trick and challenge popups take T-131's heat step (one shared source, `ComboHeat`): unchanged black and white below x2, a yellow ring at x2, a wider orange ring with an orange amount at x3, and that plus a flickering flame edge in the likes-bar fire's style from x4. Fill stays white, names black, no Redgull red, drawn in code. Stacking, limits and T-132's depth unchanged; the drift prototype keeps plain popups. QA round 1: all 7 pass. Noted for later if the board wants: the small extended-drift popup's orange "+0.05" at x3+ is muddy at game scale (cheap fix: keep it black); x4 flames can overlap the bottom of a popup stacked above.
- Documents touched: `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-133 (done)

## 2026-10-14: The likes heart: script-drawn, in the comic look
- Decision or change: the board moved T-086 (the heart icon on the likes bar) to Planning and chose the Project Lead's recommendations: drawn by script (no PixelLab, 0 generations) and matching the HUD's new comic look (thick dark outline like the "LIKES" text, sized to it). T-086 started with the Asset Generation Agent.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-086

## 2026-10-14: T-086 done: the likes heart
- Decision or change: the board playtested and approved it ("lgtm"). The heart next to "LIKES" is an 11x10 pixel heart drawn by script (no PixelLab, 0 generations) in flat Redgull red with a dark outline, shown at 2x, level with "LIKES". QA round 1 failed it: the shorter art moved "LIKES", "HYPE LV" and the combo counter 4 px down; round 2 kept the old row height (a 26 px heart box) and pinned the HUD positions in a test. QA round 2: all 6 pass. The rule that a task failing QA once moves to opus could not be applied: the model hook reads the task file on master, not on the task's branch, so the fix ran on sonnet.
- Documents touched: `game/README.md`
- Tasks: T-086 (done)

## 2026-10-14: The model hook keeps reading master's task file
- Decision or change: the board chose to leave the model hook as it is. It reads a task's model from the task file on master, so a model change made on a task's branch (for example to opus after a failed QA round) does not reach the hook; no tooling ticket.
- Documents touched: none
- Tasks: none

## 2026-10-14: T-044 done: minions
- Decision or change: the board playtested and approved it ("lgtm"). Placeholder light green minions keep 12 to 20 around the car (growing over the 7 minutes, `enemies.json` unchanged), spawning 3 units off screen, walking at the car round buildings and boulders, never blocking it; touching the car deals 5 damage every 0.5 s with a knockback; pausing freezes them and a new run clears them; they take the car's place in the buildings' draw order. `take_damage(amount)` is documented for the weapons; on death a minion drops 2 coins 60% of the time, and driving over a coin collects it. With no weapons yet, the board's playtest covered spawning, chasing, damage, knockback, pause and draw order; killing and coins are judged once the starting gun (T-041) is in, with no debug kill key (board). Proposals the board accepted as built: minions walk round obstacles, ones left a screen behind are replaced at the screen's edge, minions behind an opaque building are hidden, and sizes stay in code. QA round 1: all 9 pass. The combo's extra spawning has a hook (`run.minions.spawn_multiplier`), wired by T-085. Merged in 676439e (another Project Lead instance's timeline commit took in the staged merge); this entry, the GDD regeneration and the unblocked tasks follow in the next commit. Now open: T-041, T-042, T-045, T-068, T-072, T-085.
- Documents touched: `docs/enemies.md`, `game/README.md`
- Tasks: T-044 (done)

## 2026-10-14: Rule: check for another instance's merge before committing on master
- Decision or change: after the Project Lead's timeline commit swept up the other instance's half-finished T-044 merge (676439e; the other instance finished T-044 in 41f14f6), the board made it a rule: all instances share the main checkout, so before every commit on master an instance checks that no merge is in progress and doesn't commit if one is, stages only its own files (never `git add -A`), and chains git commands with `&&` so an error stops the command.
- Documents touched: `docs/working-with-the-board.md`
- Tasks: none

## 2026-10-14: Weapons, kaiju, combo spawning and enemy art started in parallel
- Decision or change: the board asked to start every ticket T-044 unblocked, each on its own agent: T-041 (starting gun), T-042 (flamethrower), T-045 (kaiju), T-085 (combo raises spawning), T-068 (minion art) and T-072 (hit, death, coin and car damage effects). The art tasks generate one sample each for the board's review before the full set (the board's go for the samples). T-042 and T-045 get a documented playtest setting (the flamethrower from the start of a run; an early kaiju), since there is no level-up offer yet and the kaiju comes at 7:00. T-085 got a board's review line: more minions with a combo is something the player meets.
- Documents touched: none
- Tasks: T-041, T-042, T-045, T-068, T-072, T-085

## 2026-10-14: T-041 done: the starting gun
- Decision or change: the board playtested it and marked it done, then asked for the merge. The car starts every run with the gun: it fires only with an enemy in range, every 1.26 s at tier 1, closest enemy first (the Unity rule), bullets dealing 2 damage through `take_damage`; all 8 tiers can be applied from code (offering them is T-043). Placeholder bullets: a cyan dot with a white core. It also adds the shared weapon plumbing (`run.weapons`, `weapon.gd`): every weapon extends `weapon.gd` and is listed in `WEAPON_SCRIPTS`; targets are any node in the "enemies" group with `take_damage()`, so the kaiju is shot too. QA round 1: all 7 pass. Left for playtests: bullet size and the wait before the first shot.
- Documents touched: `docs/weapons.md`, `game/README.md`
- Tasks: T-041 (done)

## 2026-10-14: T-127 done: named Project Lead sessions and ticket owners
- Decision or change: the board asked this instance to merge T-127, which another instance had built, QA'd (round 1, all 8 pass) and marked done on its branch but not merged. Each Project Lead session now gets a short name from the board (`python tools/board_inbox.py name <session id> <Name>`); tickets get a `lead:` header line naming their owner, set only through `task_status.py --lead`; the inbox is append-only with a read position per session, so every session sees the board's drags on its own and unowned tickets and never another's; `board_inbox.py watch` replaces the old tail-and-`take_inbox()` monitor; the task board shows an owner label on cards and in the Builds tab, with an owner filter. One merge conflict in `tasks/README.md` (both sides added text; both kept). T-128 to T-133, created on master after T-127 branched, have no `lead:` line yet; they count as unowned and the script adds the line when a session claims them. Next: the board's message-on-move idea builds on this.
- Documents touched: `tasks/README.md`, `tasks/_TEMPLATE.md`, `docs/README.md`, `docs/working-with-the-board.md`
- Tasks: T-127 (done)

## 2026-10-14: Minion animation, polish animations, dev settings, the dev timer
- Decision or change: the board kept the T-068 sample lizard as the base and wants it animated walking on all fours in 8 directions (5 drawn, 3 mirrored) with 7 walk frames each (about 37 generations in all); next step with its go: the 8 rotations and a 7-frame walk in one direction for review (about 9). Polish for the MVP, once it is playable end to end: a minion damage animation, and minions that bump into each other fall down, get up and carry on (new tickets T-134, behaviour with a placeholder, and T-135, its art). Settings exposed for playtests and development go under an internal dev flag players never see. T-045 sent back to add a dev timer setting (the run clock's minutes and seconds at the start) to fast-forward to the boss, replacing its early-kaiju switch. This Project Lead session is named Enemies.
- Documents touched: `docs/enemies.md`, `docs/visual-style.md`, `docs/hud-and-menus.md`
- Tasks: T-068, T-134, T-135, T-045

## 2026-10-14: The board's answers on the coin, combo switch, flames, kaiju and gun
- Decision or change: T-072's coin sample is fixed by free scripts (outline, smaller, stray pixels removed) and the hit, death and car damage effects are drawn by script, with no more PixelLab calls. T-085's code-level on/off switch is enough for now. The flamethrower keeps the drift smoke showing. The flames hit the kaiju on any overlap with its body (minions keep the centre rule); folded into T-042's fit, with the kaiju's body size from T-045. The kaiju walks round buildings, as built. The gun's bullet size and first-shot wait are fine as built.
- Documents touched: `docs/weapons.md`, `docs/enemies.md`
- Tasks: T-072, T-085, T-042, T-045

## 2026-10-14: T-085 done: the combo raises minion spawning
- Decision or change: the board playtested it ("works fine") and asked for the merge. The minion count follows the combo live, through `ComboData.spawn_multiplier` (up to about 1.75 times at the top combo), on top of the slow growth over the run; a minion's hit cuts the combo, so the extra minions push it back down. Switch: `combo_raises_spawning` in `minion_spawner.gd`, on by default (the board: a code-level switch is enough for now). QA round 1: all 4 pass.
- Documents touched: `docs/enemies.md`, `game/README.md`
- Tasks: T-085 (done)

## 2026-10-14: T-136 done: a note with every drag on the task board
- Decision or change: the board wants to give feedback from the task board without going to a Claude terminal. Dropping a card on another column now opens a small box for an optional note (Enter moves, Shift+Enter adds a line, Esc cancels and the card stays); the note travels with the move to the ticket's owner session (the watcher prints it as `(note: ...)`) and is added to the ticket's result notes. A refused move keeps the box open with the note and the reason. The note path from the server to the watcher already existed (the detail view's "Note for the move"); only the drag skipped it. Tooling, merged after QA: round 1, all 5 pass. This instance is named "Tools" (T-127).
- Documents touched: `docs/README.md`, `docs/working-with-the-board.md`
- Tasks: T-136 (done)

## 2026-10-14: T-042 done: the exhaust flamethrower
- Decision or change: the board asked for the merge. Flames come out behind the car while it drifts (0.85 units/s or more, 0.2 s linger, half size growing to full over 1 s), hitting enemies inside for 2 at once and 2 every 0.2 s through `take_damage`; all 8 tiers apply from code. Before merging it was fitted into T-041's weapon plumbing (it extends `weapon.gd`, is in `WEAPON_SCRIPTS`, not owned at the start of a run) and gained the board's rule: an enemy reporting `hit_radius_units()` (the kaiju) burns on any overlap, minions on their centre. Drift smoke still shows with it. Playtest switch `flamethrower_at_start` in `game/data/playtest.json`, on as merged. QA round 2: all 7 pass. Now open: T-043, T-071.
- Documents touched: `docs/weapons.md`, `game/README.md`
- Tasks: T-042 (done)

## 2026-10-14: The kaiju's dev timer dropped; the kaiju at 30 s for the playtest
- Decision or change: the board dropped the dev timer setting it asked for earlier. For T-045's playtest the kaiju arrives 30 s into the run; once the board has seen it spawn, take damage, damage the car and win the run when killed, it approves the merge, and the arrival is set back to 7 minutes right before merging. T-045 merges master first, so the gun and flamethrower can kill it. T-045's QA round 2 had failed only on a duplicated section in `game/README.md`, fixed in this round.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-045

## 2026-10-15: No routing around refused actions; test-run time limit and per-run settings files; the flamethrower switch stays on
- Decision or change: the board took the Project Lead's recommendations. A common rule for every agent in `CLAUDE.md`: when an action is refused, an agent never gets around it with another tool; it stops and tells the Project Lead, who brings it to the board (after an agent used `taskkill` when stopping its own hung Godot test run was refused). New tooling ticket T-137: the test runners stop hung runs after a time limit, and tests that write `user://` files get per-run files so parallel runs from different folders don't fail at random. The `flamethrower_at_start` playtest switch stays on in master until T-043 offers the flamethrower at a level-up. The board played the T-045 kaiju build ("good"): it merges once QA passes, with the kaiju set back to 7 minutes first.
- Documents touched: `CLAUDE.md`
- Tasks: T-137, T-045

## 2026-10-15: T-045 done: the kaiju
- Decision or change: the board played the kaiju build ("good") and approved the merge. On the boss-time signal (7:00 into the run) a placeholder kaiju (4 units wide, 7 tall, dark slate green, drawn in code) appears just off-screen and walks round buildings at the car at 3 units/s; contact does 20 damage once a second with a 16 units/s knockback; weapons damage it at any time through `take_damage`, and it reports `hit_radius_units()` 2.0 so the flames burn it on any overlap; at 0 health its 10 coins are added and the run ends as a win. Playtest switch `kaiju_early_arrival` (30 s) in `game/data/playtest.json`, set to off right before merging as the board asked; the earlier dev timer setting was dropped. QA: round 1 passed, round 2 failed on a duplicated README section, round 3 (after the board's change) passed. Now open: T-046, T-050, T-069.
- Documents touched: `docs/enemies.md`, `game/README.md`
- Tasks: T-045 (done)

## 2026-10-15: T-068 done: the animated minion
- Decision or change: the board approved it ("it's good") and asked for the merge. The board's sample lizard walks on all fours in 8 directions (S, SE, E, NE, N drawn; SW, W, NW mirrored) with 8 walk frames each at 10 per second, each minion starting at a random point in the cycle, drawn at scale 0.5 (about 1 unit long), facing the way it walks. 8 frames instead of 7 because PixelLab's animation endpoint only takes even counts (board, 2026-10-14). The board's tweak: no shadow under the minions (the coin keeps its own). Cost: 9 generations in all (4919 to 4909), including one duplicate call charged by mistake after a shell timeout shorter than the 600 s rule. QA round 1: all 5 pass. Now open: T-134.
- Documents touched: `game/README.md`
- Tasks: T-068 (done)

## 2026-10-15: T-043 done: the level-up weapon choices (logic only)
- Decision or change: each level-up now works out its weapon choices and applies the one taken: "get the flamethrower" or "upgrade the gun" at first, then "upgrade the gun" or "upgrade the flamethrower"; a weapon at its last tier is not offered (only one choice when only one weapon is left), and with nothing left the level-up is skipped. Ids `upgrade_gun`, `get_flamethrower`, `upgrade_flamethrower`, signal `offers_ready`, function `choose()` (`game/README.md`, "The level-up offers"). Nothing shows yet: the level-up pause stays off until the screen (T-052, after its text, T-051) turns it on, so the board saw no change at a level-up in the T-043 build; the Project Lead had not said clearly enough that the playable step is T-052. The `flamethrower_at_start` switch stays on until the board has played T-052. Tooling-style merge after QA: round 1, all 6 pass. Now open: T-051. Also planned (this session, "Weapons"): T-138, the Project Lead's replies posted on tickets at each lane change and highlighted cards on the task board (the board's request).
- Documents touched: `docs/weapons.md`, `game/README.md`
- Tasks: T-043 (done), T-051, T-052, T-138

## 2026-10-15: T-137 done: test runs end themselves when hung, and parallel runs don't share files
- Decision or change: tooling the player never meets, merged straight after QA. `run_tests.sh` and `run_tests.ps1` stop a run after 300 s (`GUT_TIME_LIMIT` changes it), killing only the Godot process they started, with a message naming the limit (`game/tools/check_time_limit.sh` shows it). Every test that wrote under `user://` (12, plus T-045's kaiju test) now uses `RunPaths.file(...)`, a per-run folder `user://test_runs/<pid>/` deleted after the run, so parallel runs from different folders no longer fail at random. QA round 1: all 5 pass; two full runs at once passed three times in a row.
- Documents touched: `game/README.md`
- Tasks: T-137 (done)

## 2026-10-15: T-051 done: the level-up screen text
- Decision or change: the board read the text ("text lgtm"). Heading "Redgull Sent a Gift Pack!", button "Take it", a card for getting the flamethrower and one per upgrade tier of each weapon (gun tiers 2 to 8, flamethrower tiers 2 to 8), and names for the two weapons: the gun is "Sponsor Special", the flamethrower "Hot Take Exhaust". The table is in T-051's result notes. QA round 1: all 4 pass; QA noted the gun's "20% faster" is 18 to 19% in practice and the flame's "area grows 20%" means 20% wider and deeper; the board kept the text as written. Now open: T-052, the screen.
- Documents touched: none (the text lives in T-051's result notes)
- Tasks: T-051 (done), T-052

## 2026-10-15: T-072 done: enemy hit tint, car shake, the coin
- Decision or change: the board playtested it ("lgtm") and marked it done. The board removed round 1's hit, death and car damage effects (their art kept in `art-archive/T-072/unused_effects/`). What's left: an enemy that takes damage (minions and the kaiju) gets a brief, slight red tint (`Color(1, 0.62, 0.62)` for 0.12 s, not Redgull red; the flamethrower's orange flash takes over cleanly); the car's sprite shakes for 0.2 s (about 3 pixels) when the car takes damage, moving only the drawing, not physics or the camera; and the coin is a script-fixed 10x12 gold coin from the one PixelLab sample (1 generation). QA: round 1 passed the first version; round 2, on criteria rewritten for the board's changes, passed all 6.
- Documents touched: `game/README.md`
- Tasks: T-072 (done)

## 2026-10-15: The level-up screen's look and controls; T-052 planned
- Decision or change: the board chose the comic look for the level-up screen's cards (white rounded cards, black borders, Bangers font, over the dimmed run), replacing "plain cards", and keyboard plus mouse to pick (A/D or arrows move, Enter or Space takes, or click the card's button). Upgrade cards show the next tier's text from T-051. The `flamethrower_at_start` playtest switch goes off in T-052's branch, so the board's first level-up offers the flamethrower. T-052 goes to the UI Agent; it waits for the board's playtest before merging.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-052

## 2026-10-15: The kaiju's health bar above the kaiju; level-up animations and red-gold level-up art; the meteor attack started
- Decision or change: T-050 (planned from the task board): the kaiju's health bar sits above the kaiju and follows it, about as wide as the kaiju (following its width), neon purple on white with a black outline and thin black dividers every 10%, in a subtle comic style like the combo popups, no label, always drawn above buildings; it replaces the HUD-corner bar. New tickets: T-139 (the likes bar animates on a level-up), T-140 (art for the level-up screen, red and gold, Redgull-themed; sample first, PixelLab only with the board's go) and T-141 (the level-up screen animates in with that art; waits for T-140, as the board asked). T-046 (the kaiju's meteor attack) started on the board's go.
- Documents touched: `docs/hud-and-menus.md`, `docs/visual-style.md`
- Tasks: T-050, T-139, T-140, T-141, T-046

## 2026-10-15: Cheaper QA
- Decision or change: the board's usage tab showed every session subagent-heavy and the QA/Integration Agent as the largest share (15%). On the board's request: QA always runs on sonnet (it was opus for tasks with a board's review line; the hook in `.claude/hooks/board_gate.py` and the `tasks/README.md` rule changed with it), its definition gets a "Keeping checks cheap" section (read the diff and only what a criterion needs, run each test set once with summary output only, no temporary tests or extra switch runs unless a criterion asks, one short line per criterion), and the Project Lead keeps its QA prompts short, since it reruns every test set at merge anyway.
- Documents touched: `tasks/README.md`, `.claude/agents/qa-integration.md`, `agent-notes/project-lead.md`
- Tasks: none

## 2026-10-15: T-059 done: the garage screen text
- Decision or change: the garage screen's text, in the voice the board approved for the level-up cards: heading "Redgull Pit Stop"; upgrades "Sponsored Throttle" (top speed 0.1 s sooner per level), "Reinforced Chassis" (+10 car health per level), "Brand Impact" (+5% weapon damage per level); "Level {n}", "Price: {n}", "Coins: {n}", "Buy", "Fully Funded" at the last level, "Not enough coins", "Back". The table is in T-059's result notes. QA round 1: all 3 pass. The board first asked for merges without its playtest, then changed its mind (board, 2026-10-15: one unified build to playtest at the end instead). This merge was already open by then, and another Project Lead instance's commit (31764bb, "Cheaper QA") was made while it was open and completed it, so T-059 is in master without the board's read. It is text in the ticket only (no change the player sees until the garage screen, T-058, which goes into the unified build); the board can still change any line.
- Documents touched: none (the text lives in T-059's result notes)
- Tasks: T-059 (done), T-058

## 2026-10-15: T-138 done: Project Lead replies on tickets, highlighted cards
- Decision or change: `python tools/task_status.py <id> [<status>] --reply "<text>"` posts the Project Lead's reply to the board on the ticket, in a new `## Updates` section just before Result notes (date, lane change, full text). The task board's ticket view shows the newest as "Latest from the Project Lead" at the top, older ones collapsed; a card glows with a "New" chip when its status changed or a reply was posted since the board last opened it, and the "Changed" list follows the same rule. Rule for the Project Lead: at every lane change of a ticket it owns, it posts the same reply it gives in the terminal (board, 2026-10-15). The live task board server must be restarted to show the page changes. Tooling, merged after QA: round 1, all 7 pass.
- Documents touched: `docs/README.md`, `docs/working-with-the-board.md`, `tasks/README.md`, `tasks/_TEMPLATE.md`
- Tasks: T-138 (done)

## 2026-10-15: T-004 done: the Freesound downloader keeps only CC0 and CC BY
- Decision or change: the downloader searches with a license filter for "Creative Commons 0" and "Attribution" only (Freesound's names, checked against its API docs by QA) and skips, with a printed reason, any other license before writing a file; the allowed list is one line in `game/tools/freesound.py`. The quoted multi-word OR filter isn't shown word for word in Freesound's docs, so the first live search (T-076) should confirm it returns results. Tooling, merged after QA: round 1, all 7 pass. Now open: T-076.
- Documents touched: `game/README.md`
- Tasks: T-004 (done), T-076

## 2026-10-15: T-057 done: coins and garage upgrades are saved; buying works
- Decision or change: `PlayerProgress` (`game/scripts/data/player_progress.gd`, made by `GameFlow` as `GameFlow.progress`) saves the coin total and each upgrade's level to `user://progress.json`; a missing or broken file is a new player. Every run's coins are banked when it ends, win or loss. `buy(id)` spends the price, raises the level and saves, or refuses with `NOT_ENOUGH_COINS` or `MAXED` and changes nothing; reading functions give each upgrade's level, next price and value for the garage screen and for applying upgrades at run start. Simple choices where the docs were silent: levels clamped to 0..max, negative run coins ignored. Nothing shows yet (the garage screen is T-058), so merged after QA: round 1, all 7 pass. Now open: T-060, T-061, T-062.
- Documents touched: `docs/garage-design.md`, `game/README.md`
- Tasks: T-057 (done), T-058, T-060, T-061, T-062

## 2026-10-15: T-062 done: the garage damage bonus reaches both weapons
- Decision or change: at the start of a run, `GameFlow` gives the weapon rack the damage bonus bought in the garage (`progress.current_value("damage_bonus")`); the gun's and the flamethrower's damage are multiplied by 1 + bonus/100 on top of their own tiers, the same factor for both. At level 0 nothing changes, and no level can be bought until the garage screen (T-058) is merged, so nothing the player meets changes yet: merged after QA, round 1, all 4 pass.
- Documents touched: `docs/weapons.md`, `game/README.md`
- Tasks: T-062 (done)

## 2026-10-15: T-060 done: the garage acceleration upgrade reaches the car
- Decision or change: at the start of a run the car's time to top speed comes from the garage's acceleration upgrade (`progress.current_value("acceleration")`, 2.3 s at level 0 down to 1.3 s at level 10); the drift prototype keeps its own tuning. W snaps the car to cruise speed first, so the upgrade only shortens the climb from cruise to top speed: the board should judge in playtest whether it is felt. Invisible until the garage screen (T-058) merges, so merged after QA: round 1, all 5 pass.
- Documents touched: `docs/drifting.md`, `game/README.md`
- Tasks: T-060 (done)

## 2026-10-15: T-061 done: the garage health upgrade reaches the car
- Decision or change: at the start of a run the car's starting and maximum health come from the garage's car health upgrade (`progress.current_value("car_health")`, 100 at level 0, +10 per level), and the HUD's health bar follows it; a run with no saved progress attached (tests, fixtures) keeps run.json's health. Invisible until the garage screen (T-058) merges, so merged after QA: round 1, all 4 pass. With T-060 and T-062 this completes the three garage upgrades.
- Documents touched: `game/README.md`
- Tasks: T-061 (done)

## 2026-10-15: The cruise boost's look: discreet motion lines
- Decision or change: the board played T-008's placeholder boost (five streaks behind the car) in the weapons-garage playtest build and found it too much. The boost should be discreet: a few motion lines that show briefly. The art comes later, in T-009 (final release), which now has the description and waits only for T-008.
- Documents touched: `docs/visual-style.md`, `docs/drifting.md`
- Tasks: T-105 (done), T-009 (description added), T-008

## 2026-10-15: T-052 done: the level-up screen
- Decision or change: the level-up (gift pack) screen merged after the board's playtest in the weapons-garage unified build ("level up screen is fixed all good"). The board's earlier freeze on a beige screen in T-052's own folder was not the screen: Godot's local class cache there was stale after master was merged in, so the game script failed to load. The Project Lead rebuilt the cache (a headless import); no file changed. The status script counted that pass back through QA as a third round, though no check ran.
- Documents touched: `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-052 (done), T-140 (now open)

## 2026-10-15: T-050 done: the kaiju's health bar
- Decision or change: the board played the kaiju build ("it works well!") and the kaiju's HUD health bar merged. After the merge, 3 of its tests fail on master (the bar's position and width tests, and hiding in a new run); they passed on the branch, so the UI Agent is finding the cause and fixing it on T-050's branch, to be merged again.
- Documents touched: `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-050 (done; fix after merge in progress), T-098 (now open)

## 2026-10-15: Meteor boulders fade away after 10 seconds
- Decision or change: the board liked the meteor attack in the kaiju build (damage and a big knockback when a meteor lands on the car; likes the falling rocks). One change, in its own ticket: a boulder left by a meteor stays 10 seconds, then fades away and is gone. T-046 itself is being made ready to merge (its playtest switches set back off, master merged in).
- Documents touched: `docs/enemies.md`
- Tasks: T-046, T-142 (new, blocked on T-046)

## 2026-10-15: T-046 done: the kaiju's meteor attack
- Decision or change: merged after the board's playtest in the kaiju build ("it works well!": damage and a big knockback when a meteor lands on the car, likes the falling rocks). Before merging, the Enemy Behavior Agent caught the branch up with master and set its playtest switches back to the game's rules (`kaiju_early_arrival` and `flamethrower_at_start` both off). Tests: 734 of 737 GUT tests pass; the 3 failures are T-050's kaiju health bar tests, already failing on master and being fixed on T-050's branch. Python tool tests all pass.
- Documents touched: `docs/enemies.md`, `game/README.md`
- Tasks: T-046 (done), T-142 (now unblocked), T-070, T-078

## 2026-10-15: T-050 fix after merge: master's tests pass again
- Decision or change: the 3 kaiju health bar tests that failed after T-050's merge had an outdated setup, not a broken bar: since T-052 the run pauses on level-ups, and an earlier test in the suite leaves the game paused, so the bar never updated in those tests. The UI Agent made the test file unpause the game before and after each test; the bar's code is unchanged. Merged without QA (test-only change). Master: 737 of 737 GUT tests, all Python tool tests pass. Which earlier test leaks the pause is not traced.
- Documents touched: none
- Tasks: T-050

## 2026-10-16: T-076 done: the MVP's sound effects are chosen
- Decision or change: the board listened to T-076's candidates and approved them ("sfx looks good"): the SFX Agent's recommended file per sound (engine, drift, gun, flames, hit, coin, meteor warning, meteor impact) goes into the game in T-077, which the board will playtest. Only the meteor warning ("Falling.wav" by Augdog) is CC BY and needs a credit.
- Documents touched: `docs/unfiled-game-details.md`, `game/README.md`
- Tasks: T-076 (done), T-077 (now open, the board's review added)

## 2026-10-16: T-058 done: the garage screen
- Decision or change: the board played the garage (with T-089's Garage button, in T-089's folder): "garage works!". One change: the acceleration upgrade is named "Energy Throttle" instead of "Sponsored Throttle" (board, 2026-10-16). The UI Agent renamed it, QA passed once more, and T-059's text table is updated. Merged.
- Documents touched: `docs/garage-design.md`, `game/README.md`
- Tasks: T-058 (done), T-059 (text table updated), T-089

## 2026-10-16: T-089 done: the main menu's Garage button opens the garage
- Decision or change: Garage on the main menu opens the garage screen, and its Back button returns to the main menu; Start still works after a visit. Built on T-058's branch so the board could play both together (board, 2026-10-15); the board played them: "garage works!". Merged after T-058.
- Documents touched: `docs/game-loop-architecture.md`, `game/README.md`
- Tasks: T-089 (done)

## 2026-10-16: The status hook should let read-only commands through
- Decision or change: the board asked for a tooling ticket: the hook that keeps task status lines changing only through the status script also refuses commands that only read a task file and mention `status:`. T-143 keeps blocking writes and lets reads through.
- Documents touched: none yet (T-143 updates `tasks/README.md`)
- Tasks: T-143 (new), T-142 (started), T-077 (in QA)

## 2026-10-16: Redgull logo: a seagull's head in profile, one shade of dark red
- Decision or change: the board redefined the logo: only the side profile of a seagull's head (the whole bird would look like any bird), as minimal as possible, in a single shade of dark red. Replaces the "sketched seagull with red eyes". The board asked for a PixelLab sample first, so T-075 starts with one logo for review.
- Documents touched: `docs/visual-style.md`, `docs/extended-narrative.md`
- Tasks: T-075 (started)

## 2026-10-16: T-075 first logo sample rejected; allowance of 10 generations
- Decision or change: the first PixelLab sample read as a bell or the letter R, not a gull's head. The board agreed and gave an allowance of up to 10 more generations, spent at the team's judgement, until there is a sample worth showing. This replaces the one-round rule for T-075 only.
- Documents touched: none (recorded on T-075)
- Tasks: T-075

## 2026-10-16: An SFX volume slider, silent by default
- Decision or change: from the board's playtest drag on T-077: "add a settings slider for the SFX volume. default it to 0." The pause screen gets an "SFX volume" slider, 0 to 100, starting at 0 (sound effects silent until the player turns them up; the board confirmed this reading), saved between sessions like the zoom. Built as a quick tweak on T-077 by the SFX Agent.
- Documents touched: `docs/hud-and-menus.md`
- Tasks: T-077

## 2026-10-16: T-142 done: meteor boulders fade away
- Decision or change: a boulder left by a meteor stays 10 seconds, then fades over 2 seconds and is removed (no longer blocks the car); the map's own boulders stay. Both numbers are in `game/data/enemies.json`; the 2-second fade was the agent's proposal and the board kept it. The board playtested it: "LGTM". The early-kaiju playtest switch was set back off before merging.
- Documents touched: `docs/enemies.md`, `game/README.md`
- Tasks: T-142 (done)

## 2026-10-16: T-075 done: the Redgull logo
- Decision or change: the board picked PixelLab's result made from a script-drawn gull silhouette (init strength 80): a gull's head in profile with a hooked beak and a slanted eye cut-out, flattened to one dark red (RGB 135,17,27), at 128, 64 and 32 pixels. The board: "the icons look good to me, merge them". 6 generations in total (the first sample plus 5 of the allowance of 10). Every other candidate is kept in `art-archive/T-075/`. Where the logo appears in the game is decided separately.
- Documents touched: `docs/visual-style.md`, `game/README.md`
- Tasks: T-075 (done)

## 2026-10-16: The QA column can mean "ready for the board's review"
- Decision or change: the board found T-077 left in In progress although its slider tweak was ready to play. Rule (board): a task in the QA column usually waits for the QA/Integration Agent, but when the board or the ticket says so (for example after a quick-tuning tweak) it waits there for the board's own review, with no QA agent. The board also found the SFX volume slider unusable (squeezed into the checkbox row, no room to drag); it goes back to the SFX Agent to match the zoom slider's row.
- Documents touched: `docs/working-with-the-board.md`
- Tasks: T-077

## 2026-10-16: Gift pack drop: Redgull's helicopter drops the gift pack
- Decision or change: the board decided the level-up screen should no longer just appear. When the player levels up, a helicopter sent by Redgull flies over the screen and drops a package with Redgull's brand; driving over the package opens the level-up (gift pack) screen. Replaces the after-MVP "plane drops the gift pack" idea. Tickets created, not started: T-144 (the flow with placeholders, Game Loop Agent), T-145 (helicopter art) and T-146 (package art), both waiting for T-144. Open questions on T-144 go to the board before it starts.
- Documents touched: `docs/game-loop-architecture.md`, `docs/visual-style.md`, `docs/extended-narrative.md`, `docs/hud-and-menus.md`
- Tasks: T-144, T-145, T-146 (new)

## 2026-10-16: Meteors never land on a standing meteor boulder
- Decision or change: the board saw meteors fall on boulders left by earlier meteors that hadn't faded yet, and decided they must not. The built placement check already refuses overlapping boulders, so T-147 first finds why it still happens, then fixes it. Ticket created, not started.
- Documents touched: `docs/enemies.md`
- Tasks: T-147 (new)

## 2026-10-16: T-077 done: the sound effects play in the game
- Decision or change: the approved sounds play at their moments (engine following speed, drift, gun, flames, hits, coins, meteor warning and impact), volumes in `game/data/sfx.json`, credit for "Falling.wav" by Augdog (CC BY 4.0) in `game/README.md`. The board's tweaks: an "SFX volume" slider on the pause screen, 0 to 100, silent (0) by default, saved; first squeezed into the checkbox row and undraggable, then given its own row like the zoom slider. The 60 the board saw on opening was a value saved in its settings file, not the default; the Project Lead cleared it. Board: "LGTM". Final QA passed. One test fails on the board's computer only, because it reads the board's real saved garage upgrades: T-148 (new) fixes that.
- Documents touched: `docs/hud-and-menus.md`, `game/README.md`
- Tasks: T-077 (done), T-148 (new)

## 2026-10-16: T-143 done: the status hook lets read-only commands through
- Decision or change: the hook still refuses any shell command that could write a task file's status or qa_rounds line, but now lets through commands it can prove only read (grep, sed -n, head, Select-String and so on); anything it can't prove is still refused. QA round 1: all 5 pass. While working, the agent hit the old false refusal on a README edit and then made the edit with the file editing tool; reported to the board. One GUT test still fails on the board's computer only (it reads the board's real save); T-148 fixes it.
- Documents touched: `tasks/README.md`
- Tasks: T-143 (done)

## 2026-10-16: The new level-up is built and played as one build
- Decision or change: the board started the new level-up (the gift pack drop, the likes bar animation, the level-up screen's red and gold art and its animation) and wants to playtest it all together in one build, not piece by piece. The session "Level-up" took over T-139 to T-141 (from Enemies) and T-144 to T-146 (from Art). The board's answers to T-144: the run keeps going until the screen opens; the package lands a short way ahead of the car on open road and stays until picked up; one package per level-up, each opening its own screen; an edge arrow points to an off-screen package. PixelLab go: one sample each for T-140, T-145 and T-146.
- Documents touched: `docs/game-loop-architecture.md`
- Tasks: T-139, T-140, T-141, T-144, T-145, T-146

## 2026-10-16: T-148 done: tests never touch the player's real save
- Decision or change: tests that went through the main menu read the board's real `progress.json` (one failed because the board had bought a damage upgrade), and 14 test files pointed later tests back at the real save files when cleaning up. Every test run now starts with empty test save files, and the run fails if any test is left pointing at the real save. QA round 1: all 4 pass with the board's real save in place, and the board's save files were byte-identical before and after. Master: 777 of 777 GUT tests pass again.
- Documents touched: `game/README.md`
- Tasks: T-148 (done)

## 2026-10-16: Old playtest builds removed; an agent's edit after a refusal accepted
- Decision or change: everything in the two unified playtest builds (`playtest/weapons-garage`, `playtest/kaiju-fight`) is now in master, so their folders are removed at the board's word; the branches are kept. Master is now the most complete build. The board also accepted the `tasks/README.md` edit the T-143 agent made with the file editing tool after the old hook falsely refused its shell command (the rule stays: an agent stops and reports a refusal instead of getting around it).
- Documents touched: none
- Tasks: T-143

## 2026-10-16: The level-up art and animation build on each other's branches
- Decision or change: so the new level-up can be played in one build, the board chose to chain the branches: T-145 and T-146 no longer wait for T-144 to be done but merge its branch for the swap-in; T-141 no longer waits for T-140 to be done but starts from its branch once its full set is approved. Each still passes QA; all go into one playtest build.
- Documents touched: none (tickets only)
- Tasks: T-141, T-145, T-146

## 2026-10-16: The cruise boost's motion lines: animated, PixelLab, judged in the game
- Decision or change: the board wants to see the motion lines in the game, not as samples ("There's no point for me checking the samples"), and wants them animated, made with PixelLab (one round, the board's go). T-009 is built on T-008's unmerged branch: the Asset Generation Agent generates the animation and swaps it in for T-008's placeholder, and the board plays it there. T-008 merges first, then T-009.
- Documents touched: `docs/visual-style.md`
- Tasks: T-009 (started), T-008

## 2026-10-16: Level-up art samples approved; the package reuses the gift box
- Decision or change: the board approved the three samples and the Project Lead's suggestions ("Yeah, looks good to me"), and asked for the Redgull logo wherever it fits. T-140: the gift box emblem (PixelLab) and the rest of the level-up screen art drawn by script. T-145: the helicopter, with its red shifted to Redgull's, a stronger red panel, the logo and script-drawn rotor frames. T-146: the dropped package reuses T-140's gift box, scaled down by script, with the logo and a parachute for the fall; its own crate sample is archived. No further PixelLab calls planned (3 generations spent in total). T-139 and T-144 passed QA and wait for the one level-up build.
- Documents touched: none (tickets only)
- Tasks: T-139, T-140, T-144, T-145, T-146

## 2026-10-16: T-008 and T-009 done: the cruise boost with animated motion lines
- Decision or change: when W jumps the car to cruise speed, three thin pale-cyan motion lines appear at the rear bumper, follow the car and slide back and thin out over about a third of a second (5 frames at 14 fps, 16 directions). PixelLab: 2 generations as planned (the first came back empty and was not regenerated; a script drew the first frame for the second). The board played it in the game, no samples: "LGTM". T-008 (the boost signal and effect) merged first, then T-009 (the art). The QA agent set T-009's qa_rounds back to 1 by hand after the status script counted 2 (raised with the board).
- Documents touched: `docs/visual-style.md`, `game/README.md`
- Tasks: T-008 (done), T-009 (done)

## 2026-10-16: The new level-up is done: Redgull's helicopter drops the gift pack
- Decision or change: the board played the one level-up build and approved it ("i played the level up playtest, and everything looks great"). Merged into master: T-144 (a level-up sends Redgull's helicopter, which drops the gift pack ahead of the car on open road; the run keeps going; driving over it opens the level-up screen; one package per level-up; an edge arrow to an off-screen package; tuning in `game/data/gift_pack.json`), T-145 (the Redgull helicopter, red with the logo and a spinning rotor), T-146 (the package: T-140's gift box made smaller, with the logo and a parachute while it falls), T-139 (the likes bar's white-hot flash at the level-up), T-140 (the level-up screen's red and gold art, with the logo on the ribbon and the gift box) and T-141 (the screen builds in over about half a second, with no card taken by accident). After the art went in, the drop's layout was fixed on the playtest branch (helicopter fully on screen, package below it, a 1.4 s parachute fall). PixelLab: 3 generations in all. Integration check and all three test sets passed on the merge.
- Documents touched: `docs/game-loop-architecture.md`, `docs/hud-and-menus.md`, `docs/long-gdd.md`, `docs/short-gdd/README.md`, `game/README.md`
- Tasks: T-139, T-140, T-141, T-144, T-145, T-146 (done)

## 2026-10-16: Ticket for the qa_rounds guard gap
- Decision or change: on T-139 the QA agent changed the ticket's qa_rounds line itself before running the status script, so it read 2 after one QA round; the hook meant to refuse that didn't. The board asked for a ticket: T-149 finds how such changes get past the hooks and closes each gap, with tests. Tooling only, so it merges after QA without a playtest. Not started.
- Documents touched: none
- Tasks: T-149 (new)

## 2026-10-16: Arrow-key trick prototype
- Decision or change: the board wants a quick playtest of tricks done with the arrow keys. One trick: Up, Right, Down, Left in a row makes the car side-flip to the right with a small fake jump; a live arrow-key HUD in the bottom-right corner; a comic-style confirmation when the sequence is completed; the roll art from PixelLab (board's go given), one car direction first. A standalone prototype, not MVP. Tickets: T-150 (text), T-151 (sequence detection, flip and hop with a placeholder roll), T-152 (input HUD and confirmation), T-153 (roll frames). One playtest build of all four.
- Documents touched: `docs/drifting.md`
- Tasks: T-150, T-151, T-152, T-153 (new)

## 2026-10-16: Trick prototype text is done
- Decision or change: T-150 passed QA and is merged: the side flip shows as "SIDE FLIP!" and the arrow-key display is labelled "TRICK". T-152 (the arrow-key display and confirmation) is unblocked. The long GDD now includes the trick prototype decision (not in the short GDD: not MVP).
- Documents touched: `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-150 (done), T-152 (open)

## 2026-10-16: Trick prototype ready for the board's playtest
- Decision or change: T-151 (arrow-key sequence and side flip with a fake hop), T-152 (arrow-key display labelled TRICK, SIDE FLIP! confirmation) and T-153 (PixelLab roll frames for the start direction, the code roll for the others; 2 generations) all passed QA and are combined in one playtest build, `playtest/tricks` (`C:\solid-carbide-worktrees\playtest-tricks`). GUT 874/874 on the combined build. Waiting for the board to play it.
- Documents touched: none on master yet (`docs/drifting.md`, `docs/visual-style.md`, `game/README.md` on the task branches)
- Tasks: T-151, T-152, T-153 (needs-playtest)

## 2026-10-17: Trick prototype round 2: jumping over obstacles, the left flip and the nose launch
- Decision or change: the board played the trick prototype (after Play was made to start straight into it on the playtest branch) and asked for: flying over obstacles and walls during a trick's jump, with a jump-over bonus that counts as a trick; the left side flip (Up, Left, Down, Right); and the nose launch (Up, Down, Up, Up). The board found the side flip's roll flat, like flipping a 2D image; the art approach is an open question to the board. Tickets T-154 (text), T-155 (the jumps and the two tricks, on top of `playtest/tricks`), T-156 (the confirmation cards for them).
- Documents touched: `docs/drifting.md`
- Tasks: T-154, T-155, T-156 (new); T-151, T-152, T-153 (needs-playtest)

## 2026-10-17: Trick art stays the code stand-in for now
- Decision or change: offered a 3D car rendered as pixels, more PixelLab generations, or the code stand-in for the tricks' art, the board chose to keep the code stand-in and judge how the tricks feel first. No new art tickets; T-153's frames stay in the playtest build.
- Documents touched: `docs/drifting.md`
- Tasks: none

## 2026-10-17: Trick prototype text, round 2, is done
- Decision or change: T-154 passed QA and is merged: LEFT FLIP!, NOSE POP!, CLEARED IT! (the jump-over bonus), and the right flip renamed RIGHT FLIP! so the two read as a pair (the board may keep SIDE FLIP!). T-156 is unblocked. The long GDD is regenerated with the round 2 decisions.
- Documents touched: `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-154 (done), T-156 (open)

## 2026-10-17: Trick art: full PixelLab art, made with the rotation tools
- Decision or change: the board asked whether PixelLab's rotation tools are available (they are: `/rotate` can change facing and tilt the camera, `/generate-8-rotations-v3` turns around the vertical axis, `/interpolation-v2` makes in-betweens; none rolls an object directly), then replaced the earlier "keep the code stand-in" decision: the tricks get full generated art. T-157 makes a sample in one direction (side roll, played reversed for the left flip, and the nose pop), capped at 15 generations; all 16 directions follow after the board approves it.
- Documents touched: `docs/drifting.md`
- Tasks: T-157 (new)

## 2026-10-17: Trick prototype round 2 and the rotation art sample ready to play
- Decision or change: T-155 (flying over obstacles with a CLEARED IT! bonus per obstacle, the left flip, the nose pop), T-156 (cards for RIGHT FLIP!, LEFT FLIP!, NOSE POP!, CLEARED IT!) and T-157 (15 PixelLab `/rotate` generations guided by a script-drawn 3D car; the nose pop has depth, the side roll is inconsistent) passed QA and are in the playtest build `playtest/tricks`. Waiting for the board's playtest and its choice for the roll art. PixelLab for tricks so far: 17 generations.
- Documents touched: none on master yet (`docs/drifting.md`, `docs/visual-style.md`, `game/README.md` on the task branches)
- Tasks: T-155, T-156, T-157 (needs-playtest)

## 2026-10-17: Trick prototype round 3: tilt feedback and wall grinds
- Decision or change: the board asked for the car to tilt slightly toward the held arrow key while on the ground, and for wall grinds: land near a wall's edge after a trick to lock into a grind across the wall (slightly diagonal), sliding along it and slowing, with sparks; Space (new jump key) or another trick exits, keeping the speed along the wall. The grind counts as a trick. Tickets T-158 (text), T-159 (tilt and grind, on top of `playtest/tricks`), T-160 (the grind's card). The roll art choice (T-157) is still open.
- Documents touched: `docs/drifting.md`
- Tasks: T-158, T-159, T-160 (new)

## 2026-10-17: The grind's card text is done
- Decision or change: T-158 passed QA and is merged: the grind's card says GRIND!. T-160 is unblocked. The long GDD is regenerated with the round 3 decisions.
- Documents touched: `docs/long-gdd.md`, `docs/short-gdd/README.md`
- Tasks: T-158 (done), T-160 (open)

## 2026-10-17: T-149 done: the status guard closes the gaps found
- Decision or change: the board chose to merge T-149 as built. It found eleven ways an agent could change a ticket's status or QA count without the status script (a repeated header line, other path spellings, wildcards, running commands from inside the tickets folder, the script's name in a comment, a split field name, inline code, an undecodable file, a hand edit then a commit) and closes them, with a test each. The status script now records every state it writes (`.board/blessed-states.jsonl`); commits and the script refuse a ticket whose guarded lines differ from that record. A ticket-header merge conflict fixed by hand must be finished through the status script. Still open: an agent editing the guard's own files. QA round 1 passed; all three test sets passed on the merge. Interim protection until the new studio's ticket system (`C:\game-studio`) replaces it. While committing this merge, the new guard refused a commit command whose text only mentioned the guarded field names (a false refusal); the board chose to reword and commit.
- Documents touched: the tasks README
- Tasks: T-149 (done)

## 2026-10-17: Tilt feedback and wall grinds ready to play
- Decision or change: T-159 (the car tilts toward the last held arrow key on the ground; wall grinds after a trick, at 70 degrees to the wall, slowing 4 units/s each second, with sparks; Space or a trick to leave, keeping the speed along the wall; a 30-unit low wall to try it on) and T-160 (the GRIND! card) passed QA and are in the playtest build `playtest/tricks`. Waiting for the board's playtest; the roll art choice (T-157) is still open.
- Documents touched: none on master yet (`docs/drifting.md`, `game/README.md` on the task branches)
- Tasks: T-159, T-160 (needs-playtest)

## 2026-10-17: T-161 done: the status guard stops refusing the merge routine
- Decision or change: after T-149 the guard refused worktree cleanup (the branch name held the guarded field name; `git merge-base` wasn't counted as read-only) and text that only named the guarded fields (a heredoc into the timeline). The board asked for a quick fix. Heredoc text, redirects into plain files, `if ... then` wrappers and more read-only git commands are now allowed; every step of the Project Lead's merge routine has a test; T-149's tests all still pass. QA round 1 passed; all three test sets passed on the merge. Residual risk QA reasoned about but did not test: a heredoc fed to `bash` or `sh` containing an edit of a ticket. While working, the builder hit two false refusals and made those edits with the file editing tool instead, which goes against the rule never to route around a refusal; reported to the board.
- Documents touched: none
- Tasks: T-161 (done)

## 2026-10-18: Game work on hold; the goal runner (course assignment)
- Decision or change: the board put all game work on hold for a course assignment and asked for a clean repo. Nothing was merged, cancelled or deleted: the trick prototype's tickets (T-151 to T-160) stay in their task folders and the `playtest/tricks` build (unsaved result notes were committed on their branches), and the vision draft moved off `master` to the branch `hold/vision-draft`. Still open for later: the roll art for T-157, the grind agent's workaround of a false refusal, the studio repo's specs (`C:\game-studio`), and the elevation prototype and level editor (no tickets yet). The assignment: a goal-oriented code agent, the **goal runner** (`tools/goal_agent/`). The board gives it a goal (one feature, or the whole short GDD); it ranks sub-goals (priority scoring), writes only the missing tickets after checking the existing tickets and code (gap detection), builds them with the agents and QA (code writing), and rescans after every ticket until the goal's own criteria pass (iteration loop). The board's rules for a run: the goal is its go for PixelLab up to an art cap it sets per goal, no sample review, still one generation round per task, QA passing counts as done for the runner, and one playtest of the goal's build at the end before anything reaches `master`. The board approved the plan (PR-style description) and the one-line addition to `CLAUDE.md`. The coursework folder is `course-material/goal-oriented-code-agent/`.
- Documents touched: `docs/working-with-the-board.md`, `CLAUDE.md`, `tasks/README.md`, `tasks/_TEMPLATE.md`, `README.md`, `course-material/README.md`, `course-material/goal-oriented-code-agent/README.md`
- Tasks: T-162 (open), T-163 (blocked, waits on T-162)

## 2026-10-18: T-162 done: goal runner part 1 (goal file, priority scoring, gap detection)
- Decision or change: `tools/goal_agent/` now plans a goal: `run.py start "<goal>"` ranks sub-goals by code (what others wait on first, then value), checks them against every ticket and the code, reuses tickets already in flight, writes only the missing tickets (refusing any that break the studio's rules), and commits the goal file in `goals/` and its tickets. `run.py status` shows a goal. The goal file also holds open questions the docs leave unanswered. A reused ticket gets the goal's id only when its branch isn't open and it has no goal yet, and isn't claimed. 49 new tests with a fake Claude; QA round 1 passed all 7 criteria; all three test sets passed on the merge. Building and the loop follow in T-163.
- Documents touched: `tasks/README.md`
- Tasks: T-162 (done), T-163 (open)

## 2026-10-18: T-163 done: goal runner part 2 (building and the iteration loop)
- Decision or change: `run.py start "<goal>"` now plans and then builds: the goal's build is `playtest/<goal id>`; each ticket gets its own worktree from it, its agent and QA run headless (`claude -p`, the ticket's model, QA on sonnet, session name `Goal-<goal id>`), statuses move only through the status script, a first QA fail goes back on opus, a second is flagged, and passed tickets are merged into the goal's build. After every ticket the runner rescans and runs gap detection again; when every ticket has passed, QA checks the goal's own criteria, and all passing makes the goal `ready-to-play`. Pauses (each with its kind in the goal file): iteration cap (default 20), art cap, a flagged ticket others depend on, the same gap or criterion twice with no progress, any refusal, a refused command, a merge conflict, waiting on a reused ticket another session owns, two refused draft sets. `resume` rebuilds the state from the files; `--plan-only` only plans. The status script now lets a ticket start when a dependency is `needs-playtest` in the same goal, and a goal ticket's move to `needs-playtest` unblocks that goal's tickets; nothing changed outside a goal. 34 new tests (293 tools tests); QA round 1 passed all 7 criteria; all three test sets passed on the merge. Not yet tried: a real run with Claude; the task board's Builds tab may not show `playtest/<goal id>` folders. The builder met four false refusals from the guard; for two heredoc edits it made the same edits with the file editing tool instead, which goes against the rule never to route around a refusal (reported to the board).
- Documents touched: `tasks/README.md`, `docs/working-with-the-board.md`, `course-material/goal-oriented-code-agent/README.md`
- Tasks: T-163 (done)

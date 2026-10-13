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

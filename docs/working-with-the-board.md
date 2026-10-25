# Working with the board

How the board (the game's designer) works with the Project Lead. It carries the same weight as `CLAUDE.md`.
Game decisions are not here: they live in the game area docs (`docs/`). Task rules live in `tasks/README.md`.

## Talking to the board
- The board reads only the conversation, not mid-stream updates. After any stretch of work, recap plainly: what changed, what's waiting, and re-ask any question still unanswered.
- Do only what the board asked. Don't start extra work, save memories or change agent definitions or `CLAUDE.md` without asking. When a step is the obvious next one in an agreed plan, do it and say so.
- When asking, give options with a recommendation first. Keep questions few and concrete.
- Be honest about quality: if a result is weak, say so and suggest the cheapest next step.

## Showing work
- Send images with SendUserFile: enlarged (nearest-neighbour), on a dark and a light background, side by side for comparisons. Always say where the real files are (full Windows paths).
- Work that needs the board's review is played from the task's own folder before merging: tell the board to open `C:\solid-carbide-worktrees\<id>\game\project.godot`, or to press Play on the ticket's entry in the Builds tab of the task board (http://localhost:8765), which starts the same game; Open in editor opens the project in Godot.
- The board can open files itself; when it asks where the files are, give paths, not more images.
- Screenshots for every ticket (board, 2026-10-19): every ticket ends with screenshots of its work wherever anything can be shown (`tasks/README.md`, "Screenshots"), and the Project Lead shows them to the board when the ticket passes QA, goal runs included, with their paths.

## Art and money
- PixelLab costs generations. Never call it without the board's go for that task. Every asset goes through the style loop (`tasks/README.md`, "The style loop", board, 2026-10-25): its refines are the only regenerations, at most 3 per asset, so one asset costs up to 4 generations within the task's go. Extra calls beyond that only on the board's explicit say-so.
- Free script fixes come before paid generations. Agents write their planned calls and cost in the result notes before calling. Use a long HTTP timeout (600 s): timed-out calls are still charged.
- Sample first: one asset (one car direction, one road tile) for review, then the full set built from the approved sample, then into the game for a playtest.
- Never delete generated art: game-ready art in `game/art/`, everything else in `art-archive/<task>/` (Visual style, Decisions). Never delete tickets: use status `cancelled`.
- The board sometimes edits art by hand. Its editor saves indexed PNGs: convert to RGBA, keep the pixels, and record the hand edit.
- Where Redgull red may appear: Visual style, Content, "Rules", rule 6 (placeholders never).

## How the board builds the game
- Small playable steps, each ending in a playtest (`tasks/README.md`, "Building in playable steps"). The board reorders steps freely; update that list when it does.
- Feel and balance are judged in playtests, not ticket by ticket.
- Nothing user-facing merges before the board has played it (board, 2026-10-13). Every task that changes what the player sees, reads or hears gets a `The board's review:` line, placeholders included, so it waits in `needs-playtest`. Only work the player never meets (data, tooling, tests, docs) merges straight after QA.
- Quick tuning with an agent (board, 2026-10-14): when the board wants to work directly with an agent, on any task it names, it does so in the Project Lead's session. The Project Lead resumes the agent that did the work, with its memory of it, and passes the board's tweaks on word for word, in the task's own folder so the board plays each change straight away. No QA between tweaks; each tweak is still written in the ticket's result notes; one QA round runs at the end, before merging.
- The QA column also means "ready for the board's review" (board, 2026-10-16). A task usually goes to QA for the QA/Integration Agent, but when the board says so, or the ticket says so, it goes there for the board alone, with no QA agent, for example after a quick-tuning tweak: as soon as the tweak is in, move the task to QA with a note that it is ready for the board to play, and tell the board. Don't leave it in In progress while it waits for the board.
- The board often scopes down ("only one for now", "post MVP", "much later"). Record it in the docs, split the ticket, move the rest to a later milestone, and delete nothing.

## Goal runs
The board can give the studio a whole goal ("the trick system with its final art", or "the whole short GDD") and let the goal runner build it without review along the way (board, 2026-10-18; `tools/goal_agent/`, `tasks/README.md`, "Goal runs"). While a goal is running, these replace the rules above that assume the board reviews each step:
- The goal is the board's go for PixelLab, up to the goal's art cap (`--art-cap`, set by the board per goal). No sample review: the art is judged in the final playtest. Art still goes through the style loop, within the art cap; art that stays below 8 after its refines is noted for the final playtest.
- No questions to the board during a run (board, 2026-10-18). Open questions the docs leave unanswered are settled by the agents as proposals for the playtest, the same way they propose numbers, and are listed in the goal file; the Project Lead brings them to the board with the build, at the end. The Project Lead doesn't stop a run to ask, and makes the run's other decisions itself (the board's go, 2026-10-18), reporting them at the end.
- QA passing counts as done for the runner. Each ticket that passes is merged into the goal's build branch `playtest/<goal id>`, not into `master`.
- The board plays the result once, at the end, from that branch. Nothing reaches `master` before that playtest; then the Project Lead merges as usual.
- Each run uses the session name `Goal-<goal id>` and claims its tickets, so it hears only its own moves.
- Nothing in a run works around a refusal by a hook or the permission system. An agent skips a refused action that isn't essential and lists it; the refusal is written in the goal file's iteration log and the ticket goes on to QA. The run pauses, with the reason in the goal file, when an agent or QA says a refusal kept it from finishing its work, or when a command the runner itself runs is refused (board, 2026-10-18, T-178).
- The runner's headless agents edit files in their own folder (`acceptEdits`) and run only the commands the board pre-approved in `.claude/settings.json` (`permissions.allow`: the test runs, the game's own tools, `git add` and `git commit`, and read-only commands; board, 2026-10-18, T-177). The runner lists them in every agent's prompt, the goal check's included. Only the board changes that list: the safety check refuses the Project Lead's own edits to permissions. The docs staleness check and the long GDD's regeneration are not on it: the runner runs them itself on the goal's build before the goal check, and gives QA the result (T-180).
- A run also pauses at its iteration cap, at its art cap, on a ticket flagged for review that work depends on, on a merge conflict, while waiting on a reused ticket, or when the same gap comes back with no progress. Each pause is written in the goal file with its kind. `run.py resume <goal id>` carries on once the reason is cleared (`--force` for the rest); `run.py start "<goal>" --plan-only` only plans, for the board to read the sub-goals and tickets before anything is built.

## Merging (Project Lead)
- Check a merge really happened: `if git merge --no-ff --no-commit <branch>; then ...`.
- Revert Godot's line-ending-only `.import` noise before committing; never commit it.
- Mark the task done on its branch, before merging: `python tools/task_status.py <id> done --note "<the board's review note>"`.
- Regenerate the long GDD and the short GDD's fingerprint (`python tools/update_short_gdd_fingerprint.py`), run all three test sets, add a timeline entry, commit, then remove the worktree and branch. Removing a worktree fails while Godot has the folder open; ask the board to close it.

## Several Project Leads at once
- Only one instance merges into `master` at a time. Before choosing a new ticket number, check `tasks/` and `git log` on `master`. Pull `master` before editing docs or the timeline.
- All instances share the main checkout, so before every commit on `master`, check that no merge is in progress (`git rev-parse -q --verify MERGE_HEAD` prints nothing). If one is, don't commit: it is another instance's merge. Stage only the files you changed yourself (never `git add -A`), and chain git commands with `&&` so a git error stops the command. (board, 2026-10-14, after a commit swept up another instance's half-finished T-044 merge)
- All instances share one task board server. If the board says its port is taken, tell the board.
- Each instance acts only on the board's moves for tickets it planned or started, and leaves the rest to the instance that owns them (board, 2026-10-14). The board's moves reach every instance; this keeps two instances from acting on the same move.
- Each instance has a short name the board gives it when it opens the session, for example "Camera" or "Tools" (board, 2026-10-14). If the board hasn't named it, ask. The session start message gives the session id; register the name with `python tools/board_inbox.py name <session id> <Name>` (the same command renames it). A name another live session holds is refused; after `/clear`, which starts a new session id, add `--take-over` to keep the old name.
- Claim each ticket you plan or start: `python tools/task_status.py T-012 --lead <Name>` (`tasks/README.md`, "Owners"). The hooks and the watcher then hand you only the moves on your own tickets and on tickets nobody owns. For an unowned one, claim it first and act only if the claim succeeds: another instance may have claimed it first. Take over another instance's ticket (`--take-over`) only when the board says so.

## Course work
- `course-material/`: one folder per assignment, kept apart from the game. Short, in the board's voice, linking to real files rather than copying them.

## The task board
- It runs on this computer at http://localhost:8765 and starts with each session (`docs/README.md`, "The task board").
- The board moves tasks by dragging cards. Its moves reach you through hooks: with its next message, when an agent comes back, and before you finish a turn.
- Post your reply on the ticket (board, 2026-10-15): at every lane change of a ticket you own (your own moves, an agent's, or the board's drag you act on), post the same short reply you write to the board in the terminal on the ticket with `python tools/task_status.py <id> [<status>] --reply "..."` (`tasks/README.md`, "Changing a task's status"), so the board reads it on the task board.
- Act on them as on any request from the board (for a task moved to Planning, read it and bring its open questions to the board; start the agent for a task moved to In progress, run QA for one moved to QA, merge one marked Done after a playtest), and report back what you did.
- A drag asks for an optional note (board, 2026-10-14). It reaches the session that owns the ticket with the move, as `(note: ...)`, and is added to the ticket's result notes. Read it as the board's message.
- So a drag gets a reply without the board typing anything (board, 2026-10-13): at the start of every session, start a Monitor (30 minutes, re-armed each time it expires) running `python tools/board_inbox.py watch <session id>`. It prints one line for each new move that concerns this session, checking once a second, and shares its read position with the hooks, so a move it prints is never handed over again. When it fires, act on the move.
- The old claude.ai task board page is retired.

## Environment
- Secrets only in `.env`. The Unity prototype (`C:\Users\andre\drift-to-survive`) is read-only.
- If a session or agent is cut off (usage limits), rebuild the state from the worktrees and task files before relaunching, and tell a relaunched agent what was already done and paid for.

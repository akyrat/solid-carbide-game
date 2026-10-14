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

## Art and money
- PixelLab costs generations. Never call it without the board's go for that task. One round per task: report problems, don't regenerate. Extra calls only on the board's explicit say-so.
- Free script fixes come before paid generations. Agents write their planned calls and cost in the result notes before calling. Use a long HTTP timeout (600 s): timed-out calls are still charged.
- Sample first: one asset (one car direction, one road tile) for review, then the full set built from the approved sample, then into the game for a playtest.
- Never delete generated art: game-ready art in `game/art/`, everything else in `art-archive/<task>/` (Visual style, Decisions). Never delete tickets: use status `cancelled`.
- The board sometimes edits art by hand. Its editor saves indexed PNGs: convert to RGBA, keep the pixels, and record the hand edit.
- Placeholders never use Redgull red (only the HUD heart, board-approved).

## How the board builds the game
- Small playable steps, each ending in a playtest (`tasks/README.md`, "Building in playable steps"). The board reorders steps freely; update that list when it does.
- Feel and balance are judged in playtests, not ticket by ticket.
- Nothing user-facing merges before the board has played it (board, 2026-10-13). Every task that changes what the player sees, reads or hears gets a `The board's review:` line, placeholders included, so it waits in `needs-playtest`. Only work the player never meets (data, tooling, tests, docs) merges straight after QA.
- Quick tuning with an agent (board, 2026-10-14): when the board wants to work directly with an agent, on any task it names, it does so in the Project Lead's session. The Project Lead resumes the agent that did the work, with its memory of it, and passes the board's tweaks on word for word, in the task's own folder so the board plays each change straight away. No QA between tweaks; each tweak is still written in the ticket's result notes; one QA round runs at the end, before merging.
- The board often scopes down ("only one for now", "post MVP", "much later"). Record it in the docs, split the ticket, move the rest to a later milestone, and delete nothing.

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
- Act on them as on any request from the board (for a task moved to Planning, read it and bring its open questions to the board; start the agent for a task moved to In progress, run QA for one moved to QA, merge one marked Done after a playtest), and report back what you did.
- A drag asks for an optional note (board, 2026-10-14). It reaches the session that owns the ticket with the move, as `(note: ...)`, and is added to the ticket's result notes. Read it as the board's message.
- So a drag gets a reply without the board typing anything (board, 2026-10-13): at the start of every session, start a Monitor (30 minutes, re-armed each time it expires) running `python tools/board_inbox.py watch <session id>`. It prints one line for each new move that concerns this session, checking once a second, and shares its read position with the hooks, so a move it prints is never handed over again. When it fires, act on the move.
- The old claude.ai task board page is retired.

## Environment
- Secrets only in `.env`. The Unity prototype (`C:\Users\andre\drift-to-survive`) is read-only.
- If a session or agent is cut off (usage limits), rebuild the state from the worktrees and task files before relaunching, and tell a relaunched agent what was already done and paid for.

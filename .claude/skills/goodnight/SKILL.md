---
name: goodnight
description: The board is going to sleep. Ask any last open questions in one go, then work through the night with the board's explicit approval for everything needed, so a playtest build is ready in the morning.
---

# Goodnight (board, 2026-11-08)

The board is going to sleep and expects work ready to playtest on waking. The board gives explicit approval for everything needed to finish the work in progress: starting, resuming and QA-ing tickets, merging approved work, building playtest branches, and PixelLab within each ticket's existing cap. Pushing to itch.io, deleting tickets or art, changing agent definitions or permissions, and anything a hook refuses stay off-limits.

1. **Last questions, once.** Gather every open question across the tickets you own. Ask them all in one AskUserQuestion call, each with your recommendation first. If the board said it can't answer (or doesn't within the turn), take your top recommendation for each and write the choice in the ticket's notes.
2. **Plan the night.** List what's in flight and what each needs to reach the board's playtest. Merge only what the board already approved, one merge at a time (never start a merge while another is testing; set `GUT_TIME_LIMIT=3600` when agents are also running tests).
3. **Usage limits.** If an agent or you hit a usage limit, schedule a one-shot CronCreate a few minutes after the reset with a resume prompt that lists every ticket's state and next step, so work carries on unattended.
4. **Work through it.** Check every agent's result yourself before counting it (diff, tests, a launch, screenshots). User-facing work ends in `needs-playtest`; put it together into one morning playtest branch (`playtest/<date>-morning`) where the pieces belong together, and keep separate playtests separate.
5. **Morning note.** End with a short recap for the board: what's ready to play and where (folders and the launch command), every decision you made for it, what's still running, and anything that failed.

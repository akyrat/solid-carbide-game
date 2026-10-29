# Token spend: why the HUD batch's hand-backs stayed long (2026-10-29)

Written for T-359, from `docs/token-spend/after-2026-10-29.md`, which found subagent reports at 24.6% of the Greenbull session's weighted context against 8.8% in the Tokens session, although T-343 asks every agent to hand back one short line. Analysis only: nothing in the agent definitions or rules was changed. The fixes at the end are proposals for the board.

## Read this first

- The agents mostly did what T-343 asks. In Greenbull's session the 29 hand-backs carry on average **266 characters of the agent's own words** (limit: about 300). Only 6 were over 300, by 263 characters in all (longest 377).
- What arrives in the main session is about 1,470 characters per hand-back, because the harness wraps every hand-back in a fixed frame of **1,207 characters** (a warning that the text is model output, and a closing paragraph). The frame is 82% of each hand-back. It is not under the agents' control.
- Two more harness texts sit in the same "subagent reports" category: a **launch acknowledgement** (1,071 characters on average) each time an agent is started in the background, and a **task notification** (877 characters on average) after 7 of the 29 hand-backs.
- The category is also mislabelled: of Greenbull's 86,903 characters counted as "subagent reports", 30,628 (35%) are not subagent results at all (launch acknowledgements, messages from the Tokens session, background-command notices). Subagent results are 56,275, of which the agents' own words are 7,845 (9% of the category).
- Greenbull's higher share comes from the count, not the length: 43 results against 13 in the Tokens session, at 1,309 against 1,470 characters each. The biggest saving on offer is running agents in the foreground (up to about 53,000 of the 86,903 characters), at the cost of the Project Lead waiting; see "Proposed fixes".

## How it was measured

`python tools/hand_backs.py --session 0a239fb3 --from 2026-10-28T03:55:00Z --to 2026-10-29T01:10:00Z` (and `--session 2c104619`; `--out FILE` writes it). It streams the main session's transcript, same layout, range rule and character counting as `tools/token_report.py`, and lists every subagent result that came back: time, subagent type, characters, delivery kind, the agent's own words, whether the Agent prompt asked for a one-line hand-back, and the first 80 characters of the prompt. The delivery kinds:

- **SubagentHandback**: a peer message headed "[Subagent hand-back]": the final report of a background agent, in the harness frame.
- **Agent tool result**: the Agent tool's own result, when the agent ran in the foreground. It is the report with no frame.
- **task notification**: the notice that an agent stopped. "(pointer)": it only says the report came as a message. "(failed)": the agent was stopped, here by the usage limit at 04:00Z on 2026-10-28, with a long error text.

"Asked for one line" is a text match on the prompt (one line, one short line, under or about N characters). Items token_report.py counts as subagent reports but are not results are listed apart: launch acknowledgements, messages between the two Project Lead sessions, and notices about background commands. The script's totals agree with token_report.py's `subagent reports` characters to the character for the same range: Greenbull 56,275 + 30,628 = 86,903, Tokens 19,114 + 18,999 = 38,113 (both match).

## Greenbull (0a239fb3)

Range 2026-10-28T03:55:00Z to 2026-10-29T01:10:00Z. 43 subagent results, 56,275 characters, of which the agents' own words 7,845.

By subagent type:

| type | results | characters | average | share | own words | prompt asked for one line |
|---|---|---|---|---|---|---|
| qa-integration | 28 | 35,274 | 1,259 | 62.7% | 4,451 | 28 |
| ui | 10 | 14,078 | 1,407 | 25.0% | 2,347 | 10 |
| asset-generation | 4 | 5,444 | 1,361 | 9.7% | 775 | 1 |
| game-loop | 1 | 1,479 | 1,479 | 2.6% | 272 | 1 |

By delivery kind:

| kind | results | characters | average | share | own words | prompt asked for one line |
|---|---|---|---|---|---|---|
| SubagentHandback | 29 | 42,724 | 1,473 | 75.9% | 7,721 | 27 |
| task notification (failed) | 7 | 7,411 | 1,058 | 13.2% | 124 | 6 |
| task notification (pointer) | 7 | 6,140 | 877 | 10.9% | 0 | 7 |

Counted by token_report.py as subagent reports, but not results:

| kind | items | characters |
|---|---|---|
| launch acknowledgement | 18 | 19,278 |
| cross-session peer message | 9 | 8,434 |
| background command notice | 7 | 2,916 |

All 40 results from qa-integration, ui and game-loop agents had a prompt that asked for one line (typically "Hand back ONE line under 300 characters: pass/fail count, new status and the test counts."). The 3 that did not ask are asset-generation hand-backs for T-325, whose prompt predates the rule; they came back at 249 to 255 own characters anyway.

## Tokens (2c104619)

Same range. 13 subagent results, 19,114 characters, of which the agents' own words 6,502.

| type | results | characters | average | own words | prompt asked for one line |
|---|---|---|---|---|---|
| general-purpose | 9 | 12,656 | 1,406 | 4,208 | 9 |
| qa-integration | 4 | 6,458 | 1,614 | 2,294 | 4 |

| kind | results | characters | average | own words |
|---|---|---|---|---|
| SubagentHandback | 7 | 13,626 | 1,946 | 5,177 |
| task notification (failed) | 3 | 2,757 | 919 | 116 |
| task notification (report) | 2 | 1,816 | 908 | 294 |
| Agent tool result | 1 | 915 | 915 | 915 |

Not results: launch acknowledgements 5 (5,355), cross-session peer messages 11 (9,619), background command notices 11 (4,025).

The Tokens session's agents are the ones that wrote long reports (two hand-backs of 2,043 and 1,783 own characters), yet its share is low: it got 13 results, Greenbull 43, and the frame, acknowledgement and notice cost is per agent. The one foreground result (915 characters, a general-purpose agent) is the report alone: no frame, no acknowledgement, no notice.

## The ten longest results in Greenbull's session

All ten are SubagentHandbacks. Each is 1,479 to 1,584 characters, of which 1,207 is the harness frame and 272 to 377 the agent's own words. The longest is only 7% longer than the average one, so there is no outlier to fix.

| # | time (UTC) | type | characters | own words | prompt asked | cause |
|---|---|---|---|---|---|---|
| 1 | 10-28 12:28 | qa-integration | 1,584 | 377 | yes | Integration job. Harness frame, and the agent ran 77 characters over the ask |
| 2 | 10-28 14:08 | ui | 1,581 | 374 | yes | T-338 hearts. A resumed agent (second hand-back of agent a8fc2e44): the frame came again, and 74 over the ask |
| 3 | 10-28 07:09 | qa-integration | 1,561 | 354 | yes | Integration job. Harness frame, 54 over the ask |
| 4 | 10-28 17:11 | qa-integration | 1,548 | 341 | yes | Integration job, a resumed agent (a1575a33's second hand-back); frame again, 41 over |
| 5 | 10-28 13:56 | qa-integration | 1,523 | 316 | yes | T-351 QA. Harness frame, 16 over |
| 6 | 10-28 06:42 | qa-integration | 1,508 | 301 | yes | T-333 QA. Harness frame; own words at the limit |
| 7 | 10-28 06:47 | qa-integration | 1,491 | 284 | yes | T-340 QA. Harness frame; own words within the ask |
| 8 | 10-28 12:01 | qa-integration | 1,488 | 281 | yes | T-334 QA. Harness frame; within the ask |
| 9 | 10-28 20:05 | qa-integration | 1,480 | 273 | yes | T-351 final QA. Harness frame; within the ask |
| 10 | 10-28 11:23 | game-loop | 1,479 | 272 | yes | T-334 build. Harness frame; within the ask |

Cause summary: ten of ten are the harness frame; two are also resumed agents (the frame is paid again per hand-back); six are 1 to 77 characters over the "about 300" ask, which is the only part an agent could shorten. None is a prompt that did not ask, an agent that ignored the ask (the longest own-words overrun is 77 characters), or a background notice repeating the report: the notices say "delivered to you as a message... not repeated here". Pointer notices are a separate 877 characters, after 7 of the 29 hand-backs.

Resumed agents overall: 6 of Greenbull's 29 hand-backs came from an agent that had been sent a message (quick tuning and re-checks); each paid the 1,207-character frame again, 7,242 characters together.

## What the definitions and tasks/README.md ask

- `tasks/README.md`, "Handing back" (board, 2026-10-28, T-343): the full report goes in the ticket's result notes; the hand-back is one short line, about 300 characters at most (ticket id, done or blocked, what the Project Lead must act on); tests run in the foreground and no background job is left running (a finished agent with one wakes up and re-sends its hand-back); the ticket is committed before handing back.
- All 12 agent definitions in `.claude/agents/` carry the same "Handing back" bullet pointing to that section. The goal runner's agent and QA prompts carry it too (T-343).
- Nothing in the definitions or the README says how the Project Lead should start an agent (background or foreground), and nothing mentions the harness frame, the launch acknowledgement or the task notice. T-343 merged at 02:31Z on 2026-10-28, before this range starts; the agents in this range were bound by it.
- The Project Lead's prompts repeat the ask for QA, ui and game-loop; asset-generation prompts reused from before the rule did not.

## Proposed fixes

Proposals only; the board decides. Savings are characters of Greenbull's 86,903 in the range, from this analysis (they are measured, not forecast, except where marked as an estimate).

1. **Start QA agents in the foreground** (no `run_in_background`) when the Project Lead has nothing to do while QA runs. A foreground result is the report alone: no frame, no launch acknowledgement, no pointer notice. QA agents: frames 18,105 + acknowledgements 11,781 + pointer notices 5,272 = **35,158 characters (40% of the category)**. The cost is that the Project Lead waits, and parallel QA of many tickets at once would become serial; the saving rests on one observed foreground result (Tokens, 915 characters, the report only).
2. **Do the same for every agent the Project Lead waits on anyway** (build agents as well as QA): upper bound **53,179 characters (61%)** (frames of the non-resumed hand-backs 27,761, acknowledgements 19,278, pointer notices 6,140). Not realistic for work run in parallel with the board's playtest.
3. **Group QA of several tickets in one agent** (one run for a batch of tickets that touch the same area, as the three integration jobs already did): each agent avoided saves about 2,500 characters (frame 1,207, acknowledgement 1,071, a quarter of a pointer notice). Estimate: 8 fewer QA runs in this batch, **about 20,000 characters**. Cost: QA's per-ticket independence and a longer single run.
4. **Batch the board's quick-tuning tweaks into one resume** instead of resuming an agent per tweak: each resume saved is 1,207 characters. The 6 resumed hand-backs held **7,242 characters** in frames; at most a few of them could be merged, so the realistic saving is a fraction of that. The board's rule (resume the agent per tweak) would have to be relaxed.
5. **Shorten the agents' own words** below 300: saves **263 characters**. Not worth a rule.
6. **Make token_report.py say what is in "subagent reports"**: split it into subagent results, launch acknowledgements, cross-session messages and background-command notices. Saves nothing, but corrects the reading: 30,628 characters (35%) of Greenbull's category are not subagent results, so its weighted share would be about 16% rather than 24.6% (estimate, assuming the same weighting).
7. **Nothing to do about the 7 "failed" notices** (7,411 characters) of the usage limit at 04:00Z: the harness text is long and cannot be shortened, and the cause is outside the project.

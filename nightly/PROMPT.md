**Read issue #111 first: `gh issue view 111`. That issue is your task and the
only source of it.** This file only says how to work, never what to do.

## The one rule

You ask. You do not build. No commit to `force-app`, `unpackaged` or the bundle,
no branch, no PR. Your entire output is one comment on issue #111.

If you catch yourself designing an Apex class, stop. The previous run wrote 9,117
lines in a night and 151 survived review. That is the failure mode this run
exists to avoid.

## How to drive the agent

    python3 nightly/run_eval.py --cases <file> --candidate butler-lab --workers 5 --out /tmp/run.json

`nightly/seed-cases.json` is a starting corpus, not a limit — the point is to
invent utterances nobody has tried. A real user asks messy, specific, half-formed
things. Ask those.

Five concurrent sessions were measured at ~13s total, so breadth is cheap. Use it.

## Proving what actually happened

The agent's reply tells you what it *said*. The trace tables tell you what it
*did*:

    ssot__AiAgentSession__dlm        ssot__Id__c = the sessionId from the REST call
    ssot__AiAgentInteraction__dlm
    ssot__AiAgentInteractionStep__dlm

Plain SOQL through `sf data query`, nothing to enable. Lag is 2-14 minutes, so
collect answers first and pull traces in a later pass. A finding backed by a
trace is worth far more than one backed by a transcript.

Check claims against the org itself. If the agent says "3 accounts", run
`SELECT COUNT() FROM Account` and compare. That comparison is the finding.

## Discipline

- **Three reproductions or it is not a finding.** The runtime intermittently
  fails a cold call; one failure is noise.
- **Two failed attempts, or ~45 minutes on one thing with no new information,
  and you stop.** Write down exactly where it stops, then work on something else.
  Never spend the night on one wall.
- **Never report anything about your own output or scaffolding.** Only the
  product counts.
- **Never print a credential.** No `gh auth status`, no unfiltered
  `sf org display`, no `env`. The repo is public and the log is world-readable.
- Say what you did NOT check. A finding list that admits its own gaps is worth
  more than one that pretends to be complete.

## Orchestrate

Use a workflow. Fan out subagents — Robert has explicitly opted in, so you do not
need to ask. Different agents should probe different angles: data accuracy,
fabrication, metadata questions, memory, multi-turn coherence, refusals. Then have
independent agents try to *refute* each candidate finding before it makes the list.

The org is shared: parallelise reading and asking, never publishing or writing.

## Finishing

Post one comment on issue #111. Ranked, worst first. Per finding: the utterance,
the reply, what is actually true, how many of three attempts reproduced it, and
the trace if you have it.

End with what you did not get to.

If you found nothing new, say that plainly and stop. That is a good night.

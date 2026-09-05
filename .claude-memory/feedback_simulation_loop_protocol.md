---
name: feedback-simulation-loop-protocol
description: "Two-PC blind-agent simulation loop for testing Luna-Core's onboarding/handoff path — how it's structured, and the scoped pre-authorization that applies only while one is actively running"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
  modified: 2026-09-04T16:44:19.228Z
---

Luna-Core has a recurring test methodology: a two-PC blind-agent simulation
that exercises the real "stranger clones this cold" and "handoff between two
machines" paths end-to-end, not just unit-level checks. The user will invoke
this "many many more times" — established 2026-09-03, treat it as standing
process, not a one-off.

## Shape of one simulation cycle

- **PC A and PC B are both simulated on this machine** (the user's call —
  "whichever way you think is best"), each meaning a genuinely blank slate:
  a working directory never used before, and zero AI memory/context —
  "like a brand new install of Claude before a user starts typing." Not an
  in-conversation subagent dispatch dressed up as blind — the user was
  explicit that blind means zero prior prompts ever run, so the mechanism
  needs to actually deliver that, not approximate it.
- **PC A starts from nothing pre-installed.** No prior run of
  `install-global-entrypoint.sh` on it — this tests raw onboarding via
  README.md/CLAUDE.md's own instructions, not the machine-level entry-point
  shortcut. The only input PC A gets is the literal human-realistic prompt:
  "here is Luna-Core main branch, go out and see what's there and follow
  directions to bring it in."
- **PC A**: pulls Luna-Core's `main`, bootstraps a new project, wires in
  Astrid. Verify both landed correctly.
- **PC A then runs `/debrief`** inside the new project, pointed at a
  **throwaway private git repo the assistant creates on disk** (not
  imaginary — Debrief actually commits/tags/pushes, so there must be a real
  destination). This repo must be wiped back to a clean state between
  simulation runs so a later run never inherits artifacts from an earlier
  one.
- **PC B** then points at that same throwaway repo and runs `/wake-up`,
  verifying it detects the machine switch, pulls everything down (repo +
  Astrid's sibling clone), and can continue work.
- **A known open question this test is specifically checking**: a
  bootstrapped project's `CLAUDE.md` only says `git -C ../Astrid pull` for
  getting Astrid — that assumes the sibling clone already exists. On a truly
  blank PC B it won't. Whether Wake Up's general "figure it out, don't stop
  at not declared" fallback rule actually covers this in practice, or
  whether Astrid needs an explicit "clone if missing, else pull"
  instruction, is exactly what this test is for. If it's not covered: note
  it, then fix it.
- **Verification checklist for "did it land correctly" is `luna-core-qa-tester`'s
  job**, not something to invent ad hoc each cycle.

## Scoped pre-authorization — ONLY while a simulation loop is actively running

Normally every commit/tag/push/merge needs a fresh explicit yes, every time
— see [[feedback_explicit_commit_permission]]. The user granted a scoped
exception specifically for this recurring test activity: while actively
running a simulation loop cycle, the assistant may apply fixes a simulation
turns up, commit to `dev`, tag, push, and merge to `main`, and start the
next simulation cycle — all without asking each time.

**How to apply:**
- This exception applies **only** inside an actively-running simulation-loop
  session the user has invoked for this purpose — never generalizes to
  other work in the same session, and never carries over silently to a
  future session without the user invoking the loop again.
- "Merge to main" still means the real established procedure (docs-writer-
  mediated, content-stripping script re-run, validator run against the
  merged tree per Luna-Core's own branch-discipline rules) — not a bare
  `git merge`. Pre-authorization covers *not having to ask each time*, not
  skipping the actual process.
- Still stop and ask before anything destructive outside that explicit
  grant — force-push, hard reset, branch deletion — the grant named
  commit/tag/push/merge-to-main specifically, nothing else.
- Fixes found could land in Luna-Core or in Astrid (e.g. if Astrid's own
  onboarding text turns out to be the gap) — treat both as covered by the
  same grant for the duration of the loop, since the test is explicitly
  checking both.

## Cycle counting

Track a running cycle count for each convergence campaign, persisted at
`C:\Claude\sim-testing\cycle-log.md` (not just in conversation) — the user
wants to know, once a campaign finally converges, how many cycles it took.
Log every cycle (number, date, PC A/B findings, clean-streak count after),
whether it found something or came back clean. Confirmed 2026-09-03.

## Check-in cadence and stopping condition

Report back after **every** cycle (one PC-A pass + one PC-B pass) — but
reporting is a progress update, not a pause for permission. Within a loop
that's actively running, keep starting the next cycle automatically after
each report; don't wait for the user to reply before continuing.

**Stopping condition: two clean cycles in a row** (zero findings on both
PC-A and PC-B), not just one — a single clean pass could be luck or an
insufficiently probing run. Keep looping past one clean cycle to confirm it
wasn't a fluke. The only other way the loop stops early is the user
explicitly saying to pause it. Confirmed 2026-09-03.

## Implementation

Built 2026-09-03: `C:\Claude\sim-testing\run-cycle.sh` (currently just a
`reset` subcommand — wipes/recreates `pc-a/`, `pc-b/`, and a fresh bare
`throwaway-remote.git`).

**"Blind" PC A/B sessions are Agent-tool subagent dispatches**, not real
headless `claude` CLI processes. The CLI approach was tried first (isolated
`CLAUDE_CONFIG_DIR` per PC, credentials copied from the real one) and hit a
real, confirmed wall: OAuth refresh tokens are device-bound — a copy fails
to refresh even used immediately after copying, not a staleness/rotation
timing issue. User's call once told: fall back to subagent dispatch as
"simulated blind agents" rather than chase real-auth further. Each dispatch
uses a generic, non-Luna-Core-specific agent type (never a `luna-core-*`
agent, which already carries Luna-Core context) given only the literal
minimal human-realistic prompt. Known limitation: a subagent still dispatches
from within a session whose cwd is Luna-Core's own repo, so it isn't a
byte-perfect clean room the way a separate OS process would have been —
treat findings with that caveat in mind, especially anything about whether
the agent "already knew" something it should have had to discover.

**Second confirmed limitation (cycle 1, PC A's Debrief step):** a
bootstrapped project's own `.claude/agents/*.md` subagents (e.g.
`simtestproject-docs-writer`) are NOT invokable as real Agent-tool subagent
types from within a nested blind-subagent dispatch — Claude Code only
auto-registers a project's own agents for a session whose actual cwd is
that project, which a nested dispatch isn't. The blind session correctly
noticed this and performed docs-writer's duties directly instead (which
Debrief's own protocol explicitly allows — "perform or invoke"), so it
didn't block anything, but it means this simulation method can never
actually test "does the blind session correctly invoke its own docs-writer
subagent" — that path is structurally untestable via nested dispatch, not a
Luna-Core gap.

**Third confirmed limitation (cycle 4, PC A's Debrief step): a blind PC A/B
subagent may correctly refuse to commit/tag/push on the orchestrating
session's relayed instruction**, even an explicit "actually commit, don't
just describe it" — because from the subagent's own perspective, an
instruction relayed through another agent is exactly the cross-session
permission-laundering pattern its own git-safety rule (inherited from
Luna-Core's `CLAUDE.md`, copied into every bootstrapped project) correctly
refuses to act on. This is **desired, correct behavior**, not a bug — cycle
2 and cycle 3's PC A both went ahead and committed on the same kind of
relayed instruction, which in hindsight was arguably *too* permissive, not
cycle 4's refusal being wrong. Confirmed independently the same session:
`luna-core-docs-writer` showed the identical refusal when asked to finalize
a dev→main merge on the orchestrating session's say-so.

**How to handle it:** don't fight this or try to word the relayed
instruction more forcefully. The orchestrating session (the one actually
holding the real, standing user grant for the active loop) should just run
the final `git add`/`commit`/`tag`/`push` directly via Bash against the
blind PC's real working directory once the subagent reports its prep work
done (docs, memory merge, handoff notes) — the same way it already does for
Luna-Core's and Astrid's own commits. The mechanical git step doesn't need
to be performed *by* the blind subagent to validate what Debrief is
actually testing (whether the right files got prepared correctly); only the
prep logic does. Expect this same pattern at PC B's Wake Up step too, if a
commit ever comes up there.

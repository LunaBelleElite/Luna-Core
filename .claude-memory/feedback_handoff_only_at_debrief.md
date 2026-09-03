---
name: feedback-handoff-only-at-debrief
description: "Don't rewrite handoff/HANDOFF.md after every mid-session milestone (e.g. each blind-test round) — it's for the Debrief protocol at session end, not a running log."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7ae81e10-1d7d-4657-9c9e-e57c816aac04
  modified: 2026-09-02T13:47:06.974Z
---

Don't update `handoff/HANDOFF.md` (or `STATUS.md`) after every mid-session milestone — e.g. don't rewrite it after each round of a testing loop just to note "round N done, round N+1 next."

**Why:** The user pointed out handoff exists for the Debrief protocol (session hand-off/wrap-up), not as a running log updated inline while still actively working the same session. If I already know the current state (it's live in this conversation), there's no need to persist it to handoff mid-stream — that file should reflect state at the point work actually pauses/ends, not every intermediate step.

**How to apply:** Only write/update `handoff/HANDOFF.md` and `handoff/STATUS.md` when actually running the Debrief protocol (session truly ending, computer switch, or explicit request) — not after each loop iteration, round, or subtask completes within an ongoing session. If updating it mid-session would genuinely help (e.g., real risk of losing context before a natural end point), it's fine to judge that it's useful — the user left room for that ("unless you find updating handoff useful") — but default to skipping it and rely on inline conversation state instead.

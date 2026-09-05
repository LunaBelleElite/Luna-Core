---
name: feedback-fable-manual-only
description: "SUPERSEDED 2026-09-04 — Fable is now the top subagent tier and may be dispatched by the assistant when it's genuinely the best fit; the old 'manual-only, never dispatch' rule no longer holds. Luna-Core's own CLAUDE.md still carries the old wording and needs reconciling."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7ae81e10-1d7d-4657-9c9e-e57c816aac04
  modified: 2026-09-05T00:19:14.356Z
---

**Corrected 2026-09-04.** The rule below (Fable manual-only, never dispatched
by the assistant) has been superseded by two things that agree with each
other:

1. The machine-global standing rules at `C:\Claude\CLAUDE.md` (created
   2026-09-04), which state plainly: **"The 'most capable' subagent tier is
   Fable, not Opus. Implementers stay on Sonnet unless the work says
   otherwise."** That file declares itself authoritative over memory files
   when they disagree — this memory is the one that needed correcting.
2. The user, directly, the same evening: "if Fable is deemed the best
   working model, go ahead and use it, even for agents. We have tokens for
   this week we can burn for it."

**How to apply now:**
- The candidate model set for routing is **{Sonnet, Opus, Fable}**. Fable
  is the top tier, reached for when the work genuinely warrants it — hard
  design/architecture, precision-on-first-pass spec writing, subtle
  debugging — not by default. Implementers stay on Sonnet unless the work
  says otherwise.
- The user's framing was budget-aware ("tokens for this week we can burn"),
  so Fable is appropriate when it fits *and* budget allows — this is a
  routing preference, not a mandate to escalate everything.
- Still name the agent and model out loud at every dispatch, as before.

**Open reconciliation:** Luna-Core's own repo-root `CLAUDE.md` ("Match model
to license tier and task" → point 1) still carries the OLD language ("Fable
is excluded from this rule — manual-only, never dispatched by the
assistant... a hard constraint"). That text now directly contradicts the
global rule and the user's stated preference. It's a real inconsistency in
a file every bootstrapped project inherits — worth raising with the user
for a deliberate fix, not silently editing during unrelated work.

---

## Original rule (2026-09-03), now superseded — kept for the evidence trail

The user reserves **Fable** for projects they personally decide need it, and invokes it themselves. **The assistant works with Sonnet and Opus only, and must never dispatch an agent on Fable.** This is a hard constraint, not a preference to weigh against task fit — it holds even on Max/Premium tiers where [[feedback_model_selection]] otherwise says "pick whichever model is best-suited, task by task."

**Why:** This session under-routed seven agent dispatches onto Sonnet because the recorded license tier said Business Standard (teams) when the account is actually Max 5x (personal) — see [[user_license_tier]], corrected 2026-09-03T04:35:00.000Z. Nothing in the project contradicted the stale tier, so it went unquestioned. The rule that fixes *that* failure (dynamic per-task routing across Sonnet/Opus) has a boundary the user drew explicitly: Fable stays out of the pool the assistant routes into, regardless of tier. The rule existing only in a machine-local memory bucket is what let drift like this happen unnoticed — recording it in the repo-root `CLAUDE.md` instead means every project bootstrapped from Luna-Core inherits the constraint directly, not just this one machine's memory.

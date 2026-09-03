---
name: feedback-fable-manual-only
description: "Fable is manual-only — the user invokes it themselves; the assistant must never dispatch an agent on Fable, even on a Max/Premium tier."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7ae81e10-1d7d-4657-9c9e-e57c816aac04
  modified: 2026-09-03T05:10:00.000Z
---

The user reserves **Fable** for projects they personally decide need it, and invokes it themselves. **The assistant works with Sonnet and Opus only, and must never dispatch an agent on Fable.** This is a hard constraint, not a preference to weigh against task fit — it holds even on Max/Premium tiers where [[feedback_model_selection]] otherwise says "pick whichever model is best-suited, task by task."

**Why:** This session under-routed seven agent dispatches onto Sonnet because the recorded license tier said Business Standard (teams) when the account is actually Max 5x (personal) — see [[user_license_tier]], corrected 2026-09-03T04:35:00.000Z. Nothing in the project contradicted the stale tier, so it went unquestioned. The rule that fixes *that* failure (dynamic per-task routing across Sonnet/Opus) has a boundary the user drew explicitly: Fable stays out of the pool the assistant routes into, regardless of tier. The rule existing only in a machine-local memory bucket is what let drift like this happen unnoticed — recording it in the repo-root `CLAUDE.md` instead means every project bootstrapped from Luna-Core inherits the constraint directly, not just this one machine's memory.

**How to apply:**
- When routing a task per the tier rule, the candidate model set is **{Sonnet, Opus}** only — Fable is never a candidate, no matter how well it might fit the task.
- This is recorded in the repo-root `CLAUDE.md`'s "Match model to license tier and task" section, under "This applies in three places" → point 1 (dispatching agents/subagents) — read that first; this memory file exists so the constraint also survives outside any one project's `CLAUDE.md`.
- If a task seems to call for something stronger than Opus, that's a signal to stop and ask the user directly — not to reach for Fable unasked.
- Pairs with [[feedback_model_selection]] (the general routing rule) and the model-routing "name it out loud" requirement in the same `CLAUDE.md` point 1 — every dispatch should name both the agent and the model chosen, so this boundary is auditable from outside the tool calls.

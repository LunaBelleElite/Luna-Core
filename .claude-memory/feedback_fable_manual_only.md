---
name: feedback-fable-manual-only
description: "Fable is manual-only — the user invokes it themselves; the assistant never dispatches agents on Fable. A temporary, budget-based exception was granted 2026-09-04 ('for now, tokens to burn this week, if it fits the proper need'); the standing rule is unchanged and Luna-Core's CLAUDE.md wording is correct."
metadata: 
  node_type: memory
  type: feedback
  modified: 2026-09-05T02:33:18.688Z
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
---

**Standing rule (2026-09-03, reaffirmed by the user 2026-09-04):** the user
reserves **Fable** for projects they personally decide need it, and invokes
it themselves. **The assistant works with Sonnet and Opus only, and never
dispatches an agent on Fable.** This is a hard constraint, not a preference
to weigh against task fit — it holds even on Max/Premium tiers where
[[feedback_model_selection]] otherwise says "pick whichever model is
best-suited, task by task." Luna-Core's repo-root `CLAUDE.md` ("Match model
to license tier and task" → point 1) states this rule and **is correct as
written**; do not "reconcile" it.

**Temporary exception, 2026-09-04 (evening):** the user said "if Fable is
deemed the best working model, go ahead and use it, even for agents. We have
tokens for this week we can burn for it," and later clarified: "the old rule
is correct for Fable is manual only. I authorized it for now since we have
some tokens we can burn if it fits the proper need." So:

- The exception is **scoped to this week's spare token budget and to work
  that genuinely fits Fable** (hard design, precision-on-first-pass spec
  writing, subtle debugging). It is not a new default and not a standing
  authorization. When in doubt, treat it as expired and ask.
- Even under the exception, Fable was found to be the wrong fit for
  voice-matched spec prose with the design already settled (Opus was right);
  and Fable hit its session rate limit mid-task once that evening, which is
  a real risk for anything that must not be cut off half-done.
- Name the agent and model out loud at every dispatch, as always.

**Correction trail:** an earlier version of this memory (2026-09-04, before
the user's clarification) wrongly declared the rule SUPERSEDED, citing the
machine-global `C:\Claude\CLAUDE.md` line "The 'most capable' subagent tier
is Fable, not Opus." That global line does not match the user's stated rule
and needs correcting by the user; this memory now records the rule the user
actually holds. Luna-Core's `CHANGELOG.md` `ver-1.0.0.3-dev` entry repeats
the wrong "Fable is now the top subagent tier" claim as a dated historical
note — superseded by this correction, not to be edited retroactively.

**Why the rule exists:** on 2026-09-03 a session under-routed seven agent
dispatches onto Sonnet because the recorded license tier was stale (see
[[user_license_tier]]). The fix for that — dynamic per-task routing across
Sonnet/Opus — has a boundary the user drew explicitly: Fable stays out of
the pool the assistant routes into, regardless of tier. Recording it in the
repo-root `CLAUDE.md` means every project bootstrapped from Luna-Core
inherits the constraint, not just this machine's memory.

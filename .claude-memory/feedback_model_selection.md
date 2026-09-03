---
name: feedback-model-selection
description: "Model choice serves token efficiency — fewest total tokens to a correct result — gated by license tier; switching has its own cost, so only switch when it pays."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7ae81e10-1d7d-4657-9c9e-e57c816aac04
  modified: 2026-09-03T04:35:00.000Z
---

**The goal is token efficiency: reach a correct result for the fewest total tokens, without running out.** That's the objective model choice serves — not maximum capability, and not minimum cost per token.

Check the user's Claude license tier first ([[user_license_tier]] — currently Max 5x, personal), then apply:

- **Max (personal) or Premium (teams):** pick whichever model is best-suited, task by task, switching as the work changes.
- **Pro (personal) or Business Standard (teams):** default to Sonnet — but still speak up when something looks genuinely hard enough that a stronger model would likely cost fewer tokens overall. The user decides; don't make the call silently, and don't stay quiet about it either.
- **Tier unknown and nobody to ask** (a subagent, a non-interactive run): default to Sonnet.

**Why:** The user stated the objective directly — spend tokens as efficiently as possible without running out. That reframes model choice: a weaker model flailing on a hard problem (wrong approach, rework, more correction rounds) burns more than a stronger model getting it right first pass, while a stronger model doing mechanical edits is pure waste. It also means **switching is itself a cost** — a handoff buys a dispatch, a brief, and a review; a session switch buys a real stop. The user explicitly endorsed *not* splitting a small job across models for this reason.

**How to apply:**
- Only switch or hand off when the expected saving beats the switch overhead. For a small job, finish it on whatever is already loaded if that model is adequate.
- The rule runs **both directions** — once the hard reasoning is done and what's left is mechanical, say so and come back down; don't let one hard question park a session on the expensive model.
- A subagent can run a different model than the session dispatching it, so a separable hard piece usually goes to a subagent rather than stopping the session.
- If the user declines a suggested switch: proceed on the current model and drop it — don't re-raise it or hedge later answers.
- Full text lives in the repo-root `CLAUDE.md` as the standing "Match model to license tier and task" section, inherited by every project cloned from Luna-Core, with a matching handback contract in the four agent templates.

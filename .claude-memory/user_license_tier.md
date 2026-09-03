---
name: user-license-tier
description: "User's current Claude license tier (Claude Max 5x, personal) — governs the model-selection rule in the repo-root CLAUDE.md."
metadata: 
  node_type: memory
  type: user
  originSessionId: 7ae81e10-1d7d-4657-9c9e-e57c816aac04
  modified: 2026-09-03T04:35:00.000Z
---

The user is currently on **Claude Max 5x (personal)**.

**Why this matters:** The repo-root `CLAUDE.md`'s "Match model to license tier and task" rule branches on license tier — Max (personal) or Premium (teams) means always dynamically pick the best-suited model per task (switching between Sonnet/Opus as needed); Pro (personal) or Business Standard (teams) means default to Sonnet unless the user asks otherwise.

**How to apply:** Since the user is on Max 5x, pick whichever model is best-suited task by task and switch as the work changes — never settle on one model as a standing default (inline work or dispatched subagents alike). Speak up when a task calls for a different model than what's currently loaded; don't silently stay on one model out of inertia.

**Verified:** confirmed directly by the user on 2026-09-03, and cross-checked from this machine's config: `C:\Claude\.credentials.json` → `claudeAiOauth.subscriptionType: "max"`, `rateLimitTier: "default_claude_max_5x"`. `C:\Users\Owner\.claude.json` → `oauthAccount.seatTier` and `userRateLimitTier` are both `None`, and `organizationName` is "gryphdalkar@gmail.com's Organization" with `organizationType: "claude_pro"` — the auto-created personal wrapper, not a team seat. A future session can re-check the same two fields in `.credentials.json` rather than re-asking. The prior entry claiming Business Standard (teams) was wrong and has been corrected.

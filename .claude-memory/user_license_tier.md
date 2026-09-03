---
name: user-license-tier
description: "User's current Claude license tier (Claude Business Standard, teams) — governs the model-selection rule in the repo-root CLAUDE.md."
metadata: 
  node_type: memory
  type: user
  originSessionId: 7ae81e10-1d7d-4657-9c9e-e57c816aac04
  modified: 2026-09-02T14:55:14.209Z
---

The user is currently on **Claude Business Standard (teams)**.

**Why this matters:** The repo-root `CLAUDE.md`'s "Match model to license tier and task" rule branches on license tier — Max (personal) or Premium (teams) means always dynamically pick the best-suited model per task (switching between Sonnet/Opus as needed); Pro (personal) or Business Standard (teams) means default to Sonnet unless the user asks otherwise.

**How to apply:** Since the user is on Business Standard, default to Sonnet for both inline work and dispatched subagents unless the user explicitly asks for a different model for a specific task, or says their license tier has changed (update this memory if so).

---
name: feedback-explicit-commit-permission
description: "Never commit, merge, or push git changes without explicit per-action permission from the user, even in auto mode. A granted commit permission bundles in its push — no separate ask for that push."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 7ae81e10-1d7d-4657-9c9e-e57c816aac04
  modified: 2026-08-31T17:34:30.607Z
---

Never run `git commit`, `git merge`, or `git push` (or any agent/tool that does so on the user's behalf) without asking first and getting an explicit yes — every time, not just once per session or once per project.

**Commit+push are bundled:** once the user says yes to a commit, push that same commit to the remote right after, without asking separately for the push. `git merge` still requires its own separate explicit permission, as does anything else.

**Why:** The user is setting up commit-capable agents (see the agent templates in this kit) and wants full control over when work actually lands in git history before those agents are in regular use. This applies broadly, not just to Luna-Core — it's a generic, cross-project rule (also kept in the shared/generic memory scope), but is repeated here since it directly governs work in this project too. The commit+push bundling was added because asking twice for what the user considers one action was unnecessary friction.

**How to apply:** Treat git commit/merge/push as always requiring confirmation, on top of the general "ask before hard-to-reverse actions" guidance. Do not treat a prior approval as blanket permission for future commits — ask again each time. The one exception: the push immediately following a just-approved commit does not need its own separate ask.

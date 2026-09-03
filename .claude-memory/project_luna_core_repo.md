---
name: project-luna-core-repo
description: "Luna-Core is the starter-kit toolkit at C:\\Users\\Owner\\Documents\\Claude\\Luna-Core that every new project is bootstrapped from; has a git repo on dev with origin wired to GitHub, but no commits yet."
metadata: 
  node_type: memory
  type: project
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
  modified: 2026-09-03T04:20:00.000Z
---

**Luna-Core** (`C:\Users\Owner\Documents\Claude\Luna-Core`) is the source-of-truth starter kit every new project of the user's is bootstrapped from: four agent templates (`luna-core-{docs-writer,research,qa-tester,implementer}` — agent identifiers are lowercase by convention, matching `lunahud-*`, while the project name keeps its capitals), the Wake Up / Debrief protocols, a baseline `CLAUDE.md`, the `ver-A.B.C.D` versioning scheme, and `scripts/` that install it all into a new project. Currently `ver-0.1.0.0-dev`.

**Why:** the user wanted one core that every project starts from, so conventions are inherited rather than recreated ad hoc per project.

**How to apply:**
- **Git repo now exists, on `dev`, with `origin` wired to a private GitHub remote** — `https://github.com/LunaBelleElite/Luna-Core.git`. This replaces the earlier bundle-hub design entirely; there is no bundle and no synced-drive hub folder, and there will not be one. Nothing has been committed, tagged, or pushed yet. `scripts/install-global-entrypoint.sh` was rewritten to match: it takes no arguments, reads the clone URL from this checkout's own `origin` remote, and writes two things (the machine `CLAUDE.md` pointer block and `/new-project`) instead of three — it no longer writes a README beside a bundle. `README.md`, `CLAUDE.md`, `CHANGELOG.md`, and `handoff/HANDOFF.md` were all updated to match on 2026-09-02.
- Work on it as its own session, working directory set to the project folder — its agents and `/wake-up` `/debrief` are project-scoped and only load then, and memory scoped to the shared `Documents\Claude` parent leaks into unrelated projects.
- Bootstrap a new project with `scripts/bootstrap-new-project.sh <luna-core-dir> <new-project-dir> <ProjectName>`, then `scripts/validate-luna-core-setup.sh` inside it. Bootstrap lowercases the project name for agent identifiers, so `TestProj` yields `testproj-qa-tester`.
- Both declared superpowers dependencies are installed and `check-superpowers.sh` exits 0 — see [[claude_code_skill_stack_setup]] for the local patches Steroids needed.

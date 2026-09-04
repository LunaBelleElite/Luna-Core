---
name: project-astrid-shares-this-memory-scope
description: "Astrid's own repo (C:\\Users\\Owner\\Documents\\Claude\\Astrid) deliberately shares Luna-Core's auto-memory scope rather than getting its own — an explicit user decision, not a leak"
metadata: 
  node_type: memory
  type: project
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
  modified: 2026-09-04T13:39:18.599Z
---

**Decision (2026-09-04, explicit user instruction):** work done in the
Astrid codex repo (`C:\Users\Owner\Documents\Claude\Astrid`, the sibling
clone providing Luna-Core's personality/voice layer) gets logged in
*this* memory scope — Luna-Core's own — rather than a separate
Astrid-scoped memory bucket. The user's own words: "just continue to use
Luna-Core's memory for both since we are entwining these repos technically."

**Why:** the two repos are being worked on together in the same sessions,
sibling-cloned by design, and increasingly cross-referencing each other
(Astrid's new `.claude/agents/*.md` set was itself cloned from Luna-Core's
agent templates; the Stop-hook auto-speak mechanism Astrid provides is
depended on by Luna-Core sessions — see [[feedback_astrid_auto_speak]]).
Splitting memory by repo would fight that, not reflect it.

**How to apply:** this is a deliberate exception to
[[feedback_handoff_only_at_debrief]]'s general neighbor rule and to
CLAUDE.md's "Keep this project's memory scoped locally, not universal"
guidance — that guidance exists to prevent *accidental* leakage into a
shared parent-folder bucket when a session's cwd is wrong; this is the
opposite case, an *intentional* shared scope the user asked for between two
specific, related repos. Don't "fix" this later by splitting Astrid's
memories out unless the user asks — it would undo a real decision, not
correct a mistake. If a future session is unsure why Astrid-related facts
live in Luna-Core's memory folder, this is why.

**Practical note on invoking Astrid's own agents:** Claude Code auto-registers
a project's `.claude/agents/*.md` as invokable-by-name subagent types only
for a session whose actual cwd is that project. A Luna-Core-rooted session
(like the one that created them) cannot invoke `astrid-docs-writer` /
`astrid-research` / `astrid-qa-tester` / `astrid-implementer` by name —
same limitation already documented for bootstrapped test projects in
[[feedback_simulation_loop_protocol]]. Work "as" one of Astrid's agents by
reading its `.claude/agents/astrid-*.md` file in full and operating exactly
per that spec (dispatched as a `general-purpose` agent, not the named type),
same workaround Debrief's own protocol already allows ("perform or invoke").

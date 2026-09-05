---
name: research-agents-may-use-network
description: "The global \"no-network constraint in every agent brief\" rule covers live third-party API calls, not web research; research agents (luna-core-research, astrid-research) are allowed and expected to go online."
metadata: 
  node_type: memory
  type: feedback
  modified: 2026-09-05T01:24:02.960Z
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
---

Research agents are allowed online. Do not put a blanket "no network / no
WebSearch / no WebFetch" line in a brief for `astrid-research` or
`luna-core-research`.

**Why:** On 2026-09-04 I dispatched `astrid-research` twice (the JARVIS/FRIDAY
interaction-mechanics analysis) with a hard "no network" constraint, citing the
global standing rule in `C:\Claude\CLAUDE.md` ("Put a no-network constraint in
every agent brief"). The user corrected it: "Research agent specifically is
allowed to go online." The global rule's stated scope is *live third-party API
calls* (EDSM, Spansh, EDAstro and the like) without asking — it exists to stop
agents hitting rate-limited or paid services, not to stop web research. A
research agent is given WebSearch/WebFetch precisely so it can do that research;
constraining it to memory produced an analysis with a dozen scene attributions
it couldn't verify.

**How to apply:** In a research brief, keep the *specific* constraint (no live
calls to named third-party APIs without asking) and drop the blanket one. Keep
the copyright rule regardless: no verbatim reproduction of copyrighted text
(scripts, lyrics, articles) — paraphrase at the level of shape. Related:
[[feedback_no_live_api_calls_without_asking]], [[feedback_delegate_research_to_subagents]].

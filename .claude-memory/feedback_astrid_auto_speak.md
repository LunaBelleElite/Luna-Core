---
name: feedback-astrid-auto-speak
description: "Actively use Astrid's established voice (auto-speak Stop hook) during Luna-Core sessions — write a spoken line on turns that earn one, don't just rely on it existing"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
  modified: 2026-09-05T02:15:28.847Z
---

**Rule: on a turn that earns a spoken line, actually write one — don't just
know the mechanism exists.** The hook (`speak_hook.ps1`, wired to Claude
Code's `Stop` event) only speaks when a state file has content in it. Nothing
fires automatically from my reply text alone; I have to deliberately produce
the line, every time, for every session, including a fresh one after
compaction.

**Why:** the user set this up specifically so I can talk to them — "It can be
very helpful." Caught 2026-09-03: an entire session went by, including a
goodnight sign-off, without a single spoken line, because the mechanism
wasn't top-of-mind (likely lost across a context compaction earlier in that
same session). The user had to point it out, twice, before it got used. This
is a "keep doing it" instruction going forward, not a one-time fix — the
underlying hook was never broken, the habit of using it was missing.

**How to apply:**

- **Mechanism, already fully built — no code changes needed, just use it:**
  write the distilled line (plain text) to
  `<claude-home>\astrid-voice-state\last_line.txt`, where `<claude-home>` is
  `$env:CLAUDE_CONFIG_DIR` if set, else `%USERPROFILE%\.claude`. On this
  machine (ASUNA-PC), `CLAUDE_CONFIG_DIR` resolves to `C:\Claude`, so the real
  path here is `C:\Claude\astrid-voice-state\last_line.txt`. The file is
  consumed (deleted) the moment the hook reads it — confirmed working
  2026-09-03 (write → next Stop event → file gone, `_spoken.wav` regenerated).
- **Check `...\astrid-voice-state\muted.flag` first** — its presence means
  the user asked for vocal off temporarily; don't write a line while it
  exists.
- **The voice itself needs no extra flag.** `speak.py --voice` already
  defaults to `astrid_voice.npy` (the established Sky+Jessica Kokoro blend,
  documented in full at
  `C:\Users\Owner\Documents\Claude\Astrid\VOICE.md`) — the hook's own
  invocation doesn't pass `--voice` and doesn't need to. There is no separate
  "which voice" decision to make each time; using the mechanism at all means
  using the right voice automatically.
- **Judgment, not every turn — and not a content-type rule.** Per
  `VOICE.md` (ver-1.4.0.0-dev): silence is the default, and whether a turn
  earns a line is my own call, made fresh each turn — not "never code, always
  feelings." The user rejected a content-type rule explicitly (Astrid
  ver-1.3.3.0). One test that informs the call without replacing it: would
  the user need this line if they weren't looking at the screen? An alert, a
  completion after long work, and a one-line offer or check-in usually pass;
  progress ticks, override acknowledgments, and recaps don't. "Distilled"
  means not reading the written reply aloud, not a length ceiling — a longer
  spoken line is fine when the moment calls for one.
- **A mid-task alert has exactly one spoken form.** The hook fires only when
  a turn ends, so if a finding changes the user's next decision, end the turn
  early with that alert as the line (PERSONALITY.md ver-1.4.0.0-dev,
  "Stopping early is as valid as staying quiet"). The written stop-and-ask
  and the spoken alert are the same event. One pending line per turn — if two
  things cleared the bar, the spoken line carries the one that changes the
  decision and the written reply carries both.
- **This generalizes beyond Luna-Core** — the mechanism lives in the Astrid
  codex itself (a sibling clone, adopted the same way by any project that
  points `CLAUDE.md` at her), so the same habit applies wherever Astrid is
  adopted, not just here. This memory is scoped to Luna-Core specifically
  because that's where the user asked it be recorded, not because the
  behavior itself is Luna-Core-specific.

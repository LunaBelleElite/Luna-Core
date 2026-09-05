---
name: feedback-astrid-auto-speak
description: "Actively use Astrid's established voice (auto-speak Stop hook) during Luna-Core sessions — write a spoken line on turns that earn one, don't just rely on it existing"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
  modified: 2026-09-05T21:57:35.302Z
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
- **Remote/phone sessions: the hook cannot reach them, tested 2026-09-05.**
  `speak_hook.ps1` ends in .NET `SoundPlayer.PlaySync()`, so audio always plays
  on the machine Claude Code runs on. A remote-control session from a phone
  hears nothing. Two workarounds were built and tested:
  - **File card** — render the line and `SendUserFile` it. Works everywhere and
    survives anything, but audio **attaches rather than rendering inline**, and
    **cannot autoplay** (browser gesture requirement, not a fixable setting).
    One tap per line. `scratchpad/speak.sh` and `relay_line.py` do the render.
  - **Artifact Voice Relay** (published 2026-09-05,
    https://claude.ai/code/artifact/3a0bb43e-8d8e-4570-b535-e45dcbe73f23) — a
    `db`-capable page holding a live `onSnapshot` on one document
    (`voice/current`); the assistant writes `{seq, text, ts, dur, mp3_b64}` via
    `write_db` with `file_path` so the base64 never enters the conversation.
    One document overwritten each time, never one per line — the store caps
    documents at 256 KiB and warns against one-doc-per-item streams. Plays
    hands-free after a single Enable tap. **Confirmed working, and confirmed
    it dies the moment the page is closed** to read the conversation. So it is
    a *second-device* tool (propped phone, tablet, PC) — on a single phone you
    can have the conversation or the relay, never both.
  **Standing decision (interim):** keep file cards, but raise the bar — send
  audio only for lines that genuinely carry something, text for the rest.
- **The real fix, researched 2026-09-05 — self-hosted ntfy + Tasker (Android).**
  The user is on Android. Verified chain, hands-free with the screen locked and
  playing the actual Kokoro audio: PC publishes the clip as an attachment to a
  self-hosted **ntfy** server → the **F-Droid build** of the ntfy Android app
  (the Play build routes via Firebase; the F-Droid build holds its own
  foreground-service connection) → the app unconditionally broadcasts
  `io.heckel.ntfy.MESSAGE_RECEIVED` with `attachment_url` in the extras →
  **Tasker** "Intent Received" profile fetches it and plays it. No tap anywhere.
  Fully self-hosted: no Google, no third party ever holds the audio.
  Requirements: Tasker $3.49 one-time; battery-optimisation exemption for BOTH
  apps plus OEM autostart settings (dontkillmyapp.com). Caveat: disputed reports
  of ~5%/hr battery drain on cellular, near-zero on Wi-Fi.
  **Gap the research missed, found here:** the phone must be able to REACH the
  self-hosted server from cellular — needs Tailscale (not installed on ASUNA-PC
  as of 2026-09-05), a port-forward + DDNS, or a tunnel. Docker 29.6.2 IS
  installed, so the server itself is trivial.
  **Ruled out definitively — do not revisit:** web push / a self-built PWA
  cannot play audio at all (service workers have no DOM or Web Audio access —
  an unimplemented spec gap, not a policy); Home Assistant's companion app has
  no command that plays a supplied audio file (confirmed open feature request);
  Pushover cannot upload sounds via API; ntfy/Discord/Matrix/Gotify/KDE Connect
  deliver without playing; a self-built Android app is strictly more work than
  ntfy+Tasker for identical capability. Claude Code itself has no native path —
  `PushNotification` is text-only by schema, and hooks are host-side with no
  remote target.
- **BUILT AND CONFIRMED WORKING 2026-09-05** — backgrounded, hands-free, real
  Kokoro voice, verified with Tasker in the background while the user read the
  conversation. The exact configuration:

  **PC side (ASUNA-PC):**
  - ntfy 2.28.0 at `C:\Tools\ntfy` — config `server.yml`, port **8090**, topic
    **`astrid-xiyz8vtydg`**, base-url `http://192.168.1.37:8090`.
  - A tiny static server at `C:\Tools\astrid-latest\serve.py` — port **8091**,
    serves ONLY `/latest.mp3`, sends `Cache-Control: no-store` (a constant URL
    over changing bytes is exactly how a client plays stale audio).
  - Both registered as **scheduled tasks at logon** (`ntfy-astrid-relay`,
    `astrid-latest-server`) so they survive reboots. No Docker: Docker Desktop's
    Linux engine needs WSL2, which is not installed on this machine.
  - Two **Private-profile inbound firewall rules**, TCP 8090 and 8091. Creating
    them needs elevation — the assistant cannot, the user must.
  - `say.py` (in the session scratchpad) renders the line, copies the mp3 to
    `C:\Tools\astrid-latest\latest.mp3` via write-temp-then-`os.replace` (so the
    phone can't fetch a half-written file), and POSTs the **text** to ntfy as a
    bare trigger. Audio no longer rides on the ntfy message.

  **Phone side (Android, Tasker $3.49 + ntfy):**
  - Profile: **Event → System → Intent Received**, action
    `io.heckel.ntfy.MESSAGE_RECEIVED`.
  - Task, three actions: **Net → HTTP Request** (GET,
    `http://192.168.1.37:8091/latest.mp3`, save to `Astrid/line.mp3`) →
    **Task → Wait 1s** → **Media → Music Play** (`Astrid/line.mp3`).

  **The six things that broke, all worth not rediscovering:**
  1. **`HTTP Get` silently corrupts binary** — it decodes the response as text
     and re-encodes UTF-8, inflating a 75 KB mp3 to 133 KB, unplayable. **Use
     `HTTP Request`.** The size ratio (~1.8x) is the diagnostic signature.
  2. **`%attachment_url` never resolved** in Tasker despite ntfy's broadcast
     setting being on. Sidestepped entirely by the fixed URL — do not go back
     to reading the URL out of the intent.
  3. **Tasker doubles the storage root** on a path with no leading slash:
     `storage/emulated/0/...` became `/storage/emulated/0/storage/emulated/0/...`.
  4. **Test-running a single action is not running the task** — it executes only
     that action and stops. This made a working task look broken for over an
     hour. Use the task's play button.
  5. **PowerShell 5.1 `Set-Content -Encoding utf8` writes a BOM**, which
     corrupted the topic string and sent the first publish to the server root.
  6. Tasker's **Flash action does nothing** on this device (needs "Display over
     other apps"), so it is useless as a probe. The **Run Log** is the reliable
     instrument — its columns are Time / Status / **ID** / Details, and the ID
     is `task.action`, not a duration.

  **Still open:** this works on the home LAN only. Off-network (cellular) needs
  Tailscale, a tunnel, or port-forwarding; Tailscale is not installed. Also not
  yet built: the `remote.flag` beside `muted.flag` to gate the phone channel,
  and moving the publish into `speak_hook.ps1` so it fires automatically on
  every spoken line rather than the assistant calling `say.py` by hand.
- **This generalizes beyond Luna-Core** — the mechanism lives in the Astrid
  codex itself (a sibling clone, adopted the same way by any project that
  points `CLAUDE.md` at her), so the same habit applies wherever Astrid is
  adopted, not just here. This memory is scoped to Luna-Core specifically
  because that's where the user asked it be recorded, not because the
  behavior itself is Luna-Core-specific.

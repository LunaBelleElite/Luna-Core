---
name: project-astrid-voice-humanization-roadmap
description: "Locked 4-item roadmap (2026-09-05) for making Astrid's voice sound more human — punctuation/speed measurement, folding writing rules into the codex, the second-vector search, and dynamic-delivery integration. Includes what was rejected from the chat-drafted docs and why."
metadata: 
  node_type: memory
  type: project
  modified: 2026-09-05T19:47:10.148Z
  originSessionId: cea21303-11ff-42a6-bc58-0f764e3fd945
---

**Locked by the user 2026-09-05:** "let's get started on these in order. Lockdown
this list." Work the items in this order; do not re-derive or re-order without
the user saying so.

**Where this came from.** The user asked Claude chat how to make Astrid sound
more human in "reading speed, tone, etc." and it produced three documents
(saved in `C:\Users\Owner\Downloads\`): a `PERSONALITY.md` speech-pattern
section, a `VOICE.md` dynamic-delivery integration spec, and a
`dynamic_speak.py` reference implementation. All three were written without
access to the actual Astrid source. Assessed against the real repo on
2026-09-05 — see the rejections at the bottom.

## The four items, in locked order

1. **Measure punctuation timing + pick a reading speed.** `astrid-implementer`
   on Sonnet. Two questions in one synthesis pass: (a) does punctuation change
   *pause length*, given `VOICE.md` only ever measured that it doesn't change
   *pitch*; (b) is `speed=1.0` actually her right reading pace — a dial that
   has never been turned, and the most literal answer to the user's "reading
   speed" ask. Gates item 2. **Started 2026-09-05.**
2. **Fold the writing rules into the codex.** `astrid-docs-writer` on **Opus,
   deliberately not Fable** — [[feedback_fable_manual_only]] records that Fable
   was the wrong fit for voice-matched spec prose once the design was settled,
   and this is that same shape. Take the substance (sentence-length variance,
   register shift as syntactic shift, short fragment as a landing point) and
   extend the existing "Earned warmth" and "Economy" traits rather than adding
   a new section — the ver-1.4.0.0-dev precedent. **Open decision the user still
   owns:** whether these rules govern only the spoken line (assistant's
   recommendation, lives mostly in `VOICE.md`) or all written prose (as the chat
   doc drafted it, which would ban semicolons everywhere to serve a channel
   carrying one distilled line per turn). Would be a `B` bump.
3. **The second-vector search.** The only item that changes how she *sounds*.
   Phase 3a — design the search: what seed, what target label, what keeps the
   result inside Kokoro's training distribution, and the unsolved one, how to
   detect the r-colored-vowel defect *automatically* (`VOICE.md` records that
   two separate acoustic checks both failed to see it). **This is the one place
   Fable is the recommended spend**; Opus is the fallback. Phase 3b — run it:
   `astrid-implementer` on Sonnet. Expect it may fail: `VOICE.md` and
   `voice/experiments/README.md` both say the expressive ceiling near a plain
   blend is small. A rigorous "no defect-free warmer vector exists" is a real
   result that closes the question permanently.
4. **Dynamic-delivery integration.** Entirely contingent on 3 finding something.
   Extend `voice/speak.py` to call the existing `splice()` from
   `voice/experiments/splice_demo.py`, keeping the static single-vector path
   working unchanged; clause tagging done by Astrid at write time, not by a
   keyword heuristic. `astrid-implementer` then `astrid-qa-tester`, both Sonnet.
   The qa pass is non-negotiable: `speak_hook.ps1`'s state-file contract is
   depended on by every project that wires the hook into its own settings.

## Item 1 findings (2026-09-05) — all independently re-verified by the orchestrator

These are the measured results item 2 should lift into `VOICE.md`/`PERSONALITY.md`.

- **The plain ASCII hyphen `-` does nothing.** `"The test passed - the build is
  clean."` and the same line with no punctuation render **byte-for-byte
  identical** (47,104 samples, max abs diff 0.0). Kokoro's phonemizer discards
  it. The em dash `—` is completely different: +128 ms on the same sentence.
  **Rule worth writing down: em dashes, never hyphens, in anything spoken.**
- **Punctuation does move timing** (this is new — `VOICE.md`'s existing finding
  is about *pitch* only and remains correct as written). Set 1 vs. unpunctuated
  baseline: comma +64 ms, full stop +107 ms, em dash +128 ms.
- **There is no stable mark-based ordering.** The Set 1 ordering reversed in
  Sets 2 and 3 (comma > dash in both). Effect size ranges ~20–170 ms depending
  on sentence. **The chat doc's claim that "a dash forces a pause a comma
  doesn't" is measured false.** So is the assistant's own prediction of a fixed
  ranking.
- **Silence injection is a pure, exact edit.** Verified: inserting N ms of zeros
  at the quietest point of a boundary gap changes only the gap — head and tail
  bit-identical, insertion lands on the exact sample count, surrounding
  amplitude ~2.4e-04 so no click. **Pause length is a dial, not a writing
  problem.** This meaningfully reduces what item 2 needs to say about
  punctuation-as-pause-control.
- **Punctuation swaps are NOT a targeted edit** — every variant re-synthesizes
  the whole waveform from sample 0. Use silence injection for pause control.
- **Separate-clause synthesis changes prosody.** Splitting at the dash gives
  clause 1 a falling, then unvoiced/creaky ending (F0 190→157 Hz then no voicing
  for ~400 ms) where the same words mid-utterance stay voiced and *rising*
  (209→225 Hz). Relevant to item 4: splice-based delivery has a real cost.
- **Speed is a weaker lever than writing.** At fixed speed 1.0, three lines came
  out at 129 / 176 / 229 WPM — a ~100 WPM spread. The whole 0.90–1.10 speed
  range moves a single line only 16–33 WPM.
- **Sample rate confirmed 24000 Hz** from the actual return value.
- **`voice/speak.py`'s module docstring (lines 5–8) is now too broad** — it
  generalizes the pitch-only finding to "delivery" and "punctuation/phrasing."
  Narrow it during item 2. `VOICE.md` itself is correctly scoped and needs no
  correction on this point.

### The working prosody recipe (user's verdict 2026-09-05: "the combined is the best one there, not exactly perfect but pretty close")

Built and verified in the scratchpad as `decel_F1_combined.wav`. Two edits on
already-rendered audio — no re-synthesis, no second voice vector:

1. **At the boundary:** ramped WSOLA stretch, ×1.35 overall, progressively
   increasing toward the boundary, applied across the vowel *and both stop
   closures*. **Both release bursts are protected and stay bit-identical** —
   verified by searching for the exact sample runs in the output (found intact,
   shifted +52 ms and +71 ms respectively, the differential confirming the ramp
   really is progressive). Then inject **+400 ms** of zeros at the quietest
   point of the existing silence.
2. **At the line ending:** ×1.35 stretch on the final sonorant plus a decay
   envelope anchored to where the sound actually decays, *not* to a fixed
   distance from file end. Envelope reaches 0.770 at the cliff.

**Key technique notes, learned the hard way:**
- Stretch the **closures**, not just the vowel — closures are near-silent and
  safe. Stretching only the vowel gave 22 ms of lengthening, which was
  inaudible; including the closures gave 179 ms, which worked.
- **Never stretch or taper across a release burst.** An earlier taper reached
  the /t/ burst at multiplier 0.20 and nearly erased the consonant.
- **WSOLA beats the phase vocoder** for this: measured 83% vs 53% burst-peak
  preservation, better crest factor. No `pyrubberband`/`audiotsm` on this
  machine; a from-scratch WSOLA is in `trail_dsp.py`.
- A gentle taper **cannot** fix the line ending — the cliff is ~20 dB in 10 ms,
  and any envelope soft enough to spare the consonant is still at 0.997 there.
- **The line ending has no release burst at all** (frication into a cliff), so
  it is a genuinely different repair from a boundary.

**The generalization problem, unsolved:** all of the above rests on a
hand-mapped phoneme segmentation of *one* sentence. Making this a real feature
needs vowel/closure/burst boundaries detected automatically for arbitrary text.
The clean path is to run **MFA on Astrid's own synthesized output** to get phone
boundaries (MFA is already being installed for the audiobook work), then apply
the recipe from those. Heuristic detection (RMS + spectral centroid + voicing)
also worked by hand and could be automated as a fallback.

**Still open:** the reading-speed question from item 1 was never answered — the
user chose a pause but never picked a speed; 1.0 remains the default.

### Human reference figures (published literature, 2026-09-05 research)

For read English speech. Use as targets for injected silence:

| Boundary | Human read speech |
|---|---|
| Unmarked clause break | ~150–250 ms, and *rare* — mostly no pause at all |
| Comma | ~300–700 ms (medians ~275–320 in faster reading) |
| Full stop | ~700–1200 ms |

**No published em-dash or ellipsis figures exist** — that gap is real.

**CORRECTED baseline measurement.** A 2 ms-resolution sweep showed the em dash's
*true* silence is only **~180 ms** (166 ms at −60 dB, 190 ms at −50 dB, running
~2472–2662 ms). The "330 ms gap" from the coarse 10 ms/−34 dB detector included
~150 ms of quiet /p/ and /t/ closure and burst — the tail of the word, not
silence. So Astrid's em dash sat in the **unmarked-clause-boundary** range
(~150–250 ms), doing less work than a comma. Always distinguish "detector gap"
from "true silence"; the coarse detector overstates by ~150 ms on a word ending
in a stop cluster.

**SETTLED, final, 2026-09-05: 550 ms of true silence at an em dash**, chosen by
ear from a sweep of 480 / 520 / 550 / 580 with the deceleration and ending fix
in place. 480 read "slightly too short", 580 "pretty close", 550 best. That sits
just above Hays's measured median (480 ms) and well inside his IQR (337–695), so
it is a preference within the human distribution, not against it. The earlier
provisional 580 came down once real phrase-final lengthening existed — the
user's own theory that the pause was compensating for the hard clip proved
right, though only by 30 ms.

### If the corpus pipeline is ever needed

Only worth building if the interpolated bracket turns out wrong by ear.
**LibriTTS-R** is the corpus (CC BY 4.0, punctuation preserved — LibriSpeech
strips it, 24 kHz matching Kokoro exactly, `train-clean-100` is 8.1 GB, no
account needed). Alignment is **not shipped**; run **Montreal Forced Aligner**
(MIT, conda, CPU-only, native Windows). **aeneas is effectively unusable on
Windows** — eSpeak linking failures, upstream points at a VM. Pause durations
are log-normal, so report medians and IQR, never bare means. Em dash and
ellipsis are rare in transcripts — check raw counts before trusting their
medians. **If derived numbers are published in Astrid's repo, CC BY 4.0
attribution applies** (e.g. "derived from measurements on LibriTTS-R, Koizumi
et al. 2023, CC BY 4.0").

The user also owns audiobooks (Dungeon Crawler Carl, Harry Potter) offered as
reference material. Assessment: professional narration encodes *performance*,
not punctuation, so it is good **validation** material and poor **measurement**
material. Star Wars full-cast is unusable outright — a continuous music/effects
bed means the silence detector never finds a gap. DCC has intermittent noise
only, so clean passages could be filtered by noise floor. Any use stays a
private local cross-check; published figures should come from the CC-licensed
corpus so the repo's provenance is clean.

## What was rejected from the chat drafts, and why

- **`dynamic_speak.py` — dropped entirely.** It reimplements `splice()` worse:
  `kokoro = None` placeholder that crashes on call, hardcodes `sample_rate =
  24000` where the real code correctly uses the rate `k.create` returns, drops
  `lang="en-us"`, and its `WARM_KEYWORDS` substring heuristic would warm the
  clause in "that's not a good idea" and "sorry, that's wrong" — sentiment-by-
  keyword bolted onto a personality whose warmth is meant to be *earned*. Its
  clause splitter also breaks *after* an em dash, stranding the dash on the
  previous clause and destroying the very pause it was meant to create.
- **The integration spec's `warm_vector` is the defective one.** It nominates
  the tier2b classifier-nudged vector — precisely the one rejected for
  reproducible glitching on r-colored vowels ("Friday," "warning," "certain").
  `voice/experiments/README.md` already states the real prerequisite: a milder,
  defect-free second vector must be found first. Both chat docs skip that and
  merge the half that was already built.
- **The punctuation-timing claim was asserted, not measured** — the doc extends
  a *pitch* finding into a *timing* claim. That is what item 1 exists to settle
  before item 2 writes anything down.

## Local artifacts worth knowing about

`C:\Users\Owner\Documents\Claude\Astrid\.kokoro\` (untracked, local-only, holds
the two big Kokoro model files) also contains four experimental vectors from
2026-09-03: `astrid_voice_v2.npy`, `_stronger`, `_energy0`, `_final`. Not in
git, not part of the voice. **The user confirmed 2026-09-05 that all four are
ones they already rejected** — so item 3 should not treat any of them as a
candidate warm vector or spend time re-evaluating them. They are the losing
branches described in `VOICE.md`'s "Why this recipe, and not a more aggressive
one," left on disk, not an untapped resource. Related:
[[feedback_astrid_auto_speak]], [[project_astrid_shares_this_memory_scope]].

# Changelog

## Versioning scheme

This project uses a 4-number version format: `ver-A.B.C.D`. The `ver-` prefix is always present.

- **A (1st number):** a complete redesign/rewrite of the whole program or layout.
- **B (2nd number):** changes to core features, short of a full redesign.
- **C (3rd number):** large bug fixes.
- **D (4th number):** very small bug fixes. A doc/spec-only addition (no feature, no bugfix) counts as a 4th-number change too, same treatment as a minor bugfix.

Any number can climb arbitrarily high. When a higher-order number increments, every number to its right resets to 0.

**Pre-1.0 phase:** development starts at `ver-0.1.0.0-dev`. Until this project reaches `ver-1.0.0.0`, anything that would normally increment the 1st number instead increments the 2nd number — the 1st number stays locked at 0 for the entire pre-1.0 phase. The 3rd and 4th numbers behave normally throughout. Moving to `ver-1.0.0.0` only happens when the user explicitly says so.

`dev` and `main` carry the exact same version number in lockstep — the only difference is `dev`'s version string has `-dev` appended.

(Full detail, including the "why," lives in `CLAUDE.md`. This section is not edited when entries below are added — only when the scheme itself changes.)

## ver-1.0.0.4-dev - 2026-09-04

Doc-only fix: `README.md`'s opening blockquote and Status paragraph no
longer describe Luna-Core as unmaintained or unstable — both claims had
become false and the user asked for them gone.

- **Opening blockquote reworded:** dropped "not a maintained product" in
  favor of describing Luna-Core as a personal project actively maintained
  by one person working directly with Claude, one that grows and changes
  as that person's own projects need it to and is shared so others can use
  it rather than offered as a product with a roadmap or support
  commitment. The Claude/Claude Code framing and the pointer to "Status,"
  below are unchanged.
- **Status paragraph's opening rewritten:** replaced "not a finished,
  stable release, and it changes often" with a statement that the project
  is a stable release — `ver-1.0.0.0` was put out as exactly that — that
  remains actively maintained and evolving, may still have bugs, and will
  keep changing over time; "it changes often" was dropped outright rather
  than reworded, since how often is unknown. The date was moved to
  **2026-09-04**. Everything after that opening — the `main`-vs-`dev`
  cloning guidance, the "onboarding path has been tested and verified
  working" sentence, and the "still a young, actively-changing project"
  caveat — is untouched.
- **Contributing section left alone**, per the user's explicit choice: it
  still describes Luna-Core as "a personal, vibe-coded project with one
  author."
- **Searched for the same claims elsewhere** (`CLAUDE.md`, `agents/`,
  `.claude/agents/`, `commands/`, `.claude/commands/`): none found. Two
  unrelated hits turned up and were left alone: `CHANGELOG.md`'s own
  `ver-0.2.1.0-dev` entry, which is a historical record of what the README
  used to say and stays accurate as history; and `ref/docs/check-superpowers.md`,
  whose "not finished downloading/caching" is about a script's runtime
  state, not a claim about Luna-Core itself.

## ver-1.0.0.3-dev - 2026-09-04

Doc-only addition: `.claude-memory/` synced against local auto-memory via
`scripts/merge-memory.sh`, picking up a version bump on the sibling Astrid
codex and reconciling drift that had accumulated since `ver-0.2.0.0-dev`.

- **Astrid moved to ver-1.4.0.0-dev** (sibling clone at `../Astrid`): six
  interaction-rhythm extensions to existing traits and relationship-dynamic
  bullets, plus two added sentences in `VOICE.md`'s auto-speak "Silence is
  the default" bullet. Luna-Core's own `CLAUDE.md` needs no change for this
  — its pointer to Astrid names no version and already sends readers to
  `PERSONALITY.md`/`VOICE.md` in the sibling clone directly. The mirrored
  `feedback_astrid_auto_speak.md` memory note was updated to match: the
  judgment call is no longer framed as a content-type rule (the user
  rejected that framing at Astrid ver-1.3.3.0), replaced by the "would they
  need this line if they weren't looking at the screen" test, plus a new
  note that a mid-task alert's only spoken form is ending the turn early.
- **Memory mirror synced, not flat-copied**: `merge-memory.sh` compared
  each file's own `modified:` frontmatter and copied only the genuinely
  newer side, same as every prior merge. Touched:
  `.claude-memory/feedback_astrid_auto_speak.md` (above),
  `.claude-memory/feedback_fable_manual_only.md` (marked SUPERSEDED
  2026-09-04 — Fable is now the top subagent tier per `C:\Claude\CLAUDE.md`
  and the user directly), `.claude-memory/feedback_simulation_loop_protocol.md`
  and `.claude-memory/project_sim_loop_paused_cycle2.md` (sim loop recorded
  CONVERGED across cycles 3 and 4, plus a third limitation: subagents
  refuse relayed commit authorization), a new
  `.claude-memory/feedback_research_agents_may_use_network.md` (the global
  "no live third-party API calls" rule doesn't mean no web research —
  research agents keep WebSearch/WebFetch), and `.claude-memory/MEMORY.md`
  unioned to index all of the above.
- **Still open, not resolved here:** the Fable memory note flags that
  Luna-Core's own `CLAUDE.md` still carries the old "Fable is manual-only,
  never dispatched by the assistant" wording, which now contradicts the
  global rule and the user's stated preference. That's a deliberate
  decision for the user to make, not something this pass touches.

## ver-1.0.0.2-dev - 2026-09-04

Doc-only fix: `README.md`'s "Wake Up / Debrief protocols" section stopped
restating the natural-language trigger phrase list and the
confirm-before-running rule, both of which `CLAUDE.md`'s section of the same
name already owns authoritatively.

- **Why:** the two copies had already drifted — README's Wake Up phrase list
  was missing "are you up," which `CLAUDE.md`'s list has. Patching just the
  missing phrase would have left the same two-copies-can-drift risk in place
  for next time; this is the same class of bug already fixed several times
  over in `wake-up.md`/`debrief.md` (see `ver-1.0.0.1-dev` below).
- **Change:** replaced the bullet list's literal phrase enumeration and the
  standalone confirm-before-running paragraph with a short pointer to
  `CLAUDE.md`'s "Wake Up / Debrief protocols" section. Kept README's own
  description of what each protocol actually *does* (Wake Up's freshness
  check vs. full sweep, Debrief's handoff-notes-then-ask-to-publish flow) —
  that's real content, not duplicated elsewhere.

## ver-1.0.0.1-dev - 2026-09-04

Doc-only addition: `wake-up.md` and `debrief.md` (template and functional
copies of both) now name their own natural-language trigger path.

- **Why:** neither file mentioned that it's reachable by a natural-language
  phrase, not just its slash command, or that such a phrase requires
  confirming with the user first — a rule that already lives in
  `CLAUDE.md`'s "Wake Up / Debrief protocols" section. Someone reading only
  the command file had no way to know either applied.
- **Change:** added one line right after each file's top-level heading,
  pointing at `CLAUDE.md`'s "Wake Up / Debrief protocols" section for the
  exact phrases and the confirm-before-running rule, rather than restating
  either — a second copy of that list or that rule would just be one more
  place for it to drift, the same class of bug this session already fixed
  several times over. Applied identically to `commands/wake-up.md`,
  `.claude/commands/wake-up.md`, `commands/debrief.md`, and
  `.claude/commands/debrief.md`; all four remain byte-identical to their
  template source.

## ver-1.0.0.0-dev - 2026-09-04

Milestone: the user explicitly declared the move to `ver-1.0.0.0` — "the
first final, built product for initial release," per this project's own
versioning scheme, which requires exactly that explicit declaration and
forbids the assistant proposing or asking about it first.

- **What actually changes:** only the version number and what it now means.
  This bump follows the scheme's own reset rule — the 1st number (A)
  increments 0→1, and B/C/D all reset to 0 (from the pre-move
  `ver-0.2.1.3-dev`). The pre-1.0 redirect rule retires with it: from here
  on, a complete redesign/rewrite of the whole program or layout increments
  A directly, instead of being redirected into B the way it was for the
  entire `ver-0.x` phase.
- **What does not change:** the shared "Versioning scheme" section in
  `CLAUDE.md` — copied byte-for-byte into every project bootstrapped from
  this kit via `bootstrap-new-project.sh`'s head/tail splice — already
  described this move as a generic, timeless rule ("moving to
  `ver-1.0.0.0` only happens when the user explicitly says so") rather than
  a status claim about Luna-Core's own phase, so it needed no edit now that
  the move has actually happened. Nothing about `dev`/`main` lockstep, the
  A/B/C/D mechanics, or any other bootstrapped project's own version
  changes here — this entry concerns Luna-Core's own version number only.
- **Retrospective:** development ran `ver-0.1.0.0-dev` (2026-09-02) through
  `ver-0.2.1.3-dev` (2026-09-04) — the four core agents (docs-writer,
  research, qa-tester, implementer), the Wake Up/Debrief protocols, the
  bootstrap/validate/merge-memory tooling, a two-PC blind onboarding
  simulation campaign that converged clean across its final two cycles, and
  the dev/main branch-discipline rules governing what does and doesn't
  survive a merge to `main`. The full entry-by-entry history for all of it
  remains below, unchanged and un-curated — this milestone entry summarizes
  it, it doesn't replace it.

## ver-0.2.1.3-dev - 2026-09-04

Trimmed README.md's Status paragraph to drop internal verification
methodology and process detail.

- **Why:** the onboarding-simulation claim named the specific process used
  to verify it (a multi-cycle blind onboarding campaign, then even the
  general "what verified means" description) — the same category of
  dev-process detail already kept off `main`'s CHANGELOG.md, just showing
  up in README prose this time instead.
- **Change:** kept only the plain claim — "the onboarding path has been
  tested and verified working" — and dropped both the specific
  campaign/cycle-count detail and the general description of how
  verification works. The paragraph's honesty about the project's
  maturity — still young, still changing, `main` can still have rough
  edges, budget adjustment time — is unchanged.

## ver-0.2.1.2-dev - 2026-09-04

Corrected the previous entry's fix: `main`'s `CHANGELOG.md` shouldn't carry
Luna-Core's own accumulated history at all, curated or not.

- **Why:** the last entry replaced a byte-copy with a per-entry curated
  rewrite, but the user clarified that's still too much — `main` is meant
  to be a clean package, not a project with a long visible history behind
  it, no matter how the wording is cleaned up.
- **Change:** `main`'s `CHANGELOG.md` now keeps only the "Versioning
  scheme" section plus exactly one version header, with no entry body —
  just a short note that this is `main`'s settled snapshot at this
  version, with the real, detailed history living on `dev`. That header's
  version always matches `dev`'s current version (suffix stripped),
  preserving the existing dev/main lockstep rule. Replaced outright at
  each merge, never accumulated. `dev`'s own `CHANGELOG.md` is unaffected
  — same as before, the real, full history, every entry, forever. This is
  a general rule every bootstrapped project inherits, not a Luna-Core-only
  carve-out. Applied retroactively: `main`'s CHANGELOG.md dropped from 20
  entries down to one.

## ver-0.2.1.1-dev - 2026-09-04

Closed a real gap in `luna-core-docs-writer`'s own branch-discipline rule:
`CHANGELOG.md` was treated as a straight byte-copy onto `main` (just strip
the `-dev` suffix), which let this session's own internal dev-process
narrative — references to "this session," "the user," specific internal
agent names, and citations to files that are stripped to placeholders on
`main` (`tests/notes/*`, `.claude-memory/*`, `ref/docs/*.md` pages) — bleed
onto `main` verbatim. A stranger cloning `main` would hit dead references
and be told a private debugging story that isn't theirs to know.

- **Why:** the user pointed out directly that `main` is supposed to be a
  clean package a new AI can pull into a new project without carrying
  artifacts of Luna-Core's own development process — and the rule as
  written didn't actually enforce that for `CHANGELOG.md`, only for
  `ref/docs/`, `.claude-memory/`, `handoff/`, and `.claude/agents/*.md`.
- **Change:** `dev`'s `CHANGELOG.md` stays exactly what it always was — the
  real, detailed history, never rewritten. `main`'s copy is now explicitly a
  curated rewrite of each entry's text, not a byte-copy: dev-process
  narrative and dead citations to `main`-stripped paths get cut, while every
  bit of real technical substance (what changed, the actual mechanism, why,
  how it was verified) survives in full. This is the same category of
  divergence the rule already had for `handoff/HANDOFF.md` (a freshly
  authored note on `main`, not `dev`'s real one), just extended to a file
  previously treated as an exact copy. Applied retroactively to all 20
  existing entries on `main` in the same pass, and folded into the merge
  checklist so every future merge does the rewrite, not just a suffix
  strip.

## ver-0.2.1.0-dev - 2026-09-04

Corrected a stale credibility claim in README.md, and added a standing
self-check to catch this whole class of bug going forward.

- **Why:** README's opening caveat said `main`'s onboarding path "has not
  yet been run through an actual onboarding simulation" — true when it
  was written, but a real two-PC blind simulation campaign ran tonight
  (four cycles, converging on two clean cycles in a row, each
  independently verified) and made the sentence false without anyone
  updating it. The same shape of bug showed up three other times this
  session — two hardcoded version numbers left behind after a bump, and
  Debrief's own handoff note going stale the moment the next session
  touched it — all a sentence stating something as currently true that's
  guaranteed to go stale the moment reality moves past it. `main`'s own
  copy of `handoff/HANDOFF.md` carried the same stale claim in its
  "Current state" section, written there by hand during an earlier merge
  with no template backing it, so the next merge had nothing to correct
  it from.
- **Change:** rewrote the README caveat to reflect the real simulation
  history while staying honest that the project is still young and
  actively changing. Added a carve-out to `luna-core-docs-writer`'s
  branch discipline (both the portable template and the functional copy)
  for Luna-Core's own `main` copy of `handoff/HANDOFF.md`: it no longer
  reuses bootstrap's "just set up, first run" wording (false for
  Luna-Core's own history) or hand-writes its own point-in-time status
  claim — it defers to README's caveat instead, so there's exactly one
  place that claim can go stale rather than two copies drifting
  independently. Also added a short standing "Watch for self-stale
  claims" instruction telling any future docs pass to actively look for
  this pattern.

## ver-0.2.0.4-dev - 2026-09-04

Wording addition only: the Wake Up protocol now covers the case where a
machine has no local copy of the project at all yet, not just a stale one.

- **Why:** the simulation loop found that Wake Up's first step assumed a
  local checkout already existed — it only covered fetching into one and
  reading the handoff notes from one. On a genuinely new machine with
  nothing local at all, there was nothing to fetch into and the handoff
  notes couldn't be read yet either, since reading them requires the
  clone to already exist. A test session facing this had to improvise a
  placement by inferring it from a different machine's leftover clone of
  a sibling dependency — a real first-ever pickup would have had nothing
  like that to go on.
- **Change:** added an explicit step covering the zero-local-copy case,
  ahead of the existing "check HANDOFF.md for where this publishes"
  guidance: clone the project first using whatever location this session
  was actually given to reach it, treat exactly where to place that clone
  as a per-machine judgment call rather than a hardcoded path (matching
  how this kit already leaves other placement decisions open), and once
  the clone exists and `CLAUDE.md` becomes readable, place any sibling-clone
  dependency it names (e.g. Astrid) as a genuine sibling of wherever the
  project landed. Nothing about the existing stale-copy handling changed.

## ver-0.2.0.3-dev - 2026-09-04

Wording clarification only: README.md's Getting Started step 5 now makes
clear that a subagent carrying out this step must still attempt to ask
about Astrid, not just a top-level session talking directly with a person.

- **Why:** the simulation loop caught a subagent given this exact step,
  with the exact same wording, sometimes skip asking entirely — deciding
  on its own that it was "non-interactive" and jumping straight to the
  documented fallback (bring her in) without ever attempting to ask, even
  though its own dispatcher was fully capable of relaying the question to
  a real person and returning a real answer. A separate test run showed
  that relay chain working correctly when the subagent did attempt to ask,
  so the mechanism was never broken — only the wording's silence on
  subagents let one talk itself out of trying.
- **Change:** added an explicit clarification, next to the existing "wait
  on a real answer" sentence, that a subagent's turn ending on the
  question still counts, because its own dispatcher is the next link
  toward a real person, not a dead end. Also tightened the fallback's
  trigger condition from the looser "a fully non-interactive bootstrap run
  has no way to get a real answer" to concrete evidence no human is
  anywhere in the loop at all (e.g. explicitly told this is a fully
  automated/headless run) — being "just a subagent" is never itself that
  evidence. No change to the underlying policy, which is still
  opt-out-by-default with a real decline required to skip Astrid.

## ver-0.2.0.2-dev - 2026-09-04

Wording clarification only: `debrief.md` step 3's "anything uncommitted"
handoff-note bullet now excludes Debrief's own pending commit/publish
decision.

- **Why:** the simulation loop's cycle 4 caught a real bug — Debrief writes
  `HANDOFF.md` before asking for commit permission, so on a project's
  first-ever commit (or any time the note truthfully says "not committed
  yet") that sentence ships baked into the very commit that makes it false.
  Same root cause as the earlier version-staleness fixes: a fact restated
  in committed prose that the next documented step is guaranteed to
  invalidate. Wake Up's step 3c already independently checks live git
  state rather than trusting `HANDOFF.md` for this, so the note was never
  load-bearing to begin with.
- **Change:** clarified that the bullet covers genuinely separate
  uncommitted work still open beyond the session, not this Debrief's own
  in-flight commit decision. Applied identically to both `commands/debrief.md`
  (template source) and `.claude/commands/debrief.md` (functional copy) to
  keep them in sync.
- Closes open item `debrief-self-stale-handoff-note` in
  `tests/notes/open-items.md`.

## ver-0.2.0.1-dev - 2026-09-04

Wording clarification only: README.md's Getting Started step 5 now spells
out what "wait on a real answer" means for the Astrid question.

- **Why:** this session's cycle-3 simulation test confirmed the mechanism
  already works correctly — a non-interactive dispatch ends its turn with
  the question and gets re-invoked with the answer, which is exactly how a
  live interactive session also naturally works (ask in chat, the turn
  ends, the user's next message continues it). Nothing was implemented
  wrong; the old wording just didn't name that mechanism, which could read
  as implying synchronous in-turn blocking to a future reader.
- **Change:** added one clarifying clause to step 5 — no change to the
  underlying policy, which is still opt-out-by-default with a real decline
  required to skip Astrid.
- Closes open item `readme-step5-turn-semantics` in
  `tests/notes/open-items.md`.

## ver-0.2.0.0-dev - 2026-09-04

Policy change: Astrid (the personality/voice layer) is now brought in by
default when bootstrapping a new project, instead of purely opt-in.

- **Why:** a simulation-loop test this session ran a blind fresh bootstrap
  through README.md's existing Getting Started flow, and `luna-core-qa-tester`
  confirmed Astrid never gets adopted unless a user proactively asks for
  her — exactly what the old wording specified. That was correct behavior
  under the old policy, but the user decided the policy itself should flip:
  most people bootstrapping a project want the same personality this kit was
  itself developed with, and shouldn't have to already know to ask for it.
- **New default:** README.md's Getting Started step 5 now has the session
  introduce Astrid right after bootstrap finishes — a short blurb on what
  she is, a plain statement that she'll be brought in unless the user says
  otherwise, and a direct question the session waits on for a real answer.
  Declining skips the clone and removes the "Personality & voice: Astrid"
  bullet from the new project's generated `CLAUDE.md`, so an opted-out
  project doesn't carry a dangling reference. Accepting — or defaulting,
  only when no interactive answer is possible at all — clones her as a
  sibling exactly as that bullet already describes, and now also confirms
  `PERSONALITY.md`/`VOICE.md` actually landed rather than trusting the
  clone command's exit code.
- **Unchanged:** `scripts/bootstrap-new-project.sh` itself still
  unconditionally generates the descriptive Astrid paragraph in every new
  project's `CLAUDE.md` toolkit section — that text is harmless reference
  material with no side effect on its own. The clone-or-not decision and
  the conditional bullet removal both happen as session-level follow-up
  steps per README's instructions, not inside the script.

## ver-0.1.6.3-dev - 2026-09-04

Doc-only fix: CLAUDE.md's "This project's toolkit" section no longer
hardcodes the current version number in prose.

- **Why:** versioning here is immediate — every commit-worthy change gets
  its own new CHANGELOG.md version header right away, per this file's own
  "Versioning & CHANGELOG entries" rules. A line stating "currently
  ver-X" in CLAUDE.md therefore went stale on essentially every commit,
  and had already needed manual re-syncing more than once.
- **Root cause:** this line had drifted from a pattern that was already
  correct elsewhere in this same repo. `scripts/bootstrap-new-project.sh`
  generates this exact toolkit section for every other project bootstrapped
  from Luna-Core, and its own template line reads "started at ver-X" —
  a permanent historical fact — rather than "currently ver-X." Luna-Core's
  own self-hosted CLAUDE.md had deviated from that correct template
  wording at some point in its history; nothing else needed to change.
- **Fix:** reworded the line to "started at `ver-0.1.0.0-dev`" (Luna-Core's
  actual first CHANGELOG.md entry), deferring "what's the current version"
  to CHANGELOG.md — the real single source of truth — instead of
  duplicating a number that changes constantly. Checked README.md and the
  rest of CLAUDE.md for any other instance of this same hardcoded-current-
  version pattern; none were found (CLAUDE.md's other `ver-0...` mentions
  are the versioning scheme's own generic example numbers, not claims
  about the current version, so they were left alone).
- **This line should never need touching again on a routine version
  bump.** A future session should not "fix" it back to a hardcoded
  current-version number.

## ver-0.1.6.2-dev - 2026-09-04

Doc-only change: a wordiness/concision trim on README.md and on this
CHANGELOG.md itself. No feature or behavior change — substance (bug
mechanisms, measured numbers, caveats) was deliberately preserved
throughout.

- **README.md** — collapsed a three-way restatement of the same point down
  to one, dropped a straw-man negation, and merged two sentences that were
  saying the same thing twice.
- **CHANGELOG.md** — trimmed two closing-sentence restatements that
  repeated what their entry had already said.

## ver-0.1.6.1-dev - 2026-09-03

Small bug fix: the functional `/wake-up` command file had fallen out of
sync with its own template source.

- **Brought `.claude/commands/wake-up.md` back in sync with
  `commands/wake-up.md`.** The prior commit (`ver-0.1.6.0-dev`) added a new
  step to the template — checking for a sibling-clone dependency such as
  Astrid — but that addition landed only in the template file and was
  missed in the functional copy Claude Code actually reads when someone
  runs `/wake-up`. The gap was caught during that prior commit's own merge
  diligence. This commit copies the template's current content into the
  functional file so the two are byte-identical again, meaning `/wake-up`
  now actually runs the sibling-clone check as intended. No behavior
  beyond that sync changed.

## ver-0.1.6.0-dev - 2026-09-03

Large bug fix: `merge-memory.sh`'s `MEMORY.md` union only ever wrote back in
one direction. Found independently of the two-PC simulation-loop batch
below — during a routine memory-merge step in an earlier pass — so it gets
its own version bump rather than folding into that one.

- **Fixed `merge_index()` silently dropping one side's exclusive entries
  when the other side was a strict superset.** The write-back that copies
  the unioned `MEMORY.md` pointer lines back to both sides was gated on a
  counter that only incremented when the *older* side contributed a new
  entry to the union. If the *newer* side already had everything the older
  side had, plus an entry the older side lacked entirely, the older side
  never received that entry — the gate never opened. The run still exited
  0 with no warning, and in some cases printed `MEMORY.md: differs`
  immediately followed by the contradictory `Both sides already agree.
  Nothing copied.` This ran directly against the function's own documented
  purpose and against `ref/docs/merge-memory.md`'s description of the same
  union behavior. Fixed by adding a second scan over the newer side's own
  entries (a `gap` counter, alongside the existing `added` counter) and
  widening the write-back gate to fire when either counts anything. Does
  not touch the pre-existing conflict path — same-target entries with
  differing wording still correctly refuse to auto-resolve.

## ver-0.1.5.0-dev - 2026-09-03

Two real defects found by a two-PC blind onboarding/handoff simulation test
(cycle 1) and fixed, landing together as one large-bug-fix bump.

- **Fixed `bootstrap-new-project.sh` mangling the one filename it must never
  rename.** The `awk` rename chain that copies each `agents/luna-core-*.md`
  template into a new project's `.claude/agents/` (renaming `luna-core-` to
  `<projectname>-` throughout) was blindly matching the literal,
  deliberately-never-renamed filename `validate-luna-core-setup.sh`
  wherever it appeared inside agent body text — two places in
  `luna-core-docs-writer.md` — turning it into a broken reference like
  `validate-simtestproject-setup.sh` in every single project ever
  bootstrapped from this repo. Fixed by shielding that literal filename
  behind a placeholder token before the rename substitutions run, then
  restoring it afterward. The more serious of the two fixes in this batch —
  real, shipped corruption, not just a documentation gap.
- **`commands/wake-up.md`'s full sweep now checks for a sibling-clone
  dependency (e.g. Astrid) and confirms it's actually present.** A new step,
  3a-ii, reads this project's own `CLAUDE.md` toolkit section for a
  "Personality & voice" line; if one exists, it clones the sibling fresh at
  the documented path/branch when the directory doesn't exist yet (the
  new-machine case) or runs `git -C <path> pull` when it does, then confirms
  the expected files (e.g. `PERSONALITY.md`/`VOICE.md`) are actually
  present afterward. Before this fix, wake-up.md never mentioned Astrid at
  all, so a blind Wake Up session on a genuinely new machine never checked
  for her — `CLAUDE.md`'s existing `git -C ../Astrid pull` instruction
  silently assumes the clone is already there, which it never is on a
  machine that's never worked on this project before. Caught by an actual
  blind-subagent simulation run that hit exactly this gap.

## ver-0.1.4.0-dev - 2026-09-03

Large bug fix: the one machine-level path a stranger's AI session is supposed
to trust for bootstrapping a new project could silently land on the wrong
branch.

- **`scripts/install-global-entrypoint.sh`'s two generated clone commands now
  pin `-b main`.** Neither the pointer block it writes into a machine's global
  `CLAUDE.md` nor the generated `/new-project` command specified a branch, so
  a fresh machine-level bootstrap would silently follow whatever GitHub
  reported as the default branch — which was still `dev`, even though the
  README already told humans to clone `-b main` explicitly. Both generated
  paths now agree with the README instead of one being a stale trap for
  anyone who ran the other.
- **Flipped Luna-Core's actual GitHub default branch from `dev` to `main`**
  (`gh repo edit --default-branch main`, confirmed via `gh repo view`), so a
  bare `git clone` with no flags at all — not generated by either path above —
  also now lands on `main`. A repo setting, not a code change, but a real
  behavioral change to this project's own hosting worth recording alongside
  the fix it complements.
- **Trimmed a now-stale line in the same script:** the failure message after a
  failed clone used to blame "no network, or this machine not being
  authenticated to a private repository." Luna-Core is public now, so the
  second cause no longer applies — it now just says "the likeliest cause is
  no network."

## ver-0.1.3.1-dev - 2026-09-03

Doc-only: `main` is live now, and `README.md`'s "Agents" section still
described docs-writer's job using the framing that `ver-0.1.3.0-dev` had
already superseded — "these paths never reach `main`" — rather than the
resolved policy (the path survives with placeholder content; only this
project's own real working state stays on `dev`). Caught and fixed on
`main` itself before that commit, and now applied here too so `dev`'s copy
doesn't drift back into stating a rule that no longer holds.

## ver-0.1.3.0-dev - 2026-09-03

Fixed the front door, ahead of this project being public. A stranger arriving
here — a person or an AI session — had nowhere to start, and one of the few
instructions actually aimed at them could not be run as written.

- **`README.md` rebuilt around someone who has never seen this project.** It
  used to open with a "Current state" status report and read as a development
  log, offering no onboarding path at all, and its example bootstrap command
  hardcoded the author's own machine path — so anyone who copied it ran a
  command pointing at a directory that does not exist on their computer. The
  command now uses `<path-to-luna-core-clone>` placeholders, and a numbered
  "Getting started" section leads with clone, bootstrap, validate, open.
  Maintainer-only material (the copy-from-it-never-write-back rule, per-machine
  setup, publishing) moved into a "Maintaining a Luna-Core checkout itself"
  section at the bottom, where it reads as reference rather than as a barrier
  standing between a newcomer and step one. Nothing was dropped, only
  reordered.
- **Added the disclaimers this needed before going public:** that it is a
  vibe-coded personal project rather than a maintained product, that it is
  built specifically around Claude and does not target other AI tools, a dated
  development-status line, and an instruction to clone `main` rather than
  `dev`.
- **Stated the contribution policy plainly** — issues welcome, pull requests
  not reviewed or merged. There is no repository setting that actually
  prevents a pull request from being opened, so this has to be a stated
  policy rather than a switch, and staying silent about it would waste a
  stranger's time on work that was never going to be merged.
- **`CLAUDE.md` now tells a cold session what its first action is.** The file
  loads automatically, so the rules were always in front of a stranger's
  session — but nothing told that session to orient itself first, and the Wake
  Up protocol only triggers on phrases like "wake up" that someone new here
  would never think to say, so nothing would ever prompt it. A new opening
  section has such a session work out whether it is sitting in a Luna-Core
  checkout or in a project bootstrapped from one (using the same tell the
  setup validator already uses, rather than a second test that could drift
  away from it), run the validator instead of assuming the setup is sound, and
  read the README's "Getting started" section when it turns out to be in
  Luna-Core itself.
- **Settled what the `main` branch actually carries, before creating it.** The
  rule had always been that this project's own working files never reach
  `main`. Read as "those paths are absent from `main`," it would have produced
  a branch that fails its own setup validator on a fresh clone — the validator
  requires the handoff files, the memory folder and the agent definitions to
  exist, and every project's `CLAUDE.md` sends sessions to those paths too.
  The rule is now stated the way it was already applied to the reference-docs
  folder: the *path* survives on `main`, carrying generic or template content,
  and only this project's own accumulated and machine-specific content is left
  behind. Recorded in the docs-writer agent, which owns the branch rules, so
  the next merge follows the resolved version rather than rediscovering the
  problem. The memory folder also gained the keeper file it had been missing
  all along — it happened to be safe only because it currently holds real
  files, and would have vanished from the next clone the moment it didn't.

## ver-0.1.2.2-dev - 2026-09-03

Doc-only: made the Astrid pointer explicit about which branch, since it
previously just said "clone this repo" without naming one.

- **Both the `CLAUDE.md` bullet and `bootstrap-new-project.sh`'s generated
  copy now say `dev` explicitly**, and note that Astrid's `main` has been
  retired — it was a pure mirror of `dev` (verified: zero commits unique to
  `dev`, no content difference beyond version-stamp wording), so maintaining
  a second branch was pure overhead for zero benefit. `dev` is also already
  that repo's default branch, so a plain clone already got it — this just
  makes the intent explicit rather than leaning on a default that could
  change without anyone here noticing.

## ver-0.1.2.1-dev - 2026-09-03

Doc-only addition: pointed Luna-Core at Astrid, its sibling personality-and-voice
spec, instead of bundling her in.

- Astrid (https://github.com/LunaBelleElite/Astrid) is developed as its own
  repo so she can be adopted, updated, and versioned independently of any
  one project's toolkit, rather than merged into each project that uses
  her. Luna-Core now references her by pointer instead of copy.
- Added a "Personality & voice" bullet to Luna-Core's own `CLAUDE.md`
  toolkit list, describing Astrid as a sibling clone (e.g. `../Astrid` next
  to this project) and pointing to her `PERSONALITY.md` and `VOICE.md`
  rather than duplicating their content here.
- The same bullet was already added to `scripts/bootstrap-new-project.sh`'s
  generated `CLAUDE.md` template, so every project bootstrapped from
  Luna-Core going forward automatically inherits this same pointer to
  Astrid without any manual step.

## ver-0.1.2.0-dev - 2026-09-03

Two real, previously-undetected defects found by testing and fixed, landing
together as one large-bug-fix bump.

- **Fixed silent exit-0 masking in `check-prerequisites.sh`.** The trailing
  "nothing declared" branch was keyed on `$checked` (only incremented for
  lines that passed the regex-validity guard) instead of on everything
  actually declared. A config whose *only* line had an invalid regex set
  `status=1`, printed the correct `NOTE:` about the bad pattern, then hit
  the "nothing declared" branch anyway — since that one line was never
  counted as checked — printed `OK: no runtime prerequisites declared for
  this project`, and exited 0, silently discarding the failure it had just
  reported one branch earlier. The mask was conditional, not universal: a
  second, valid entry alongside the bad one made the run fail correctly,
  which is exactly the kind of intermittence that hides a bug. Fixed by
  keying that branch on what was declared instead of what was successfully
  checked. This was the first time this code path had ever run against a
  real, non-empty config — see the next item for why.
- **`ref/prerequisites.conf` now declares real prerequisites**: Git, GNU
  sed, and GNU find, replacing the empty stub. Sed and find are declared
  specifically because three of this project's own scripts rely on
  GNU-specific flags (`sed -i` with no backup suffix, `find ... -printf`)
  that a non-GNU sed/find doesn't provide. This is what let the bug above
  actually be exercised for the first time, rather than reasoned through
  from source alone.
- **Rebuilt the template-vs-functional drift check** in
  `validate-luna-core-setup.sh`. The old design diffed the two sides and
  then filtered the diff, dropping any differing line that merely
  *contained* an expected token — measured to be blind to 18.5% of lines
  across the three fill-in agents, and capable of silently waving through
  a semantic inversion of a behavioral constraint. The new design
  normalises both sides onto shared sentinels before comparing, so every
  remaining difference is real drift by construction, with no allowlist
  left to leak through. Landed with it: a fill-in region (`## Stack`,
  `# PART TWO`) must now exist on both sides, or deleting one wholesale no
  longer reports clean; content drift now fails the run instead of only
  ever printing an informational note; and the CLAUDE.md agent-roster
  reverse-check now walks every agent file on disk instead of only
  role-suffixed ones, so an orphan agent filename is no longer invisible
  to the whole validator. The rebuilt check found one real drift on its
  first live run: the research agent's functional copy had lost a
  `(branch `dev`)` parenthetical, previously masked by the old filter.
  Resolves the two open items this had been tracked under
  (`tests/notes/open-items.md` OI-1 and OI-2).
- **Extended `CLAUDE.md`'s interface-verification rule to plan tasks, not
  just tests**, and added a new rule requiring a row-by-row conflict scan
  before dispatching parallel agents rather than a verbal "looks clean."
  Doc-only, no code involved, folded into this batch's bump rather than
  given its own.

## ver-0.1.1.1-dev - 2026-09-03

Documentation-only batch: `ref/docs/` goes from empty to populated, and a
branch-scoping question about it gets ruled on. No code changed and no
defect was fixed, so this stays a 4th-number bump rather than a core-feature
one — see the reasoning below.

- **Populated `ref/docs/` with one page per script**, plus `ref/docs/README.md`
  as an index: `bootstrap-new-project.md`, `check-prerequisites.md`,
  `check-superpowers.md`, `install-global-entrypoint.md`,
  `lib-claude-home.md`, `merge-memory.md`, and `validate-luna-core-setup.md`,
  covering the seven scripts in `scripts/`. `CLAUDE.md` has always told every
  session to consult `ref/docs/` before reading source, but the folder was
  empty, so that instruction pointed at nothing while 1,847 lines of shell
  sat unexplained. Each page covers what its script does, how it's invoked,
  what it writes inside versus outside the repo, its refusal conditions, and
  the non-obvious traps mined from source comments — several of which record
  real failures. The pages cite `tests/notes/live-checks.md` for measured
  behavior rather than duplicating it.
- **Ruled: `ref/docs/*.md` pages are dev-only, not shared with `main`.**
  `main` is what a fresh consumer clones — someone who has never run this
  project — and these pages document *this* project's own internals, useless
  and confusing to that reader. This reverses the previous assumption (that
  `ref/docs/*.md` shipped on both branches like `CLAUDE.md`/`README.md`/
  `CHANGELOG.md`) and is now encoded in both `luna-core-docs-writer` copies
  (`agents/` and `.claude/agents/`), `CLAUDE.md`, and `README.md`.
  `ref/docs/` itself keeps the partial exception it already had for its
  folder-plus-keeper-file: the pages are stripped at merge time like
  `.claude-memory/`, `handoff/`, and `.claude/agents/*.md`, but the empty
  folder and its `.gitkeep` survive on `main`, since the "check `ref/docs/`
  first" instruction must still point at something real there — the same
  keeper-file reasoning `CLAUDE.md` already applies to every other
  referenced-but-empty path.

## ver-0.1.1.0-dev - 2026-09-02

Fixes and rulings found by testing after `ver-0.1.0.0-dev` was committed and
pushed (`be3fb7f`) — everything below landed on `dev` afterward, so unlike
earlier passes this genuinely earns its own version rather than folding into
the starting commit.

- **Fixed silent memory loss in `merge-memory.sh`.** The script's whole job
  is reconciling this project's memory index across machines without ever
  losing an entry, but `merge_index()` located each entry's target file by
  matching the *last* parenthesis on its line instead of the one right after
  the link text. An entry whose description happened to end in something
  like "(personal)" got keyed on `personal` instead of its actual filename.
  That produced duplicate entries, and — worse — let two unrelated files
  whose descriptions happened to end in the same parenthetical collapse into
  a single index entry; once collapsed, the file that lost the collision had
  it silently erased from the side that still held it, because a nonzero
  `added` count writes the merged union back to both sides. Exit code 0,
  message "1 file(s) updated" — no error anywhere. The most serious fix in
  this batch: exactly the failure mode this tool exists to prevent. Fixed
  by anchoring the match at
  the start of the line so it reads the bracketed link's actual target
  rather than whatever parenthetical happens to come last.
- **Fixed a false "Updated" from `install-global-entrypoint.sh` on a CRLF
  entry-point file.** The script decided *whether* to replace its managed
  block using a CR-tolerant substring match, but then performed the
  replacement with an exact line match — the two disagree on a file with
  Windows line endings, so the script reports success while changing
  nothing. The bug was invisible on this machine, where the local awk
  strips carriage returns automatically, which is exactly why it needed
  catching by other means: this installer's whole purpose is running
  correctly on machines that haven't been tested on directly.
- **Fixed a misread version stamp in `validate-luna-core-setup.sh`.** The
  same greedy-match mistake as the memory-index bug above, in a different
  script: reading the entry point's version stamp took whatever followed
  the *last* occurrence of the marker text instead of the real one, which
  could report a stale entry point as current (`OK:`) rather than flagging
  it (`NOTE:`) in a bootstrapped project.
- **Fixed leftover advice in `validate-luna-core-setup.sh` for a removed
  argument.** Every freshly bootstrapped project was being told to pass a
  `<hub-folder>` argument to the entry-point installer that the installer no
  longer accepts — the second instance of this exact "advice that cannot be
  followed" shape found in this file.
- **Ruled: Fable is manual-only.** The assistant routes dispatches across
  Sonnet and Opus only, on any license tier — Fable is never dispatched by
  the assistant; the user invokes it themselves when a project calls for
  it. Recorded directly in `CLAUDE.md` so every project bootstrapped from
  Luna-Core inherits the boundary, not just this machine's local memory.
- **Added `CLAUDE.md` section 5, "Verify Interfaces Before Testing."** A
  test written against an interface nobody confirmed exists is worse than
  no test at all — it creates false confidence and pushes discovery of the
  real interface from planning time into implementation time. The new
  section requires confirming an interface actually exists, by reading
  source or type definitions, before writing a test against it.
- **Corrected the recorded Claude license tier** in `.claude-memory/` from
  Business Standard (teams) to Max 5x (personal) — the wrong tier had been
  silently under-routing dispatches to Sonnet — and added
  `feedback_fable_manual_only.md` to record the Fable boundary above outside
  any one project's `CLAUDE.md`.
- **Extended test coverage** for all three script fixes above, plus a newly
  documented blind spot in the template-vs-functional drift check: its
  filter for lines mentioning `luna-core-` is broad enough to silently wave
  through a semantic edit to any line containing that token, including an
  inversion of a "what you don't do" constraint. Two open questions from
  that work are tracked in `tests/notes/open-items.md` as OI-1 and OI-2.

## ver-0.1.0.0-dev - 2026-09-02

Luna-Core's starting state: the starter kit every project on this machine is
bootstrapped from.

- Four agent templates (`luna-core-docs-writer`, `luna-core-research`,
  `luna-core-qa-tester`, `luna-core-implementer`), in `agents/` as template
  source and `.claude/agents/` as the functional copies Claude Code invokes.
  **Agent identifiers are lowercase**, `<projectname>-<role>`; bootstrap
  lowercases the project name for them, so `TestProj` yields
  `testproj-qa-tester` while prose still reads `TestProj`. The templates keep
  their fill-in blanks (`<projectname>`, `<directory>`, qa-tester's `## Stack`,
  implementer's Part Two) for a new project to fill in; Luna-Core's own
  functional copies have them filled in, and the validator excludes those
  regions when comparing the two.
- The Wake Up and Debrief session protocols, as `/wake-up` and `/debrief`.
- A baseline `CLAUDE.md` carrying the operating rules every bootstrapped
  project inherits, including this versioning scheme.
- `scripts/` — `bootstrap-new-project.sh` to set up a new project,
  `validate-luna-core-setup.sh` to confirm it landed, `merge-memory.sh` for
  memory that roams between machines, `install-global-entrypoint.sh` for the
  machine-level entry point, and the dependency/prerequisite checks.
- `scripts/lib-claude-home.sh` resolves Claude's config directory from
  `CLAUDE_CONFIG_DIR` when it is set, falling back to `$USERPROFILE/.claude`
  and `$HOME/.claude`. Without that first branch, a machine that sets
  `CLAUDE_CONFIG_DIR` has every script read and write where Claude Code never
  looks.
- The setup validator enforces `CLAUDE.md`'s "a referenced folder must be
  created, with a keeper file" rule in full: `check()` proves a folder exists,
  `check_keeper()` proves it still holds a file. It guards the two folders that
  are backed by nothing but a `.gitkeep` — `ref/docs/` and `.claude-memory/`;
  every other referenced folder has a mandatory file checked by name. Git tracks files rather than
  directories, so a folder whose keeper was deleted is simply absent after the
  next clone — a failure that appears on the second machine, not the first.
  The recipe for re-proving it is in `tests/notes/live-checks.md`.
- The hub is a private GitHub repository at
  `https://github.com/LunaBelleElite/Luna-Core.git`, wired as `origin` on
  `dev`. Neither the hub nor the working copy at
  `C:\Users\Owner\Documents\Claude\Luna-Core` sits in a folder synced by a
  consumer cloud-sync client, so the corruption risk that a bundle-based hub
  guards against does not apply here — an ordinary `git push` is the publish
  step.

Not yet set up: the repository exists but is empty — nothing has been
committed, tagged, or pushed yet. See README's "Publishing" section.

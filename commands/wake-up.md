---
description: Wake Up Protocol — pick up this project after time away, checking for a machine switch and catching up as needed
---

# Wake Up Protocol

Pick up this project after time away. Run through these steps in order.

## 1. Fetch the latest published state

Before checking anything, make sure you're not looking at a stale local
copy. Fetch/pull from wherever this project's remote actually is — a live
git remote, or a bundle file — so local `dev` reflects what was actually
last published.

**Look in `handoff/HANDOFF.md` first**, under "Where this project
publishes". That is the file Debrief maintains and bootstrap always
creates, so it is the one place guaranteed to exist and to have been
updated by the last session. A project's `README.md` may also record it
(Luna-Core's own does) — check there second, and note the disagreement
if the two differ rather than silently preferring one.

A clone does not carry the address it came from, so if neither file records
it, a session on a new machine genuinely cannot discover it.

**If there's nothing real to fetch yet** — either `git remote -v` is empty,
or a remote is configured (e.g. a local bare repo or bundle) but
has zero commits so the fetch is a silent no-op — and `HANDOFF.md` still
says nothing is published yet: this is normal for a project freshly
bootstrapped from Luna-Core. Don't treat it as an error: skip this step,
note in your final report that nothing has been published yet, and ask the
user where they'd like this project's remote/publish location to live so it
can be recorded in `handoff/HANDOFF.md`'s "Where this project publishes"
section for future Wake Ups to use.

## 2. Check for a computer switch

Read `handoff/STATUS.md` for the last-recorded computer name. Get this
machine's actual computer name (`hostname` on macOS/Linux/Git Bash,
`$env:COMPUTERNAME` in PowerShell).

- **Same computer as last recorded:** this is a quick check, not a full
  sweep. Confirm local `dev` is up to date with what was just fetched, and
  that `README.md`/`CHANGELOG.md` reflect what's actually published. Also
  do two cheap things that don't need a machine switch to be worth
  noticing: report any uncommitted changes, and confirm this project's
  local auto-memory directory isn't empty or absent (if it is, run the
  merge in step 3a — an empty memory bucket is worth catching even on a
  familiar machine, since it means nothing has been loaded). Then run
  `bash scripts/check-superpowers.sh --quick`: the superpowers plugins are
  installed per-machine, not per-project, so one can be uninstalled or wiped
  by a Claude Code update without this machine's name ever changing — which
  the full sweep would never get a chance to notice. `--quick` tests presence
  only and skips the functional Python run, so it stays cheap enough for
  every wake. If it reports anything missing, surface the install commands it
  prints; they have to be run by hand (see step 3b). If everything
  matches, stop here — report ready to continue, no further action needed.
- **Different computer, or no prior record in `handoff/STATUS.md`:**
  proceed to the full sweep below.

## Standing rule: never report a missing thing without telling the user how to get it

This applies to **every** check in this protocol, not just the ones that
happen to spell it out below.

If any check finds something absent from this machine — a plugin, a runtime,
a skill pack, a machine-level file, a tool a script depends on — then:

1. **Install it if you safely can.** Some things are yours to fix: a memory
   merge, a re-run of `install-global-entrypoint.sh`, a missing folder.
2. **If you can't, give the exact commands.** Not "install .NET" — the actual
   command line for this machine, plus where it came from. Most of the checks
   here already print theirs (`check-superpowers.sh` prints install blocks;
   `check-prerequisites.sh` prints the `>` hints declared alongside each
   entry in `ref/prerequisites.conf`). Pass those through to the user
   verbatim rather than paraphrasing them.
3. **If nothing here has instructions for it, work them out — don't stop at
   "not declared."** This is the case nobody could anticipate in advance, and
   it's the one where you're most useful. You are an AI agent reading this: if
   something needed is absent and no script declares how to get it, then
   identify what it actually is, determine how it installs *on this machine*
   (this OS, this package manager, this shell — check what's actually
   available rather than assuming), and either do it if it's safely within
   your remit, or hand the user a specific, ready-to-run command. Research it
   if you don't know. "No install instructions are declared" is a starting
   point for you, not an answer for the user.

   Two things to keep straight while doing that:

   - **Say how confident you are, and how you got there.** A command you ran
     and saw succeed, a command from official documentation you actually
     read, and a command you inferred from convention are three different
     things — label which one you're handing over. Never present a guess as
     verified.
   - **Ask before anything with real consequences.** Installing a runtime,
     elevating privileges, piping a remote script into a shell, or changing
     machine-wide configuration is the user's call, not yours. Bring them the
     command and the reasoning; let them run it.

   Then close the loop: once it's resolved, add it to the right declaration —
   `ref/prerequisites.conf` with `>` install hints for a runtime or tool — so
   the next machine is *told*, not left to rediscover it. An unanticipated
   dependency should only be unanticipated once.

4. **Do not report the project as ready to work on.** Say which items are
   outstanding and that they need to be handled first. A cheerful "ready to
   continue" over a missing dependency is the failure this rule prevents:
   the breakage surfaces later, somewhere unrelated, with no obvious cause.

Reason it's a standing rule rather than per-check prose: a new machine is the
one situation where *several* of these are missing at once, and that's exactly
when the protocol is most load-bearing. The declared checks below cover what
was known when they were written; this rule covers everything else, which is
why it's phrased around judgment rather than a fixed list. Anything that
reports a problem without a route out of it just moves the work onto whoever
has the least context — usually the person on a brand-new machine who wanted
to start working, not to debug an install.

## 3. Full sweep (different computer, or first run)

This is the "is this machine actually ready to work on this project" path,
not just a briefing. Do the environment steps first — the rest of the
sweep's judgment depends on them.

**3a. Merge the memory, before anything judgment-based.**

Run `bash scripts/merge-memory.sh` (if this project has it). On a machine
that has never worked on this project, this is what turns a clone into a
working setup — the repo carries the memory, but nothing loads it unless
this runs.

Read what it reports. It never flat-copies, and it deliberately leaves
some things for you: a file present on only one side (copied across,
never deleted, because absence has no timestamp to judge), and a file
with the same timestamp but different content. Surface those to the user
rather than passing over them.

**If memory was restored, say so explicitly in your final report, and
say whether it's in effect yet.** Memory files are read from disk, so
newly arrived ones should be available going forward — but if anything
you then read suggests otherwise, tell the user to restart the session
rather than quietly proceeding as though the memory is live.

**3b. Run the setup validator.**

Run `bash scripts/validate-luna-core-setup.sh`. One call covers the
file layout, whether every agent was renamed, template-vs-functional
agent drift, this machine's Luna-Core entry point, the superpowers
plugin dependencies, and any runtime prerequisites this project declares
in `ref/prerequisites.conf`.

Read its output rather than treating its exit code as the verdict: it
distinguishes `MISSING` (a real failure) from `NOTE` (informational —
e.g. a placeholder that's *meant* to be filled in later). Report the
`MISSING` lines prominently and the `NOTE` lines as follow-ups.

**The superpowers dependencies cannot be installed for the user, and this
is the step where that matters most** — a brand-new machine is exactly
where they'll be absent. `superpowers-extended-cc` installs through
`/plugin marketplace add` and `/plugin install`, which are slash commands
that only work *inside* an interactive Claude session, so no script can run
them. Claude Code on Steroids installs by piping a remote shell script from
GitHub into bash, which shouldn't be run automatically on the user's behalf.
So when either is reported missing: surface the exact commands
`check-superpowers.sh` printed, say plainly that the user has to run them,
and note that a Claude Code restart is needed afterward before the skills
appear. Don't report the project as ready to work on until they're in
place — everything in `CLAUDE.md`'s "Always do these" assumes both exist.

**3b-ii. Fix agent repo paths for THIS machine.**

If the validator reported an agent whose recorded repo path belongs to another
machine, fix it now — this is one of the things you safely can, so per the
standing rule above, do it rather than reporting it. Update the path in each
named `.claude/agents/*.md` to this checkout's actual location, and say which
files you changed.

This is a real consequence of the toolkit's own design: agent definitions
record an absolute repo path, memory and handoff notes roam between machines,
and so the paths inside those definitions arrive stale on the new machine. A
stale path is a perfectly well-formed line — nothing about it looks wrong —
so the agent simply looks for files that aren't there, and the failure reads
as the agent being broken rather than as a path needing one edit.

**3c. Report the git state — don't resolve it.**

Check for uncommitted changes, and whether local `dev` is behind or has
diverged from what's published. Report what you find and stop there.
Never auto-resolve: unlike memory, these files are git-tracked, and git
already detects conflicts properly. Silently picking a winner here would
throw away the very protection git provides.

Then continue with the briefing half of the sweep:

- Read `handoff/HANDOFF.md` in full — the previous session's handoff
  notes, written specifically so you'd know what to do here.
- Review recent commits, `CHANGELOG.md` entries, and `README.md` for
  anything that changed since the last-recorded check.
- Review `.claude/agents/*.md` for every agent defined in this project.
- **Functionally test each agent — don't just confirm the files exist.**
  Actually invoke each one with a trivial, low-cost task (e.g. "briefly
  confirm your role and that you're reading current instructions") and
  confirm it responds sensibly, off the current file content. Report which
  agents were tested and the result — presence isn't proof it works.
  **If this session's tooling can't actually invoke this project's own
  agents by name** (e.g. it's not rooted at this project, so a same-named
  agent from elsewhere gets invoked instead, or no such tool is available
  at all) — don't silently skip this or invoke the wrong thing. Fall back
  to reading each agent file directly and manually working through what it
  would do for the trivial task, and say plainly in your report that this
  was a simulated check, not a real invocation.
- Note anything from `handoff/HANDOFF.md` that still needs attention or
  follow-up.
- Confirm the recorded Claude license tier still looks right (see `CLAUDE.md`'s
  "Match model to license tier and task" — which model to use depends on it). A
  machine or account switch is exactly the kind of thing that changes it, which
  is why this belongs here and not in the quick-check path above. If there's no
  record of it, or this looks like a different account than the one recorded,
  ask rather than assuming the old answer still holds.

## 4. Update the tracking record

Write this machine's computer name and the current date/time into
`handoff/STATUS.md`, regardless of which path above was taken.

## 5. Report back

Give a brief, friendly summary — a little personality here is welcome,
this is the moment the user actually sees. Say whether this was a quick
check or a full sweep, what (if anything) changed since last time, and
what's ready to pick up. If something needs the user's attention
(uncommitted work found elsewhere, an agent that didn't respond correctly,
no handoff notes found from a prior session), say so clearly before moving
on to anything else — don't bury it.

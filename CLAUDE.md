# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## If this is your first look at this project

Claude Code loads this file automatically, so a session that has never seen this project before still arrives holding these rules — but holding the rules is not the same as knowing where you are. Do the three steps below once, at the start of any session with no established context on this project, before proposing or changing anything.

Do them unprompted. The Wake Up protocol described near the bottom of this file is the fuller version of this, but it fires on phrases like "wake up" — and someone who has never used this toolkit has no reason to say them, so waiting to be asked means never being asked.

**1. Work out which of two things you are looking at.** Use the same tell `scripts/validate-luna-core-setup.sh` uses for its own `IS_LUNA_CORE` branch — don't invent a second, divergent test:

- `agents/` **and** `scripts/bootstrap-new-project.sh` both present → this is a checkout of **Luna-Core itself**, the starter kit other projects are built from. Bootstrap copies neither of those into a project, so the pair together is a reliable tell.
- Otherwise → this is **a project bootstrapped from Luna-Core**. The toolkit section directly below describes that project's own agents, commands and version, not Luna-Core's.

**2. Confirm the setup rather than assuming it.**

```bash
bash scripts/validate-luna-core-setup.sh
```

A clean exit means the paths this file sends you to actually exist. A `MISSING:` line means an instruction you are about to follow points at nothing, which is a setup problem to resolve first, not a thing to work around. `NOTE:` lines are informational and do not fail the run.

**3. Then orient on which case you are in.**

- **Luna-Core itself** → read `README.md`'s "Getting started" section before suggesting anything. Most people who open a Luna-Core checkout want to bootstrap a *new* project from it, not develop the kit itself; that section is the path, and the two jobs want completely different first moves. Say which one you think is happening and confirm it rather than guessing.
- **A bootstrapped project** → if there is prior work to pick up, offer the Wake Up protocol rather than reading around at random; it exists to do exactly this properly.

## This project's toolkit

Filled in by `scripts/bootstrap-new-project.sh` when this project was set up from Luna-Core. Keep it current the same as anything else in this file — if an agent gets added/removed/renamed, or a dependency changes, update this section too.

- **Agents:** `luna-core-docs-writer`, `luna-core-research`, `luna-core-qa-tester`, `luna-core-implementer` (functional copies in `.claude/agents/` — that's where Claude Code actually looks to invoke them by name; `agents/` is Luna-Core's own template source, not a working location)
- **Commands:** `/wake-up`, `/debrief` (see `commands/`, copied into `.claude/commands/`)
- **Dependencies:** superpowers-extended-cc, Claude Code on Steroids (see README's "Dependency: superpowers plugins")
- **Personality & voice:** Astrid — maintained separately at https://github.com/LunaBelleElite/Astrid, kept as a sibling clone (e.g. `../Astrid` next to this project) rather than bundled into this repo, so she can be adopted, updated, and versioned independently of any one project's toolkit. Read `PERSONALITY.md` and `VOICE.md` there — not copied here, and not duplicated in this file. Always the `dev` branch, deliberately: her repo has no `main` (retired — `dev` was always kept current, so a second branch just to lag behind it added merge overhead with no real benefit), and `dev` is already that repo's default branch, so a plain clone gets it without a flag. `git -C ../Astrid pull` picks up anything new.
- **Versioning:** currently `ver-0.1.6.0-dev` (see "Versioning scheme" below and `CHANGELOG.md` for the full history)

(This is Luna-Core's own toolkit, listed here since this file is also Luna-Core's own live `CLAUDE.md`. For a new project set up from Luna-Core, `bootstrap-new-project.sh` replaces this list with that project's actual agent names and starting version.)

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Verify Interfaces Before Planning or Testing

**Before a plan task depends on an external API, library method, or internal function — and before any test references one — confirm it exists.**

Catching a phantom interface while writing the plan costs a lookup. Catching the same one while writing the test costs a wasted task. Catching it only at execution time costs a stuck implementer and a rework cycle. It's the same check at every stage; only the price of skipping it changes — so run it at the earliest stage, while planning, not just before testing.

A test — or a plan task — written against an invented interface is worse than none at all. It creates false confidence (it "passes" review, or "passes" as a test, because it exercises a phantom), pushes discovery of the real interface later than it needed to happen, and leaves something broken in the plan or suite that misleads whoever reads it next.

Confirm the interface exists by reading the source or the type definitions — the equivalent for this project's stack of checking a package's shipped types or grepping for the export. For a plan task, that means confirming the dependency is actually declared, the method name and import path are real, and an internal utility's file path, export, and signature all check out — none of it assumed from memory. If you cannot find it, stop and verify the correct interface before writing the task or the test; do not guess.

| Pattern | Problem |
|---|---|
| Importing/calling a method without checking its types or signature | Invented import |
| Asserting on a return value's shape without checking what it actually returns | Invented shape |
| Using a function signature from memory | May be wrong or outdated |
| "the implementer will wire it up" | Test is untethered from any real interface |
| A plan task built on `library.method()` without checking it exists | Plan fails at execution, not at review |

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Always do these

If not already in plan mode, switch to plan mode.

Use SuperPowers (both superpowers-extended-cc and Claude Code on Steroids — see README.md "Dependency: superpowers plugins" for what each provides and how to check/install them)

Use agents and as many as needed to accomplish the tasks in smaller bites.

Give agents access to the skills they need.

Agents should have the same permissions as you do. (updated as you gain more permissions)

Before reading source files, check `ref/docs/` for an explanation of the module or file first. These MD files are the primary reference for understanding what source files do and how they fit together. Only read source files directly when the docs don't cover what you need.

Utilize `ref/docs/` as needed while planning and researching.

Use plan mode first.  Ask clarifying questions until you are 95% confident in the plan.

Update the files in `ref/docs/` with any new information, bugs, or changes on the file once a task is completed.

## A referenced folder must be created, with a keeper file

If any template file — this `CLAUDE.md`, an agent definition, a protocol
command — tells a project to use a path, `bootstrap-new-project.sh` must
create that path, and the setup validator must check it. Otherwise the first
instruction an agent follows points at nothing, which reads as a broken
toolkit rather than as an empty project.

Anything created empty needs a keeper file (`.gitkeep`, or a real stub where
an agent is told to *read* a specific file). **Git cannot track an empty
directory**, so without one the folder exists on the machine that ran
bootstrap and is simply absent after a clone — the failure appears on the
second machine, not the first.

This has already recurred once: the fix was applied correctly to `ref/docs/`
and never extended to `tests/` or `.claude-memory/`, which is why the
validator now checks them rather than trusting that bootstrap got it right.
When you add a path reference to any template, add its creation and its check
in the same change.

This is also why `ref/docs/` is not stripped as a whole from `main`, where a
`main` branch exists, even though its `.md` pages are dev-only and never
reach `main`: this rule says the "check `ref/docs/` first" instruction above
must still point at something real on any branch, including `main`, so the
folder and its keeper file (`ref/docs/.gitkeep`) survive there empty while
only the pages are stripped at merge time. Deleting the whole folder along
with the pages would recreate the exact failure this section exists to
prevent — see `<projectname>-docs-writer`'s "Branch discipline" section for
the merge mechanics.

## Git commits require explicit permission

Never run `git commit`, `git merge`, or `git push` without asking first and getting an explicit yes from the user — every time, not just once per session or once per project. This overrides any inclination in auto mode to proceed without asking.

Commit and push are bundled as one action: once the user approves a commit, push it to the remote right after — no separate ask for that push. `git merge` still requires its own separate explicit permission.

If this project uses the versioning scheme below, tag every commit that adds a new `CHANGELOG.md` version header with an annotated git tag matching that exact version string, pointing at that commit — this is part of the same approved commit action, not a separate ask, so there's always a way back to a known-good point.

## Check for a cloud-sync git remote before assuming `push` is safe

If this project's git remote/hub lives inside a folder synced by a consumer cloud-sync client (Google Drive, Dropbox, OneDrive, iCloud Drive), don't assume normal `git push` is safe long-term — this is a documented, known corruption risk (sync clients don't understand git's atomic writes, and can silently break a live repo, sometimes well after a push already looked successful). Check for this, and if it's the case, note the risk to the user and ask whether they want two fixes applied (don't apply either without asking first, and don't assume every project needs this):

1. Redirect the working copy's `.git` internals out of the synced folder, to plain local storage with no cloud-sync involvement.
2. Use a `.bundle`-file-based hub instead of a live bare repo as the sync-folder "remote" — bundles are just files, not live git internals, so the sync client can't corrupt them mid-write.

(Luna-Core's own hub is a private GitHub remote, `https://github.com/LunaBelleElite/Luna-Core.git` — not a folder on a consumer cloud-sync client, so this risk does not apply to Luna-Core itself. See its README's "Publishing" section for the full detail.)

## Memory roaming across machines

This project's local Claude auto-memory only lives on the machine it was created on by default. To let it roam with the user across machines via git:

One command handles both directions: `bash scripts/merge-memory.sh` (if this project has that script — it's cloned in from Luna-Core). Run it before committing memory changes, and on a machine that may not have this project's memory yet. It's deliberately the *same* operation either way — two directions implemented separately would eventually disagree about what's current.

**Never flat-copy memory in either direction.** The merge compares each file and copies only the genuinely newer one. It uses each memory file's own `modified:` frontmatter, falling back to the file's last *commit* date on the repo side — never the repo file's mtime, because git records no mtimes, so every file in a fresh clone carries the moment of checkout and would look newer than anything local. A flat copy in that situation destroys real work.

What it will not decide for you:

- **A file on one side only.** Absence carries no timestamp, so "deliberately deleted" and "never received" are indistinguishable. It copies the file across, never deletes, and says so, so you can undo it.
- **Same timestamp, different content.** Reported and left alone.
- **`MEMORY.md`.** It's an index both machines append to, so newest-wins would silently drop the other machine's entries. Its pointer lines are unioned by link target instead, and conflicting text for the same target is reported rather than resolved.

**This applies to every commit, not just a Debrief.** The Debrief protocol has a merge step, but memory gets written mid-session too — so if you saved, edited, or deleted anything in local auto-memory during a session, merge before the *next* commit, whenever that is. Don't wait for a Debrief that may not happen. The failure here is silent: nothing breaks locally, and the loss only surfaces later on a different machine as memory that never arrived, or a `MEMORY.md` index pointing at files that aren't there.

If a memory file mirrors a repo file, update that mirror *before* merging, or the merge faithfully carries a stale version. Order: edit the repo file → update the mirror → merge → commit. Better still, don't keep verbatim mirrors of repo files in memory at all — a repo-root `CLAUDE.md` already auto-loads and travels with the clone, so a copy in memory adds no reach and one more thing to drift.

## Keep this project's memory scoped locally, not universal

Claude's local auto-memory is scoped by the session's working directory (check what Claude's local directory is before just using this one and verify with the user) (`~/.claude/projects/<sanitized-cwd>/memory/`). If a session works on this project while its working directory is actually some shared parent folder (e.g. a folder that holds many projects), this project's memories land in that shared/universal bucket instead of a project-specific one — and can then leak into unrelated projects opened from that same shared folder later.

To avoid this: always work on this project as its own session with the working directory set to this project's own folder, not a shared parent folder. If a session realizes partway through that it's scoped to the wrong (shared) directory, switch the working directory to this project's own folder, then move any of this project's existing memory files out of the shared location and into this project's own scoped location (and remove them from the shared one) so they don't linger in — or leak out from — the wrong scope.

## Scan for plan conflicts before dispatching parallel agents

Before dispatching two or more agents to work in parallel, write out every pair of tasks that share a file or an interface, and rule on each pair — sequence them, merge them into one dispatch, or confirm they're genuinely independent — before the first one starts. Two agents editing the same file, or one depending on an interface another is mid-changing, is a conflict to resolve up front, not something to discover from a mangled diff afterward.

Make the scan a table, not a verdict: one row per pair of tasks that share a file or interface, naming what one produces against what the other consumes, and what you found. "The scan is clean" without that row-by-row record isn't a scan you actually ran. A clean scan needs no further comment; a conflict gets resolved — by sequencing the dependent pair, folding them into one dispatch, or narrowing each agent's brief to avoid the overlap — before task one goes out.

Hand-written per-agent scope lists catch most of this by care, but care isn't a process — it misses things under load, and a brief that names a file another agent is mid-editing is exactly the failure this scan exists to catch before it happens. Run the scan explicitly every time you're about to dispatch agents in parallel, not just when something feels risky.

## Match model to license tier and task

**The objective is token efficiency: reach a correct result for the fewest total tokens.** Not "always use the strongest model," and not "always use the cheapest." A weaker model flailing on a genuinely hard problem — wrong approach, rework, three more rounds of correction — burns far more than a stronger model getting it right on the first pass. A stronger model grinding through mechanical edits is pure waste. Judge by expected total cost to a correct answer, including the cost of switching.

First, check which Claude license tier the user is on. If you don't already know, ask, and save the answer to this project's local auto-memory so later sessions don't re-ask. Re-check if something suggests it changed (a different machine, a different account, a model that used to be available and isn't). **If you can't determine the tier and can't ask — a subagent, or a non-interactive run — default to Sonnet.**

- **Claude Max (personal) or Claude Premium (teams):** pick whichever model is actually best-suited, task by task, and switch as the work changes. Never settle on one model as a standing default.
- **Claude Pro (personal) or Claude Business Standard (teams):** default to Sonnet. Don't switch unasked — but *do* speak up when a task looks genuinely hard enough that a stronger model would likely cost fewer tokens overall (see "speaking up" in point 3 below). The user decides; your job is to give them the choice, not to make it silently or to stay quiet about it.

### Which model fits what

- **Opus** — architecture and design decisions; ambiguous or underspecified requirements; subtle debugging where the cause isn't localized; security and design review; writing behavioral rules or specs that must be precise on the first pass; anything where a wrong first approach means expensive rework.
- **Sonnet** — well-specified implementation; mechanical or repetitive edits; running and interpreting tests; file sweeps and propagation; routine doc updates. This is the right default for most work.
- **Haiku** — trivial lookups, single-fact greps, simple mechanical transforms.

### Switching costs tokens too

Switching is not free, in either direction: a handoff costs a dispatch, a written brief, and a review of what came back; a session switch costs a real stop and usually some re-establishing of context. **Only switch when the expected savings exceed that overhead.** For a small job, finish it on whatever model is already loaded if that model is adequate — splitting a twenty-minute task across two models costs more than it saves.

### Switch back down, not just up

This rule runs both ways. Once the hard reasoning is done and what's left is mechanical, say so and hand it down (or offer to) — don't let one hard question park the whole session on the expensive model for the rest of its life. On Max, that also protects the weekly cap.

### This applies in three places

1. **Dispatching agents/subagents.** Set each agent's model to whichever one fits that agent's task, subject to the tier rule — don't default every dispatch to the same model out of habit. Note that **a subagent can run a different model than the session dispatching it.** So when the hard piece is separable, the usual answer is to hand it to a subagent running the better-suited model, not to stop the session (see point 3). Don't pin a `model:` in an agent definition's frontmatter — that hardcodes one choice and defeats per-task selection; leave it unset so the dispatcher decides.

   **Fable is excluded from this rule — manual-only, never dispatched by the assistant.** The user reserves Fable for projects they personally decide need it, and invokes it themselves. On a Max/Premium tier, "pick whichever model is best-suited" ranges over Opus and Sonnet only; never dispatch an agent on Fable. This is a hard constraint, not a preference to weigh against task fit.

   **Name the agent and the model out loud at every dispatch**, in the message launching it — e.g. "dispatching `luna-core-implementer` on Opus for this" — so the user can audit the routing from outside without reading tool calls. This applies whether the choice was Opus or Sonnet; silence is only acceptable when there's nothing to dispatch (see point 3, inline work).
2. **A subagent mid-task.** If partway through you find distinct follow-on work that would genuinely be better suited to a different model, stop and report it back rather than continuing on a mismatched model. When you do, **leave the work in a consistent state** — finish or fully revert whatever edit is in flight, never half-apply a change — and report precisely: what you completed, what's left, and why the other model fits it. The point is to save the dispatcher tokens, so a handback that forces them to redo your work has failed.
3. **Inline work in the current session — "speaking up."** If the model already running fits, keep going and say nothing. If a different model would clearly be better and the work can't be handed to a subagent: **pause, say what's coming up and why it calls for a different model, and wait for the user to confirm they've switched** — a running session can't change its own model, so this has to be a real stop, not a note in passing. **If the user declines the switch, proceed on the current model without further comment** — don't re-raise it, and don't hedge every later answer with a reminder. Their call is made.

### Receiving a mismatch report

If an agent hands work back citing a model mismatch, act on it: re-dispatch that piece to an agent running the better-suited model, or — if it needs the main session's context — raise it with the user per point 3 above. Weigh it against the switching cost first; if the remaining work is small, just finish it. Either way don't silently re-dispatch the same piece on the same model, which wastes the handback entirely.

## Versioning scheme

This project uses a 4-number version format: `ver-A.B.C.D` (e.g. `ver-4.14.52.105`). The `ver-` prefix is always present.

- **A (1st number):** a complete redesign/rewrite of the whole program or layout.
- **B (2nd number):** changes to core features, short of a full redesign.
- **C (3rd number):** large bug fixes.
- **D (4th number):** very small bug fixes. A doc/spec-only addition (no feature, no bugfix) counts as a 4th-number change too, same treatment as a minor bugfix.

Any number can climb arbitrarily high — no fixed cap or rollover point. When a higher-order number increments, every number to its right resets to 0 — e.g. a core-feature change bumps B and resets C and D to 0.

**Pre-1.0 phase:** development starts at `ver-0.1.0.0-dev`. Until the project reaches `ver-1.0.0.0`, anything that would normally increment the 1st number instead increments the 2nd number — the 1st number stays locked at 0 for the entire pre-1.0 phase. The 3rd and 4th numbers behave normally throughout.

**Moving to `ver-1.0.0.0`** (the first final, built product for initial release) only happens when the user explicitly says so. Never propose or ask about making this move — wait for them to declare it.

**dev vs. main:** both branches carry the exact same version number in lockstep. The only difference is that `dev`'s version string has `-dev` appended (e.g. `dev` is at `ver-0.3.12.7-dev`; once merged to `main`, that same version is `ver-0.3.12.7`, no suffix).

## Wake Up / Debrief protocols

Two session-boundary rituals, recognized both as real slash commands (`/wake-up`, `/debrief` — the full procedure lives at `.claude/commands/wake-up.md` / `.claude/commands/debrief.md`, which is where Claude Code looks for slash commands — note a bare `commands/` folder at a project's root, if one exists, is only Luna-Core's own template source for new projects to copy from, never a working location itself) and as natural-language phrases:

- **Wake Up** — triggered by phrases like "wake up," "let's get our day started," "are you awake," "are you up" (or an obvious variation). Picks up the project after time away, checking whether the computer has changed since the last check and doing a full sweep (including functionally testing agents, not just confirming they exist) if so.
- **Debrief** — triggered by phrases like "let's end here for the day," "I'm calling it for now and heading to sleep," "I'm switching to another computer" (or an obvious variation). Wraps up the session: preps docs (including `.claude/agents/*.md`), writes handoff notes, records the current computer/timestamp, then asks to commit and publish.

**When triggered by a natural-language phrase (not the slash command itself), confirm with the user before running either protocol** — don't just launch into it. Give the confirmation ask a little personality, like a personal butler checking in, rather than a flat system prompt. Typing the slash command directly already counts as explicit confirmation — no need to ask again in that case.

Both protocols read/write `handoff/STATUS.md` (last-known computer name + timestamp) and `handoff/HANDOFF.md` (current handoff notes) — both dev-only, owned by `<projectname>-docs-writer`.

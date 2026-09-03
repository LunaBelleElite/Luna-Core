# `scripts/install-global-entrypoint.sh`

## What it does

Writes this *machine's* entry point for bootstrapping new projects from
Luna-Core. A brand-new empty project directory has nothing in it pointing
back to Luna-Core, so this script closes that gap by writing two things
*outside* this repo, into the machine-level Claude Code config: a short
pointer block in the global `CLAUDE.md` (loaded into every session on the
machine, any working directory) and a global `/new-project` slash command
that runs the full bootstrap in one keystroke. Run it once per machine,
after cloning Luna-Core; safe to re-run.

## Invocation

```bash
bash scripts/install-global-entrypoint.sh
```

**Takes no arguments.** The clone URL a new machine needs is read from this
checkout's own `git remote get-url origin` — the one address guaranteed
correct, since it's where this very checkout came from. It is not read from
a flag, a config file, or a hardcoded constant, on purpose: any of those
could go stale or be wrong for a reason the script can't detect. See
"Refusal conditions" below for what happens when there's no origin to read.

### What it writes, and where

Both writes land in `$CLAUDE_DIR` (resolved by `lib-claude-home.sh` — see
that page), **not** inside this repo:

1. **`$CLAUDE_DIR/CLAUDE.md`** — a marker-delimited block (`<!-- luna-core:begin
   ... -->` / `<!-- luna-core:end -->`) containing the pointer text and the
   manual bootstrap commands. If the file doesn't exist, it's created with a
   short preamble explaining why it stays short. If it exists without the
   markers, the block is appended, never overwriting existing content. If it
   exists *with* the markers already (a re-run), only the block between them
   is replaced — see the CR trap below for the one way this can silently
   fail to happen.
2. **`$CLAUDE_DIR/commands/new-project.md`** — the global `/new-project`
   slash command body, generated fresh each run (not diffed/preserved — a
   plain overwrite, since the whole file is Luna-Core's content and hand
   edits to it aren't expected to survive a re-run).

Both files are stamped with `<!-- luna-core:version X.Y.Z.W-dev -->`, read
from the first `## ver-` line in `CHANGELOG.md`. `validate-luna-core-setup.sh`
reads that stamp back and compares it against the checkout's current
version to detect a stale entry point — see that script's page.

Nothing is written inside this repo. Nothing is written to any other
project.

### Re-running

Re-running is safe and idempotent for the entry-point content: the script's
own block is located by its markers and replaced; everything else in
`$CLAUDE_DIR/CLAUDE.md` — anything the user or another tool added — is left
alone. A `.bak` copy of the pre-run file is kept (`$CLAUDE_DIR/CLAUDE.md.bak`)
each time the replace or append path runs (not on first-creation).

## Refusal conditions

All of these print an explanation and **write nothing** — verified by
directly checking the filesystem after a refusal, not just by reading the
error text (see `tests/notes/live-checks.md`, "The entry-point installer"
section, which measured this):

- **`scripts/lib-claude-home.sh` is missing.** Refuses rather than guessing
  where the config lives — a wrong guess here would write the entry point
  somewhere Claude Code never reads, which is a worse failure than refusing,
  because it looks like success.
- **`$CLAUDE_DIR` doesn't exist.** Read as "Claude Code isn't installed for
  this user" — nothing to write into.
- **No `origin` remote on this checkout** (or the checkout isn't a git repo
  at all). The error message distinguishes "not a git repo yet" from "is a
  repo, but no origin configured," and tells you how to add one
  (`git remote add origin <url>`). This refusal exists specifically because
  an earlier version of this script wrote the entry point anyway with only a
  warning — leaving a `/new-project` command that fails at clone time with
  no obvious cause. The comment in the script calls that out explicitly as
  "success-shaped output over a broken result," and the current behavior is
  the fix.

## Non-obvious behavior and traps

**The CR-sensitivity bug in the replace path — the highest-value thing to
know about this file.** The script *finds* its own block with `grep -qF
"$BEGIN" "$GLOBAL_MD"`, which matches the marker as a substring and is
CR-tolerant. It then *replaces* the block with an awk script using `$0 == b`,
an **exact** line match. On a CRLF-line-ended `$CLAUDE_MD`, those two checks
disagree: grep takes the replace branch, but awk's exact comparison never
fires because every line still carries a trailing `\r`. The result: the
script prints `"Updated the Luna-Core block in ..."` and exits 0, having
changed nothing — a silent no-op that looks like success. The fix in the
current script is `{ sub(/\r$/, "") }` applied to every line before the
comparisons run.

**This machine cannot see that bug by default.** Git Bash's gawk strips CR
in text mode, so a CRLF file behaves as if it were LF here — the bug is real
but latent on ASUNA-PC specifically. `tests/notes/live-checks.md` (same
section) records the exact recipe to force it visible if you need to
re-verify: a PATH-shadowing `awk` wrapper invoking `gawk -v BINMODE=3`, added
to `PATH` in **POSIX form via `cygpath -u`** (a `C:/...`-style PATH entry
silently resolves to the real awk and the test passes for the wrong reason).

**The `sed` substitution treats the origin URL as regex-replacement text,
not literal text.** `sed`'s replacement side treats `\` as an escape and `&`
as "insert the whole match." A git remote URL should contain neither, but
the script escapes both anyway (`sed_escape()`, `s/[\\&|]/\\&/g`) rather than
assuming — the comment notes this was exercised against Windows paths before
and the failure mode was silent and plausible-looking. If you ever see a
mangled origin URL in a generated file, check this function first.

**Latent, unconfirmed risk in the version stamp.** Line 83 extracts the
CHANGELOG version with `awk '{print $2}'` on the matched `## ver-...` line.
If `CHANGELOG.md` itself were ever CRLF, a trailing `\r` would ride along
into the stamp, and the validator's later comparison against the checkout's
current version would mismatch for a reason that isn't visible by eye. This
is noted in `tests/notes/live-checks.md` as **latent, not live** — it has
not actually been observed, only reasoned about from the same root cause as
the confirmed bug above.

**Every write is preceded by a `.bak`, but only on the replace/append
paths.** First-time file creation doesn't produce a `.bak`, because there's
nothing yet to back up.

## Cross-references

- **Sources:** `scripts/lib-claude-home.sh`, to resolve `$CLAUDE_DIR`. Fails
  loudly if that file is missing rather than reimplementing the lookup — see
  that page for why a fourth hand-rolled variant would be a mistake.
- **Read back by:** `scripts/validate-luna-core-setup.sh`, which locates
  `$CLAUDE_DIR/CLAUDE.md` (via the same `lib-claude-home.sh` resolver) and
  compares the version stamp this script wrote against the checkout's
  current CHANGELOG version, reporting drift as a `NOTE:` line. That
  reporting can only ever be a `NOTE:` and cannot fail the validator's exit
  code — see `tests/notes/live-checks.md`'s note that "the validator's
  entry-point check cannot fail a run," true across all four reader states
  (current, missing, stale stamp, no block).
- **Not copied into a new project.** Unlike most of `scripts/`, this file is
  machine-level, not project-level — `bootstrap-new-project.sh` does not
  copy it. A generated `README.md` or `/new-project` command that tells a
  bootstrapped project to run `scripts/install-global-entrypoint.sh` from
  its own `scripts/` directory is pointing at a file that isn't there; the
  correct instruction is to run it from the *Luna-Core checkout*, not from
  the new project. `validate-luna-core-setup.sh` handles this distinction
  explicitly (its `ENTRYPOINT_HOWTO` variable branches on `$IS_LUNA_CORE`).
- **Depended on by:** the Wake Up protocol's "never report a missing thing
  without a route out of it" standing rule names re-running this script as
  one of the things a session can safely do on its own when an entry point
  is found stale or missing.

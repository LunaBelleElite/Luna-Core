# `scripts/check-prerequisites.sh`

## What it does

Checks the runtime and toolchain prerequisites a project declares it needs
(a .NET SDK, a specific Python or Node version, whatever that project
actually depends on) against what this machine actually has installed. The
script itself is completely generic — it hardcodes nothing about any
particular runtime — and reads its list of checks from a project-local
config file, `ref/prerequisites.conf`, in a small pipe-delimited DSL. A
project that declares nothing (Luna-Core's own stub does exactly this) gets
a neutral "nothing declared" line and no warnings; the comment is explicit
that a docs-only project must not nag forever.

## How it's invoked

```bash
bash scripts/check-prerequisites.sh
```

No arguments. It `cd`s to the project root (one level up from `scripts/`)
before reading `ref/prerequisites.conf`, so it must be run from within a
project that has that layout — but it can be invoked from anywhere since it
resolves its own location via `$SCRIPT_DIR`.

It writes **nothing to disk**. Pure read-and-report.

### The config format (`ref/prerequisites.conf`)

One check per line:

```
label | command | expected-regex
```

- `label` — human-readable name for the report.
- `command` — a shell command, `eval`'d, expected to print a version (or
  just succeed/fail).
- `expected-regex` — optional; an extended regex the command's output must
  match. Leave it off to accept any output — presence alone is enough.

Only the **first two** `|` characters are delimiters — everything after the
second one is the regex, verbatim. This is deliberate: it lets alternation
like `^(8|9)\.` appear in the regex without being misparsed as a field
separator.

**Install hints attach to the check declared immediately above them**, on
continuation lines starting with `>`:

```
.NET SDK | dotnet --version | ^(8|9)\.
> winget install Microsoft.DotNet.SDK.8
```

Hints can span multiple lines (real install instructions often do), and are
printed only at the point where that specific check fails — not
up front. Blank lines and lines starting with `#` are ignored.

## Refusal conditions

There isn't a hard refusal in the "writes nothing and exits nonzero before
doing anything" sense — this script always runs and always reports
something. The closest thing to a refusal:

- **No `ref/prerequisites.conf` in this project.** Prints a `NOTE:` pointing
  at Luna-Core's own copy as a format reference, and **exits 0** — an
  absent config is not a failure, it means the project has declared no
  prerequisites.
- **Exit code is nonzero only when something declared isn't satisfied** —
  a command failed, its output didn't match the expected regex, or the
  regex itself was malformed and couldn't be evaluated. Per the script's own
  header comment, this is informational: "callers should treat this as
  informational ..., not as proof the project setup itself is broken" —
  mirroring exactly how `validate-luna-core-setup.sh` treats
  `check-superpowers.sh`'s exit code. See that script's page.
- The malformed-regex case above was, until 2026-09-03, capable of being
  silently discarded rather than exiting nonzero — see the next section.
  That's fixed now; the exit code is trustworthy for this case as of the fix.

## Non-obvious behavior and traps

**Two-pass parsing exists because a hint is written *after* the check it
belongs to, but has to be *printed by* that check when it fails.** Pass 1
parses the whole file into four parallel arrays (`LABELS`, `CMDS`, `WANTS`,
`HINTS`); pass 2 runs each check and, on failure, looks up the
already-collected hint by index. A hint can't be printed by a check that
hasn't finished being parsed yet, hence the split.

**A malformed regex is caught and reported distinctly from a genuine version
mismatch — this is not incidental.** `grep` exits 2 on an invalid pattern
and 1 on a clean no-match. Without checking for exit code `> 1` specifically
(`printf '' | grep -qE "$want"; [ $? -gt 1 ]`), a typo'd regex would silently
present as "wrong version installed" (a `MISMATCH` line) rather than "this
pattern can't be evaluated" (a `NOTE:` line) — two very different problems
that call for different fixes. The check runs against an empty string
specifically so it tests only pattern validity, not the real command output.

**This script does not install anything, ever — by design, not oversight.**
A runtime install is treated as the user's decision, and often needs
elevation. So the burden shifts entirely to declaration quality: install
hints are written once into `ref/prerequisites.conf` and then surface
automatically at every future failure. When no hint is declared for a
failing check, `show_hint()` doesn't just say "not declared" and stop — its
else-branch is written **as an instruction to whatever AI agent is reading
this output**, not to the end user: work out how the missing thing installs
*on this specific machine*, hand over a specific ready-to-run command rather
than a vague suggestion, ask before anything needing elevation, be explicit
about whether the command is verified or inferred, and then **write the hint
back into `ref/prerequisites.conf`** as `>` continuation lines so the next
machine doesn't have to rediscover it. This is the same standing rule
stated more generally in `.claude/commands/wake-up.md`'s "never report a
missing thing without telling the user how to get it" section — this
script's `show_hint()` is one concrete place that rule is implemented in
code rather than only in prose.

**This code path has now been exercised against a real, non-empty config,
and it found a real bug on first contact.** `ref/prerequisites.conf` went
from an empty stub to declaring Git, GNU sed, and GNU find (git is a real
external dependency; sed and find are declared specifically because
`bootstrap-new-project.sh`, `install-global-entrypoint.sh`, and
`merge-memory.sh` rely on GNU-specific flags — `sed -i` with no backup
suffix, `find ... -printf` — that BSD sed/find don't provide). `awk`,
`grep`, `mktemp`, `diff`, and `cmp` are also used unguarded elsewhere in
this project's scripts but only in portable, POSIX-safe ways, so they stay
undeclared on purpose — a false prerequisite is worse than a missing one.

Six scenarios were run directly against the script (happy path, `MISMATCH`,
`NOT FOUND`, bad regex, malformed line, orphan hint line). Five matched
prediction exactly. The sixth — a config whose **only** declared entry has
an invalid regex — surfaced a real defect: the regex-validity guard
correctly set `status=1` and printed its `NOTE:`, but `continue`d before
`checked` was incremented. The trailing block then read `[ "$checked" -eq 0
]`, found it true (the bad-regex line was never counted), and printed `OK:
no runtime prerequisites declared for this project.` followed by **exit
0** — discarding the very failure it had just reported one branch earlier,
and asserting something false (a check *was* declared; it just couldn't
run). The mask was conditional, not universal: a second, valid entry
alongside the bad one made `checked` nonzero, and the run correctly exited
1 — so this bug only bit a conf whose bad-regex line was otherwise alone.

**Fixed** by keying that trailing check on `${#LABELS[@]}` (everything
actually parsed out of the conf in pass 1) instead of `$checked` (only what
pass 2 finished checking without hitting a `continue`). `${#LABELS[@]}` is
never wrong for "was anything declared," since it's set before either
`continue` branch can skip it. Re-run after the fix: the same single-bad-
regex conf now prints the `NOTE:` followed by "Some declared prerequisites
need attention" and exits 1, and the two-line (bad regex + valid `Git`)
case is unchanged. Full measurements and the sandbox recipe for re-proving
this are in `tests/notes/live-checks.md`'s "`check-prerequisites.sh`, run
for the first time against real declarations" section.

## Cross-references

- **Does not source `lib-claude-home.sh`** — unlike the other three scripts
  in this set, it has no need to locate Claude's config directory; everything
  it touches (`ref/prerequisites.conf`) is inside the current project.
- **Run by:** `scripts/validate-luna-core-setup.sh`, under an
  "informational — doesn't affect setup pass/fail" heading, same treatment
  as `check-superpowers.sh`. See that script's page.
- **Read by:** the Wake Up protocol's full-sweep path, and named directly in
  its standing rule about surfacing install hints verbatim rather than
  paraphrasing them.
- **Copied into every new project** by `bootstrap-new-project.sh`, alongside
  a fresh (empty, commented) `ref/prerequisites.conf` for that project to
  fill in.

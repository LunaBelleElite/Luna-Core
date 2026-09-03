# `scripts/lib-claude-home.sh`

## What it does

The shared resolver for one question every other script in `scripts/` needs
answered the same way: *where does this machine's live Claude Code config
actually live?* It is **sourced, not executed** — 64 lines defining one
function, `resolve_claude_home()`, called once at the bottom of the file so
that simply sourcing it sets the answer. It sets two variables: `CLAUDE_DIR`
(the config directory itself — what every caller should actually use) and
`HOME_DIR` (the directory holding it, kept only for building human-readable
messages).

## How it's invoked

Never run directly — sourced from a script's own directory:

```bash
. "$SCRIPT_DIR/lib-claude-home.sh"
```

After sourcing, `$CLAUDE_DIR` is set for the rest of that script's run.
Nothing is written to disk by this file itself; it only sets shell
variables in the caller's environment.

## Resolution order (read this before touching the logic)

1. **`CLAUDE_CONFIG_DIR`, if set, wins outright and is checked first.**
   Claude Code itself honors this variable, so a machine that sets it has
   its live config there and nowhere else. Critically: `CLAUDE_CONFIG_DIR`
   **is** the config directory already, not a home directory containing a
   `.claude` folder — the resolver returns it as `CLAUDE_DIR` directly, with
   no `/.claude` appended. On Windows, a `cygpath -u` conversion is applied
   first if `cygpath` is available, so a Windows-style path like `C:\Claude`
   resolves correctly for a POSIX shell; on a platform without `cygpath`
   (i.e. not Windows), no conversion is needed or attempted.
2. **If unset, probe `$USERPROFILE` then `$HOME`**, preferring whichever one
   contains `.claude/projects` (not just bare `.claude`) — that subdirectory
   is what proves a candidate is the *live* config rather than a stray
   lookalike.
3. **If neither has `.claude/projects`, fall back to bare `.claude`
   existence** on either candidate.
4. **If neither has anything at all, default to `$HOME/.claude`** — the
   naive answer, used only when nothing better was found.

## Refusal conditions

None — this file cannot fail or refuse. Sourcing it always sets both
variables to *something*, even in the worst case (step 4 above). It has no
`exit` calls and performs no validation of its own; scripts that source it
are responsible for checking whether the resulting `$CLAUDE_DIR` actually
exists and contains what they need. (See `install-global-entrypoint.sh`,
which checks `[ ! -d "$CLAUDE_DIR" ]` right after sourcing this.)

## Non-obvious behavior and traps

**Getting the `CLAUDE_CONFIG_DIR`-is-the-config-dir-not-a-home distinction
wrong is a *silent* failure, not a loud one.** A script that treats
`CLAUDE_CONFIG_DIR` as a home directory and appends `/.claude` to it writes
to a path that simply doesn't exist as Claude Code's config — or worse,
creates a new, empty, unread `.claude` folder there. Either way the script
reports success: files got written, no error was thrown, but Claude Code
never reads them. This reads as "reinstall the plugin" when the actual bug
is "wrong directory." The file's own header comment calls this out as the
specific failure class it exists to prevent, and it is not hypothetical —
per the comment in the script, **this exact bug has now been found four
separate times on this machine**: in this library before it existed, in a
third-party installer (Claude Code on Steroids — see the README's
"Dependency: superpowers plugins" section for the `$HOME`-vs-`CLAUDE_CONFIG_DIR`
patch that was needed), a token-analytics script, and a skill.

**The Windows mapped-drive gotcha this file was written to survive.** On
this author's machine, `$HOME` is frequently a mapped network drive (`Y:\`)
while the *real*, live config sits under `$USERPROFILE`. A script that
drops even an empty `.claude` folder onto that mapped drive — accidentally
or via some other tool — creates a lookalike that a naive `$HOME`-first
check would find and trust. This is exactly why the `.claude/projects`
check (not bare `.claude`) is preferred: `projects/` only exists where
Claude Code has actually been used, so it distinguishes the live config
from an empty stray folder.

**Why this is one file instead of nine repeated lines.** The header comment
notes the identical resolution logic had already been hand-copied into two
scripts before this file existed, and the third script that needed it
most — the one whose entire job is detecting installed plugins
(`check-superpowers.sh`) — never received the copy, and so had the
wrong-reason failure described above. This is Luna-Core's own worked
example of the rule in `CLAUDE.md`'s "A referenced folder must be created,
with a keeper file" section — the general lesson there (a template
reference needs matching creation and a matching check) applies here in
spirit: a shared assumption needs one shared implementation, not three
independently-maintained ones that will drift.

## Cross-references

- **Sourced by:** `install-global-entrypoint.sh`, `check-superpowers.sh`,
  `validate-luna-core-setup.sh`, and `merge-memory.sh` — all four refuse
  loudly (rather than falling back to a naive guess) if this file is
  missing from `scripts/`, specifically to avoid reintroducing the
  wrong-reason failure this file exists to prevent.
- **Not sourced by:** `check-prerequisites.sh`, which has no need to locate
  Claude's config directory — it only reads `ref/prerequisites.conf` inside
  the current project.
- **Copied into every new project** by `bootstrap-new-project.sh`, since
  every project-level script that needs `$CLAUDE_DIR` needs this alongside
  it.

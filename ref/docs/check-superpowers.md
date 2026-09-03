# `scripts/check-superpowers.sh`

## What it does

Checks whether both of the superpowers-based Claude Code plugin dependencies
this toolkit assumes are **installed and functioning** — not just present on
disk, but actually working. The two are `superpowers-extended-cc`
(`pcvelz/superpowers` marketplace plugin) and Claude Code on Steroids
(GadaaLabs skill pack + `/tokenburn` command). Run it once after cloning
Luna-Core into a new project, and before relying on any agent or skill that
assumes either is available — see `CLAUDE.md`'s "Always do these," which
names both as standing assumptions.

## How it's invoked

```bash
bash scripts/check-superpowers.sh
[--quick]
```

`--quick` skips the functional Python run of `tokenburn.py` and checks
presence only. It exists for the Wake Up protocol's same-machine quick-check
path, which runs on *every* wake on a familiar machine and has to stay cheap
— see the comment at the top of the `--quick` branch: the plugins are
installed per-machine, not per-project, so one can be silently uninstalled
or wiped by a Claude Code update without this machine's recorded name ever
changing, which the full sweep (different-machine path) would never get a
chance to notice. Without `--quick`, the full functional check runs.

It writes **nothing to disk** — this is a pure read/report script. It does
create one throwaway temp file (`mktemp`) to capture `tokenburn.py`'s output
for display, deleted before exit.

## Refusal conditions

Only one: **`scripts/lib-claude-home.sh` is missing.** Refuses loudly and
exits 1 rather than falling back to a naive `$HOME`-based lookup — the
comment is explicit that guessing here would produce a **false "MISSING"
verdict**: reporting both dependencies absent when they're actually
installed, just not where a naive guess looked. This is the same
wrong-reason-failure class `lib-claude-home.sh` exists to prevent generally
— see that page.

Beyond that, this script does not "refuse" in the sense of writing nothing
and stopping — it always runs both checks and reports. Its exit code
(`overall_status`) is nonzero if either dependency is missing or broken, but
that's a report, not a refusal.

## Non-obvious behavior and traps

**It cannot install either dependency itself, by design — not by
limitation.** Both `print_*_install_instructions` functions exist because
the plugins require action this script structurally cannot take:

- `superpowers-extended-cc` installs via `/plugin marketplace add` and
  `/plugin install`, which are **slash commands that only work inside an
  interactive Claude session** — no script can invoke them.
- Claude Code on Steroids installs by **piping a remote shell script from
  GitHub into bash** (`curl ... | bash`). The script's own comment states
  plainly: "an AI assistant should not run this for you" — the instructions
  it prints tell the user to run it themselves, in their own terminal.

Because of this, **its findings are deliberately informational and do not
gate the setup validator's exit code.** `validate-luna-core-setup.sh` runs
this script and reports what it found, but a missing superpowers dependency
does not make the overall validation fail — see that script's page and its
own comment: "this doesn't mean the file setup itself is broken." The
consuming protocol (Wake Up) is the one that turns this into a hard stop —
its standing rule says explicitly not to report a project ready to work on
until both are in place, since everything in `CLAUDE.md`'s "Always do these"
assumes both exist.

**The `/dev/null` redirect trap for `tokenburn.py`.** The functional check
redirects `tokenburn.py`'s output to a real `mktemp` file, not `/dev/null`.
The comment explains why: on this Windows/MSYS setup, redirecting to
`/dev/null` confuses the script's terminal-detection logic and it crashes
inside `curses.wrapper` — even though the exact same script runs fine with
output going anywhere else, including a real (but unread) file. This is a
platform-specific trap that would be very easy to "fix" back in by someone
who doesn't know the history, so it's worth flagging if you ever see this
redirect questioned in review.

**`tokenburn.py` needs the Windows `py` launcher specifically**, not just
"a python on PATH" — the comment notes this explicitly as the common failure
cause, verified with `py --version`.

**The plugin-content check is a real functional probe, not a version
check.** For `superpowers-extended-cc`, "functioning" means finding an
actual `SKILL.md` file under the plugin's cached marketplace path
(`find ... -iname "SKILL.md" -ipath "*brainstorming*"`) with nonzero size —
not just checking that the marketplace key is registered in
`settings.json`. A plugin can be *registered* (present in settings) but
*broken* (not finished downloading/caching) — the script distinguishes
these two failure modes explicitly (`MISSING` vs. `BROKEN`) and gives
different remediation for each (`BROKEN` suggests `/plugin update` first).

**This author's machine runs a third overlapping skill source** —
`obra/superpowers` itself (`superpowers@superpowers-dev`), upstream of both
plugins this script checks — which this script does not check for at all.
See the README's "Dependency: superpowers plugins" section: which of the
three is authoritative where they overlap is called out there as an open
decision, not something this script resolves.

## Cross-references

- **Sources:** `scripts/lib-claude-home.sh`, to resolve `$CLAUDE_DIR` before
  locating `settings.json`, the plugin cache, and the Steroids skill/marker
  files.
- **Run by:** `scripts/validate-luna-core-setup.sh` (full check, informational
  — see that page), and the Wake Up protocol both in its quick-check path
  (`--quick`, on every wake on a familiar machine) and implicitly via the
  full sweep's call to the validator (different machine, or first run).
- **Copied into every new project** by `bootstrap-new-project.sh`.
- **Depended on by:** every agent and skill invocation this toolkit assumes
  works, per `CLAUDE.md`'s "Always do these" — SuperPowers usage, agent
  dispatch conventions, and skill access all assume the plugins this script
  checks are present and functioning.

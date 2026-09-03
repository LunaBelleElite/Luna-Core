---
name: claude-code-skill-stack-setup
description: How this machine's three-layer Claude Code skill stack (obra/superpowers lineage, superpowers-extended-cc plugin, claude-code-on-steroids personal skills) is installed, and exact steps to replicate on a new machine
metadata:
  type: project
---

The machine this was originally written on ran three separate, non-overlapping skill sources. (ASUNA-PC does not match this — see "Verified state" at the end.) They coexist — they do not merge into or upgrade one another, despite naming that suggests a layered lineage.

1. **obra/superpowers** (Jesse Vincent) — the original upstream project. Not installed directly here; it's the common ancestor both of the below descend from.
2. **superpowers-extended-cc** — the actively-used plugin (skills: `brainstorming`, `test-driven-development`, `systematic-debugging`, `writing-plans`, `checking-gates`, etc.). Installed via the real plugin/marketplace system:
   - `claude plugin marketplace add pcvelz/superpowers` → registers as marketplace `superpowers-extended-cc-marketplace`
   - `claude plugin install superpowers-extended-cc@superpowers-extended-cc-marketplace`
3. **claude-code-on-steroids** (GadaaLabs, github.com/GadaaLabs/claude-code-on-steroids) — 24 additional, differently-codenamed skills (arbiter, architect, ascend, blueprint, chronicle, commander, exodus, forge, gradient, horizon, hunter, ironcore, legion, nexus, oracle, pathfinder, phantom, prism, sculptor, seal, sentinel, tribunal, vault, vector) plus a `/tokenburn` slash command. None of these names collide with #2's skills. Installed as **personal skills** — not a plugin, since GadaaLabs never published a `.claude-plugin/marketplace.json` (confirmed by reading the repo tree directly on 2026-08-31 — only a `plugin.json` metadata file exists, so `claude plugin marketplace add` cannot target this repo).

**Why:** User wanted the GadaaLabs skill pack added without introducing malware or breaking the existing plugin. A full audit of the repo (read every shell script, the tokenburn Python source, and the README) turned up no malicious code — no obfuscation, no credential access, no unexpected network calls, no sudo — but did turn up real bugs in their own installer that made the official one-liner unusable as published.

**How to apply — replicating on a new machine:**

For #2, just run the two plugin commands above.

For #3, do **not** run `curl -fsSL .../install.sh | bash` unmodified. Audited 2026-08-31; found:
- **Real script bug:** `((INSTALLED++))` runs under the script's `set -e`. Bash's arithmetic post-increment evaluates to the *old* value, so the very first increment (0→1) evaluates to `0`, which `set -e` treats as command failure — the installer crashes immediately after installing just the first skill (`arbiter`) on any fresh/standalone install.
- **Windows/Git Bash gotcha:** `$HOME` can resolve to a mapped drive (e.g. `/y/`) instead of the real profile (`/c/Users/<name>`). Export `HOME` explicitly before running any curl-piped installer here.
- **README overstates what the code does:** it claims the installer "wires up the SessionStart hook," but the actual code only does that when it finds an existing plugin under the hardcoded path `~/.claude/plugins/cache/claude-plugins-official/...`. It will never find a plugin installed from a different marketplace (like `superpowers-extended-cc-marketplace` here), so it silently falls into a "standalone" branch that writes inert files nobody reads.
- **Standalone mode targets the wrong directory:** it drops files at `~/.claude/superpowers/skills/` and `~/.claude/superpowers/commands/`, which Claude Code does **not** scan. The real personal-skill/command locations (confirmed against Claude Code docs, 2026-08-31) are `~/.claude/skills/<name>/SKILL.md` and `~/.claude/commands/<name>.md` — picked up automatically, no registration needed.
- **`tools/tokenburn` is a git submodule** with no `.gitmodules` entry. GitHub's tarball export never includes submodule content, so `npm install && npm run build` is always a no-op via the curl-pipe path — this is expected and harmless, don't try to fix it.

Correct manual replication:
```bash
curl -fsSL https://github.com/GadaaLabs/claude-code-on-steroids/archive/refs/heads/main.tar.gz | tar -xz -C /tmp/steroids-src --strip-components=1
mkdir -p ~/.claude/skills ~/.claude/commands
cp -r /tmp/steroids-src/skills/* ~/.claude/skills/
cp /tmp/steroids-src/commands/tokenburn.md ~/.claude/commands/tokenburn.md
```
Optional, not required for the skills to work — reference material only:
```bash
cp -r /tmp/steroids-src/examples/. ~/.claude/superpowers-examples/
```

New personal skills only appear in a session's skill listing on its *next* start (or after `/clear`) — they won't show up in a session already running.

**`/tokenburn` — getting it actually working (2026-08-31):** The Node/TypeScript CLI can never be built (its source is the inaccessible git submodule noted above), but the repo also ships a fully standalone `scripts/tokenburn.py` (stdlib only — curses, json, os, sys, glob, math, datetime) that reads the same local JSONL session logs directly. That's the one to use. Copied it to `~/.claude/scripts/tokenburn.py` and rewrote `~/.claude/commands/tokenburn.md` to call it instead of the never-built binary. Two Windows-only fixes were needed on top of the upstream file:
- `import curses` is unconditional at module load, but stock Windows Python has no `_curses` module. Wrapped it in `try/except ImportError: curses = None` — harmless because the static/piped output path (used when not a tty) never touches curses at runtime; only the interactive TUI branch would need a real `windows-curses` pip install.
- Piping the script's output causes a `UnicodeEncodeError` from Windows' default cp1252 console encoding on the box-drawing characters. Fix: run with `PYTHONIOENCODING=utf-8` set.
- Invoke via the `py` launcher, not `python`/`python3` — those two names are intercepted by the Windows Store "app execution alias" stub on this machine and never reach the real interpreter (`AppData\Local\Programs\Python\Python313\python.exe`). `py` bypasses that stub cleanly.

**Verified state on ASUNA-PC (2026-09-02):** all three sources are now installed
and `scripts/check-superpowers.sh` exits 0. `C:\Claude\settings.json` (this
machine sets `CLAUDE_CONFIG_DIR=C:\Claude`) enables both
`superpowers@superpowers-dev` (obra, the upstream) and
`superpowers-extended-cc@superpowers-extended-cc-marketplace`. Claude Code on
Steroids' 24 skills are in `C:\Claude\skills\`, with `/tokenburn` at
`C:\Claude\commands	okenburn.md`.

**Steroids was installed by hand, not by its installer**, and `tokenburn.py`
carries two local patches on top of upstream:

1. `import curses` guarded with `try/except ImportError` — stock Windows Python
   has no `_curses`, and only the interactive TUI branch needs it.
2. Session logs read from `CLAUDE_CONFIG_DIR` instead of a hardcoded
   `~/.claude/projects`. **This one looked like success:** unpatched it found 2
   log files rather than the 589 under `C:\Claude\projects` and reported
   `$0.0000` and 0 calls with no error.

Its `tokenburn.md` was also rewritten — upstream calls macOS `osascript` and a
`tokenburn` binary that can never be built (its source is a git submodule absent
from GitHub's tarball export).

**The recurring lesson:** three separate tools this session assumed
`$HOME/.claude` on a machine that sets `CLAUDE_CONFIG_DIR` — `lib-claude-home.sh`,
the Steroids installer, and `tokenburn.py`. When something here reports success
with suspiciously empty results, check that first.

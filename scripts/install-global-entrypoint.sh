#!/usr/bin/env bash
# Installs this machine's "how do I start a new project" entry point.
#
# Luna-Core's own README explains how to bootstrap a new project — but you
# can only read it once you already have Luna-Core, and a brand-new empty
# project directory contains nothing that points back here. This script
# closes that gap by writing two things OUTSIDE this repo:
#
#   1. A short pointer block in the user-level ~/.claude/CLAUDE.md, which
#      Claude Code loads into every session on this machine regardless of
#      working directory.
#   2. A global /new-project slash command, so bootstrapping is one keystroke
#      instead of three remembered commands and a clone URL.
#
# Run this once per machine, after cloning Luna-Core. Safe to re-run: it
# replaces its own marker block and leaves any other content alone.
#
# Usage: bash scripts/install-global-entrypoint.sh
#
# No arguments: the clone URL is read from this checkout's own 'origin' remote,
# which is the one address guaranteed to be correct -- it is where this very
# checkout came from. The script refuses rather than recording an address it
# cannot verify.

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Pick the home directory carefully -- writing the entry point somewhere Claude
# Code never reads would leave this machine looking correctly installed while
# doing nothing. lib-claude-home.sh explains why and sets CLAUDE_DIR.
if [ ! -f "$REPO_ROOT/scripts/lib-claude-home.sh" ]; then
  echo "ERROR: $REPO_ROOT/scripts/lib-claude-home.sh is missing -- refusing to guess"
  echo "       where this machine's Claude config lives, since guessing wrong would"
  echo "       write the entry point somewhere Claude Code never reads."
  exit 1
fi
# shellcheck source=lib-claude-home.sh
. "$REPO_ROOT/scripts/lib-claude-home.sh"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "ERROR: no Claude Code config directory found at $CLAUDE_DIR"
  echo "Is Claude Code installed for this user? Nothing was written."
  exit 1
fi

# Where a new machine clones Luna-Core from. This is read from the checkout's
# own 'origin' remote rather than guessed or passed in: that address is where
# this very checkout came from, so it is verified by construction. This is the
# FIRST script a brand-new machine is told to run, and a wrong address here
# poisons the generated /new-project command with a clone that fails for no
# obvious reason -- so refuse rather than write a pointer that cannot work.
if ! ORIGIN_URL="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null)" || [ -z "$ORIGIN_URL" ]; then
  echo "ERROR: this checkout has no 'origin' remote, so there is no address to"
  echo "       record for a new machine to clone from."
  echo
  if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "       $REPO_ROOT is not a git repository at all yet."
  else
    echo "       It is a git repository, but no 'origin' remote is configured."
    echo "       Add one:  git remote add origin <url>"
  fi
  echo
  echo "Nothing was written. Earlier versions wrote the entry point anyway with"
  echo "only a warning, which left this machine holding a /new-project command"
  echo "that fails at clone time with no obvious cause -- success-shaped output"
  echo "over a broken result."
  exit 1
fi

# The URL is substituted into the generated files with sed, whose REPLACEMENT
# text treats backslashes as escapes and & as "the whole match". A URL should
# contain neither, but this ran against Windows paths before and the failure
# mode was silent and plausible-looking, so keep escaping rather than assume.
sed_escape() { printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'; }
ORIGIN_ESC="$(sed_escape "$ORIGIN_URL")"

# Stamp each generated file with the Luna-Core version that produced it.
# Without this, a machine's entry point is indistinguishable from a current one
# no matter how old the clone that wrote it -- so staleness can't be detected,
# only silently overwritten. The setup validator compares this stamp against
# the checkout's current version.
DC_VERSION="$(grep -m1 '^## ver-' "$REPO_ROOT/CHANGELOG.md" 2>/dev/null | awk '{print $2}')"
[ -z "$DC_VERSION" ] && DC_VERSION="unknown"
STAMP="<!-- luna-core:version $DC_VERSION -->"

GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"
CMD_DIR="$CLAUDE_DIR/commands"
BEGIN="<!-- luna-core:begin (managed by scripts/install-global-entrypoint.sh) -->"
END="<!-- luna-core:end -->"

# ----------------------------------------------------------------------------
# 1. The pointer block in the user-level CLAUDE.md
#
# This file loads into EVERY session on this machine, including unrelated
# projects, so it stays deliberately short: the pointer and nothing else.
# Every actual convention lives in a project's own root CLAUDE.md.
# ----------------------------------------------------------------------------

BLOCK_FILE="$(mktemp)"
cat > "$BLOCK_FILE" <<'BLOCK'
<!-- luna-core:begin (managed by scripts/install-global-entrypoint.sh) -->
@@STAMP@@
## Starting a new project on this machine

New projects here start from **Luna-Core**, a starter kit that supplies the
custom agents, the Wake Up / Debrief session protocols, a baseline `CLAUDE.md`,
the `ver-A.B.C.D` versioning scheme, and memory roaming across machines. Don't
hand-build a project skeleton — bootstrap from it, so the new project inherits
all of that instead of drifting into its own conventions.

Run `/new-project`, or do it by hand:

```bash
DC_SRC="$(mktemp -d)/luna-core-src"
git clone -b main "@@ORIGIN_URL@@" "$DC_SRC"
cd <new-project-dir> && git init -b dev          # if it isn't a repo yet
bash "$DC_SRC/scripts/bootstrap-new-project.sh" \
     "$DC_SRC" <new-project-dir> <ProjectName>
cd <new-project-dir> && bash scripts/validate-luna-core-setup.sh
```

Bootstrap places a `CLAUDE.md` at the new project's root, and *that* file
carries every convention from then on. This block is only a pointer — it
exists because a brand-new empty directory has nothing in it that could say
where its toolkit came from.
<!-- luna-core:end -->
BLOCK

sed -i "s|@@ORIGIN_URL@@|$ORIGIN_ESC|g; s|@@STAMP@@|$STAMP|g" "$BLOCK_FILE"

if [ -f "$GLOBAL_MD" ] && grep -qF "$BEGIN" "$GLOBAL_MD"; then
  # Replace just our block, preserving anything the user added around it.
  cp "$GLOBAL_MD" "$GLOBAL_MD.bak"
  awk -v b="$BEGIN" -v e="$END" -v f="$BLOCK_FILE" '
    # Normalise a trailing CR before comparing. The grep -qF above matches the
    # marker as a SUBSTRING, so a CRLF CLAUDE.md takes this replace branch --
    # but `$0 == b` is an exact match, and on an awk that keeps the CR the
    # marker never matches: every line falls through to `!skip`, the file is
    # rewritten byte-identical, and the script still prints "Updated". A
    # success-shaped no-op. Windows gawk strips the CR in text mode so this
    # machine cannot see it; most other awks do not -- and the whole job of this
    # installer is running on a machine we have never tested on.
    { sub(/\r$/, "") }
    $0 == b { while ((getline line < f) > 0) print line; skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$GLOBAL_MD.bak" > "$GLOBAL_MD"
  echo "- Updated the Luna-Core block in $GLOBAL_MD (previous copy: CLAUDE.md.bak)"
elif [ -f "$GLOBAL_MD" ]; then
  # File exists but has no block of ours — append, never overwrite.
  cp "$GLOBAL_MD" "$GLOBAL_MD.bak"
  printf '\n' >> "$GLOBAL_MD"
  cat "$BLOCK_FILE" >> "$GLOBAL_MD"
  echo "- Appended the Luna-Core block to the existing $GLOBAL_MD (previous copy: CLAUDE.md.bak)"
else
  {
    echo "# Global notes for this machine"
    echo
    echo "Loaded into every Claude Code session on this machine, whatever the"
    echo "working directory. Keep it short for that reason — project-specific"
    echo "conventions belong in that project's own root CLAUDE.md."
    echo
    cat "$BLOCK_FILE"
  } > "$GLOBAL_MD"
  echo "- Created $GLOBAL_MD"
fi
rm -f "$BLOCK_FILE"

# ----------------------------------------------------------------------------
# 2. The global /new-project slash command
# ----------------------------------------------------------------------------

mkdir -p "$CMD_DIR"
cat > "$CMD_DIR/new-project.md" <<'CMD'
---
description: Bootstrap a brand-new project from the Luna-Core starter kit
---

# New Project

Set up a brand-new project from the Luna-Core starter kit, so it inherits the
standard agents, session protocols, baseline `CLAUDE.md`, and versioning scheme
instead of being hand-assembled.

This file is generated by Luna-Core's `scripts/install-global-entrypoint.sh`.
Re-running that script overwrites it, so don't hand-edit this copy — change the
installer in the Luna-Core repo instead.

@@STAMP@@

## 1. Get what you need from the user

Ask for whatever they haven't already said:

- **Project name** — used as-is in agent filenames and each agent's `name:`
  frontmatter, so it must be letters, digits, hyphens and underscores only.
  No spaces. Bootstrap rejects anything else.
- **Where it should live** — the new project's own directory.

Don't guess either one. A wrong project name propagates into a dozen filenames
and agent identifiers.

## 2. Clone Luna-Core somewhere temporary

```bash
DC_SRC="$(mktemp -d)/luna-core-src"
git clone -b main "@@ORIGIN_URL@@" "$DC_SRC"
```

This is a read-only source to copy *from*. It is not the new project, and the
new project does not inherit Luna-Core's git history.

If the clone fails, stop and tell the user rather than improvising — the
likeliest cause is no network.

## 3. Make sure the destination is an initialized repo on `dev`

Bootstrap copies files *into* an existing repo; it doesn't create one:

```bash
cd <new-project-dir> && git init -b dev
```

If the project already exists as a repo, check which branch it's on. This
toolkit expects a `dev`/`main` split, and bootstrap will warn if you're
somewhere else — heed that warning rather than ignoring it.

## 4. Bootstrap

```bash
bash "$DC_SRC/scripts/bootstrap-new-project.sh" \
     "$DC_SRC" <new-project-dir> <ProjectName>
```

This copies and renames the agents (`luna-core-*` → `<projectname>-*`, fixing
internal references), copies the slash commands into `.claude/commands/`, places
`CLAUDE.md` at the new project's root with its toolkit section filled in, and
creates fresh `ref/docs/`, `handoff/`, and a `CHANGELOG.md` starting at
`ver-0.1.0.0-dev`.

It refuses to run against an already-bootstrapped project, so if it stops for
that reason, don't force it — ask the user what they actually want to happen.

## 5. Verify, don't assume

```bash
cd <new-project-dir>
bash scripts/validate-luna-core-setup.sh
bash scripts/check-superpowers.sh
```

Read the output rather than reporting success because the commands exited 0. The
validator prints `NOTE:` lines for placeholders that are *expected* to need
filling in, and `NOT RENAMED` if a rename genuinely failed — those mean different
things. In particular the `-Research` agent ships with a deliberate
`<absolute path to this project's repo>` placeholder that **must** be filled in
with the new project's real path before that agent is usable.

## 6. Report back

Tell the user what landed, what still needs their attention (any required
placeholder, any missing dependency the checks flagged), and what the new
project's starting version is.

Then stop. Do not commit — the new project inherits the standing rule that every
`git commit`, `merge`, and `push` needs explicit permission first, asked each
time. Offer, and wait.
CMD

sed -i "s|@@ORIGIN_URL@@|$ORIGIN_ESC|g; s|@@STAMP@@|$STAMP|g" "$CMD_DIR/new-project.md"
echo "- Wrote $CMD_DIR/new-project.md (available as /new-project)"


echo
echo "Done. Restart Claude Code so it picks up the global CLAUDE.md and"
echo "/new-project, then confirm with: /new-project (it should appear in the"
echo "slash-command list)."

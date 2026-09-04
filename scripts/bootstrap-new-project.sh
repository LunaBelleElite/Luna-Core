#!/usr/bin/env bash
# Sets up a new project from a Luna-Core checkout: copies and renames
# agents, copies commands/scripts, places CLAUDE.md at the new project's
# root, and creates fresh (not copied) ref/docs, handoff/, and CHANGELOG.md.
#
# The new project must already be its own initialized git repo — this
# script copies specific files INTO it,
# it does not clone Luna-Core's own history or dev-only content
# (handoff notes, .claude-memory/) into the new project.
#
# Usage: bash bootstrap-new-project.sh <luna-core-source-dir> <new-project-dir> <ProjectName>

set -e

SOURCE="$1"
DEST="$2"
PROJECT_NAME="$3"

if [ -z "$SOURCE" ] || [ -z "$DEST" ] || [ -z "$PROJECT_NAME" ]; then
  echo "Usage: bash bootstrap-new-project.sh <luna-core-source-dir> <new-project-dir> <ProjectName>"
  exit 1
fi

if ! echo "$PROJECT_NAME" | grep -qE '^[A-Za-z0-9_-]+$'; then
  echo "ERROR: <ProjectName> ('$PROJECT_NAME') must contain only letters,"
  echo "digits, hyphens, and underscores -- no spaces or other characters."
  echo "It's used in agent filenames and the agent 'name:' frontmatter"
  echo "field, which Claude Code needs as a safe, space-free identifier."
  exit 1
fi

# Agent identifiers are lowercase by convention (luna-core-qa-tester ->
# testproj-qa-tester), while prose keeps the name as the user typed it
# ("TestProj"). Two forms, one input.
LC_NAME="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"

if [ ! -d "$SOURCE/agents" ] || [ ! -f "$SOURCE/CLAUDE.md" ]; then
  echo "ERROR: $SOURCE doesn't look like a Luna-Core checkout (missing agents/ or CLAUDE.md)."
  exit 1
fi

if [ ! -d "$DEST/.git" ]; then
  echo "ERROR: $DEST doesn't look like an initialized git repo. Set that up first"
  echo "before running this script."
  exit 1
fi

if [ -f "$DEST/handoff/HANDOFF.md" ]; then
  echo "ERROR: $DEST already has handoff/HANDOFF.md -- this looks like an"
  echo "already-bootstrapped project. Re-running this script would silently"
  echo "overwrite its real handoff notes, CHANGELOG.md, and CLAUDE.md back to"
  echo "fresh-bootstrap boilerplate, destroying actual project history."
  echo "This script is meant for first-time setup only. If you're trying to"
  echo "pull in a newer version of a specific Luna-Core file (an updated"
  echo "agent, a fixed script), copy that one file by hand instead."
  exit 1
fi

DEST_BRANCH="$(git -C "$DEST" branch --show-current 2>/dev/null || echo "")"
if [ "$DEST_BRANCH" != "dev" ]; then
  echo "WARNING: $DEST is currently on branch '${DEST_BRANCH:-<none/detached>}', not 'dev'."
  echo "This toolkit (agents, versioning, Wake Up/Debrief) assumes a dev/main"
  echo "branch split — everything this script installs is dev-only content."
  echo "This script will NOT create or switch branches for you. Create 'dev'"
  echo "yourself (e.g. 'git -C \"$DEST\" checkout -b dev') before or after running"
  echo "this, whichever fits how you've already set up $DEST."
  echo
fi

# The roster is fixed and must be complete. This used to be a bare glob over
# whatever happened to exist in $SOURCE/agents/, which meant a source template
# that had gone missing produced a project quietly short one whole capability
# -- and nothing downstream noticed, because the validator only complained when
# ALL agents were absent. Check the roster up front and refuse, rather than
# emitting a half-built project: a loud failure here costs one re-run, while a
# silent one costs a project that looks fine and isn't.
EXPECTED_ROLES="docs-writer research qa-tester implementer"
missing_roles=""
for role in $EXPECTED_ROLES; do
  [ -f "$SOURCE/agents/luna-core-$role.md" ] || missing_roles="$missing_roles $role"
done
if [ -n "$missing_roles" ]; then
  echo "ERROR: $SOURCE/agents/ is missing template(s) for:$missing_roles"
  echo
  echo "All of these are required — later steps reference them by name (the"
  echo "generated CLAUDE.md toolkit list, and HANDOFF.md's next-steps), so"
  echo "continuing would produce a project whose own docs point at files that"
  echo "do not exist. Nothing has been written to $DEST."
  echo
  echo "Re-clone Luna-Core (its remote carries all four) and run this again."
  exit 1
fi

echo "=== Bootstrapping '$PROJECT_NAME' from $SOURCE into $DEST ==="

# --- scripts/ (excluding this script itself — bootstrapping OTHER
# projects is Luna-Core's own role, not something a consuming project
# needs; the validator DOES get copied, so a project can re-check its own
# setup anytime) ---
mkdir -p "$DEST/scripts"
for f in "$SOURCE"/scripts/*.sh; do
  base="$(basename "$f")"
  case "$base" in
    # Luna-Core's own distribution tool -- nothing for a child project to do
    # with it.
    bootstrap-new-project.sh) continue ;;
    # Machine-level, not project-level: it writes the entry point that points
    # AT Luna-Core, and it reads the clone URL from its own repo's origin, so a
    # copy sitting in a child project would just be broken.
    install-global-entrypoint.sh) continue ;;
  esac
  cp "$f" "$DEST/scripts/$base"
done
echo "- Copied scripts/ (check-superpowers.sh, merge-memory.sh,"
echo "  check-prerequisites.sh, validate-luna-core-setup.sh)"

# --- .gitattributes / .gitignore -- without these, the new project's first
# commit on Windows prints a wall of "LF will be replaced by CRLF" warnings
# (the exact noise .gitattributes exists to silence), and has no protection
# against committing .claude/settings.local.json ---
[ -f "$SOURCE/.gitattributes" ] && cp "$SOURCE/.gitattributes" "$DEST/.gitattributes"
[ -f "$SOURCE/.gitignore" ] && cp "$SOURCE/.gitignore" "$DEST/.gitignore"
echo "- Copied .gitattributes and .gitignore"

# --- commands/ -> .claude/commands/ ---
mkdir -p "$DEST/.claude/commands"
cp "$SOURCE"/commands/*.md "$DEST/.claude/commands/"
echo "- Copied commands/ into .claude/commands/ (/wake-up, /debrief)"

# --- agents/ -> .claude/agents/ : copy + rename luna-core-<role> ->
# <projectname>-<role> (lowercased), replacing "Luna-Core" AND any
# "<ProjectName>"/"<projectname>"
# cross-reference (e.g. one agent referring to another, like implementer ->
# qa-tester) with the new project name -- EXCEPT inside blockquote ("> ...")
# lines, which are each agent's permanent "Template note" documenting the
# rename-on-clone convention itself. Those lines correctly say "Luna-
# Core"/"<ProjectName>" forever (they're about the origin template and the
# convention, not this project specifically), and must not be rewritten.
#
# Destination is .claude/agents/, NOT a bare agents/ folder: Claude Code
# only recognizes custom subagents as invokable-by-name in .claude/agents/
# (project-level) -- a bare agents/ folder is documentation only, invisible
# to the harness. Same reasoning as commands/ -> .claude/commands/ below. ---
mkdir -p "$DEST/.claude/agents"

AGENT_LIST=""
for f in "$SOURCE"/agents/luna-core-*.md; do
  base="$(basename "$f")"
  role="${base#luna-core-}"
  role="${role%.md}"
  new_name="${LC_NAME}-${role}"
  # The lowercase <projectname> is filled in as well. It appears in operative
  # body text -- the agent description, and cross-references naming another
  # agent -- where the answer is simply this project name, so leaving it
  # shipped dangling references to an agent that exists under no such name.
  # <directory> is deliberately NOT filled: only a human knows the repo path.
  # (Comments stay out here: an apostrophe inside the awk program would close
  # the surrounding single-quoted shell string.)
  awk -v proj="${PROJECT_NAME}" -v lcproj="${LC_NAME}" '
    /^>/ { print; next }
    {
      # This literal filename is deliberately never renamed (see CLAUDE.md);
      # shield it from the blind luna-core- substring match below, then restore it.
      gsub(/validate-luna-core-setup\.sh/, "@@VALIDATE_LUNA_CORE_SETUP@@")
      gsub(/luna-core-/, lcproj "-")
      gsub(/<projectname>-/, lcproj "-")
      gsub(/Luna-Core/, proj)
      gsub(/<ProjectName>/, proj)
      gsub(/<projectname>/, proj)
      gsub(/@@VALIDATE_LUNA_CORE_SETUP@@/, "validate-luna-core-setup.sh")
      print
    }
  ' "$f" > "$DEST/.claude/agents/${new_name}.md"
  AGENT_LIST="${AGENT_LIST}\`${new_name}\`, "
done
AGENT_LIST="${AGENT_LIST%, }"
echo "- Copied and renamed into .claude/agents/: $AGENT_LIST"
echo "  (mechanical rename only — re-read each agent file, since some content"
echo "  may still need real project-specific adaptation, e.g. qa-tester's and"
echo "  implementer's '## Stack'/'Part Two' blocks, and repo path/branch in"
echo "  the Research agent.)"

# --- CLAUDE.md at the new project's root, with the toolkit section
# replaced (not blanket-renamed -- everywhere ELSE in this file, "Luna-
# Core" is a correct lineage reference, e.g. "cloned in from Luna-Core",
# and must NOT be rewritten to the new project's name) ---
CURRENT_DATE="$(date +%Y-%m-%d)"
START_LINE="$(grep -n "^## This project's toolkit$" "$SOURCE/CLAUDE.md" | head -1 | cut -d: -f1)"
END_LINE="$(grep -n "^## 1\. Think Before Coding$" "$SOURCE/CLAUDE.md" | head -1 | cut -d: -f1)"

if [ -z "$START_LINE" ] || [ -z "$END_LINE" ]; then
  echo "WARNING: couldn't find the toolkit section markers in $SOURCE/CLAUDE.md;"
  echo "copying it as-is instead. Fill in the toolkit section by hand."
  cp "$SOURCE/CLAUDE.md" "$DEST/CLAUDE.md"
else
  {
    head -n $((START_LINE - 1)) "$SOURCE/CLAUDE.md"
    cat <<EOF
## This project's toolkit

Filled in by \`scripts/bootstrap-new-project.sh\` when this project was set up from Luna-Core. Keep it current the same as anything else in this file — if an agent gets added/removed/renamed, or a dependency changes, update this section too.

- **Agents:** ${AGENT_LIST} (see \`.claude/agents/\`)
- **Commands:** \`/wake-up\`, \`/debrief\` (see \`.claude/commands/\`)
- **Dependencies:** superpowers-extended-cc, Claude Code on Steroids (see README's "Dependency: superpowers plugins")
- **Personality & voice:** Astrid — maintained separately at https://github.com/LunaBelleElite/Astrid, kept as a sibling clone (e.g. \`../Astrid\` next to this project) rather than bundled into this repo, so she can be adopted, updated, and versioned independently of any one project's toolkit. Read \`PERSONALITY.md\` and \`VOICE.md\` there — not copied here, and not duplicated in this file. Always the \`dev\` branch, deliberately: her repo has no \`main\` (retired — \`dev\` was always kept current, so a second branch just to lag behind it added merge overhead with no real benefit), and \`dev\` is already that repo's default branch, so a plain clone gets it without a flag. \`git -C ../Astrid pull\` picks up anything new.
- **Versioning:** started at \`ver-0.1.0.0-dev\` (see "Versioning scheme" below and \`CHANGELOG.md\` for the current version)

EOF
    tail -n +${END_LINE} "$SOURCE/CLAUDE.md"
  } > "$DEST/CLAUDE.md"
  # Fill in any remaining <ProjectName> placeholders elsewhere in the file
  # (e.g. "owned by <projectname>-docs-writer" in the Wake Up/Debrief
  # section) -- safe to substitute unconditionally, unlike the bare word
  # "Luna-Core" which has legitimate dual meanings elsewhere in this file.
  # Identifier form first (lowercased), then the prose form -- same two-form
  # rule the agent files above follow.
  sed -i "s/<projectname>-/${LC_NAME}-/g" "$DEST/CLAUDE.md"
  sed -i "s/<ProjectName>/${PROJECT_NAME}/g" "$DEST/CLAUDE.md"
fi
echo "- Placed CLAUDE.md at $DEST/CLAUDE.md with the toolkit section filled in"

# --- fresh ref/docs (never copied — Luna-Core's own is unrelated/empty) ---
mkdir -p "$DEST/ref/docs"
touch "$DEST/ref/docs/.gitkeep"
echo "- Created empty ref/docs/"

# --- prerequisites stub: copied (not generated) so the format documentation
# travels with it. It's comments only, so it declares nothing and warns about
# nothing until this project actually fills it in. ---
if [ -f "$SOURCE/ref/prerequisites.conf" ]; then
  cp "$SOURCE/ref/prerequisites.conf" "$DEST/ref/prerequisites.conf"
  echo "- Created ref/prerequisites.conf (empty stub -- declare this project's"
  echo "  runtime needs there so Wake Up can verify them on a new machine)"
fi

# --- every other folder the templates reference ---
#
# Standing rule: if a template file (CLAUDE.md, an agent, a protocol) tells a
# project to use a path, bootstrap creates it here. Otherwise the very first
# instruction an agent follows points at nothing, which reads as a broken
# toolkit rather than an empty project. Anything created empty needs a keeper
# file too -- git cannot track an empty directory, so without one the folder
# exists on the bootstrapping machine and is simply absent after a clone.

# .claude-memory/ is the repo side of the memory merge. merge-memory.sh would
# mkdir it on first use, but relying on that leaves it missing until someone
# happens to run a merge, and docs-writer owns it from day one.
mkdir -p "$DEST/.claude-memory"
touch "$DEST/.claude-memory/.gitkeep"
echo "- Created empty .claude-memory/ (repo side of the memory merge)"

# tests/ -- the qa-tester agent's first mandatory step is to read
# tests/TESTING_NOTES.md end to end, then the files its table names. Create
# the hub plus the two notes files that agent marks as read on EVERY pass.
# Deliberately no further notes files: the agent states its hub table is the
# authority on what exists, so a project should add notes files as it earns
# them rather than inheriting empty ones.
mkdir -p "$DEST/tests/notes"
cat > "$DEST/tests/TESTING_NOTES.md" <<EOF
# Testing notes hub

Read end to end by \`${LC_NAME}-qa-tester\` before it does any work. This
file is a **hub, not the notes** — the notes live in \`tests/notes/\`, and the
table below is the authority on which of them exist and when they apply.

Nothing has been tested yet: this project was just bootstrapped. Add a row for
each notes file as you create it, and keep this table complete — the agent
trusts it over any list written in the agent file itself.

| Notes file | Applies to | Read when |
| --- | --- | --- |
| \`notes/live-checks.md\` | Checks run against the real running project | Every pass |
| \`notes/open-items.md\` | Index of open questions, one row each | Every pass |
EOF
cat > "$DEST/tests/notes/live-checks.md" <<EOF
# Live checks

Things verified against the real running project rather than in a test
harness, and what they showed. Read on every qa-tester pass.

Empty so far — this project was just bootstrapped.
EOF
cat > "$DEST/tests/notes/open-items.md" <<EOF
# Open items

An **index**, not the detail: one row per open question. Give each a stable id,
the question in one line, where the detail lives, the exit condition, and the
test that owns it. Delete a row when it closes rather than annotating it.

Read whole on every qa-tester pass — it is meant to stay one screen.

| id | Question | Detail in | Exit condition | Owning test |
| --- | --- | --- | --- | --- |

No open items yet — this project was just bootstrapped.
EOF
cat > "$DEST/tests/TEST_INDEX.md" <<EOF
# Test index

Names every test in this project, so an agent can find the right one by
grepping this file instead of reading the test tree. Both
\`${LC_NAME}-qa-tester\` and \`${LC_NAME}-implementer\` are told to grep
here first.

Keep it current: a test that isn't listed is a test nobody will find, and an
entry pointing at a test that no longer exists is worse than no entry.

| Test | File | Covers |
| --- | --- | --- |

No tests yet — this project was just bootstrapped.
EOF
echo "- Created tests/ with TESTING_NOTES.md hub and TEST_INDEX.md, and the two always-read notes files"

# --- fresh handoff/ (never copied — Luna-Core's own notes are about
# Luna-Core, not this project) ---
mkdir -p "$DEST/handoff"
COMPUTER_NAME="$(hostname 2>/dev/null || echo "unknown")"
cat > "$DEST/handoff/STATUS.md" <<EOF
# Handoff status

Last-known computer and check-in time. Read/written by the Wake Up and Debrief protocols. Dev-only — never merges to \`main\`.

- **Computer:** (none — bootstrap only, no Wake Up has run yet)
- **Last checked:** ${CURRENT_DATE} (bootstrapped on ${COMPUTER_NAME})
EOF
cat > "$DEST/handoff/HANDOFF.md" <<EOF
# Handoff notes

Current state of this project, written so a person or AI with zero prior context could continue from here. Overwritten each time the Debrief Protocol runs.

## What this project is

(Fill this in — this project was just bootstrapped from Luna-Core and has no history yet.)

## Where this project publishes

(Not published anywhere yet. Record the exact location the FIRST time this
project is published -- a bundle path, or a git remote URL. The Wake Up
protocol's first step looks here to know where to fetch from, and a session
on a new machine has no other way to find out: the clone it was handed does
not carry the address it came from.)

## Current state

- Just set up from Luna-Core's template on ${CURRENT_DATE}.

## In progress / not yet resolved

- Nothing yet — this is the first run.

## Next steps

- Write this project's own README.md (don't reuse Luna-Core's). Include
  a "Dependency: superpowers plugins" section — CLAUDE.md references it by
  that exact name in two places, and won't resolve until it exists.
- Fill in \`.claude/agents/${LC_NAME}-qa-tester.md\`'s \`## Stack\` block once there's something to test.
- Run \`bash scripts/check-superpowers.sh\` to confirm both superpowers dependencies are installed.
EOF
echo "- Created fresh handoff/STATUS.md and handoff/HANDOFF.md"

# --- fresh CHANGELOG.md (scheme boilerplate only — not Luna-Core's history) ---
cat > "$DEST/CHANGELOG.md" <<EOF
# Changelog

## Versioning scheme

This project uses a 4-number version format: \`ver-A.B.C.D\`. The \`ver-\` prefix is always present.

- **A (1st number):** a complete redesign/rewrite of the whole program or layout.
- **B (2nd number):** changes to core features, short of a full redesign.
- **C (3rd number):** large bug fixes.
- **D (4th number):** very small bug fixes. A doc/spec-only addition (no feature, no bugfix) counts as a 4th-number change too, same treatment as a minor bugfix.

Any number can climb arbitrarily high. When a higher-order number increments, every number to its right resets to 0.

**Pre-1.0 phase:** development starts at \`ver-0.1.0.0-dev\`. Until this project reaches \`ver-1.0.0.0\`, anything that would normally increment the 1st number instead increments the 2nd number — the 1st number stays locked at 0 for the entire pre-1.0 phase. The 3rd and 4th numbers behave normally throughout. Moving to \`ver-1.0.0.0\` only happens when the user explicitly says so.

\`dev\` and \`main\` carry the exact same version number in lockstep — the only difference is \`dev\`'s version string has \`-dev\` appended.

(Full detail, including the "why," lives in \`CLAUDE.md\`. This section is not edited when entries below are added — only when the scheme itself changes.)

## ver-0.1.0.0-dev - ${CURRENT_DATE}

- Project bootstrapped from Luna-Core.
EOF
echo "- Created fresh CHANGELOG.md, starting at ver-0.1.0.0-dev"

echo
echo "=== Bootstrap complete for '$PROJECT_NAME' ==="
echo
echo "Installed:"
echo "  Agents:   $AGENT_LIST"
echo "  Commands: /wake-up, /debrief"
echo "  CLAUDE.md, CHANGELOG.md, ref/docs/, handoff/, scripts/ all in place"
echo
echo "Next: cd into $DEST, then run 'bash scripts/validate-luna-core-setup.sh'"
echo "to confirm everything actually landed correctly, then run"
echo "'bash scripts/check-superpowers.sh' to confirm plugin dependencies."

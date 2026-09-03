#!/usr/bin/env bash
# Two-way, no-clobber merge between this project's local Claude auto-memory and
# the .claude-memory/ folder in this repo. Replaces the older
# sync-memory-to-repo.sh / restore-memory-from-repo.sh pair, which were flat
# `cp -rf` in each direction and would silently destroy whichever side happened
# to be newer.
#
# Run it from either protocol, in either situation:
#   - Wake Up, on a machine that may not have this project's memory yet.
#   - Debrief, to get this session's memory into the repo before committing.
# It's the same operation both times, which is the point: two directions
# implemented separately would eventually disagree about what's current.
#
# Usage: bash scripts/merge-memory.sh [--dry-run]
#
# Deliberately NOT using `set -e`: this script is mostly comparisons, and a
# non-zero grep or a file without frontmatter is an expected outcome, not a
# failure. Errors are handled where they can actually happen.

set -uo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve the local auto-memory bucket: it's keyed on the project's directory
# path, sanitized. Derive it from the repo root rather than the caller's cwd, so
# this works when invoked from anywhere.
#
# Picking the home directory needs care -- get it wrong and memory silently
# merges into the wrong bucket. lib-claude-home.sh explains why and sets
# CLAUDE_DIR; it is shared so this logic cannot drift between scripts again.
if [ ! -f "$SCRIPT_DIR/lib-claude-home.sh" ]; then
  echo "ERROR: $SCRIPT_DIR/lib-claude-home.sh is missing -- refusing to guess where"
  echo "       this machine's memory lives, since guessing wrong would merge into"
  echo "       the wrong bucket. Restore it from Luna-Core's scripts/ folder."
  exit 1
fi
# shellcheck source=lib-claude-home.sh
. "$SCRIPT_DIR/lib-claude-home.sh"

# -l forces the LONG form. Without it, a repo root that arrived already
# 8.3-shortened stays short (C:\Users\USERNA~1\...) while Claude Code's own
# bucket name uses the long one (C:\Users\username\...) -- the same
# directory, two different sanitized strings, so this script would look in a
# bucket that does not exist and cheerfully report "nothing to merge". A silent
# no-op is the worst possible outcome here: memory simply stops roaming, and
# nothing says so. The setup validator already had to solve this same
# short-vs-long ambiguity for agent repo paths.
if command -v cygpath >/dev/null 2>&1; then
  RAW_PATH="$(cygpath -wl "$REPO_ROOT" 2>/dev/null || cygpath -w "$REPO_ROOT")"
else
  RAW_PATH="$REPO_ROOT"
fi
SANITIZED="$(echo "$RAW_PATH" | sed 's/[:\\/ ]/-/g')"

LOCAL_DIR="$CLAUDE_DIR/projects/$SANITIZED/memory"
REPO_DIR="$REPO_ROOT/.claude-memory"

echo "Local auto-memory: $LOCAL_DIR"
echo "Repo copy:         $REPO_DIR"
[ "$DRY_RUN" -eq 1 ] && echo "(dry run -- nothing will be written)"
echo

# A bucket that isn't there is indistinguishable from a bucket that is empty,
# and both look like "nothing to merge" -- which is exactly how a mis-computed
# bucket name would hide. If other projects have buckets but this one doesn't,
# say so and show them, so a wrong name is visible rather than silent.
if [ ! -d "$LOCAL_DIR" ]; then
  PROJECTS_ROOT="$CLAUDE_DIR/projects"
  if [ -d "$PROJECTS_ROOT" ]; then
    others="$(find "$PROJECTS_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -8)"
    if [ -n "$others" ]; then
      echo "NOTE: no local memory bucket at the expected name:"
      echo "        $SANITIZED"
      echo "      Other projects do have buckets here, so this is either a project"
      echo "      with no memory yet (normal, and fine), or a bucket-name mismatch"
      echo "      (bad, and silent). Existing buckets, for comparison:"
      printf '        %s\n' $(basename -a $others 2>/dev/null)
      echo
    fi
  fi
fi

if [ ! -d "$LOCAL_DIR" ] && [ ! -d "$REPO_DIR" ]; then
  echo "Neither side exists yet. Nothing to merge."
  exit 0
fi

changed=0
needs_attention=0

# --- timestamps -------------------------------------------------------------
#
# A memory file's own `modified:` frontmatter is the only timestamp that
# survives transport. File mtimes do NOT: git records no mtimes, so every file
# in a fresh clone carries the moment of checkout, which makes the repo side
# look uniformly newer than any local file. That's why the repo side falls back
# to the file's last *commit* date rather than its mtime.

ts_frontmatter() {
  local v parsed
  v="$(grep -m1 '^[[:space:]]*modified:' "$1" 2>/dev/null | sed 's/^[[:space:]]*modified:[[:space:]]*//' | tr -d '"'"'"'')"
  [ -z "$v" ] && return 1
  parsed="$(date -u -d "$v" +%s 2>/dev/null)"
  if [ -z "$parsed" ]; then
    # Present but unparseable. Falling back to mtime silently would quietly
    # downgrade the authoritative signal to guesswork over a typo, so say so.
    echo "  ?? $(basename "$1"): 'modified: $v' isn't a readable date -- falling back to file mtime, which is unreliable across machines. Worth fixing." >&2
    return 1
  fi
  printf '%s\n' "$parsed"
}

ts_mtime() { date -u -r "$1" +%s 2>/dev/null; }

ts_local() {
  ts_frontmatter "$1" && return 0
  ts_mtime "$1"
}

ts_repo() {
  local rel v
  ts_frontmatter "$1" && return 0
  rel="${1#"$REPO_ROOT"/}"
  v="$(git -C "$REPO_ROOT" log -1 --format=%ct -- "$rel" 2>/dev/null)"
  if [ -n "$v" ]; then echo "$v"; return 0; fi
  ts_mtime "$1"
}

human() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "$1"; }

copy() { # copy <src> <dst> <reason>
  echo "  -> $3"
  changed=$((changed + 1))
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$2")"
    cp -p "$1" "$2"
  fi
}

# --- MEMORY.md is an index, not a document ----------------------------------
#
# Both machines append pointer lines to it, so whichever copy is "newer" is
# simply missing the other's entries. Newest-wins would silently discard them.
# Union the pointer lines instead, keyed on the link target.

merge_index() {
  local newer="$1" older="$2" dest="$3"
  local tmp added=0
  tmp="$(mktemp)"
  cp "$newer" "$tmp"

  local line target
  while IFS= read -r line; do
    case "$line" in
      '- ['*'('*')'*)
        # Anchored deliberately. `.*(` is greedy, so it matches the LAST `(` on
        # the line -- a description ending "... (personal)" keys the entry on
        # `personal` instead of the link target. That misfires twice: the same
        # file keyed differently on each side gets appended as a duplicate, and
        # two different files whose descriptions end with the same parenthetical
        # collapse into one, so the second is never merged and is then erased
        # from the side that had it when the union is written back to both.
        # Anchor at line start, skip the bracketed label, take the FIRST group.
        target="$(printf '%s' "$line" | sed -n 's/^- \[[^]]*\](\([^)]*\)).*/\1/p')"
        [ -z "$target" ] && continue
        # Note the `--`: these patterns start with "- [", which grep would
        # otherwise parse as options.
        if grep -qF -- "($target)" "$tmp"; then
          # Same entry on both sides with different wording -- don't pick a
          # winner, just say so.
          if ! grep -qxF -- "$line" "$tmp"; then
            echo "  !! index entry for ($target) differs between sides -- left as-is, reconcile by hand"
            needs_attention=$((needs_attention + 1))
          fi
        else
          printf '%s\n' "$line" >> "$tmp"
          echo "  -> index: added missing entry for ($target)"
          added=$((added + 1))
        fi
        ;;
    esac
  done < "$older"

  if [ "$added" -gt 0 ]; then
    changed=$((changed + 1))
    if [ "$DRY_RUN" -eq 0 ]; then
      cp "$tmp" "$dest"
      # Both sides must end up with the union, not just one.
      [ "$dest" = "$LOCAL_DIR/MEMORY.md" ] && cp "$tmp" "$REPO_DIR/MEMORY.md"
      [ "$dest" = "$REPO_DIR/MEMORY.md" ] && cp "$tmp" "$LOCAL_DIR/MEMORY.md"
    fi
  fi
  rm -f "$tmp"
}

# --- walk the union of both sides -------------------------------------------

names="$(
  { [ -d "$LOCAL_DIR" ] && find "$LOCAL_DIR" -maxdepth 1 -name '*.md' -printf '%f\n'
    [ -d "$REPO_DIR" ]  && find "$REPO_DIR"  -maxdepth 1 -name '*.md' -printf '%f\n'
  } 2>/dev/null | sort -u
)"

if [ -z "$names" ]; then
  echo "No memory files on either side. Nothing to merge."
  exit 0
fi

for name in $names; do
  l="$LOCAL_DIR/$name"
  r="$REPO_DIR/$name"

  if [ -f "$l" ] && [ -f "$r" ]; then
    if cmp -s "$l" "$r"; then
      continue                      # identical -- nothing to say
    fi

    echo "$name: differs"

    if [ "$name" = "MEMORY.md" ]; then
      lt="$(ts_local "$l")"; rt="$(ts_repo "$r")"
      if [ "${lt:-0}" -ge "${rt:-0}" ]; then
        merge_index "$l" "$r" "$LOCAL_DIR/MEMORY.md"
      else
        merge_index "$r" "$l" "$REPO_DIR/MEMORY.md"
      fi
      continue
    fi

    lt="$(ts_local "$l")"; rt="$(ts_repo "$r")"
    if [ -z "$lt" ] || [ -z "$rt" ]; then
      echo "  !! couldn't determine a timestamp for both sides -- left as-is"
      needs_attention=$((needs_attention + 1))
    elif [ "$lt" -gt "$rt" ]; then
      copy "$l" "$r" "local is newer ($(human "$lt") vs $(human "$rt")) -- updated repo copy"
    elif [ "$rt" -gt "$lt" ]; then
      copy "$r" "$l" "repo is newer ($(human "$rt") vs $(human "$lt")) -- updated local copy"
    else
      echo "  !! same timestamp ($(human "$lt")) but different content -- left as-is, reconcile by hand"
      needs_attention=$((needs_attention + 1))
    fi

  elif [ -f "$l" ]; then
    # Present on one side only. Absence carries no timestamp, so there's no way
    # to tell "deliberately deleted over there" from "never received it".
    # Never delete; copy it across and say so, so it can be undone.
    echo "$name: only in local auto-memory"
    copy "$l" "$r" "copied into the repo (nothing is ever deleted by this script)"
  else
    echo "$name: only in the repo"
    copy "$r" "$l" "copied into local auto-memory (nothing is ever deleted by this script)"
  fi
done

# Flag anything the flat layout doesn't cover rather than ignoring it silently.
for d in "$LOCAL_DIR" "$REPO_DIR"; do
  if [ -d "$d" ]; then
    subs="$(find "$d" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)"
    if [ -n "$subs" ]; then
      echo
      echo "NOTE: subdirectories found under $d -- this script only merges *.md at the top level:"
      printf '  %s\n' $subs
      needs_attention=$((needs_attention + 1))
    fi
  fi
done

echo
if [ "$changed" -eq 0 ] && [ "$needs_attention" -eq 0 ]; then
  echo "Both sides already agree. Nothing copied."
else
  echo "$changed file(s) updated; $needs_attention needing a human decision."
  [ "$needs_attention" -gt 0 ] && echo "Nothing was overwritten for the items marked !! above."
fi

if [ "$DRY_RUN" -eq 0 ] && [ "$changed" -gt 0 ]; then
  echo
  echo "If .claude-memory/ changed, commit it to dev (with explicit permission,"
  echo "per the project's standing git rule) so it roams with you."
fi

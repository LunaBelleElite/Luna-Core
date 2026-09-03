#!/usr/bin/env bash
# Checks the runtime/toolchain prerequisites this project declares in
# ref/prerequisites.conf -- the .NET SDK, a Python version, a Node version,
# whatever this particular project actually needs to be worked on.
#
# Prerequisites differ per project, so nothing is hardcoded here: this script is
# the generic checker, and each project declares its own list. A project that
# declares nothing gets no output beyond a neutral line and no warnings -- a
# docs-only project must not nag forever.
#
# Usage: bash scripts/check-prerequisites.sh
#
# When something is absent, this script cannot install it -- a runtime install
# is the user's decision and often needs elevation. So the declaration carries
# the install instructions with it, and they are printed at the point of
# failure. A check that says "NOT FOUND" and stops leaves the user to work out
# what to do; that is the whole gap this exists to close. See the Wake Up
# protocol's standing rule: anything missing gets actionable instructions, and
# work does not continue as though it were present.
#
# Exit code is non-zero if something declared isn't satisfied, so a caller can
# notice -- but callers should treat this as informational (the way
# validate-luna-core-setup.sh treats check-superpowers.sh), not as proof the
# project setup itself is broken.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

CONF="ref/prerequisites.conf"

if [ ! -f "$CONF" ]; then
  echo "NOTE: no $CONF in this project -- nothing declared, nothing checked."
  echo "      Create it (see Luna-Core's copy for the format) if this project"
  echo "      needs a particular runtime or toolchain to work on."
  exit 0
fi

status=0
checked=0

trim() { printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }

# --- pass 1: parse ----------------------------------------------------------
#
# Two passes, because an install hint is written on continuation lines AFTER
# the check it belongs to, and a hint cannot be printed by a check that has
# already run. Hints use leading '>' rather than a fourth pipe-delimited field:
# everything after the second '|' is the regex verbatim (so alternation like
# ^(8|9)\. works), and a fourth field would break that. Continuation lines also
# let an install hint span several lines, which real install steps usually do.

LABELS=(); CMDS=(); WANTS=(); HINTS=()

while IFS= read -r raw || [ -n "$raw" ]; do
  line="$(trim "$raw")"
  [ -z "$line" ] && continue
  case "$line" in \#*) continue ;; esac

  # Continuation: install instructions for the check declared just above.
  case "$line" in
    ">"*)
      hint="$(trim "${line#>}")"
      if [ "${#LABELS[@]}" -eq 0 ]; then
        echo "NOTE: install-hint line in $CONF has no check above it to attach to: $line"
        continue
      fi
      idx=$(( ${#HINTS[@]} - 1 ))
      if [ -z "${HINTS[$idx]}" ]; then
        HINTS[$idx]="$hint"
      else
        HINTS[$idx]="${HINTS[$idx]}"$'\n'"$hint"
      fi
      continue
      ;;
  esac

  case "$line" in
    *"|"*) : ;;
    *)
      echo "NOTE: skipping malformed line in $CONF (need 'label | command | regex'): $line"
      continue
      ;;
  esac

  label="$(trim "${line%%|*}")"
  rest="${line#*|}"
  case "$rest" in
    *"|"*) cmd="$(trim "${rest%%|*}")"; want="$(trim "${rest#*|}")" ;;
    *)     cmd="$(trim "$rest")";       want="" ;;
  esac

  if [ -z "$label" ] || [ -z "$cmd" ]; then
    echo "NOTE: skipping malformed line in $CONF (need 'label | command | regex'): $line"
    continue
  fi

  LABELS+=("$label"); CMDS+=("$cmd"); WANTS+=("$want"); HINTS+=("")
done < "$CONF"

# --- pass 2: check ----------------------------------------------------------

show_hint() { # show_hint <index> <label>
  local h="${HINTS[$1]}"
  if [ -n "$h" ]; then
    echo "  How to install $2 on this machine:"
    printf '%s\n' "$h" | sed 's/^/      /'
    echo "  Install it before relying on this project, then re-run this check."
  else
    # An undeclared hint is a gap, but it is not a dead end -- this output is
    # normally read by an AI agent, which can work out the install for this
    # specific machine and then write it down. Say that, so "not declared"
    # doesn't get passed to the user as though it were the answer.
    echo "  No install instructions are declared for this one."
    echo "  Work out how it installs on THIS machine (this OS / package manager),"
    echo "  hand over a specific ready-to-run command rather than a general"
    echo "  suggestion, and ask before anything needing elevation. Say whether the"
    echo "  command is one you verified or one you inferred -- don't present a"
    echo "  guess as tested. Then add it to $CONF as '>' continuation lines under"
    echo "  this entry, so the next new machine is told instead of rediscovering."
  fi
}

i=0
while [ "$i" -lt "${#LABELS[@]}" ]; do
  label="${LABELS[$i]}"; cmd="${CMDS[$i]}"; want="${WANTS[$i]}"

  # Catch an unusable pattern before it can masquerade as a version mismatch.
  # grep exits 2 on a bad regex and 1 on a clean no-match; without this check
  # the two are indistinguishable and a typo reads as "wrong version installed".
  if [ -n "$want" ]; then
    printf '' | grep -qE "$want" 2>/dev/null
    if [ $? -gt 1 ]; then
      status=1
      echo "NOTE: $label -- '$want' isn't a valid regex, so this line can't be checked."
      echo "      Fix the pattern in $CONF. (Everything after the second '|' is the"
      echo "      regex, so pipes inside it are fine.)"
      i=$((i + 1)); continue
    fi
  fi

  checked=$((checked + 1))

  out="$(eval "$cmd" 2>&1)"
  rc=$?

  if [ $rc -ne 0 ]; then
    status=1
    echo "NOT FOUND: $label -- \`$cmd\` failed (exit $rc)."
    [ -n "$out" ] && echo "           output: $(printf '%s' "$out" | head -1)"
    show_hint "$i" "$label"
    i=$((i + 1)); continue
  fi

  first="$(printf '%s' "$out" | head -1)"

  if [ -z "$want" ]; then
    echo "OK: $label ($first)"
  elif printf '%s' "$out" | grep -qE "$want"; then
    echo "OK: $label ($first)"
  else
    status=1
    echo "MISMATCH: $label -- expected /$want/, got: $first"
    show_hint "$i" "$label"
  fi
  i=$((i + 1))
done

if [ "$checked" -eq 0 ]; then
  echo "OK: no runtime prerequisites declared for this project."
  exit 0
fi

echo
if [ "$status" -eq 0 ]; then
  echo "All $checked declared prerequisite(s) satisfied."
else
  echo "Some declared prerequisites need attention -- see above. This script does"
  echo "not install anything itself; the instructions printed with each item are"
  echo "meant to be acted on -- carried out where that's safe, or handed to the"
  echo "user as a specific command where it needs their decision (elevation, a"
  echo "machine-wide change, a remote script). Don't stop at reporting them."
fi
exit $status

#!/usr/bin/env bash
# Verify every relative markdown link ([text](path)) in the readiness-program
# runbook docs resolves to a real file, either in the workspace root or in a
# nested repo. Run from anywhere; it locates the workspace root from its own
# path (this script lives at <workspace-root>/scripts/).
#
# Usage: scripts/check_readiness_runbook_links.sh [file ...]
#   With no args, checks the six 2026-09-03 readiness-program runbook docs.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  FILES=(
    "$ROOT/w17-parts-to-gift-master-sequence.md"
    "$ROOT/w17-giftee-pc-install-guide.md"
    "$ROOT/w17-handover-checklist.md"
    "$ROOT/w17-elrs-backup-handset.md"
    "$ROOT/w17-gcs-box-guide.md"
    "$ROOT/w17-a2-execution-session-prompt.md"
  )
fi

exit_code=0
for f in "${FILES[@]}"; do
  echo "== $f =="
  if [ ! -f "$f" ]; then
    echo "  FILE NOT FOUND"
    exit_code=1
    continue
  fi
  targets="$(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//' | sort -u)"
  [ -z "$targets" ] && { echo "  (no markdown links)"; continue; }
  while IFS= read -r target; do
    case "$target" in
      http*|mailto:*|"#"*) continue ;;
    esac
    path="${target%%#*}"
    [ -z "$path" ] && continue
    if [ -f "$ROOT/$path" ]; then
      echo "  OK   $target"
    else
      echo "  MISSING   $target"
      exit_code=1
    fi
  done <<< "$targets"
done
exit $exit_code

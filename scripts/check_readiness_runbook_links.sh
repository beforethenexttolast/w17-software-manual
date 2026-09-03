#!/usr/bin/env bash
# Verify every path reference in the readiness-program runbook docs resolves
# to a real file: both markdown links ([text](path)) and backticked path
# tokens (`some/path.md`, optionally with a trailing :LINE or :LINE-LINE),
# for the extensions .md/.sh/.js/.go/.json/.yaml/.yml (the doc/script/config
# kinds these runbooks actually cite; source headers like .cpp/.hpp are out
# of scope — those are checked by path:line during the doc-truth review, not
# by this script).
#
# This workspace-root worktree does not check out the nested repos
# (w17-control-fw, w17-ground-station, w17-mapper, w17-soundlight-fw,
# w17-3d-codex, iPhone_rc) it cites by relative path, so a path into one of
# them is EXPECTED to read MISSING here — that is reported as MISSING-NESTED
# (informational, does not fail the run) rather than a plain MISSING, unless
# --workspace-root is given, in which case it is actually resolved there and
# a real miss is a hard failure. Run it BOTH ways before trusting it (see
# w17-parts-to-gift-master-sequence.md's fixer-pass instructions):
#   scripts/check_readiness_runbook_links.sh
#   scripts/check_readiness_runbook_links.sh --workspace-root /Users/vitaliykhomenko/Documents/projects
#
# A backticked path with a slash but no nested-repo prefix (e.g.
# "main/hotspot.js" for what is really w17-ground-station/main/hotspot.js —
# prose sometimes drops a prefix already established a sentence earlier) is
# reported UNVERIFIED, not failed, when there is no --workspace-root to
# actually search; give it one and an unresolved one becomes a real MISSING.
# A markdown [text](path) link never gets this leniency — that form is
# always meant to be workspace-root-relative in this doc set, so an
# unresolved one fails the run with or without --workspace-root.
#
# A bare filename with no "/" at all (e.g. `CLAUDE.md`, `settings.json`) is
# inherently ambiguous prose — it might name a workspace-root file, a
# nested-repo file, or (for things like `settings.json`) a runtime artifact
# that was never a repo path at all. These are reported UNVERIFIED
# (informational, never fails the run) rather than guessed at.
#
# A path under review-seeds/ (the v2 review JSON a fixer pass reads) is
# orchestrator scratch data in neither root by design — reported
# MISSING-SCRATCH, never failed, with or without --workspace-root.
#
# Usage: scripts/check_readiness_runbook_links.sh [--workspace-root PATH] [file ...]
#   With no file args, checks the seven 2026-09-03 readiness-program runbook
#   docs (the six link-bearing ones plus the workspace-root doc corrected in
#   the same fixer pass).
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_ROOT=""
NESTED_REPOS=(w17-control-fw w17-ground-station w17-soundlight-fw w17-mapper w17-3d-codex iPhone_rc)
# Directories that are orchestrator/session scratch data, not part of any
# git repo in EITHER root (checked against neither) — e.g. review-seeds/,
# the v2 review JSON inputs a fixer pass reads but that never land in git.
SCRATCH_PREFIXES=(review-seeds)

FILES=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --workspace-root)
      shift
      [ "$#" -gt 0 ] || { echo "--workspace-root needs a path" >&2; exit 2; }
      WORKSPACE_ROOT="$(cd "$1" && pwd)"
      shift
      ;;
    --workspace-root=*)
      WORKSPACE_ROOT="$(cd "${1#--workspace-root=}" && pwd)"
      shift
      ;;
    *)
      FILES+=("$1")
      shift
      ;;
  esac
done

if [ "${#FILES[@]}" -eq 0 ]; then
  FILES=(
    "$ROOT/w17-parts-to-gift-master-sequence.md"
    "$ROOT/w17-giftee-pc-install-guide.md"
    "$ROOT/w17-handover-checklist.md"
    "$ROOT/w17-elrs-backup-handset.md"
    "$ROOT/w17-gcs-box-guide.md"
    "$ROOT/w17-a2-execution-session-prompt.md"
    "$ROOT/w17-electrical-inputs-for-codex.md"
  )
fi

is_nested() {
  # $1 = path; true if its top-level segment names a known nested repo.
  local top="${1%%/*}"
  local repo
  for repo in "${NESTED_REPOS[@]}"; do
    [ "$top" = "$repo" ] && return 0
  done
  return 1
}

is_scratch() {
  # $1 = path; true if its top-level segment is orchestrator scratch data
  # that exists in neither root by design.
  local top="${1%%/*}"
  local prefix
  for prefix in "${SCRATCH_PREFIXES[@]}"; do
    [ "$top" = "$prefix" ] && return 0
  done
  return 1
}

exit_code=0

check_target() {
  # $1 = raw target string (already stripped of a trailing #anchor for md
  # links; backticked tokens still carry a possible :LINE(-LINE) suffix,
  # stripped here).
  # $2 = "strict" for a [text](path) markdown link (the original contract:
  # a workspace-root-relative miss is always a hard failure) or "loose" for
  # a backticked prose token (a slash-bearing path with no nested-repo
  # prefix and no workspace-root to check against is reported, not failed,
  # since backtick prose sometimes drops a repo prefix already established
  # by nearby text — e.g. "main/hotspot.js" after "w17-ground-station" was
  # named a sentence earlier).
  local raw="$1" strict="${2:-strict}" path
  path="$(printf '%s' "$raw" | sed -E 's/:[0-9]+(-[0-9]+)?$//')"
  [ -z "$path" ] && return 0

  case "$path" in
    *'\'*)
      echo "  SKIP      $raw   (Windows-style backslash path, not checked)"
      return 0
      ;;
  esac

  if [ -f "$ROOT/$path" ]; then
    echo "  OK        $raw"
    return 0
  fi
  if [ -n "$WORKSPACE_ROOT" ] && [ -f "$WORKSPACE_ROOT/$path" ]; then
    echo "  OK        $raw   (workspace-root)"
    return 0
  fi

  if is_scratch "$path"; then
    echo "  MISSING-SCRATCH   $raw   (orchestrator scratchpad reference, not a repo path in either root — expected, never resolvable here)"
    return 0
  fi

  if is_nested "$path"; then
    if [ -n "$WORKSPACE_ROOT" ]; then
      echo "  MISSING   $raw   (nested-repo path, not found under --workspace-root)"
      exit_code=1
    else
      echo "  MISSING-NESTED   $raw   (expected absent in this worktree; re-run with --workspace-root to verify)"
    fi
    return 0
  fi

  case "$path" in
    */*)
      # Has a directory component but isn't under a known nested repo and
      # isn't a workspace-root file either: try it one level inside each
      # nested repo (a path written relative to "inside that repo", e.g.
      # main/hotspot.js meaning w17-ground-station/main/hotspot.js) when we
      # have a real workspace root to search.
      if [ -n "$WORKSPACE_ROOT" ]; then
        local repo
        for repo in "${NESTED_REPOS[@]}"; do
          if [ -f "$WORKSPACE_ROOT/$repo/$path" ]; then
            echo "  OK        $raw   (resolved under $repo/)"
            return 0
          fi
        done
        echo "  MISSING   $raw"
        exit_code=1
        return 0
      fi
      if [ "$strict" = "strict" ]; then
        echo "  MISSING   $raw"
        exit_code=1
      else
        echo "  UNVERIFIED   $raw   (relative path, no nested-repo prefix — needs --workspace-root to check; not failed)"
      fi
      ;;
    *)
      # Bare filename, no directory component: ambiguous prose reference
      # (could be workspace-root, nested-repo, or not a repo path at all —
      # e.g. a runtime artifact like settings.json). Best-effort locate by
      # basename; never fails the run either way.
      local hit="" hits=0 search_roots=("$ROOT")
      [ -n "$WORKSPACE_ROOT" ] && search_roots+=("$WORKSPACE_ROOT")
      local sroot found
      for sroot in "${search_roots[@]}"; do
        while IFS= read -r found; do
          [ -z "$found" ] && continue
          hit="$found"
          hits=$((hits + 1))
        done < <(find "$sroot" -maxdepth 6 -name "$(basename "$path")" 2>/dev/null)
      done
      if [ "$hits" -eq 1 ]; then
        echo "  OK        $raw   (basename match: ${hit#"$ROOT"/})"
      elif [ "$hits" -gt 1 ]; then
        echo "  UNVERIFIED   $raw   (bare filename, $hits basename matches — ambiguous, not checked)"
      else
        echo "  UNVERIFIED   $raw   (bare filename, no match found — ambiguous prose reference or a non-repo artifact, not checked)"
      fi
      ;;
  esac
}

for f in "${FILES[@]}"; do
  echo "== $f =="
  if [ ! -f "$f" ]; then
    echo "  FILE NOT FOUND"
    exit_code=1
    continue
  fi

  md_targets="$(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//' | sort -u)"
  bt_targets="$(grep -oE '`[^`]+\.(md|sh|js|go|json|yaml|yml)(:[0-9]+(-[0-9]+)?)?`' "$f" \
    | sed -E 's/^`//; s/`$//' | sort -u)"

  if [ -z "$md_targets" ] && [ -z "$bt_targets" ]; then
    echo "  (no links or path-like backtick tokens found)"
    continue
  fi

  if [ -n "$md_targets" ]; then
    while IFS= read -r target; do
      [ -z "$target" ] && continue
      case "$target" in
        http*|mailto:*|"#"*) continue ;;
      esac
      target="${target%%#*}"
      [ -z "$target" ] && continue
      check_target "$target" strict
    done <<< "$md_targets"
  fi

  if [ -n "$bt_targets" ]; then
    while IFS= read -r target; do
      [ -z "$target" ] && continue
      check_target "$target" loose
    done <<< "$bt_targets"
  fi
done
exit $exit_code

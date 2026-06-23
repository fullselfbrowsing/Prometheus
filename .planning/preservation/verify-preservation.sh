#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$SOURCE_ROOT"

bundle=".context/falkon-preservation/falkon-prometheus-v1.bundle"
patch_dir=".context/falkon-preservation/patches"
dossier=".planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md"
expected_head="b0521c9d37e7545c680b78dfcc24f777a984091c"
expected_patch_count="81"

fail() {
  printf 'preservation check failed: %s\n' "$1" >&2
  exit 1
}

require_rg() {
  local pattern="$1"
  shift
  if ! rg --quiet "$pattern" "$@"; then
    fail "missing required pattern: $pattern"
  fi
}

check_preservation_artifacts() {
  [ ! -d "falkon" ] || fail "active long-lived falkon/ directory exists at workspace root"
  [ -s "$bundle" ] || fail "missing or empty bundle: $bundle"
  [ -d "$patch_dir" ] || fail "missing patch directory: $patch_dir"

  git bundle verify "$bundle" >/dev/null 2>&1 || fail "git bundle verify failed: $bundle"

  local head_ref
  head_ref="$(git ls-remote "$bundle" HEAD | awk '$2 == "HEAD" {print $1; exit}')"
  [ "$head_ref" = "$expected_head" ] || fail "bundle HEAD was $head_ref, expected $expected_head"

  local master_ref
  master_ref="$(git ls-remote "$bundle" refs/heads/master | awk '$2 == "refs/heads/master" {print $1; exit}')"
  [ "$master_ref" = "$expected_head" ] || fail "bundle refs/heads/master was $master_ref, expected $expected_head"

  local patch_count
  patch_count="$(find "$patch_dir" -maxdepth 1 -name '*.patch' | wc -l | tr -d ' ')"
  [ "$patch_count" = "$expected_patch_count" ] || fail "patch count was $patch_count, expected $expected_patch_count"

  local tmpdir
  tmpdir="$(mktemp -d .context/falkon-preservation/restore-check-XXXXXX)"
  cleanup_restore_check() {
    if [ -n "${tmpdir:-}" ] && [ -d "$tmpdir" ]; then
      rm -rf "$tmpdir"
    fi
  }
  trap cleanup_restore_check EXIT

  git clone --quiet "$bundle" "$tmpdir/repo" || fail "temporary bundle clone failed"

  local restored_head
  restored_head="$(git -C "$tmpdir/repo" rev-parse HEAD)"
  [ "$restored_head" = "$expected_head" ] || fail "restored HEAD was $restored_head, expected $expected_head"

  cleanup_restore_check
  trap - EXIT

  git check-ignore -q "$bundle" || fail "preservation bundle is not ignored by root git: $bundle"
  git check-ignore -q "$patch_dir" || fail "preservation patch directory is not ignored by root git: $patch_dir"

  if git ls-files -- "$bundle" "$patch_dir" | rg -q .; then
    fail "preservation artifacts must not be tracked by root git"
  fi
}

check_dossier_evidence() {
  require_rg "Preservation Evidence Gate" "$dossier"
  require_rg "b0521c9d37e7545c680b78dfcc24f777a984091c" "$dossier"
  require_rg "patch count.*81|81.*patch" "$dossier"
  require_rg "already_removed" "$dossier"
  require_rg "reference-only|reference_only" "$dossier"
  require_rg "Do not copy.*without explicit license review|no GPL Falkon.*without explicit license review" "$dossier"
}

check_migration_map() {
  require_rg "Capability Migration Map" "$dossier"
  require_rg "Chromium Owner" "$dossier"
  require_rg "Parity Evidence" "$dossier"
  require_rg "License / Attribution Note" "$dossier"
  require_rg "Product identity and Powered by FSB" "$dossier"
  require_rg "Font Awesome Free offline icon subset" "$dossier"
  require_rg "Compact chrome" "$dossier"
  require_rg "FSB Control Panel nine operator sections" "$dossier"
  require_rg "Prometheus start page" "$dossier"
  require_rg "Native agent command router" "$dossier"
  require_rg "DOM/page snapshots" "$dossier"
  require_rg "MCP bridge tool names" "$dossier"
  require_rg "Provider runtime" "$dossier"
  require_rg "Supervision, pairing" "$dossier"
  require_rg "Extension surfaces" "$dossier"
  require_rg "Parity/security/de-Falkon" "$dossier"
  require_rg "contract_only" "$dossier"
  require_rg "product_owned" "$dossier"
  require_rg "third_party_attribution_required" "$dossier"
  require_rg "reference_only" "$dossier"
  require_rg "license_review_required" "$dossier"
  require_rg "Phase 13 Product Identity" "$dossier"
  require_rg "Phase 14 Asset" "$dossier"
  require_rg "Phase 15 Chromium UI Shell" "$dossier"
  require_rg "Phase 16 Prometheus WebUI" "$dossier"
  require_rg "Phase 17 Native Agent" "$dossier"
  require_rg "Phase 18 Page Adapter" "$dossier"
  require_rg "Phase 19 MCP Bridge" "$dossier"
  require_rg "Phase 20 FSB Runtime" "$dossier"
  require_rg "Phase 21 Supervision" "$dossier"
  require_rg "Phase 22 Chrome Extension" "$dossier"
  require_rg "Phase 23 Migration Parity" "$dossier"
  require_rg "Phase 24 Packaging" "$dossier"
}

check_visual_ledger() {
  require_rg "Deferred Visual Check Ledger" "$dossier"

  local visual_rows
  visual_rows="$(rg -c '^\| VIS-(08|09|10)-' "$dossier")"
  [ "$visual_rows" = "26" ] || fail "visual ledger row count was $visual_rows, expected 26"

  require_rg "VIS-08-01" "$dossier"
  require_rg "VIS-08-10" "$dossier"
  require_rg "VIS-09-01" "$dossier"
  require_rg "VIS-09-08" "$dossier"
  require_rg "VIS-10-01" "$dossier"
  require_rg "VIS-10-08" "$dossier"
  require_rg "carry_forward" "$dossier"
  require_rg "retired" "$dossier"

  rg '^\| VIS-(08|09|10)-' "$dossier" | awk -F'|' '
    {
      status=$6
      owner=$5
      evidence=$7
      gsub(/^[ \t]+|[ \t]+$/, "", status)
      gsub(/^[ \t]+|[ \t]+$/, "", owner)
      gsub(/^[ \t]+|[ \t]+$/, "", evidence)
      if (status != "carry_forward" && status != "retired") {
        bad_status=1
      }
      if (owner == "" || evidence == "") {
        bad_content=1
      }
    }
    END {
      if (bad_status || bad_content) {
        exit 1
      }
    }
  ' || fail "visual ledger rows must have allowed status, Chromium owner, and future evidence"
}

check_freeze_docs() {
  require_rg "Source Wipe And Freeze Checklist" "$dossier"
  require_rg "already_removed" "$dossier"
  require_rg "must_stay" "$dossier"
  require_rg "reference_only" "$dossier"
  require_rg "future_chromium_owned" "$dossier"
}

check_stale_docs() {
  local stale_pattern
  stale_pattern='cmake -S falkon|falkon/tools|detached.*screen|prometheus-chromium-build.*running|built on Qt and QtWebEngine'

  local stale_files=(README.md .planning/STATE.md .planning/chromium/CHROMIUM-CHECKOUT.md)
  local file
  for file in "${stale_files[@]}"; do
    [ -r "$file" ] || fail "missing or unreadable stale-doc scan target: $file"
  done

  set +e
  rg -n "$stale_pattern" "${stale_files[@]}"
  local rg_status=$?
  set -e

  if [ "$rg_status" -eq 0 ]; then
    fail "stale active Falkon/build docs remain"
  fi

  [ "$rg_status" -eq 1 ] || fail "stale-doc scan failed with rg exit status $rg_status"
}

case "${1:-}" in
  --artifacts-only)
    check_preservation_artifacts
    ;;
  --dossier-only)
    check_dossier_evidence
    check_migration_map
    check_visual_ledger
    check_freeze_docs
    ;;
  "")
    check_preservation_artifacts
    check_dossier_evidence
    check_migration_map
    check_visual_ledger
    check_freeze_docs
    check_stale_docs
    ;;
  *)
    fail "unknown argument: $1"
    ;;
esac

printf 'Preservation verification passed.\n'

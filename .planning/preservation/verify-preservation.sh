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

case "${1:-}" in
  --artifacts-only)
    check_preservation_artifacts
    ;;
  --dossier-only)
    check_dossier_evidence
    check_migration_map
    ;;
  "")
    check_preservation_artifacts
    check_dossier_evidence
    check_migration_map
    ;;
  *)
    fail "unknown argument: $1"
    ;;
esac

printf 'Preservation verification passed.\n'

#!/usr/bin/env bash
set -euo pipefail

# GPL Falkon source guard for Prometheus Chromium directories.
# Fails immediately if any Falkon C++/Qt signature appears in Prometheus-owned Chromium source.
# Run before each Prometheus-branch commit.
# Source: Phase 13 license boundary decisions (BRAND-05).
# [VERIFIED: .planning/phases/13-product-identity-branding-and-legal-baseline/13-CONTEXT.md]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_ROOT="${PROJECT_ROOT}/.context/chromium"
CHROMIUM_SRC="${CHROMIUM_ROOT}/src"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"

export PATH="${DEPOT_TOOLS}:${PATH}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

fail() {
  printf 'GPL guard failed: %s\n' "$1" >&2
  exit 1
}

# -------------------------------------------------------------------------
# GPL Falkon signature patterns — derived from Falkon codebase naming
# conventions preserved at .context/falkon-preservation/.
# [ASSUMED: A1 — no authoritative Falkon signature spec; Phase 23 provides
# the exhaustive de-Falkon sweep.]
# -------------------------------------------------------------------------

SRC="${CHROMIUM_SRC}"

GPL_PATTERNS=(
  "class.*Falkon"
  "Falkon::"
  "falkon::"
  "FalkonBrowser"
  "#include.*qzcommon.h"
  "#include.*WebPage.h"
  "#include.*tabwidget"
  "QzBrowserWindow"
  "QWebEngineView"
)

# -------------------------------------------------------------------------
# Scan only Prometheus-owned Chromium directories.
# Scope is intentionally narrow (BRAND-05, T-13-01):
#   - chrome/browser/prometheus
#   - components/prometheus
# Scanning the full Chromium tree would produce false positives from
# unrelated third-party code. Both dirs may not exist yet (no Prometheus
# C++ has been written); guard returns exit 0 in that case.
# -------------------------------------------------------------------------

FOUND=0
for pat in "${GPL_PATTERNS[@]}"; do
  hits=$(grep -rn --include="*.cc" --include="*.h" --include="*.mm" \
         -E "${pat}" \
         "${SRC}/chrome/browser/prometheus" \
         "${SRC}/components/prometheus" 2>/dev/null || true)
  if [[ -n "${hits}" ]]; then
    printf 'GPL GUARD FAIL: Pattern "%s" found in Prometheus Chromium source:\n%s\n' \
      "${pat}" "${hits}" >&2
    FOUND=1
  fi
done

if [[ "${FOUND}" -ne 0 ]]; then
  fail "GPL Falkon signatures detected in Prometheus Chromium directories. Do not copy GPL source into Chromium without license review."
fi

printf 'GPL guard: clean — no Falkon GPL signatures in Prometheus Chromium directories.\n'

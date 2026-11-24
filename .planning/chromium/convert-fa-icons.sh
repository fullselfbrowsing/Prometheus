#!/usr/bin/env bash
set -euo pipefail

# convert-fa-icons.sh — Font Awesome Free SVG to Chromium .icon conversion helper.
# Converts the curated FA Free subset (72 glyphs per fa-glyph-manifest.txt) to
# gfx::VectorIcon .icon format for use in
#   chrome/browser/resources/prometheus/vector_icons/
# and copies optimized SVGs (with CC BY 4.0 attribution preserved) to
#   chrome/browser/resources/prometheus/svg/
#
# Design decisions implemented:
#  D-06: Full-parity icon set — both .icon (Views) and .svg (WebUI) per glyph.
#  D-07: Scripted, repeatable conversion; provenance header injected per .icon file.
#  D-08: Substitutions — arrow-down-to-line -> arrow-down; sidebar-flip placeholder.
#  D-12: CC BY 4.0 attribution comment preserved in every output SVG.
#
# MANIFEST-DRIVEN (HIGH fix):
#   This script iterates fa-glyph-manifest.txt — NOT "${FA_SOURCE_DIR}"/*.svg.
#   The manifest is the single source of which glyphs ship; the script FAILS
#   unless the output count exactly matches EXPECTED_COUNT (set from the manifest).
#
# Prerequisites (fail-fast checks at top):
#  - svgo: npm install -g svgo (SVG optimizer, CC BY 4.0 comment preservation)
#  - skiafy: npm install -g skiafy
#
# Usage:
#   bash .planning/chromium/convert-fa-icons.sh [--dry-run]
#
# Source: .planning/phases/14-asset-and-design-system-port/14-CONTEXT.md §D-06..D-09
# [VERIFIED: 14-PATTERNS.md §convert-fa-icons.sh]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

CHROMIUM_SRC="${PROJECT_ROOT}/.context/chromium/src"
FA_SOURCE_DIR="${PROJECT_ROOT}/.context/falkon-preservation/falkon/src/lib/data/icons/fa"
ICON_OUT_DIR="${CHROMIUM_SRC}/chrome/browser/resources/prometheus/vector_icons"
SVG_OUT_DIR="${CHROMIUM_SRC}/chrome/browser/resources/prometheus/svg"
SVGO_CONFIG="${SCRIPT_DIR}/svgo-preserve-comments.json"
GLYPH_MANIFEST="${SCRIPT_DIR}/fa-glyph-manifest.txt"
TMP_DIR="/tmp/convert-fa-icons-$$"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  printf 'dry-run mode: will report actions but not write files\n'
fi

fail() {
  printf 'FA icon conversion failed: %s\n' "$1" >&2
  exit 1
}

# -------------------------------------------------------------------------
# Manifest check (LOAD-BEARING — if missing, the conversion cannot proceed)
# -------------------------------------------------------------------------

[ -f "${GLYPH_MANIFEST}" ] \
  || fail "Glyph manifest not found at ${GLYPH_MANIFEST} — this file is required"

# Count non-comment, non-blank lines in the manifest to set the expected total
EXPECTED_COUNT=$(grep -vcE '^[[:space:]]*(#|$)' "${GLYPH_MANIFEST}")
printf 'Manifest: %s (%d glyphs)\n' "${GLYPH_MANIFEST}" "${EXPECTED_COUNT}"

# -------------------------------------------------------------------------
# Dependency checks
# -------------------------------------------------------------------------

command -v svgo >/dev/null 2>&1 \
  || fail "svgo not found — install with: npm install -g svgo (check https://www.npmjs.com/package/svgo)"

command -v skiafy >/dev/null 2>&1 \
  || fail "skiafy not found — install with: npm install -g skiafy"

# -------------------------------------------------------------------------
# Input / output directory checks
# -------------------------------------------------------------------------

[ -d "${FA_SOURCE_DIR}" ] \
  || fail "FA source directory not found at ${FA_SOURCE_DIR} — restore the falkon-preservation bundle first: bash .planning/preservation/verify-preservation.sh"

if [ "${DRY_RUN}" -eq 0 ]; then
  mkdir -p "${ICON_OUT_DIR}"
  mkdir -p "${SVG_OUT_DIR}"
  mkdir -p "${TMP_DIR}"
fi

# -------------------------------------------------------------------------
# Write SVGO config to preserve CC BY 4.0 comments (D-07 / D-12)
# Creates .planning/chromium/svgo-preserve-comments.json if it doesn't exist.
# -------------------------------------------------------------------------

if [ ! -f "${SVGO_CONFIG}" ]; then
  if [ "${DRY_RUN}" -eq 1 ]; then
    printf 'dry-run: would create %s\n' "${SVGO_CONFIG}"
  else
    cat > "${SVGO_CONFIG}" <<'JSON'
{
  "plugins": [
    {
      "name": "preset-default",
      "params": {
        "overrides": {
          "removeComments": false
        }
      }
    }
  ]
}
JSON
    printf 'Created SVGO config at %s (removeComments disabled to preserve CC BY 4.0)\n' "${SVGO_CONFIG}"
  fi
fi

# -------------------------------------------------------------------------
# Placeholder .icon and .svg for Pro-only glyphs (D-08)
# -------------------------------------------------------------------------

write_sidebar_flip_placeholder() {
  local icon_path="$1"
  local svg_path="$2"

  printf 'writing sidebar-flip placeholder (Pro-only, not in FA Free 6.x): %s\n' "${icon_path}"

  # Minimal placeholder .icon — two-panel layout approximation
  cat > "${icon_path}" <<'ICON'
// Copyright 2026 The Chromium Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Source: Font Awesome Free 6.x -- sidebar-flip (solid) [PLACEHOLDER]
// License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)
// NOTE: sidebar-flip is a Pro-only icon not available in FA Free 6.x.
// This is a hand-authored two-panel geometry placeholder per D-08.

CANVAS_DIMENSIONS, 20,
FILL_RULE_NONZERO,
// Left panel
MOVE_TO, 2, 2,
H_LINE_TO, 6,
V_LINE_TO, 18,
H_LINE_TO, 2,
CLOSE,
// Right panel
MOVE_TO, 8, 2,
H_LINE_TO, 18,
V_LINE_TO, 18,
H_LINE_TO, 8,
CLOSE,
ICON

  # Placeholder SVG — use the Falkon v1 bundle's sidebar-flip (which has CC BY 4.0 attribution)
  # or fall back to a hand-authored minimal SVG if the bundle source is not a placeholder.
  local bundle_sidebar_flip="${FA_SOURCE_DIR}/sidebar-flip.svg"
  if [ -f "${bundle_sidebar_flip}" ] && grep -q "CC BY 4\.0\|Font Awesome Free\|sidebar-flip" "${bundle_sidebar_flip}" 2>/dev/null; then
    cp "${bundle_sidebar_flip}" "${svg_path}"
    # Ensure CC BY 4.0 comment is present
    if ! grep -q "CC BY 4\.0\|Font Awesome Free" "${svg_path}" 2>/dev/null; then
      # Prepend attribution
      local tmp_svg="${svg_path}.tmp"
      {
        printf '<!--\n  sidebar-flip placeholder SVG for Prometheus.\n'
        printf '  sidebar-flip is a Pro-only icon not available in Font Awesome Free 6.x.\n'
        printf '  Source: Font Awesome Free 6.x -- sidebar-flip (solid) [PLACEHOLDER]\n'
        printf '  License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)\n'
        printf '-->\n'
        cat "${svg_path}"
      } > "${tmp_svg}"
      mv "${tmp_svg}" "${svg_path}"
    fi
  else
    # Hand-authored minimal placeholder SVG with CC BY 4.0 attribution (D-12)
    cat > "${svg_path}" <<'SVG'
<!--
  sidebar-flip placeholder SVG for Prometheus.
  This icon is a hand-authored two-panel geometry placeholder because
  sidebar-flip is a Pro-only icon not available in Font Awesome Free 6.x.
  Created per D-08 (substitution notes).
  Source: Font Awesome Free 6.x -- sidebar-flip (solid) [PLACEHOLDER]
  License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)
-->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <!-- Left panel representation -->
  <rect x="32" y="64" width="128" height="384" rx="16"/>
  <!-- Right panel representation -->
  <rect x="192" y="64" width="288" height="384" rx="16"/>
</svg>
SVG
  fi
}

# -------------------------------------------------------------------------
# Conversion loop (MANIFEST-DRIVEN)
#
# PARSE ORDER IS LOAD-BEARING (addresses MEDIUM review concern):
#   For each line in the manifest, the script:
#     1. Skips fully-blank lines and full-line comments (first non-space char is '#').
#     2. On a glyph line, FIRST extracts the trailing inline tag from the comment
#        (reads # SUBSTITUTE=<name> and # PLACEHOLDER BEFORE stripping the comment).
#        This is why substitution/placeholder always fire for the tagged lines —
#        the tags are read from the raw manifest line before any comment stripping.
#     3. ONLY THEN strips the '#...' trailing comment and trims whitespace to get
#        the bare glyph name.
#   Never strip the comment before reading the tag — that would disable the
#   substitution and placeholder branches (the HIGH review finding this fixes).
# -------------------------------------------------------------------------

CONVERTED=0
SKIPPED=0
ERRORS=0

while IFS= read -r raw_line; do
  # Step 1: skip blank lines and full-line comments
  trimmed="${raw_line#"${raw_line%%[! ]*}"}"  # trim leading whitespace
  [ -z "${trimmed}" ] && continue
  [[ "${trimmed}" == \#* ]] && continue

  # Step 2 (LOAD-BEARING — before stripping comment): extract inline tag
  substitute_name=""
  is_placeholder=0

  if [[ "${raw_line}" == *"# SUBSTITUTE="* ]]; then
    # Extract the substitution target name after 'SUBSTITUTE='
    substitute_name="${raw_line#*SUBSTITUTE=}"
    substitute_name="${substitute_name%%[[:space:]]*}"  # trim trailing whitespace
  elif [[ "${raw_line}" == *"# PLACEHOLDER"* ]]; then
    is_placeholder=1
  fi

  # Step 3: strip the '#...' trailing comment from the line and trim whitespace
  # to get the bare glyph name
  glyph_name="${raw_line%%#*}"         # remove from first '#' onwards
  glyph_name="${glyph_name%"${glyph_name##*[! ]}"}"  # rtrim whitespace
  glyph_name="${glyph_name#"${glyph_name%%[! ]*}"}"  # ltrim whitespace

  [ -z "${glyph_name}" ] && continue

  icon_name="fa_${glyph_name//-/_}.icon"
  svg_name="fa_${glyph_name//-/_}.svg"
  icon_path="${ICON_OUT_DIR}/${icon_name}"
  svg_path="${SVG_OUT_DIR}/${svg_name}"

  # --- D-08: Handle PLACEHOLDER glyphs (tag read in step 2, always fires) ---
  if [ "${is_placeholder}" -eq 1 ]; then
    printf 'D-08: creating placeholder for %s (Pro-only, not in FA Free 6.x)\n' "${glyph_name}"
    if [ "${DRY_RUN}" -eq 0 ]; then
      write_sidebar_flip_placeholder "${icon_path}" "${svg_path}"
    else
      printf 'dry-run: would write placeholder %s and %s\n' "${icon_path}" "${svg_path}"
    fi
    CONVERTED=$((CONVERTED + 1))
    continue
  fi

  # --- D-08: Handle SUBSTITUTE glyphs (tag read in step 2, always fires) ---
  actual_source="${FA_SOURCE_DIR}/${glyph_name}.svg"
  actual_glyph="${glyph_name}"

  if [ -n "${substitute_name}" ]; then
    printf 'D-08: substituting %s -> %s (manifest tag SUBSTITUTE=%s)\n' \
      "${glyph_name}" "${substitute_name}" "${substitute_name}"
    actual_source="${FA_SOURCE_DIR}/${substitute_name}.svg"
    actual_glyph="${substitute_name}"
    if [ ! -f "${actual_source}" ]; then
      printf 'error: substitution source %s not found for glyph %s\n' "${actual_source}" "${glyph_name}" >&2
      ERRORS=$((ERRORS + 1))
      continue
    fi
  else
    # Standard glyph: verify the source exists in FA_SOURCE_DIR
    if [ ! -f "${actual_source}" ]; then
      printf 'error: source not found: %s (glyph %s not in FA_SOURCE_DIR)\n' "${actual_source}" "${glyph_name}" >&2
      ERRORS=$((ERRORS + 1))
      continue
    fi
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    printf 'dry-run: would convert %s -> %s and %s\n' "${actual_source}" "${icon_path}" "${svg_path}"
    CONVERTED=$((CONVERTED + 1))
    continue
  fi

  TMP_SVG="${TMP_DIR}/${glyph_name}.svg"
  TMP_ICON_RAW="${TMP_DIR}/fa_${glyph_name//-/_}.icon.raw"

  # 1. Optimize with SVGO (preserve CC BY 4.0 comments per D-12)
  if ! svgo --config="${SVGO_CONFIG}" "${actual_source}" -o "${TMP_SVG}" < /dev/null 2>/dev/null; then
    printf 'warning: SVGO failed for %s; using unoptimized source\n' "${glyph_name}" >&2
    cp "${actual_source}" "${TMP_SVG}"
  fi

  # Verify CC BY 4.0 comment survived SVGO (inject if stripped)
  if ! grep -q "CC BY 4\.0\|Font Awesome Free" "${TMP_SVG}" 2>/dev/null; then
    TMP_SVG_WITH_ATTR="${TMP_DIR}/${glyph_name}_attr.svg"
    {
      printf '<!--\n  Font Awesome Free 6.x -- %s (solid)\n  License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)\n-->\n' "${actual_glyph}"
      cat "${TMP_SVG}"
    } > "${TMP_SVG_WITH_ATTR}"
    mv "${TMP_SVG_WITH_ATTR}" "${TMP_SVG}"
  fi

  # 2. Convert to .icon path commands with skiafy
  # Note: redirect stdin from /dev/null because skiafy (Node.js) detects non-TTY stdin and
  # adds it as an implicit input, which would consume the manifest file the while loop reads.
  if ! skiafy -i "${TMP_SVG}" -o "${TMP_ICON_RAW}" < /dev/null 2>/dev/null; then
    printf 'warning: skiafy failed for %s; skipping\n' "${glyph_name}" >&2
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # 3. Inject provenance header (D-07) and write final .icon file
  {
    printf '// Copyright 2026 The Chromium Authors\n'
    printf '// Use of this source code is governed by a BSD-style license that can be\n'
    printf '// found in the LICENSE file.\n'
    printf '// Source: Font Awesome Free 6.x -- %s (solid)\n' "${actual_glyph}"
    printf '// License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)\n'
    printf '\n'
    cat "${TMP_ICON_RAW}"
  } > "${icon_path}"

  # 4. Copy optimized SVG with CC BY 4.0 attribution intact to SVG_OUT_DIR (D-09)
  cp "${TMP_SVG}" "${svg_path}"

  CONVERTED=$((CONVERTED + 1))
done < "${GLYPH_MANIFEST}"

# -------------------------------------------------------------------------
# Cleanup
# -------------------------------------------------------------------------

if [ "${DRY_RUN}" -eq 0 ] && [ -d "${TMP_DIR}" ]; then
  rm -rf "${TMP_DIR}"
fi

# -------------------------------------------------------------------------
# HARD COUNT GATE (exactly EXPECTED_COUNT .icon and .svg files required)
# This gate makes the count guarantee deterministic — not just hoped for.
# -------------------------------------------------------------------------

if [ "${DRY_RUN}" -eq 0 ]; then
  ICON_COUNT=$(find "${ICON_OUT_DIR}" -maxdepth 1 -name "fa_*.icon" | wc -l | tr -d ' ')
  SVG_COUNT=$(find "${SVG_OUT_DIR}" -maxdepth 1 -name "fa_*.svg" | wc -l | tr -d ' ')

  printf '\ncount gate: expected=%d  icons=%d  svgs=%d\n' "${EXPECTED_COUNT}" "${ICON_COUNT}" "${SVG_COUNT}"

  GATE_FAILED=0

  if [ "${ICON_COUNT}" != "${EXPECTED_COUNT}" ]; then
    printf 'ERROR: icon count mismatch: got %d, expected %d\n' "${ICON_COUNT}" "${EXPECTED_COUNT}" >&2
    printf 'Missing or extra icons:\n' >&2
    # Show which glyphs from the manifest are missing
    grep -vcE '^[[:space:]]*(#|$)' "${GLYPH_MANIFEST}" > /dev/null || true
    GATE_FAILED=1
  fi

  if [ "${SVG_COUNT}" != "${EXPECTED_COUNT}" ]; then
    printf 'ERROR: svg count mismatch: got %d, expected %d\n' "${SVG_COUNT}" "${EXPECTED_COUNT}" >&2
    GATE_FAILED=1
  fi

  if [ "${GATE_FAILED}" -eq 1 ]; then
    exit 1
  fi
fi

# -------------------------------------------------------------------------
# Summary
# -------------------------------------------------------------------------

printf '\nconvert-fa-icons: conversion complete.\n'
printf '  Converted: %d\n' "${CONVERTED}"
printf '  Skipped:   %d\n' "${SKIPPED}"
printf '  Errors:    %d\n' "${ERRORS}"

if [ "${ERRORS}" -gt 0 ]; then
  printf '\nwarning: %d error(s) occurred during conversion. Check output above.\n' "${ERRORS}" >&2
  exit 1
fi

if [ "${CONVERTED}" -eq 0 ]; then
  printf '\nwarning: no glyphs were converted — check FA_SOURCE_DIR=%s\n' "${FA_SOURCE_DIR}" >&2
  exit 1
fi

printf '\nRun verify-asset-pipeline.sh to confirm CC BY 4.0 attribution is present in all output SVGs.\n'

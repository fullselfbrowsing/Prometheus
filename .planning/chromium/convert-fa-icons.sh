#!/usr/bin/env bash
set -euo pipefail

# convert-fa-icons.sh — Font Awesome Free SVG to Chromium .icon conversion helper.
# Converts the curated FA Free subset (~69 glyphs) to gfx::VectorIcon .icon format
# for use in chrome/browser/resources/prometheus/vector_icons/, and copies
# optimized SVGs (with CC BY 4.0 attribution preserved) to
# chrome/browser/resources/prometheus/svg/.
#
# Design decisions implemented:
#  D-06: Full-parity icon set — both .icon (Views) and .svg (WebUI) per glyph.
#  D-07: Scripted, repeatable conversion; provenance header injected per .icon file.
#  D-08: Substitutions — arrow-down-to-line -> arrow-down; sidebar-flip placeholder.
#  D-12: CC BY 4.0 attribution comment preserved in every output SVG.
#
# Prerequisites (fail-fast checks at top):
#  - svgo: npm install -g svgo (SVG optimizer, CC BY 4.0 comment preservation)
#  - skiafy: see https://skia.googlesource.com/skia/+/refs/heads/main/tools/skiafy/
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
# Dependency checks
# -------------------------------------------------------------------------

command -v svgo >/dev/null 2>&1 \
  || fail "svgo not found — install with: npm install -g svgo (check https://www.npmjs.com/package/svgo)"

command -v skiafy >/dev/null 2>&1 \
  || fail "skiafy not found — see https://skia.googlesource.com/skia/+/refs/heads/main/tools/skiafy/ for installation instructions"

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
# D-08 substitution map:
#   arrow-down-to-line -> arrow-down (not in FA Free 6 solid)
#   sidebar-flip       -> hand-authored placeholder (Pro-only)
# -------------------------------------------------------------------------

declare -A SUBSTITUTIONS
SUBSTITUTIONS["arrow-down-to-line"]="arrow-down"

# Glyphs to skip (will generate a hand-authored placeholder instead)
PLACEHOLDER_GLYPHS="sidebar-flip"

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

  # Minimal placeholder SVG with CC BY 4.0 attribution (D-12)
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
}

# -------------------------------------------------------------------------
# Conversion loop
# -------------------------------------------------------------------------

CONVERTED=0
SKIPPED=0
ERRORS=0

for svg_source in "${FA_SOURCE_DIR}"/*.svg; do
  [ -f "${svg_source}" ] || continue

  glyph_name="$(basename "${svg_source}" .svg)"
  icon_name="fa_${glyph_name//-/_}.icon"
  svg_name="fa_${glyph_name//-/_}.svg"
  icon_path="${ICON_OUT_DIR}/${icon_name}"
  svg_path="${SVG_OUT_DIR}/${svg_name}"

  # --- D-08: Handle placeholder glyphs ---
  if echo "${PLACEHOLDER_GLYPHS}" | grep -qw "${glyph_name}"; then
    printf 'D-08: creating placeholder for %s (Pro-only, not in FA Free 6.x)\n' "${glyph_name}"
    if [ "${DRY_RUN}" -eq 0 ]; then
      write_sidebar_flip_placeholder "${icon_path}" "${svg_path}"
    else
      printf 'dry-run: would write placeholder %s and %s\n' "${icon_path}" "${svg_path}"
    fi
    CONVERTED=$((CONVERTED + 1))
    continue
  fi

  # --- D-08: Handle substitution map ---
  actual_source="${svg_source}"
  actual_glyph="${glyph_name}"

  if [ "${glyph_name}" = "arrow-down-to-line" ]; then
    # substitution: arrow-down-to-line is not in FA Free 6 solid
    printf 'D-08: substituting %s -> arrow-down (not in FA Free 6 solid)\n' "${glyph_name}"
    actual_source="${FA_SOURCE_DIR}/arrow-down.svg"
    actual_glyph="arrow-down"
    if [ ! -f "${actual_source}" ]; then
      printf 'warning: substitution source %s not found; skipping %s\n' "${actual_source}" "${glyph_name}" >&2
      SKIPPED=$((SKIPPED + 1))
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
  if ! svgo --config="${SVGO_CONFIG}" "${actual_source}" -o "${TMP_SVG}" 2>/dev/null; then
    printf 'warning: SVGO failed for %s; skipping\n' "${glyph_name}" >&2
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Verify CC BY 4.0 comment survived SVGO
  if ! grep -q "CC BY 4\.0\|Font Awesome Free" "${TMP_SVG}" 2>/dev/null; then
    printf 'warning: CC BY 4.0 attribution lost after SVGO for %s\n' "${glyph_name}" >&2
    # Inject attribution comment at the top of the SVG
    TMP_SVG_WITH_ATTR="${TMP_DIR}/${glyph_name}_attr.svg"
    {
      printf '<!--\n  Font Awesome Free 6.x -- %s (solid)\n  License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)\n-->\n' "${actual_glyph}"
      cat "${TMP_SVG}"
    } > "${TMP_SVG_WITH_ATTR}"
    mv "${TMP_SVG_WITH_ATTR}" "${TMP_SVG}"
  fi

  # 2. Convert to .icon path commands with skiafy
  if ! skiafy "${TMP_SVG}" -o "${TMP_ICON_RAW}" 2>/dev/null; then
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
done

# -------------------------------------------------------------------------
# Cleanup
# -------------------------------------------------------------------------

if [ "${DRY_RUN}" -eq 0 ] && [ -d "${TMP_DIR}" ]; then
  rm -rf "${TMP_DIR}"
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

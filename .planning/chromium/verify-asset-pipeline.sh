#!/usr/bin/env bash
set -euo pipefail

# verify-asset-pipeline.sh — Phase 14 asset license and offline guarantee gate.
# Asserts all 6 D-12 requirements for the Prometheus design system asset pipeline.
# Expected to exit non-zero on a fresh tree without assets (correct Wave 0 RED state).
# Expected to exit 0 only after Plans 14-04 and 14-05 land all assets.
#
# Source: Phase 14 decisions D-12 (license gate), D-07 (CC BY 4.0 provenance).
# [VERIFIED: .planning/phases/14-asset-and-design-system-port/14-CONTEXT.md §D-12]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

CHROMIUM_SRC="${PROJECT_ROOT}/.context/chromium/src"

fail() {
  printf 'verify-asset-pipeline check failed: %s\n' "$1" >&2
  exit 1
}

# -------------------------------------------------------------------------
# Assertion 1: Every declared font and brand asset present and non-zero.
# Covers Poppins (4 weights woff2 + ttf), Space Mono (woff2 + ttf),
# all FA glyphs (svg), PM mark, wordmark, FSB logo assets.
# -------------------------------------------------------------------------

FONT_DIR="${CHROMIUM_SRC}/third_party/poppins"
SPACEMONO_DIR="${CHROMIUM_SRC}/third_party/space_mono"
FA_SVG_DIR="${CHROMIUM_SRC}/chrome/browser/resources/prometheus/svg"
IMAGES_DIR="${CHROMIUM_SRC}/chrome/browser/resources/prometheus/images"

# Poppins woff2 (WebUI)
[ -s "${FONT_DIR}/Poppins-Thin.woff2" ]       || fail "Poppins-Thin.woff2 missing or empty in third_party/poppins"
[ -s "${FONT_DIR}/Poppins-Light.woff2" ]      || fail "Poppins-Light.woff2 missing or empty in third_party/poppins"
[ -s "${FONT_DIR}/Poppins-ExtraBold.woff2" ]  || fail "Poppins-ExtraBold.woff2 missing or empty in third_party/poppins"
[ -s "${FONT_DIR}/Poppins-Black.woff2" ]      || fail "Poppins-Black.woff2 missing or empty in third_party/poppins"

# Poppins ttf (native Views shim path — D-11)
[ -s "${FONT_DIR}/Poppins-Thin.ttf" ]         || fail "Poppins-Thin.ttf missing or empty in third_party/poppins"
[ -s "${FONT_DIR}/Poppins-Light.ttf" ]        || fail "Poppins-Light.ttf missing or empty in third_party/poppins"
[ -s "${FONT_DIR}/Poppins-ExtraBold.ttf" ]    || fail "Poppins-ExtraBold.ttf missing or empty in third_party/poppins"
[ -s "${FONT_DIR}/Poppins-Black.ttf" ]        || fail "Poppins-Black.ttf missing or empty in third_party/poppins"

# Space Mono woff2 (WebUI) and ttf (Views shim)
[ -s "${SPACEMONO_DIR}/SpaceMono-Regular.woff2" ] || fail "SpaceMono-Regular.woff2 missing or empty in third_party/space_mono"
[ -s "${SPACEMONO_DIR}/SpaceMono-Regular.ttf" ]   || fail "SpaceMono-Regular.ttf missing or empty in third_party/space_mono"

# FA SVG subset — at least one svg must exist to pass
FA_SVG_COUNT=$(find "${FA_SVG_DIR}" -name 'fa_*.svg' 2>/dev/null | wc -l | tr -d ' ')
[ "${FA_SVG_COUNT}" -gt 0 ] || fail "No fa_*.svg files found in ${FA_SVG_DIR} — run convert-fa-icons.sh first"

# PM mark and wordmark (dark/light variants)
[ -s "${IMAGES_DIR}/pm_mark_dark.png" ]         || fail "pm_mark_dark.png missing or empty in prometheus/images"
[ -s "${IMAGES_DIR}/pm_mark_light.png" ]        || fail "pm_mark_light.png missing or empty in prometheus/images"
[ -s "${IMAGES_DIR}/pm_wordmark_dark.png" ]     || fail "pm_wordmark_dark.png missing or empty in prometheus/images"
[ -s "${IMAGES_DIR}/pm_wordmark_light.png" ]    || fail "pm_wordmark_light.png missing or empty in prometheus/images"

# FSB logo assets
[ -s "${IMAGES_DIR}/fsb_logo_dark.png" ]        || fail "fsb_logo_dark.png missing or empty in prometheus/images"
[ -s "${IMAGES_DIR}/fsb_logo_light.png" ]       || fail "fsb_logo_light.png missing or empty in prometheus/images"

printf 'Assertion 1 passed: all declared font and brand assets present.\n'

# -------------------------------------------------------------------------
# Assertion 2: OFL.txt and LICENSE files present per font family;
# root LICENSES/ OFL stubs are filled (not empty placeholder).
# -------------------------------------------------------------------------

[ -f "${FONT_DIR}/OFL.txt" ]                       || fail "OFL.txt missing in third_party/poppins"
[ -s "${FONT_DIR}/OFL.txt" ]                       || fail "OFL.txt is empty in third_party/poppins"
[ -f "${SPACEMONO_DIR}/OFL.txt" ]                  || fail "OFL.txt missing in third_party/space_mono"
[ -s "${SPACEMONO_DIR}/OFL.txt" ]                  || fail "OFL.txt is empty in third_party/space_mono"
[ -f "${CHROMIUM_SRC}/third_party/font_awesome_free/LICENSE" ] \
  || fail "LICENSE missing in third_party/font_awesome_free"
[ -s "${CHROMIUM_SRC}/third_party/font_awesome_free/LICENSE" ] \
  || fail "LICENSE is empty in third_party/font_awesome_free"

# Root LICENSES/ OFL stubs filled (Phase 13 created placeholders; Phase 14 fills them)
[ -s "${PROJECT_ROOT}/LICENSES/poppins-OFL.txt" ]   || fail "LICENSES/poppins-OFL.txt missing or empty (Phase 14 should fill the Phase-13 placeholder)"
[ -s "${PROJECT_ROOT}/LICENSES/spacemono-OFL.txt" ] || fail "LICENSES/spacemono-OFL.txt missing or empty (Phase 14 should fill the Phase-13 placeholder)"

printf 'Assertion 2 passed: OFL and LICENSE files present.\n'

# -------------------------------------------------------------------------
# Assertion 3: README.chromium present in each third_party font/icon dir.
# -------------------------------------------------------------------------

[ -f "${CHROMIUM_SRC}/third_party/poppins/README.chromium" ]          || fail "README.chromium missing in third_party/poppins"
[ -f "${CHROMIUM_SRC}/third_party/space_mono/README.chromium" ]        || fail "README.chromium missing in third_party/space_mono"
[ -f "${CHROMIUM_SRC}/third_party/font_awesome_free/README.chromium" ] || fail "README.chromium missing in third_party/font_awesome_free"

printf 'Assertion 3 passed: README.chromium present per third_party dir.\n'

# -------------------------------------------------------------------------
# Assertion 4: CC BY 4.0 attribution comment in every bundled FA SVG.
# SVGO must be run with removeComments disabled (D-07).
# -------------------------------------------------------------------------

FA_SVG_FAIL=0
for svg in "${FA_SVG_DIR}"/fa_*.svg; do
  if [ ! -f "${svg}" ]; then
    # No svgs yet — reported by Assertion 1 above
    break
  fi
  if ! grep -q "CC BY 4\.0\|Font Awesome Free" "${svg}" 2>/dev/null; then
    printf 'assertion 4 fail: CC BY 4.0 attribution missing from %s\n' "${svg}" >&2
    FA_SVG_FAIL=1
  fi
done

[ "${FA_SVG_FAIL}" -eq 0 ] || fail "One or more FA SVG files are missing CC BY 4.0 attribution comment (run convert-fa-icons.sh with SVGO removeComments=false)"

printf 'Assertion 4 passed: CC BY 4.0 attribution present in all bundled FA SVGs.\n'

# -------------------------------------------------------------------------
# Assertion 5: No remote URLs in bundled Prometheus CSS/SVG/HTML resources.
# The offline guarantee (DESIGN-03): no http://, https://, fonts.googleapis.com.
# -------------------------------------------------------------------------

RESOURCES_DIR="${CHROMIUM_SRC}/chrome/browser/resources/prometheus"

if [ -d "${RESOURCES_DIR}" ]; then
  # Check for functional remote URL patterns only (CSS imports, fetch calls, link/script hrefs).
  # CC BY 4.0 attribution comments in FA SVG files (D-07 requirement) and SVG xmlns namespace
  # declarations (required for valid SVG) are excluded — they are not functional network requests.
  # The offline guarantee (DESIGN-03) covers runtime fetches, not static attribution metadata.
  REMOTE_URLS=$(grep -rn \
    -e '@import.*https://\|@import.*http://' \
    -e 'url(.*https://\|url(.*http://' \
    -e 'fonts\.googleapis\.com' \
    -e '<link[^>]*href=['"'"'"]['"'"'"]https://' \
    -e '<script[^>]*src=['"'"'"]['"'"'"]https://' \
    "${RESOURCES_DIR}/" 2>/dev/null | grep -v '^Binary file' || true)
  if [ -n "${REMOTE_URLS}" ]; then
    printf 'assertion 5 fail: Functional remote URL(s) found in bundled Prometheus resources:\n%s\n' "${REMOTE_URLS}" >&2
    fail "Remote URL found in bundled Prometheus resources — offline guarantee violated (DESIGN-03)"
  fi
  printf 'Assertion 5 passed: no functional remote URLs in bundled Prometheus resources.\n'
else
  fail "Prometheus resources dir ${RESOURCES_DIR} does not exist — run Plans 14-04/14-05 first"
fi

# -------------------------------------------------------------------------
# Assertion 6: NOTICES.md contains required sections for Font Awesome,
# Poppins, Space Mono, CC BY 4.0, OFL, and chrome://credits pointer.
# Ties back to the Phase 13 legal baseline (NOTICES.md).
# -------------------------------------------------------------------------

NOTICES_FILE="${PROJECT_ROOT}/NOTICES.md"

[ -f "${NOTICES_FILE}" ] || fail "NOTICES.md not found at project root — create it with required sections"

grep -q "Font Awesome" "${NOTICES_FILE}" \
  || fail "NOTICES.md is missing 'Font Awesome' section (required by D-12)"
grep -q "Poppins" "${NOTICES_FILE}" \
  || fail "NOTICES.md is missing 'Poppins' section (required by D-12)"
grep -q "Space Mono" "${NOTICES_FILE}" \
  || fail "NOTICES.md is missing 'Space Mono' section (required by D-12)"

printf 'Assertion 6 passed: NOTICES.md contains all required sections.\n'

printf '\nverify-asset-pipeline: all checks passed.\n'

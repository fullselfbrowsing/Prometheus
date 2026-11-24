# Phase 13: Product Identity, Branding, and Legal Baseline — Pattern Map

**Mapped:** 2026-06-23
**Files analyzed:** 9 new/modified files
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.context/chromium/src/chrome/app/theme/chromium/BRANDING` | config | transform | `.context/chromium/src/chrome/app/theme/chromium/BRANDING` (read-only baseline; in-place patch) | exact |
| `.context/chromium/src/chrome/app/chromium_strings.grd` | config | transform | `.context/chromium/src/chrome/app/chromium_strings.grd` (read-only baseline; in-place patch) | exact |
| `.context/chromium-patches/phase-13-branding/*.patch` | config | file-I/O | `.context/falkon-preservation/patches/*.patch` patch file convention | role-match |
| `.planning/chromium/smoke-launch-prometheus.sh` | utility | request-response | `.planning/chromium/smoke-launch-unmodified.sh` | exact |
| `.planning/chromium/check-falkon-gpl-guard.sh` | utility | batch, file-I/O | `.planning/chromium/verify-artifact-isolation.sh` + `check-chromium-env.sh` | role-match |
| `NOTICES.md` | config | file-I/O | `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` legal sections; v1 `legal-notice-inventory.md` | role-match |
| `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` | config | transform | `.planning/chromium/CHROMIUM-CHECKOUT.md`; v1 `product-identity-inventory.md` | role-match |
| `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` | config | transform | `.planning/chromium/CHROMIUM-CHECKOUT.md`; v1 `legal-notice-inventory.md` | role-match |
| `README.md` | config | transform | `README.md` (update existing, lines 44-48 and related Falkon/QtWebEngine references) | exact |

---

## Pattern Assignments

### `.context/chromium/src/chrome/app/theme/chromium/BRANDING` (config, transform)

**Analog:** Same file — in-place edit tracked as a git format-patch. Edit inside `.context/chromium/src` on branch `prometheus/phase-13-branding`.

**Current upstream content** (lines 1-11, direct read — this is the baseline to diff against):
```text
COMPANY_FULLNAME=The Chromium Authors
COMPANY_SHORTNAME=The Chromium Authors
PRODUCT_FULLNAME=Chromium
PRODUCT_SHORTNAME=Chromium
PRODUCT_INSTALLER_FULLNAME=Chromium Installer
PRODUCT_INSTALLER_SHORTNAME=Chromium Installer
COPYRIGHT=Copyright @LASTCHANGE_YEAR@ The Chromium Authors. All rights reserved.
MAC_BUNDLE_ID=org.chromium.Chromium
MAC_CREATOR_CODE=Cr24
MAC_TEAM_ID=
```

**Prometheus override (full file replacement)**:
```text
COMPANY_FULLNAME=Full Self Browsing
COMPANY_SHORTNAME=FSB
PRODUCT_FULLNAME=Prometheus
PRODUCT_SHORTNAME=Prometheus
PRODUCT_INSTALLER_FULLNAME=Prometheus Installer
PRODUCT_INSTALLER_SHORTNAME=Prometheus Installer
COPYRIGHT=Copyright 2024-2026 Full Self Browsing. Powered by Chromium.
MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus
MAC_CREATOR_CODE=Cr24
MAC_TEAM_ID=
```

**Critical post-edit sequence:** After editing BRANDING, always run `gn gen out/Default --args='is_debug=false is_component_build=true symbol_level=0'` before `autoninja`. The `exec_script` call in `build/util/branding.gni` only re-runs at GN gen time. Missing `gn gen` after a BRANDING edit builds with the old cached values and `Chromium.app` persists instead of `Prometheus.app`.

**Do NOT change:** `MAC_CREATOR_CODE` (leave as `Cr24`). Do NOT set `MAC_TEAM_ID` yet (Phase 24). Do NOT create a new `chrome/app/theme/prometheus/` directory — edit the `chromium/` tree in place.

---

### `.context/chromium/src/chrome/app/chromium_strings.grd` (config, transform)

**Analog:** Same file — in-place patch. Processed by the `branded_strings` grit target for non-Chrome-branded builds.

**Minimum viable IDS_* overrides — current values and exact line numbers** (verified by direct read):

| Message ID | Line | Current value | Override |
|-----------|------|---------------|----------|
| `IDS_PRODUCT_NAME` | 296-298 | `Chromium` | `Prometheus` |
| `IDS_SHORT_PRODUCT_NAME` | 299-301 | `Chromium` | `Prometheus` |
| `IDS_FIRST_RUN_DIALOG_WINDOW_TITLE` | 319-321 | `Welcome to Chromium` | `Welcome to Prometheus` (dead code for non-GOOGLE_CHROME_BRANDING, but patch for correctness) |
| `IDS_BROWSER_WINDOW_TITLE_FORMAT` (not chromeos, not macos) | 445-447 | `$1 - Chromium` | `$1 - Prometheus` |
| `IDS_ABOUT_VERSION_COMPANY_NAME` (else branch) | 508-510 | `The Chromium Authors` | `Full Self Browsing` |
| `IDS_ABOUT_VERSION_COPYRIGHT` (else branch) | 511-513 | `Copyright {0,date,y} The Chromium Authors. All rights reserved.` | `Copyright <ph name="YEAR">{0,date,y}<ex>2026</ex></ph> Full Self Browsing. Powered by Chromium — see chrome://credits for attributions.` |
| `IDS_ABOUT` (use_titlecase, not chromeos, else branch) | 1082-1084 | `About &amp;Chromium` | `About &amp;Prometheus` |
| `IDS_ABOUT` (not use_titlecase, not chromeos, else branch) | 1099-1101 | `About &amp;Chromium` | `About &amp;Prometheus` |
| `IDS_APP_MENU_PRODUCT_NAME` (macos) | 1118-1120 | `Chromium` | `Prometheus` |
| `IDS_HELPER_NAME` (macos) | 1121-1123 | `Chromium Helper` | `Prometheus Helper` |
| `IDS_SHORT_HELPER_NAME` (macos) | 1124-1126 | `Chromium Helper` | `Prometheus Helper` |

**GRD conditional guard rule:** `IDS_ABOUT` appears at lines 1082, 1099, and 1109. The macOS build uses `use_titlecase=true` on macOS. Patch BOTH the `use_titlecase` branch (line 1082) AND the `not use_titlecase` branch (line 1099) to prevent the app menu showing "About Chromium" in either configuration. The ChromeOS branch (line 1109) is irrelevant for this target platform.

**Patch excerpt — product name block** (lines 295-301, current XML):
```xml
        <else>
          <message name="IDS_PRODUCT_NAME" desc="The Chrome application name" translateable="false">
            Chromium
          </message>
          <message name="IDS_SHORT_PRODUCT_NAME" desc="The Chrome application short name." translateable="false">
            Chromium
          </message>
        </else>
```

**Patch excerpt — macOS menu block** (lines 1117-1127, current XML):
```xml
      <if expr="is_macosx">
        <message name="IDS_APP_MENU_PRODUCT_NAME" desc="The application's short name, used for the Mac's application menu, activity monitor, etc. This should be less than 16 characters. Example: Chrome, not Google Chrome." translateable="false">
          Chromium
        </message>
        <message name="IDS_HELPER_NAME" desc="The helper application's name.  Should contain the Chrome application name (IDS_PRODUCT_NAME). Example: Google Chrome Helper.">
          Chromium Helper
        </message>
        <message name="IDS_SHORT_HELPER_NAME" desc="The helper application's short name, used for the Mac's application menu, activity monitor, etc. Example: Chrome Helper, not Google Chrome Helper.">
          Chromium Helper
        </message>
      </if>
```

**Do NOT change in this phase:** Any `chrome://welcome` WebUI strings, `IDS_PRODUCT_DESCRIPTION` (Windows only), `IDS_RELAUNCH_TO_UPDATE`, or any `_is_chrome_for_testing_branded` then-branches.

---

### `.context/chromium-patches/phase-13-branding/*.patch` (config, file-I/O)

**Analog:** `.context/falkon-preservation/patches/*.patch` — the 81-file Phase 1-10 Falkon patch series that established the naming and export convention.

**Patch naming convention** (from preservation patches directory listing):
```
0001-branding-BRANDING-file-override.patch
0002-branding-chromium-strings-grd-product-name.patch
0003-branding-prometheus-notices-third-party-dir.patch  (optional, if Option B chosen)
```

**Export command pattern** (from `.planning/chromium/CHROMIUM-CHECKOUT.md` lines 290-294):
```sh
# Run inside .context/chromium/src after commits on named branch
git format-patch 0e8499df5172f55d0d29e2b92ef7e6a704529578..HEAD \
  -o ../../../../.context/chromium-patches/phase-13-branding
```

**Branch creation pattern** (from CHROMIUM-CHECKOUT.md line 286):
```sh
# Run inside .context/chromium/src
git new-branch prometheus/phase-13-branding
```

**Do NOT commit the Chromium source to root git.** `.context/` is ignored. Patch files under `.context/chromium-patches/` are also ignored by root git and referenced only from tracked planning docs.

---

### `.planning/chromium/smoke-launch-prometheus.sh` (utility, request-response)

**Analog:** `.planning/chromium/smoke-launch-unmodified.sh` — exact role, same data flow. The new script adapts only the binary path and evidence key names.

**Shebang + set -euo pipefail** (lines 1-2 of analog):
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Source block comment + phase reference** (lines 4-7 of analog):
```bash
# Prometheus Chromium Baseline Smoke — unmodified launch gate.
# Source: Phase 12 decisions and Chromium Mac launch docs.
# [VERIFIED: .planning/phases/12-chromium-checkout-build-and-patch-discipline/12-CONTEXT.md]
# [CITED: https://chromium.googlesource.com/chromium/src/+/main/docs/mac_build_instructions.md]
```

**PROJECT_ROOT resolution pattern** (lines 17-19 of analog):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"
```

**Path constants block** (lines 21-27 of analog — change CHROMIUM_BIN for Phase 13):
```bash
DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_ROOT="${PROJECT_ROOT}/.context/chromium"
CHROMIUM_SRC="${CHROMIUM_ROOT}/src"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"
# Phase 13 change: Prometheus.app replaces Chromium.app after BRANDING rebuild
PROMETHEUS_BIN="${BUILD_DIR}/Prometheus.app/Contents/MacOS/Prometheus"
STATUS_FILE="${PROJECT_ROOT}/.context/prometheus-launch.status"
LOG_FILE="${PROJECT_ROOT}/.context/prometheus-launch.log"
```

**PATH + DEVELOPER_DIR exports** (lines 33-34 of analog):
```bash
export PATH="${DEPOT_TOOLS}:${PATH}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
```

**fail() helper pattern** (lines 60-63 of analog):
```bash
fail() {
  printf 'prometheus launch smoke failed: %s\n' "$1" >&2
  exit 1
}
```

**Preflight call pattern** (line 99 of analog):
```bash
bash "${PROJECT_ROOT}/.planning/chromium/check-chromium-env.sh"
```

**Evidence status file pattern** (lines 302-324 of analog — key-value pairs written to STATUS_FILE):
```bash
{
  printf 'chromium_revision=%s\n'     "${chromium_revision}"
  printf 'gn_args=%s\n'               "${gn_args}"
  printf 'status=%s\n'               "${final_status}"
  printf 'log_file=%s\n'             "${LOG_FILE}"
  if [ "${final_status}" -eq 0 ]; then
    printf 'patches_blocked=false\n'
  else
    printf 'patches_blocked=true\n'
  fi
} > "${STATUS_FILE}"
```

**Artifact isolation gate at end** (line 341 of analog):
```bash
bash "${PROJECT_ROOT}/.planning/chromium/verify-artifact-isolation.sh"

printf 'Prometheus launch smoke passed.\n'
```

**Phase 13 identity verification additions** (new, insert after artifact isolation gate):
```bash
# Identity assertions (BRAND-01, BRAND-06)
PLIST="${BUILD_DIR}/Prometheus.app/Contents/Info.plist"
[ -f "${PLIST}" ] || fail "Info.plist not found at ${PLIST}; rebuild after BRANDING patch"
plutil -p "${PLIST}" | grep -q 'Prometheus' \
  || fail "CFBundleName does not contain 'Prometheus' in ${PLIST}"
plutil -p "${PLIST}" | grep -q 'com.fullselfbrowsing.prometheus' \
  || fail "CFBundleIdentifier is not 'com.fullselfbrowsing.prometheus' in ${PLIST}"
```

**Key divergences from `smoke-launch-unmodified.sh`:**
- `CHROMIUM_BIN` → `PROMETHEUS_BIN` pointing to `Prometheus.app/Contents/MacOS/Prometheus`
- Status file: `.context/prometheus-launch.status` (not `chromium-launch.status`)
- Log file: `.context/prometheus-launch.log`
- osascript quit uses bundle ID `com.fullselfbrowsing.prometheus` (not `org.chromium.Chromium`) and app name `Prometheus` (not `Chromium`)
- Adds post-launch `plutil` identity assertions for BRAND-01 and BRAND-06
- Keep `--with-dial-workaround` flag (same macOS DIAL permission noise risk exists for Prometheus.app)

---

### `.planning/chromium/check-falkon-gpl-guard.sh` (utility, batch/file-I/O)

**Analog:** `.planning/chromium/verify-artifact-isolation.sh` — same role (static guard/gate script), same data flow (batch grep over filesystem, exit nonzero on failure). Also mirrors `check-chromium-env.sh` for overall structure.

**Shebang + set pattern** (line 1-2 of `verify-artifact-isolation.sh`):
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Source comment pattern** (lines 4-6 of `verify-artifact-isolation.sh`):
```bash
# Source: Phase 12 patch-discipline decisions and root git artifact isolation.
# [VERIFIED: .planning/phases/12-chromium-checkout-build-and-patch-discipline/12-CONTEXT.md]
```

**PROJECT_ROOT resolution** (lines 8-10 of `verify-artifact-isolation.sh`):
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"
```

**fail() helper** (lines 11-14 of `verify-artifact-isolation.sh`):
```bash
fail() {
  printf 'chromium artifact isolation check failed: %s\n' "$1" >&2
  exit 1
}
```

**Grep pattern check idiom** (lines 20-27 of `verify-artifact-isolation.sh` — use same `-q` + `|| fail` idiom for GPL guard):
```bash
grep -qF '/.context/' .gitignore || fail ".gitignore is missing required policy line: /.context/"
```

**GPL guard core logic pattern** (from RESEARCH.md GPL guard sketch — adapt with PROJECT_ROOT):
```bash
SRC="${PROJECT_ROOT}/.context/chromium/src"

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

FOUND=0
for pat in "${GPL_PATTERNS[@]}"; do
  hits=$(grep -rn --include="*.cc" --include="*.h" --include="*.mm" \
         -E "$pat" \
         "${SRC}/chrome/browser/prometheus" \
         "${SRC}/components/prometheus" 2>/dev/null || true)
  if [[ -n "${hits}" ]]; then
    printf 'GPL GUARD FAIL: Pattern %s found:\n%s\n' "${pat}" "${hits}" >&2
    FOUND=1
  fi
done

if [[ "${FOUND}" -ne 0 ]]; then
  fail "GPL Falkon signatures detected. Do not copy GPL source into Chromium without license review."
fi
printf 'GPL guard: clean — no Falkon GPL signatures in Prometheus Chromium directories.\n'
```

**Scope rule:** Guard scans only `chrome/browser/prometheus` and `components/prometheus` — Prometheus-owned directories that do not yet exist (guard is safe/pass before Phase 13 adds any). Avoid scanning the full Chromium tree to prevent false positives from unrelated third-party code that may coincidentally use similar patterns.

**Success string convention** (final printf from all Phase 12 scripts — match exactly):
```bash
printf 'GPL guard: clean — no Falkon GPL signatures in Prometheus Chromium directories.\n'
```

---

### `NOTICES.md` (config, file-I/O)

**Analog:** `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` legal sections (lines 70-80 for the licensing boundary) + v1 `legal-notice-inventory.md` structure (recovered from `.context/falkon-preservation/patches/0081-style-ui-standardize-Prometheus-native-chrome.patch` lines 4148-4202).

**v1 legal-notice-inventory section structure to mirror**:
```markdown
# Legal Notice Inventory

**Phase:** 1 - Baseline and Legal Inventory
**Captured:** 2026-06-16
**Scope:** Inherited legal and license notice surfaces...

## Required Preservation Rule
...text of rule...

## Source-Level License Files
| File | Current role | Preservation requirement |
|------|--------------|--------------------------|
...rows...

## In-App Legal/About Surfaces
...table...

## Packaging And Metadata Surfaces
...table...

## Release Obligations To Carry Forward
...bullets...

## Verification Commands
...code block...
```

**NOTICES.md content pattern for Phase 13** (from RESEARCH.md lines 492-518):
```markdown
# Prometheus Notices

Prometheus is built on Chromium. See chrome://credits for Chromium and
third-party open source notices.

## Font Awesome Free
Font Awesome Free 6.x — https://fontawesome.com
Icons: CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
Fonts: SIL OFL 1.1 — https://scripts.sil.org/OFL
Code: MIT — https://opensource.org/licenses/MIT
Attribution comments are preserved in each bundled SVG file.

## Poppins
Poppins — https://github.com/itfoundry/poppins
License: SIL Open Font License 1.1 — see LICENSES/poppins-OFL.txt

## Space Mono
Space Mono — https://github.com/googlefonts/spacemono
License: SIL Open Font License 1.1 — see LICENSES/spacemono-OFL.txt

## FSB-Owned Material
Product identity, FSB brand marks, PM monogram, and Prometheus wordmark
are owned by Full Self Browsing. All rights reserved.

Powered by FSB — https://fullselfbrowsing.com
```

**Validation grep commands** (from RESEARCH.md validation architecture lines 632-634):
```bash
grep -q "Powered by FSB" NOTICES.md
grep -q "Font Awesome" NOTICES.md && grep -q "Poppins" NOTICES.md && grep -q "Space Mono" NOTICES.md
grep -q "Powered by Chromium" NOTICES.md
```

---

### `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` (config, transform)

**Primary analog:** `.planning/chromium/CHROMIUM-CHECKOUT.md` — canonical planning doc in the same directory; establishes heading style, table conventions, code block evidence blocks, and cross-reference links.

**Secondary analog:** v1 `product-identity-inventory.md` structure (recovered from `.context/falkon-preservation/patches/0081-style-ui-standardize-Prometheus-native-chrome.patch` lines 4393-4439).

**CHROMIUM-CHECKOUT.md header pattern** (lines 1-8):
```markdown
# Chromium Checkout Handoff

**Created:** 2026-06-17
**Updated:** 2026-06-24
**Milestone:** v2.0 Chromium Engine Migration
**Status:** Phase 12 complete. ...
```

**CHROMIUM-CHECKOUT.md table convention** (lines 25-32):
```markdown
| Item | Path |
|------|------|
| depot_tools | `.context/depot_tools` |
| Chromium source | `.context/chromium/src` |
```

**v1 product-identity-inventory.md section structure**:
```markdown
# Product Identity Inventory

**Phase:** 1 - Baseline and Legal Inventory
**Captured:** 2026-06-16
**Scope:** Product-visible Falkon/KDE/Qt identity surfaces...

## High-Priority Rebrand Targets
| Surface | Current identifiers | Notes |
|---------|---------------------|-------|
| `falkon/src/main/Info.plist` | `org.kde.falkon`, `Falkon` | macOS bundle identifier... |
...

## Medium-Priority Rebrand Targets
...table...

## Legal-Attribution-Sensitive Surfaces
...list...

## Phase 2 Notes
...bullets...
```

**Phase 13 adaptation — PRODUCT-IDENTITY-INVENTORY.md must include:**

Per CONTEXT.md decisions (Area 4):

```markdown
# Chromium Product Identity Inventory

**Phase:** 13 - Product Identity, Branding, and Legal Baseline
**Captured:** [date]
**Scope:** Chromium-era product-visible identity surfaces — records both upstream Chromium value
and Prometheus override per surface so rebases can detect identity drift.

## BRANDING File Fields
| Field | Upstream (Chromium) value | Prometheus override | Notes |
|-------|--------------------------|---------------------|-------|
| `PRODUCT_FULLNAME` | `Chromium` | `Prometheus` | Drives .app dir name, binary name, Info.plist EXECUTABLE_NAME |
| `MAC_BUNDLE_ID` | `org.chromium.Chromium` | `com.fullselfbrowsing.prometheus` | Profile directory root; must not collide with installed Chromium |
...

## GRD String Overrides
| IDS_ key | Upstream value | Prometheus override | Where visible |
|----------|---------------|---------------------|---------------|
| `IDS_PRODUCT_NAME` | `Chromium` | `Prometheus` | Window title, accessibility, pak |
...

## Info.plist Identity Fields (post-build)
...

## Surfaces Intentionally Preserved as "Chromium"
| Surface | Reason |
|---------|--------|
| `about:version` upstream attribution | BRAND-03 legal attribution |
| `chrome://credits` | Required third-party notices |
...

## Rebase Drift Detection
...commands to verify identity after gclient sync / rebase...
```

---

### `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` (config, transform)

**Analog:** v1 `legal-notice-inventory.md` (recovered from patch 0081, lines 4148-4202) + `.planning/chromium/CHROMIUM-CHECKOUT.md` for doc conventions.

**v1 legal-notice-inventory.md full structure** (direct from patch):
```markdown
# Legal Notice Inventory

**Phase:** 1 - Baseline and Legal Inventory
**Captured:** 2026-06-16
**Scope:** Inherited legal and license notice surfaces...

## Required Preservation Rule
Rebrand work may replace product-visible Falkon/KDE identity, but it must not delete
required GPL, Qt, KDE, Falkon, theme, third-party, or source-availability notices.
If a notice is removed from a marketing surface, it must remain available in source
and in an appropriate legal/about surface.

## Source-Level License Files
| File | Current role | Preservation requirement |
|------|--------------|--------------------------|
| `falkon/COPYING` | Top-level GPL license text | Must remain in source distributions |
...

## In-App Legal/About Surfaces
...table with aboutdialog, licenseviewer...

## Packaging And Metadata Surfaces
...table...

## Release Obligations To Carry Forward
- Keep GPL license text available with source and binary distributions.
...

## Verification Commands
...code block...
```

**Phase 13 adaptation — LEGAL-NOTICE-INVENTORY.md must include:**
```markdown
# Chromium Legal Notice Inventory

**Phase:** 13 - Product Identity, Branding, and Legal Baseline
**Captured:** [date]
**Scope:** Chromium-era legal notice surfaces — what exists, what was authored, and
what must ship with release artifacts.

## Required Preservation Rule
...adapted from v1: replace "GPL Falkon/KDE" with "Chromium BSD + third-party"...

## Source-Level Notice Files (this repo)
| File | Role | Status |
|------|------|--------|
| `NOTICES.md` | Prometheus-owned notices (Font Awesome, Poppins, Space Mono, FSB) | Authored Phase 13 |
...

## Chromium In-Tree Legal Surfaces
| Surface | Role | Phase 13 action |
|---------|------|-----------------|
| `chrome://credits` | Chromium + third-party licenses | Preserved as-is (sample page until Phase 24 wires generate_about_credits) |
| `about:version` | Attribution and copyright | `IDS_ABOUT_VERSION_COMPANY_NAME` patched to "Full Self Browsing"; `IDS_ABOUT_VERSION_COPYRIGHT` includes Chromium attribution |
...

## Third-Party Assets (Prometheus-owned)
| Asset | License | Notice file |
|-------|---------|-------------|
| Font Awesome Free 6.x | CC BY 4.0 (icons) + OFL 1.1 (fonts) + MIT (code) | Attribution in NOTICES.md + comments in bundled SVGs |
| Poppins | OFL 1.1 | NOTICES.md |
| Space Mono | OFL 1.1 | NOTICES.md |

## Release Obligations
- NOTICES.md must be included in any release artifact (Phase 24 validates).
- `chrome://credits` must be reachable in the built browser (satisfied by Chromium default).
- "Powered by Chromium" attribution must appear in legal surfaces.
- Font Awesome SVG comments must not be stripped.

## Verification Commands
...grep commands against NOTICES.md and built plist...
```

---

### `README.md` (config, transform)

**Analog:** `README.md` itself — update existing file, do not replace. Pattern is update-in-place following the same centered header + badge style already established.

**Lines requiring update for BRAND-07** (from grep of current README.md):

Line 44 (current):
```markdown
Prometheus is migrating to a Chromium-based agent-native desktop browser; v1.0 was proven on a Falkon/QtWebEngine bootstrap and Falkon is now a preserved reference, not the production base. It brings Full Self Browsing's DOM first automation into the browser itself...
```

Line 48 (current):
```markdown
> **Status:** v1.0 shipped as a Falkon/QtWebEngine bootstrap and is preserved for reference. Active work is the v2.0 Chromium migration: rebuild the same product, MCP, runtime, supervision, and design contracts on Chromium-native primitives while keeping Falkon source reference-only.
```

**Target wording per CONTEXT.md BRAND-07:** "Chromium-based agent-native browser" must appear in the README description. The exact phrase `Chromium-based agent-native browser` is the BRAND-07 compliance anchor.

**Validation command** (from RESEARCH.md line 638):
```bash
grep -q "Chromium-based agent-native browser" README.md
```

**Do NOT remove:** Falkon attribution text (lines 192-198, 216, 228-230) — these are historical/legal context, not product marketing claims, and BRAND-03 permits attribution where required.

---

## Shared Patterns

### Bash Gate Script Structure
**Source:** `.planning/chromium/check-chromium-env.sh` and `.planning/chromium/verify-artifact-isolation.sh`
**Apply to:** `smoke-launch-prometheus.sh`, `check-falkon-gpl-guard.sh`

Every bash gate script in `.planning/chromium/` shares this exact skeleton:

```bash
#!/usr/bin/env bash
set -euo pipefail

# [One-line description of what this gate checks.]
# Source: [Phase decision reference]
# [VERIFIED: path/to/CONTEXT.md or inline evidence]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

DEPOT_TOOLS="${PROJECT_ROOT}/.context/depot_tools"
CHROMIUM_SRC="${PROJECT_ROOT}/.context/chromium/src"
BUILD_DIR="${CHROMIUM_SRC}/out/Default"

export PATH="${DEPOT_TOOLS}:${PATH}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

fail() {
  printf '[script-name] failed: %s\n' "$1" >&2
  exit 1
}

# ... guard logic using "|| fail" idiom ...

printf '[Script-name] passed.\n'
```

Rules:
- `set -euo pipefail` always on line 2, no exceptions.
- `fail()` uses `printf` not `echo`, writes to stderr, exits 1.
- `PROJECT_ROOT` resolved via `SCRIPT_DIR/../..` — never hardcoded.
- Final success line always uses `printf` with a period.
- Evidence written to `.context/*.status` and `.context/*.log` (both paths are covered by `.gitignore`).

### Evidence Status File Pattern
**Source:** `.planning/chromium/smoke-launch-unmodified.sh` lines 302-324, `build-chromium-baseline.sh` lines 120-132
**Apply to:** `smoke-launch-prometheus.sh`

All evidence status files use key=value format, one per line, written to `.context/`:

```bash
{
  printf 'chromium_revision=%s\n'  "${chromium_revision}"
  printf 'gn_args=%s\n'            "${gn_args}"
  printf 'status=%s\n'            "${final_status}"
  printf 'log_file=%s\n'          "${LOG_FILE}"
  printf 'patches_blocked=%s\n'   "$([ "${final_status}" -eq 0 ] && echo false || echo true)"
} > "${STATUS_FILE}"
```

### Bounded Log Evidence Pattern
**Source:** `.planning/chromium/build-chromium-baseline.sh` lines 96-109
**Apply to:** `smoke-launch-prometheus.sh` (already uses this via append to LOG_FILE)

Large command output is bounded to first 80 + last 200 lines to keep `.context/*.log` files manageable:
```bash
{
  head -n 80 "${FULL_LOG_TMP}" 2>/dev/null || true
  printf '\n--- last 200 lines ---\n'
  tail -n 200 "${FULL_LOG_TMP}" 2>/dev/null || true
} > "${LOG_FILE}"
```

### Chromium Identity Facts (Locked)
**Source:** CONTEXT.md code_context section; BRANDING file direct read
**Apply to:** All scripts and docs in this phase

These values are locked and must be used verbatim:
- Bundle ID: `com.fullselfbrowsing.prometheus` (exact)
- Product name: `Prometheus` (exact, no "The Prometheus" or "Prometheus Browser")
- Affiliation tagline: `Powered by FSB` (exact, verbatim)
- App binary path after rebuild: `.context/chromium/src/out/Default/Prometheus.app/Contents/MacOS/Prometheus`
- Chromium baseline revision: `0e8499df5172f55d0d29e2b92ef7e6a704529578`

### Planning Doc Header Convention
**Source:** `.planning/chromium/CHROMIUM-CHECKOUT.md` lines 1-8
**Apply to:** `PRODUCT-IDENTITY-INVENTORY.md`, `LEGAL-NOTICE-INVENTORY.md`

```markdown
# [Title]

**Created:** [date]
**Milestone:** v2.0 Chromium Engine Migration
**Status:** [current status sentence]
```

Use bold field labels, ISO date format, no hyphens in prose (per house style).

---

## No Analog Found

All Phase 13 files have close analogs in this repo. No files require falling back to RESEARCH.md code examples as a primary pattern — all patterns are grounded in actual repo files.

| File | Status |
|------|--------|
| `.context/chromium-patches/phase-13-branding/` | Directory only; naming convention from preservation patches |
| `NOTICES.md` | Content from RESEARCH.md outline + v1 legal-notice-inventory structure; no existing Chromium-era NOTICES file to copy from |

---

## Metadata

**Analog search scope:** `.planning/chromium/`, `.context/falkon-preservation/patches/0081-*.patch`, `.context/chromium/src/chrome/app/theme/chromium/BRANDING`, `.context/chromium/src/chrome/app/chromium_strings.grd`, `README.md`, `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`
**Files read:** 14
**Pattern extraction date:** 2026-06-23

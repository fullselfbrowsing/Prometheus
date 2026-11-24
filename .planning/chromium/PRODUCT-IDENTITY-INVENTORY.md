# Chromium Product Identity Inventory

**Created:** 2026-06-24
**Milestone:** v2.0 Chromium Engine Migration
**Status:** Phase 13 complete — branding patches applied. Records upstream Chromium values
and Prometheus overrides per surface so rebases can detect identity drift.

---

## BRANDING File Fields

Source: `.context/chromium/src/chrome/app/theme/chromium/BRANDING`

| Field | Upstream (Chromium) value | Prometheus override | Notes |
|-------|--------------------------|---------------------|-------|
| `COMPANY_FULLNAME` | `The Chromium Authors` | `Full Self Browsing` | Legal entity displayed in about surfaces |
| `COMPANY_SHORTNAME` | `The Chromium Authors` | `FSB` | Short form used internally |
| `PRODUCT_FULLNAME` | `Chromium` | `Prometheus` | Drives .app directory name, binary name, Info.plist EXECUTABLE\_NAME |
| `PRODUCT_SHORTNAME` | `Chromium` | `Prometheus` | Short display name; maps to CFBundleName via CHROMIUM\_SHORT\_NAME |
| `PRODUCT_INSTALLER_FULLNAME` | `Chromium Installer` | `Prometheus Installer` | Installer package name |
| `PRODUCT_INSTALLER_SHORTNAME` | `Chromium Installer` | `Prometheus Installer` | Short installer name |
| `COPYRIGHT` | `Copyright @LASTCHANGE_YEAR@ The Chromium Authors. All rights reserved.` | `Copyright 2024-2026 Full Self Browsing. Powered by Chromium.` | Dual attribution required by BRAND-03 and BRAND-04 |
| `MAC_BUNDLE_ID` | `org.chromium.Chromium` | `com.fullselfbrowsing.prometheus` | macOS bundle identifier; profile root at `~/Library/Application Support/com.fullselfbrowsing.prometheus/`; must not collide with installed Chromium |
| `MAC_CREATOR_CODE` | `Cr24` | `Cr24` (preserved) | Four-character macOS creator code; intentionally unchanged |
| `MAC_TEAM_ID` | (empty) | (empty — deferred to Phase 24) | Apple Developer Team ID for notarization |

**Critical build note:** Changing BRANDING requires re-running `gn gen out/Default` before
`autoninja`. The `exec_script` call in `build/util/branding.gni` only re-runs at GN generation
time. Missing `gn gen` after a BRANDING edit builds with stale cached values and `Chromium.app`
persists instead of `Prometheus.app`.

---

## GRD String Overrides

Source: `.context/chromium/src/chrome/app/chromium_strings.grd` (branded\_strings grit target)

| IDS\_ key | Upstream value | Prometheus override | Where visible | Conditional |
|-----------|---------------|---------------------|---------------|-------------|
| `IDS_PRODUCT_NAME` | `Chromium` | `Prometheus` | Window title, accessibility, pak strings | `<else>` branch (non-Chrome-branded) |
| `IDS_SHORT_PRODUCT_NAME` | `Chromium` | `Prometheus` | Short display references in UI | `<else>` branch |
| `IDS_FIRST_RUN_DIALOG_WINDOW_TITLE` | `Welcome to Chromium` | `Welcome to Prometheus` | First-run dialog window title | macOS/Linux; dead code for non-GOOGLE\_CHROME\_BRANDING builds but patched for correctness |
| `IDS_BROWSER_WINDOW_TITLE_FORMAT` | `$1 - Chromium` | `$1 - Prometheus` | All browser window title bars | not chromeos, not macos branch |
| `IDS_ABOUT_VERSION_COMPANY_NAME` | `The Chromium Authors` | `Full Self Browsing` | About version page company line | `<else>` branch |
| `IDS_ABOUT_VERSION_COPYRIGHT` | `Copyright {0,date,y} The Chromium Authors. All rights reserved.` | `Copyright {0,date,y} Full Self Browsing. Powered by Chromium — see chrome://credits for attributions.` | About version page copyright line | `<else>` branch |
| `IDS_ABOUT` (use\_titlecase) | `About &Chromium` | `About &Prometheus` | macOS app menu "About" item (titlecase builds) | `use_titlecase and not is_chromeos`, `<else>` branch |
| `IDS_ABOUT` (not use\_titlecase) | `About &Chromium` | `About &Prometheus` | macOS app menu "About" item (lowercase builds) | `not use_titlecase and not is_chromeos`, `<else>` branch |
| `IDS_APP_MENU_PRODUCT_NAME` | `Chromium` | `Prometheus` | macOS Dock, Activity Monitor, app menu title | `is_macosx` |
| `IDS_HELPER_NAME` | `Chromium Helper` | `Prometheus Helper` | Helper app full name | `is_macosx` |
| `IDS_SHORT_HELPER_NAME` | `Chromium Helper` | `Prometheus Helper` | Helper app short name in macOS menu | `is_macosx` |

**GRD conditional note:** `IDS_ABOUT` appears at three locations guarded by different conditions
(use\_titlecase, not use\_titlecase, chromeos). Patch both macOS-relevant branches to prevent
"About Chromium" appearing in either build configuration. The ChromeOS branch is not patched.

---

## Info.plist Identity Fields (Post-Build)

Derived from BRANDING values via `chrome/app/app-Info.plist` substitution at build time.

| Field | Value after rebuild | Source |
|-------|---------------------|--------|
| `CFBundleName` | `Prometheus` | `${CHROMIUM_SHORT_NAME}` from `PRODUCT_SHORTNAME` via branding.gni |
| `CFBundleIdentifier` | `com.fullselfbrowsing.prometheus` | `${CHROMIUM_BUNDLE_ID}` from `MAC_BUNDLE_ID` via branding.gni |
| `CFBundleDisplayName` | `Prometheus` | `${EXECUTABLE_NAME}` from `PRODUCT_FULLNAME` |
| `CFBundleExecutable` | `Prometheus` | `${EXECUTABLE_NAME}` from `PRODUCT_FULLNAME` |

**Verification command (post-build):**

```bash
plutil -p .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist \
  | grep -E 'CFBundleName|CFBundleIdentifier|CFBundleDisplayName'
```

**Status:** Pending verification — values will be confirmed after the Prometheus branding
rebuild completes in a later task. Expected values recorded above; mark as verified once
`plutil` output confirms them.

---

## Surfaces Intentionally Preserved as "Chromium"

| Surface | Reason |
|---------|--------|
| `about:version` upstream credit line | BRAND-03 attribution requirement; `IDS_ABOUT_VERSION_COPYRIGHT` retains "Powered by Chromium" clause |
| `chrome://credits` | Required third-party notices for Chromium and bundled open source; preserved as-is through Phase 24 |
| `IDS_ABOUT_VERSION_COPYRIGHT` Chromium attribution clause | Dual attribution: Full Self Browsing as producing company, Chromium as engine; both must appear |
| `MAC_CREATOR_CODE = Cr24` | Technical identifier, not a user-facing brand surface; unchanged intentionally |

---

## Rebase Drift Detection

Run these commands after a `gclient sync` or Chromium rebase to verify Prometheus identity
overrides are still applied and have not been reverted by an upstream merge:

```bash
# Verify BRANDING MAC_BUNDLE_ID override
grep -q "com.fullselfbrowsing.prometheus" \
  .context/chromium/src/chrome/app/theme/chromium/BRANDING \
  && echo "BRAND OK: MAC_BUNDLE_ID override present" \
  || echo "DRIFT DETECTED: MAC_BUNDLE_ID may have been reverted"

# Verify chromium_strings.grd IDS_PRODUCT_NAME override
grep -q "Prometheus" \
  .context/chromium/src/chrome/app/chromium_strings.grd \
  && echo "BRAND OK: IDS_PRODUCT_NAME Prometheus present in GRD" \
  || echo "DRIFT DETECTED: IDS_PRODUCT_NAME may have reverted to Chromium"

# Verify built Info.plist identity (requires a completed build)
if [ -f .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist ]; then
  plutil -p .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist \
    | grep -q "com.fullselfbrowsing.prometheus" \
    && echo "BRAND OK: CFBundleIdentifier confirmed in built Info.plist" \
    || echo "DRIFT DETECTED: CFBundleIdentifier mismatch in built Info.plist"
else
  echo "INFO: Prometheus.app not yet built — run autoninja after gn gen"
fi

# Verify NOTICES.md baseline is present
grep -q "Powered by FSB" NOTICES.md \
  && echo "LEGAL OK: NOTICES.md Powered by FSB present" \
  || echo "DRIFT DETECTED: NOTICES.md missing or tagline removed"
```

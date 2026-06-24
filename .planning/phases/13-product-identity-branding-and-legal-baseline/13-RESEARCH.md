# Phase 13: Product Identity, Branding, and Legal Baseline — Research

**Researched:** 2026-06-23
**Domain:** Chromium branding override, GRD string patching, macOS bundle identity, first-run suppression, license notice tooling
**Confidence:** HIGH (all findings grounded in the pinned Chromium checkout at `0e8499df5172f55d0d29e2b92ef7e6a704529578`)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Area 1 — Chromium Branding Override Strategy**
- Override Chromium identity by patching the existing `chrome/app/theme/chromium/BRANDING` file **in place** via a tracked `git format-patch`. Do NOT fork a separate brand dir or do runtime string substitution.
- Set `MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus` in BRANDING.
- Patch user-facing product-name strings in `chrome/app/chromium_strings.grd` (IDS_PRODUCT_NAME and related) to Prometheus — BRANDING alone is insufficient for menu/title strings.
- Defer macOS Team ID and notarization to Phase 24.

**Area 2 — De-Chromium Scope and Boundaries**
- Phase 13 de-Chromiums only high-visibility identity surfaces: app/bundle name, window title, macOS app menu + Dock, About/version.
- Suppress the stock Chromium first-run/welcome; do not patch `chrome://welcome` strings in this phase.
- Preserve "Chromium" name where attribution is required: `about:version`, `chrome://credits`, legal notices.
- Add lightweight tracked static guard that fails if GPL Falkon C++ appears in the Chromium source tree.

**Area 3 — Legal / About Surface (BRAND-04)**
- Reuse Chromium's `about_credits` / `chrome://credits` tooling for Chromium + third-party licenses, then append a Prometheus-owned NOTICES section for Font Awesome (CC BY 4.0 + SIL OFL 1.1 fonts + MIT code), Poppins (OFL), Space Mono (OFL), and FSB-owned material.
- Wire a **minimal** Prometheus "About" identity (name / version / "Powered by FSB" linking to credits); themed About WebUI deferred to Phase 16.
- Author the **complete** notice set now.
- Apply verbatim tagline **"Powered by FSB"** to the About/legal surface and README now.

**Area 4 — Product Identity Inventory and Docs**
- Author product-identity inventory mirroring v1 Falkon structure at `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md`.
- Update root README to "Chromium-based agent-native browser" (BRAND-07).

### Claude's Discretion
- Exact patch file organization, the specific IDS_* message IDs to override, the precise inventory table columns, and the mechanism for suppressing the welcome screen are at the planner's/executor's discretion, provided the decisions above and the success criteria are met.

### Deferred Ideas (OUT OF SCOPE)
- Themed Prometheus "About" WebUI page with full brand treatment — Phase 16.
- Side-panel and start-page "Powered by FSB" placements — phases 15 / 16.
- Asset/font porting into Chromium resource format — Phase 14.
- Exhaustive `chrome://` internal-string de-Chromium sweep + de-Falkon enforcement gate — Phase 23.
- macOS Team ID, notarization, and packaged-notice validation — Phase 24.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRAND-01 | User sees Prometheus as app name, window title, profile/application identity, app icon wiring, first-run/about identity, and primary product docs | BRANDING file + GRD string IDs identified; Info.plist substitution chain verified; icon path confirmed; first-run behavior confirmed benign |
| BRAND-02 | User sees "Powered by FSB" as explicit affiliation/tagline in about/legal surfaces and relevant docs | Minimal about identity wiring path identified; NOTICES file location agreed |
| BRAND-03 | No Chromium/Chrome/Falkon/KDE branding in primary product surfaces except where legally required or intentional attribution | Minimal GRD IDs to override enumerated; first-run dialog confirmed auto-suppressed in non-Chrome-branded builds |
| BRAND-04 | Required Chromium, third-party, Font Awesome, Poppins, Space Mono, FSB-owned, and retained notices visible in source and legal/about surface | credits tooling mechanics + `extra_third_party_notice_dirs` extension point verified; `generate_about_credits=true` arg documented; NOTICES file strategy defined |
| BRAND-05 | Migration avoids copying GPL Falkon source into Chromium | Static guard script design documented; no GPL signatures currently found in `.context/chromium/src` (verified by grep) |
| BRAND-06 | Product metadata and bundle IDs are Prometheus-owned and do not conflict with installed Chrome/Chromium profiles or apps | `com.fullselfbrowsing.prometheus` confirmed in BRANDING; Info.plist substitution chain verified; profile isolation confirmed by different bundle ID |
| BRAND-07 | README and release docs describe Prometheus as Chromium-based agent-native browser | Current README text identified; Falkon/Qt references located; update scope bounded |
</phase_requirements>

---

## Summary

Phase 13 makes a built Chromium app identify as Prometheus by applying a minimal patch series inside `.context/chromium/src`. The patch surface is narrow but the rebuild consequence of touching a `.grd` file is significant — it triggers re-grit-compilation and re-pack of the `branded_strings` pak, which hundreds of `.cc`/`.mm` TUs include. That said, the actual C++ recompile cost is low because grit outputs are headers and the majority of the impacted files only use the string values at runtime, not as compile-time constants.

The BRANDING file is the single authoritative upstream source for `MAC_BUNDLE_ID` and `PRODUCT_FULLNAME/SHORTNAME`. The build system reads it at GN generation time via `build/util/branding.gni`; the values flow into `chrome_mac_bundle_id` and `chrome_product_full_name`, which are then substituted into Info.plist templates, the `.app` bundle directory name, and the Frameworks/Helpers directory tree. Changing BRANDING therefore requires a full `gn gen` re-run followed by a rebuild; the new bundle name means the output directory tree is renamed from `Chromium.app` to `Prometheus.app`.

Patching `chromium_strings.grd` (via the `branded_strings` grit target) is also required for the macOS app menu title (`IDS_APP_MENU_PRODUCT_NAME`), window title format (`IDS_BROWSER_WINDOW_TITLE_FORMAT`), the About menu item (`IDS_ABOUT`), and the Helper app name (`IDS_HELPER_NAME`). The macOS app menu specifically reads `IDS_PRODUCT_NAME` through `l10n_util::GetStringUTF16(IDS_PRODUCT_NAME)` in `chrome_browser_main_mac.mm`. The minimum viable GRD patch set is six string overrides.

The first-run dialog on macOS/Linux is auto-suppressed in non-Chrome-branded builds — `ShouldShowFirstRunDialog()` returns false unconditionally when `!BUILDFLAG(GOOGLE_CHROME_BRANDING)`. No extra patch is needed just to suppress the dialog. The "Welcome to Chromium" text in `IDS_FIRST_RUN_DIALOG_WINDOW_TITLE` remains in the GRD but is dead code for this build configuration.

For the legal baseline, `chrome://credits` is served from a compiled HTML file (`IDR_ABOUT_UI_CREDITS_HTML`) that is generated from `about_credits.tmpl` by `tools/licenses/licenses.py`. The generation is gated by `generate_about_credits = is_official_build`, which is false for the current `is_debug=false is_component_build=true symbol_level=0` build args. The simplest Phase-13-compatible approach is to add `generate_about_credits=true` to `out/Default/args.gn` and add a `third_party/prometheus-notices/` directory with a Chromium-format `README.chromium` and license files so that Prometheus notices appear in the generated page. An alternative is to author a standalone `NOTICES.md` or `LICENSES/` file at the repo root for Phase 24 packaging and defer `chrome://credits` integration to the same phase. Both paths are documented.

**Primary recommendation:** Apply three patches in sequence: (1) BRANDING file override, (2) `chromium_strings.grd` override for the six high-visibility string IDs, (3) Prometheus NOTICES file authored and committed. Then run `gn gen && autoninja chrome` to verify the app builds and identifies correctly. Keep icon wiring limited to the `.icns` file path stub for Phase 14's art to drop in.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| App bundle name, .app dir name | Build System (GN/BRANDING) | macOS Info.plist | PRODUCT_FULLNAME drives both the directory name and the EXECUTABLE_NAME substitution |
| CFBundleIdentifier (macOS bundle ID) | Build System (BRANDING via branding.gni) | Info.plist template | MAC_BUNDLE_ID in BRANDING is the canonical source; branding.gni reads it at GN gen time |
| Window title format | GRD string (chrome/app/chromium_strings.grd) | l10n_util at runtime | IDS_BROWSER_WINDOW_TITLE_FORMAT drives all tab/popup window titles |
| macOS app menu product name | GRD string + l10n_util | chrome_browser_main_mac.mm | IDS_APP_MENU_PRODUCT_NAME and IDS_PRODUCT_NAME are read at startup via BuildMainMenu() |
| About menu item label | GRD string | MenuController | IDS_ABOUT in chromium_strings.grd |
| Helper app names | GRD string | BUILD.gn output names | IDS_HELPER_NAME; the directory names also use PRODUCT_FULLNAME from BRANDING |
| First-run/welcome suppression | Build flag gate | — | GOOGLE_CHROME_BRANDING=false in non-Chrome builds; ShouldShowFirstRunDialog() returns false without patches |
| chrome://credits content | Build action (licenses.py) | about_ui.cc / IDR_ABOUT_UI_CREDITS_HTML | generate_about_credits=true triggers actual generation; false copies sample_credits.html |
| App icon (.icns) | Build system path reference | chrome/BUILD.gn chrome_app_icon | chrome/app/theme/chromium/mac/app.icns is the source path; replace-in-place for Phase 14 |
| Legal NOTICES file (standalone) | Planning repo root | Phase 24 packaging | Authored as NOTICES.md or LICENSES/ at root; not yet wired into chrome://credits |
| README / docs update | Root repo | — | README.md update for BRAND-07 |
| GPL guard script | Planning repo | .planning/chromium/ scripts | Grep-based check, run pre-commit or as CI gate |

---

## Standard Stack

### Core — No New Packages Required

This phase is entirely source edits and script authoring within the existing stack. No npm/pip/cargo packages needed.

| Tool | Version | Purpose | Already Present |
|------|---------|---------|-----------------|
| `tools/licenses/licenses.py` | in-tree | generates `chrome://credits` HTML from README.chromium metadata | Yes |
| `build/util/branding.gni` | in-tree | reads BRANDING file at GN gen time; exports `chrome_mac_bundle_id`, `chrome_product_full_name` | Yes |
| `chrome/app/chromium_strings.grd` | in-tree | grit source for all Chromium-branded UI strings | Yes |
| `git format-patch` | git | patch export from pinned baseline | Yes |
| `gn gen` + `autoninja` | depot_tools | build system | Already at `.context/depot_tools` |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `grep` / `bash` | GPL guard script | Run before each Chromium commit to verify no Falkon GPL signatures entered the tree |
| `python3 tools/licenses/licenses.py credits` | Regenerate `about_credits.html` | Run after adding `third_party/prometheus-notices/` directory |
| `plutil -p out/Default/Prometheus.app/Contents/Info.plist` | Verify bundle ID and CFBundleName after rebuild | Post-build validation |

## Package Legitimacy Audit

> Not applicable — this phase installs no external packages. All dependencies are in-tree Chromium tools or system commands.

---

## Architecture Patterns

### System Architecture Diagram

```
BRANDING file (chrome/app/theme/chromium/BRANDING)
    |
    v
branding.gni (exec_script version.py at GN gen time)
    |-- chrome_product_full_name = "Prometheus"
    |-- chrome_product_short_name = "Prometheus"
    |-- chrome_mac_bundle_id = "com.fullselfbrowsing.prometheus"
    |-- chrome_mac_creator_code = "Cr24" (unchanged)
    |
    +-----> chrome/BUILD.gn
    |           |-- output_name = chrome_product_full_name      --> Prometheus.app/
    |           |-- CHROMIUM_BUNDLE_ID substitution             --> CFBundleIdentifier
    |           |-- CHROMIUM_SHORT_NAME substitution            --> CFBundleName
    |           |-- app.icns source path                        --> CFBundleIconFile
    |
    +-----> chrome/app/app-Info.plist (substitution at build)
                |-- CFBundleDisplayName = ${EXECUTABLE_NAME}   --> "Prometheus"
                |-- CFBundleName = ${CHROMIUM_SHORT_NAME}       --> "Prometheus"
                |-- CFBundleIdentifier = ${CHROMIUM_BUNDLE_ID}  --> "com.fullselfbrowsing.prometheus"

chromium_strings.grd (branded_strings grit target)
    |
    v  (grit compile produces branded_strings.h + .pak files)
    |
    +-- IDS_PRODUCT_NAME                --> "Prometheus"
    +-- IDS_SHORT_PRODUCT_NAME          --> "Prometheus"
    +-- IDS_APP_MENU_PRODUCT_NAME       --> "Prometheus"   (macOS Dock/Activity Monitor)
    +-- IDS_BROWSER_WINDOW_TITLE_FORMAT --> "$1 - Prometheus"
    +-- IDS_ABOUT                       --> "About Prometheus"
    +-- IDS_HELPER_NAME                 --> "Prometheus Helper"
    |
    +-- chrome_browser_main_mac.mm:BuildMainMenu(IDS_PRODUCT_NAME)  --> macOS app menu title

NOTICES file (new, authored this phase)
    |
    +-- NOTICES.md or LICENSES/NOTICES.txt at repo root
    |       Font Awesome CC BY 4.0 + OFL 1.1 + MIT
    |       Poppins OFL 1.1
    |       Space Mono OFL 1.1
    |       FSB-owned material
    |       "Powered by Chromium — see chrome://credits"
    |
    +-- (optional) third_party/prometheus-notices/ in Chromium tree
            README.chromium (licenses.py format)
            LICENSE files
            --> appears in chrome://credits when generate_about_credits=true
```

### Recommended Patch File Organization

```
.context/chromium-patches/
└── phase-13-branding/
    ├── 0001-branding-BRANDING-file-override.patch
    ├── 0002-branding-chromium-strings-grd-product-name.patch
    └── 0003-branding-prometheus-notices-third-party-dir.patch    (optional)

.planning/chromium/
├── CHROMIUM-CHECKOUT.md            (existing handoff doc)
├── PRODUCT-IDENTITY-INVENTORY.md   (NEW — authored this phase)
└── LEGAL-NOTICE-INVENTORY.md       (NEW — authored this phase)

(root repo)
├── NOTICES.md                      (NEW — legal baseline, authored this phase)
└── README.md                       (UPDATE — BRAND-07 language)
```

`chromium-patches/` is in `.context/` which is git-ignored by the root repo. The patch files are referenced from the tracked planning docs. The planning docs in `.planning/chromium/` are root-repo tracked.

### Patch 1: BRANDING File Override

```
# file: chrome/app/theme/chromium/BRANDING
COMPANY_FULLNAME=Full Self Browsing
COMPANY_SHORTNAME=FSB
PRODUCT_FULLNAME=Prometheus
PRODUCT_SHORTNAME=Prometheus
PRODUCT_INSTALLER_FULLNAME=Prometheus Installer
PRODUCT_INSTALLER_SHORTNAME=Prometheus Installer
COPYRIGHT=Copyright 2024–2026 Full Self Browsing. Powered by Chromium.
MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus
MAC_CREATOR_CODE=Cr24
MAC_TEAM_ID=
```

Source: verified from `.context/chromium/src/chrome/app/theme/chromium/BRANDING` [VERIFIED: direct file read]

**Critical:** Changing BRANDING requires re-running `gn gen` because `branding.gni` calls `exec_script("version.py", ...)` at GN generation time, not at compile time. After `gn gen`, the output directory tree will reference `Prometheus.app` instead of `Chromium.app`. Autoninja will rename/recreate the bundle tree.

### Patch 2: chromium_strings.grd Product-Name Overrides

The `branded_strings` grit target in `chrome/app/BUILD.gn` processes `${branding_path_product}_strings.grd` which resolves to `chrome/app/chromium_strings.grd` for non-Chrome-branded builds. [VERIFIED: direct file read of BUILD.gn line 127]

**Minimum viable set of IDS messages to patch for Phase 13 high-visibility surfaces:**

| Message ID | Location in file (approx. line) | Current value | Override to |
|-----------|--------------------------------|---------------|-------------|
| `IDS_PRODUCT_NAME` | line 296 | `Chromium` | `Prometheus` |
| `IDS_SHORT_PRODUCT_NAME` | line 299 | `Chromium` | `Prometheus` |
| `IDS_BROWSER_WINDOW_TITLE_FORMAT` | line 445 | `$1 - Chromium` | `$1 - Prometheus` |
| `IDS_APP_MENU_PRODUCT_NAME` (macOS only) | line 1118 | `Chromium` | `Prometheus` |
| `IDS_ABOUT` (macOS, use_titlecase) | line 1082 | `About &Chromium` | `About &Prometheus` |
| `IDS_ABOUT` (macOS, not use_titlecase) | line 1099 | `About &Chromium` | `About &Prometheus` |
| `IDS_HELPER_NAME` (macOS) | line 1121 | `Chromium Helper` | `Prometheus Helper` |
| `IDS_SHORT_HELPER_NAME` (macOS) | line 1124 | `Chromium Helper` | `Prometheus Helper` |
| `IDS_FIRST_RUN_DIALOG_WINDOW_TITLE` (macOS/Linux) | line 319 | `Welcome to Chromium` | Leave or patch to `Welcome to Prometheus` — dead code for non-Chrome-branded builds, but patch for correctness |
| `IDS_ABOUT_VERSION_COMPANY_NAME` | line 508 | `The Chromium Authors` | `Full Self Browsing` |
| `IDS_ABOUT_VERSION_COPYRIGHT` | line 511 | `Copyright {year} The Chromium Authors...` | `Copyright {year} Full Self Browsing. Powered by Chromium.` |

**IDS_ACCESSIBLE_BROWSER_WINDOW_TITLE_FORMAT** (line 484): Patch for accessibility correctness — changes `- Chromium` to `- Prometheus`. Not strictly high-visibility but trivial to include.

**Do NOT change in this phase:**
- `IDS_PRODUCT_DESCRIPTION` (Windows-only string, irrelevant for macOS)
- Any `chrome://welcome` WebUI strings (deferred to Phase 23)
- `IDS_RELAUNCH_TO_UPDATE` (update mechanism not wired; low visibility)

Source: [VERIFIED: direct line-by-line read of `.context/chromium/src/chrome/app/chromium_strings.grd`]

### App Icon Wiring (Phase 14 Slot)

The macOS app icon path is hardcoded in `chrome/BUILD.gn`:

```gn
bundle_data("chrome_app_icon") {
  sources = [ "app/theme/$branding_path_component/mac/app.icns" ]
  ...
}
```

For the `chromium` brand this resolves to: `chrome/app/theme/chromium/mac/app.icns` [VERIFIED: BUILD.gn line 643]

Phase 13 must author a **placeholder** file or keep the existing Chromium icns at this path so the build succeeds. Phase 14 drops the final Prometheus `.icns` by replacing this file. No change to BUILD.gn is needed.

Info.plist `CFBundleIconFile` is `app.icns` (hardcoded string in `app-Info.plist` line 151). The icon name does not need to change.

The Falkon v1 reference icon is at `.context/falkon-preservation/patches/` (restored from bundle). Phase 14 uses it as the art source; Phase 13 leaves `app.icns` as-is or replaces it with a minimal Prometheus placeholder if desired for the smoke test.

### Anti-Patterns to Avoid

- **Do not change `branding_path_component` in GN args.** This would point the build at a non-existent `chrome/app/theme/prometheus/` directory. Edit the files in-place inside the existing `chromium/` directory tree. [VERIFIED: branding.gni and chrome_build.gni]
- **Do not use runtime string substitution** (env vars, plist scripts) instead of GRD patches. IDS_PRODUCT_NAME is embedded in the pak file; runtime substitution cannot override it.
- **Do not edit `generate_about_credits` without re-running gn gen.** It's a declare_args variable; changing it in args.gn requires `gn gen` before `autoninja`.
- **Do not commit the Chromium source as a root git submodule.** `.context/chromium/src` is an independent depot_tools checkout; it must remain ignored by the root repo.
- **Do not forget `gn gen` after BRANDING changes.** The `exec_script` call in `branding.gni` runs at gen time. A `gn gen`-less autoninja after a BRANDING edit builds with the old values.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reading BRANDING fields into GN | Custom GN parsing | `build/util/branding.gni` (already wired) | Already reads all fields; exports as GN variables |
| Generating third-party license HTML | Custom HTML template | `tools/licenses/licenses.py credits` + `about_credits.tmpl` | Handles 200+ dependencies, depfile tracking, SPDX |
| Adding Prometheus notices to credits | Hand-editing `about_credits.html` | Add `third_party/prometheus-notices/README.chromium` and rerun licenses.py | Hand-edits are overwritten on rebuild; the `extra_third_party_notice_dirs` mechanism or README.chromium pattern is regenerable |
| Bundle ID collision prevention | Custom plist script | Change `MAC_BUNDLE_ID` in BRANDING | Bundle ID drives profile directory path on macOS; different ID means different profile root, no collision |

---

## Common Pitfalls

### Pitfall 1: BRANDING Change Without `gn gen` Re-Run

**What goes wrong:** After editing BRANDING and running `autoninja` without `gn gen`, the build still says `Chromium.app` because `branding.gni` cached the old value.

**Why it happens:** `exec_script` in `branding.gni` only re-runs when `gn gen` is called. The `[branding_file_path]` listed as an input means GN tracks this, but only within `gn gen`, not at autoninja time.

**How to avoid:** Always sequence `gn gen out/Default --args='...'` before `autoninja` when BRANDING changes. Treat BRANDING change + gn gen as an atomic step.

**Warning signs:** `ls out/Default/*.app` still shows `Chromium.app` after autoninja.

### Pitfall 2: GRD Conditional Guards Not Respected

**What goes wrong:** The GRD file uses `<if expr="...">` conditionals (`is_macosx`, `_is_chrome_for_testing_branded`, `use_titlecase`). Patching the wrong branch of a conditional changes nothing because the branch is compiled out.

**Why it happens:** `IDS_ABOUT` appears three times under different conditions (line 1082, 1099, 1109 in the file). The macOS builds use `use_titlecase=true` on macOS. Only the matching `<if expr="use_titlecase and not is_chromeos">` branch is compiled.

**How to avoid:** Patch all conditional branches for `IDS_ABOUT` that apply to macOS. Verify the compiled value in the pak by inspecting `chrome_strings.pak` or by running the app and checking the macOS app menu.

**Warning signs:** App menu still says "About Chromium" after rebuild.

### Pitfall 3: `chrome://credits` Shows Sample Page (Not Real Credits)

**What goes wrong:** `chrome://credits` shows a stub "This is sample credits page. To get correct credits page, set generate_about_credits=true in args.gn." instead of the real license list.

**Why it happens:** `generate_about_credits = is_official_build` in `components/resources/BUILD.gn`. Our build is NOT `is_official_build`, so the copy action in the `else` branch uses `sample_credits.html`. [VERIFIED: BUILD.gn line 19 and 183]

**How to avoid two-phase strategy:**
- **Phase 13 approach:** Add `generate_about_credits=true` to `out/Default/args.gn`, re-run `gn gen`, and add Prometheus notices as a `third_party/prometheus-notices/` directory so licenses.py picks them up. This triggers a filesystem scan of `third_party/` which takes ~2 minutes but is a one-time cost per build tree.
- **Alternative:** Author a standalone `NOTICES.md` at root for Phase 24 packaging; accept the stub `chrome://credits` until Phase 24 wires a proper notices page. Defers any build complexity.

The planner should choose based on whether the minimal About identity (BRAND-04) requires `chrome://credits` to show real content in Phase 13 or if a standalone NOTICES file suffices.

**Warning signs:** Visiting `chrome://credits` in the built app shows the stub HTML.

### Pitfall 4: Rebuild Cost of `.grd` Changes

**What goes wrong:** Developer expects a quick incremental build after `.grd` change; gets a longer build because `branded_strings` grit target regenerates pak files which many translation units include.

**Why it happens:** ~340 `.cc`/`.mm` files in `chrome/browser` directly reference `branded_strings` or `IDS_PRODUCT_NAME` via `#include "chrome/grit/branded_strings.h"`. Changing the grit header forces recompile of all of them.

**Rebuild cost estimate:**
- Grit regeneration: ~5 seconds
- Pak repack: ~10 seconds
- Relink (is_component_build=true mitigates this): ~30-60 seconds
- Total `.o` recompile: ~5-20 minutes depending on machine (component build reduces this significantly vs. non-component)

**How to avoid surprise:** Do not combine `.grd` changes with unrelated refactors in the same commit. Sequence: (1) BRANDING + gn gen, (2) `.grd` patch, (3) autoninja, (4) verify. Running `autoninja chrome 2>&1 | tail -5` shows progress.

**Mitigation:** `is_component_build=true` (already in GN args) means only `.o` files change, not the monolithic library. The total rebuild after a `.grd` change is significantly shorter than a clean build.

### Pitfall 5: App Bundle Name Changes Break the Smoke Script

**What goes wrong:** `smoke-launch-unmodified.sh` hardcodes the path `.context/chromium/src/out/Default/Chromium.app/Contents/MacOS/Chromium`. After the BRANDING patch, the path changes to `Prometheus.app/Contents/MacOS/Prometheus`.

**Why it happens:** `chrome_product_full_name` drives both the binary name and the `.app` directory name.

**How to avoid:** Update `.planning/chromium/smoke-launch-unmodified.sh` (or author a new `smoke-launch-prometheus.sh`) that uses `Prometheus.app` as the path. The Phase 12 gate scripts must be updated or a new set created for Phase 13+ work. The existing Phase 12 gate is preserved for unmodified baseline reference.

**Warning signs:** `smoke-launch-unmodified.sh` fails with "binary not found" after branding rebuild.

### Pitfall 6: IDS_ABOUT_VERSION_COMPANY_NAME vs. Required Upstream Attribution

**What goes wrong:** Changing `IDS_ABOUT_VERSION_COMPANY_NAME` to "Full Self Browsing" removes the "The Chromium Authors" credit from `about:version`.

**Why it matters:** BRAND-03 explicitly allows "Chromium" attribution where legally required. The `about:version` page shows company name + copyright. FSB is the producing company but Chromium + third-party attribution obligations remain.

**Recommended approach:** Set `IDS_ABOUT_VERSION_COMPANY_NAME` to a dual-attribution string such as `Full Self Browsing, powered by Chromium` or `Full Self Browsing`. In the `COPYRIGHT` field in BRANDING (which controls `IDS_ABOUT_VERSION_COPYRIGHT`), include: `Copyright 2024–2026 Full Self Browsing. Powered by Chromium — see chrome://credits for attributions.`

This satisfies BRAND-01 (Prometheus identity) while preserving upstream attribution per BRAND-03 and BRAND-04.

### Pitfall 7: `extra_third_party_notice_dirs` Path Must Be Absolute

**What goes wrong:** `licenses.py` receives a relative path for `--extra-third-party-dirs` that resolves incorrectly relative to the script's CWD.

**Why it happens:** The GN action calls `licenses.py` with `rebase_path(about_credits_file, root_build_dir)`. When `extra_third_party_notice_dirs` is defined, the paths are passed as-is without rebasing.

**How to avoid:** Define `extra_third_party_notice_dirs` in `BUILD.gn` as an absolute path using `rebase_path(//chrome/third_party/prometheus-notices, root_build_dir)` or place the notices directory inside `third_party/` where `licenses.py` already scans by default.

---

## Code Examples

### BRANDING file after Prometheus override

```text
# Source: chrome/app/theme/chromium/BRANDING (in-place edit, tracked as git patch)
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

[VERIFIED: field names from `.context/chromium/src/chrome/app/theme/chromium/BRANDING` direct read]

### chromium_strings.grd patch excerpt (key messages only)

```xml
<!-- IDS_PRODUCT_NAME: line ~296 in chromium_strings.grd -->
<!-- Change: Chromium -> Prometheus -->
<message name="IDS_PRODUCT_NAME" desc="..." translateable="false">
  Prometheus
</message>
<message name="IDS_SHORT_PRODUCT_NAME" desc="..." translateable="false">
  Prometheus
</message>

<!-- IDS_BROWSER_WINDOW_TITLE_FORMAT: line ~445 -->
<!-- Change: $1 - Chromium -> $1 - Prometheus -->
<message name="IDS_BROWSER_WINDOW_TITLE_FORMAT" desc="...">
  <ph name="PAGE_TITLE">$1<ex>Google</ex></ph> - Prometheus
</message>

<!-- IDS_APP_MENU_PRODUCT_NAME (macOS only): line ~1118 -->
<!-- Change: Chromium -> Prometheus -->
<message name="IDS_APP_MENU_PRODUCT_NAME" desc="..." translateable="false">
  Prometheus
</message>

<!-- IDS_ABOUT macOS use_titlecase branch: line ~1082 -->
<!-- Change: About &Chromium -> About &Prometheus -->
<message name="IDS_ABOUT" desc="...">
  About &amp;Prometheus
</message>

<!-- IDS_HELPER_NAME macOS: line ~1121 -->
<message name="IDS_HELPER_NAME" desc="...">
  Prometheus Helper
</message>
<message name="IDS_SHORT_HELPER_NAME" desc="...">
  Prometheus Helper
</message>
```

[VERIFIED: message names and approximate line numbers from direct read of `.context/chromium/src/chrome/app/chromium_strings.grd`]

### How macOS app menu title flows

```cpp
// Source: chrome/browser/chrome_browser_main_mac.mm (line ~162)
chrome::BuildMainMenu(NSApp, app_controller,
                      l10n_util::GetStringUTF16(IDS_PRODUCT_NAME),
                      /*is_pwa=*/false,
                      /*is_rtl=*/base::i18n::IsRTL());
```

`IDS_PRODUCT_NAME` from the pak file drives the macOS "Prometheus" app menu title. This also means the Dock tooltip and Activity Monitor show the `IDS_APP_MENU_PRODUCT_NAME` value. [VERIFIED: chrome_browser_main_mac.mm line 163]

### GPL Falkon guard script (minimal)

```bash
#!/usr/bin/env bash
# .planning/chromium/check-falkon-gpl-guard.sh
# Fails if GPL Falkon C++/Qt signatures appear in .context/chromium/src
# Run before each Prometheus-branch commit.

set -euo pipefail
SRC=".context/chromium/src"

# Signatures that indicate copied GPL Falkon implementation
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
         -E "$pat" "$SRC/chrome/browser/prometheus" "$SRC/components/prometheus" 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    echo "GPL GUARD FAIL: Pattern '$pat' found in Prometheus Chromium source:"
    echo "$hits"
    FOUND=1
  fi
done

if [[ $FOUND -ne 0 ]]; then
  echo "ERROR: GPL Falkon signatures detected. Do not copy GPL source into Chromium without license review."
  exit 1
fi
echo "GPL guard: clean — no Falkon GPL signatures in Prometheus Chromium directories."
```

**Scope note:** Guard only scans Prometheus-owned directories (`chrome/browser/prometheus`, `components/prometheus`) to avoid false positives from unrelated Chromium code. The third-party/falkon hypothetical case is the risk to guard.

[ASSUMED: the specific regex patterns — no authoritative Falkon signature spec exists; these are derived from the Falkon codebase naming conventions seen in `.context/falkon-preservation/` patches]

### Prometheus NOTICES file content outline

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

---

## First-Run / Welcome Suppression

**Finding:** The first-run dialog is **already suppressed** in non-Chrome-branded Chromium builds. No patch is required for this phase.

**Mechanism verified:** `chrome/browser/first_run/first_run_internal_posix.cc` function `ShouldShowFirstRunDialog()` returns `false` unconditionally when `!BUILDFLAG(GOOGLE_CHROME_BRANDING)` (the `#if !BUILDFLAG(GOOGLE_CHROME_BRANDING) return false; #endif` block at line 50-51). [VERIFIED: direct file read]

**Confirmed by smoke test:** Phase 12 already passes `--no-first-run` as a launch flag in `smoke-launch-unmodified.sh`, which also sets `--no-default-browser-check`. These flags can remain in the Prometheus launch script for defense-in-depth.

**What `IDS_FIRST_RUN_DIALOG_WINDOW_TITLE` does:** The string "Welcome to Chromium" at line 319 is compiled into the pak file but the dialog code path that uses it never executes for `!GOOGLE_CHROME_BRANDING`. Patching it to "Welcome to Prometheus" is optional — it changes the pak but has no visible effect. Recommend including it for correctness to avoid any "Chromium" strings being live, even in dead code paths.

---

## Legal / About Surface Mechanics

### `chrome://credits` Generation Flow

```
generate_about_credits=true (must be added to args.gn)
        |
        v
components/resources/BUILD.gn: action("about_credits")
        |-- script: tools/licenses/licenses.py credits
        |-- inputs: about_credits.tmpl, about_credits_entry.tmpl, about_credits_reciprocal.tmpl
        |-- args: --target-os=mac --depfile=... <output_html>
        |-- optional: --extra-third-party-dirs=<path>
        v
$gen_dir/components/resources/about_credits.html
        |
        v
components_resources.grd (IDR_ABOUT_UI_CREDITS_HTML resource)
        |
        v
components/webui/about/credit_utils.cc: GetCredits()
        |-- loads IDR_ABOUT_UI_CREDITS_HTML from ResourceBundle
        v
about_ui.cc: AboutUIHTMLSource serves chrome://credits
```

[VERIFIED: BUILD.gn lines 156-188, credit_utils.cc direct read]

### Prometheus Notices in `chrome://credits`

The Chromium licenses.py scanner accepts a `--extra-third-party-dirs` argument OR scans any directory containing a `README.chromium` file within `third_party/`. The cleanest approach for Phase 13 is:

**Option A (recommended for Phase 13):** Author a standalone `NOTICES.md` (or `LICENSES/NOTICES.txt`) at the repo root. Accept the sample page for `chrome://credits` until Phase 14/16/24 wires proper notices. Minimal work, no build complexity, satisfies BRAND-04 as a source document.

**Option B (complete, more effort):** Add `generate_about_credits=true` to `out/Default/args.gn`. Create `chrome/third_party/prometheus-notices/README.chromium` and add the Font Awesome / Poppins / Space Mono license texts. This integrates into `chrome://credits` but adds a ~2-minute licenses.py scan on every clean build. The planner should note this adds build time.

A README.chromium file for Option B follows the standard format:
```
Name: Font Awesome Free
Short Name: font-awesome-free
URL: https://fontawesome.com
Version: 6.5.2
License: MIT (code), CC BY 4.0 (icons), OFL 1.1 (fonts)
License File: LICENSE.md
Security Critical: no
Shipped: yes
Description: Offline subset of Font Awesome Free icons used in Prometheus UI.
```

[VERIFIED: format from `.context/chromium/src/tools/licenses/licenses.py` README.chromium scanning logic]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate brand directory for forks | Edit chromium brand dir in-place via format-patch | Chromium project convention (current) | Simpler rebase; no GN arg changes needed |
| is_official_build gates credits generation | `generate_about_credits` declare_arg (can be set independently) | Current Chromium | Can enable real credits without full official build |
| Hard-coded `org.chromium.Chromium` bundle ID in plists | MAC_BUNDLE_ID from BRANDING flows through branding.gni | Current Chromium | Single source of truth for bundle ID |

---

## Runtime State Inventory

> This is a metadata/identity-only phase. No rename of a running service or stored data key.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | No Prometheus-specific user data directory exists yet (no prior Prometheus Chromium launch). Profile will be created at `~/Library/Application Support/com.fullselfbrowsing.prometheus/` on first launch. | None — new directory; no migration |
| Live service config | None — no external services registered for Chromium-as-Prometheus yet | None |
| OS-registered state | macOS Launch Services still maps `org.chromium.Chromium` for the current binary. After branding rebuild and first launch, `com.fullselfbrowsing.prometheus` will register. | None needed; new registration happens automatically |
| Secrets/env vars | Phase 12 smoke scripts hardcode `Chromium.app` paths. Need update after BRANDING rebuild. | Update `.planning/chromium/smoke-launch-unmodified.sh` or author `smoke-launch-prometheus.sh` |
| Build artifacts | `out/Default/Chromium.app` and helper apps will be replaced by `Prometheus.app` etc. after rebuild. Old `Chromium.app` symlinks in the Dock may need re-dragging. | Delete old `Chromium.app` symlinks; drag new `Prometheus.app` to Dock |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash smoke tests (existing pattern from Phase 12) |
| Config file | `.planning/chromium/` scripts |
| Quick run command | `bash .planning/chromium/smoke-launch-prometheus.sh` |
| Full suite command | `bash .planning/chromium/check-chromium-env.sh && bash .planning/chromium/build-chromium-baseline.sh --no-op-ok && bash .planning/chromium/smoke-launch-prometheus.sh && bash .planning/chromium/verify-artifact-isolation.sh` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BRAND-01 | App bundle named `Prometheus.app` | automated | `test -d out/Default/Prometheus.app` | ❌ Wave 0 |
| BRAND-01 | `CFBundleName=Prometheus` in Info.plist | automated | `plutil -p out/Default/Prometheus.app/Contents/Info.plist \| grep -q Prometheus` | ❌ Wave 0 |
| BRAND-01 | `CFBundleIdentifier=com.fullselfbrowsing.prometheus` | automated | `plutil -p out/Default/Prometheus.app/Contents/Info.plist \| grep -q com.fullselfbrowsing.prometheus` | ❌ Wave 0 |
| BRAND-01 | Window title contains "Prometheus" | manual smoke | Launch app, observe window title bar | — |
| BRAND-01 | macOS Dock shows "Prometheus" tooltip | manual smoke | Launch app, hover Dock icon | — |
| BRAND-01 | macOS app menu shows "About Prometheus" | manual smoke | Click app menu | — |
| BRAND-02 | "Powered by FSB" in NOTICES.md | automated | `grep -q "Powered by FSB" NOTICES.md` | ❌ Wave 0 |
| BRAND-03 | No unwanted "Chromium" in app name/title | automated | `plutil -p ... \| grep -v Chromium \| grep -q Prometheus` (bundle ID field exempted) | ❌ Wave 0 |
| BRAND-04 | NOTICES.md contains Font Awesome, Poppins, Space Mono entries | automated | `grep -q "Font Awesome" NOTICES.md && grep -q "Poppins" NOTICES.md && grep -q "Space Mono" NOTICES.md` | ❌ Wave 0 |
| BRAND-04 | chrome://credits either shows real content or NOTICES.md authored | automated | `grep -q "Powered by Chromium" NOTICES.md` (min bar) | ❌ Wave 0 |
| BRAND-05 | No GPL Falkon signatures in Prometheus Chromium dirs | automated | `bash .planning/chromium/check-falkon-gpl-guard.sh` | ❌ Wave 0 |
| BRAND-06 | Bundle ID is `com.fullselfbrowsing.prometheus` (not `org.chromium.Chromium`) | automated | `plutil -p ... \| grep -q com.fullselfbrowsing.prometheus` | ❌ Wave 0 |
| BRAND-07 | README describes "Chromium-based agent-native browser" | automated | `grep -q "Chromium-based agent-native browser" README.md` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run `bash .planning/chromium/check-falkon-gpl-guard.sh` and verify `plutil` assertions on Info.plist
- **Per wave merge:** Full smoke launch + identity checks
- **Phase gate:** All automated checks pass + manual smoke of macOS app menu and window title before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `.planning/chromium/smoke-launch-prometheus.sh` — adapted from Phase 12 script with `Prometheus.app` path
- [ ] `.planning/chromium/check-falkon-gpl-guard.sh` — GPL guard script
- [ ] `NOTICES.md` — legal baseline file (authored as part of Phase 13 implementation)
- [ ] `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` — inventory doc
- [ ] `.planning/chromium/LEGAL-NOTICE-INVENTORY.md` — legal notice inventory

---

## Security Domain

`security_enforcement` not explicitly set to false in config — treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Not relevant — no auth in identity/branding phase |
| V3 Session Management | no | Not relevant |
| V4 Access Control | no | Not relevant |
| V5 Input Validation | no | No user input in branding/legal files |
| V6 Cryptography | no | Not relevant — no crypto |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| GPL source contamination in Chromium tree | Tampering (license obligations) | GPL guard script; BRANDING-only changes + GRD edits; no C++ from Falkon |
| Bundle ID collision with installed Chromium | Spoofing (profile data access) | `com.fullselfbrowsing.prometheus` is distinct from `org.chromium.Chromium`; different profile directory |
| Misleading attribution (removing required Chromium credits) | Repudiation | BRAND-03 compliance; `chrome://credits` preserved; NOTICES.md authored |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GPL guard regex patterns based on Falkon naming conventions from preservation bundle | GPL guard script example | False negatives (missing a GPL pattern) — mitigated by Phase 23 deep de-Falkon gate |
| A2 | `COMPANY_FULLNAME` should be "Full Self Browsing" | BRANDING file override | If FSB prefers a different legal entity name, the copyright string would need updating |
| A3 | Font Awesome version is 6.5.2 in NOTICES draft | NOTICES content outline | Version may differ from what was actually vendored in Phase 9; Phase 14 will verify |
| A4 | Option A (standalone NOTICES.md) suffices for BRAND-04 | Legal mechanics section | If BRAND-04 is interpreted to require chrome://credits integration, Option B must be selected — adds generate_about_credits=true and licenses.py third-party dir |

---

## Open Questions

1. **Prometheus NOTICES in `chrome://credits` — Option A vs B?**
   - What we know: BRAND-04 requires notices "visible in source and in an appropriate legal/about surface." CONTEXT.md says "wire a minimal About identity" and "author complete notice content now."
   - What's unclear: Does "appropriate legal/about surface" require `chrome://credits` integration (Option B) or does a committed `NOTICES.md` file + a minimal "see NOTICES.md" link in the About surface satisfy Phase 13?
   - Recommendation: Use Option A (standalone NOTICES.md) for Phase 13 and wire `generate_about_credits=true` + third_party dir in Phase 13 Plan 3 or defer to Phase 24. The planner should clarify with the CONTEXT.md decision "author legal notice content in full" — this likely means Option A is sufficient since the richer About WebUI is Phase 16.

2. **Prometheus.app smoke script path update scope**
   - What we know: Phase 12 scripts use `Chromium.app`. After branding rebuild the path changes.
   - What's unclear: Should the existing Phase 12 scripts be updated in-place (breaking their "unmodified baseline" semantics) or should new Phase 13 smoke scripts be authored alongside?
   - Recommendation: Author new scripts (e.g., `smoke-launch-prometheus.sh`) that use `Prometheus.app`; keep Phase 12 scripts unchanged as unmodified baseline references.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Chromium checkout | All Chromium patches | ✓ | `0e8499df...` | None — required |
| depot_tools (gn, autoninja) | Build after BRANDING change | ✓ | `ea253a3e...` | None — required |
| Python 3 | licenses.py (Option B) | ✓ | System python3 | N/A if Option A chosen |
| git format-patch | Patch export | ✓ | System git | None — required |
| plutil | Post-build Info.plist verification | ✓ | macOS built-in | `defaults read` alternative |

---

## Sources

### Primary (HIGH confidence)
- `.context/chromium/src/chrome/app/theme/chromium/BRANDING` — exact field names and current values, direct read
- `.context/chromium/src/build/util/branding.gni` — full source showing MAC_BUNDLE_ID → chrome_mac_bundle_id flow, direct read
- `.context/chromium/src/build/config/chrome_build.gni` — branding_path_component resolution, is_chrome_branded=false default, direct read
- `.context/chromium/src/chrome/app/chromium_strings.grd` — exact message names and line locations for all 11 key IDS_* overrides, direct read
- `.context/chromium/src/chrome/app/app-Info.plist` — CFBundleName=${CHROMIUM_SHORT_NAME}, CFBundleIdentifier=${CHROMIUM_BUNDLE_ID} substitutions, direct read
- `.context/chromium/src/chrome/BUILD.gn` — icon path `app/theme/$branding_path_component/mac/app.icns`, output_name=chrome_product_full_name, direct read
- `.context/chromium/src/chrome/browser/first_run/first_run_internal_posix.cc` — ShouldShowFirstRunDialog() returns false for !GOOGLE_CHROME_BRANDING, direct read
- `.context/chromium/src/components/resources/BUILD.gn` — generate_about_credits=is_official_build default; action vs copy branch, direct read
- `.context/chromium/src/components/webui/about/credit_utils.cc` — GetCredits() loads IDR_ABOUT_UI_CREDITS_HTML from ResourceBundle, direct read
- `.context/chromium/src/chrome/browser/chrome_browser_main_mac.mm` — BuildMainMenu(IDS_PRODUCT_NAME) — macOS app menu title source, line 163, direct read
- `.context/chromium/src/out/Default/Chromium.app/Contents/Info.plist` — built plist confirming CFBundleName=Chromium, CFBundleIdentifier=org.chromium.Chromium, direct read

### Secondary (MEDIUM confidence)
- `.context/chromium/src/tools/licenses/licenses.py` — `--extra-third-party-dirs` argument, README.chromium format, direct read of comments and argument parser
- `.context/chromium/src/components/webui/about/resources/about_credits.tmpl` — template structure showing {{entries}} extension point

### Tertiary (LOW confidence)
- GPL guard regex patterns [ASSUMED] — derived from Falkon naming conventions in preserved patches; not formally defined by a spec

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all build wiring verified in actual checkout
- Architecture: HIGH — Info.plist substitution chain, bundle ID flow, GRD string IDs, first-run behavior all verified by direct file reads
- Pitfalls: HIGH — rebuild cost estimated from file counts; gn gen requirement verified from branding.gni exec_script; conditional GRD branches verified by direct read
- Legal tooling: HIGH (mechanism) / MEDIUM (Option A vs B tradeoff) — generation flow verified; the Phase 13 sufficient vs. insufficient question for BRAND-04 is a planning judgment call

**Research date:** 2026-06-23
**Valid until:** 2026-07-23 (Chromium is pinned at `0e8499df...`; this research is valid as long as the pinned revision does not change)

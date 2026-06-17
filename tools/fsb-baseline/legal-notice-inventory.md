# Legal Notice Inventory

**Phase:** 1 - Baseline and Legal Inventory  
**Captured:** 2026-06-16  
**Scope:** Inherited legal and license notice surfaces that later rebrand, packaging, and release phases must preserve.

## Required Preservation Rule

Rebrand work may replace product-visible Falkon/KDE identity, but it must not delete required GPL, Qt, KDE, Falkon, theme, third-party, or source-availability notices. If a notice is removed from a marketing or product-identity surface, the equivalent legal notice must remain available in source and in an appropriate legal/about surface.

## Source-Level License Files

| File | Current role | Preservation requirement |
|------|--------------|--------------------------|
| `falkon/COPYING` | Top-level GPL license text for the inherited Falkon codebase. | Must remain in source distributions and release artifacts. |
| `falkon/.flatpak-manifest.json.license` | License metadata for Flatpak manifest handling. | Preserve unless packaging format is replaced with equivalent license metadata. |
| `falkon/themes/chrome/license.txt` | Theme license notice. | Preserve while theme assets or derivative theme assets remain bundled. |
| `falkon/themes/mac/license.txt` | Theme license notice. | Preserve while theme assets or derivative theme assets remain bundled. |

## In-App Legal/About Surfaces

| Surface | Current role | Preservation requirement |
|---------|--------------|--------------------------|
| `falkon/src/lib/other/aboutdialog.cpp` | About dialog implementation and attribution surface. | Later product about UI may become FSB-branded, but inherited acknowledgements/license access must remain reachable. |
| `falkon/src/lib/other/aboutdialog.h` | About dialog declaration. | Preserve legal/about access path or replace with equivalent FSB-owned surface. |
| `falkon/src/lib/other/aboutdialog.ui` | About dialog UI structure. | Update branding carefully; retain legal notice affordance. |
| `falkon/src/lib/other/licenseviewer.cpp` | License viewer implementation. | Preserve or replace with equivalent license viewing surface. |
| `falkon/src/lib/other/licenseviewer.h` | License viewer declaration. | Preserve or replace with equivalent license viewing surface. |

## Packaging And Metadata Surfaces

| Surface | Current legal sensitivity | Preservation requirement |
|---------|---------------------------|--------------------------|
| `falkon/linux/appdata/org.kde.falkon.appdata.xml` | KDE developer metadata and inherited product description. | Product metadata can be rebranded, but legal/developer attribution should move to a legal notice if removed from appstream metadata. |
| `falkon/src/main/version.rc` | `CompanyName=KDE` and Windows product metadata. | Rebrand company/product fields only after deciding where KDE/Falkon attribution appears. |
| `falkon/README.md` | Upstream project links and support references. | Product README can change, but source distribution should include upstream attribution and license guidance. |
| `falkon/mac/*deploy*`, `falkon/mac/create_dmg.*` | Bundling scripts for inherited app. | Release packaging must include required license files/notices. |

## Release Obligations To Carry Forward

- Keep GPL license text available with source and binary distributions.
- Keep source-availability guidance available for redistributed modified binaries.
- Keep Qt/KDE/Falkon/third-party notices available in an About, Licenses, or Legal Notices surface.
- Keep theme and bundled asset license notices when those assets remain bundled or are modified derivatives.
- Track any added Prometheus/FSB-owned assets separately so inherited and original notices are not conflated.

## Verification Commands

Run these checks before and after later rebrand phases:

```sh
test -f COPYING
find . -iname '*license*' -o -iname 'COPYING*'
rg -n "licenseviewer|aboutdialog|GPL|copyright|KDE|Falkon" src linux mac themes README.md COPYING
```

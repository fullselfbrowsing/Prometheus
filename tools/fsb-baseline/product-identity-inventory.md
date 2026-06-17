# Product Identity Inventory

**Phase:** 1 - Baseline and Legal Inventory  
**Captured:** 2026-06-16  
**Scope:** Product-visible Falkon/KDE/Qt identity surfaces to review before Phase 2 rebrand work.

## High-Priority Rebrand Targets

| Surface | Current identifiers | Notes |
|---------|---------------------|-------|
| `falkon/CMakeLists.txt` | `project(Falkon ...)`, `FALKON_INSTALL_PLUGINDIR`, `FALKON_PLUGIN_PATH` | Build-level names and plugin paths. Rename carefully because CMake variables may also act as internal API. |
| `falkon/src/main/Info.plist` | `org.kde.falkon`, `Falkon` | macOS bundle identifier and display strings. Primary macOS product identity target. |
| `falkon/src/main/version.rc` | `CompanyName=KDE`, `FileDescription=Falkon`, `InternalName=falkon`, `OriginalFilename=falkon.exe`, `ProductName=Falkon` | Windows version metadata. |
| `falkon/linux/applications/org.kde.falkon.desktop` | `Name=Falkon`, `Icon=falkon`, `Exec=falkon %u`, `StartupWMClass=Falkon` | Linux desktop identity and executable linkage. |
| `falkon/linux/appdata/org.kde.falkon.appdata.xml` | `org.kde.falkon.desktop`, KDE developer metadata, `Falkon` names/descriptions | Linux appstream metadata and public description. |
| `falkon/linux/hicolor/*-apps-falkon.*` | `falkon` icon asset names | Linux icon theme assets. |
| `falkon/logo.png` | Falkon logo asset | Top-level product logo. |
| `falkon/mac/create_dmg.sh`, `falkon/mac/create_dmg.scpt`, `falkon/mac/macdeploy.sh` | `Falkon`, `Falkon.app`, `Falkon.dmg`, `libFalkonPrivate` | macOS packaging and deploy identity. |
| `falkon/README.md` | Falkon/KDE project description, links, support channels | Product docs should become Prometheus-owned and mention "Powered by FSB" where appropriate, while preserving attribution elsewhere. |

## Medium-Priority Rebrand Targets

| Surface | Current identifiers | Notes |
|---------|---------------------|-------|
| `falkon/linux/completion/_falkon` | `#compdef falkon`, Falkon option descriptions | Shell completion should track executable rename. |
| `falkon/linux/completion/README.md` | `falkon`, `_falkon` | Shell completion docs. |
| `falkon/themes/*/metadata.desktop` | `X-Falkon-Type`, `X-Falkon-Author`, `X-Falkon-License`, comments mentioning Falkon | Some keys may be internal plugin/theme API and may need compatibility aliases. |
| `falkon/src/main/falkonversion.h.cmake` | Generated `falkonversion.h` naming | Build include naming may be internal. |
| `falkon/src/lib/notifications/desktopnotificationsfactory.cpp` | Notification app name `Falkon`, temp image `falkon_notif.png` | User-visible notification identity. |
| `falkon/src/lib/session/*.h`, `*.cpp` | Header comments `Falkon - Qt web browser` | Source comments can remain until legal attribution policy is decided. |

## Legal-Attribution-Sensitive Surfaces

These mention Falkon/KDE/Qt and should not be blindly deleted during rebrand:

- `falkon/COPYING`
- `falkon/src/lib/other/aboutdialog.*`
- `falkon/src/lib/other/licenseviewer.*`
- `falkon/.flatpak-manifest.json.license`
- `falkon/themes/chrome/license.txt`
- `falkon/themes/mac/license.txt`

## Phase 2 Notes

- Rebrand user-visible app identity first: app name `Prometheus`, "Powered by FSB" affiliation/tagline, bundle IDs, desktop files, icons, appstream metadata, window/about surfaces, and docs intended for this product.
- Preserve compatibility names only when they are required by plugin paths, CMake target names, or migration from the inherited profile/config layout.
- Do not remove required legal attributions. Move them to a legal/about surface if they no longer belong in product marketing copy.

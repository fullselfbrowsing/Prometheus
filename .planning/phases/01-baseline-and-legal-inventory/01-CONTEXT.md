# Phase 1: Baseline and Legal Inventory - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 establishes a reliable baseline for the local Falkon-derived browser before any visible rebrand or agent-control work. It should prove what can be built and smoked on this workstation, and it should inventory inherited product identity and legal surfaces without changing them yet.

</domain>

<decisions>
## Implementation Decisions

### Baseline Validation
- Keep Phase 1 non-invasive: add repeatable validation tooling and documentation, but do not rename Falkon symbols or modify user-facing product identity yet.
- Treat missing local build dependencies as a blocker that must be reported with exact evidence, not papered over as a passing build.
- Use macOS as the initial validation target, matching the project assumption in `.planning/PROJECT.md`.
- Prefer scripts that fail fast and print remediation details over scripts that attempt large system installs.

### Inventory Scope
- Inventory product-visible strings, bundle IDs, desktop IDs, executable names, icons, packaging files, theme metadata, default docs, and appdata metadata.
- Inventory legal artifacts separately from rebrand targets so Phase 2 can remove product branding without deleting required GPL/KDE/Qt/Falkon notices.
- Preserve inherited legal notices and about/license viewer code as canonical legal surfaces for later rebrand work.
- Include generated inventory artifacts under `falkon/tools/fsb-baseline/` so they live near the fork they describe.

### Smoke Coverage
- Define the smoke path as launch, open a URL, navigate to a second URL, request a new tab/window action through command-line supported surfaces where possible, and exit cleanly.
- If the binary is not present, the smoke script must fail with a clear build prerequisite message.
- Do not require network-only pages for smoke validation; local or `data:` pages are acceptable when supported.
- Record the exact binary path and output logs when smoke is run.

### the agent's Discretion
Implementation details for shell script structure, inventory formatting, and local build directory naming are at the agent's discretion, as long as the outputs are repeatable and Phase 2 can consume them.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `falkon/CMakeLists.txt` defines the current Qt6/KF6 browser build, project name `Falkon`, plugin directory variables, and mandatory dependencies.
- `falkon/src/main/Info.plist`, `falkon/src/main/version.rc`, `falkon/linux/applications/org.kde.falkon.desktop`, and `falkon/linux/appdata/org.kde.falkon.appdata.xml` are primary packaging identity surfaces.
- `falkon/src/lib/other/aboutdialog.*` and `falkon/src/lib/other/licenseviewer.*` are primary legal/about UI surfaces.

### Established Patterns
- The fork is a CMake/KDE/QtWebEngine project with source under `falkon/src`.
- The top-level workspace has a root Git repo for planning, while `falkon/` is a separate nested Git checkout.
- The local machine currently lacks `cmake`, `ninja`, and `qmake` on PATH.

### Integration Points
- Later rebrand phases should consume `falkon/tools/fsb-baseline/product-identity-inventory.md`.
- Legal preservation and release phases should consume `falkon/tools/fsb-baseline/legal-notice-inventory.md`.
- Build and smoke validation should run through `falkon/tools/fsb-baseline/preflight.sh` and `falkon/tools/fsb-baseline/smoke-browser.sh`.

</code_context>

<specifics>
## Specific Ideas

User steer received during Phase 1: the browser product name is Prometheus, with "Powered by FSB" as the affiliation/tagline. Use that for Phase 2 product identity work while preserving inherited GPL and third-party notices.

</specifics>

<deferred>
## Deferred Ideas

- Installing Homebrew/KDE/Qt dependencies automatically is deferred; this phase should report the missing tools and leave system package installation to a deliberate user action.
- Renaming product identifiers is deferred to Phase 2.
- Native agent control is deferred to Phase 3.

</deferred>

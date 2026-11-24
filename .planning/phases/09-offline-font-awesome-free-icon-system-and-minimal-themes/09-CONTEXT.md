# Phase 9 Context: Offline Font Awesome Free Icon System and Minimal Themes

## User Steer

Prometheus should use offline free Font Awesome icons natively, keep themes super minimal, and avoid depending on network assets or inconsistent host icon themes.

## Research Summary

Font Awesome Free is GPL-friendly, with SVG/JS icons under CC BY 4.0, fonts under SIL OFL 1.1, and code under MIT. Attribution comments and license metadata must be preserved.

Local code already uses `falkon/src/lib/data/icons.qrc`, bundled icons, inherited theme assets, and many `QIcon::fromTheme` calls. That creates inconsistent icon availability across environments unless Prometheus provides deterministic bundled fallbacks.

## Planning Targets

- Vendor a curated Font Awesome Free SVG subset into Qt resources with license metadata.
- Add a central Prometheus icon resolver and action-to-icon map.
- Replace primary UI `QIcon::fromTheme` dependencies with deterministic bundled fallbacks.
- Simplify themes around restrained native surfaces, clear state, and minimal accents.
- Validate icon presence, attribution, packaging, readability, and no network dependency.


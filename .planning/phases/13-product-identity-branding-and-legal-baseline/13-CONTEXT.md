# Phase 13: Product Identity, Branding, and Legal Baseline - Context

**Gathered:** 2026-06-23
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous) — all 4 grey areas accepted as recommended

<domain>
## Phase Boundary

Make the built Chromium app identify as **Prometheus** while preserving every required attribution, and establish the legal/notice baseline — without copying GPL Falkon source into the Chromium tree.

In scope for this phase:
- Chromium product-identity override (app name, window title, macOS app menu + Dock, bundle identity, About/version) via tracked Chromium patches.
- A legal/about notice baseline (Chromium + third-party + Font Awesome / Poppins / Space Mono / FSB) authored in full.
- A product-identity inventory (Chromium equivalent of the v1 Falkon inventory) and a legal-notice inventory.
- README / release-doc language updated from Falkon/QtWebEngine to "Chromium-based agent-native browser".
- A lightweight guard that rejects GPL Falkon C++ entering the Chromium source tree.

Explicitly NOT in this phase (owned later):
- The compact browser chrome / tab UI → Phase 15.
- The themed Prometheus WebUI surfaces (start page, side panel, themed About page) → Phase 16.
- Asset/font resource porting into Chromium resource format → Phase 14.
- Exhaustive `chrome://` internal-string de-Chromium sweep + de-Falkon gate → Phase 23.
- Notarization / Team ID / packaged-notice validation → Phase 24.
</domain>

<decisions>
## Implementation Decisions

### Area 1 — Chromium Branding Override Strategy
- Override Chromium identity by patching the existing `chrome/app/theme/chromium/BRANDING` file **in place** via a tracked `git format-patch` (Chromium builds the `chromium` brand by default; reuses the Phase-12 patch/rebase discipline). Do NOT fork a separate brand dir or do runtime string substitution.
- Set `MAC_BUNDLE_ID=com.fullselfbrowsing.prometheus` in BRANDING (matches the v1 bundle id, satisfies BRAND-06 by not colliding with installed `org.chromium.Chromium` profiles/apps).
- Patch user-facing product-name strings in `chrome/app/chromium_strings.grd` (e.g. IDS_PRODUCT_NAME and related) to Prometheus — BRANDING alone is insufficient for menu/title strings.
- Defer macOS Team ID and notarization to Phase 24 (packaging); leave the Chromium Creator Code at its default for now.

### Area 2 — De-Chromium Scope & Boundaries
- Phase 13 de-Chromiums only the **high-visibility identity surfaces**: app/bundle name, window title, macOS app menu + Dock, and About/version. The exhaustive `chrome://` internal-page string sweep is deferred to Phase 23 (de-Falkon / parity gate).
- Suppress the stock Chromium first-run/welcome so no "Chromium" first-run branding shows; the Prometheus start page (Phase 16) becomes the real first-run surface. Do not patch `chrome://welcome` strings in this phase.
- Intentionally preserve the "Chromium" name where attribution is required: `about:version`, `chrome://credits`, and the legal/about notices (BRAND-03 explicitly allows upstream attribution where legally required).
- Add a lightweight **tracked static guard now** that fails if GPL Falkon C++ appears in the Chromium source tree (reinforces the Phase 11/12 license boundary; satisfies BRAND-05). The deeper de-Falkon gate remains Phase 23.

### Area 3 — Legal / About Surface (BRAND-04)
- Generate notices by reusing Chromium's existing `about_credits` / `chrome://credits` tooling for Chromium + third-party licenses, then **append a Prometheus-owned NOTICES section** for Font Awesome (CC BY 4.0 + SIL OFL 1.1 fonts + MIT code), Poppins (OFL), Space Mono (OFL), and FSB-owned material.
- For this phase: author the legal notice content in full and wire a **minimal** Prometheus "About" identity (name / version / "Powered by FSB" linking to credits). The richer themed About WebUI page is deferred to Phase 16.
- Author the **complete** notice set now (this is the legal-baseline phase); Phase 24 validates the notices actually ship in the package.
- Apply the verbatim tagline **"Powered by FSB"** to the About/legal surface and README now. Reserve — but do NOT build — the side-panel and start-page "Powered by FSB" slots, which phases 15 and 16 own.

### Area 4 — Product Identity Inventory & Docs
- Author a product-identity inventory that **mirrors the v1 Falkon `product-identity-inventory.md` structure**, adapted to Chromium surfaces (BRANDING fields, `.grd` strings, `Info.plist`, app icon, `chrome://` identity surfaces), plus a legal-notice-inventory equivalent.
- Location: `.planning/chromium/PRODUCT-IDENTITY-INVENTORY.md` (beside `CHROMIUM-CHECKOUT.md`), with the legal-notice inventory alongside.
- The inventory records **both** the upstream Chromium value and the Prometheus override per surface, so rebases can detect identity drift (ties to Phase 12 patch discipline).
- Update the root README and release docs now: replace Falkon/QtWebEngine language with "Chromium-based agent-native browser" (BRAND-07).

### Claude's Discretion
- Exact patch file organization, the specific IDS_* message ids to override, the precise inventory table columns, and the mechanism for suppressing the welcome screen are at the planner's/executor's discretion, provided the decisions above and the success criteria are met.
</decisions>

<code_context>
## Existing Code Insights

### Locked identity facts (reuse — do not re-derive)
- Product name **Prometheus**; affiliation tagline **"Powered by FSB"** (locked Phase 2).
- Bundle id pattern **com.fullselfbrowsing.prometheus** (v1-verified at `build/fsb-baseline/bin/prometheus.app`).
- FSB orange primary accent **#ff6b35**, gradient end **#ff8c42**; full dark/light palette in `.planning/design/DESIGN-REFERENCE.md`.
- Fonts: **Poppins** (100/300/800/900) + **Space Mono**, bundled offline (OFL). Body = system stack.
- Brand marks: PM monogram (`P` Poppins Thin + `M` Poppins Black + `▽0.1` Space Mono), Prometheus wordmark, app icon (rounded square, 24% radius, 128/80/48). Source of truth: `.planning/design/prometheus-brand/Prometheus Logo.html`.

### Chromium branding surfaces (baseline, unmodified)
- `.context/chromium/src/chrome/app/theme/chromium/BRANDING` — fields: `COMPANY_FULLNAME`/`COMPANY_SHORTNAME` = "The Chromium Authors", `PRODUCT_FULLNAME`/`PRODUCT_SHORTNAME` = "Chromium", `COPYRIGHT`, `MAC_BUNDLE_ID=org.chromium.Chromium`, `MAC_CREATOR_CODE=Cr24`, `MAC_TEAM_ID=` (empty).
- `chrome/app/chromium_strings.grd` — Chromium-visible product strings (the `google_chrome_strings.grd` variant is not built for this brand).
- Chromium baseline pinned at `0e8499df5172f55d0d29e2b92ef7e6a704529578`; patch-branch convention `prometheus/phase-13-branding`; `git format-patch` export from the pinned baseline (per `.planning/chromium/CHROMIUM-CHECKOUT.md`).

### License / legal rules already set
- License boundary (`.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md`): do NOT copy GPL Falkon C++/Qt/QSS/packaging into Chromium without explicit license review; reimplement behavior natively.
- Required attribution: Font Awesome Free (CC BY 4.0 art / OFL 1.1 fonts / MIT code, comments preserved in bundled SVGs), Poppins (OFL 1.1 + OFL.txt), Space Mono (OFL 1.1 + OFL.txt).
- v1 reference bundle preserved at `.context/falkon-preservation/falkon-prometheus-v1.bundle`.

### v1 inventory to mirror
- v1 produced `falkon/tools/fsb-baseline/product-identity-inventory.md` and `legal-notice-inventory.md` (Phase 1 outputs) tracking: product-visible strings, bundle IDs, desktop IDs, executable names, icons, packaging files, theme metadata, default docs, appdata metadata, legal artifacts.

### Integration points
- Patches live under the Chromium checkout `.context/chromium/src` and are exported/tracked per Phase-12 discipline; planning-owned scripts live under `.planning/chromium/`.
- Phase-12 gate scripts (`check-chromium-env.sh`, `build-chromium-baseline.sh`, `smoke-launch-unmodified.sh`, `verify-artifact-isolation.sh`) remain the build/launch/isolation gates; identity changes must still pass them.
</code_context>

<specifics>
## Specific Ideas

- Tagline text is exactly "Powered by FSB" (verbatim).
- Bundle id is exactly `com.fullselfbrowsing.prometheus`.
- Keep the Phase-12 artifact-isolation and rebase discipline intact: branding changes to the Chromium tree must be tracked as exportable patches, and the root git must continue to ignore the checkout.
- README must describe Prometheus as a "Chromium-based agent-native browser" (BRAND-07 wording).
</specifics>

<deferred>
## Deferred Ideas

- Themed Prometheus "About" WebUI page with full brand treatment → Phase 16 (WebUI surfaces).
- Side-panel and start-page "Powered by FSB" placements → phases 15 / 16.
- Asset/font porting into Chromium resource format → Phase 14.
- Exhaustive `chrome://` internal-string de-Chromium sweep + de-Falkon enforcement gate → Phase 23.
- macOS Team ID, notarization, and packaged-notice validation → Phase 24.
</deferred>

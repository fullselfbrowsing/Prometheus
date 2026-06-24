# Chromium Legal Notice Inventory

**Created:** 2026-06-24
**Milestone:** v2.0 Chromium Engine Migration
**Status:** Phase 13 complete — NOTICES.md authored. Records all Chromium-era legal surfaces,
notice files, third-party assets, and release obligations.

---

## Required Preservation Rule

Chromium is distributed under the BSD 3-Clause license, with additional third-party library
attributions required by the bundled dependencies. These attributions must remain reachable
via `chrome://credits` in the built browser. Prometheus branding overrides product-visible
identity surfaces but must not remove, weaken, or obscure any Chromium or third-party
attribution obligation.

Prometheus-owned notices (Font Awesome, Poppins, Space Mono, FSB material) must be present
in `NOTICES.md` at the repository root and must ship with any release artifact.

GPL Falkon source must not appear in the Chromium tree without explicit license review. See
`check-falkon-gpl-guard.sh` for the static guard script that enforces this boundary before
each Prometheus-branch commit.

---

## Source-Level Notice Files (This Repo)

| File | Role | Status |
|------|------|--------|
| `NOTICES.md` | Prometheus-owned notices for Font Awesome, Poppins, Space Mono, and FSB material; includes Chromium attribution pointer and verbatim "Powered by FSB" tagline | Authored Phase 13 |
| `LICENSES/poppins-OFL.txt` | Full SIL Open Font License 1.1 text for the Poppins typeface | Placeholder — Phase 14 drops Poppins font files and this license text together |
| `LICENSES/spacemono-OFL.txt` | Full SIL Open Font License 1.1 text for the Space Mono typeface | Placeholder — Phase 14 drops Space Mono font files and this license text together |

---

## Chromium In-Tree Legal Surfaces

| Surface | Role | Phase 13 action |
|---------|------|-----------------|
| `chrome://credits` | Chromium BSD-3-Clause and all bundled third-party open source licenses, rendered as an HTML page by `tools/licenses/licenses.py` | Preserved as-is. Sample page shown until `generate_about_credits=true` is wired (deferred to Phase 24). Real credits remain accessible via rebuild with `generate_about_credits=true`. |
| `about:version` | Browser attribution page; shows company name, version, and copyright string | `IDS_ABOUT_VERSION_COMPANY_NAME` set to "Full Self Browsing"; `IDS_ABOUT_VERSION_COPYRIGHT` includes "Powered by Chromium — see chrome://credits for attributions" to preserve dual attribution per BRAND-03. |

---

## Third-Party Assets (Prometheus-Owned)

| Asset | License | Notice location |
|-------|---------|-----------------|
| Font Awesome Free 6.x | Icons: CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/ — Fonts: SIL OFL 1.1 — https://scripts.sil.org/OFL — Code: MIT — https://opensource.org/licenses/MIT | `NOTICES.md` section "Font Awesome Free"; attribution comments preserved in each bundled SVG file |
| Poppins | SIL Open Font License 1.1 | `NOTICES.md` section "Poppins"; full license text at `LICENSES/poppins-OFL.txt` (Phase 14) |
| Space Mono | SIL Open Font License 1.1 | `NOTICES.md` section "Space Mono"; full license text at `LICENSES/spacemono-OFL.txt` (Phase 14) |

---

## Release Obligations

- `NOTICES.md` must be included in any release artifact. Phase 24 validates that the
  packaging step includes this file and that all required sections are present.
- `chrome://credits` must be reachable in the built browser. The Chromium default behavior
  satisfies this; the sample page shown with `generate_about_credits=false` is replaced by
  full credits when `generate_about_credits=true` is set and `gn gen` is rerun.
- "Powered by Chromium" attribution must appear in legal surfaces. Currently fulfilled by
  the `IDS_ABOUT_VERSION_COPYRIGHT` override and the NOTICES.md Chromium attribution line.
- Font Awesome SVG attribution comments must not be stripped by any asset pipeline or
  minification step. Phase 14 and Phase 24 must verify this when the SVG subset is ported
  to Chromium resource format.
- GPL Falkon implementation source must not appear in the Chromium tree. Enforced by
  `.planning/chromium/check-falkon-gpl-guard.sh` as a pre-commit gate.

---

## Verification Commands

```bash
# Verify Prometheus-owned notices are present and complete
grep -q "Powered by FSB" NOTICES.md \
  && echo "OK: Powered by FSB present" \
  || echo "FAIL: Powered by FSB missing"

grep -q "CC BY 4.0" NOTICES.md \
  && echo "OK: Font Awesome CC BY 4.0 notice present" \
  || echo "FAIL: Font Awesome CC BY 4.0 missing"

grep -q "Space Mono" NOTICES.md \
  && echo "OK: Space Mono notice present" \
  || echo "FAIL: Space Mono missing"

grep -q "chrome://credits" NOTICES.md \
  && echo "OK: Chromium attribution pointer present" \
  || echo "FAIL: chrome://credits reference missing"

# Verify GPL guard passes (no Falkon GPL source in Prometheus Chromium dirs)
bash .planning/chromium/check-falkon-gpl-guard.sh

# Verify Chromium attribution in built app (requires completed Prometheus build)
if [ -f .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist ]; then
  plutil -p .context/chromium/src/out/Default/Prometheus.app/Contents/Info.plist \
    | grep -q "com.fullselfbrowsing.prometheus" \
    && echo "OK: CFBundleIdentifier correct" \
    || echo "FAIL: CFBundleIdentifier mismatch"
else
  echo "INFO: Prometheus.app not yet built — identity check deferred"
fi
```

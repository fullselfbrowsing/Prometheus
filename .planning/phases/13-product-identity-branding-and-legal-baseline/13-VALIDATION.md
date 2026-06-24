---
phase: 13
slug: product-identity-branding-and-legal-baseline
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-23
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Populated by the planner as plans are created; rows map each task to a verifiable identity/legal check.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash gate scripts + grep/plutil assertions (no app unit-test harness; identity surfaces verified via built `.app` introspection) |
| **Config file** | none — gates live under `.planning/chromium/` |
| **Quick run command** | `bash .planning/chromium/verify-artifact-isolation.sh` |
| **Full suite command** | branding verify gate (authored this phase) + Phase 12 env/build gates |
| **Estimated runtime** | ~seconds (verification); rebuild after BRANDING/.grd change ~5–20 min (is_component_build) |

---

## Sampling Rate

- **After every task commit:** Run the relevant gate (`verify-artifact-isolation.sh`, or `bash -n` on authored scripts)
- **After every plan wave:** Re-run the branding verify gate + isolation gate
- **Before `/gsd-verify-work`:** Branding gate green; built `Prometheus.app` shows Prometheus identity
- **Max feedback latency:** seconds (excluding the one branding rebuild)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _populated by planner_ | | | BRAND-0x | | | | | | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Branding verify gate script (asserts `Prometheus.app`, `CFBundleIdentifier=com.fullselfbrowsing.prometheus`, app-menu/product strings)
- [ ] Falkon-source guard script (fails on GPL Falkon C++/Qt signatures in `.context/chromium/src`)

*Existing Phase 12 gates (env/build/isolation) cover build + isolation requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App menu / window title visibly read "Prometheus" | BRAND-01 | GUI-only string at runtime | Launch built app; confirm macOS app menu + window title say Prometheus, not Chromium |
| "Powered by FSB" visible on about/legal surface | BRAND-02 | rendered surface | Open the about/legal surface; confirm verbatim "Powered by FSB" |

*Remaining behaviors (bundle id, notices in source, inventory, README) have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (branding rebuild is the one slow step)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

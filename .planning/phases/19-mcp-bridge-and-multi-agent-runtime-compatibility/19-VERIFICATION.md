---
phase: 19
slug: mcp-bridge-and-multi-agent-runtime-compatibility
status: passed
score: "7/7 requirements verified"
verified: 2026-07-13
chromium_head: 460caac2f9e7deecd9fa6294c41d13e5a6dd6115
human_uat: not_run
manual_dependency: none
high_severity_threats_open: 0
---

# Phase 19 Verification

## Result

Phase 19 passed automated verification at nested Chromium HEAD
`460caac2f9e7deecd9fa6294c41d13e5a6dd6115`.

An external MCP host can spawn the dependency-free Prometheus Node bridge,
which discovers an owner-only browser descriptor, creates or explicitly
resumes a browser-issued session, and calls the authenticated IPv4-loopback
gateway. The bridge exposes the exact 90-name compatibility inventory and
never bundles or launches a third-party agent CLI, terminal, runtime, engine,
prompt provisioner, or `CLAUDE.md` integration.

No human UAT was run. Phase 19 has no manual acceptance dependency; the
separate human visual review remains a non-blocking Phase 24 release check.

## Requirement Coverage

| Requirement | Status | Automated evidence |
|-------------|--------|--------------------|
| MCP-01 | VERIFIED | The live smoke initializes the separately spawned stdio bridge against a real built Prometheus app, owner-only descriptor, browser-issued session, and authenticated gateway. Node tests cover supported MCP versions, both framing modes, bounded parsing, cancellation, EOF, signals, clean graceful exits, protocol-only stdout, and full in-memory response privacy scans. |
| MCP-02 | VERIFIED | `tools/list` returns exactly 90 names. All 22 native names and eight aliases dispatch only through the closed native route set. Twenty-two typed stubs, 36 later-phase tools, and two removed tools return deterministic compatibility errors without browser contact or false success. |
| MCP-03 | VERIFIED | Real browser and live-smoke tests cover tabs, background navigation, page reads, text, present-empty and missing attributes, full/compact snapshots, snapshot-derived refs, exact child-frame routing, and restricted-frame denial. Runtime, memory, vault, provider, and supervision reads remain honest `NOT_READY` results owned by Phases 20 or 21. |
| MCP-04 | VERIFIED | Every subset of `visual_reason`, `client`, and `is_final` survives native and alias translation independently. Bounds and badge normalization are enforced, and the fields cannot supply identity, ownership, authentication, or log content. |
| MCP-05 | VERIFIED | Unsupported, unavailable, later-phase, and removed tools return stable codes, owner phase where applicable, replacements, and recovery guidance. `start_visual_session` and `end_visual_session` remain discoverable removed calls with migration metadata. |
| MCP-06 | VERIFIED | Authenticated health returns exactly `browser`, `bridge`, `active_tab`, `content_adapter`, `internal_adapter`, `webui_adapter`, `vault`, `provider`, `supervision`, and `extensions`. Later systems report `not_ready`; bearer, descriptor, session, profile, page, script, and visual-reason data are absent. |
| MCP-07 | VERIFIED | Unit, browser, and live tests cover two-session caps and ownership, background focus preservation, stable handles after reorder, graceful close, abrupt expiry, exact-tab authority after opaque resume, fresh-session denial, expired-resume rejection, post-expiry release, bounded closed/expired metadata churn, numeric bounds, visual subsets, diagnostics, and exactly-once shutdown. |

## Compatibility Inventory

The frozen v1 fixture has 46 names, the current FSB fixture has 59, and their
15-name overlap produces a 90-name union. Every name has exactly one
disposition:

| Disposition | Count | Behavior now |
|-------------|------:|--------------|
| `native` | 22 | Calls a closed Chromium-native route. |
| `alias` | 8 | Normalizes to one of the closed native routes. |
| `typed_stub` | 22 | Returns explicit unsupported/not-ready guidance. |
| `later_phase` | 36 | Returns `NOT_READY` with Phase 20 or 21 ownership. |
| `removed` | 2 | Returns `TOOL_REMOVED` with replacement metadata. |

Inventory evidence is in `phase19-07-manifest-inventory.log`; Node and live
smoke evidence independently confirm that all 90 names are discoverable and
that non-native dispositions cannot reach the browser.

## Security and Lifecycle Findings

| Threat | Result | Evidence |
|--------|--------|----------|
| Local endpoint theft or remote exposure | PASS | Gateway binds only to `127.0.0.1` on an ephemeral port. Every one of six closed endpoints requires the process-fresh bearer; Host, Origin, method, content type, body, concurrency, and timeout checks fail closed. Descriptor publication is atomic beneath an owner-only directory with mode `0600`. |
| Cross-profile or cross-session confused deputy | PASS | Session creation is regular-profile keyed, off-the-record creation is denied, caller labels carry no authority, tab mutations require ownership, and a second live session receives `TAB_NOT_OWNED`. |
| Schema coercion or route injection | PASS | Manifest-backed schemas reject unknown fields, conflicting target aliases, invalid numbers, and undeclared routes; numeric coercion is limited to declared bounded integer fields. |
| Immortal or orphaned ownership | PASS | Three-second heartbeat, explicit graceful close, opaque resume inside ten seconds, expiry cleanup, and exactly-once shutdown are covered through real gateway/browser paths and the live smoke. |
| Secrets or content in protocol diagnostics/logs | PASS | Output and audit denylist gates exclude bearer, nonce, session id, profile path, page body, scripts, visual reason, and credentials. stdout remains JSON-RPC only. |
| False compatibility claims | PASS | The 90-name union is closed and exactly mapped. Deferred and unsupported tools return explicit structured errors; later Phase 20–22 systems remain unclaimed. |
| Embedded third-party runtime returns | PASS | Static audit scanned 65 production files and found no third-party executable spawn, terminal/shell UI, engine selector, prompt provisioner, `CLAUDE.md` provisioner, or bundled runtime dependency. The only root `child_process` use is the test smoke client spawning the Prometheus-owned bridge. |

No high-severity threat remains open.

## Gate Evidence

Every cited log is under `.context/chromium/src/out/Default/` and ends with
`EXIT_CODE=0`.

| Gate | Fresh result | Log |
|------|--------------|-----|
| Chromium build | PASS; `chrome`, `browser_tests`, `prometheus_unittests`, and `prometheus_action_dispatcher_unittests` | `phase19-07-build.log` |
| Root Node suite | PASS; 64/64, zero fail/cancelled/skipped/TODO | `phase19-07-node-tests.log` |
| Focused native units | PASS; 34/34 | `phase19-07-focused-units.log` |
| Renderer units | PASS; 7/7 | `phase19-07-renderer-units.log` |
| Phase 19 browser inventory | PASS; 32/32 serial | `phase19-07-phase19-browser.log` |
| Phase 17/18 regression | PASS; 53/53 serial | `phase19-07-phase17-18-regression.log` |
| Built-browser-to-stdio smoke | PASS | `phase19-07-live-smoke.log` |
| 90-name disposition inventory | PASS; 90/90 | `phase19-07-manifest-inventory.log` |
| Exact-range patch inventory | PASS; 19 commits, 19 nonempty source-only patches | `phase19-07-patch-inventory.log` |
| No-embedded-runtime/security boundary | PASS; 65 production files | `phase19-07-static-boundary-audit.log` |
| README/document consistency | PASS; no obsolete readiness or human-UAT claim | `phase19-07-doc-consistency.log` |
| Chromium environment | PASS | `phase19-07-check-chromium-env.log` |
| Falkon GPL guard | PASS | `phase19-07-check-falkon-gpl-guard.log` |
| Artifact isolation | PASS | `phase19-07-verify-artifact-isolation.log` |
| Preservation | PASS | `phase19-07-verify-preservation.log` |
| Root diff check | PASS | `phase19-07-root-diff-check.log` |
| Nested diff check | PASS | `phase19-07-nested-diff-check.log` |

The macOS live fixture uses `--use-mock-keychain` for its disposable profile
and narrowly disables Chromium's local-network permission checks so the local
test fixture is reachable in this Chromium revision. It also uses
`--no-proxy-server`. The real Network Service, renderer sandbox, authenticated
gateway, descriptor permissions, session lifecycle, and process boundary all
remain active.

## Patch and Preservation Evidence

Nineteen nonempty source-only patches were exported from the exact nested range
`caae2f6a81..460caac2f9`. The first commit follows the Phase 18 verified tip,
and the count matches all 19 Phase 19 nested commits. Generated output is not
present in the patch series.

The preservation dossier records only Phase 19's external stdio/native MCP
compatibility evidence. Phase 20 still owns runtime, providers, vault, memory,
logs, and live control-panel data; Phase 21 still owns supervision and pairing;
Phase 22 still owns extension health and policy.

## Manual Verification

None. Human UAT and screenshots were intentionally not run and are not
represented as passed.

## Final Status

`status: passed`

All seven MCP requirements are satisfied with automated evidence at Chromium
HEAD `460caac2f9`. Phase 19 may be marked complete and Phase 20 may become
current.

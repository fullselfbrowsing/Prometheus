---
phase: 19
slug: mcp-bridge-and-multi-agent-runtime-compatibility
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-12
---

# Phase 19 — Validation Strategy

Per-phase automated validation contract for the clean-room MCP catalog, native
route gateway, profile/session/ownership lifetime, and external stdio bridge.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | Node 20 built-in `node:test`; Chromium GTest unit tests; `InProcessBrowserTest`; shell/Node live smoke. |
| **Node tests** | `tools/prometheus-mcp/test/*.test.mjs` (created in Wave 0). |
| **C++ targets** | `prometheus_unittests`, `prometheus_action_dispatcher_unittests`, and Prometheus sources in `browser_tests`. |
| **Quick Node command** | `node --test tools/prometheus-mcp/test/*.test.mjs` |
| **Quick C++ command** | `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='*PrometheusAgentTransport*:*PrometheusAgentSession*:*PrometheusCompatibility*'` |
| **Focused browser command** | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*Prometheus*Mcp*:*Prometheus*Gateway*:*Prometheus*ElementRead*:*PrometheusAgentService*' --test-launcher-jobs=1` |
| **Full phase command** | Build `browser_tests prometheus_unittests prometheus_action_dispatcher_unittests`; run all Node tests, focused Prometheus unit/renderer/browser tests, then `bash tools/prometheus-mcp/smoke-browser.sh`. |
| **Estimated runtime** | Node tests under 15 seconds; focused C++ units under 90 seconds; browser/live smoke several minutes after an incremental build. |

## Sampling Rate

- **After every task commit:** Run the most focused Node or C++ unit filter for
  the modified contract, plus `git diff --check` in the owning repository.
- **After every plan wave:** Run all Phase 19 Node tests and the focused C++
  unit/browser filters whose files now exist.
- **Before phase verification:** Build all three targets; run Node, unit,
  renderer, browser, live smoke, Phase 17/18 regression, environment, GPL,
  artifact-isolation, preservation, no-embedded-runtime, and diff gates.
- **Max feedback latency:** Keep pure Node/codec/session feedback below 90
  seconds; no three consecutive implementation tasks may land without an
  automated test command.

## Requirement Verification Map

| Requirement | Planned behavior | Threat Ref | Secure behavior | Test type | Automated command | File exists | Status |
|-------------|------------------|------------|-----------------|-----------|-------------------|-------------|--------|
| MCP-01 | External MCP host launches a standards-compliant stdio bridge that creates a browser-issued session and reaches the real Chromium service. | T-19-01 / T-19-02 / T-19-07 | Loopback-only, authenticated native hop; external adapter never launches an agent CLI/runtime. | Node + browser + live smoke | `node --test tools/prometheus-mcp/test/transport.test.mjs && bash tools/prometheus-mcp/smoke-browser.sh` | ✅ | passed |
| MCP-02 | Compatible tab/navigation/page/action names and aliases call native routes; unsupported coordinate/mutation names stay discoverable with typed guidance. | T-19-03 / T-19-06 | Closed manifest disposition and native allowlist; no arbitrary route or false-success fallback. | Node + C++ unit + browser | `node --test tools/prometheus-mcp/test/catalog.test.mjs tools/prometheus-mcp/test/tools.test.mjs` | ✅ | passed |
| MCP-03 | Page/text/attribute/snapshot/tab reads work; later runtime/memory/site-guide reads return truthful typed owner results. | T-19-03 / T-19-05 / T-19-06 | Exact frame/ref, bounded output, restricted-frame no-fallback, and no secret-bearing Node synthesis. | C++ unit + renderer + browser + Node | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*Prometheus*ElementRead*:*Prometheus*Page*' --test-launcher-jobs=1` | ✅ | passed |
| MCP-04 | Optional `visual_reason`, `client`, and `is_final` survive aliases and the native envelope. | T-19-03 / T-19-05 | Fields are bounded presentation metadata, supplied badges are normalized/allowlisted, and reason content never enters audit/logs. | Node + C++ unit + browser | `node --test tools/prometheus-mcp/test/visual-session.test.mjs` | ✅ | passed |
| MCP-05 | Changed, unavailable, and removed tools return stable compatibility codes, replacements, owner phase, and recovery. | T-19-06 | No name disappears and no deferred capability returns empty success. | Node fixture + C++ codec | `node --test tools/prometheus-mcp/test/catalog.test.mjs tools/prometheus-mcp/test/errors.test.mjs` | ✅ | passed |
| MCP-06 | Diagnostics report all ten required layers with honest closed states and no token/content/secret leakage. | T-19-01 / T-19-05 / T-19-06 | Authenticated bounded health; later systems remain `not_ready`; token/profile paths/page data absent. | C++ unit + browser + Node | `node --test tools/prometheus-mcp/test/diagnostics.test.mjs` | ✅ | passed |
| MCP-07 | Lifecycle, cap, resume/grace, ownership, background targeting, numeric coercion, visual compatibility, and recovery are regression-tested. | T-19-02 / T-19-03 / T-19-04 | Opaque session authority, orphan-owner cleanup, stable handles, exact numeric bounds, and active-tab non-theft. | Node + C++ unit + browser + live smoke | `node --test tools/prometheus-mcp/test/*.test.mjs` plus focused Phase 19 browser filters | ✅ | passed |

## Threat References

| Ref | Threat | Required mitigation |
|-----|--------|---------------------|
| T-19-01 | Local endpoint token theft, DNS rebinding, or remote interface exposure | IPv4 loopback-only bind, mode-0600 nonce descriptor, bearer on every endpoint, Host/Origin/method/content/body/concurrency checks, no token in health/log/audit. |
| T-19-02 | Session becomes a cross-profile/incognito confused deputy | Regular-profile keyed service, profile pinned at session creation, OTR denial, stable browser/tab identity. |
| T-19-03 | Schema coercion, alias conflict, or arbitrary-route injection | Data-driven closed manifest, strict JSON schemas, declared numeric coercion only, double bounds in Node/C++, conflicting target rejection. |
| T-19-04 | Abrupt bridge loss leaves immortal sessions or orphaned tab ownership | Heartbeat, 10-second opaque resume grace, graceful close, expiry cleanup, exactly-once shutdown. |
| T-19-05 | Page, prompt, visual reason, token, profile path, or secret leaks through diagnostics/audit/errors | Physically separate bounded result payloads, audit denylist, closed diagnostic fields, content-free errors/logs. |
| T-19-06 | False compatibility or capability claims | All 90 union names mapped once; explicit unsupported/later/removed results with owner/replacement/recovery; no empty success. |
| T-19-07 | External MCP support reintroduces an embedded third-party agent runtime | Static/process tests prohibit Claude/agent CLI spawning, terminal surface, engine selector, CLAUDE.md provisioning, and third-party runtime dependencies. |

## Wave 0 Requirements

- [x] `tools/prometheus-mcp/test/catalog.test.mjs` — frozen 46/current 59 union coverage, dispositions, schemas, aliases, and typed stubs.
- [x] `tools/prometheus-mcp/test/transport.test.mjs` — newline and archived framing, lifecycle, stdout cleanliness, bounds, and cancellation fixtures.
- [x] `tools/prometheus-mcp/test/native-client.test.mjs` — endpoint discovery, bearer, session heartbeat/resume/close, and mock native errors.
- [x] `tools/prometheus-mcp/test/visual-session.test.mjs` — exact field preservation, optional compatibility, normalization, denial, and no-log checks.
- [x] `tools/prometheus-mcp/test/diagnostics.test.mjs` — ten-layer schema and secret/content exclusion.
- [x] `chrome/browser/prometheus/prometheus_agent_transport_unittest.cc` — strict codec, target aliases, bounds, visual metadata, and diagnostic serialization.
- [x] `chrome/browser/prometheus/prometheus_agent_gateway_browsertest.cc` — real auth/profile/session/route/shutdown behavior.
- [x] Extended `chrome/browser/prometheus/prometheus_page_adapter_browsertest.cc` and renderer units for exact-frame element reads.
- [x] `tools/prometheus-mcp/smoke-browser.sh` plus a Node smoke client — real built-browser-to-stdio integration.

## Final Automated Evidence

All fresh closeout logs live under `.context/chromium/src/out/Default/` and
end with `EXIT_CODE=0`:

- `phase19-07-build.log` — `chrome`, `browser_tests`,
  `prometheus_unittests`, and `prometheus_action_dispatcher_unittests` built.
- `phase19-07-node-tests.log` — 64/64 passed; zero failed, cancelled,
  skipped, or TODO.
- `phase19-07-focused-units.log` — 34/34 focused gateway, session,
  transport, and compatibility units passed.
- `phase19-07-renderer-units.log` — 7/7 renderer units passed.
- `phase19-07-phase19-browser.log` — 32/32 gateway, profile, element-read,
  and consolidated MCP browser tests passed serially.
- `phase19-07-phase17-18-regression.log` — 53/53 prior native-service,
  page, action, and frame regressions passed serially.
- `phase19-07-live-smoke.log` — the built Prometheus app, real owner-only
  descriptor, authenticated gateway, and separately spawned stdio bridge
  passed end to end.
- `phase19-07-manifest-inventory.log` — 46 frozen, 59 current, 15 overlap,
  90 union, and 90/90 dispositions.
- `phase19-07-patch-inventory.log` — the exact Phase 18-tip range contains 19
  commits and exports 19 nonempty source-only patches.
- `phase19-07-static-boundary-audit.log` — 65 production files scanned with
  no embedded agent runtime, terminal/engine surface, wildcard listener,
  unauthenticated health, or secret-bearing logging.
- Environment, GPL, artifact-isolation, preservation, and both repository
  diff checks passed in their corresponding `phase19-07-*.log` files;
  `phase19-07-doc-consistency.log` also rejects obsolete readiness/UAT claims.

## Manual-Only Verifications

None. Human UAT and screenshots are intentionally excluded from Phase 19.
Every acceptance behavior requires automated Node, unit, browser, or live-smoke
evidence.

## Validation Sign-Off

- [x] All seven requirements have planned automated evidence.
- [x] Sampling continuity prevents three consecutive tasks without tests.
- [x] Wave 0 names every missing test/fixture.
- [x] No watch-mode flags.
- [x] Security threats map to automated gates.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-07-12

---
*Phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility*

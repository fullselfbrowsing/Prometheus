---
phase: 22
slug: chrome-extension-ecosystem-and-policy
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-28
---

# Phase 22 — Validation Strategy

Automated validation contract for Chromium extension availability, native
install/manage handoff, browser-owned extension identity, deny-by-default
per-extension Agent grants, visible extension-surface routing, Private-mode
separation, sanitized diagnostics, five representative compatibility
categories, and truthful Web Store/Manifest limitations.

Subjective desktop polish remains a non-blocking Phase 24 screenshot review and
cannot replace any Phase 22 functional, security, accessibility, lifecycle, or
privacy gate.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | Chromium GTest, `InProcessBrowserTest`, Views/WebUI browser tests, extension test helpers, Node 20 `node:test`, and shell/static evidence |
| **Nested source/output** | `.context/chromium/src` at the pinned Prometheus revision; existing `out/Default` component release build |
| **Native build pattern** | Extend the Phase 21 Siso-query/direct-object compile and focused-link strategy. Preserve `.ninja_log`, `.ninja_deps`, linked Blink artifacts, and packaged resources byte-for-byte unless a plan explicitly owns their reviewed replacement. |
| **Unit target** | Existing `prometheus_unittests` object graph, with policy model, registry lifecycle, grant lattice, generation, Private-mode, diagnostics, and codec tests |
| **Browser target** | Existing `browser_tests`, focused to extension policy/resolver/adapter, native confirmation, Control Panel, gateway/MCP, and upstream extension-manager regressions |
| **Fixture support** | Chromium `extensions/test/TestExtensionDir`, `ChromeTestExtensionLoader`, `ExtensionTestMessageListener`, local embedded test server, and five Prometheus-owned unpacked MV3 fixtures |
| **Node tests** | Existing `tools/prometheus-mcp/test/*.test.mjs`, extended for typed extension-policy errors, ten-key health, bounded reason/recovery, and inventory/content absence |
| **Quick root command** | `git diff --check && git -C .context/chromium/src diff --check` |
| **Quick native command after focused link** | `cd .context/chromium/src && ./out/Default/prometheus_unittests --gtest_filter='PrometheusExtensionPolicy*:*PrometheusGatewayHealth*'` |
| **Focused browser command** | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='PrometheusExtension*:*PrometheusWebUI*ExtensionPolicy*' --test-launcher-jobs=1 --test-launcher-retry-limit=0` |
| **Full phase command** | `bash .planning/chromium/verify-phase-22.sh` |

The Phase 22 verifier must evolve the existing Phase 21 harness; it must not
create a second build convention under a root `scripts/` directory or use a
different output directory.

---

## Sampling Rate

- **After every task commit:** run `git diff --check` in root and nested
  Chromium plus the narrowest non-empty owning unit/browser/WebUI/Node filter.
- **After every plan:** run all Phase 22 filters implemented so far and every
  directly touched Phase 17–21 regression cohort; export a non-empty stable
  root patch for each nested Chromium source commit.
- **After every execution wave:** run the complete implemented Phase 22 native,
  browser, WebUI, fixture, and Node subsets serially where profile/extension
  state is shared.
- **Before verification:** run `bash .planning/chromium/verify-phase-22.sh`
  from clean captured artifact hashes with list guards, retry limit zero,
  ordered patch replay, mutation self-test, and built-app evidence.
- **Sampling continuity:** no three consecutive implementation commits may land
  without a fresh automated result.
- **Max feedback latency:** 120 seconds for an already-linked focused filter;
  direct compile/link and built-app work belong at plan/wave boundaries.

No deterministic acceptance command may require an external network, Chrome
Web Store availability, Google account, real extension account, real password,
vault secret, human click, watch mode, or test-only install-verification bypass.

---

## Requirement Verification Map

| Requirement | Secure behavior | Threat refs | Minimum automated evidence | Status |
|-------------|-----------------|-------------|----------------------------|--------|
| EXT-01 | The pinned regular-profile extension subsystem is live and browser-owned; Prometheus reports truthful bounded health without replacing Chromium lifecycle ownership. | T-22-02, T-22-04, T-22-08 | ExtensionSystem/Registry readiness and lifecycle units, built-app health, exact ten-key gateway diagnostics, OTR/profile isolation. | ⬜ pending |
| EXT-02 | Users retain native `chrome://extensions` lifecycle actions and a proven developer-mode `Load unpacked` path; Store support is claimed only from matching live built-app evidence. | T-22-07, T-22-08 | Upstream manager regressions, owned unpacked lifecycle browser test, built-app disposable-profile smoke, Store-claim evidence gate. | ⬜ pending |
| EXT-03 | Chrome permissions never grant Agent authority; regular and Private `Blocked`/`Read only`/`Interact` grants are browser-owned, generation-bound, and fail closed. | T-22-01, T-22-02, T-22-04, T-22-05 | Grant lattice/persistence/registry tests, native confirmation and stale-row tests, reverse-boundary static/browser tests, Private non-inheritance. | ⬜ pending |
| EXT-04 | `chrome-extension://` targets are classified separately; only positively proven visible user-facing contexts route, arbitrary script and hidden contexts remain denied. | T-22-01, T-22-03, T-22-05, T-22-08, T-22-09 | Resolver/adapter unit and browser matrix for tab/options/popup/side panel plus background/offscreen/DevTools/hidden/wrong-profile/script denials. | ⬜ pending |
| EXT-05 | Five owned MV3 fixtures prove only their exact categories and include category-specific isolation failures. | T-22-02, T-22-03, T-22-05, T-22-09 | Password-manager-like, DNR ad blocker, productivity content script, side-panel/tooling, and developer-workflow fixture runs with machine-readable rows. | ⬜ pending |
| EXT-06 | Local UI/docs expose exact disabled/unverified Store, Google-service, Manifest, and context limitations; external diagnostics remain bounded and inventory-free. | T-22-06, T-22-07, T-22-10 | Copy/state WebUI tests, docs/static gates, MV2 observation without override, health privacy tests, built-app copy selection. | ⬜ pending |

---

## Threat References

| Ref | Threat | Mandatory mitigation and blocking gate |
|-----|--------|----------------------------------------|
| T-22-01 | A stale row, renderer-supplied ID, label, URL, or generation mutates the wrong extension grant. | Renderer sends only ordinal, generation, closed grant, and Private intent; native code resolves the exact current registry ID before confirmation and again before mutation. Reorder/removal/reload/replacement tests must cancel stale work. |
| T-22-02 | Extension permissions or extension code obtain an Agent session, gateway bearer, vault authority, internal-surface permission, or grant mutation path. | No extension/native-messaging bridge; no bearer/session in extension-visible state; local-UI-only grant mutation; recursive boundary/static tests. Any reverse-authority path blocks completion. |
| T-22-03 | Background workers, offscreen documents, hidden hosts, guests, or DevTools are mistaken for visible Agent-routable surfaces. | Closed positive view/ownership resolver using committed frame, registry, BrowserContext, and active browser UI; exhaustive negative browser matrix. Registry/host membership alone never authorizes. |
| T-22-04 | Regular grants leak into OTR, shared registries cross profiles, or ordinary Private eligibility silently grants Private Agent access. | Separate effective regular/Private grants, default Blocked, Private cannot exceed regular, exact BrowserContext checks, synchronous collapse on eligibility loss, cross-profile/OTR tests. |
| T-22-05 | `Read only` mutates, `Interact` reaches arbitrary `execute_js`, or a typed action bypasses existing ownership/document/confirmation/verification. | Closed read/action matrix, explicit script denial, enforcement before adapter dispatch and again at execution, source/static call-graph gate, unit/browser tests for every route family. |
| T-22-06 | Extension inventory, page content, form values, scripts, full identities, or authority leak through WebUI, MCP diagnostics, logs, audits, errors, accessibility, or compatibility rows. | Closed bounded DTOs, suffix-only local identity, exact ten-key inventory-free external health, metadata-only audit, recursive sentinel scans. |
| T-22-07 | Prometheus claims Web Store, MV2, or broad Chrome compatibility from a link, test bypass, unpacked fixture, or stale evidence. | Three-state Store result, unmodified MV policy, exact build/revision/fixture evidence, claim-to-evidence gate, no universal compatibility badge. |
| T-22-08 | Extension reload/disable/uninstall invalidates an extension pointer or identity after authorization, causing use-after-free or wrong-target routing. | Persist IDs not pointers, re-query registry after mutation, generation-fence callbacks, invalidate before observer delivery, lifecycle/race tests. |
| T-22-09 | Content-script-injected DOM on HTTP(S) is treated as extension identity or trusted authorization state. | Keep `PrometheusPageAdapter::IsNormalPageUrl()` HTTP(S)-only; adapter selection uses committed scheme/frame identity, never DOM provenance. Local-page content-script test proves normal-page routing. |
| T-22-10 | Unbounded names, installed rows, permissions, events, fixtures, diagnostics, or evidence exhaust memory or create oversized transport output. | Fixed count/byte/string/event bounds, deterministic truncation/pruning, at/over-limit tests, and bounded serialization checks. |

Security enforcement is enabled at ASVS level 1 and blocks on high-severity
threats. Every Phase 22 PLAN.md must include a `<threat_model>` covering the
threats it owns.

---

## Per-Task Verification Map

Task IDs are provisional planning anchors. The planner may split them further
but must preserve every row and bind each final task to an automated command.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | EXT-01, EXT-03 | T-22-01, T-22-04, T-22-08, T-22-10 | Closed grant lattice, registry-owned IDs, separate Private state, bounded generation snapshots | unit | `out/Default/prometheus_unittests --gtest_filter='PrometheusExtensionPolicy*'` | ❌ W0 | ⬜ pending |
| 22-01-02 | 01 | 1 | EXT-01, EXT-03 | T-22-01, T-22-08 | Registry removal/reload/disable transitions revoke or block effective access without stale pointers | unit | `out/Default/prometheus_unittests --gtest_filter='PrometheusExtensionPolicy*Registry*:*Lifecycle*'` | ❌ W0 | ⬜ pending |
| 22-02-01 | 02 | 2 | EXT-04 | T-22-01, T-22-03, T-22-04, T-22-08 | Exact frame/registry/profile/visibility resolver accepts only user-visible contexts | unit/browser | `out/Default/browser_tests --gtest_filter='PrometheusExtensionSurface*' --test-launcher-jobs=1 --test-launcher-retry-limit=0` | ❌ W0 | ⬜ pending |
| 22-02-02 | 02 | 2 | EXT-03, EXT-04 | T-22-02, T-22-05, T-22-09 | Read/Interact matrix is enforced; scripts/hidden contexts/reverse authority are denied | unit/browser/static | `.planning/chromium/verify-phase-22-extension-policy.sh --focused` | ❌ W0 | ⬜ pending |
| 22-03-01 | 03 | 2 | EXT-02, EXT-03 | T-22-01, T-22-04, T-22-06 | Local policy rows and native confirmation use safe DTOs, fresh generations, safe default focus, and truthful Private state | browser/WebUI | `out/Default/browser_tests --gtest_filter='PrometheusWebUI*ExtensionPolicy*:*PrometheusExtensionConfirmation*' --test-launcher-jobs=1 --test-launcher-retry-limit=0` | ❌ W0 | ⬜ pending |
| 22-03-02 | 03 | 2 | EXT-01, EXT-06 | T-22-06, T-22-07, T-22-10 | Live health retains ten bounded external keys and local UI/docs show exact recovery without inventory | unit/browser/Node | `.planning/chromium/verify-phase-22-mcp.sh --focused && .planning/chromium/verify-phase-22-webui.sh --focused` | ❌ W0 | ⬜ pending |
| 22-04-01 | 04 | 3 | EXT-05 | T-22-02, T-22-03, T-22-05, T-22-09 | Five owned MV3 categories prove positive behavior and category-specific isolation | browser fixtures | `.planning/chromium/verify-phase-22-extension-fixtures.sh --focused` | ❌ W0 | ⬜ pending |
| 22-04-02 | 04 | 3 | EXT-02, EXT-05, EXT-06 | T-22-07, T-22-10 | Lifecycle/MV2 truth and exact evidence matrix never overclaim compatibility | browser/docs | `.planning/chromium/verify-phase-22-extension-fixtures.sh` | ❌ W0 | ⬜ pending |
| 22-05-01 | 05 | 4 | EXT-01..EXT-06 | T-22-01..T-22-10 | Built app and closeout prove native lifecycle, policy, isolation, fixtures, truthful Store state, regressions, and patch preservation | built-app/full | `bash .planning/chromium/verify-phase-22.sh` | ❌ W0 | ⬜ pending |

---

## Wave 0 Requirements

No separate Wave 0 plan is required. The first task that owns each seam must
write compileable RED fixtures, list-guard the exact filter, prove the expected
failure, then retain the same test as GREEN evidence.

- [ ] `prometheus_extension_policy_service_unittest.cc` — grant lattice,
  persistence bounds, generation, registry lifecycle, and Private separation.
- [ ] `prometheus_extension_surface_resolver_unittest.cc` — closed view/profile/
  identity classification and hidden-context denials.
- [ ] extension Agent adapter/service unit and browser fixtures — read/action
  matrix, execute-js denial, ownership/document revalidation, and audit privacy.
- [ ] extension native confirmation and Control Panel browser fixtures — exact
  copy, safe focus, stale generation, mutation reconciliation, OTR, a11y,
  responsive, theme, and structural privacy.
- [ ] gateway/Node diagnostics fixtures — live bounded extension health, exact
  ten keys, no inventory/content/authority.
- [ ] five owned MV3 fixture directories — password-manager-like, ad blocking,
  productivity content script, side-panel/tooling, and developer workflow.
- [ ] `.planning/chromium/verify-phase-22*.sh` — focused and final list guards,
  direct compile/link, built-app, preservation, patch replay, and claim-evidence
  gates.

---

## Final Gate Checklist

- [ ] every new or modified Prometheus unit/browser object compiles through
  exact queried commands; focused binaries and app link; reviewed build metadata
  and unrelated artifacts remain byte-identical
- [ ] policy/grant/registry/generation/Private unit filters are non-empty and
  green at bounds, over bounds, reload, disable, uninstall, and shutdown
- [ ] exact visible tab/options/popup/side-panel cases pass; background worker,
  offscreen, hidden host, guest ambiguity, DevTools, wrong-profile, disabled,
  terminated, and stale cases return the expected typed denial
- [ ] `Read only` denies all mutation, `Interact` permits only the closed typed
  action set, and extension-surface `execute_js` is unreachable
- [ ] reverse extension-to-Agent, gateway bearer, vault, internal-surface, and
  grant-mutation paths are structurally absent
- [ ] regular and Private grants never inherit silently and immediately fail
  closed on native Private eligibility loss
- [ ] Control Panel exact copy/states, generation-bound confirmation, safe
  default focus, focus return, 320/480/720/1024 widths, 200% zoom, dark/light
  contrast, and no-stale-error behavior pass
- [ ] external health retains exactly ten bounded components and exposes no
  extension inventory, page content, profile path, permission data, or
  authority
- [ ] native `chrome://extensions` lifecycle and developer-mode Load unpacked
  work in a disposable built-app profile without an install-verification bypass
- [ ] all five owned MV3 category rows exist with exact build/revision,
  fixture/version/hash, install source, behaviors, limitation, and only
  `Verified`/`Degraded`/`Unsupported`
- [ ] content-script DOM remains normal HTTP(S) page content and cannot select
  the extension adapter or authorize a route
- [ ] MV2 status comes from unmodified pinned Chromium policy
- [ ] a Store support claim exists only with matching fresh successful live
  evidence; failed, unavailable, or unrun probes select exact limitation and
  developer-mode recovery copy without failing deterministic acceptance
- [ ] complete Phase 17–21 native/browser/WebUI/Node regressions, compatibility
  catalog, built MCP smoke, security/resource/preservation/GPL/artifact gates,
  ordered patch replay, mutation self-test, and root/nested `git diff --check`
  pass
- [ ] human subjective visual review remains `not_run` and is routed to the
  non-blocking Phase 24 release walkthrough

---

## Manual-Only Verifications

No human action is required for Phase 22 acceptance. Optional real Chrome Web
Store probing and real-world extension smoke may enrich the compatibility
report, but an unavailable network/store selects a truthful `Unverified` or
`Unavailable` state and cannot block the deterministic phase gate.

Subjective hierarchy, density, truncation, and dark/light polish are recorded
for Phase 24 human screenshot review; they cannot waive automated UI,
accessibility, contrast, privacy, or responsive checks.

---

## Validation Sign-Off

- [x] All six requirements map to automated evidence.
- [x] Every high-severity threat has a fail-closed automated gate.
- [x] Every provisional task has an automated command or explicit Wave 0 owner.
- [x] Sampling continuity prevents three consecutive unverified commits.
- [x] No watch-mode flag, external service, live account, real secret, or human
  action is required for deterministic acceptance.
- [x] Feedback latency target is below 120 seconds after focused linking.
- [x] `nyquist_compliant: true` is set; `wave_0_complete` remains false until
  every owning RED fixture exists and is retained as GREEN evidence.

**Approval:** strategy approved for planning; execution evidence pending

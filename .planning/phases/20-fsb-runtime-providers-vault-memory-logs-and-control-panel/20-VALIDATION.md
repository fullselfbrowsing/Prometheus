---
phase: 20
slug: fsb-runtime-providers-vault-memory-logs-and-control-panel
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-13
---

# Phase 20 — Validation Strategy

Automated validation contract for the native FSB task runtime, provider
networking, secure storage, memory/site guides, vault confirmation, WebUI, and
external MCP compatibility. Human visual UAT is intentionally not a Phase 20
gate and remains consolidated into the non-blocking Phase 24 release review.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Frameworks** | Chromium GTest, `InProcessBrowserTest`, renderer tests, Node 20 `node:test`, shell/static evidence. |
| **Native unit execution** | Every owned object is freshly compiled from exact Siso-queried commands and linked into focused executables without invoking Ninja or mutating its reviewed metadata. The unrelated aggregate `prometheus_unittests` component-build edge is not claimed. |
| **Browser target** | `browser_tests` with runtime profile, fake provider, WebUI, side-panel ownership, native confirmation, and MCP filters. |
| **Node tests** | `tools/prometheus-mcp/test/*.test.mjs`, extended with Phase 20 catalog/schema/secret/runtime fixtures. |
| **Network/secret fakes** | `network::TestURLLoaderFactory`; injected fake `PrometheusSecretStore`/encryptor. No real API key or macOS Keychain access. |
| **Quick Node command** | `node --test tools/prometheus-mcp/test/catalog.test.mjs tools/prometheus-mcp/test/tools.test.mjs tools/prometheus-mcp/test/diagnostics.test.mjs` |
| **Quick native command** | Run the full phase command once to create the verified custom link, then `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='PrometheusRuntimeTypesTest.*:PrometheusRuntimeStoreTest.*:PrometheusMemoryStoreTest.*:PrometheusSecretStoreTest.*:PrometheusProviderRegistryTest.*:PrometheusProviderCodecTest.*:PrometheusRuntimeProfileServiceTest.*:PrometheusRuntimeTestBootstrapTest.*:PrometheusRuntimeTransportCodecTest.*:PrometheusVaultServiceTest.*:PrometheusAgentServiceTest.*:PrometheusAgentSessionTest.*:PrometheusAgentGatewayTest.*'`. |
| **Focused browser command** | `cd .context/chromium/src && ./out/Default/browser_tests --gtest_filter='*PrometheusRuntime*:*PrometheusProvider*:*PrometheusVault*:*Prometheus*WebUI*:*Prometheus*Mcp*' --test-launcher-jobs=1` |
| **Full phase command** | `bash .planning/chromium/verify-phase-20.sh`; it queries Siso for exact commands, directly compiles every owned production/unit/browser object, relinks the app runtime and focused test executables, verifies Ninja metadata is unchanged, then runs Node, native/renderer/browser, Phase 17-19 regressions, built-app smoke, static, preservation, patch, and diff gates. |

## Sampling Rate

- After every RED/GREEN task: run the narrowest owning unit/Node test plus
  `git diff --check` in the owning repository.
- After each plan: run the full Phase 20 unit or Node subset affected by that
  plan and export a non-empty nested Chromium patch for every nested source
  commit.
- No three consecutive implementation commits may land without an automated
  test result.
- Before phase verification: fresh incremental builds and all mandatory gates;
  no live provider credentials, external services, human screenshots, or
  browser UAT.

## Requirement Verification Map

| Requirement | Owning plans/tasks | Planned behavior | Threat | Automated evidence | Status |
|-------------|--------------------|------------------|--------|--------------------|--------|
| FSB-01 | 20-02 T1-T2; 20-07 T2-T4; 20-11 T1-T3; 20-14 T1-T2 | Ask FSB seeds without auto-submit; explicit side-panel submission creates one bounded task and renders truthful state/result. | Duplicate/oversized/blank submission; wrong-window targeting. | Runtime service/store units, exact-window side-panel browser tests, 32-case integration, and built-app MCP smoke. | passed |
| FSB-02 | 20-01 T1-T3; 20-05 T1-T3; 20-06 T1-T2; 20-07 T1-T4; 20-09 T1-T3; 20-10 T1-T3; 20-11 T2-T3; 20-14 T1-T2 | Hosted/routed/local execution and MCP-origin tasks use one state machine with progress, cancel, timeout, terminal result, fresh fallback authorization, and authoritative session-loss cleanup. | Loop/replay/double completion; authority revoked between provider attempts; close/expiry/shutdown leaving provider work live; external client mistaken for embedded engine. | Lifecycle/fallback/cancel units; production MCP close/expiry/shutdown browser coverage; gateway/Node contracts; fake-provider browser test; external MCP smoke; no-spawn audit. | passed |
| FSB-03 | 20-04 T1-T3; 20-05 T1-T3; 20-07 T1-T4; 20-09 T1-T3; 20-10 T1-T3; 20-12 T1-T3; 20-13 T2-T3; 20-14 T1-T2 | All required provider kinds have metadata, endpoint policy, discovery, model selection, health, and bounded fallback order. | SSRF, redirect credential leak, ambiguous trust origin, unsafe retry. | Provider registry/codec tests, `TestURLLoaderFactory` request assertions, live control browser tests, and fake-provider integration. | passed |
| FSB-04 | 20-04 T1-T3; 20-05 T1-T3; 20-08 T1-T3; 20-09 T1-T3; 20-10 T1-T3; 20-13 T2-T3; 20-14 T1-T2 | Provider secrets use OSCrypt-backed origin-bound envelopes and never display after native save. | Plaintext/ciphertext through prefs, WebUI, MCP, logs, errors, or renderer. | Fake encryptor round-trip/failure/re-encrypt tests, native-dialog browser tests, and recursive serialization/denylist scans. | passed |
| FSB-05 | 20-01 T1-T3; 20-02 T1-T2; 20-05 T1-T3; 20-06 T1-T2; 20-07 T2-T4; 20-09 T1-T3; 20-10 T1-T3; 20-11 T2-T3; 20-12 T1-T3; 20-14 T1-T2 | Bounded task/log/action/diagnostic/usage/outcome persistence with integer token/cost/duration metrics. | Content-bearing telemetry, unbounded growth, fabricated zero/unknown accounting. | Store eviction/restart/redaction/accounting units plus WebUI, MCP, integration, and smoke sanitized snapshots. | passed |
| FSB-06 | 20-03 T1-T2; 20-07 T2-T4; 20-09 T1-T3; 20-10 T1-T3; 20-13 T1-T3; 20-14 T1-T2 | Memory and site-guide CRUD/search/apply with exact-origin guides and no automatic secret ingestion. | Cross-origin guide use, secret-as-memory, quota bypass. | CRUD/search/bounds/profile/exact-origin units, control browser tests, MCP integration, and built-app smoke. | passed |
| FSB-07 | 20-04 T1-T2; 20-08 T1-T3; 20-09 T1-T3; 20-10 T1-T3; 20-13 T1-T3; 20-14 T1-T2 | Vault metadata is listable; values remain native; every fill requires fresh confirmation and post-confirmation target revalidation. | Stale-document/wrong-origin/background/unowned/replayed secret insertion. | Native confirmation accept/deny/navigation/focus/expiry/replay unit/browser tests, MCP retry integration, and no-secret scans. | passed |
| FSB-08 | 20-01 T1-T3; 20-02 T1-T2; 20-04 T1-T3; 20-06 T1-T2; 20-07 T2-T4; 20-09 T1-T3; 20-10 T1-T3; 20-11 T1-T3; 20-12 T1-T3; 20-13 T1-T3; 20-14 T1-T2 | Internal surfaces, caps, ownership/background actions, telemetry, vault boundaries, and Phase-21 supervision state reflect enforcement. | Decorative settings or MCP policy weakening. | Policy clamp/persistence/dispatch tests, effective-state WebUI assertions, diagnostics, full regressions, and static boundary audits. | passed |

## Threat References

| Ref | Threat | Mandatory mitigation and gate |
|-----|--------|-------------------------------|
| T-20-01 | Page/provider prompt injection widens authority | Treat all observations as untrusted; closed autonomous tool allowlist; native route/schema/ownership enforcement; adversarial fixtures. |
| T-20-02 | Provider endpoint leaks credential or reaches unsafe network target | Fixed hosted origins, HTTPS remote custom, exact loopback HTTP only, omitted credentials/cookies/referrer, cache off, auth redirect rejection, bounded body/time. |
| T-20-03 | Secret crosses renderer/MCP/log/pref boundary | OSCrypt envelope, native entry/use, structurally absent DTO fields, exact-sentinel recursive scans. |
| T-20-04 | Vault approval applies to changed target | Capture and revalidate profile/tab/owner/origin/frame/document/ref/focus; one-use short expiry; fail closed. |
| T-20-05 | Async race causes duplicate terminal state or post-cancel action | `(task_id,generation)`, weak callbacks, task-owned loader, one `FinishOnce` path, exactly-once tests. |
| T-20-06 | Provider fallback replays mutation or reuses another credential | Fallback only for retryable pre-mutation failures; exact provider/origin secret binding; no post-mutation replay. |
| T-20-07 | External MCP support becomes an embedded agent runtime | MCP is provenance/adapter only; no subprocess, terminal, CLI, engine selector, prompt provisioner, provider Node/Python runtime, or `CLAUDE.md`. |
| T-20-08 | Persistence/telemetry becomes an exfiltration or growth path | Closed event fields, bounded deterministic eviction, local-only/off telemetry, prompts/page/typed data absent. |

High-severity gate: stop and do not claim Phase 20 complete if any exact secret
sentinel appears in a serialized boundary, an unsafe URL/redirect sends
authorization, a stale vault target can fill, a cancelled task dispatches, an
unknown tool reaches routing, or production launches an external engine.

## RED Fixture Ownership (No Separate Wave 0)

No separate Wave 0 plan is required. Each owning RED task below creates minimal
compileable fixture scaffolding, proves the intended behavior fails, and guards
`--gtest_list_tests` (or the explicit Node test file) before accepting RED.

- [ ] **20-01 T1** — `prometheus_runtime_types_unittest.cc`: closed enums,
  bounds, legal transitions, DTO serialization, and terminal-state rules.
- [ ] **20-02 T1** — `prometheus_runtime_store_unittest.cc`: task/log/action/
  diagnostic/usage eviction, restart, redaction, generation, and FinishOnce.
- [ ] **20-03 T1** — `prometheus_memory_store_unittest.cc`: full CRUD/search,
  deterministic bounds, caller visibility, restart, and exact-origin guides.
- [ ] **20-04 T1** — `prometheus_secret_store_unittest.cc` and
  `prometheus_provider_registry_unittest.cc`: bound envelopes, fake-encryptor
  failures/re-encrypt, provider kinds, endpoint policy, and fallback metadata.
- [ ] **20-05 T1** — `prometheus_provider_codec_unittest.cc` and
  `prometheus_provider_transport_unittest.cc`: three wire families, headers,
  cookie/cache/referrer/redirect denial, timeout, cancel, bounds, and typed retry.
- [ ] **20-06 T1-T2** — focused SafeTitle type/store tests plus exact
  PolicyAdmission/PolicyDispatch/TelemetryOff/LockedVaultPolicy and
  `PrometheusAgentSessionTest.*` filters.
- [ ] **20-07 T1** — closed `PrometheusRuntimeTestBootstrapTest.*`
  parser/build/launch/profile/file/endpoint/schema gates.
- [ ] **20-07 T2** — `prometheus_runtime_profile_service_unittest.cc` plus the
  first 20 evaluation fixtures: submission, one-tool loop, Agent authority,
  cancel/timeout/shutdown exactly once, fallback, accounting, and application
  of the 20-06 safe-title/policy primitives and this plan's bootstrap.
- [ ] **20-08 T1** — `prometheus_vault_service_unittest.cc` and
  `prometheus_agent_service_unittest.cc` and
  `prometheus_vault_confirmation_browsertest.cc`: metadata, move-only private
  Agent insertion, native delegation, and target/focus/owner/origin/frame/
  document/ref/expiry/replay revalidation.
- [ ] **20-09 T1** — `prometheus_runtime_transport_codec_unittest.cc` and
  gateway units: exact 27 commands, closed schemas, caller isolation, secret
  denial, existing-page-route regression, and live provider/vault diagnostics.
- [ ] **20-10 T1** — Node catalog/tools/native-client/diagnostics fixtures:
  31 live names, four alias equivalence checks, 49/12/22/5/2 counts, recursive
  schemas, caller isolation, secret-shaped denial, and truthful diagnostics.
- [ ] **20-11 T1/T3 and 20-12 T1/T3** — WebUI browser tests: exact-window live
  side tasks and live task/provider/log control sections, responsive/keyboard
  reachability, malformed messages, and structural content/secret absence.
- [ ] **20-13 T1-T3** — WebUI/native-dialog browser tests: complete memory,
  guide, vault, provider-key, settings, policy, and supervision-not-ready gates.
- [ ] **20-10 T3 and 20-14 T1** — built-app external MCP runtime smoke plus
  exactly 32 fake-provider cases for submit/status/cancel/log/memory/guide/
  diagnostics with no real key or third-party engine.

## Exact Per-Task Verification Ownership

| Owner | Exact task contract | Primary automated evidence |
|-------|---------------------|----------------------------|
| 20-01 T1 | Specify runtime contracts, legal transitions, and policy clamps (RED). | `PrometheusRuntimeTypesTest.*` expected RED. |
| 20-01 T2 | Implement closed types, budgets, serialization, and transition validation (GREEN). | `PrometheusRuntimeTypesTest.*` GREEN. |
| 20-01 T3 | Register versioned regular-profile prefs and enforced policy defaults. | Runtime type/pref registry, defaults, corrupt/clamp, and non-syncable-scope tests. |
| 20-02 T1 | Freeze bounded store, restart, redaction, and terminal-race behavior (RED). | `PrometheusRuntimeStoreTest.*` expected RED. |
| 20-02 T2 | Implement deterministic task, event, outcome, and usage persistence (GREEN). | Runtime store plus type regressions. |
| 20-03 T1 | Define memory and site-guide CRUD, visibility, bounds, and exact-origin gates (RED). | `PrometheusMemoryStoreTest.*` expected RED. |
| 20-03 T2 | Implement bounded profile memory and exact-origin guide application (GREEN). | Memory store plus runtime contract regressions. |
| 20-04 T1 | Specify exact-origin encrypted envelopes and provider registry policy (RED). | Secret-store and provider-registry suites expected RED. |
| 20-04 T2 | Implement the injectable OSCryptAsync secret store (GREEN). | `PrometheusSecretStoreTest.*` with fake encryptor. |
| 20-04 T3 | Implement provider metadata, endpoint policy, discovery state, and fallback order (GREEN). | Provider-registry plus secret-store regressions. |
| 20-05 T1 | Pin provider wire contracts, normalized output, and network security (RED). | Provider codec/transport suites expected RED. |
| 20-05 T2 | Implement three strict provider codec families (GREEN). | `PrometheusProviderCodecTest.*`. |
| 20-05 T3 | Implement secure cancellable direct provider transport (GREEN). | Codec and TestURLLoaderFactory transport suites. |
| 20-06 T1 | Add deterministic safe-title derivation and schema-v1 persistence compatibility. | Exact non-empty RuntimeTypes/RuntimeStore `*SafeTitle*` guards and passing run. |
| 20-06 T2 | Add effective policy decisions and non-evicting Agent-session cap enforcement. | Exact PolicyAdmission/PolicyDispatch/TelemetryOff/LockedVaultPolicy plus `PrometheusAgentSessionTest.*` guards and passing run. |
| 20-07 T1 | Implement the closed non-official built-app provider bootstrap. | Exact `PrometheusRuntimeTestBootstrapTest.*` guard and passing accepted/denied launch matrix. |
| 20-07 T2 | Specify regular-profile ownership, local principal lifetime, and the bounded provider/tool loop (RED). | Runtime-profile expected RED after the independently guarded Agent-session prerequisite passes. |
| 20-07 T3 | Assemble the runtime and apply safe-title, policy, session, and bootstrap primitives (GREEN). | Complete runtime-profile/Agent-session run plus exact SafeTitle/PolicyAdmission/PolicyDispatch/TelemetryOff/LockedVaultPolicy/RuntimeTestBootstrap guards. |
| 20-07 T4 | Close fallback, cancellation, accounting, discovery, and the 20-case evaluation seam (GREEN). | Runtime/store/provider/registry/Agent-session/bootstrap suites and exactly 20 fixtures. |
| 20-08 T1 | Specify vault metadata, native-only entry, and stale-target confirmation failures (RED). | Vault unit/browser suites expected RED. |
| 20-08 T2 | Implement metadata, internal approvals, and double-revalidated insertion (GREEN). | Vault-service, secret-store, and non-empty confirmed-vault Agent-service filters. |
| 20-08 T3 | Prove fail-closed native delegation and real-window revalidation (GREEN). | Serial `PrometheusVaultConfirmationBrowserTest.*` tests; Plan 20-13 owns Views. |
| 20-09 T1 | Freeze all 27 runtime command schemas, caller isolation, and gateway readiness behavior (RED). | Runtime codec/gateway suites expected RED. |
| 20-09 T2 | Implement the closed runtime codec and authenticated gateway dispatch (GREEN). | Runtime codec and gateway units. |
| 20-09 T3 | Publish live provider/vault diagnostics and preserve Phase 17-19 gateway contracts (GREEN). | Runtime codec, gateway, and transport regressions. |
| 20-10 T1 | Freeze the 31-name promotion, final manifest counts, schemas, and alias equivalence (RED). | Catalog/tools/native-client/diagnostics expected RED. |
| 20-10 T2 | Promote the catalog and implement recursive closed runtime schemas (GREEN). | Catalog and tools Node tests. |
| 20-10 T3 | Forward runtime commands and prove the built-app external MCP smoke (GREEN). | Positive Node TAP test count, complete Node suite, built smoke, precise no-process scan, and root diff check. |
| 20-11 T1 | Replace raw WebView hosting with exact-window WebUI ownership. | Multi-window exact-owner serial browser tests. |
| 20-11 T2 | Wire the live composer, task snapshots, cancel, provenance, result, and recovery. | Runtime and Ask FSB WebUI browser tests. |
| 20-11 T3 | Automate responsive, keyboard, malformed-message, and no-engine side-panel gates. | Complete Prometheus WebUI browser filter. |
| 20-12 T1 | Add a regular-profile control handler and sanitized observer snapshots. | Control-handler serial browser tests. |
| 20-12 T2 | Render live Tasks, Providers & Models, and Logs & Diagnostics workflows. | Control task/provider/log browser filters. |
| 20-12 T3 | Automate section states, responsive tables/cards, keyboard flow, and content-free boundaries. | Complete control-panel browser filter. |
| 20-13 T1 | Wire complete memory/site-guide/vault metadata CRUD and safe control rendering. | Memory/guide/vault-metadata browser filters. |
| 20-13 T2 | Launch native provider/vault dialogs and bind Settings to effective enforcement. | Native-secret/settings/permissions browser filters plus exact RuntimeProfileService PolicyAdmission/PolicyDispatch/TelemetryOff/LockedVaultPolicy and secret-store units. |
| 20-13 T3 | Close full control-panel responsive, keyboard, secret, and truthful-state gates. | Full WebUI/vault browser and runtime/memory/vault/secret units. |
| 20-14 T1 | Complete the 32-case fake-provider corpus and native browser integration. | Runtime MCP integration browser filter; exact 32/20+ counts. |
| 20-14 T2 | Run full mandatory gates, export patches, and close verification without UAT. | Full build/test/security/preservation/patch/diff checklist below. |

## Final Gate Checklist

- [x] every owned native, renderer, and browser object compiles directly; the app runtime and focused/custom links verify; reviewed Ninja metadata remains byte-identical. The aggregate unit link limitation is recorded without a pass claim.
- [x] all 75 Node tests pass with zero failures/skips/TODOs/cancellations
- [x] all 232 focused Phase 20 native/content/renderer units pass (`208 + 24`)
- [x] all 37 Phase 20 browser tests pass serially
- [x] 84 Phase 17-19 native and 83 Phase 17-19 browser/MCP regressions pass
- [x] fake-provider built-app external MCP smoke passes
- [x] exact 90-name manifest reports 49 native, 12 alias, 22 typed stub, five Phase 21, two removed
- [x] recursive secret/content/privacy audit passes
- [x] no embedded runtime/process/terminal/engine/`CLAUDE.md` audit passes
- [x] packaged WebUI remote-resource/layout/keyboard gates pass
- [x] preservation, GPL, artifact-isolation, root/nested diff, 54-patch stable-identity inventory, and `git diff --check` pass
- [x] human visual UAT recorded `not_run` and routed to non-blocking Phase 24 review

## Fresh Closeout Evidence

`bash .planning/chromium/verify-phase-20.sh` is the reproducible fail-fast
entrypoint. It writes fresh secret-free logs below
`.context/chromium/src/out/Default/phase20-closeout/`.

| Gate | Result | Named log |
|------|--------|-----------|
| Owned-object direct compile and app-runtime relink | passed; reviewed `.ninja_log` and `.ninja_deps` preserved | `phase20-direct-build.log`, `phase20-app-runtime-link.log` |
| Aggregate native target | known unrelated component-build link limitation; not run and no pass claimed | `phase20-aggregate-unit-link.log` |
| Owned-object focused/custom links | passed, signed, and verified | `phase20-content-link.log`, `phase20-browser-build.log` |
| Phase 20 native units | 208/208 | `phase20-native-units.log` |
| Content/Mojo/renderer units | 24/24 | `phase20-content-units.log` |
| Phase 17-19 native regressions | 84/84 | `phase20-regression-native-units.log` |
| Phase 20 MCP/vault/control browser fixtures | 37/37 serial | `phase20-browser-tests.log` |
| Phase 17-19 browser regressions | 83/83 serial | `phase20-regression-browser-tests.log` |
| Node MCP suite | 75/75; fail/cancelled/skipped/todo all zero | `phase20-node-tap.log` |
| Built-app external MCP smoke | passed with mode-0600 test bootstrap and loopback fixture | `phase20-built-smoke.log` |
| Corpus/catalog | 32 cases, groups `6/5/5/5/4/4/3`, 28 real loops across four families; catalog `49/12/22/5/2` | `phase20-inventory.log` |
| Environment/security/preservation/patch/diff | passed | `phase20-environment.log`, `phase20-static-boundaries.log`, `phase20-preservation.log`, `phase20-patches.log` |

The aggregate `prometheus_unittests` executable cannot currently close its
component-build link because the target omits unrelated Chrome dependencies
such as navigation, prefetch, upgrade-detector, and file-selection symbols.
The verifier does not invoke that edge. It queries exact commands through Siso,
freshly compiles all owned objects, and directly reconstructs the app, browser,
and content link response files from generated build metadata. Plain native
suites execute in the custom browser link; Mojo/content/renderer suites execute
in the focused content link. This substitution is explicit and does not turn
the aggregate limitation into a passing result.

## Manual-Only Verifications

None for Phase 20 acceptance. Human desktop visual review remains a Phase 24
non-blocking release check and cannot replace or waive any automated gate above.

## Validation Sign-Off

- [x] All eight requirements map to automated evidence.
- [x] Security threats have fail-closed automated gates.
- [x] No watch-mode command or live provider credential is required.
- [x] Human UAT is explicitly excluded without being claimed complete.
- [x] No separate Wave 0 is needed; every owning RED task creates and list-guards its fixture before asserting the intended failure.
- [x] Final evidence captured after execution.

**Approval:** passed automated closeout; `human_uat: not_run`

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*

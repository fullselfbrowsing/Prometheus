---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
verified: 2026-07-20T18:39:52Z
status: passed
score: "56/56 must-haves verified"
overrides_applied: 0
human_uat: not_run
re_verification:
  previous_status: passed
  previous_score: "8/8 requirements; no must-have score recorded"
  gaps_closed:
    - "CR-01: vault metadata now reloads and reconciles across restart."
    - "WR-01 through WR-07: tasks auto-start, generated tools use the closed schema, running state persists, arguments validate recursively, discovery is pollable, bookkeeping is bounded, and Agent caps reject only new admission."
    - "WR-08: live session ownership replaces unbounded tombstones."
    - "WR-09: patch verification uses stable patch identity and rejects a valid mutated patch body."
    - "CR-02: Auto fallback revalidates authority, policy, prompt/token/time bounds, and the exact provider binding."
    - "WR-10: session close, expiry, and gateway shutdown notify the runtime and clean up matching work exactly once."
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Subjective desktop screenshot and polish review remains unperformed."
    addressed_in: "Phase 24"
    evidence: "ROADMAP Phase 24 success criterion 6 and the preservation ledger make the consolidated visual review non-blocking when automated and functional gates pass."
---

# Phase 20: FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel Verification Report

**Phase Goal:** Restore user-facing FSB runtime functionality inside Chromium-based Prometheus.
**Verified:** 2026-07-20T18:39:52Z
**Status:** passed
**Re-verification:** Yes — independent goal-backward verification after review fixes CR-01, CR-02, and WR-01 through WR-10.

## Verification Result

The phase goal is achieved. All five roadmap success criteria and all 51
plan-specific truths are VERIFIED, all eight FSB requirements are SATISFIED,
and no human-only check is part of Phase 20 acceptance. The authoritative full
gate exited zero at root c85b1f14ace7af5a0da606b9682f1b21b43f7863
and nested Chromium 5632dcef07121bf4c3444cc2da13f222b6a61e91.

The implementation is one bounded, regular-profile, browser-owned runtime.
Side-panel and external MCP submissions converge on that same service; provider
networking and secrets remain browser-process-owned; page actions retain native
Agent authority; and renderer-visible state is sanitized metadata.

## Goal Achievement

### Roadmap Observable Truths

| # | Roadmap truth | Status | Direct evidence |
|---|---------------|--------|-----------------|
| 1 | Side-panel Auto/Provider/Local tasks and MCP-origin tasks run in the same native runtime with truthful provenance and no embedded engine. | ✓ VERIFIED | prometheus_webui.js sends explicit submit/cancel messages; prometheus_web_ui.cc binds them to the exact Browser; NativeSideRuntime and PrometheusAgentGateway both call the profile's PrometheusRuntimeProfileService. Native, browser, Node, and built-app smoke gates pass. |
| 2 | Provider configuration covers OpenAI, Anthropic, Gemini, xAI, OpenRouter, LM Studio, hosted/routed/local/custom endpoints, and fallback order. | ✓ VERIFIED | PrometheusProviderRegistry enumerates every required kind and route, canonicalizes fixed/loopback/HTTPS endpoints, and owns ordered fallback. Codec/transport tests cover OpenAI Responses, OpenAI Chat, Anthropic Messages, and Gemini generateContent. |
| 3 | Secrets never display after save and never cross MCP or remote transports. | ✓ VERIFIED | Native password dialogs feed PrometheusSecretStore; OSCrypt envelopes bind record/kind/origin; sanitized provider/vault DTOs expose configured state only; recursive sentinel scans cover WebUI, MCP, prefs, logs, diagnostics, errors, corpus, and smoke output. |
| 4 | Logs, diagnostics, metrics, token/cost accounting, memory, site guides, and vault metadata are visible in the control panel. | ✓ VERIFIED | PrometheusControlRuntime builds live bounded snapshots from the runtime store, memory store, provider registry, and vault metadata; browser tests exercise empty, live, restart, CRUD, responsive, and keyboard states. |
| 5 | Settings expose enforced permissions, caps, ownership, background actions, telemetry, and vault boundaries while supervision remains Not ready. | ✓ VERIFIED | Native policy decisions drive admission, dispatch, Agent caps, and telemetry emission; locked ownership/vault fields and supervision not_ready are rendered from the native snapshot and asserted by browser tests. |

**Roadmap score:** 5/5 VERIFIED

### Plan Must-Have Coverage

All 51 PLAN frontmatter truths were evaluated. The compact rows below retain
their plan identity while recording artifact and link closure.

| Plan | Truths | Declared artifacts | Declared links | Level 1–4 evidence | Status |
|------|--------|--------------------|----------------|--------------------|--------|
| 20-01 | 3/3 | 3/3 | 2/2 | Closed runtime types, local versioned prefs, clamps, serialization, and native tests. | ✓ VERIFIED |
| 20-02 | 3/3 | 2/2 | 2/2 | Bounded persistent task/event/action/diagnostic/usage store; generation and FinishTaskOnce tests. | ✓ VERIFIED |
| 20-03 | 3/3 | 2/2 | 2/2 | Bounded memory/site-guide CRUD, persistence, caller visibility, and exact-origin application. | ✓ VERIFIED |
| 20-04 | 3/3 | 3/3 | 2/2 | OSCrypt-backed exact-origin secret envelopes and complete provider metadata/route policy. | ✓ VERIFIED |
| 20-05 | 4/4 | 3/3 | 3/3 | Strict provider codecs, model discovery, direct secure transport, typed retryability, and cancellation. | ✓ VERIFIED |
| 20-06 | 4/4 | 3/3 | 2/2 | Backward-compatible safe-title persistence and enforced policy/session-cap primitives. | ✓ VERIFIED |
| 20-07 | 6/6 | 5/5 | 5/5 | Regular-profile runtime service, exact-browser principal, bounded provider/tool loop, fallback, lifecycle, and closed test bootstrap. | ✓ VERIFIED |
| 20-08 | 3/3 | 3/3 | 3/3 | Metadata-only vault, fresh native approval, double target revalidation, one-use insertion. | ✓ VERIFIED |
| 20-09 | 4/4 | 3/3 | 3/3 | Authenticated 27-route runtime gateway, closed JSON codec, local-only mutations, truthful health. | ✓ VERIFIED |
| 20-10 | 4/4 | 4/4 | 4/4 | 31 live Phase 20 compatibility names, exact 90-name inventory, external dependency-free Node adapter. | ✓ VERIFIED |
| 20-11 | 4/4 | 3/3 | 3/3 | Exact-window side-panel ownership, hidden RAII principal, explicit task submit/cancel/result/recovery, MCP provenance. | ✓ VERIFIED |
| 20-12 | 4/4 | 3/3 | 2/2 | Live native task/provider/log/diagnostic/usage control workflows with local-only provider mutation. | ✓ VERIFIED |
| 20-13 | 3/3 | 3/3 | 3/3 | Live memory/guide/vault/settings workflows and exact-window native provider/vault dialogs. | ✓ VERIFIED |
| 20-14 | 3/3 | 4/4 | 4/4 | Exactly-32 corpus, built-app MCP smoke, complete closeout gate, evidence, and 54 patches. | ✓ VERIFIED |

**Plan score:** 51/51 VERIFIED
**Merged score:** 56/56 must-haves VERIFIED

The mechanical artifact query found every declared file and passed 40/44
literal contains checks; the mechanical link query passed 37/40 literal
patterns. Direct semantic inspection closed all seven lexical false negatives:
RuntimeTaskSnapshot replaces the planned TaskRecord spelling; the bootstrap
literal is defined in the included header; injection cases use explicit
injection_* IDs; session.command reaches NativeClient.command and
/v1/agent/command; ShowPrometheus* functions are the dialog interface; and
effective policy values are populated by JavaScript from the native snapshot
rather than hard-coded in HTML.

## Required Artifacts

| Artifact group | Expected | Level 1 | Level 2 | Level 3 | Level 4 |
|----------------|----------|---------|---------|---------|---------|
| prometheus_runtime_types.*, prometheus_runtime_prefs.*, prometheus_runtime_store.* | Closed bounded state, local persistence, policy, safe titles, accounting | ✓ exists | ✓ substantive | ✓ service/prefs wired | ✓ native and restart tests |
| prometheus_memory_store.* | Bounded memory and exact-origin site guides | ✓ exists | ✓ substantive | ✓ runtime/control/MCP wired | ✓ CRUD, restart, origin tests and smoke |
| prometheus_provider_registry.*, prometheus_provider_codec.*, prometheus_provider_transport.* | Complete providers, strict wire formats, discovery, secure direct transport, fallback | ✓ exists | ✓ substantive | ✓ runtime and secret store wired | ✓ four-family loops plus unit/browser tests |
| prometheus_secret_store.* and prometheus_vault_service.* | OSCrypt secrets, metadata-only vault, per-use native confirmation | ✓ exists | ✓ substantive | ✓ dialogs/Agent insertion wired | ✓ restart, corruption, confirmation browser tests |
| prometheus_runtime_profile_service.* and factory | One regular-profile runtime and bounded task/tool lifecycle | ✓ exists | ✓ substantive | ✓ side panel, gateway, provider, store, Agent wired | ✓ focused native/browser tests and corpus |
| prometheus_agent_gateway.* and prometheus_runtime_transport_codec.* | Authenticated closed runtime transport | ✓ exists | ✓ substantive | ✓ same profile runtime wired | ✓ codec, gateway, lifecycle, MCP browser tests |
| tools/prometheus-mcp/src/* and test/* | External stdio adapter and exact compatibility catalog | ✓ exists | ✓ substantive | ✓ authenticated native client wired | ✓ 75 Node tests and built-app smoke |
| prometheus_web_ui.cc, prometheus_browser_main_extra_parts.cc, HTML/JS resources, runtime dialogs | Live side panel/control panel with native-only secrets | ✓ exists | ✓ substantive | ✓ exact Browser and profile service wired | ✓ 37 Phase 20 browser fixtures |
| runtime_eval_cases.json, verify-phase-20.sh, patch directory, validation/preservation evidence | Deterministic adversarial and closeout proof | ✓ exists | ✓ substantive | ✓ consumed by tests/verifier | ✓ exact inventory, patch, preservation gates |

All 44 declared artifacts are VERIFIED at existence, substance, wiring, and
real-data/test levels. No declared artifact is orphaned.

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Side-panel JavaScript | PrometheusWebUI message handler | chrome.send and sanitized listener snapshots | ✓ WIRED | Explicit submit creates one task; cancel addresses the same task; no authority IDs enter JavaScript. |
| WebUI handler | NativeSideRuntime | exact originating Browser/WebContents | ✓ WIRED | Principal creation is tied to the opening window/tab, never last-active-window lookup. |
| NativeSideRuntime and PrometheusAgentGateway | PrometheusRuntimeProfileService | regular-profile factory and typed calls | ✓ WIRED | Both user origins share the same store, provider loop, memory, vault metadata, and lifecycle. |
| Runtime service | Provider registry, secret store, transport, and codec | exact provider/config binding per turn | ✓ WIRED | Credentials are fetched immediately before a bounded request; redirects and ambient credentials are denied. |
| Provider result | Runtime tool contract and PrometheusAgentProfileService | one validated closed tool call per turn | ✓ WIRED | Schema/argument validation precedes exact-session/tab/document authority and native page execution. |
| Runtime/store/memory/vault/policy | Control snapshot and DOM | observer snapshots and fresh post-mutation reads | ✓ WIRED | Only sanitized, bounded metadata flows to the renderer. |
| Native vault dialogs | Secret store and Agent insertion | browser-owned callback, fresh approval, double revalidation | ✓ WIRED | Secret bytes never cross WebUI/MCP and are decrypted only after authority checks. |
| Agent session lifecycle | Runtime cleanup | observer notification and live-session set | ✓ WIRED | Close, expiry, gateway shutdown, and service shutdown cancel matching tasks and release once. |

## Data-Flow Trace (Level 4)

| Data | Source | Processing | Observable sink | Produces real data | Status |
|------|--------|------------|-----------------|--------------------|--------|
| Side-panel task | User draft and Auto/Provider/Local selection | WebUI validation → exact-window native principal → SubmitTask → provider/tool loop | progress, cancellation, result, failure, usage | Yes; native/browser tests exercise all states | ✓ FLOWING |
| MCP task | External stdio request | schema validation → authenticated native-client command → gateway → same SubmitTask | MCP result plus side/control provenance | Yes; Node, browser integration, and built-app smoke | ✓ FLOWING |
| Provider turn | Prompt plus native provider metadata | registry/secret lookup → bounded SimpleURLLoader → family codec | normalized result/tool/usage | Yes; 28 real fake-provider loops across four wire families | ✓ FLOWING |
| Page tool | Validated provider tool call | closed nine-tool contract → fresh policy/authority → Agent native route | verified action/result and task continuation | Yes; unit/browser/corpus action fixtures | ✓ FLOWING |
| Runtime observability | Store, memory, provider, vault, policy services | bounded sanitized snapshots | control-panel tasks/logs/diagnostics/metrics/memory/guides/vault/settings | Yes; live and restart browser fixtures | ✓ FLOWING |
| Vault value | Native password dialog | OSCrypt envelope → native approval → target revalidation → private insertion | page field only after explicit confirmation | Yes; real-window confirmation tests; no renderer/MCP copy | ✓ FLOWING |

## Review-Fix Closure

| Finding | Fix evidence | Regression evidence | Status |
|---------|--------------|---------------------|--------|
| CR-01 | 707575f reloads/reconciles persisted vault metadata and secret state. | Restart, deletion, monotonic-ID, and corruption tests are inside 208/208. | ✓ CLOSED |
| WR-01–WR-07 | e2918d9, e58b29b, 5f6fc3b, e74b8d6, c8fe8ea, 405d955, d36944b close auto-start, schema, state, validation, polling, bounds, and cap issues. | Focused runtime/gateway/session/codec suites pass. | ✓ CLOSED |
| WR-08 | c5453efd replaces retired-session tombstones with bounded live ownership. | Unique release and no-tombstone session tests pass. | ✓ CLOSED |
| WR-09 | e8e7f782 strengthens patch identity verification. | 54 stable identities pass; a syntactically valid mutated body is rejected. | ✓ CLOSED |
| CR-02 | f7318871 revalidates authority, policy, limits, and exact provider binding before Auto retry. | Revocation, changed-binding, prompt-limit, and pre/post-mutation fallback tests pass. | ✓ CLOSED |
| WR-10 | 5632dcef connects close/expiry/gateway shutdown to runtime cancellation. | Native and MCP lifecycle tests prove cancellation and exactly-once release. | ✓ CLOSED |

## Automated Verification and Probes

Fresh command:

    bash .planning/chromium/verify-phase-20.sh

Result: exit 0 — Phase 20 verification passed.

| Gate or probe | Fresh result | Status |
|---------------|--------------|--------|
| Exact direct compilation/linking | 86 owned objects: 39 production, 31 unit, 11 browser-test, four renderer, one native-dialog; focused content/browser/app links rebuilt and signed | ✓ VERIFIED |
| Phase 20 native suites | 208/208 | ✓ VERIFIED |
| Content/Mojo/renderer suites | 24/24 | ✓ VERIFIED |
| Phase 17–19 native regressions | 84/84 | ✓ VERIFIED |
| Phase 20 browser fixtures | 37/37 serial | ✓ VERIFIED |
| Phase 17–19 browser regressions | 83/83 serial | ✓ VERIFIED |
| Node MCP tests | 75/75; fail/cancelled/skipped/todo all zero | ✓ VERIFIED |
| Built Prometheus + external MCP smoke | Prometheus MCP live smoke passed against deterministic loopback model fixture | ✓ VERIFIED |
| Evaluation corpus | exactly 32; groups 6/5/5/5/4/4/3; 28 provider loops; four wire families | ✓ VERIFIED |
| Compatibility inventory | exactly 49 native, 12 alias, 22 typed_stub, five Phase 21 later_phase, two removed | ✓ VERIFIED |
| Security/resource/preservation gates | environment, GPL guard, artifact isolation, WebUI resources, static boundaries, and preservation pass | ✓ VERIFIED |
| Patch export | 54 ordered non-empty source-only patches; exact stable IDs; valid mutation rejected | ✓ VERIFIED |
| Reviewed build metadata | .ninja_log eccf79f3... and .ninja_deps ab1a6ad4... unchanged | ✓ VERIFIED |
| Diff/worktree checks before report write | root and nested diff checks pass; nested Chromium is clean | ✓ VERIFIED |

Named evidence is under
.context/chromium/src/out/Default/phase20-closeout/.

## Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| FSB-01 | 20-07, 20-11, 20-14 | Natural-language side-panel tasks | ✓ SATISFIED | Exact-window Ask FSB seed, explicit submit, safe title, native task execution, progress/result/recovery tests. |
| FSB-02 | 20-01, 20-02, 20-05, 20-07, 20-09, 20-10, 20-11, 20-14 | Auto/Provider/Local execution, visible lifecycle, same-runtime MCP adapter | ✓ SATISFIED | One native state machine; fresh authority/policy; bounded fallback; cancel/timeout/session-loss cleanup; MCP smoke and provenance. |
| FSB-03 | 20-04, 20-05, 20-07, 20-12 | Complete provider configuration and fallback | ✓ SATISFIED | All required provider kinds/routes, secure endpoint policy, model discovery, local-only mutations, ordered fallback. |
| FSB-04 | 20-04, 20-08, 20-12, 20-13 | Platform/browser secure provider secrets, never redisplayed | ✓ SATISFIED | OSCryptAsync envelopes, native password fields cleared after callback, metadata-only snapshots, sentinel-denial gates. |
| FSB-05 | 20-01, 20-02, 20-07, 20-12, 20-14 | Stored/displayed logs, actions, diagnostics, metrics, tokens/cost, outcomes | ✓ SATISFIED | Bounded persistent store and live control rows distinguish unknown from zero and exclude content/authority. |
| FSB-06 | 20-03, 20-07, 20-10, 20-13, 20-14 | Memory and site-guide save/list/retrieve/apply | ✓ SATISFIED | Bounded CRUD/search/restart/caller visibility and exact current document origin; control and MCP smoke. |
| FSB-07 | 20-04, 20-08, 20-13, 20-14 | Vault metadata, native-only secret flow, explicit confirmation | ✓ SATISFIED | Persisted/reconciled metadata, native entry, fresh one-use confirmation, double exact-target revalidation, private insertion. |
| FSB-08 | 20-01, 20-06, 20-09, 20-12, 20-13, 20-14 | User-facing enforced permissions/caps/ownership/background/telemetry/vault/supervision | ✓ SATISFIED | Native decisions affect admission/dispatch/emission; locked invariants render truthfully; supervision remains Not ready. |

No FSB-01 through FSB-08 requirement is orphaned.

## Threat Disposition

| Threat | Status | Verified mitigation |
|--------|--------|---------------------|
| T-20-01 | ✓ MITIGATED | Provider/page output is untrusted; unknown tools and injected authority fail before closed native actions and exact profile/session/tab/document checks. |
| T-20-02 | ✓ MITIGATED | Fixed endpoints, HTTPS custom remotes, exact loopback HTTP, omitted credentials/cookies/referrer/cache, redirect denial, and request/time/body bounds. |
| T-20-03 | ✓ MITIGATED | Secret/ciphertext/authorization/bootstrap sentinels are absent from prefs, WebUI, MCP, logs, diagnostics, audit, DOM, errors, corpus, and smoke output. |
| T-20-04 | ✓ MITIGATED | Vault approval binds caller/profile/window/tab/owner/origin/frame/document/refs/focus/expiry/generation and is one-use with repeated revalidation. |
| T-20-05 | ✓ MITIGATED | Task generation, owned loaders, weak callbacks, cancellation, timeout, shutdown, session loss, and FinishTaskOnce give exactly-once terminal behavior. |
| T-20-06 | ✓ MITIGATED | Fallback is limited to retryable pre-mutation failures and rechecks fresh authority, policy, limits, and exact provider binding. |
| T-20-07 | ✓ MITIGATED | Production and Node scans contain no agent subprocess, terminal, provider SDK/runtime, alternate engine selector, or prompt provisioner; MCP stays external. |
| T-20-08 | ✓ MITIGATED | Closed metadata-only events, deterministic bounds/eviction, safe titles, local/off telemetry, and recursive content-key denial prevent exfiltration and unbounded growth. |

## Anti-Patterns Found

| Scope | Pattern | Severity | Disposition |
|-------|---------|----------|-------------|
| Phase-owned production additions | TODO, FIXME, XXX, HACK, TBD, PLACEHOLDER, NOTIMPLEMENTED, or UNIMPLEMENTED debt markers | none | No matches. |
| Guard/validator paths | return false and return nullptr | ℹ Info | Defensive rejection and ineligible-profile paths, not stubs; success paths are wired and both branches are exercised by focused tests. |
| Provider network annotation | “Not implemented because direct provider access is the core function” | ℹ Info | Required policy_exception_justification text for direct user-configured provider networking, not unfinished code. |
| Supervision and five Phase 21 MCP names | not_ready / Not ready | ℹ Info | Intentional roadmap boundary and required truthful state, asserted by tests. |

No blocker or warning anti-pattern remains.

## Disconfirmation and Non-Claims

- The aggregate component-build prometheus_unittests linker closure is
  explicitly NOT_RUN and is not claimed as passing. Its unrelated Chrome
  navigation/prefetch/upgrade/file-selection symbol closure is outside the
  Phase 20 owned focused gates. The verifier directly compiled every owned
  object and rebuilt the focused binaries without changing Ninja metadata.
- No live paid provider credential or subjective real-Keychain UI walkthrough
  was used. Strict fake transports, injectable OSCrypt tests, real native
  dialogs, the 32-case corpus, and a built-app loopback provider prove the
  contract without exposing a secret or depending on an external service.
- human_uat: not_run. Remaining desktop screenshot/polish review is the
  consolidated non-blocking Phase 24 review; it cannot substitute for any
  missing functional or security gate.
- ROADMAP bookkeeping still says 13/14 plans and leaves 20-14 unchecked even
  though 20-14-SUMMARY.md, 20-VALIDATION.md, this fresh closeout, and the 54
  patches exist. This is a planning-metadata inconsistency, not a runtime goal
  gap, and this verifier was scoped to update only this report.

## Human Verification Required

None for Phase 20 acceptance. The only remaining subjective visual review is
explicitly deferred and non-blocking under Phase 24 success criterion 6.

## Gaps Summary

No actionable gap, regression, orphaned requirement, failed key link, or
blocking human check remains. Phase 20 is ready to proceed.

---

_Verified: 2026-07-20T18:39:52Z_
_Verifier: the agent (gsd-verifier)_

---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 09
subsystem: authenticated-runtime-gateway
tags: [chromium, cpp, mcp, runtime-codec, caller-isolation, health]

requires:
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 07
    provides: Regular-profile runtime, provider execution, and private caller authority
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 08
    provides: Sanitized vault metadata and native-only confirmation authority
  - phase: 19-mcp-bridge-and-multi-agent-runtime-compatibility
    provides: Authenticated loopback gateway, browser-issued sessions, and page routes
provides:
  - Exactly 27 closed bounded native runtime command schemas and sanitized result DTOs
  - Same-profile authenticated runtime dispatch with server-derived caller isolation
  - Stable LOCAL_UI_REQUIRED denial for every external provider mutation class
  - Live ten-component provider/vault health with later phases kept not_ready
affects: [20-10, 20-11, 20-12, 20-13, 20-14, phase-21, phase-22]

tech-stack:
  added: []
  patterns:
    - Keep runtime commands in a codec separate from page-action transport types
    - Derive profile and caller exclusively from a browser-issued session binding
    - Serialize metadata-only typed views with recursive authority and secret denial
    - Read provider and vault health from the same regular-profile runtime owner

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Keep the 27 runtime commands in a distinct closed codec so existing page routes remain byte-compatible and independently authorized."
  - "Pin a weak regular profile, normal Browser, and stable tab to each browser-issued session while retaining a random server-only caller UUID across resume."
  - "Reject external set_provider_config at the gateway before delegation and again at RuntimeProfileService, while preserving read-only provider discovery and diagnostics."
  - "Let RuntimeProfileService own the shared VaultService and OSCrypt SecretStore so gateway requests cannot observe stale parallel preference-backed stores."
  - "Report provider ready only when one entry is enabled, healthy, and local or backed by configured secret metadata; retain supervision and extensions as not_ready."

patterns-established:
  - "Runtime transport boundary: accept only one of 27 closed schemas, cap input/output, reject recursive reserved fields, and never serialize authority or secret values."
  - "Gateway authority boundary: the request supplies only an opaque browser session; profile, Browser, tab, origin, and caller identity remain server-owned."
  - "Caller isolation boundary: task ownership is recorded by the derived caller and enforced across task, run, log, and action reads."
  - "Health boundary: emit exactly ten content-free components from live sanitized owners, with no prompt, page, endpoint, provider body, secret, session, or profile path."

requirements-completed: []
requirements-progressed: [FSB-01, FSB-02, FSB-03, FSB-04, FSB-05, FSB-06, FSB-07, FSB-08]

duration: 2h
completed: 2026-07-16
---

# Phase 20 Plan 09: Authenticated Native Runtime Gateway Summary

**The browser gateway now accepts exactly 27 closed native runtime commands under an existing session, isolates every caller server-side, denies external provider mutation before state changes, and publishes live sanitized provider/vault health.**

## Performance

- **Duration:** 2h
- **Started:** 2026-07-16T15:25:46-05:00
- **Completed:** 2026-07-16T17:25:28-05:00
- **Tasks:** 3
- **Files modified:** 20 including 13 nested Chromium files, three exported patches, and four plan/tracking documents

## Accomplishments

- Added an exact 27-name runtime manifest with a distinct typed params variant for every command, a 1 MiB request cap, bounded values/lists, closed route schemas, recursive reserved-field rejection, and metadata-only typed results.
- Preserved the existing page route parser while adding authenticated runtime discrimination and dispatch through the same pinned regular profile, browser-issued session, stable tab, and server-derived caller.
- Enforced caller ownership across task submission/status/cancel/list, task runs, logs, actions, memory, and site-guide routes without accepting or serializing caller/profile/owner/session authority fields.
- Kept `set_provider_config` recognizable for compatibility but made every MCP invocation return stable typed `LOCAL_UI_REQUIRED` before mutation; RuntimeProfileService independently denies non-local callers.
- Exposed read-only provider config/list/discovery/diagnostics plus bounded vault metadata while keeping credential/payment value use behind typed native-confirmation outcomes and private Plan 20-08 authority.
- Reused one profile-owned VaultService and OSCrypt SecretStore through RuntimeProfileService so gateway and local runtime operations share the same preference-backed state.
- Replaced Phase 20 placeholder health with exact ten-key live state: provider eligibility follows enabled/healthy/local-or-secret-backed policy, vault reports its same-profile owner, and supervision/extensions remain `not_ready`.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1 (RED): Freeze runtime schemas, isolation, mutation denial, and health behavior** - nested `f628cfe8a8`; patch export root `e9b7e0c542`
2. **Task 2 (GREEN): Implement the authenticated closed runtime gateway** - nested `71bdf6b3ef`; patch export root `1d56cd27ad`
3. **Task 3 (GREEN): Publish live runtime health and regress existing transport contracts** - nested `d69eb101fa`; patch export root `19870b54e7`

**Plan metadata:** (this commit)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec.h` - Exact route enum, 27 typed parameter variants, bounded metadata-only result views, error vocabulary, and test manifest.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec.cc` - Closed envelope/schema parser, recursive reserved-field scanner, per-route bounds, and sanitized serializer.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_transport_codec_unittest.cc` - Eight exact-manifest, typed-schema, bounds, recursive-secret, metadata, and output-cap cases.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.h` - Runtime dispatch/test seams, live health input, and pinned session binding fields.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc` - Runtime/page discrimination, authenticated same-profile dispatch, task ownership, mutation denial, and live ten-component health.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway_unittest.cc` - Thirteen gateway authority, compatibility, health, and real native-endpoint cases.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.h` - Narrow provider, memory, site-guide, task-run, and vault transport facades plus shared vault ownership.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service.cc` - Same-profile facade implementation, defense-in-depth provider mutation gate, and shared VaultService construction.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_profile_service_unittest.cc` - Provider mutation, provider-pin, task-run, and vault metadata coverage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.h` - Sanitized metadata listing seam.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.cc` - Kind-filtered bounded metadata listing.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_vault_service_unittest.cc` - Metadata list/filter assertions.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Runtime codec source and focused test registration/dependencies.
- `patches/0023-test-20-09-freeze-runtime-transport-contract.patch` - 55,436-byte Task 1 RED export.
- `patches/0024-feat-20-09-implement-authenticated-runtime-gateway.patch` - 109,807-byte Task 2 GREEN export.
- `patches/0025-feat-20-09-publish-live-runtime-gateway-health.patch` - 18,726-byte Task 3 health/regression export.

## Decisions Made

- Runtime request schemas remain separate from `AgentRouteName` page commands. Route discrimination happens before the existing page parser, so Phase 17-19 byte compatibility and authorization stay intact.
- The browser session remains the only client-supplied authority. A session binding keeps weak profile/Browser ownership, a stable tab handle, and a random server-only caller UUID that survives resume only while that binding remains alive.
- Duplicate-submission fingerprints include the derived caller, and caller-to-task ownership is checked before task status/cancel, task-run, log, and action access.
- Provider mutation is denied twice: the gateway returns `LOCAL_UI_REQUIRED` before calling a service, and RuntimeProfileService accepts mutation only from the local control UI. Read-only discovery/config/diagnostics continue normally.
- RuntimeProfileService owns the VaultService that shares its profile-owned SecretStore; creating a second gateway-local store would have produced stale independent PrefService views and unsafe ownership.
- Provider health is ready only for the same eligibility used by registry execution: enabled, healthy, and either local or backed by configured secret metadata. Configured but inoperable providers are degraded; no configuration is not ready.
- Vault health currently reports the live profile-owned native vault service. Secret encryption/decryption remains per-operation and fail-closed because SecretStore exposes no non-mutating encryptor probe.
- Credential fill and payment use never acquire a public gateway insertion primitive. Until Plan 20-13 installs the exact-window native dialog delegates, they return typed unavailable/not-found status without a token or value.
- All FSB requirements remain tracked honestly as in progress except the previously completed FSB-06; this plan provides the native gateway layer but does not claim the later side-panel/control-panel user workflows.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added minimal production declarations for behavior-level RED tests**
- **Found during:** Task 1 (freeze all 27 runtime contracts)
- **Issue:** The planned tests could not compile or list without the codec types and gateway dispatch seams they were intended to constrain.
- **Fix:** Added only the compile-level route/params/result declarations and gateway test seam required to reach behavior assertions, then preserved RED through intended schema/dispatch failures.
- **Files modified:** runtime transport codec header/source, gateway header/source, and BUILD registration.
- **Verification:** Both exact list guards were non-empty; codec and gateway filters failed on owned behavior assertions with no compile, link, crash, or infrastructure failure.
- **Committed in:** `f628cfe8a8`

**2. [Rule 3 - Blocking] Centralized profile-owned runtime/vault transport state**
- **Found during:** Task 2 (implement authenticated dispatch)
- **Issue:** Constructing gateway-local services over the same PrefService created stale parallel stores, while VaultService had no single shared owner suitable for same-profile runtime dispatch.
- **Fix:** Made RuntimeProfileService own one VaultService sharing its OSCrypt SecretStore and exposed narrow typed provider, memory, task-run, site-guide, and vault facades; added sanitized vault metadata listing.
- **Files modified:** runtime profile service header/source/tests and vault service header/source/tests.
- **Verification:** Expanded RuntimeProfile/Vault regression passed 64/64 at the checkpoint, followed by the final codec/gateway and Task 3 matrices.
- **Committed in:** `71bdf6b3ef`

**3. [Rule 1 - Bug] Made global browser/profile lookup safe outside a fully initialized browser process**
- **Found during:** Task 3 real `/v1/health` endpoint regression
- **Issue:** `GlobalBrowserCollection::GetInstance()` unconditionally dereferences `g_browser_process->GetFeatures()`, and `ProfileManager::GetLastUsedProfileIfLoaded()` assumes `g_browser_process`; direct unit invocation crashed before health serialization.
- **Fix:** Added one availability helper guarding both global owners, used it at every gateway browser lookup, guarded last-profile fallback, and tested the actual native health handler.
- **Files modified:** gateway header/source/tests.
- **Verification:** The isolated native endpoint passed 1/1 and the final combined matrix passed 37/37.
- **Committed in:** `d69eb101fa`

---

**Total deviations:** 3 auto-fixed (one bug, two blocking issues). **Impact:** Each change was required to reach the specified behavior safely; no public secret/authority surface or unrelated feature was added.

## Issues Encountered

- The existing `out/Default` remained a mixed Ninja/Siso tree. No clean, reset, generator switch, branch change, or destructive operation was performed, and no broad target completion is claimed.
- Verification used focused production/test translation-unit compiles and the already-proven full `browser_tests` link edge with only owned temporary objects substituted. This preserved real link coverage without mutating the mixed output graph.
- The copied focused Mach-O retained a linker signature that passed static verification but macOS AMFI killed at execution. Re-signing the generated test-only artifact ad hoc made it runnable; no source, product binary, or repository artifact was changed.
- The real health endpoint test exposed that checking the pointer returned by `GlobalBrowserCollection::GetInstance()` was too late because the accessor dereferences the absent owner internally. Instruction mapping identified the reported caller return PC and led to the owner guard above.
- The bundled Chromium checkout has no executable clang-format wrapper. GN dry-run, compiler `-Werror`, diff check, and a zero-count added-line length scan were used; clang-format execution is not claimed.

## Verification

- Task 1 RED selected exactly 8 codec and 10 gateway cases. Each filter exited non-zero only on intended owned behavior assertions after clean compile/link; neither selection was empty and neither crashed.
- Task 2 focused acceptance selected 8 codec and 10 gateway cases and passed 18/18. The expanded RuntimeProfile/Vault checkpoint passed 64/64 before final codec hardening, and the fresh final codec/gateway binary again passed 18/18.
- Task 3 list guards selected exactly 8 `PrometheusRuntimeTransportCodecTest`, 13 `PrometheusAgentGatewayTest`, and 16 existing `PrometheusAgentTransportTest` cases; the combined serial filter passed 37/37 in 26 seconds.
- The actual native `/v1/health` handler passed its isolated 1/1 case and serialized exactly ten unique keys. `supervision` and `extensions` remained `not_ready`.
- Exact runtime manifest testing proved 27 and only 27 native names, distinct closed typed params, a 1 MiB input cap, recursive 16-level/4,096-field reserved-field scanning, bounded outputs, and absent authority/secret serialization.
- Gateway tests proved browser-session authorization, stable derived caller use, profile/task isolation, page-route compatibility, zero provider mutation with `LOCAL_UI_REQUIRED`, read-only provider dispatch, and content-free recovery.
- Provider readiness uses live metadata and the registry-equivalent enabled/healthy/local-or-secret-backed predicate; vault readiness comes from the live same-profile runtime owner.
- Production leak scans found zero exact prompt/page/provider-body/ciphertext/session/profile/query sentinels and zero old Phase 20 health placeholders. Added source lines over 80 columns: zero.
- Changed production/test translation units compiled cleanly with `-Werror`; the focused full-edge link log was empty. `git diff --check` and `gn format --dry-run chrome/browser/prometheus/BUILD.gn` passed.
- Patch identity checks matched source to export: Task 1 `af57085b80e58870c3e6dc539a8c48fdc56f9b5c`, Task 2 `96d985abe7dbd481dd6e8027eb0181b165ad3d5b`, and Task 3 `7195c50d8d22416dbc99d8717361a9f482e469ae`.
- All ordered exports 0023-0025 are non-empty and carry their exact nested source SHA in the format-patch header. Nested source and root patch trees were clean before summary creation.
- Broad target note: the mixed-output `autoninja -C out/Default prometheus_unittests` target was not run to completion and is not claimed. Focused TUs, the full browser link edge, exact list guards, and the selected 64/64, 18/18, and 37/37 regressions are the completion evidence.

Human UAT was not run and is not claimed; it remains deferred to the Phase 24 non-blocking visual review.

## User Setup Required

None. No provider credential, vault value, external account, live provider, MCP client, or manual configuration was required. External runtime exposure through the Node MCP bridge is Plan 20-10, and exact-window native vault dialogs remain Plan 20-13.

## Next Phase Readiness

Plan 20-10 can map its 31 MCP names to these 27 native routes plus four aliases and prove built-app external stdio smoke without inventing an alternate runtime or caller identity. The gateway already provides bounded typed outcomes, stable local-UI provider denial, and live health.

No source blocker remains. Plan 20-13 must still install exact-window native credential/payment entry and confirmation delegates; until then those value-bearing operations remain typed and fail closed.

## Self-Check: PASSED

- FOUND: all 13 nested source/test/BUILD paths
- FOUND: nested task commits `f628cfe8a8`, `71bdf6b3ef`, and `d69eb101fa`
- FOUND: matching ordered non-empty exports 0023 through 0025
- VERIFIED: exact 27-command manifest and fresh 18/18 codec/gateway gate
- VERIFIED: exact Task 3 census and combined 37/37 regression
- VERIFIED: real native health endpoint, live eligibility, and later-phase not-ready state
- VERIFIED: recursive authority/secret denial and production leak scans
- VERIFIED: all three commit-to-patch stable identities match
- VERIFIED: nested source and root patch trees clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-16*

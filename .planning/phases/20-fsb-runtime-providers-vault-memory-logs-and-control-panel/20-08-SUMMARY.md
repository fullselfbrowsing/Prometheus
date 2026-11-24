---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 08
subsystem: native-vault-authority
tags: [chromium, cpp, vault, native-confirmation, exact-browser, secret-hygiene]

requires:
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 04
    provides: Exact-bound encrypted secret storage and vault-specific secret kinds
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 07
    provides: Regular-profile runtime, private exact-Browser principal, and Agent-profile authority seam
  - phase: 17-native-agent-command-service-and-tab-ownership
    provides: Browser-owned Agent sessions, stable tabs, and ownership enforcement
  - phase: 18-page-adapter-dom-snapshot-and-action-verification
    provides: Typed page actions and document-bound target references
provides:
  - Bounded sanitized vault metadata with distinct credential/payment secret bindings and native-only entry delegates
  - Private move-only confirmed insertion authority with exact Browser/profile/session/owner/frame/document/ref/focus binding
  - Double target revalidation around decrypt plus deterministic typed field insertion and scoped plaintext wiping
  - Short-lived one-use MCP approval requiring an identical retry without exposing an approval token or secret
  - Real-window browser proof for accept, deny, missing delegate, navigation, ownership, refs, focus, expiry, replay, wrong window, cross-origin, and background-tab races
affects: [20-09, 20-10, 20-13, 20-14]

tech-stack:
  added: []
  patterns:
    - Keep vault values behind native delegates and encrypted storage while renderer-facing snapshots contain exactly six sanitized metadata fields
    - Capture the complete exact-window authority before prompting, revalidate before decrypt, revalidate again before insertion, and revalidate inside AgentService before every field
    - Make confirmed insertion a move-only C++-only method rather than an Agent route, runtime route, Mojo/JSON schema, catalog entry, or model tool
    - Treat MCP confirmation as an internal short-lived one-use capability keyed to the identical caller, entry, tab, document, refs, and request hash

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_vault_confirmation_browsertest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn
    - .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn

key-decisions:
  - "Keep the production confirmation dependency fail-closed until Plan 20-13 supplies the browser-owned Views dialogs; tests inject confirmation explicitly."
  - "Expose confirmed insertion only through AgentProfileService/AgentService C++ types, never through a public Agent/runtime route, transport schema, WebUI DTO, catalog, or model tool."
  - "Require the exact captured Browser, profile, window, stable tab, session owner, origin, process/frame, document, ordered refs, focus, generation, and expiry at every authority boundary."
  - "Decrypt only after the first post-confirmation revalidation, then revalidate again before moving scoped values into deterministic typed page actions."
  - "Clear an expired MCP approval after returning the typed expiry so a later request must begin a fresh native confirmation instead of being blocked by stale unconsumed state."

patterns-established:
  - "Native vault boundary: WebUI/MCP may handle metadata and typed outcomes, but value entry, encrypted values, and insertion plaintext stay browser-process native."
  - "Exact-target boundary: prompt binding and live target equality include Browser/profile/window/tab/owner/origin/frame/document/refs/focus with no last-active Browser lookup."
  - "Exactly-once boundary: generations, one-shot completion ownership, duplicate-callback guards, cancellation, shutdown, and per-field dispatch serials make late replies inert."
  - "Secret-lifetime boundary: move-only scoped values wipe before completion and content-free audits retain only status, field count, generation, and time."

requirements-progressed: [FSB-07]

duration: 1h16min
completed: 2026-07-16
---

# Phase 20 Plan 08: Native Vault Authority and Exact-Window Confirmation Summary

**Vault metadata and secret use now remain native-only, bind to one exact live browser target, decrypt only after confirmation and revalidation, and fail closed across every tested race without adding a public secret route.**

## Performance

- **Duration:** 1h16min
- **Started:** 2026-07-16T14:07:39-05:00
- **Completed:** 2026-07-16T15:23:22-05:00
- **Tasks:** 3
- **Files modified:** 18 including 11 nested Chromium files, three exported patches, and four plan/tracking documents

## Accomplishments

- Added bounded vault metadata CRUD with stable IDs, closed credential/payment kinds, canonical HTTP(S) origins, integer update times, and exactly one sanitized secret-state boolean.
- Added native-only secret entry/replace delegates and distinct encrypted-store bindings for credentials and payments; missing native entry or confirmation dependencies return typed failure.
- Added a move-only confirmed insertion request with scoped-wiping field values, exact captured authority, deterministic sequential dispatch, per-field fresh revalidation, duplicate callback fencing, and content-free audit records.
- Captured and compared the exact profile, Browser, window session, stable tab, Agent owner, canonical origin, render process/frame, document token, ordered refs, focus, caller, entry, request hash, generation, and expiry.
- Added double target revalidation around decrypt: confirmation approval revalidates before the encrypted read, and the read completion revalidates again before moving plaintext into Agent authority.
- Added short-lived one-use MCP approval that returns only `VAULT_NATIVE_CONFIRMATION_REQUIRED`, accepts one identical retry, rejects mismatch/replay/expiry, and exposes no capability token.
- Upgraded the in-process fixture to exercise the real `VaultService -> AgentProfileService -> AgentService` path, faking only the final typed field adapter while proving exact Browser and deterministic ref order.
- Proved fail-closed behavior for missing delegate, deny, same-origin and cross-origin navigation, owner/ref/document changes, background tab, wrong window/focus, expiry, replay, cancellation, and duplicate callbacks.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1 (RED): Specify vault metadata, native-only entry, and stale-target confirmation failures** - nested a996ea811b; patch export 27b5515fe
2. **Task 2 (GREEN): Implement metadata, internal approvals, and double-revalidated insertion** - nested c36513b1fd; patch export 37d1c829e
3. **Task 3 (GREEN): Prove fail-closed native delegation and real-window revalidation** - nested 9c35048823; patch export 63ed3021e

**Plan metadata:** (this commit)

## Files Created/Modified

- .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.h - Closed metadata, native entry/confirmation, target binding, approval, and use-result contracts.
- .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service.cc - Metadata CRUD, encrypted-store orchestration, exact approval matching, double revalidation, decrypt/insertion sequencing, cancellation, and shutdown.
- .context/chromium/src/chrome/browser/prometheus/prometheus_vault_service_unittest.cc - Seven metadata, entry, approval, race, expiry, cancellation, and secret-hygiene cases.
- .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.h - Move-only scoped values, confirmed target/request/result/audit types, and private C++ authority method.
- .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service.cc - Exact live target capture, request validation, replay fencing, sequential typed insertion, fresh per-field checks, wiping, and content-free audit.
- .context/chromium/src/chrome/browser/prometheus/prometheus_agent_service_unittest.cc - Five exact-binding, sequential failure, replay, callback, wiping, audit, and no-public-route cases.
- .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.h - Exact-Browser confirmed insertion facade and test seams.
- .context/chromium/src/chrome/browser/prometheus/prometheus_agent_profile_service.cc - Profile/Browser mismatch denial and exact forwarding to AgentService.
- .context/chromium/src/chrome/browser/prometheus/prometheus_vault_confirmation_browsertest.cc - Five real-window lifecycle and native-delegation cases.
- .context/chromium/src/chrome/browser/prometheus/BUILD.gn - Vault/Agent source and focused unit registration plus the required optimization-guide target dependency.
- .context/chromium/src/chrome/browser/ui/views/prometheus/BUILD.gn - Registration in the actual owning `browser_tests` target.
- patches/0020-test-20-08-specify-native-vault-authority.patch - 97,213-byte Task 1 RED export.
- patches/0021-feat-20-08-enforce-native-vault-insertion-authority.patch - 67,896-byte Task 2 GREEN export.
- patches/0022-test-20-08-prove-real-window-vault-authority.patch - 10,956-byte Task 3 browser-proof export.

## Decisions Made

- Metadata snapshots contain only `id`, `label`, `kind`, `canonical_site_origin`, `updated_time_ms`, and `secret_configured`; they have no value, suffix, username, payment field, ciphertext, approval token, or authority ID.
- Native entry accepts only a closed field set for the selected kind, writes one bounded encrypted envelope through the existing secret store, and never returns entered values to WebUI or MCP.
- The confirmed insertion seam is deliberately absent from AgentRouteName, RuntimeRouteName, parsers, schemas, public ExecuteRoute branches, catalogs, and model tools.
- The exact Browser supplied before prompting is retained throughout. ProfileService rejects a foreign profile/window, AgentService independently captures the live target, and no global or last-active browser lookup participates.
- The browser-origin flow continues directly after approval; MCP stops with a typed confirmation-required result and only an identical short-lived retry consumes its internal approval.
- Production has no permissive confirmation placeholder. A missing confirmation delegate performs zero decrypts and zero insertions until Plan 20-13 supplies the exact-window Views implementation.
- FSB-07 remains semantically open for its later WebUI/native-dialog integration; this plan completes its native metadata and insertion authority layer.

## Deviations from Plan

- The plan listed only `chrome/browser/prometheus/BUILD.gn`, but the existing Prometheus browser fixture is actually owned by `chrome/browser/ui/views/prometheus/BUILD.gn`. With explicit parent approval, Task 1 added the single required browser-test registration there; no other source-scope expansion occurred.

## Issues Encountered

- The existing `out/Default` remained a mixed Ninja/Siso tree. No clean, reset, generator switch, or destructive operation was performed, and no broad Chromium target completion is claimed.
- The stale unit-only link edge lacked the full dependency closure for the new browser/optimization-guide authority path. Verification reused the already-proven full `browser_tests` link edge with only the owned temporary objects substituted, allowing exact list guards and focused gtests without mutating the output graph.
- The first browser GREEN run exposed an expired, unconsumed MCP approval blocking a later fresh request. Resetting the expired approval after returning `VAULT_APPROVAL_EXPIRED` preserved fail-closed semantics and allowed the next request to prompt anew.
- The stronger Task 3 fixture initially shared one fake clock between vault approval expiry and Agent-session liveness, unintentionally expiring the owner session. Separate deterministic vault and authority clocks isolated the intended wrong-window race.

## Verification

- Task 1 RED evidence: Vault selected 7 and failed 7/7 intended metadata assertions; confirmed-Agent selected 5 and the filter exited non-zero on four intended authority assertions; browser selected 4 and failed 4/4 intended binding/metadata assertions. All RED translation units compiled and linked, with no empty-selection, crash, or infrastructure failure.
- Final list guards: 7 `PrometheusVaultServiceTest`, 5 `PrometheusAgentServiceTest.*ConfirmedVault*`, 11 `PrometheusSecretStoreTest`, and 5 `PrometheusVaultConfirmationBrowserTest` cases.
- Final focused unit gate: all 23/23 Vault, confirmed-Agent, and SecretStore tests passed.
- Final serial browser gate: all 5/5 exact-window confirmation tests passed through the real profile/service authority seam.
- Changed production and browser-test translation units compiled cleanly after final formatting; the focused full-edge runner linked without unresolved symbols.
- Static authority scan found confirmed-insertion symbols only in AgentService/ProfileService, VaultService, and their owned tests. Agent routes and WebUI/common schemas had zero confirmed-vault insertion hits.
- Production exact-secret sentinel scan had zero hits. Unit/browser checks kept exact plaintext/ciphertext/payment sentinels out of sanitized metadata, prefs, audit, typed outcomes, and WebContents-visible text.
- Runtime surface scan found only the pre-existing locked policy booleans `vault_native_only` and `vault_confirm_each_use`, never a new runtime route or DTO.
- Patch identity checks passed: Task 1 `a9caa2465f98f8ee85461a319347b1161a5d5c28`, Task 2 `9c2b69f4454f97908eac00e1a7fae0aaf4586dfd`, and Task 3 `de664501f073a8cd2c2a6e524832ab9bcf3fb7ca` matched commit and export.
- Nested source and root patch trees were clean at every task boundary; final source diff check passed.
- Broad target note: the mixed-output full `prometheus_unittests browser_tests` build was not run to completion and is not claimed. Focused translation-unit compiles, full browser-edge links, exact list guards, 23/23 units, and 5/5 serial browser tests are the completion evidence.

Human UAT was not run and is not claimed; it remains deferred to the Phase 24 non-blocking visual review.

## User Setup Required

None. No real vault value, provider credential, external account, live provider, MCP client, or manual configuration is required. The production native Views entry/confirmation surfaces remain intentionally absent and fail closed until Plan 20-13.

## Next Phase Readiness

Plan 20-09 can expose closed runtime commands through the authenticated native gateway while treating vault use as typed metadata/status orchestration only; the move-only insertion authority remains private C++ and cannot become a gateway route. Plan 20-13 can supply the exact-window native Views entry and confirmation delegates without changing the security contract proved here.

No source blocker remains. The pre-existing mixed Ninja/Siso output directory should be normalized only through an explicitly authorized build-maintenance action, not as part of this plan.

## Self-Check: PASSED

- FOUND: all 11 nested source, test, and BUILD paths
- FOUND: nested task commits a996ea811b, c36513b1fd, and 9c35048823
- FOUND: matching ordered non-empty exports 0020 through 0022
- VERIFIED: exact focused native gate 23/23 green
- VERIFIED: serial real-window browser gate 5/5 green
- VERIFIED: no public insertion route/schema and no production exact-secret sentinel
- VERIFIED: all three commit-to-patch stable identities match
- VERIFIED: nested source tree clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-16*

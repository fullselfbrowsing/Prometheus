---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 04
subsystem: native-provider-secrets-and-registry
tags: [chromium, cpp, oscrypt, prefs, providers, endpoint-policy, tdd]

requires:
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 01
    provides: Versioned non-syncable profile prefs, native-only secret policy, and bounded UTF-8 contracts
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 02
    provides: Strict profile persistence and fail-closed hydration patterns
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 03
    provides: Shared-profile sub-store and exact canonical URL policy patterns
provides:
  - Callback-only browser-process secret interface backed by injectable OSCryptAsync
  - Versioned encrypted envelopes bound to record ID, secret kind, owner kind, and full canonical endpoint or site URL
  - Closed provider kind, family, route, health, discovery, capability, model, and fallback metadata
  - Fixed hosted endpoints plus strict HTTPS custom and net::IsLocalhost local endpoint policy
  - Schema-checked metadata persistence, exact provider-secret bindings, and endpoint/kind secret invalidation
affects: [20-05, 20-07, 20-08, 20-09, 20-12, 20-13, 20-14]

tech-stack:
  added: []
  patterns:
    - Injectable OSCryptAsync acquisition with weak callback ownership and compare-before-reencrypt replacement
    - Versioned authenticated JSON envelopes with exact binding-field validation before secret release
    - Closed provider catalog with enum-only request routes and canonical endpoint construction
    - Strict allowlisted provider persistence with deterministic fallback order and content-free typed errors

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_secret_store.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_secret_store.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_secret_store_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Authenticate the complete canonical endpoint or site URL inside every encrypted envelope, so even a path-only provider endpoint change cannot reuse prior secret material."
  - "Acquire OSCrypt asynchronously for every operation, make destroyed owners inert through weak callbacks, wipe plaintext buffers, and replace ciphertext only when the record still matches the value that was read."
  - "Keep known hosted and routed providers on fixed HTTPS endpoints; allow HTTP only for explicit local kinds accepted by net::IsLocalhost, and require canonical HTTPS for remote custom providers."
  - "Invalidate secret_configured atomically whenever provider kind or canonical endpoint changes, and resolve disabled, non-healthy, or secret-missing remote providers through typed closed errors."

patterns-established:
  - "Secret bytes exist only in the native callback API and encrypted envelope; prefs, snapshots, errors, renderer DTOs, MCP, and logs receive metadata only."
  - "Provider IDs and fallback ranks are unique and bounded; loaded records must match an exact schema and all model IDs are path-segment safe."
  - "Provider networking receives only a provider ID plus a closed request-route enum; callers cannot supply per-request URLs, suffixes, query values, fragments, or redirects."

requirements-completed: []
requirements-progressed: [FSB-03, FSB-04, FSB-07, FSB-08]

duration: 49min
completed: 2026-07-15
---

# Phase 20 Plan 04: Encrypted Secrets and Closed Provider Registry Summary

**Browser-process OSCrypt envelopes now keep provider and vault secret bytes behind exact binding checks, while a restart-safe closed provider registry owns endpoint policy, models, discovery state, and deterministic fallback without accepting ambient request URLs.**

## Performance

- **Duration:** 49 min
- **Started:** 2026-07-15T15:13:00-05:00
- **Completed:** 2026-07-15T16:02:00-05:00
- **Tasks:** 3
- **Files modified:** 11 including exported patches and this summary

## Accomplishments

- Added a callback-only native secret contract for save, read, replace, and delete, with browser-process production construction and injectable fake OSCrypt for keychain-free tests.
- Persisted only versioned base64 ciphertext plus safe binding metadata below `prometheus.runtime`; plaintext is scoped, wiped, and absent from all profile and diagnostic snapshots.
- Authenticated record ID, secret kind, owner/provider kind, and the complete canonical HTTP(S) endpoint or site URL before returning decrypted data.
- Preserved prior ciphertext on encryption, transient decryption, and re-encryption failures; compare-before-swap prevents an asynchronous re-encrypt from overwriting a newer record.
- Added all ten provider kinds, three codec families, four route classes, fixed hosted/routed HTTPS endpoints, strict loopback local handling, HTTPS-only remote custom handling, bounded models/discovery, health, capabilities, and unique fallback ranks.
- Persisted provider metadata through an exact versioned schema, skipped malformed records, restored valid records across restart, and exposed only allowlisted metadata snapshots.
- Bound provider secrets to `provider:<stable-id>`, kind, and full canonical endpoint; endpoint or kind changes clear `secret_configured` in the same atomic registry mutation.
- Constructed inference and discovery URLs solely from validated registry metadata plus a closed route enum, with same-origin checks and no userinfo, query, fragment, or caller-controlled suffix path.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1: Specify encrypted secret and provider policy behavior (RED)** - nested `bbed3bfaad`; patch export `10da0edf4`
2. **Task 2: Implement the exact-bound OSCrypt secret store (GREEN)** - nested `e5ebaa8b64`; patch export `f5dcf2a58`
3. **Task 3: Implement the closed provider registry (GREEN)** - nested `b5d9517942`; patch export `f5be4c3d5`

**Plan metadata:** (this commit)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_secret_store.h` - Native callback API, bounded binding/result/error types, injectable implementation, and production factory.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_secret_store.cc` - OSCryptAsync acquisition, versioned envelope encryption/decryption, secure clearing, exact binding checks, failure preservation, and metadata-only snapshots.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_secret_store_unittest.cc` - Fake key-ring lifecycle, mismatch, corruption, transient failure, re-encryption, destruction, OTR, invalid-input, and plaintext-absence coverage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.h` - Closed provider catalog, bounded metadata, registry operations, request routes, typed resolution, and provider-secret binding API.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.cc` - Endpoint policy, schema persistence, discovery updates, fallback ordering, secret invalidation, sanitized snapshots, and enum-only URL construction.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry_unittest.cc` - Ten catalog, endpoint, limits, binding, invalidation, resolution, request-route, persistence, and redaction tests.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Secret-store and provider-registry source sets, direct dependencies, and test registration.
- `patches/0008-test-20-04-specify-encrypted-secrets-and-provider-policy.patch` - 60,971-byte compileable RED contract patch.
- `patches/0009-feat-20-04-implement-exact-bound-oscrypt-secret-store.patch` - 24,496-byte secret-store GREEN patch.
- `patches/0010-feat-20-04-implement-closed-provider-registry.patch` - 37,377-byte provider-registry GREEN patch.

## Decisions Made

- Used `OSCryptAsync` rather than a platform-specific credential API so production follows Chromium's browser-process encryption boundary while tests inject an in-memory key ring and never touch Keychain.
- Encrypted a versioned JSON envelope instead of only the secret string. Decrypt success is insufficient unless every stored binding field exactly matches the caller's current binding.
- Treated encryptor absence and transient decrypt failure separately from corrupt data. Recoverable failures preserve the record and never downgrade or erase the last valid ciphertext.
- Required fixed exact endpoints for named hosted/routed kinds. Custom remote endpoints must already be canonical HTTPS, while local HTTP/HTTPS is limited to explicit local kinds and `net::IsLocalhost`.
- Rejected model IDs containing empty or dot path segments so Gemini/OpenAI-compatible path construction cannot normalize into an unintended API path.
- Required remote providers to be enabled, healthy, and secret-configured before resolution. Explicit local routes may operate without an API secret, but endpoint/kind changes still invalidate any previously bound secret state.
- Kept requirements semantically open: this plan advances FSB-03/04/07/08 primitives, while Plans 20-05, 20-08, 20-12, and 20-13 still own networking, vault metadata/confirmation, and user-facing provider/settings completion.

## Deviations from Plan

None - all three RED/GREEN tasks, atomic nested commits, ordered patch exports, and required security checks were completed. The execution handoff required the warmed raw Ninja binary in place of `autoninja`; no build cache was cleaned or regenerated through Siso.

## Issues Encountered

- The compileable RED target linked successfully and failed behaviorally as intended: the secret fixture had ten expected failures with the OTR guard already passing, and the registry fixture had nine expected failures. Neither suite crashed, selected zero tests, or hid disabled tests.
- The first registry GREEN compile exposed current Chromium API naming (`GURL::path()` rather than `path_piece()`). The accessor was corrected before the GREEN commit; subsequent raw Ninja builds and all tests passed.
- Exact `git format-patch` files contain standard mail/context whitespace when viewed as newly added root files. They were retained byte-for-byte as generated, verified non-empty and reverse-applicable, and both repositories are clean after their patch-only commits.

## Verification

- Raw `third_party/ninja/ninja -C out/Default prometheus_unittests` build - passed; final source and strengthened-test rebuild compiled and linked successfully.
- `PrometheusSecretStoreTest.*` list guard - 11 registered tests, zero disabled.
- `PrometheusProviderRegistryTest.*` list guard - 10 registered tests, zero disabled.
- Combined plan gate - all 21 tests passed.
- Full `prometheus_unittests` regression - all 184 tests passed.
- Secret lifecycle evidence - save/read/replace/delete, exact mismatch, corrupt ciphertext, encrypt/decrypt/re-encrypt failure preservation, compare-before-swap, destroyed-owner, OTR, and invalid binding cases passed.
- Provider policy evidence - all ten kinds, fixed HTTPS endpoints, canonical remote custom, exact localhost routes, ambiguous authority/dot-segment rejection, model bounds, fallback uniqueness/order, closed health/secret errors, restart persistence, and exact request paths passed.
- Redaction evidence - exact credential, password, authorization, ciphertext, plaintext, raw-error, suffix, and endpoint-query sentinels are absent from prefs and sanitized snapshots.
- Chromium formatting, nested source `git diff --check`, clean nested/root worktrees, and explicit-file staging checks - passed.
- Export evidence - patches 0008-0010 are ordered and non-empty; patch 0010 reverse-applies at nested HEAD and names nested commit `b5d9517942`.

Human UAT was not run and is not claimed; it remains deferred to the Phase 24 non-blocking visual review.

## User Setup Required

None. Tests use an injected in-memory encryptor; no external provider key, platform keychain prompt, or service account is required for this native foundation.

## Next Phase Readiness

Plan 20-05 can consume validated provider metadata, exact request URLs, and native secret bindings for the three strict codec families and cancellable network transport. Plans 20-08 and 20-13 can reuse the same encrypted boundary for vault metadata, fresh confirmation, and native-only secret dialogs without exposing secret bytes to WebUI or MCP.

## Self-Check: PASSED

- FOUND: secret-store and provider-registry headers, implementations, focused fixtures, and BUILD wiring
- FOUND: nested RED/GREEN commits `bbed3bfaad`, `e5ebaa8b64`, and `b5d9517942`
- FOUND: matching non-empty exported patches `0008`, `0009`, and `0010`
- VERIFIED: 11 secret tests plus 10 provider tests green with zero disabled
- VERIFIED: complete 184-test native regression green
- VERIFIED: both repositories clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-15*

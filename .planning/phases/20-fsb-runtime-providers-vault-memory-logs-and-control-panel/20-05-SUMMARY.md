---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 05
subsystem: native-provider-protocols-and-transport
tags: [chromium, cpp, provider-codecs, url-loader, network-security, cancellation]

requires:
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 01
    provides: Closed runtime usage, bounds, execution policy, and safe-result types
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 04
    provides: Exact-bound native secrets, closed provider metadata, and registry-owned request URLs
provides:
  - Provider-neutral bounded turn and model-list contracts for OpenAI-compatible, Anthropic Messages, and Gemini generateContent wire families
  - Strict JSON encoding and normalization with at most one advertised closed tool call, bounded usage, typed stop reasons, and credential-echo containment
  - Cancellable browser-process SimpleURLLoader transport with registry-only URLs, exact-bound secret revalidation, transient isolation, and no ambient browser credentials
  - Narrow typed retry classification for network, rate-limit, and server outcomes only
affects: [20-07, 20-09, 20-12, 20-14]

tech-stack:
  added: []
  patterns:
    - Three explicit base::Value codec adapters normalize provider wire formats into one bounded native DTO
    - Provider transport resolves registry URL and exact secret binding twice, including immediately before constructing the authenticated request
    - SimpleURLLoader operations own cancellation, timeout, redirect rejection, bounded buffering, transient network isolation, and terminal callback delivery
    - Raw response and credential buffers are securely cleared, while exact credential echoes in text are redacted and echoes in tool/model data are rejected

key-files:
  created:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport_unittest.cc
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Keep exactly three native wire families behind provider-neutral request/result DTOs; compatible provider kinds select a family through registry metadata and never add an SDK or auxiliary runtime."
  - "Treat model discovery support as an explicit capability before any secret read or loader construction, and refuse pagination rather than widening the bounded one-response contract."
  - "Re-resolve the complete provider record, request URL, and exact secret binding after asynchronous decryption and immediately before send so endpoint or capability drift cannot reuse credential material."
  - "Use credentials_mode omit, cookie blocking, empty referrer, cache bypass, transient IsolationInfo, family-only authentication headers, and terminal redirect rejection for inference and discovery alike."
  - "Classify only network, rate-limit, and server outcomes as retryable; authentication, endpoint policy, invalid output, bounds, secret, cancellation, and timeout remain terminal."

patterns-established:
  - "Codec boundary: validate request fields before JSON encoding; validate documented response locations, bounds, UTF-8, usage, advertised tool names, and zero-or-one call before returning a native DTO."
  - "Transport boundary: a provider ID and closed route enum are the only routing inputs; caller URLs, query credentials, ambient cookies, automatic redirects, and automatic transport retries are absent."
  - "Cancellation boundary: erase the task-owned operation to destroy its loader and credential buffer; weak callbacks and operation lookup make every late secret/network completion inert."

requirements-completed: []
requirements-progressed: [FSB-02, FSB-03, FSB-04, FSB-05]

duration: 55min
completed: 2026-07-16
---

# Phase 20 Plan 05: Strict Provider Codecs and Secure Transport Summary

**Three strict native provider wire families now normalize bounded turns and model discovery through a registry-authoritative, origin-bound, ambient-credential-free, cancellable Chromium network transport.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-07-16T03:15:00-05:00
- **Completed:** 2026-07-16T04:10:00-05:00
- **Tasks:** 3
- **Files modified:** 15 including exported patches and plan metadata

## Accomplishments

- Added provider-neutral turn, safe-result, usage, stop-reason, closed tool-call, and model-list DTOs with hard byte/token/count bounds.
- Encoded OpenAI Responses with `store=false`, bounded OpenAI-compatible Chat, Anthropic Messages with single-call tool choice, and Gemini generateContent without introducing any provider SDK or runtime.
- Parsed documented text, tool, usage, stop, and model-list locations for all three families; malformed UTF-8/JSON, unknown or multiple calls, oversized content, unsupported discovery, and pagination produce closed typed outcomes.
- Deterministically deduplicated bounded OpenAI/Anthropic model IDs and normalized only Gemini models that explicitly advertise `generateContent`.
- Redacted exact active-credential echoes from final text, rejected them in tool arguments/call IDs and discovered model IDs, and securely cleared raw response and active credential buffers.
- Implemented `ExecuteTurn`, `DiscoverModels`, and loader-destruction `Cancel` over injected `SharedURLLoaderFactory`, limits, and `TickClock` seams.
- Applied the same registry-only URL, exact-bound secret, family header, request isolation, timeout, response cap, redirect, and cancellation rules to inference and discovery.
- Classified only network, HTTP 429, and HTTP 5xx outcomes as retryable; authentication, policy, parse, bounds, secret, cancellation, and timeout outcomes remain terminal.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1: Specify provider protocol and transport security behavior (RED)** - nested `2253a8f814`; patch export `f78f9167f`
2. **Task 2: Implement three strict provider codec families (GREEN)** - nested `cacf44897f`; patch export `73ed3cbba3`
3. **Task 3: Implement secure cancellable direct provider transport (GREEN)** - nested `07389da241`; patch export `44cc80c0d`

**Plan metadata:** (this commit)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec.h` - Provider-neutral bounded turn/model request, result, stop, error, usage, and validated-call contracts.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec.cc` - Three explicit JSON encoders/parsers, strict model discovery, redaction, raw-buffer disposal, and narrow retry classification.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_codec_unittest.cc` - Seventeen wire, bounds, malformed-data, redaction, discovery, support, and retry fixtures.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport.h` - Cancellable operation API, injected factory/limits/clock seams, and in-flight ownership.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport.cc` - Exact-bound secret reads, pre-send registry revalidation, hardened ResourceRequest construction, redirect/timeout/cancel handling, buffered parsing, and typed network mapping.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_transport_unittest.cc` - Twelve TestURLLoaderFactory cases covering methods, paths, headers, isolation, unsupported discovery, cancellation races, endpoint drift, redirects, status mapping, timeout, bounds, and secret errors.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry.cc` - Capability-gated Anthropic model-list route correction.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_provider_registry_unittest.cc` - Exact negative/positive capability test for the Anthropic `/v1/models` route.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - Codec/transport source sets plus crypto, net, URLLoader, Mojo, URL, and test dependencies.
- `patches/0011-test-20-05-specify-provider-protocols-and-transport-security.patch` - 55,147-byte compileable RED contract patch.
- `patches/0012-feat-20-05-implement-strict-provider-codecs.patch` - 33,029-byte codec GREEN patch.
- `patches/0013-feat-20-05-implement-secure-provider-transport.patch` - 29,685-byte transport GREEN patch.

## Decisions Made

- Kept OpenAI Responses and OpenAI-compatible Chat as two registry-selected shapes within one OpenAI-compatible family; provider callers cannot select arbitrary request paths or wire suffixes.
- Required every advertised tool schema to be a bounded closed object and every returned call to match one advertised lower-case native name, one bounded ID, and one dictionary argument payload.
- Refused provider pagination tokens instead of silently making unbounded follow-up requests; model discovery remains a single bounded capability-gated GET.
- Used a fresh transient `IsolationInfo` because the profile network context requires a NetworkAnonymizationKey, while `credentials_mode=kOmit` and `kURLLoadOptionBlockAllCookies` keep profile state out of provider requests.
- Preserved cancellation as local erasure without a terminal callback, matching SimpleURLLoader deletion semantics and ensuring late secret/network callbacks cannot send or mutate state.
- Kept transport retries disabled. The closed retry classifier is evidence for the later runtime fallback policy, which will create a fresh request and secret read only when Plans 20-07/14 authorize it.
- Left FSB-02/03/04/05 semantically open because provider runtime orchestration, gateway/UI exposure, settings, and integration-corpus completion remain owned by later Phase 20 plans.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed an obsolete unconditional Anthropic discovery rejection**
- **Found during:** Task 3 (secure direct provider transport)
- **Issue:** `PrometheusProviderRegistry::BuildRequestUrl(kModels)` rejected Anthropic even when the registry capability explicitly enabled discovery, so the required registry-only Anthropic fixture could never construct `/v1/models`.
- **Fix:** Kept the route capability-gated, removed only the family-specific denial, and added an exact negative/positive registry regression for `https://api.anthropic.com/v1/models`.
- **Files modified:** `prometheus_provider_registry.cc`, `prometheus_provider_registry_unittest.cc`
- **Verification:** All 11 registry tests and the supported/unsupported transport discovery cases pass.
- **Committed in:** `07389da241`

---

**Total deviations:** 1 auto-fixed blocking dependency correction.
**Impact on plan:** The correction is required by the planned Anthropic discovery contract, preserves registry-only URL authority, and adds no new provider family or route surface.

## Issues Encountered

- The compileable RED checkpoint registered exactly 17 codec and 12 transport tests after a successful link. Fourteen codec cases and all twelve transport cases then failed on intended behavior assertions; the three already-true codec support/retry primitives remained green.
- Chromium's raw-reference checker rejected a temporary native reference member in the response-buffer wiper. It was replaced with an explicitly included `raw_ptr`, after which warning-as-error compilation remained clean.
- The profile network context requires every consumer to provide a NetworkAnonymizationKey. The transport now supplies a fresh transient `IsolationInfo`, strengthening both production compatibility and cross-request state isolation.
- Exact `git format-patch` exports contain standard mail/context whitespace when viewed as newly added root files. They remain byte-for-byte generated, ordered, non-empty, and the final patch reverse-applies cleanly at nested HEAD.

## Verification

- Raw `third_party/ninja/ninja -C out/Default prometheus_unittests` build - passed after the final source and test hardening changes.
- Codec list guard - 17 registered tests, zero disabled; all 17 passed.
- Transport list guard - 12 registered tests, zero disabled; all 12 passed.
- Registry regression - 11 registered tests including exact Anthropic discovery capability gating; all 11 passed.
- Combined provider gate - all 40 codec, transport, and registry tests passed with `EXIT_CODE=0`.
- Complete native regression - all 214 `prometheus_unittests` cases passed with `EXIT_CODE=0`.
- Request-security evidence - registry-only same-origin URLs, transient isolation, omitted credentials and cookies, empty referrer, bypassed cache, family-only auth/version headers, no query secret, and terminal redirects are asserted through `TestURLLoaderFactory`.
- Lifecycle evidence - loader deletion, pre-secret cancel, endpoint drift, late callback suppression, two-second timeout, request/response byte caps, and secret-store error paths are asserted deterministically without live network or credentials.
- Static boundary audit - no provider SDK, subprocess runtime, arbitrary tool surface, or forbidden codec tool term appears in production codec/transport sources or BUILD dependencies.
- Nested source and root worktree `git diff --check`, explicit-file staging, and final cleanliness checks - passed.
- Export evidence - patches 0011-0013 are ordered and non-empty at 55,147, 33,029, and 29,685 bytes; patch 0013 reverse-applies at nested HEAD and names nested commit `07389da241`.

Human UAT was not run and is not claimed; it remains deferred to the Phase 24 non-blocking visual review.

## User Setup Required

None. Every request uses injected fake secrets and `TestURLLoaderFactory`; no live provider key, network service, SDK, subprocess runtime, or external account is required.

## Next Phase Readiness

Plan 20-06 can add safe-title persistence and the native policy/session-cap primitives on top of bounded runtime metadata. Plan 20-07 can then assemble the task loop over these provider-neutral codecs and cancellable operations, with fresh-request fallback and cancellation state remaining native and typed.

FSB-02, FSB-03, FSB-04, and FSB-05 remain in progress until their later runtime, gateway/UI, settings, and integration gates are complete. No blocker remains for Plan 20-06.

## Self-Check: PASSED

- FOUND: codec and transport headers, implementations, focused fixtures, registry correction, and BUILD wiring
- FOUND: nested RED/GREEN commits `2253a8f814`, `cacf44897f`, and `07389da241`
- FOUND: matching non-empty exported patches `0011`, `0012`, and `0013`
- VERIFIED: 17 codec, 12 transport, and 11 registry cases green with zero disabled
- VERIFIED: complete 214-test native regression green
- VERIFIED: both repositories clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-16*

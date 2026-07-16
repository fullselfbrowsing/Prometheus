---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 06
subsystem: runtime-safe-title-and-policy
tags: [chromium, cpp, safe-title, redaction, policy, telemetry, agent-sessions]

requires:
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 01
    provides: Closed runtime types, local versioned prefs, execution limits, and immutable native security boundaries
  - phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
    plan: 02
    provides: Generation-fenced task store, bounded sanitized snapshots, schema-v1 restart hydration, and exactly-once task completion
  - phase: 19-mcp-client-and-agent-contract-restoration
    provides: Opaque Agent sessions, browser-owned tab ownership, and typed route results
provides:
  - Deterministic prompt-derived safe task titles with redaction, valid-UTF-8 truncation, schema-v1 fallback, and no persisted raw prompt
  - Closed native task, Agent, dispatch, ownership, and telemetry policy decisions evaluated from fresh effective policy
  - Local non-syncable max_active_agents policy with default 4 and clamp 1..64
  - Production Agent-session admission enforcement that rejects only new work and never evicts existing sessions or ownership
affects: [20-07, 20-09, 20-13, 20-14]

tech-stack:
  added: []
  patterns:
    - Derive and redact the sole prompt-derived persisted field before task creation; the runtime store never accepts a raw prompt
    - Clamp persisted policy into a fresh effective value and then force ownership, native-vault, per-use-confirmation, and supervision locks
    - Represent admission, dispatch, ownership, and telemetry outcomes with closed content-free enums rather than caller-selected behavior
    - Lowered concurrency caps reject only new admissions; active task/session state and tab ownership continue through normal close or expiry

key-files:
  created: []
  modified:
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.h
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_session_unittest.cc
    - .context/chromium/src/chrome/browser/prometheus/BUILD.gn

key-decisions:
  - "Derive safe_title at the explicit task-creation boundary and pass only that bounded value into RuntimeStore::CreateTask, so the store has no API capable of receiving the original prompt."
  - "Keep schema version 1: records missing safe_title hydrate as Browser task for compatibility, while present empty, non-string, invalid-UTF-8, or oversized values are corrupt."
  - "Evaluate every admission and dispatch against a fresh clamped RuntimePolicy; policy denial precedes ownership and delegate dispatch, and allowed dispatch still requires an already-owned target."
  - "Treat telemetry Off as a no-emission decision at the source and local-only telemetry as a closed content-free event enum, leaving no payload or remote transport seam."
  - "Apply max_active_agents only to new Agent sessions; lowering the cap cannot erase active sessions, touch ownership, or alter normal close/expiry cleanup."

patterns-established:
  - "Safe-title boundary: collapse ASCII whitespace, redact URL/email/digit-run/key-value and credential spans, prefix Task:, truncate on a valid UTF-8 boundary at 96 bytes, and fall back exactly to Browser task."
  - "Effective-policy boundary: clamp caller/pref inputs first, then unconditionally lock tab ownership, native-only vault access, confirmation on every secret use, and supervision-not-ready."
  - "Non-evicting admission boundary: typed cap decisions prevent new task/session creation without mutating active records or ownership."

requirements-completed: []
requirements-progressed: [FSB-02, FSB-05, FSB-08]

duration: 25min
completed: 2026-07-16
---

# Phase 20 Plan 06: Safe Task Titles and Native Policy Enforcement Summary

**Tasks now persist only deterministic bounded redacted titles, while fresh closed native decisions enforce task, Agent, dispatch, ownership, vault, and telemetry policy without evicting active work.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-16T04:25:50-05:00
- **Completed:** 2026-07-16T04:50:50-05:00
- **Tasks:** 2
- **Files modified:** 17 including exported patches and plan metadata

## Accomplishments

- Added `RuntimeTaskSnapshot::safe_title`, the exact `Browser task` fallback, and a 96-byte valid-UTF-8 ceiling without adding a persisted prompt field.
- Derived titles before `CreateTask`, collapsed ASCII whitespace, and deterministically redacted URLs, emails, long digit runs, key/value material, and credential-bearing spans.
- Preserved schema-v1 compatibility by hydrating older missing-title records with the fallback while rejecting present malformed title values as corrupt.
- Added closed `RuntimePolicyDecision` values for task/Agent admission, dispatch/ownership, internal-surface, background-action, and telemetry decisions.
- Added content-free `RuntimeTelemetryEventKind` values and blocked telemetry at the emission decision when policy is Off.
- Persisted `max_active_agents` in the existing local, non-syncable, versioned profile namespace with default 4 and clamp 1..64.
- Added production Agent-session admission and cap setters; cap decreases preserve every active session and ownership record through normal close or expiry.
- Forced effective policy to retain tab ownership, native-only vault access, confirmation on every use, and supervision-not-ready regardless of weakening inputs.

## Task Commits

Each nested Chromium task was committed atomically and immediately exported:

1. **Task 1: Add bounded safe task titles** - nested `7e59c5126f`; patch export `20b27223c`
2. **Task 2: Enforce closed runtime policy decisions** - nested `c1bfa54a05`; patch export `2ee74ec1d`

**Plan metadata:** (this commit)

## Files Created/Modified

- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.h` - Safe-title bounds/fallback plus effective policy, closed decision, and content-free telemetry contracts.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types.cc` - Deterministic safe-title derivation and fresh task, Agent, dispatch, ownership, and telemetry decision evaluation.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_types_unittest.cc` - Exact redaction, whitespace, UTF-8, policy admission/dispatch, telemetry-off, and locked-vault fixtures.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store.h` - Task creation accepts only an already-derived safe title.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store.cc` - Safe-title persistence, schema-v1 fallback hydration, and malformed-value rejection.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_store_unittest.cc` - Restart persistence, compatibility fallback, corruption, and recursive content-sentinel coverage.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.h` - RuntimePolicy ownership moved to the shared runtime contract.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_runtime_prefs.cc` - Local versioned `max_active_agents` persistence with default and clamping.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.h` - Production cap setter and typed admission check.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_session.cc` - New-session cap enforcement with no active-session eviction.
- `.context/chromium/src/chrome/browser/prometheus/prometheus_agent_session_unittest.cc` - Default/clamped caps, denial/recovery, non-eviction, and complete close/expiry regression.
- `.context/chromium/src/chrome/browser/prometheus/BUILD.gn` - RE2 dependency for deterministic bounded redaction.
- `patches/0014-feat-20-06-add-bounded-safe-task-titles.patch` - 23,347-byte safe-title patch.
- `patches/0015-feat-20-06-enforce-closed-runtime-policy-decisions.patch` - 24,047-byte native policy/session-cap patch.

## Decisions Made

- Kept `safe_title` as the only prompt-derived persisted value. Callers derive it before task creation, so the runtime store cannot accidentally serialize the original prompt.
- Used explicit ASCII whitespace collapse instead of a trimming helper that discards separators, preserving deterministic word boundaries across tabs and newlines.
- Redacted before truncation and cut only on a valid UTF-8 boundary, making the 96-byte limit deterministic and preventing partial code points.
- Kept the existing schema version. Absence means a compatible older record and receives `Browser task`; an explicitly invalid field remains corruption rather than being silently repaired.
- Moved `RuntimePolicy` into the shared runtime contract so admission and dispatch decisions own a single closed effective-policy type rather than depending on prefs implementation details.
- Evaluated internal-surface and background-action denials before ownership or delegate execution; allowed paths still require existing tab ownership and permit exactly one downstream dispatch.
- Kept local-only telemetry content-free and made Off suppress event construction at its source rather than filtering after collection.
- Left FSB-02, FSB-05, and FSB-08 semantically open because runtime assembly, control-panel/settings integration, telemetry/logging surfaces, and later end-to-end gates remain owned by subsequent Phase 20 plans.

## Deviations from Plan

None - the two planned tasks, declared file scopes, ordered patch exports, and automated gates were completed as specified.

## Issues Encountered

- The compileable RED checkpoints produced only the intended missing-contract compile diagnostics for safe titles, closed decisions, effective policy fields, and production Agent admission APIs.
- Chromium's existing whitespace helper removed newline separators instead of collapsing them. A byte-preserving ASCII whitespace collapse helper restored the exact deterministic title contract, after which every focused fixture was green.
- Exact `git format-patch` exports contain standard mail/context whitespace when viewed as newly added root files. Both remain byte-for-byte generated, ordered, non-empty, and name their exact nested commits.

## Verification

- Raw `third_party/ninja/ninja -C out/Default prometheus_unittests` build - passed after the final source and test changes.
- SafeTitle list guards - 3 runtime-types and 2 runtime-store cases registered; all 5 passed.
- Policy list guards - 2 PolicyAdmission, 1 PolicyDispatch, 1 TelemetryOff, 1 LockedVaultPolicy, and 16 Agent-session cases registered; all 21 passed.
- Complete native regression - all 226 listed `prometheus_unittests` cases passed.
- Safe-title evidence - exact fixtures, every redaction class, whitespace collapse, deterministic output, valid-UTF-8 truncation, restart persistence, missing-field compatibility, malformed input rejection, and recursive raw-content absence are covered.
- Policy evidence - local/non-syncable default and clamped Agent caps, task-cap reuse, denial-before-dispatch, required existing ownership, one allowed dispatch, source-level telemetry suppression, and immutable native vault/ownership locks are covered.
- Lifecycle evidence - lowering the Agent cap preserves three active sessions, denies only new admission, recovers after normal close, and leaves the complete existing close/expiry suite green.
- Static boundary audit - zero process-launch, subprocess, terminal-runtime, embedded-engine, `CLAUDE.md`, renderer, MCP-service, runtime-service, provider-SDK, or bootstrap additions across all 278 new production lines.
- Nested source and root worktree `git diff --check`, exact declared task scopes, explicit-file staging, and pre-summary cleanliness checks - passed.
- Export evidence - patches 0014 and 0015 are ordered and non-empty at 23,347 and 24,047 bytes and name nested commits `7e59c5126f` and `c1bfa54a05` exactly.

Human UAT was not run and is not claimed; it remains deferred to the Phase 24 non-blocking visual review.

## User Setup Required

None. The implementation is native, deterministic, and exercised entirely through local Chromium unit-test seams; it needs no live provider key, network service, SDK, subprocess runtime, or external account.

## Next Phase Readiness

Plan 20-07 can assemble the regular-profile runtime using bounded persisted safe titles, fresh effective policy decisions, production Agent-session admission, and source-level telemetry controls. It does not need to reopen schema-v1 history or add a renderer, MCP, SDK, subprocess, terminal, prompt provisioner, or embedded-engine escape hatch.

FSB-02, FSB-05, and FSB-08 remain in progress until their later runtime, control-panel, settings, logging, and integration gates are complete. No blocker remains for Plan 20-07.

## Self-Check: PASSED

- FOUND: all 12 declared nested source/test/BUILD paths
- FOUND: nested task commits `7e59c5126f` and `c1bfa54a05`
- FOUND: matching non-empty exported patches `0014` and `0015`
- VERIFIED: exact 5-case SafeTitle and 21-case policy/session gates green
- VERIFIED: complete 226-test native regression green
- VERIFIED: zero forbidden production additions and both repositories clean before summary creation

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-16*

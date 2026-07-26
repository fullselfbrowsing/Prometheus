---
phase: "21-supervision-pairing-and-remote-control"
fixed_at: "2026-07-26T10:42:26-05:00"
review_path: ".planning/phases/21-supervision-pairing-and-remote-control/21-REVIEW.md"
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: "all_fixed"
---

# Phase 21 Code Review Fix Report

**Fixed at:** 2026-07-26T10:42:26-05:00
**Source review:** `.planning/phases/21-supervision-pairing-and-remote-control/21-REVIEW.md`
**Iteration:** 1

## Summary

- Findings in scope: 3
- Fixed: 3
- Skipped: 0
- Result: all three release blockers are fixed and covered by fresh native,
  renderer, browser, Node, built-application, patch-integrity, and preservation
  evidence.

The source review remains unchanged. Product fixes are the final three nested
Chromium commits and exported patches 0072 through 0074. Root commits track the
patches and synchronized closeout evidence; two later root-only commits make
the built-app retention-gap smoke deterministic without changing its
120-second deadline or adding retries.

## Fixed Issues

### CR-01: Dirty notifications are lost while a capture is in flight

**Status:** fixed

**Files modified:** `prometheus_supervision_capture_hub.cc`,
`prometheus_supervision_capture_hub.h`,
`prometheus_supervision_capture_hub_unittest.cc`

**Commits:** nested Chromium
`0c8599e1ab77d3e501175b4bc8375db3acdd3a22`; root tracking
`b18c15f50ce1adb8eff0866900ff95391c51177e`

**Patch:** `0072-fix-21-queue-dirty-captures-while-snapshot-is-in-fli.patch`;
stable patch ID `e9549479c7d3bc00d9e2962fc9b1ab2bc4d8719d`; SHA-256
`4b4f12505243c8dcac8626661a0e1f9b08c866656eb9f310ca86b2b4916f7e91`

**Applied fix:** The capture hub records dirty work that arrives while a
snapshot is in flight. Completion of the older snapshot immediately starts a
forced follow-up capture before compatibility waiters can receive stale or
no-change state. Overflow state is carried into that follow-up capture.

**Verification:** `DirtyAfterSnapshotStartsQueuesFollowUpCapture` completes the
first request with a pre-mutation snapshot, proves both consumers remain
blocked, completes the queued request with the later mutation, and proves both
independent cursors receive the same new diff. This coverage is included in
the fresh Phase 21 native result of 190/190.

### CR-02: Destructive confirmations can execute against a different row

**Status:** fixed

**Files modified:** `prometheus_browser_main_extra_parts.cc`,
`prometheus_webui.js`, `prometheus_side_panel_runtime.cc`,
`prometheus_side_panel_runtime.h`, `prometheus_web_ui.cc`,
`prometheus_web_ui.h`, `prometheus_web_ui_browsertest.cc`

**Commits:** nested Chromium
`3ea941de9a2b71b261f2bb49846a9e54136e2f49`; root tracking
`38ac9c8d7267f477faf312eb492b52c515b47a63`

**Patch:** `0073-fix-21-bind-destructive-confirms-to-snapshot-generat.patch`;
stable patch ID `a5c8723fc5b8f9d7b5fae9541f1a1d5fb1286c64`; SHA-256
`c0a82c21557e2f96a86d4d9ba19f5170235db6c0e34e2b7518fb7e031a4ec203`

**Applied fix:** Browser snapshots now carry a bounded opaque generation.
Replace-pairing, revoke-session, and end-target confirmations submit the
generation that named the displayed row. Native handlers reject a stale or
forged generation before ordinal resolution, and the WebUI cancels an open
confirmation when a refreshed snapshot invalidates its binding.

**Verification:**
`SupervisionRuntimeDestructiveActionsRejectStaleSnapshotGeneration` reorders
tabs and connected rows between rendering and submission, then proves stale
replace, revoke, and end operations fail closed without affecting the
originally displayed or newly indexed row. This coverage is included in the
fresh Phase 21 browser result of 52/52.

### CR-03: The renderer stops observing after root creation or replacement

**Status:** fixed

**Files modified:** `prometheus_supervision_document_supplement.cc`,
`prometheus_supervision_document_supplement_unittest.cc`,
`prometheus_supervision_capture_hub_browsertest.cc`

**Commits:** nested Chromium
`de937473bd1b5e99aec391ea003545ecd205e367`; root tracking
`252a5ed815a5b554403b169cb5b90e812143efe8`

**Patch:** `0074-fix-21-observe-document-root-lifecycle-mutations.patch`;
stable patch ID `1b8a9f7232d815cdf0f38094751a935d92cce604`; SHA-256
`5836165a81c6313a4d27d157c86c1bb932f7c2716b67a4a0526ff1539737e8f5`

**Applied fix:** The Blink supplement observes the `Document` subtree rather
than attaching once to the current root. Enabling before root creation,
replacing `documentElement`, and later mutations below the replacement all
emit bounded dirty notifications without exposing page content.

**Verification:** Renderer fixtures
`EnableBeforeDocumentElementCreationObservesLaterRoot` and
`DocumentElementReplacementObservesNewRootMutations` cover both lifecycle
edges. Browser fixture
`DocumentElementReplacementKeepsRealCaptureLive` proves replacement and a
later descendant mutation start real browser captures and deliver updated
diffs. They are included in the fresh renderer 14/14 and browser 52/52 results.

## Built-App Closeout Recovery

The first fresh no-argument closeout after the product fixes passed every
static, native, renderer, browser, Node, catalog, and patch gate, then reached
the built-app smoke's unchanged 120-second outer deadline. Timing evidence
showed that the 35-mutation retention-gap loop requested a fresh MCP DOM
snapshot before the supervision capture caused by the preceding click had
completed. After ten iterations, overlapping capture work repeatedly reached
Chromium's four-second page-stability bound.

Root commit `2525e5b5ed5498f6307ed2c30f7f88e14858f067` isolates the disposable smoke
profile from background networking and component updates. Root commit
`e4b08acb2c5b6ec3d0363a0a2433807e38df6d4d` serializes each retention-gap
iteration as click, independent compatibility diff/ACK, then fresh MCP
snapshot. The compatibility session owns its own capture-consumer token, so
that ACK cannot advance the intentionally unacknowledged dashboard viewer A/B
cursors. Static/unit guards require this ordering, retain exactly 35 mutations
against the 32-batch history bound, and reject a dashboard ACK inside the gap
loop.

The smoke timeout remains 120 seconds and its retry behavior is unchanged. One
instrumented focused trial returned a transient `CAPABILITY_NOT_READY` after
reaching the later Phase 20 regression section; the unchanged next focused run
passed in 59 seconds with the exact `Prometheus MCP live smoke passed.` marker.
Temporary instrumentation was restored byte-for-byte before the authoritative
run. The failed partial closeout directory was removed, and the final
no-argument verifier recreated all evidence from scratch and passed its
built-app smoke on that single invocation.

## Fresh Authoritative Verification

The exact actual-root command exited 0:

    bash .planning/chromium/verify-phase-21.sh

Evidence is under
`.context/chromium/src/out/Default/phase21-closeout/`.

| Cohort or gate | Exact result |
|----------------|--------------|
| Phase 21 native | 190/190 passed; fail 0; skip 0 |
| Phase 20 native regression | 208/208 passed; fail 0; skip 0 |
| Phase 17–19 native regression | 84/84 passed; fail 0; skip 0 |
| Phase 20 content regression | 21/21 passed; fail 0; skip 0 |
| Phase 21 browser | 52/52 passed; fail 0; skip 0 |
| Phase 20 browser regression | 37/37 passed; fail 0; skip 0 |
| Phase 17–19 browser regression | 83/83 passed; fail 0; skip 0 |
| Phase 21 Blink renderer | 14/14 passed |
| Phase 19 renderer regression | 3/3 passed |
| Complete Node TAP | 81/81 passed; fail 0; skip 0 |
| Compatibility catalog | exactly 54 native / 12 alias / 22 typed stub / 0 later / 2 removed |
| Built application | exact `Prometheus MCP live smoke passed.` marker |
| Patch series | 74/74 ordered source-only identities; valid mutation rejected |
| Final result | `Phase 21 verification passed.` |

The reviewed build artifacts remained byte-identical before and after the
authoritative run:

| Artifact | SHA-256 |
|----------|---------|
| `.ninja_log` | `eccf79f3dfdc6c8d51af20f56bf1973eb35ff486b1dab9b2b0653cc37b586dce` |
| `.ninja_deps` | `ab1a6ad4639e8db53459384f8636dc53f396397363f3c2751bcdadc0349947c0` |
| `libblink_modules.dylib` | `663af12ba1a986db789c4c05967dda8b3b3615030e6cecb569de0f74ba01ff8e` |
| `libblink_modules.dylib.TOC` | `bdc164a10b8616fa099b089a1f4542c789a584c84212b0f4d92b616701a3ce9b` |
| framework `resources.pak` | `c9c541d780ad9c0054eaec0abd8453703972ebcc3ce3607d06e3c80e5a8f79ff` |

Nested Chromium is clean at
`de937473bd1b5e99aec391ea003545ecd205e367`, tree
`97c4043b11ef760f3f03705a279641d4421ddf2f`. Root tracked state is clean at
`e4b08acb2c5b6ec3d0363a0a2433807e38df6d4d`, tree
`181998a7e541d0d9d70107879e8260760416313c`; this report is intentionally the
only uncommitted root path.

## Skipped Issues

None.

---

_Fixed: 2026-07-26T10:42:26-05:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_

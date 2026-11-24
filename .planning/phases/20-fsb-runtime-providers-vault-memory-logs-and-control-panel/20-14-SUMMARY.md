---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
plan: 14
subsystem: testing
tags: [chromium, runtime, providers, mcp, browser-tests, security, closeout]

requires:
  - phase: 20-07
    provides: regular-profile native runtime, provider loop, policy enforcement, and closed test bootstrap
  - phase: 20-10
    provides: promoted external MCP catalog, closed schemas, and built-app smoke path
  - phase: 20-11
    provides: exact-window side-panel runtime composer and observer bridge
  - phase: 20-12
    provides: live control-panel task, provider, log, and diagnostics workflows
  - phase: 20-13
    provides: memory, site-guide, native-secret, vault, and effective-settings workflows
provides:
  - Exactly 32 deterministic adversarial runtime cases with 28 real provider loops across four wire families
  - Native browser integration proof for provider, lifecycle, authority, policy, vault, memory, provenance, and sanitized diagnostics behavior
  - One fail-fast Phase 20 verifier covering builds, 294 units, 118 browser tests, 74 Node tests, built-app smoke, security, preservation, patches, and documentation
  - Passed FSB-01 through FSB-08 verification with exact human_uat not_run and explicit Phase 21-24 carry-forward
affects: [21-supervision-pairing, 22-extension-authority, 23-parity-security, 24-release-validation]

tech-stack:
  added: []
  patterns:
    - Table-driven fake-provider evaluation through network::TestURLLoaderFactory and injected fake secret storage
    - Generated-Ninja focused links for exact owned-object execution when an aggregate component target has unrelated closure defects
    - Renderer-level synthetic viewport sizing for deterministic sub-minimum side-panel responsive tests
    - One executable closeout command with exact suite counts, named logs, patch identity checks, and fail-closed security scans

key-files:
  created:
    - .planning/chromium/verify-phase-20.sh
    - .planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-VERIFICATION.md
  modified:
    - .context/chromium/src/chrome/test/data/prometheus/runtime/runtime_eval_cases.json
    - .context/chromium/src/chrome/browser/prometheus/prometheus_mcp_integration_browsertest.cc
    - .context/chromium/src/chrome/browser/prometheus/prometheus_agent_gateway.cc
    - .context/chromium/src/chrome/browser/ui/webui/prometheus/prometheus_web_ui_browsertest.cc
    - README.md
    - .planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md
    - .planning/phases/20-fsb-runtime-providers-vault-memory-logs-and-control-panel/20-VALIDATION.md

key-decisions:
  - "Execute every owned native and browser object through verified focused/custom links while recording, but never misreporting, the unrelated aggregate prometheus_unittests linker limitation."
  - "Require exactly 28 real provider-loop fixtures across OpenAI Responses, OpenAI Chat, Anthropic Messages, and Gemini generateContent, exceeding the planned 20-case minimum."
  - "Drive 300px and 320px responsive assertions through RenderWidgetHostView because the production side panel correctly enforces a 360px minimum and can relayout its child WebView."
  - "Keep human visual UAT explicitly not_run and route the consolidated non-blocking review to Phase 24."

patterns-established:
  - "Counted closeout: list-guard every suite, assert exact terminal counts, disable browser retries, and preserve a named log for each gate."
  - "Patch fidelity: export every nested commit immediately and verify exact ordered one-to-one From identities from the Phase 20 baseline."
  - "Truthful limitations: accept only a fingerprinted unrelated build failure and document the substitute evidence without converting it into a pass claim."

requirements-completed: [FSB-01, FSB-02, FSB-03, FSB-04, FSB-05, FSB-06, FSB-07, FSB-08]

duration: 5h 45m
completed: 2026-07-18
---

# Phase 20 Plan 14: Runtime Integration and Automated Closeout Summary

**A 32-case adversarial fake-provider corpus, built-app external MCP smoke, and exact counted closeout now prove the complete native runtime/provider/vault/memory/control product without live credentials, an embedded engine, or a human-UAT claim.**

## Performance

- **Duration:** 5h 45m
- **Started:** 2026-07-18T16:15:18-05:00
- **Completed:** 2026-07-18T22:00:18-05:00
- **Tasks:** 2
- **Files modified:** 21 distinct plan-owned paths across root and nested Chromium
- **Nested Chromium commits:** 6
- **Ordered exported patches:** 6 (`0037` through `0042`; 42 total from the Phase 20 baseline)

## Accomplishments

- Expanded the runtime corpus to exactly 32 cases in groups `6/5/5/5/4/4/3`; 28 cases execute real provider loops across OpenAI Responses, OpenAI Chat, Anthropic Messages, and Gemini generateContent.
- Exercised benign completion, injected authority, secret echo/containment, codec and tool-call conformance, lifecycle races, fallback budgets, accounting, memory/site-guide provenance, and vault confirmation through native browser-owned runtime paths.
- Closed policy evidence for admission, requested/effective dispatch, telemetry-off emission, immutable ownership/vault/per-use/supervision settings, safe-title persistence, live diagnostics, and exact-window WebUI handoff.
- Added a single executable closeout gate that rebuilds owned code, reconstructs and signs focused binaries, enforces exact counts, runs the built Prometheus app with the closed loopback bootstrap, scans security/preservation boundaries, and validates the complete patch ledger.
- Published passed VALIDATION and VERIFICATION evidence for FSB-01 through FSB-08 and T-20-01 through T-20-08 while preserving `human_uat: not_run` and Phase 21-24 ownership boundaries.

## Task Commits

Every nested Chromium commit was exported immediately as an ordered non-empty patch and tracked in a separate root commit:

1. **Task 1 RED: Specify the exact 32-case runtime corpus** — `cb0d456331` (`0037-test-20-14-specify-32-case-runtime-evaluation-corpus.patch`); root tracker `a2e18f18b`
2. **Task 1 GREEN: Complete runtime/provider/native integration** — `8f1878117f` (`0038-feat-20-14-complete-runtime-provider-integration-cor.patch`); root tracker `347462b85`
3. **Task 2 regression: Align live diagnostics with Phase 20 vault readiness** — `1253d711f0` (`0039-test-20-14-update-live-diagnostics-regression.patch`); root tracker `acda12d16`
4. **Task 2 regression: Align gateway health with Phase 20 vault readiness** — `c9dbe94134` (`0040-test-20-14-update-gateway-health-regression.patch`); root tracker `83b31074a`
5. **Task 2 regression: Stabilize Ask FSB handoff and WebUI fixture ownership** — `a37b3b88f9` (`0041-fix-20-14-stabilize-webui-regression-gates.patch`); root tracker `b7ff8c97d`
6. **Task 2 regression: Stabilize the synthetic responsive viewport** — `5beb75dd92` (`0042-test-20-14-stabilize-synthetic-side-panel-viewport.patch`); root tracker `f854877ad`
7. **Task 2 closeout: Add the verifier and publish passed evidence** — `e29950500`

## Automated Verification

The final `bash .planning/chromium/verify-phase-20.sh` acceptance run exited zero and produced fresh named logs under `.context/chromium/src/out/Default/phase20-closeout/`:

- Phase 20 native runtime/provider/vault suites passed `187/187`.
- Content, Mojo, and renderer suites passed `23/23`.
- Phase 17-19 native regressions passed `84/84`.
- Phase 20 MCP integration, native vault confirmation, and control-panel browser fixtures passed `36/36` serially with retries disabled.
- Phase 17-19 gateway, profile/service, page/frame/action, tab-command, and WebUI regressions passed `82/82` serially with retries disabled; the 300/320px responsive case passed at `[80/82]`.
- Node MCP tests passed exactly `74/74`, with fail, cancelled, skipped, and todo all exactly zero.
- Built-app external MCP smoke passed against `Prometheus.app`, the mode-0600 closed bootstrap, and fixture-owned `GET /v1/models` plus `POST /v1/responses`; MCP never seeded provider prefs.
- Inventory assertions passed exactly 32 corpus cases, 28 real loops, four wire families, and catalog dispositions `49/12/22/5/2`.
- Environment, GPL, artifact isolation, packaged WebUI, recursive content/secret/process/network, preservation, root/nested diff, and exact 42-patch identity gates passed.

The stock `chrome` and renderer targets built. The aggregate `prometheus_unittests` edge was attempted and matched its audited unrelated Chrome-symbol closure defect; no aggregate pass is claimed. All 31 owned unit objects and 11 owned browser-test objects were freshly compiled and executed through generated-Ninja focused/custom links, with the content and browser binaries signed and verified before use.

## Decisions Made

- Split exact native execution between a custom browser link and a focused content/renderer link because the aggregate component target omits unrelated Chrome navigation, prefetch, upgrade-detector, and file-selection dependencies. The verifier accepts only that known signature and still compiles every owned object.
- Treat endpoint/origin examples as inert operator input copy rather than banning every `https://` string from packaged resources; executable remote `src`, `href`, CSS URL/import, dynamic import, and fetch paths remain forbidden.
- Test sub-minimum responsive CSS by repeatedly applying the viewport to the renderer host. This isolates layout behavior from the production `SidePanel` minimum-width constraint and eliminates parent-layout races without weakening product geometry.
- Keep visual review out of Phase 20 acceptance. Automated responsive, keyboard, focus, accessibility, reduced-motion, disclosure, and packaging checks pass; screenshot/polish review remains a single Phase 24 item.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test expectation] Updated Phase 19 diagnostics for completed Phase 20 vault ownership**
- **Found during:** Task 2 full regression gate
- **Issue:** Two regressions still classified `vault` as later-phase/not-ready even though Phase 20 now owns live native vault behavior.
- **Fix:** Required vault `ready` while provider, supervision, and extensions retain their truthful states.
- **Files modified:** `prometheus_mcp_integration_browsertest.cc`, `prometheus_agent_gateway_browsertest.cc`
- **Verification:** Final Phase 20 and Phase 17-19 native/browser filters passed.
- **Committed in:** `1253d711f0`, `c9dbe94134`

**2. [Rule 1 - Bug/Test fixture] Removed duplicate Ask FSB renderer callback and bound the test to the actual side-panel owner**
- **Found during:** Task 2 WebUI regression gate
- **Issue:** The new-tab handler invoked a callback after navigation, and the fixture relied on synthetic form/callback behavior instead of the browser-owned handoff and visible side-panel WebView.
- **Fix:** Removed the unsafe duplicate callback, invoked the message contract directly in the fixture, and resolved the exact visible side-panel WebView/WebContents.
- **Files modified:** `prometheus_tab_control_web_ui.cc`, `prometheus_web_ui_browsertest.cc`
- **Verification:** Ask FSB prompt seeding, URL/history absence, exact-window ownership, and the complete 82-test regression filter passed.
- **Committed in:** `a37b3b88f9`

**3. [Rule 1 - Flaky test] Replaced a parent-layout race with deterministic renderer viewport sizing**
- **Found during:** Task 2 complete 82-test regression replay
- **Issue:** One-shot `WebView::SetSize(300, 900)` raced the production side panel's correct 360px minimum layout, so the renderer sometimes never observed the synthetic 300px precondition in the full filter.
- **Fix:** Applied 300px and 320px sizes directly to `RenderWidgetHostView` inside the polling precondition before evaluating the existing CSS/accessibility assertions.
- **Files modified:** `prometheus_web_ui_browsertest.cc`
- **Verification:** The isolated responsive case passed twice at `1/1`, then passed at `[80/82]` in both the focused full replay and final acceptance run, all with retries disabled.
- **Committed in:** `5beb75dd92`

**4. [Rule 3 - Blocking build infrastructure] Substituted exact focused links for the unrelated aggregate linker closure**
- **Found during:** Task 2 mandatory build gate
- **Issue:** `prometheus_unittests` compiles Prometheus code but cannot link because its Chromium component edge omits unrelated Chrome symbols; repairing broad upstream target closure would exceed Phase 20 scope.
- **Fix:** Kept the aggregate attempt and strict failure fingerprint, then compiled every owned object and reconstructed focused content and browser executables from generated Ninja commands. No aggregate pass is claimed.
- **Files modified:** `.planning/chromium/verify-phase-20.sh`, `20-VALIDATION.md`, `20-VERIFICATION.md`
- **Verification:** The final verifier compiled all owned objects, linked/signed both substitutes, and passed 294 native/content/regression units plus all browser gates.
- **Committed in:** `e29950500`

---

**Total deviations:** 4 auto-fixed (three correctness/test-fixture issues, one blocking build-infrastructure substitution). All changes were required for truthful deterministic evidence; none widened runtime authority or product scope.

## Issues Encountered

- Restored Ninja dependency metadata correctly invalidated a large Chromium graph, so the first full build processed roughly 58,120 edges over about 2h25m. The final acceptance rerun was incremental and rebuilt only the relevant Prometheus/component edges.
- The first full 82-test replay exposed the side-panel minimum-width race only in suite context; isolated execution had passed. Inspecting `SidePanel` geometry showed that the failed wait was a fixture precondition, not a product CSS/accessibility failure, leading to the renderer-level fix above.
- Generated linker commands required preserving response-file semantics while appending the exact Prometheus objects. The verifier now checks command discovery, object counts, link output, code signing, and test-list selection before execution.

## User Setup Required

None. Tests use fake provider transport, fake encryption, an isolated regular profile, and the local built-app bootstrap. No live API key, Keychain entry, third-party engine, or external service is required.

## Next Phase Readiness

- Phase 21 can build supervision and pairing on a verified native runtime, authenticated gateway, exact-window authority model, and truthful `Not ready` diagnostics.
- Phase 22 retains extension authority and health ownership; no extension capability was marked ready here.
- Phase 23 retains migration parity and security hardening, with the complete Phase 20 preservation/evidence ledger available as input.
- Phase 24 retains packaging/release validation and the consolidated non-blocking desktop visual review.
- No known Phase 20 functional or security blocker remains. The aggregate unit target closure is documented as build-infrastructure debt with full owned-object substitute evidence.

## Self-Check: PASSED

- The nested Chromium branch remains `prometheus/phase-14-assets` and is clean at `5beb75dd92`.
- The root branch remains `chromium`; the closeout commit is `e29950500`.
- The exact nested range `460caac2f9e7deecd9fa6294c41d13e5a6dd6115..5beb75dd92` contains 42 commits and has 42 ordered non-empty source-only patches with matching `From` identities.
- Final automated counts are `187 + 23 + 84 = 294` unit/renderer tests, 36 Phase 20 browser tests, 82 browser regressions, and 74 Node tests; built smoke and every security/preservation gate passed.
- Requirements completed by this plan are exactly `FSB-01` through `FSB-08`; `human_uat: not_run`.

---
*Phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel*
*Completed: 2026-07-18*

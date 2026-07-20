---
phase: 20-fsb-runtime-providers-vault-memory-logs-and-control-panel
verified: 2026-07-20
status: passed
human_uat: not_run
---

# Phase 20 Verification

Phase 20 passes its automated closeout. The browser now owns one bounded
regular-profile FSB runtime, provider networking and model discovery, encrypted
provider/vault secrets, memory and exact-origin site guides, sanitized task/log/
accounting persistence, live side/control WebUI, and the promoted external MCP
routes. Supervision remains truthfully owned by Phase 21.

Human visual UAT was not run and is not an acceptance dependency:
`human_uat: not_run`. The remaining desktop visual review is consolidated into
the non-blocking Phase 24 release review.

## Automated Result

Run the complete gate from the root checkout:

```sh
bash .planning/chromium/verify-phase-20.sh
```

The command uses `set -euo pipefail`, rebuilds or freshly compiles every owned
source object, creates named secret-free logs under
`.context/chromium/src/out/Default/phase20-closeout/`, and exits zero only after
all runtime, browser, Node, built-app, security, preservation, patch, and
documentation checks pass.

| Evidence | Result |
|----------|--------|
| Phase 20 native suites | 203/203 across runtime types/store, memory, secret store, provider registry/codec, runtime profile/bootstrap/transport codec, vault, agent service/session/gateway |
| Content/Mojo/renderer suites | 24/24 across provider transport, tab state, and action dispatcher |
| Phase 17-19 native regressions | 84/84 |
| Phase 20 browser fixtures | 36/36 serial across MCP integration, vault confirmation, and control panel |
| Phase 17-19 browser regressions | 83/83 serial across gateway, profile/service, page/frame/action, tab commands, and WebUI foundation |
| Node MCP tests | 75/75 with exact fail `0`, cancelled `0`, skipped `0`, todo `0` |
| Built-app external MCP smoke | passed against the built Prometheus app and deterministic loopback fixture |
| Corpus | exactly 32; groups `6/5/5/5/4/4/3`; 28 real provider loops across OpenAI Responses, OpenAI Chat, Anthropic Messages, and Gemini generateContent |
| Compatibility catalog | exactly 49 native, 12 alias, 22 typed stub, five Phase 21, two removed |
| Chromium patch export | 52 ordered non-empty source-only patches with exact stable patch identities for the nested range `460caac2f9e7deecd9fa6294c41d13e5a6dd6115..HEAD` |

The aggregate `prometheus_unittests` target is not reported as passing. Its
current component-build edge cannot close an unrelated Chrome symbol set
(navigation, prefetch, upgrade-detector, file selection, and related helpers).
The closeout command does not invoke Ninja or that aggregate edge. It queries
exact commands through Siso, directly compiles every owned object, reconstructs
the app/browser/content response files from generated metadata, and signs and
verifies each executable link. Reviewed `.ninja_log` and `.ninja_deps` hashes
must remain byte-identical from start to finish.

## Requirement Evidence

| Requirement | Result | Evidence |
|-------------|--------|----------|
| FSB-01 | passed | Ask FSB seeds the exact-window side panel without URL/history prompt leakage or auto-submit. Explicit submit creates one bounded task; safe title, progress, terminal result, cancel, recovery, and restart rendering pass in native and browser fixtures. |
| FSB-02 | passed | Hosted, routed, local, Agent-side, and MCP-side work share the native state machine. Exactly-once cancel/timeout/shutdown, pre-mutation-only fallback, lifecycle generation, bounded tool authority, and external-smoke submit/status/cancel/log flows pass. No third-party engine is embedded or launched. |
| FSB-03 | passed | OpenAI-compatible, Anthropic, Gemini, Ollama, LM Studio, and fixed hosted metadata obey closed endpoint policy, strict codecs, discovery/model selection, direct `SimpleURLLoader` transport, redirect rejection, omitted ambient credentials, bounded bodies/timeouts, and typed fallback. |
| FSB-04 | passed | Provider and vault values use profile-owned injectable OSCrypt envelopes. Entry/use remains native; renderer, WebUI, MCP, prefs snapshots, logs, errors, diagnostics, corpus output, and captured smoke output remain value-free. Re-encrypt and failure preservation pass. |
| FSB-05 | passed | Tasks, events, actions, diagnostics, outcomes, integer token/duration/action/cost accounting, and known-versus-unknown cost survive bounded deterministic persistence without prompts, page content, selectors, scripts, typed text, raw provider bodies, profile paths, or gateway authority. |
| FSB-06 | passed | Memory and site-guide create/list/search/stats/apply flows enforce caller visibility, deterministic item/byte limits, restart behavior, and exact current origin/document provenance. Built-app MCP smoke and control WebUI both exercise the live native owner. |
| FSB-07 | passed | Vault metadata remains listable and value-free. Every fill/use requires fresh native confirmation and revalidates regular profile, session owner, stable tab/window, origin, frame, document, ref, focus, expiry, generation, and one-use retry before decrypt/insertion. |
| FSB-08 | passed | Effective settings change admission, requested/effective dispatch, internal/background Agent delegate behavior, caps, and telemetry emission. Vault ownership/per-use confirmation and supervision policy stay locked; WebUI renders effective values and supervision remains `Not ready`. |

## Safe-Title, Policy, and Bootstrap Proof

- Safe-title tests cover deterministic benign titles and redacted URL/query/
  credential prompts. Raw prompts are absent from persisted task records,
  search indexing, WebUI DOM, snapshots, diagnostics, logs, and errors.
- `PolicyAdmission`, `PolicyDispatch`, `TelemetryOff`, and
  `LockedVaultPolicy` filters execute inside the 203-test native gate. They
  prove real admission/delegate/emission effects and immutable ownership,
  native-vault, fresh-confirmation, and supervision invariants.
- `PrometheusRuntimeTestBootstrapTest.*` proves the bootstrap requires a
  non-official test build, exact `--test-type=prometheus-runtime`, an absolute
  non-symlink mode-0600 file, closed schema, one eligible loopback local
  provider, and an isolated profile. Official-build and ordinary-launch denial
  leave provider registry mutation count at zero.
- The built smoke creates `phase20-smoke-local` only through that file, launches
  the built app with the exact bootstrap switch, and uses fixture-owned
  `GET /v1/models` plus `POST /v1/responses`. MCP attempts to mutate provider
  state are denied and do not seed the runtime.

## Threat Disposition

| Threat | Result | Automated disposition |
|--------|--------|-----------------------|
| T-20-01 | mitigated | The 32-case corpus treats provider/page output as untrusted, rejects injected or unknown authority/tools, and routes only closed native actions after profile/session/tab/document checks. |
| T-20-02 | mitigated | Fixed origins, HTTPS remote custom policy, exact loopback HTTP, omitted credentials/cookies/referrer, rejected redirects, and request/response/time bounds pass transport and static gates. |
| T-20-03 | mitigated | Exact secret/ciphertext/authorization/bootstrap sentinels remain absent from serialized prefs, WebUI, MCP, logs, diagnostics, audit, DOM, errors, and captured smoke output. |
| T-20-04 | mitigated | Vault approval captures and revalidates profile/window/tab/owner/origin/frame/document/ref/focus with short expiry, generation, one-use semantics, and identical MCP retry. |
| T-20-05 | mitigated | `(task_id, generation)`, task-owned loaders, weak callbacks, cancellation, timeout, shutdown, and one `FinishOnce` path pass exactly-once race fixtures. |
| T-20-06 | mitigated | Provider fallback occurs only on retryable pre-mutation failures; terminal auth/invalid output and any post-mutation state are never replayed with another provider or credential. |
| T-20-07 | mitigated | Recursive production scans and Node contracts find no subprocess, terminal, alternate engine selector, prompt provisioner, provider SDK/runtime, or `CLAUDE.md`; MCP remains an external adapter only. |
| T-20-08 | mitigated | Closed metadata-only events, bounded deterministic eviction, local/off telemetry, safe titles, and recursive content-key/sentinel denial prevent persistence or telemetry exfiltration and unbounded growth. |

## Boundary and Preservation Gates

- Environment, Falkon GPL guard, artifact isolation, packaged WebUI resources,
  and Falkon preservation all pass.
- Prometheus WebUI resources contain no executable remote `src`, `href`, CSS,
  import, or fetch path. Endpoint/origin input placeholders are inert UI copy,
  not resource loads.
- Production browser/renderer/MCP sources contain no embedded-agent process,
  terminal, engine-selection, provider-SDK, unsafe redirect, ambient credential,
  remote WebUI, or false supervision-ready path.
- The exact 52-commit nested range has one ordered non-empty source-only patch
  per commit; stable patch IDs must match every claimed commit, and a valid but
  mutated patch must fail the verifier self-test. Patches reject output, object,
  library, response, dependency, and other build artifacts.
- Root and nested `git diff --check` pass. The nested Chromium worktree is clean
  after each exported implementation or regression commit.

## Visual Review Routing

Automated responsive, keyboard, focus, live-region, reduced-motion, packaged-
resource, and secret-absence gates are complete, including side-panel 300/320
viewports and control-panel 320/480/720/1024 plus 200%-zoom-equivalent checks.
Desktop screenshot/polish review remains a single non-blocking Phase 24 release
ledger item. It is not represented as complete here and cannot waive any
functional or security gate.

## Final Status

- FSB-01 through FSB-08: passed
- T-20-01 through T-20-08: mitigated by passing automated gates
- automated closeout: passed
- aggregate unit executable: known linker limitation; no pass claimed
- human_uat: not_run
- Phase 21 carry-forward: supervision and pairing
- Phase 22 carry-forward: extension authority and health
- Phase 23 carry-forward: migration parity and security hardening
- Phase 24 carry-forward: packaging and non-blocking visual review

---
phase: 20
slug: fsb-runtime-providers-vault-memory-logs-and-control-panel
status: complete
researched: 2026-07-13
confidence: high
---

# Phase 20 Research: Native FSB Runtime, Providers, Vault, Memory, Logs, and Control Panel

## Executive Summary

Phase 20 should be implemented as one regular-profile Chromium service with
three narrow adapter surfaces:

1. native WebUI/Views for user interaction and secret confirmation;
2. the existing Phase 19 external stdio MCP bridge for sanitized compatibility;
3. direct browser-process HTTP adapters for hosted, routed, custom, and
   user-operated local model endpoints.

There is no compliant reason to add LangGraph, an Agents SDK, a provider SDK,
or a third-party CLI. The existing product is native C++, its authority and
page routes are already native, and the project explicitly removed the
embedded-agent plan. A small provider-neutral turn contract plus three wire
adapter families gives Prometheus the necessary model flexibility without a
second runtime or dependency tree.

The largest risks are not model quality. They are authority confusion,
asynchronous lifetime bugs, SSRF/redirect credential leakage, secret
serialization, stale-target vault insertion, unbounded provider loops, and a
UI that claims readiness without native enforcement. The plan should therefore
lead with closed contracts and RED security tests, then add persistence,
OSCrypt, provider networking, the task loop, compatibility routes, and finally
live WebUI/Views plumbing.

## Confirmed Current State

### Native authority and routing

- `PrometheusAgentProfileService` is a regular-profile keyed authority for
  browser-issued sessions and `PrometheusAgentService`.
- `PrometheusAgentService` already centralizes tab ownership, permission checks,
  stable tab identity, typed page actions, audit completion, and Phase 18
  verification. Phase 20 task actions must dispatch through it.
- `AgentRouteRequest` and `AgentRouteResult` are closed page/action contracts.
  Runtime/provider/task DTOs should be separate types rather than arbitrary
  entries in page-action `params`.
- The gateway health response and Node bridge currently force provider/vault
  diagnostics to Phase-20-not-ready. Both layers need to transition together.

### Compatibility and UI gaps

- The 90-name compatibility union is fixture-locked. All 31 Phase 20 names are
  currently `later_phase` with empty schemas.
- A clean-room mapping can promote 27 names to native and four to aliases while
  leaving the union unchanged: 49 native, 12 alias, 22 typed stub, five Phase
  21, and two removed.
- The side panel and control panel are packaged static WebUI shells. Their only
  live runtime-adjacent behavior is the browser-owned Ask FSB seed handoff.
- The current side-panel raw `views::WebView` does not provide the strongest
  exact-window WebUI ownership seam. Live task submission should move to the
  established `SidePanelWebUIViewT`/`WebUIContentsWrapperT` pattern before it
  resolves an owning browser.

### Secure storage and networking primitives

- Chromium has removed legacy synchronous OSCrypt. The pinned source documents
  browser-wide `g_browser_process->os_crypt_async()` and UI-sequence
  `GetInstance()` callbacks. Returned `Encryptor` objects can encrypt/decrypt on
  other sequences, and their decrypt flags indicate re-encryption needs.
- `CacheEncryptionProviderImpl` is a useful fail-closed pattern for obtaining an
  encryptor, validating ciphertext, re-encrypting when requested, and avoiding
  use after callback-owner shutdown.
- Chromium provider/network implementations already use
  `network::SimpleURLLoader`, injected `SharedURLLoaderFactory`, omitted
  credentials, disabled cache, bounded downloads, weak callbacks, and redirect
  cancellation.

## Framework Decision

**Selected:** Native Chromium C++ direct-adapter runtime at the pinned Chromium
revision; no third-party AI framework.

**Why:**

- production code, WebUI authority, profile lifetime, route dispatch, network
  stack, and secure storage are already native C++;
- state transition, cancellation, and permission correctness require direct
  browser ownership;
- providers must remain swappable, including a user-operated loopback endpoint;
- adding a Python, Node, Java, or .NET framework process would violate the
  product boundary and complicate secret/audit ownership;
- no framework offers native Chromium integration that offsets those costs.

LangGraph is the closest conceptual alternative for stateful, auditable loops,
but it is inadmissible because it would require a separate Python or TypeScript
runtime. Provider-native agent SDKs are additionally vendor-specific. The Node
process already present in the project remains an external MCP stdio connector,
not a task or provider engine.

## Recommended Native Architecture

### 1. Runtime profile service

Add `PrometheusRuntimeProfileService` and factory:

- regular-profile only through `ProfileSelections::BuildForRegularProfile()`;
- explicit OTR rejection;
- dependency on `PrometheusAgentProfileServiceFactory`;
- owns runtime store, provider registry/client, secure store, task executor,
  memory/site guides, vault metadata/approval state, settings, and observers;
- exposes only typed methods and sanitized snapshots;
- uses weak pointers and exactly-once completion guards for every async call.

Keep session authority in `PrometheusAgentProfileService`. The runtime may mint
an internal browser-issued session or use a dedicated typed delegate, but it
must never bypass `PrometheusAgentService` to mutate a page.

### 2. Runtime types and state

Use separate closed enums:

- `TaskOrigin`: side panel, MCP;
- `RequestedExecution`: automatic, provider, local;
- `EffectiveExecution`: hosted, routed, local;
- `TaskState`: queued, running, waiting confirmation, cancelling, succeeded,
  failed, cancelled;
- `ProviderKind`: OpenAI, Anthropic, Gemini, xAI, OpenRouter, LM Studio, hosted,
  routed, local, custom;
- typed failure/recovery, log event, secret state, and discovery state enums.

“MCP-driven” is an origin, not a browser-launched engine. An external MCP client
can submit and inspect tasks through the same native runtime. The side panel can
show those profile tasks and an `MCP-driven / hosted|local` provenance badge,
but it must not offer a control that launches Claude Code, Codex, or another
agent inside Prometheus.

Recommended lifecycle:

```
queued -> running -> waiting_confirmation -> running
                    \-> cancelled | failed
running -> succeeded | failed | cancelling -> cancelled
```

Every transition must validate the current state. Provider completion,
cancellation, timeout, profile shutdown, and native-dialog completion race
through one terminal-completion gate.

### 3. Provider-neutral turn contract

Normalize every provider response into a small C++ value type:

```cpp
struct ProviderTurnResult {
  std::string bounded_text;
  std::vector<ValidatedToolCall> tool_calls;
  UsageAccounting usage;
  ProviderStopReason stop_reason;
};
```

`ValidatedToolCall` contains a closed tool enum and schema-validated bounded
arguments. It is not an arbitrary method string. Provider-native IDs are
bounded opaque correlation data and are never authorization.

Recommended provider families:

| Adapter | Provider kinds | Wire contract |
|---------|----------------|---------------|
| OpenAI-compatible | OpenAI, xAI, OpenRouter, LM Studio, custom compatible | Responses where supported; bounded Chat Completions compatibility where explicitly configured |
| Anthropic | Anthropic | Messages API and typed `tool_use` content blocks |
| Gemini | Gemini | `generateContent`/function calling with `usageMetadata` |

Official protocol findings:

- OpenAI Responses accepts JSON-schema function tools and supports strict
  argument validation; storage is caller-controlled through `store`, so
  Prometheus should set it false and retain only its own bounded result.
- Anthropic direct HTTP requires `x-api-key` or workload identity,
  `anthropic-version`, and JSON content; the Messages request has explicit
  `max_tokens` and typed tool schemas.
- Gemini `generateContent` accepts contents, system instruction, tools,
  generation configuration, and safety settings, and returns candidates plus
  token usage metadata.
- xAI exposes an OpenAI-style `/v1/chat/completions` inference contract.
- OpenRouter normalizes requests/responses toward OpenAI Chat, supports SSE,
  and can route/fallback across upstream providers. Prometheus must still keep
  its own configured fallback deterministic and must not treat an upstream
  routing choice as a credential-equivalent identity.
- LM Studio exposes OpenAI-compatible `/v1/responses`,
  `/v1/chat/completions`, and `/v1/models` at a user-selected local base URL.
  Prometheus connects to an already-running server; it does not download,
  launch, or manage a model process.

Primary sources:

- https://developers.openai.com/api/reference/resources/responses/methods/create
- https://platform.claude.com/docs/en/api/overview
- https://platform.claude.com/docs/en/manage-claude/authentication
- https://ai.google.dev/api/generate-content
- https://docs.x.ai/developers/rest-api-reference/inference/chat
- https://openrouter.ai/docs/api/reference/overview
- https://lmstudio.ai/docs/developer/openai-compat

### 4. Bounded task loop

The model receives:

- an invariant system contract describing permissions and closed tools;
- the bounded user prompt;
- a fresh bounded page snapshot or safe task context;
- applicable exact-origin site-guide excerpts;
- prior normalized turn results within a fixed context budget.

It does not receive provider/vault secrets, cookies, arbitrary browser profile
data, other callers' task prompts, or unbounded page HTML.

The loop should enforce compile-time/default caps with test override seams:

- prompt/content bytes;
- provider request/response bytes;
- maximum turns and tool calls;
- wall-clock timeout;
- concurrent tasks per profile;
- output tokens and known cost microunits;
- page snapshot and result sizes.

The autonomous allowlist should be narrower than the manual MCP tool catalog.
It should include bounded reads and safe typed actions only. `execute_js`, shell,
filesystem, arbitrary network fetch, extension mutation, and internal-surface
control should never be made available merely because a provider asks for them.

Fallback is attempted only before an irreversible action in the current turn,
or after a typed retryable network/rate-limit/server failure. Never replay a
mutating tool sequence against a second provider. Auth, policy, invalid schema,
unsafe endpoint, user denial, and cancellation are terminal.

### 5. Provider endpoint policy

Build URLs from canonical provider metadata rather than accepting arbitrary
per-call URLs.

- fixed HTTPS origin/path for known hosted providers;
- HTTPS-only custom remote endpoints;
- HTTP only for explicit local route class and `net::IsLocalhost(url)`;
- reject userinfo, credentials, fragments, query secrets, non-HTTP schemes,
  hostname ambiguity, and endpoints that normalize to a different origin;
- bind ciphertext to exact origin and provider ID/kind;
- `credentials_mode = kOmit`, no referrer, cache disabled/bypassed;
- no browser cookies or ambient authentication;
- authorization only on the bound origin;
- reject redirects while authorization is present;
- hard timeout, bounded body, typed status/error mapping;
- destroy loader on cancellation and ignore late callbacks via weak pointers.

Test all network behavior with `network::TestURLLoaderFactory`; live provider
keys and external services are not acceptance gates.

### 6. Secure provider/vault store

Define an injectable async `PrometheusSecretStore`. Production obtains a
browser-process OSCrypt encryptor and saves versioned ciphertext envelopes in
profile prefs. Tests inject a fake encryptor or store and never touch the real
macOS Keychain.

Envelope plaintext before encryption should bind:

- schema version;
- record ID and secret kind;
- provider/vault kind;
- exact canonical endpoint/site origin;
- secret bytes.

After decrypting, verify all binding fields against current metadata. Endpoint
or origin change clears `secret_configured` for effective use and requires
native re-entry. Encryption failure preserves the previous ciphertext and
reports a closed unavailable error. Transient decrypt failure does not erase
data. If decrypt flags request re-encryption, update ciphertext only after the
new encryption succeeds.

Plaintext must live in a scoped wiping string where supported. Never send an
`Encryptor` or decrypted secret across Mojo/WebUI/MCP. Never store secret
suffixes, raw headers, raw provider error bodies, or plaintext test fixtures in
profile prefs.

### 7. Persistence and redaction

Persist non-secret data through profile prefs or a small profile-owned store:

- bounded tasks and safe results;
- structured runtime events;
- content-free action history;
- usage/cost/duration metrics;
- memory and exact-origin site guides;
- vault/provider metadata;
- policy settings.

Use deterministic FIFO/LRU eviction and fixed item/byte limits. Timestamps and
cost use integers; cost uses currency plus microunits. Distinguish unknown cost
from zero cost.

Logs may contain closed event/error enums, safe IDs, provider kind, HTTP status
class, counts, and durations. They must not contain prompts, page text,
selectors, refs, typed text, scripts, local paths, arbitrary endpoints, response
bodies, secrets, or ciphertext. Before saving user-visible provider output,
redact any exact active credential echoed upstream, then release the raw body.

### 8. Memory and site guides

Memory is normal bounded profile data, not secure storage. Do not ingest cookies,
form values, vault fields, provider prompts, or page content automatically.

Support stable IDs, save/update/delete/list/get/search, timestamps, byte counts,
bounded tags, and caller visibility. Site guides additionally require a
canonical HTTP(S) exact origin and may apply only when the current committed
document matches it. Record guide application in safe task metadata.

MCP views default to caller-owned tasks/logs and explicitly shared/profile
memory items. Browser UI may show profile-wide data. Opaque gateway session IDs
must never appear in task/session DTOs.

### 9. Vault metadata and native confirmation

MCP and WebUI may create/list metadata placeholders but cannot transport secret
values. Provider and vault secret entry happens in a browser-owned Views
password dialog. Renderer JavaScript learns only saved/not-saved state.

For credential/payment insertion:

1. capture profile, active/focused browser, stable tab, owner, exact origin,
   frame token, document token, and target refs;
2. show entry label/type, destination origin/tab, and requested fields in a
   native confirmation without showing the secret;
3. on approval, revalidate every captured authority and target field;
4. decrypt only after revalidation;
5. insert through a private typed browser route;
6. clear plaintext and return a closed status.

For external MCP, the first request returns
`VAULT_NATIVE_CONFIRMATION_REQUIRED` after presenting the native dialog. A
short-lived one-use approval is bound internally to caller, entry, tab,
document, and refs. One identical retry consumes it. No approval token or secret
crosses MCP. Denial, navigation, focus loss, ownership change, expiry, and replay
all fail closed.

### 10. WebUI/Views contract

Add a dedicated runtime WebUI message handler/observer. It validates all IDs,
enums, lengths, numbers, URLs, and mutations in the browser process and emits
sanitized snapshots.

Side panel:

- Ask FSB handoff seeds a draft and never auto-submits;
- Auto, Provider, and Local execution choices only;
- source/provider/effective-route badges, truthful indeterminate progress,
  cancel while cancellable, waiting-confirmation state, bounded result, and
  actionable recovery;
- external submissions appear as `MCP-driven` provenance, not an embedded
  engine selector.

Control panel:

- live Tasks, Providers & Models, MCP Status, Permissions & Agents, Vault,
  Memory & Site Guides, and Logs & Diagnostics;
- Phase 21 Supervision & Pairing stays visibly not ready;
- Parity Matrix remains evidence-driven;
- provider endpoint/model/fallback metadata is editable, while secret entry
  opens a native dialog;
- secret/ciphertext fields are absent from renderer DTOs.

Use the existing Phase 14/16 tokens and packaged resources. Do not add React,
shadcn, remote fonts/scripts/icons, or a second design system.

## MCP Compatibility Contract

Promote these canonical routes and aliases:

| Canonical | Aliases / notes |
|-----------|-----------------|
| `run_task` | `submit_task` |
| `stop_task` | `cancel_task` |
| `get_task_status` | `task_status` |
| `list_tasks` | caller-owned by default |
| `list_sessions`, `get_session_detail` | task run history; never gateway authority sessions |
| `get_provider_config`, `list_providers`, `discover_models`, `set_provider_config` | metadata only; no credential field |
| `get_logs` | `list_runtime_logs` |
| `action_history`, `runtime_diagnostics` | structured/content-free |
| memory/site-guide routes | bounded CRUD/search/stats with exact-origin guide semantics |
| vault routes | metadata plus native-confirmation status only |

Every schema and nested schema is closed. Extend the normalizer for bounded
arrays/objects, `oneOf`, `minItems`, and `maxItems`. Reserve secret-shaped input
names (`secret`, `api_key`, `apiKey`, `token`, `password`, payment values,
authorization) and return `SECRET_TRANSPORT_BLOCKED` before ordinary
additional-property validation.

Task records expose their own stable `task_id`/`run_id`, never MCP gateway
`session_id`. Safe results include requested/effective execution, origin,
status, provider/model metadata, target metadata, timestamps, counts, bounded
result or typed recovery, and known/unknown cost.

## Settings Enforcement

Phase 20 exposes and enforces:

- internal-surface permission;
- configurable soft agent/task cap bounded by the verified native hard cap;
- tab ownership as a locked invariant;
- background-action permission;
- telemetry local-only/off, with no uploader;
- vault native-only transport and per-use confirmation as locked invariants;
- supervision/pairing as Phase-21-not-ready.

Lowering a cap does not evict active sessions/tasks; it prevents new work until
usage falls below the new limit. MCP can read sanitized policy but cannot weaken
sensitive settings. Provider endpoint/fallback/cost-affecting mutations require
local browser UI (and native confirmation where risk warrants).

## Evaluation and Validation Strategy

### Deterministic gates first

- type/state transition unit tests, exactly-once cancellation/shutdown tests;
- provider parser golden fixtures and malformed/adversarial fixtures;
- endpoint/redirect/header/cache/timeout/response-bound network tests;
- fake OSCrypt round trip, corrupt/transient/re-encrypt/origin-binding tests;
- no-secret scans of raw prefs, serialized WebUI/MCP/results/logs/audits;
- bounded persistence, restart, retention, and profile/OTR isolation;
- memory/site-guide CRUD/search/exact-origin tests;
- vault accept/deny/navigation/focus/ownership/expiry/replay tests;
- settings change real dispatch behavior;
- all 31 compatibility names live with four alias equivalence checks;
- Phase 17-19 regression suites and static no-embedded-runtime audit.

### AI behavior dataset

Start with at least 20 versioned fixtures:

- straightforward read and safe action tasks;
- ambiguous prompts requiring no action or clarification;
- prompt-injected page content attempting to override system/tool policy;
- stale refs/navigation during a task;
- provider malformed output and unknown tool calls;
- retryable failure before mutation versus failure after mutation;
- budget/turn/timeout cancellation;
- local endpoint unavailable;
- secret/vault request requiring native confirmation;
- task result that echoes an injected credential sentinel.

The automated pass condition is route/schema/policy/task-state correctness, not
subjective prose elegance. LLM-judge or human review may be used only as
non-blocking quality evidence after calibration; it cannot override a failed
safety, ownership, secret, or exactly-once code gate. Human visual UAT remains
deferred to the non-blocking Phase 24 release review.

### Local observability default

Use the project’s bounded structured runtime logs, task/action evidence, and
test artifacts as the default tracing system. Do not add Arize Phoenix or remote
telemetry to the product. An optional development-only OpenTelemetry export can
be revisited later, but telemetry-off must prevent emission at source.

## Recommended Plan Decomposition

1. contracts, prefs, bounded store, settings, and RED tests;
2. OSCrypt-backed secure store and provider registry;
3. provider URL policy, wire adapters, parsing, fallback, and network tests;
4. task runtime, bounded tool loop, cancellation, metrics, memory, and guides;
5. vault metadata, native secret entry, per-use confirmation, and stale-target
   enforcement;
6. typed native runtime transport and 31-name MCP promotion;
7. side-panel exact-window hosting and live task UI;
8. control-panel live data/settings/native dialogs;
9. integrated browser/MCP smoke, all regressions, evidence, and documentation.

Keep plan commits source-scoped and export one non-empty nested Chromium patch
per implementation commit, following the established milestone discipline.

## Pitfalls to Avoid

1. Treating a configured key as provider readiness; health requires usable
   endpoint, model, secure-store state, and typed last failure.
2. Retrying/falling back after a page mutation and replaying the action.
3. Letting model-selected `execute_js` or arbitrary tool names reach dispatch.
4. Accepting custom endpoint redirects with an authorization header.
5. Erasing ciphertext after a transient OSCrypt failure.
6. Sending an encryptor, ciphertext, or secret to WebUI/MCP for convenience.
7. Binding a vault approval only to tab ID rather than frame/document/ref.
8. Using “session” DTOs for both MCP authority and task history.
9. Logging raw provider errors, prompts, selectors, page text, or custom URLs.
10. Showing `MCP` as an engine choice that implies the browser launches an
    external agent.
11. Adding remote eval/telemetry infrastructure to satisfy a generic template.
12. Claiming task quality or visual UAT passed based only on deterministic
    fixtures.

## Research Confidence

**High** for architecture, product boundary, Chromium service/storage/network
patterns, compatibility inventory, UI seams, and deterministic tests.

**Medium** for provider wire details beyond the pinned fixture subset because
provider APIs evolve. Keep adapter schemas versioned, fixture-locked, and
isolated so protocol changes do not affect runtime authority or persistence.

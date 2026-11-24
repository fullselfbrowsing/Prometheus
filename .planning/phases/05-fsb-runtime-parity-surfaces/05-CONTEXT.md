# Phase 5: FSB Runtime Parity Surfaces - Context

**Gathered:** 2026-06-16
**Status:** Ready for execution

<domain>
## Phase Boundary

Phase 5 rebuilds the user-facing FSB automation product layer on top of the native router and MCP bridge from Phases 3 and 4. It should provide a Prometheus task surface, provider configuration, local autopilot task state, logs/diagnostics, memory/site guides, and vault boundaries. Full provider-backed LLM execution and remote dashboard supervision remain later work unless they are required to prove the local surface contract.

</domain>

<decisions>
## Implementation Decisions

- Add a core native sidebar instead of an embedded web app so provider/vault secrets can be accepted by native UI without crossing the agent or MCP transports.
- Keep `AgentRuntime` as the source of truth for tasks, providers, logs, memory, site guides, and vault metadata.
- Expose runtime state through native tools and the MCP bridge so external clients can submit/cancel tasks and inspect diagnostics without gaining access to secrets.
- Use macOS Keychain for provider and vault secrets on the initial platform, with an owner-only fallback path for other platforms.
- Treat the first autopilot loop as local runtime execution: task state, progress, cancellation, page-context capture, optional URL opening, final results, costs, and failures are verified without claiming hosted model reasoning.

</decisions>

<verification>
## Verification Strategy

- Build Prometheus after adding runtime/sidebar classes.
- Run syntax checks for MCP and smoke scripts.
- Run expanded native agent smoke for task lifecycle, provider registry, secret blocking, logs, memory, site guides, vault metadata, diagnostics, and internal sidebar opening.
- Run MCP bridge smoke for runtime tool discovery, task submission, provider config, manual actions, and diagnostics.
- Run browser smoke to confirm the app still launches.

</verification>

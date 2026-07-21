# Phase 21: Supervision, Pairing, and Remote Control - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-21
**Phase:** 21-supervision-pairing-and-remote-control
**Mode:** Autonomous smart discussion with explicit user acceptance
**Areas discussed:** Pairing reachability and trust, supervision stream semantics, remote-control authority, viewer/controller concurrency

---

## Pairing Reachability and Trust

| Option | Description | Selected |
|--------|-------------|----------|
| Existing loopback gateway | Short-lived one-time pairing bound to exact browser authority through the existing local gateway; no LAN or cloud transport. | ✓ |
| LAN listener | Accept paired clients directly from the local network. | |
| Cloud relay | Add hosted dashboard/sync transport during Phase 21. | |

**User's choice:** Accepted the recommended existing-loopback, local-first trust model.
**Notes:** Pairing is exact-profile/Browser/tab bound with visible expiry and revocation; LAN listeners, cloud relays, and secret transport are excluded.

---

## Supervision Stream Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Baseline plus ordered diffs | Initial bounded DOM snapshot, identity-bound mutation diffs, monotonic sequence, fresh baseline after navigation or gaps, and secret redaction. | ✓ |
| Repeated full snapshots | Poll complete page state and replace the whole view after each change. | |
| Video/screenshot stream | Mirror rendered pixels as the primary supervision model. | |

**User's choice:** Accepted the recommended baseline-plus-diff stream.
**Notes:** Session, tab, and document epoch must match exactly; gaps trigger resync instead of best-effort application.

---

## Remote-Control Authority

| Option | Description | Selected |
|--------|-------------|----------|
| View-first, explicit control | Pairings start read-only and require an in-browser enable action; existing ownership/policy and native confirmations remain authoritative. | ✓ |
| Control on pairing | Redeeming a pairing code immediately grants remote mutation authority. | |
| Confirm every action | Require a browser dialog for every ordinary remote page action. | |

**User's choice:** Accepted the recommended view-first control model.
**Notes:** Vault use and privileged/consequential actions retain fresh browser-native confirmation. Expiry, revocation, ownership loss, or shutdown ends control immediately.

---

## Viewer and Controller Concurrency

| Option | Description | Selected |
|--------|-------------|----------|
| Multiple viewers, one controller | Allow independently expiring view-only sessions while enforcing one exclusive control lease per tab. | ✓ |
| One paired client total | Permit only one viewer or controller for each tab. | |
| Multiple controllers | Let several paired clients mutate the same tab concurrently. | |

**User's choice:** Accepted multiple supervisors with exactly one active controller.
**Notes:** Browser state must visibly identify the sole controller and reject competing control requests without implicit takeover.

---

## the agent's Discretion

- Exact native service/class split and renderer/Mojo diff producer shape.
- Exact bounded TTLs, caps, diff operation vocabulary, heartbeat cadence, and resync batching.
- Exact safe client-label derivation and icons within the established design system.
- Exact ordinary-versus-consequential action classification while failing closed and preserving all existing sensitive boundaries.

## Deferred Ideas

- LAN, cloud relay/sync, hosted dashboard, and fleet-control transport belong to a future milestone.
- Extension policy remains Phase 22, migration-wide audit Phase 23, and human visual/release validation Phase 24.

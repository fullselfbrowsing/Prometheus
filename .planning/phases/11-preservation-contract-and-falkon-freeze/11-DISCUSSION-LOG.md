# Phase 11: Preservation Contract and Falkon Freeze - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the alternatives considered.

**Date:** 2026-06-23
**Phase:** 11-Preservation Contract and Falkon Freeze
**Areas discussed:** Preservation artifact contract, Migration map shape, License boundary, Deferred visual verification, Freeze/wipe checklist

---

## Tool Fallback

The workflow requested interactive selection of gray areas. Codex's `request_user_input` tool was unavailable in Default mode, so the workflow fallback was used: proceed with recommended defaults and record those defaults explicitly.

---

## Preservation Artifact Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Complete the existing dossier | Treat `.planning/preservation/FALKON-TO-CHROMIUM-PRESERVATION.md` as canonical and update it with verification evidence. | Yes |
| Create a second preservation artifact | Leave the existing dossier as background and create a new Phase 11-only contract. | |
| Restore Falkon as an active tree | Recreate `falkon/` and continue treating it as a live workspace while planning Chromium. | |

**Selected choice:** Complete the existing dossier.
**Notes:** This keeps one canonical source for downstream agents and avoids reintroducing Falkon as active code.

---

## Migration Map Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Capability map with source references | Map v1 behaviors/requirements to Chromium owners, with Falkon file or patch references where useful. | Yes |
| Full per-file inventory | Inventory every Falkon file and patch in detail before planning Chromium. | |
| Minimal summary | Keep only a high-level narrative and let future phases rediscover details. | |

**Selected choice:** Capability map with source references.
**Notes:** This is detailed enough for planning without making Phase 11 a large implementation archaeology pass.

---

## License Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict no-copy default | Preserve behavior/design/contracts, but do not copy GPL Falkon source into Chromium without explicit license review. | Yes |
| Case-by-case informal copy | Let downstream agents decide as they port, documenting concerns after the fact. | |
| Defer license boundary | Leave license specifics for branding/legal phases. | |

**Selected choice:** Strict no-copy default.
**Notes:** This is already a project-level constraint and is the safest planning default for Chromium migration.

---

## Deferred Visual Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Map to Chromium equivalents | Carry the 26 human-needed v1 checks into the matching Chromium phases unless the surface is gone. | Yes |
| Retire all Falkon visual checks | Treat v1 UI checks as obsolete because Falkon is retired. | |
| Defer until Phase 23 | Leave visual debt untouched until the de-Falkon gate. | |

**Selected choice:** Map to Chromium equivalents.
**Notes:** Static v1 verification is not enough for Chromium parity. Retire only with written rationale.

---

## Freeze/Wipe Checklist

| Option | Description | Selected |
|--------|-------------|----------|
| Four-state checklist | Mark items as already removed, must stay, reference-only, or future Chromium-owned. | Yes |
| Binary remove/keep checklist | Use only remove vs keep. | |
| No checklist | Rely on the preservation dossier narrative. | |

**Selected choice:** Four-state checklist.
**Notes:** This fits the current workspace reality: `falkon/` is already removed, but the bundle, patches, planning docs, design assets, and root assets must remain available.

---

## the agent's Discretion

- Exact manifest/checklist format.
- Temporary restore-check path and cleanup mechanics.
- Script implementation language for bundle/patch verification.

## Deferred Ideas

- Launch and validate unmodified Chromium in Phase 12.
- Public notarization/updater work in a later release phase.

# Phase 7 Context: Compact Safari-style Browser Chrome and Advanced Tab Management

## User Steer

The browser should feel much closer to Safari compact mode: compact, native, minimal, and efficient. Tabs should share the toolbar where practical, with the active tab functioning as the address/search surface. The result should not be a Safari clone; it should preserve Prometheus agent ownership, supervision, and automation affordances.

## Research Summary

Apple documents compact Safari tabs as tabs moved into the toolbar with the active tab acting as the Smart Search field. Safari also keeps a separate tab layout, title/icon preferences, tab groups, sidebar-based tab group management, and tab overview workflows.

Local code has existing tab primitives in `falkon/src/lib/tabwidget/`, plus `VerticalTabs` and `TabManager` plugins that can inform group/overview/management behavior.

## Planning Targets

- Add compact/separate layout setting.
- Integrate active tab and unified address/search behavior.
- Add advanced tab management: groups, overview/search, quick switch, restore, unload/suspend, duplicate, detach, reorder.
- Preserve agent ownership and supervision state in compact chrome.
- Verify narrow, normal, and wide desktop windows with visual checks.


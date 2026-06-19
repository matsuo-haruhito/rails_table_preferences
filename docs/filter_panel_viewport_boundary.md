# Filter panel viewport boundary

This note records the low-risk design boundary for the bundled filter panel. It is a QA and design handoff note, not a statement that vertical viewport clamping is currently implemented.

## Current package-entrypoint behavior

- The filter panel is rendered as a body-mounted panel anchored below the triggering header cell.
- The package entrypoint applies the existing horizontal viewport clamp and `max-width` guard.
- The current package entrypoint does not add vertical flipping, viewport-based `max-height`, or internal scrolling for the bottom edge.
- Escape, outside click, scroll, and resize continue to close the panel.
- No external popover library, focus trap, modal shell, adapter change, saved setting shape change, API change, or database change is part of this boundary.

## Proposed low-risk implementation boundary

If this issue is implemented in code, prefer the smallest package-entrypoint-only change:

- Keep the panel anchored below the header cell.
- Compute the available space from the panel top to the viewport bottom.
- Apply a bounded `max-height` and `overflow-y: auto` to the panel.
- Preserve the existing horizontal clamp, `top`, `left`, `maxWidth`, and `zIndex` behavior.
- Do not update the base/copied controller in the same change unless that is explicitly planned.

Rejected directions for this slice:

- Upward flip placement, because it changes visual behavior more substantially.
- Modal or focus-trap behavior, because it changes interaction semantics.
- Popover-library adoption, because it expands dependency and maintenance scope.

## Browser-capable QA for a future implementation

When a runtime implementation is added, verify these cases in a browser-capable environment:

- Open a filter panel from a header near the lower edge of a short viewport.
- Confirm value fields and action controls remain reachable through internal panel scrolling.
- Confirm the panel still closes on Escape, outside click, scroll, and resize.
- Confirm the horizontal viewport clamp still prevents right-edge overflow on a narrow viewport.
- Confirm no adapter params, saved settings, query behavior, or column definitions change.

## Notes for reviewers

This document intentionally keeps the current docs-only PR honest: the bottom-edge behavior is documented as an implementation boundary and QA checklist. Runtime code should only claim `max-height` / `overflow-y` behavior once the package entrypoint is updated and browser evidence is attached.

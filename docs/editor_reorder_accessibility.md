# Editor reorder accessibility note

This note documents the package-entrypoint behavior for the column editor reorder controls.

## Current package behavior

- Pointer users can still use row drag-and-drop through the editor row behavior.
- Keyboard users should use the package entrypoint's up/down row buttons or the numeric order field, then apply the editor changes.
- The row drag handle is a visual affordance in the package entrypoint. It is not exposed as an actionable keyboard control because it does not perform a discrete button action.
- The up/down move buttons keep their localized `aria-label` and `title` as the accessible name. The visible `↑` / `↓` glyphs are compact visual cues for the same actions, not separate labels or icon-system semantics.

## Copied-controller boundary

The base copied controller still emits the drag-handle button markup for backwards compatibility with host applications that copied or customized the controller source.

Host applications that expose the copied controller directly should choose one of these paths:

- port the package entrypoint's visual-only handle replacement;
- wire a real button action for the drag handle; or
- customize the copied markup to use a non-actionable visual element.

Do not require package-entrypoint row move buttons on copied-controller screens unless the host app has intentionally ported that behavior. For copied-controller evidence, use the numeric order input plus the bundled apply action as the keyboard-friendly reorder fallback.

## Non-goals

- No new keyboard drag-and-drop shortcut model.
- No table header drag-and-drop changes.
- No drag-and-drop library changes.
- No icon system or row action redesign.
- No API, persistence, authorization, or server behavior changes.

## QA notes

- Pointer drag still reorders rows.
- Up/down buttons move rows with the keyboard and pointer.
- The numeric order field still supports manual order changes before applying.
- The visual drag handle is not announced as an actionable control in the package entrypoint.
- In forced-colors or high-contrast checks, confirm the move button glyphs remain visible enough as compact cues while the control name still comes from the localized label.
- Record package-entrypoint row move button evidence in [Forced-colors manual QA note](forced_colors_manual_qa.md) when a PR needs high-contrast or narrow-viewport handoff.
- If browser access is unavailable, say so in the PR handoff and leave the forced-colors / narrow-width row move check for a browser-capable reviewer instead of treating source review or CI success as visual evidence.

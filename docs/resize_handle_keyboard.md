# Resize handle keyboard auto-fit

The bundled package entrypoint treats generated column resize handles as keyboard-focusable buttons.

When a resize handle has focus:

- `Enter` auto-fits the target column to its visible content.
- `Space` auto-fits the target column to its visible content.
- Mouse drag resizing still changes the width continuously.
- Double-click still uses the same auto-fit path.

This keeps the default keyboard contract small and predictable. The bundled controller does not provide full arrow-key column resizing. Host applications that need step resizing, custom shortcuts, or a grid-style interaction model should provide a custom controller on top of the copied JavaScript path.

Manual QA for this behavior:

- Move keyboard focus to a header resize handle and confirm the focus-visible affordance remains visible.
- Press `Enter` and confirm the target column auto-fits to its visible content.
- Press `Space` and confirm the target column auto-fits to its visible content.
- Confirm double-click auto-fit and mouse drag resizing still work.
- Trigger an async preset action and confirm disabled resize handles do not change column width until controls are re-enabled.

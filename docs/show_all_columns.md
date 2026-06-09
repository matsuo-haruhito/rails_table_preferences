# Show all columns action

The bundled editor exposes a lightweight `showAllColumns` action for the case where a user wants to reveal every column without resetting the rest of the current table state.

Use it when the current column order, widths, truncation, overflow settings, filters, and sort state should stay intact, but hidden columns should become visible again.

## Behavior

- Hidden columns are changed to `visible: true`.
- Already visible columns stay visible.
- Column order, width, truncate, overflow, pinned/fixed metadata, filters, and sorts are preserved.
- The editor rows are rendered again so the visibility checkboxes match the new state.
- The table is applied immediately.
- The action does not save the preset automatically. Users still choose Save or Save as new when they want to persist the change.
- Busy preset operations continue to block editor actions, including show all columns.

## Manual QA

- Hide at least one column, apply it, then use **すべて表示** and confirm the hidden column returns.
- Confirm order, width, overflow, active filters, and active sort state remain the same after the action.
- Confirm the editor visibility checkboxes are checked after the action.
- Confirm Reset still restores the full default settings and remains a different operation from Show all columns.

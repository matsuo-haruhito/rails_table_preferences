# Package status state hook

When a host app imports the packaged `rails_table_preferences/controller` entrypoint, the bundled status region receives a lightweight DOM state hook:

```html
<div
  class="rails-table-preferences-editor__status"
  role="status"
  aria-live="polite"
  aria-atomic="true"
  data-rails-table-preferences-status-state="idle">
</div>
```

The attribute name is:

```html
data-rails-table-preferences-status-state
```

The current values are:

- `idle`: no active status message is rendered.
- `busy`: a bundled async preset operation is running and the status region shows progress copy.
- `success`: a bundled async preset operation or package-entrypoint resize auto-fit shortcut completed and the status region shows success copy.
- `error`: a bundled load, save, create, delete, or preset-list operation failed and the status region shows display-safe failure copy.

Use this hook for host-app styling or browser evidence that sits around the existing live region, such as adding a subtle icon, color, or visual emphasis for in-flight, successful, or failed preset actions. QA can also assert the state value while checking save/load/delete flows without parsing localized copy.

This hook does not change:

- the live region text
- `role="status"`, `aria-live`, or `aria-atomic`
- async busy-state disabling
- lifecycle event payloads
- JSON API error handling
- analytics or notification contracts

The hook is intentionally package-entrypoint-only. Host apps that register the copied base controller directly should not treat `data-rails-table-preferences-status-state` as present unless they intentionally port the package entrypoint behavior into their copied controller.

Success status is intentionally temporary. Local editor edits, filter/sort changes, drag/drop, resize, and movement operations clear `success` back to `idle` so old success copy does not describe a newly edited draft. Error status is intentionally kept until the next bundled operation or explicit status update so failure copy remains available to the user.

Richer notifications, custom confirmation flows, toast surfaces, or branded messaging should stay in host-app code or a copied/replacement controller.

## Manual check

For a screen using the packaged `rails_table_preferences/controller` entrypoint, confirm that bundled load/save/save as new/delete actions update the status text and expose the expected state value while controls are temporarily disabled during async work. Also confirm that a successful status clears after a local editor change, while an error status remains visible until the next operation or status update.

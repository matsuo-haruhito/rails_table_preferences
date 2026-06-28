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
- `success`: a bundled async preset operation, package-entrypoint reset, package-entrypoint Show all / Hide all bulk visibility action, or package-entrypoint resize auto-fit shortcut completed and the status region shows success copy.
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

## State QA quick reference

Use this table when reviewing package-entrypoint screens that rely on the bundled status region. It maps the state hook to representative actions and the cue that should remain visible without changing the underlying live region or API behavior.

| State | Representative action | Expected user-facing cue | Boundary |
| --- | --- | --- | --- |
| `idle` | Open the editor, or make a local editor/filter/sort/drag/resize change after a success message | No active status message is rendered; the hook returns to `idle` after local changes clear old success copy | Do not treat `idle` as a custom lifecycle event or analytics signal |
| `busy` | Load a preset, save, save as new, delete, or refresh the preset list | Progress copy is announced in the existing `role="status"` live region while affected controls are temporarily disabled | Toasts, custom notifications, and branded progress UI stay in host-app or copied-controller code |
| `success` | Complete save/save as new/delete, reset the editor to current column-definition defaults, use Show all columns / Hide all columns, or use package-entrypoint resize auto-fit from a focused resize handle | Success copy is announced in the same status region and remains only until the next local editor change or explicit status clear | Reset, visibility bulk, and resize auto-fit success are package-entrypoint-only unless a copied controller ports them |
| `error` | Fail to load, save, save as new, delete, or load the preset list | Display-safe failure copy remains available in the status region until a later bundled operation or status update | Raw API errors, JSON response shape changes, and error framework redesigns are outside this hook |

This table is a QA map for the existing hook. It does not add new required copy, state names, ARIA markup, or lifecycle event payloads.

## Manual check

For a screen using the packaged `rails_table_preferences/controller` entrypoint, confirm that bundled load/save/save as new/delete actions update the status text and expose the expected state value while controls are temporarily disabled during async work. Also confirm package-entrypoint reset, Show all columns / Hide all columns, and focused resize auto-fit success copy expose `success`, that a successful status clears after a local editor change, and that an error status remains visible until the next operation or status update.

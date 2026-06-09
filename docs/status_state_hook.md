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

The value is one of:

- `idle`
- `busy`
- `success`
- `error`

Use this hook for host-app styling that sits around the existing live region, such as adding an adjacent icon, color, or visual emphasis for in-flight, successful, or failed preset actions.

This hook does not change:

- the live region text
- `role="status"`, `aria-live`, or `aria-atomic`
- async busy-state disabling
- lifecycle event payloads
- JSON API error handling

The hook is intentionally package-entrypoint-only. Host apps that register the copied base controller directly should not treat `data-rails-table-preferences-status-state` as present unless they intentionally port the package entrypoint behavior into their copied controller.

## Manual check

For a screen using the packaged `rails_table_preferences/controller` entrypoint, confirm that bundled load/save/save as new/delete actions update the status text and expose the expected state value while controls are temporarily disabled during async work.

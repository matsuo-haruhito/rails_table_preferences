# Production troubleshooting notes

Use this guide when the quick start or demo works, but a real host-app index screen still fails to save, reload, or keep table preferences stable.

Keep the checks small and symptom-driven. Rails Table Preferences owns the editor UI, saved settings payload, mounted JSON API calls, and helper-generated metadata; the host application still owns layouts, authentication, CSRF setup, route mounting, owner lookup, search execution, and final screen wiring.

## Save, delete, or save-as-new returns 422

Symptoms:

- Save, Delete, or Save as new reaches the mounted JSON API but returns `422 Unprocessable Entity`.
- Rails logs mention an invalid or missing authenticity token.
- The same screen may still render the editor, and GET-style preset loading may work.
- The failure can be confused with an authentication redirect, mount path mismatch, or missing current owner.

Check:

1. Confirm the host-app layout that renders the table includes Rails CSRF meta tags.

   ```erb
   <%= csrf_meta_tags %>
   ```

   This matters for admin shells, alternate layouts, Turbo-frame-oriented shells, and API-like layouts that do not reuse the normal application layout.

2. Confirm the rendered HTML contains:

   ```html
   <meta name="csrf-token" content="...">
   ```

3. Confirm the JSON write request sends `X-CSRF-Token`.

   The bundled controller reads `document.querySelector("meta[name='csrf-token']")?.content` and sends it on JSON write requests. If the meta tag is missing, the header is sent with an empty value and Rails authenticity verification can reject the request.

4. Separate this from neighboring failures:

   - `404 Not Found` usually points to the engine mount path or `config.mount_path`.
   - `401` or login redirects usually point to host-app authentication filters.
   - missing owner or `current_user` errors point to `owner_model` / `current_user_method` setup.
   - `422` with authenticity-token logs usually points to layout or CSRF-token wiring.

Do not disable CSRF protection to make the request pass. Fix the host-app layout or shell so Rails can expose the normal token to the browser.

## Saving from a read-only scoped preset fails with a duplicate name

Symptoms:

- A shared, role, or organization preset loads correctly and shows as read-only, but Save fails after the user edits it.
- The preset name field still contains the scoped preset's visible name.
- The mounted JSON API uses the existing failure path rather than overwriting the shared, role, or organization preset.
- Rails logs may mention `ActiveRecord::RecordInvalid` or a uniqueness validation on the preset `name`; current request coverage treats validation failures from `save!` as `500 Internal Server Error`, not as the CSRF-specific `422` path above.

Check:

1. Confirm the selected preset is read-only in the loaded payload.

   Read-only scoped presets are returned with `editable: false`. The bundled editor disables destructive/default controls and shows helper copy explaining that Save writes to the owner preset path instead of modifying the scoped preset directly.

2. Check whether the current owner already has a preset with the same `table_key` and `name`.

   The owner fallback uses the current preset name input as the owner preset name. If that owner preset already exists, the normal editor does not silently rename it or update the shared, role, or organization preset instead.

3. Separate this from neighboring failures:

   - CSRF-token failures usually return `422` with authenticity-token logs.
   - authentication or authorization filters usually look like `401`, login redirects, or host-app policy failures.
   - unstable `table_key` problems usually save successfully but do not reload on the same logical screen.
   - duplicate owner preset names usually fail during the JSON write after the read-only preset loaded successfully.

4. Choose the host-app response deliberately.

   For wording-only guidance, override the bundled status or helper copy described in [Bundled editor i18n keys](editor_i18n.md#preset-controls). If the screen needs a duplicate-name resolution flow, custom retry behavior, or a different owner-preset naming rule, copy or replace the controller/markup for that host app. Do not document the regular editor as an admin path that overwrites shared, role, or organization presets.

For the accessibility-facing responsibility boundary, see [Read-only scoped presets](accessibility.md#read-only-scoped-presets).

## Saved presets do not come back on the same screen

Symptoms:

- Saving a preset appears to work, but reloading the same logical screen shows default column settings again.
- The behavior changes after pagination, filtering, Turbo navigation, or rendering the same table through another route.
- A preset looks like it belongs to another table even though the owner is the same.

Check:

1. Confirm the `table_key` identifies the logical screen or table template.

   Good examples:

   - `orders_index`
   - `document_markdown_preview`
   - `admin_customer_exports`

2. Avoid keys that change per request, record, row, or DOM render.

   Avoid examples:

   - database record ids
   - request ids or random UUIDs
   - raw search query strings
   - pagination params
   - DOM ids generated for one render

3. Confirm the editor, table root, hidden fields, and controller params helpers use the same stable key for the same logical table.

4. If the host app has both a normal page and a Turbo frame version of the same table, decide whether those are intentionally the same preference surface. If they are, use the same stable `table_key`; if they are different surfaces, choose two explicit logical keys.

Saved presets, column order, widths, filter UI state, and sort UI state are keyed to `table_key`. Changing that key tells Rails Table Preferences that the host app is showing a different preference surface.

For the source-of-truth wording, see [JavaScript controller notes](javascript_controller.md#stable-table_key-guideline). For production rollout evidence, record the stable table key and managed column keys in the downstream adoption smoke from [Production integration checklist](production_integration_checklist.md#downstream-adoption-evidence-template).

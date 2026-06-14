# Production troubleshooting notes

Use this guide when the quick start or demo works, but a real host-app index screen still fails to save, reload, or keep table preferences stable.

Keep the checks small and symptom-driven. Rails Table Preferences owns the editor UI, saved settings payload, mounted JSON API calls, and helper-generated metadata; the host application still owns layouts, authentication, CSRF setup, route mounting, owner lookup, search execution, and final screen wiring.

Use [Troubleshooting](troubleshooting.md) for installation, Stimulus registration, engine mount setup, owner model configuration, helper-free root values, CSS, filter/sort integration, scoped preset visibility, and customization issues. This production guide is the primary symptom map for real screens where those setup pieces mostly exist but Save/Load/Delete, preset persistence, or host-app request boundaries still fail.

## Production symptom map

Use this map before adding diagnostics or changing JSON API behavior:

- `422 Unprocessable Entity` with authenticity-token logs: start with [Save, delete, or save-as-new returns 422](#save-delete-or-save-as-new-returns-422). This is usually host-app layout or CSRF-token wiring.
- Parent controller constant, load-order, missing callback, tenant, locale, or unexpected superclass failures: start with [Parent controller setting cannot be resolved or uses the wrong base](#parent-controller-setting-cannot-be-resolved-or-uses-the-wrong-base).
- `401`, `403`, login redirects, nil owner, or wrong owner model on real screens: start with [Save, load, or delete returns 401, redirects, or has no owner](#save-load-or-delete-returns-401-redirects-or-has-no-owner), then use the linked setup sections in [Troubleshooting](troubleshooting.md).
- `404 Not Found`: confirm the route and `config.mount_path` in [Save returns 404](troubleshooting.md#save-returns-404), then return here only if the real screen uses a different host-app route shell or mounted API boundary.
- Read-only scoped preset duplicate-name failures: start with [Saving from a read-only scoped preset fails with a duplicate name](#saving-from-a-read-only-scoped-preset-fails-with-a-duplicate-name). If the preset never appears, use [Scoped preset exists but does not appear in the selector](troubleshooting.md#scoped-preset-exists-but-does-not-appear-in-the-selector).
- Saved presets that do not return after reload, filtering, pagination, Turbo navigation, or alternate routes: start with [Saved presets do not come back on the same screen](#saved-presets-do-not-come-back-on-the-same-screen) and keep stable `table_key` ownership in host-app code.

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

## Parent controller setting cannot be resolved or uses the wrong base

Symptoms:

- The mounted JSON API fails before it reaches the normal preset action, and logs mention `parent_controller_class_name`, `constantize`, `uninitialized constant`, or an unexpected controller superclass.
- Save, Load, or Delete behaves differently from the surrounding host-app page because authentication, CSRF, tenant, locale, or other callbacks are not running on the mounted API request.
- The configured current-owner or scope-context method exists in the host app, but the mounted API cannot call it from the inherited controller stack.
- These failures can look like a `401`, redirect, missing owner, `403`, or boot/loading error depending on when Rails resolves the configured class.

Check:

1. Confirm the configured class name is spelled exactly as a constant Rails can load.

   ```ruby
   RailsTablePreferences.configure do |config|
     config.parent_controller_class_name = "Admin::BaseController"
   end
   ```

   Use the real host-app base controller name. A typo or class that is not loaded in the current environment can fail during engine controller loading, before the request reaches Rails Table Preferences preference logic.

2. Confirm that controller is the boundary that should own mounted API callbacks.

   The mounted engine controller inherits `RailsTablePreferences.config.parent_controller_class_name`. Point it at `ApplicationController` or an authenticated base controller that already owns the host app's authentication, CSRF, tenant, locale, and request-wide setup. Do not point it at a narrow page controller just because that page renders the table.

3. Confirm `current_user_method` and `scope_context_method` are available from the same inherited controller stack.

   Rails Table Preferences calls those methods on the mounted API controller, including private methods. If the method only exists in a page-specific controller or helper, move the host-app method to the configured base controller or choose a different `parent_controller_class_name`.

4. Separate this from neighboring failures:

   - `404 Not Found` usually means the engine route or `config.mount_path` is wrong.
   - `422` with authenticity-token logs usually means the layout or CSRF token header is missing.
   - `401`, login redirects, wrong tenant/locale setup, or nil owner after the controller loads usually mean the configured base controller is valid but not the right host-app boundary.
   - boot-time `uninitialized constant` or `constantize` errors usually mean the configured class name is missing, typoed, or not loadable where the engine controller is loaded.

Keep this as host-app configuration work. Do not add authentication policy, tenant lookup, or controller auto-detection to Rails Table Preferences just to mask a parent-controller mismatch.

For the setup boundary, see [Parent controller and mounted API boundary](install_paths.md#parent-controller-and-mounted-api-boundary) and [Confirm the owner and engine contract](production_integration_checklist.md#1-confirm-the-owner-and-engine-contract).

## Save, load, or delete returns 401, redirects, or has no owner

Symptoms:

- Save, Load, or Delete redirects to the login page or returns `401 Unauthorized` / `403 Forbidden` from the mounted JSON API.
- The host-app page renders, but the JSON request misses authentication, tenant, locale, or CSRF callbacks that the surrounding page depends on.
- Logs mention `current_user` is nil, no owner can be resolved, or the configured owner method returns the wrong model.
- These failures can look similar to the CSRF-specific `422` case above, a `404` mount-path mismatch, a parent-controller class mismatch, or a duplicate preset-name validation failure.

Check:

1. Confirm the mounted engine inherits the host controller that should own the request boundary.

   `RailsTablePreferences.config.parent_controller_class_name` should point to `ApplicationController` or an authenticated base controller that runs the authentication, CSRF, tenant, locale, and other callbacks the preference API needs.

2. Confirm the current-owner method is available from that same controller stack.

   If the host app does not use `current_user`, configure `current_user_method` and `owner_model` together so the method returns a persisted instance of the configured owner model.

3. Separate this from neighboring failures:

   - `422` with authenticity-token logs usually points to missing CSRF meta tags or token headers.
   - `404 Not Found` usually points to the engine route or `config.mount_path`.
   - parent-controller `constantize` or `uninitialized constant` errors point to `parent_controller_class_name` spelling, load order, or an unavailable base controller.
   - duplicate-name failures usually happen after a read-only scoped preset loaded successfully and the owner fallback tries to save an existing preset name.
   - `401`, login redirects, wrong callbacks, or nil owner logs usually point to the host-app controller boundary or owner lookup setup.

Do not move host-app authentication, authorization, tenant, or locale policy into Rails Table Preferences to make the request pass. Keep those checks in the configured host controller, then verify the mounted API uses that boundary.

For the detailed setup checks, see [Save returns 401 or redirects to login](troubleshooting.md#save-returns-401-or-redirects-to-login), [Save, Load, or Delete uses the wrong controller boundary](troubleshooting.md#save-load-or-delete-uses-the-wrong-controller-boundary), [current_user is nil](troubleshooting.md#current_user-is-nil), and [Confirm the owner and engine contract](production_integration_checklist.md#1-confirm-the-owner-and-engine-contract).

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

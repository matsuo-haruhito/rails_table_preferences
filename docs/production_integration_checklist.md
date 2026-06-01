# Production integration checklist

Use this checklist after the quick start or demo screen is working and before wiring Rails Table Preferences into a real host-app index screen.

The goal is to choose the smallest production path, keep demo-only setup separate from host-app behavior, and leave search, authorization, exports, and presentation decisions with the host application.

## 1. Confirm the owner and engine contract

- Confirm `RailsTablePreferences.config.owner_model` matches the model that owns table preferences in the host app.
- Confirm `RailsTablePreferences.config.current_user_method` returns a persisted owner record for normal requests.
- Confirm `RailsTablePreferences.config.parent_controller_class_name` points to the host controller that should own the mounted JSON API boundary, such as `ApplicationController` or an authenticated base controller.
- Mount `RailsTablePreferences::Engine` when the screen uses the bundled JSON API.
- Confirm the mounted API routes inherit the expected host-app authentication, CSRF handling, locale/tenant setup, and other `before_action` callbacks from the configured parent controller.
- If the mount path is not `/rails_table_preferences`, keep `config.mount_path` aligned with the route.
- If shared, role, or organization presets are enabled, confirm `RailsTablePreferences.config.scope_context_method` is available from the parent controller and returns the identifiers those presets use.

See [Quick start](quick_start.md), [Install path options](install_paths.md), and [Mounted JSON API](json_api.md) for the generator, mount-path, and engine-boundary setup.

## 2. Choose the table rendering path

- For convention-first Active Record lists, start with `resource_table_for` and use profile overrides only where the inferred columns need adjustment.
- For tree-shaped records, use `tree_resource_table_for` only when the host app already has a stable parent id method.
- For existing shared table partials, keep the host-app table markup and add the Rails Table Preferences data attributes to managed `th` / `td` cells.
- Keep action links, badges, sensitive columns, and business-specific markup host-app-owned unless they are intentionally part of the managed column set.

See [Resource table adapters](resource_tables.md), [Table data attribute merge boundary](table_data_attributes.md), and [JavaScript controller notes](javascript_controller.md).

## 3. Preserve existing search and sort behavior

- Treat filter and sort settings as saved UI state, not as database query execution.
- Map `filter:` metadata to the host app's existing query params before changing controller search code.
- Use `rails_table_preference_params(...)` or `rails_table_preference_merged_params(...)` when the controller should merge saved filter/sort state into existing search params.
- Use `table_preferences_hidden_fields(...)` when a GET search form should carry saved filter/sort state without rewriting the form flow.
- For Ransack, Datagrid, Filterrific, or custom search objects, keep adapter logic in the host app and verify the generated params before saving a preset.

See [Controller integration](controller_integration.md), [Filter metadata](filter_metadata.md), and [Filter adapters](filter_adapters.md).

## 4. Decide whether exports should follow preferences

- If CSV, Excel, or report exports should mirror visible columns and order, resolve `rails_table_preference_export_payload(...)` in the export action.
- Keep file generation, authorization, joins, and business-specific formatting in the host app.
- Verify that hidden columns and ignored columns do not expose sensitive data through HTML or export paths.

See [Export integration](export_integration.md).

## 5. Add shared or scoped presets only when needed

- Owner presets work without extra scope setup.
- Configure `scope_context_method` only when the same screen needs shared, role, or organization presets.
- Keep shared, role, and organization preset administration in a host-app admin flow or a separate operating process.

See [Scoped presets](scoped_presets.md).

## 6. Run the quick host-app smoke

Before asking real users to try the screen, verify this path in the real host app:

1. Load the index screen as a normal signed-in owner.
2. Change visible columns, order, width, overflow, filter state, and sort state for one table.
3. Save the preset, reload the page, and confirm the same table state returns.
4. Submit the existing search form and confirm saved filter/sort state still round-trips.
5. If exports are enabled, export once and confirm column order and hidden columns match the selected preset.
6. Confirm unmanaged columns, action links, authorization, pagination, and empty states still behave like the host app expects.
7. Confirm the mounted JSON API is reachable only through the expected host-app authentication, CSRF, and `before_action` boundary.
8. Review keyboard focus, resize handles, sticky columns, and narrow viewport behavior on the production layout.

See [Manual QA checklist](manual_qa.md), [Troubleshooting](troubleshooting.md), and [Support matrix](support_matrix.md) for the broader verification path.

## Boundary reminders

Rails Table Preferences owns the editor UI, saved settings payload, preset API calls, managed-column data attributes, and helper-generated export payloads.

The mounted engine inherits `RailsTablePreferences.config.parent_controller_class_name`; the configured host controller is where authentication, CSRF handling, tenant or locale setup, and other request-wide callbacks should be checked.

The host app still owns authentication, authorization, query execution, joins, pagination, unmanaged columns, export file generation, and final screen styling.

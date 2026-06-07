# Production integration checklist

Use this checklist after the quick start or demo screen is working and before wiring Rails Table Preferences into a real host-app index screen.

The goal is to choose the smallest production path, keep demo-only setup separate from host-app behavior, and leave search, authorization, exports, and presentation decisions with the host application.

## 1. Confirm the owner and engine contract

- Confirm `RailsTablePreferences.config.owner_model` matches the model that owns table preferences in the host app.
- Confirm `RailsTablePreferences.config.current_user_method` returns a persisted owner record for normal requests.
- Confirm `RailsTablePreferences.config.parent_controller_class_name` points to the host controller that should own the mounted JSON API boundary, such as `ApplicationController` or an authenticated base controller.
- Mount `RailsTablePreferences::Engine` when the screen uses the bundled JSON API.
- Confirm the mounted API routes inherit the expected host-app authentication, CSRF handling, locale/tenant setup, and other `before_action` callbacks from the configured parent controller.
- Confirm the host-app layout or shell that renders the table includes Rails CSRF meta tags before relying on JSON save/delete requests.
- If the mount path is not `/rails_table_preferences`, keep `config.mount_path` aligned with the route.
- If shared, role, or organization presets are enabled, confirm `RailsTablePreferences.config.scope_context_method` is available from the parent controller and returns the identifiers those presets use.

See [Quick start](quick_start.md), [Install path options](install_paths.md), [Mounted JSON API](json_api.md), and [Production troubleshooting notes](production_troubleshooting.md) for the generator, mount-path, CSRF, and engine-boundary setup.

## 2. Choose the table rendering path

- For convention-first Active Record lists, start with `resource_table_for` and use profile overrides only where the inferred columns need adjustment.
- When using the default resource table partials, decide whether the table needs a short semantic `caption:`. Use it for a table name that helps distinguish the table surface; keep page headings, explanatory copy, and business-specific instructions in the host app around the generated table.
- When a resource table profile formatter reads associations, such as `order.customer`, preload those associations in the host-app relation before rendering; Rails Table Preferences does not infer `includes`, joins, or authorization scopes from formatter code.
- For tree-shaped records, use `tree_resource_table_for` only when the host app already has a stable parent id method.
- For existing shared table partials, keep the host-app table markup and add the Rails Table Preferences data attributes to managed `th` / `td` cells.
- Keep action links, badges, sensitive columns, and business-specific markup host-app-owned unless they are intentionally part of the managed column set.

See [Resource table adapters](resource_tables.md), [Accessibility baseline](accessibility.md#resource-table-captions), [Table data attribute merge boundary](table_data_attributes.md), and [JavaScript controller notes](javascript_controller.md).

## 3. Preserve existing search and sort behavior

- Treat filter and sort settings as saved UI state, not as database query execution.
- Keep the `table_key` stable for the logical screen or table template; do not derive it from pagination, search params, record ids, or per-render DOM ids.
- Map `filter:` metadata to the host app's existing query params before changing controller search code.
- Use `rails_table_preference_params(...)` or `rails_table_preference_merged_params(...)` when the controller should merge saved filter/sort state into existing search params.
- Use `table_preferences_hidden_fields(...)` when a GET search form should carry saved filter/sort state without rewriting the form flow.
- Decide in the host app whether a saved filter/sort change should clear, keep, or clamp the existing `page` param; Rails Table Preferences does not own pagination reset behavior.
- For Ransack, Datagrid, Filterrific, or custom search objects, keep adapter logic in the host app and verify the generated params before saving a preset.

See [Controller integration](controller_integration.md), [Filter metadata](filter_metadata.md), [Filter adapters](filter_adapters.md), and [Production troubleshooting notes](production_troubleshooting.md#saved-presets-do-not-come-back-on-the-same-screen).

## 4. Decide whether exports should follow preferences

- If CSV, Excel, or report exports should mirror visible columns and order, resolve `rails_table_preference_export_payload(...)` in the export action.
- Keep file generation, authorization, joins, and business-specific formatting in the host app.
- Verify that hidden columns and ignored columns do not expose sensitive data through HTML or export paths.

See [Export integration](export_integration.md).

## 5. Add shared or scoped presets only when needed

- Owner presets work without extra scope setup.
- Configure `scope_context_method` only when the same screen needs shared, role, or organization presets.
- Use the scoped presets minimal operating patterns before creating the first shared, role, or organization preset.
- Keep shared, role, and organization preset administration in a host-app admin flow or a separate operating process.
- Confirm the admin-created `scope_key` values match the identifiers returned by `scope_context_method`.
- Confirm normal users can read available non-owner presets while regular editor writes still create owner presets.

See [Scoped presets](scoped_presets.md) and its [minimal operating patterns](scoped_presets.md#minimal-operating-patterns).

## 6. Run the quick host-app smoke

Before asking real users to try the screen, verify this path in the real host app. Keep this as a short gate; use the [Manual QA checklist](manual_qa.md) for the detailed browser and accessibility pass.

1. Load the index screen as a normal signed-in owner.
2. Change visible columns, order, width, overflow, filter state, and sort state for one table.
3. Save the preset, reload the page, and confirm the same table state returns.
4. Trigger one Turbo Drive or Turbo Frame replacement that re-renders the editor and target table, then confirm both reconnect with the same `table_key`, `name`, `columns`, `settings`, collection/member URL values, and managed column keys so saved visibility/order/filter/sort state does not drift between the editor and table. When pagination or filtering paths are also used, repeat the reload through those paths and confirm the same stable `table_key` still resolves the preset.
5. Submit the existing search form and confirm saved filter/sort state still round-trips. If the screen can keep an old `page` param, repeat the same check from a later page and confirm the host app either clears, clamps, or intentionally preserves that page after saved filters/sorts change the result set.
6. If exports are enabled, export once and confirm column order and hidden columns match the selected preset.
7. If resource table profile formatters read associations, render representative rows while watching the host app's query log or existing N+1 guard and confirm the relation preloads those associations explicitly.
8. If `resource_table_for` or `tree_resource_table_for` uses `caption:`, confirm the caption is a short semantic table name and does not duplicate the page heading or surrounding instructions.
9. Confirm unmanaged columns, action links, authorization, pagination, and empty states still behave like the host app expects.
10. Confirm the mounted JSON API is reachable only through the expected host-app authentication, CSRF, and `before_action` boundary.
11. If shared, role, or organization presets are enabled, sign in as a representative owner and confirm the expected non-owner preset is visible, non-editable from the regular editor path, and resolved from the same `scope_key` value the host app created.
12. Check the dense table layout in the real production shell:
   - Move keyboard focus through editor controls, filter buttons, resize handles, sortable headers, sticky/fixed columns, and row actions.
   - Resize one managed column and confirm the handle remains visible and does not collide with header text, filter buttons, or sort indicators.
   - Horizontally scroll a table with sticky/fixed columns and confirm focused links, buttons, and inputs are not covered.
   - Use a narrow viewport or container with long labels/values and confirm editor controls, filter panels, and fixed columns stay readable and reachable.

See [Manual QA checklist](manual_qa.md), [Troubleshooting](troubleshooting.md), [Production troubleshooting notes](production_troubleshooting.md), and [Support matrix](support_matrix.md) for the broader verification path.

## 7. Separate upstream evidence from downstream adoption smoke

Use this checklist as upstream Rails Table Preferences evidence: packaged helpers, JavaScript entrypoints, generator output, mounted API contract, demo coverage, manual QA coverage, package verification, and focused docs are all signals that the gem surface is ready to evaluate in a host app.

A downstream host app still needs its own adoption evidence for each real table surface. Record the stable table key and column keys, filter and sort parameter mapping, preset save/load/delete behavior, mounted engine save path, export boundary when exports are enabled, and the rollback or pinned-gem target the host app will return to if the bump is not accepted.

For example, a downstream admin index such as `admin/document_sets` can be used as a representative smoke surface, but Rails Table Preferences should not make that app-specific route or schema part of its public contract. If the downstream known-good target, rollback target, or human release gate is not decided yet, keep the broad host-app bump paused and capture that as downstream evidence work rather than changing the gem API or this checklist.

### Downstream adoption evidence template

Use this short template in a downstream host-app bump PR, release note, or issue comment. Replace app-specific values with the real host-app evidence; do not copy private routes, schema details, or release gates into Rails Table Preferences docs as public contract.

```markdown
### Rails Table Preferences downstream adoption smoke

- Host app / surface:
- Gem version, branch, or SHA under evaluation:
- Stable table key:
- Stable managed column keys:
- Filter / sort parameter mapping checked:
- Preset path checked:
  - save:
  - reload/load:
  - delete, if applicable:
- Mounted engine save path and auth boundary checked:
- Export boundary checked, if exports are enabled:
- Layout / accessibility smoke checked:
- Known-good rollback target or pinned gem target:
- Human release gate / owner:
- Follow-up needed:
```

Keep the note short. The goal is to prove that the real host-app table can adopt this gem revision without mixing host-app-specific routes, schemas, or release policy into the gem's upstream release checklist.

## Boundary reminders

Rails Table Preferences owns the editor UI, saved settings payload, preset API calls, managed-column data attributes, and helper-generated export payloads.

The mounted engine inherits `RailsTablePreferences.config.parent_controller_class_name`; the configured host controller is where authentication, CSRF handling, tenant or locale setup, and other request-wide callbacks should be checked.

The host app still owns authentication, authorization, query execution, joins, pagination, unmanaged columns, export file generation, shared/role/organization preset administration, and final screen styling.

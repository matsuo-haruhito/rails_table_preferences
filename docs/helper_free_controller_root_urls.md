# Helper-free controller root URLs

Use this note when a host app keeps its own table partial and mounts `data-controller="rails-table-preferences"` manually instead of using `table_preferences_table_tag(...)`.

The helper-free DOM contract is still the same one described in [JavaScript controller notes](javascript_controller.md#manual-root-values-when-bypassing-the-table-helper): the controller root needs the current table key, preset name, columns, settings, collection URL, and member URL. This page focuses only on the URL values.

## URL responsibility

The manual root values must point at the mounted JSON API endpoint that serves the same logical table:

- `data-rails-table-preferences-collection-url-value` points to `/preferences/:table_key` under the mounted engine path.
- `data-rails-table-preferences-url-value` points to `/preferences/:table_key/:name` under the same mounted engine path.
- Both URLs should use the same `table_key` and preset `name` that the editor or preset selector is showing.

Rails Table Preferences does not add a helper-free-only URL helper. If the host app bypasses the table helper, the host app owns how those two strings are built.

## Default mount path example

The examples that use raw strings assume the default engine mount path:

```ruby
@table_preference_collection_url = "/rails_table_preferences/preferences/#{ERB::Util.url_encode(@table_key)}"
@table_preference_url = "#{@table_preference_collection_url}/#{ERB::Util.url_encode(@table_preference_name)}"
```

This is only a minimal default-path example. It is not a reason to hard-code `/rails_table_preferences` in an app that mounted the engine elsewhere.

## Custom mount path example

When the host app changes the engine mount path, build the manual root URLs from that mounted path or from a host-app route helper that returns the mounted preference endpoint.

For example, if the app mounts the engine at `/settings/table_preferences`, the manual root URLs should follow that same path:

```ruby
mounted_preferences_path = "/settings/table_preferences"
encoded_table_key = ERB::Util.url_encode(@table_key)
encoded_name = ERB::Util.url_encode(@table_preference_name)

@table_preference_collection_url = "#{mounted_preferences_path}/preferences/#{encoded_table_key}"
@table_preference_url = "#{@table_preference_collection_url}/#{encoded_name}"
```

Keep the route mount path and `RailsTablePreferences.config.mount_path` aligned. The bundled helpers build JSON API URLs from `config.mount_path`; manually rendered roots need to use the same mounted endpoint by construction.

## PR smoke

For helper-free controller root changes, record these checks in the PR body or comment:

- The editor and helper-free table root receive the same `table_key`, preset `name`, columns, and settings.
- The collection URL and member URL use the actual mounted engine path for the host app.
- The member URL URL-encodes the preset name and the collection URL URL-encodes the table key.
- Managed headers and body cells still expose matching `data-rails-table-preferences-column-key` values.
- Any mismatch with `config.mount_path` is handled as routing/troubleshooting work, not as a controller rewrite.

See [Mounted JSON API](json_api.md#route-shape) for the endpoint shape and [Troubleshooting](troubleshooting.md#helper-free-table-root-is-missing-required-data-values) for symptoms caused by stale manual root values.
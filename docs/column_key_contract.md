# Column key selector boundary

Rails Table Preferences uses each column's `key` to connect saved settings, editor rows, and table cells through `data-rails-table-preferences-column-key` attributes.

For the bundled Stimulus controller, prefer stable string keys that are safe to use as DOM attribute values and remain unchanged across releases. Common host-app keys such as `customer.name`, `customer:id`, `status]flag`, and keys containing quotes or backslashes are supported by modern browsers through `CSS.escape` before the controller builds its cell lookup selector.

When a host app runs in a browser-like environment without `CSS.escape`, the controller falls back to escaping quoted CSS attribute selector string delimiters. That fallback is intentionally narrow and is meant for already-stable host-app keys; avoid newline and control characters in column keys unless the target environment provides `CSS.escape` or the host app supplies its own controller override.

This boundary keeps column key handling predictable without changing the saved settings schema, migrating existing preferences, or introducing a new public key normalization contract.

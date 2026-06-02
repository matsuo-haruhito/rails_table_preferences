# Scoped preset selector

The bundled preset selector can list owner, shared, role, and organization presets for the same table. When more than one available preset has the same `name`, the option label includes the non-owner scope label, and the selector keeps the selected option's scope metadata with the load request.

For example, if these presets are available for `orders`:

| Name | Scope type | Scope key | Selector label |
| --- | --- | --- | --- |
| `default` | `owner` | blank | `default` |
| `default` | `role` | `admin` | `default [role]` |
| `default` | `organization` | `tokyo` | `default [organization]` |

Selecting the role option loads the same name with explicit scope params:

```text
GET /rails_table_preferences/preferences/orders/default?scope_type=role&scope_key=admin
```

Name-only requests still use the existing resolver priority. That keeps existing host-app links and API calls backward compatible:

```text
GET /rails_table_preferences/preferences/orders/default
```

Host applications can still avoid same-name scoped presets by using descriptive names such as `operations-default`, `tokyo-default`, or `shared-baseline`. When a host app intentionally reuses a name across scopes, the bundled selector uses the option's `scope_type` and `scope_key` metadata so the user's selected scope is preserved.

## Boundaries

- The selector does not change default resolution priority.
- The selector does not add scoped preset admin UI.
- The selector does not change preset uniqueness validation or database schema.
- Shared, role, and organization presets remain read-only in the regular bundled editor path.

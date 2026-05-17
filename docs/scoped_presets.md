# Scoped presets

Rails Table Preferences supports owner, shared, role, and organization scoped presets.

The feature is intended for applications that want one or more default table layouts to be provided by the application, an administrator, a role, or an organization, while still allowing each user to save personal overrides.

## Scope types

| Scope type | Meaning | Owner foreign key | Scope key |
| --- | --- | --- | --- |
| `owner` | A personal preset for the current owner, usually the current user. | Required | Empty |
| `shared` | A global preset available to all owners. | Empty | Empty |
| `role` | A preset available to owners whose scope context includes the role. | Empty | Required |
| `organization` | A preset available to owners whose scope context includes the organization. | Empty | Required |

The generated migration includes:

```ruby
t.references :user, null: true
t.string :scope_type, null: false, default: "owner"
t.string :scope_key
```

The owner reference is nullable because shared, role, and organization presets are not owned by a single user.

## Scope context

Configure a method that returns the current scope context:

```ruby
RailsTablePreferences.configure do |config|
  config.scope_context_method = :table_preference_scope_context
end
```

Then define the method in the parent controller:

```ruby
class ApplicationController < ActionController::Base
  private

  def table_preference_scope_context
    {
      roles: current_user.roles.pluck(:key),
      organization: current_user.organization_id
    }
  end
end
```

The method may be public or private. If no method is configured, the context is empty.

## Default resolution order

When no preset name is explicitly requested, Rails Table Preferences resolves defaults in this order:

1. Owner default
2. Role default
3. Organization default
4. Shared default
5. Owner preset named `default`
6. Empty normalized settings

This lets an application provide a shared baseline while allowing users to override it by saving their own default preset.

## Named preset resolution

When a preset name is requested, Rails Table Preferences looks for available presets with that name using the same availability rules.

Available presets are:

- presets owned by the current owner
- shared presets
- role presets matching the configured role context
- organization presets matching the configured organization context

## API parameters

Normal personal presets do not need any extra parameters:

```json
{
  "name": "default",
  "settings": { "columns": [] }
}
```

Create a shared preset:

```json
{
  "name": "team-default",
  "scope_type": "shared",
  "settings": { "columns": [] }
}
```

Create a role preset:

```json
{
  "name": "inspection",
  "scope_type": "role",
  "scope_key": "admin",
  "settings": { "columns": [] }
}
```

Create an organization preset:

```json
{
  "name": "tokyo-default",
  "scope_type": "organization",
  "scope_key": "tokyo",
  "settings": { "columns": [] }
}
```

## API response fields

Preference responses include scope metadata:

```json
{
  "table_key": "orders",
  "name": "team-default",
  "default": true,
  "scope_type": "shared",
  "scope_key": "",
  "scope_label": "shared",
  "editable": false,
  "settings": { "columns": [], "filters": {}, "sorts": [] }
}
```

`editable` is `true` for owner presets that belong to the current owner. Shared, role, and organization presets are returned as non-editable from the normal user-facing editor path.

## Recommended UI behavior

For user-facing screens:

- users may select shared, role, or organization presets
- users should save personal changes as owner presets
- non-owner presets should not be overwritten from the regular editor
- host applications may provide a separate admin screen for managing shared, role, or organization presets

## Authorization boundary

Rails Table Preferences stores and resolves scoped presets. It does not decide who is allowed to create or edit organization-wide presets in your business application.

If an application exposes shared, role, or organization preset management to administrators, it should enforce authorization in the host application or a custom controller layer.

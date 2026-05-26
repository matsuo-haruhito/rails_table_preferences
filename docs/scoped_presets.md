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

Role and organization preset matching is string-based. Use the same stable identifiers in `scope_key` that the configured scope context method returns.

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

## Minimal operating patterns

The following patterns keep the bundled editor simple while still giving the host application a clear place to manage non-owner presets.

### 1. Seed a shared baseline

A seed task, migration, or one-off setup script can bootstrap one shared default per table by storing the same payload shape that the JSON API accepts:

```ruby
shared_default_payload = {
  name: "operations-default",
  default: true,
  scope_type: "shared",
  settings: {
    columns: [],
    filters: {},
    sorts: []
  }
}
```

Use that payload when the host app creates the generated preference record or when it calls the same host-app path that administrators use for shared presets. The important part is that the record is stored as `scope_type: "shared"` and marked `default: true` only when it should win before owner presets exist.

### 2. Give administrators a separate write path

Regular end users should still save personal presets from the bundled editor. Shared, role, and organization presets work better when the host app exposes an explicit admin form, service object, or maintenance script that sets `scope_type` and, when needed, `scope_key`.

A minimal strong-parameters shape looks like this:

```ruby
params.require(:preset).permit(
  :table_key,
  :name,
  :default,
  :scope_type,
  :scope_key,
  settings: {}
)
```

Typical `scope_key` values are stable business identifiers such as role keys (`"admin"`) or organization IDs/slugs (`"tokyo"`). The host app remains responsible for deciding who may create or update each key.

A copyable host-app controller/service split can stay close to the repository's current controller and model contract:

```ruby
class Admin::TablePreferencePresetsController < ApplicationController
  def create
    preset = ScopedPresetUpserter.call(preset_params)

    redirect_to admin_table_preference_presets_path,
                notice: "Preset saved: #{preset.name}"
  end

  def update
    preset = ScopedPresetUpserter.call(preset_params)

    redirect_to admin_table_preference_presets_path,
                notice: "Preset updated: #{preset.name}"
  end

  private

  def preset_params
    params.require(:preset).permit(
      :table_key,
      :name,
      :default,
      :scope_type,
      :scope_key,
      settings: {}
    )
  end
end
```

```ruby
class ScopedPresetUpserter
  def self.call(attrs)
    scope_type = attrs.fetch(:scope_type)
    scope_key = attrs[:scope_key].presence

    preference = RailsTablePreferences::Preference.find_or_initialize_for(
      user: nil,
      table_key: attrs.fetch(:table_key),
      name: attrs[:name].presence || "default",
      scope_type: scope_type,
      scope_key: scope_key
    )

    preference.user = nil
    preference.scope_type = scope_type
    preference.scope_key = scope_key
    preference.settings = RailsTablePreferences::SettingsNormalizer.call(attrs[:settings] || {})
    preference.default_flag = ActiveModel::Type::Boolean.new.cast(attrs[:default])

    if preference.default_flag?
      RailsTablePreferences::Preference.for_scope(preference.scope_type, preference.scope_key)
                                     .where(RailsTablePreferences.configuration.user_foreign_key => nil)
                                     .for_table(preference.table_key)
                                     .where.not(id: preference.id)
                                     .update_all(default_flag: false)
    end

    preference.save!
    preference
  end
end
```

Why this shape works:

- `user: nil` matches the current model/controller contract for shared, role, and organization presets.
- `scope_type` and `scope_key` stay explicit instead of relying on hidden controller state.
- `RailsTablePreferences::SettingsNormalizer.call(...)` keeps admin-created payloads aligned with the same normalized `columns` / `filters` / `sorts` shape used by the bundled JSON API.
- `default_flag` clearing stays per table + scope so only one default wins inside the same scope bucket.

If your host app prefers to manage presets through the mounted JSON API instead of direct model writes, use the same parameter shape shown above. The important part is to keep the stored `scope_type`, `scope_key`, and normalized `settings` consistent.

### 3. Split the regular editor and the admin flow on purpose

| Surface | Who uses it | What it should save |
| --- | --- | --- |
| Bundled editor | Normal end users | Owner presets only |
| Admin form or seed path | Administrators, setup tasks, support scripts | Shared, role, and organization presets |
| Resolver path | Every request | Whatever presets are available from owner + scope context |

A practical rule of thumb is: let users read every available preset, but only let the regular editor write owner presets. Put shared, role, and organization writes behind an app-specific admin flow.

### 4. Keep `scope_context_method` and admin inputs aligned

The `scope_context_method` decides which non-owner presets are available for the current request. If the method returns role keys and an organization identifier, the admin flow should store those same kinds of values in `scope_key`.

A concrete alignment example looks like this:

```ruby
class ApplicationController < ActionController::Base
  private

  def table_preference_scope_context
    {
      roles: current_user.roles.pluck(:key),
      organization: current_organization.slug
    }
  end
end
```

| Use case | `scope_type` | `scope_key` stored by admin flow | Resolver input that makes it available |
| --- | --- | --- | --- |
| Shared baseline for everyone | `shared` | blank | none |
| Operations role preset | `role` | `operations` | `roles: ["operations", ...]` |
| Tokyo organization preset | `organization` | `tokyo-hq` | `organization: "tokyo-hq"` |

That keeps three things consistent:

- the seed/default data you create up front
- the admin UI or service object that edits scoped presets later
- the runtime resolver that decides which scoped presets the current owner can use

If your runtime context returns numeric IDs, UUIDs, or tenant slugs, store that same stable value in `scope_key`. Avoid saving human-facing labels such as `Operations Team` unless the resolver also returns that exact label.

## Authorization boundary

Rails Table Preferences stores and resolves scoped presets. It does not decide who is allowed to create or edit organization-wide presets in your business application.

If an application exposes shared, role, or organization preset management to administrators, it should enforce authorization in the host application or a custom controller layer.
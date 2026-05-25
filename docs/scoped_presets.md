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
  :name,
  :default,
  :scope_type,
  :scope_key,
  settings: {}
)
```

Typical `scope_key` values are stable business identifiers such as role keys (`"admin"`) or organization IDs/slugs (`"tokyo"`). The host app remains responsible for deciding who may create or update each key.

### Copyable admin controller flow

If the host app wants a small admin-only endpoint for shared, role, or organization presets, the current model/controller contracts are enough. The important part is that non-owner writes use `user: nil`, while the payload is normalized through `RailsTablePreferences::SettingsNormalizer`.

```ruby
class Admin::TablePresetTemplatesController < Admin::BaseController
  before_action :require_table_preset_admin!

  def create
    preset = build_scoped_preset
    clear_other_defaults(preset) if preset.default_flag?
    preset.save!

    redirect_to admin_table_preset_templates_path, notice: "Preset saved"
  end

  def update
    preset = build_scoped_preset
    clear_other_defaults(preset) if preset.default_flag?
    preset.save!

    redirect_to admin_table_preset_templates_path, notice: "Preset updated"
  end

  private

  def build_scoped_preset
    preset = RailsTablePreferences::Preference.find_or_initialize_for(
      user: nil,
      table_key: preset_payload[:table_key],
      name: preset_payload[:name],
      scope_type: preset_payload[:scope_type],
      scope_key: preset_payload[:scope_key]
    )

    preset.user = nil
    preset.scope_type = preset_payload[:scope_type]
    preset.scope_key = preset_payload[:scope_key]
    preset.default_flag = ActiveModel::Type::Boolean.new.cast(preset_payload[:default])
    preset.settings = RailsTablePreferences::SettingsNormalizer.call(preset_payload[:settings])
    preset
  end

  def preset_payload
    raw = params.require(:preset)

    {
      table_key: raw[:table_key].to_s,
      name: raw[:name].presence || "default",
      scope_type: raw[:scope_type].presence || RailsTablePreferences::Preference::SHARED_SCOPE_TYPE,
      scope_key: raw[:scope_key].presence,
      default: raw[:default],
      settings: raw[:settings].respond_to?(:to_unsafe_h) ? raw[:settings].to_unsafe_h : raw[:settings] || {}
    }
  end

  def clear_other_defaults(preset)
    RailsTablePreferences::Preference
      .for_scope(preset.scope_type, preset.scope_key)
      .where(user: nil)
      .for_table(preset.table_key)
      .where.not(id: preset.id)
      .update_all(default_flag: false)
  end
end
```

This keeps the bundled `/preferences/...` JSON API focused on the regular editor flow while giving the host app a narrow place to enforce admin-only authorization, audit logging, or tenant-specific rules.

### 3. Split the regular editor and the admin flow on purpose

| Surface | Who uses it | What it should save |
| --- | --- | --- |
| Bundled editor | Normal end users | Owner presets only |
| Admin form or seed path | Administrators, setup tasks, support scripts | Shared, role, and organization presets |
| Resolver path | Every request | Whatever presets are available from owner + scope context |

A practical rule of thumb is: let users read every available preset, but only let the regular editor write owner presets. Put shared, role, and organization writes behind an app-specific admin flow.

### 4. Keep `scope_context_method` and admin inputs aligned

The `scope_context_method` decides which non-owner presets are available for the current request. If the method returns role keys and an organization ID, the admin flow should store those same kinds of values in `scope_key`.

That keeps three things consistent:

- the seed/default data you create up front
- the admin UI or service object that edits scoped presets later
- the runtime resolver that decides which scoped presets the current owner can use

A simple alignment table helps avoid drift:

| Runtime source | Example returned value | Stored `scope_type` | Stored `scope_key` |
| --- | --- | --- | --- |
| `current_user.roles.pluck(:key)` | `"operations"` | `role` | `"operations"` |
| `current_user.organization.slug` | `"tokyo"` | `organization` | `"tokyo"` |

For example, if the runtime context is:

```ruby
def table_preference_scope_context
  {
    roles: current_user.roles.pluck(:key),
    organization: current_user.organization.slug
  }
end
```

then the admin write path should store matching values:

```ruby
{ scope_type: "role", scope_key: "operations" }
{ scope_type: "organization", scope_key: "tokyo" }
```

## Authorization boundary

Rails Table Preferences stores and resolves scoped presets. It does not decide who is allowed to create or edit organization-wide presets in your business application.

If an application exposes shared, role, or organization preset management to administrators, it should enforce authorization in the host application or a custom controller layer.

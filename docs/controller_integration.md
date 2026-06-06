# Controller integration

Rails Table Preferences provides controller helpers for host applications that want to apply saved filter and sort preferences to existing list actions.

The helpers do not execute searches. They resolve saved preferences and convert saved filter/sort settings into params that can be passed to the host application's existing search layer. They can also return an ordered export payload for CSV, Excel, or report code that the host application owns.

## Helpers

The engine includes `RailsTablePreferences::Controller` into `ActionController::Base`.

Available controller helpers:

```ruby
rails_table_preference(table_key:, name: nil, owner: nil, scope_context: nil)
rails_table_preference_settings(table_key:, name: nil, owner: nil, scope_context: nil, fallback: {})
rails_table_preference_params(table_key:, columns:, name: nil, owner: nil, scope_context: nil, adapter: :controller_params, sort_param: "sort")
rails_table_preference_export_payload(table_key:, columns:, name: nil, owner: nil, scope_context: nil, include_hidden: false, fallback: {})
rails_table_preference_merged_params(params_source = params, **options)
```

Available view helpers:

```ruby
table_preferences_params(settings:, columns:, ignored_columns: [], adapter: :controller_params, sort_param: "sort")
table_preferences_hidden_fields(settings:, columns:, ignored_columns: [], adapter: :controller_params, sort_param: "sort", namespace: nil)
```

## Preference resolution

When `name:` is provided:

1. Use the preset with that name.
2. Return `nil` when it does not exist.

When `name:` is omitted:

1. Use the preset with `default_flag = true`.
2. If there is no default preset, use the preset named `default`.
3. If neither exists, return `nil` or normalized fallback settings.

When shared, role, or organization presets are enabled, the controller helpers resolve available presets using the current scope context. By default that context comes from `RailsTablePreferences.configuration.scope_context_method`. Pass `scope_context:` only when an action needs to resolve preferences for a different request context than the configured method would return.

See [Scoped presets](scoped_presets.md) for scope types, resolution priority, and admin-maintenance patterns.

## Existing search(params) / order_by(params[:sort]) controllers

Many Rails applications already use a pattern like this:

```ruby
@warehouse_stocks = WarehouseStock
  .search(params)
  .order_by(params[:sort])
```

For this style, use the default `:controller_params` adapter.

```ruby
class WarehouseStocksController < ApplicationController
  def index
    columns = [
      table_preferences_column(
        :customer_name,
        filter: { type: :text, param: :search_word }
      ),
      table_preferences_column(
        :status,
        filter: { type: :select, values_param: :statuses }
      ),
      table_preferences_column(
        :delivery_date,
        filter: { type: :date, from_param: :from_date, to_param: :to_date },
        sortable: true
      )
    ]

    preference_params = rails_table_preference_params(
      table_key: :warehouse_stocks,
      name: params[:table_preference_name],
      columns: columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @warehouse_stocks = WarehouseStock
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
  end
end
```

Example output from `rails_table_preference_params`:

```ruby
{
  "search_word" => "山田",
  "statuses" => ["未出荷", "出荷済"],
  "from_date" => "2026-01-01",
  "to_date" => "2026-01-31",
  "sort" => "-delivery_date"
}
```

Descending sorts are prefixed with `-`. Ascending sorts use the key as-is.

Use `sort_param:` when the controller expects a different top-level sort param name:

```ruby
preference_params = rails_table_preference_params(
  table_key: :warehouse_stocks,
  columns: columns,
  sort_param: :order
)
```

## Hidden fields for existing search forms

Use `table_preferences_hidden_fields` when a normal search form should submit saved preference filters/sorts alongside user-entered search params.

```erb
<%= form_with url: warehouse_stocks_path, method: :get do %>
  <%= text_field_tag :search_word, params[:search_word] %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: columns
  ) %>

  <%= submit_tag "Search" %>
<% end %>
```

This renders ordinary hidden fields:

```html
<input type="hidden" name="search_word" value="山田">
<input type="hidden" name="statuses[]" value="未出荷">
<input type="hidden" name="statuses[]" value="出荷済">
<input type="hidden" name="sort" value="-delivery_date">
```

Saved boolean values are preserved as values. For example, a saved filter value of `false` renders as a hidden field value of `false`, including when it appears inside an array value. `nil`, empty strings, and blank array items are still omitted so a saved preference does not submit empty search params.

Use `namespace:` for nested params such as Ransack's `q`:

```erb
<%= table_preferences_hidden_fields(
  settings: @table_preference_settings,
  columns: columns,
  adapter: :ransack,
  namespace: :q
) %>
```

Example output:

```html
<input type="hidden" name="q[customer_name_cont]" value="山田">
<input type="hidden" name="q[s][]" value="delivery_date desc">
```

`table_preferences_params` returns the same converted params as a Ruby hash when hidden fields are not needed.

## Merging helper

Use `rails_table_preference_merged_params` when the action simply needs a params-like hash with saved preference params overlaid:

```ruby
merged_params = rails_table_preference_merged_params(
  table_key: :warehouse_stocks,
  columns: columns
)

@warehouse_stocks = WarehouseStock
  .search(merged_params)
  .order_by(merged_params["sort"] || params[:sort])
```

Saved preference params override existing params when keys overlap.

## Pagination and page params

Rails Table Preferences does not decide when a paginated list should reset to the first page. If a saved filter or sort changes the effective result set while the request still carries an old `page` param, the host application's paginator can legitimately render an empty page even though matching records exist on earlier pages.

Keep that decision in the host app's search flow. Common patterns are to clear `page` when the user submits a new search form, to clear it when `table_preference_name` changes, or to clamp an out-of-range page in the controller after the query runs. Do not rely on `rails_table_preference_params(...)`, `rails_table_preference_merged_params(...)`, or `table_preferences_hidden_fields(...)` to rewrite pagination params for every application.

When the form should keep the current page, submit `page` explicitly as part of the normal host-app form. When applying a saved preset should restart the result list, omit or clear `page` before calling the host application's search and pagination code.

## Ransack controllers

Use `adapter: :ransack` when the host application already uses Ransack:

```ruby
ransack_params = rails_table_preference_params(
  table_key: :orders,
  columns: columns,
  adapter: :ransack
)

@q = Order.ransack(params.fetch(:q, {}).to_unsafe_h.merge(ransack_params))
@orders = @q.result
```

## Explicit owner

By default, the helpers use:

```ruby
public_send(RailsTablePreferences.configuration.current_user_method)
```

Pass `owner:` when applying preferences for a different owner object:

```ruby
preference_params = rails_table_preference_params(
  table_key: :orders,
  owner: current_customer,
  columns: columns
)
```

## Explicit scope context

By default, role and organization preset availability comes from the configured scope context method:

```ruby
RailsTablePreferences.configure do |config|
  config.scope_context_method = :table_preference_scope_context
end
```

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

That is usually the right path for normal list actions because every helper call resolves presets for the same current request.

Pass `scope_context:` when a controller action intentionally needs a different context. For example, an admin preview can resolve the same table for a selected role without changing the current signed-in user:

```ruby
class Admin::WarehouseStockPreviewsController < ApplicationController
  def show
    columns = warehouse_stock_columns
    preview_scope_context = { roles: [params.require(:role_key)] }

    preference_params = rails_table_preference_params(
      table_key: :warehouse_stocks,
      name: params[:table_preference_name],
      columns: columns,
      scope_context: preview_scope_context
    )

    export_payload = rails_table_preference_export_payload(
      table_key: :warehouse_stocks,
      columns: columns,
      scope_context: preview_scope_context
    )

    @warehouse_stocks = WarehouseStock.search(params.to_unsafe_h.merge(preference_params))
    @export_columns = export_payload["columns"]
  end
end
```

Keep the values in `scope_context:` aligned with the `scope_key` values stored for role or organization presets. Rails Table Preferences resolves and normalizes the matching preset, but the host application still decides who may preview, create, update, or export data for that context.

## Responsibility boundary

Rails Table Preferences is responsible for:

- resolving the saved preference
- normalizing settings
- converting saved filter/sort settings to params
- returning an ordered export payload from saved display settings
- rendering optional hidden fields for existing forms

The host application remains responsible for:

- applying params to `ActiveRecord::Relation`
- authorization
- joins and associations
- validating searchable fields
- business-specific search behavior
- deciding whether saved filter/sort changes should clear or clamp pagination params
- CSV, Excel, or report file generation
- admin UI and permission checks for shared, role, or organization presets

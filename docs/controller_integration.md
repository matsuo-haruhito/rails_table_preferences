# Controller integration

Rails Table Preferences provides controller helpers for host applications that want to apply saved filter and sort preferences to existing list actions.

The helpers do not execute searches. They resolve saved preferences and convert saved filter/sort settings into params that can be passed to the host application's existing search layer.

## Helpers

The engine includes `RailsTablePreferences::Controller` into `ActionController::Base`.

Available helpers:

```ruby
rails_table_preference(table_key:, name: nil, owner: nil)
rails_table_preference_settings(table_key:, name: nil, owner: nil, fallback: {})
rails_table_preference_params(table_key:, columns:, name: nil, owner: nil, adapter: :controller_params, sort_param: "sort")
rails_table_preference_merged_params(params_source = params, **options)
```

## Preference resolution

When `name:` is provided:

1. Use the preset with that name.
2. Return `nil` when it does not exist.

When `name:` is omitted:

1. Use the preset with `default_flag = true`.
2. If there is no default preset, use the preset named `default`.
3. If neither exists, return `nil` or normalized fallback settings.

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

## Responsibility boundary

Rails Table Preferences is responsible for:

- resolving the saved preference
- normalizing settings
- converting saved filter/sort settings to params

The host application remains responsible for:

- applying params to `ActiveRecord::Relation`
- authorization
- joins and associations
- validating searchable fields
- business-specific search behavior

# Rails Table Preferences

Rails Table Preferences is a Rails engine/gem for saving and restoring user-specific table display preferences in Rails applications.

It is designed for business applications with many index tables, where users need to customize visible columns, column order, column width, and text truncation per table.

## Goals

- Save table display preferences per user
- Support column visibility, order, width, and truncation
- Provide Rails helpers and Stimulus controllers
- Keep compatibility with existing `ColumnAdjustment`-style implementations
- Start small and allow future support for Excel-like filters and saved sorts

## Supported versions

Rails Table Preferences targets Rails 7.0 and later.

Primary support is planned for:

- Rails 7.1
- Rails 7.2
- Rails 8.0
- Rails 8.1

Rails 7.0 is expected to work, but Rails 7.1+ is recommended.

Ruby 3.1+ is required.

## Initial scope

The first version focuses on extracting and generalizing the `ColumnAdjustment`-style table display settings used in existing Rails applications.

Included in the initial scope:

- Table-specific display settings
- User-specific preference persistence
- Column visibility
- Column order
- Column width
- Text truncation metadata
- Rails engine structure
- View helpers
- Stimulus controllers
- Install generator
- Migration generator
- Compatibility path for existing JSON column-adjustment values

## Out of scope for the first version

The following features are intentionally left for later versions:

- Excel-like column filters
- Complex query generation
- Saved search conditions
- Saved sort conditions
- CSV export integration
- Pagination abstraction
- DataTables-like full grid replacement
- React or Vue components
- Shared administrator presets
- Tenant-wide default views
- Application-specific permission logic

## Planned roadmap

### v0.1: Column display preferences

- Column visibility, order, width, and truncation
- User-specific persistence
- Rails helpers and Stimulus integration
- Migration and install generators
- Existing `ColumnAdjustment` compatibility guidance

### v0.2: Presets and preference management

- Multiple presets per table
- Default preset
- Duplicate, delete, and reset actions
- Clearer user/table/preset data model

### v0.3: Excel-like filters

- Column filter UI
- Text, number, date, boolean, blank, and non-blank filters
- Saved filter conditions
- Normalized filter params for Rails controllers

### v0.4 and later

- Shared presets
- Role or organization defaults
- Fixed columns
- Column groups
- Export integration
- Accessibility improvements

## Data model direction

The preferred long-term model is a user-specific table preference record:

```ruby
create_table :table_preferences do |t|
  t.references :user, null: false, foreign_key: true
  t.string :table_key, null: false
  t.string :name, null: false, default: "default"
  t.json :settings, null: false
  t.boolean :default_flag, null: false, default: false
  t.timestamps
end

add_index :table_preferences, [:user_id, :table_key, :name], unique: true
```

The settings payload is expected to evolve from column display preferences to include filters and sorts:

```json
{
  "columns": [
    {
      "key": "customer_code",
      "visible": true,
      "order": 10,
      "width": 120,
      "truncate": 20,
      "pinned": false
    }
  ],
  "filters": {},
  "sorts": []
}
```

## Usage direction

The final API should keep application code small and explicit.

Controller-side DSL example:

```ruby
class OrdersController < ApplicationController
  table_preferences_for :orders do
    column :order_no, label: "Order No.", default_width: 120
    column :customer_code, label: "Customer Code", default_width: 120
    column :customer_name, label: "Customer Name", default_width: 240, truncate: 30
    column :created_at, label: "Created At", default_width: 160
  end
end
```

View-side direction:

```erb
<%= table_preferences_toolbar(:orders) %>

<table data-controller="rails-table-preferences" data-table-key="orders">
  ...
</table>
```

## Development status

This gem is in the initial planning and skeleton stage.

## License

MIT License.

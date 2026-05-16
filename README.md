# Rails Table Preferences

Rails Table Preferences is a Rails engine/gem for saving and restoring user-specific table display preferences in Rails applications.

It is designed for business applications with many index tables, where users need to customize visible columns, column order, column width, and text truncation per table.

## Goals

- Save table display preferences per owner model, usually a user
- Support column visibility, order, width, and truncation
- Provide Rails helpers and Stimulus controllers
- Keep compatibility with existing `ColumnAdjustment`-style implementations
- Allow host applications to customize ERB, CSS, JavaScript, and locales
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

## Installation direction

Rails Table Preferences stores table preferences in the host application's primary database using a normal Rails migration.

It does not use a separate schema file such as `db/queue_schema.rb`. The preference records are application data linked to an owner model, not infrastructure data like a job queue.

Planned installation flow:

```bash
bin/rails generate rails_table_preferences:install
bin/rails db:migrate
```

The generator copies a regular migration into the host application's `db/migrate` directory so the table appears in the application's normal `schema.rb` or `structure.sql`. It also creates `config/initializers/rails_table_preferences.rb`.

If preferences should belong to a model other than `User`, pass an owner model. The value can be singular or plural:

```bash
bin/rails generate rails_table_preferences:install --owner-model customers
bin/rails generate rails_table_preferences:install --owner-model client
```

`customers` generates `Customer` / `customer_id`; `client` generates `Client` / `client_id`. Override the generated foreign key only when needed:

```bash
bin/rails generate rails_table_preferences:install --owner-model customers --owner-foreign-key member_id
```

Mount the engine when using the bundled JSON API:

```ruby
# config/routes.rb
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
```

## Initial scope

The first version focuses on extracting and generalizing the `ColumnAdjustment`-style table display settings used in existing Rails applications.

Included in the initial scope:

- Table-specific display settings
- Owner-specific preference persistence
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
- Owner-specific persistence
- Rails helpers and Stimulus integration
- Migration and install generators
- Existing `ColumnAdjustment` compatibility guidance

### v0.2: Presets and preference management

- Multiple presets per table
- Default preset
- Duplicate, delete, and reset actions
- Clearer owner/table/preset data model

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

The preferred long-term model is an owner-specific table preference record. By default the owner model is `User`, but it can be changed to `Customer`, `Client`, `Account`, or another application model.

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

With `--owner-model customers`, the generated migration uses `customer_id` instead of `user_id`:

```ruby
create_table :table_preferences do |t|
  t.references :customer, null: false, foreign_key: true
  # ...
end

add_index :table_preferences, [:customer_id, :table_key, :name], unique: true
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

Existing `ColumnAdjustment` style keys are accepted by the normalizer:

```json
{
  "columns": [
    {
      "column_name": "customer_code",
      "display_flag": true,
      "display_order": 10,
      "width": 120
    }
  ]
}
```

## Configuration

Default configuration:

```ruby
RailsTablePreferences.configure do |config|
  config.table_name = "table_preferences"
  config.owner_model = :users
  config.parent_controller_class_name = "ApplicationController"
  config.current_user_method = :current_user
  config.mount_path = "/rails_table_preferences"
  config.editor_partial = "rails_table_preferences/editor"
end
```

`owner_model` accepts a `String` or `Symbol`, singular or plural:

```ruby
config.owner_model = :customers # Customer / customer_id
config.owner_model = "clients"  # Client / client_id
config.owner_model = :account   # Account / account_id
```

Backward-compatible aliases are available:

```ruby
config.user_class_name = "User"
config.user_model = :users
config.account_model = :accounts
```

Override the foreign key only when the default is not correct:

```ruby
config.owner_foreign_key = :member_id
# Backward-compatible alias:
config.user_foreign_key = :member_id
```

The first implementation assumes a primary application database. Applications with different owner model names can configure the owner model and foreign key before using the model. If the engine is mounted at a different path, set `mount_path` to the same value.

## Column labels and host app locales

Column labels are resolved in this order:

1. Explicit `label:`
2. Explicit `i18n_key:`
3. `activerecord.attributes.<model_name>.<column>`
4. `activemodel.attributes.<model_name>.<column>`
5. `attributes.<column>`
6. `column.to_s.humanize`

Examples:

```ruby
columns = [
  table_preferences_column(:customer_code, model_name: :order),
  table_preferences_column(:customer_name, model: Order),
  table_preferences_column(:delivery_date, i18n_key: "orders.index.columns.delivery_date"),
  table_preferences_column(:memo, label: "備考")
]
```

Host app locale example:

```yaml
ja:
  activerecord:
    attributes:
      order:
        customer_code: 得意先コード
        customer_name: 得意先名
  orders:
    index:
      columns:
        delivery_date: 納品日
```

## Ignored columns

Use ignored columns for fields that should not appear in the user-facing column editor, even if the table or saved settings contain them.

Per-column form:

```ruby
columns = [
  table_preferences_column(:customer_code, model_name: :order),
  table_preferences_column(:internal_cost, model_name: :order, ignored: true),
  table_preferences_column(:secret_note, model_name: :order, ignore: true)
]
```

Blacklist form:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: columns,
  ignored_columns: [:internal_cost, :secret_note]
) %>

<%= table_preferences_table_tag(
  table_key: :orders,
  columns: columns,
  ignored_columns: [:internal_cost, :secret_note],
  class: "table"
) do %>
  ...
<% end %>
```

Ignored columns are removed from `columns_json` and are also filtered out of the initial `settings_json`. This prevents an old saved preference from reintroducing a column that the host application has since hidden from users.

This is a UI/display protection mechanism. Sensitive values should still be protected by normal authorization, query selection, and view rendering rules in the host application.

## Host app customization

### ERB

The editor is rendered through a partial. By default:

```ruby
config.editor_partial = "rails_table_preferences/editor"
```

To customize the markup, copy the default partial into the host application:

```bash
bin/rails generate rails_table_preferences:views
```

Then edit:

```text
app/views/rails_table_preferences/_editor.html.erb
```

You can also provide a custom partial per call:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: columns,
  partial: "shared/table_preferences_editor"
) %>
```

The partial receives these locals:

```text
table_key, name, title, settings, columns, settings_json, columns_json,
preference_url, collection_url, data_attributes
```

### CSS

The gem intentionally keeps styling minimal. Host applications can style the emitted classes directly:

```text
rails-table-preferences-editor
rails-table-preferences-editor__title
rails-table-preferences-editor__preset
rails-table-preferences-editor__default-preset
rails-table-preferences-editor__rows
rails-table-preferences-editor__actions
rails-table-preferences-editor__row
rails-table-preferences-editor__drag-handle
rails-table-preferences-resize-handle
```

### JavaScript

The bundled Stimulus controller uses stable data attributes and class hooks. Host applications can either use the bundled controller or register their own controller that reads the same data attributes:

```text
data-rails-table-preferences-table-key-value
data-rails-table-preferences-name-value
data-rails-table-preferences-url-value
data-rails-table-preferences-collection-url-value
data-rails-table-preferences-settings-value
data-rails-table-preferences-columns-value
data-rails-table-preferences-column-key
```

## Current API foundation

The mounted engine exposes a small JSON API for one owner's table preferences and presets.

```http
GET    /rails_table_preferences/preferences/:table_key
POST   /rails_table_preferences/preferences/:table_key
GET    /rails_table_preferences/preferences/:table_key/:name
PATCH  /rails_table_preferences/preferences/:table_key/:name
PUT    /rails_table_preferences/preferences/:table_key/:name
DELETE /rails_table_preferences/preferences/:table_key/:name
```

`name` is optional for single-preset operations and defaults to `default`. `POST` accepts `name`, `settings`, and optional `default`. `PATCH` and `PUT` also accept optional `default` to mark the preset as the default for that table. When one preset is marked default, other presets for the same owner and table are cleared.

Example request body:

```json
{
  "name": "inspection",
  "default": true,
  "settings": {
    "columns": [
      {
        "key": "customer_code",
        "visible": true,
        "order": 10,
        "width": 120,
        "truncate": 20
      }
    ]
  }
}
```

Example single preference response:

```json
{
  "table_key": "orders",
  "name": "default",
  "default": false,
  "settings": {
    "columns": [],
    "filters": {},
    "sorts": []
  }
}
```

Example collection response:

```json
{
  "table_key": "orders",
  "preferences": [
    {
      "table_key": "orders",
      "name": "default",
      "default": true,
      "settings": {
        "columns": [],
        "filters": {},
        "sorts": []
      }
    }
  ]
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

Current helper direction:

```erb
<% columns = [
  table_preferences_column(:order_no, model_name: :order, default_order: 10, default_width: 120),
  table_preferences_column(:customer_code, model_name: :order, default_order: 20, default_width: 120),
  table_preferences_column(:customer_name, model_name: :order, default_order: 30, default_width: 240, default_truncate: 30)
] %>

<%= table_preferences_editor(table_key: :orders, columns: columns, title: "Order table settings") %>

<%= table_preferences_table_tag(table_key: :orders, columns: columns, class: "table") do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="order_no">Order No.</th>
      <th data-rails-table-preferences-column-key="customer_code">Customer Code</th>
      <th data-rails-table-preferences-column-key="customer_name">Customer Name</th>
    </tr>
  </thead>
  <tbody>
    <% @orders.each do |order| %>
      <tr>
        <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
        <td data-rails-table-preferences-column-key="customer_code"><%= order.customer_code %></td>
        <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
      </tr>
    <% end %>
  </tbody>
<% end %>
```

The bundled Stimulus controller applies saved `visible`, `order`, `width`, and `truncate` values to cells marked with `data-rails-table-preferences-column-key`. The editor helper renders a preset selector, preset name input, default checkbox, Apply, Save, Save as new, Delete, and Reset buttons for the same settings payload.

The preset selector loads existing presets for the current table. Selecting a preset fetches that preset, merges it with the current column definitions, and applies it to the table. The preset name input controls the current preset name. Use Save to update the current preset, Save as new to create a named preset, Delete to remove it, and the default checkbox to mark a preset as the table default.

The editor rows are draggable. Drag a row up or down to reorder columns; the `order` inputs are automatically renumbered in steps of 10. Click Apply to update the current table without saving, or Save to persist the new order.

Header cells also receive a resize handle. Drag the handle horizontally to update the column width. The width is applied immediately, synchronized back to the editor width field, and persisted on Save.

## Legacy ColumnAdjustment import

Applications with an existing `ColumnAdjustment` model can import those records into `table_preferences`:

```bash
bin/rails rails_table_preferences:legacy:import_column_adjustments
```

Run a dry run first:

```bash
DRY_RUN=1 bin/rails rails_table_preferences:legacy:import_column_adjustments
```

If legacy records do not have `user`, `user_id`, `create_user`, or `create_user_id`, provide a fallback owner:

```bash
USER_ID=1 bin/rails rails_table_preferences:legacy:import_column_adjustments
```

The importer reads `setting_name`, `table_name`, and `value`, accepts legacy column keys such as `column_name`, `display_flag`, and `display_order`, and stores normalized settings in `table_preferences`.

## Development status

This gem is in the initial planning and skeleton stage.

## License

MIT License.

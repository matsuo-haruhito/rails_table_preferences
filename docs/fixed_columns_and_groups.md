# Fixed columns and column groups

Rails Table Preferences supports fixed column metadata and column group metadata.

The feature is intentionally lightweight. The gem stores and exposes the metadata, applies stable CSS hooks, and leaves final visual design to the host application.

## Fixed or pinned columns

Use either `fixed: true` or `pinned: true`.

`fixed:` is an alias intended for host application readability. Internally, both forms are normalized to `pinned: true`.

```ruby
columns = [
  table_preferences_column(:order_no, label: "受注番号", fixed: true, default_width: 120),
  table_preferences_column(:customer_name, label: "得意先名", default_width: 240),
  table_preferences_column(:amount, label: "金額", default_width: 120)
]
```

Equivalent form:

```ruby
table_preferences_column(:order_no, label: "受注番号", pinned: true)
```

## CSS hooks

Pinned cells receive stable CSS hooks through saved/default column metadata.

The default stylesheet includes sticky-column hooks:

```css
.rails-table-preferences-pinned,
.rails-table-preferences-fixed,
[data-rails-table-preferences-pinned="true"],
[data-rails-table-preferences-fixed="true"] {
  position: sticky;
  left: var(--rails-table-preferences-pinned-left, 0px);
  z-index: 2;
  background: var(--rails-table-preferences-pinned-background, canvas);
}
```

Host applications can override:

```css
.orders-table [data-rails-table-preferences-pinned="true"] {
  background: white;
  box-shadow: 0.25rem 0 0.5rem rgb(0 0 0 / 0.08);
}
```

## Multiple pinned columns

For multiple pinned columns, the host application may set explicit left offsets if the default automatic behavior is not enough for the table layout:

```erb
<th data-rails-table-preferences-column-key="order_no" style="--rails-table-preferences-pinned-left: 0px">受注番号</th>
<th data-rails-table-preferences-column-key="customer_name" style="--rails-table-preferences-pinned-left: 120px">得意先名</th>
```

The JavaScript controller keeps width, visibility, truncation, and order settings synchronized. Complex sticky offset policies remain host-app customizable because table layout, border spacing, horizontal scroll containers, and design systems differ widely.

## Column groups

Use `group:` to attach group metadata to a column.

```ruby
columns = [
  table_preferences_column(
    :customer_code,
    label: "得意先コード",
    group: { key: :customer, label: "得意先情報" }
  ),
  table_preferences_column(
    :customer_name,
    label: "得意先名",
    group: { key: :customer, label: "得意先情報" }
  ),
  table_preferences_column(
    :delivery_date,
    label: "納品日",
    group: { key: :delivery, label: "配送情報" }
  )
]
```

Short form:

```ruby
table_preferences_column(:customer_name, group: :customer)
```

The short form becomes:

```ruby
{ "key" => "customer", "label" => "customer" }
```

## What column groups do

Column groups are metadata. Rails Table Preferences preserves them in column definitions and export payloads.

They are useful for:

- custom editor grouping
- grouped table headers in host application ERB
- grouped CSV/Excel headers
- documentation or admin UI around table layout

Rails Table Preferences does not automatically rewrite your table header markup into multi-row grouped headers. The host application owns the table HTML.

## Example grouped header

```erb
<thead>
  <tr>
    <th colspan="2">得意先情報</th>
    <th colspan="1">配送情報</th>
  </tr>
  <tr>
    <th data-rails-table-preferences-column-key="customer_code">得意先コード</th>
    <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
    <th data-rails-table-preferences-column-key="delivery_date">納品日</th>
  </tr>
</thead>
```

The leaf header cells still need `data-rails-table-preferences-column-key` because the JavaScript controller applies settings to cells by column key.

## Export integration

Group metadata is preserved by `rails_table_preference_export_payload`:

```ruby
payload = rails_table_preference_export_payload(
  table_key: :orders,
  columns: columns
)

payload["columns"].first["group"]
```

See [Export integration](export_integration.md).

## Responsibility boundary

Rails Table Preferences owns:

- `fixed:` / `pinned:` metadata
- `group:` metadata
- stable CSS hooks
- settings persistence
- export payload metadata

Host applications own:

- table scroll container design
- final sticky offset policy
- grouped table header markup
- visual styling
- export file formatting

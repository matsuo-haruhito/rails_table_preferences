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

## Minimal horizontal scroll container

When a pinned table can be wider than the viewport, give it a dedicated horizontal scroll wrapper. This keeps sticky cells anchored inside the table scroller instead of the whole page.

Minimal ERB example with the bundled helper:

```erb
<div class="orders-table-scroll">
  <%= table_preferences_table_tag(
    table_key: :orders,
    columns: columns,
    class: "orders-table"
  ) do %>
    <thead>
      <tr>
        <th data-rails-table-preferences-column-key="order_no">受注番号</th>
        <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
        <th data-rails-table-preferences-column-key="amount">金額</th>
      </tr>
    </thead>
    <tbody>
      <% @orders.each do |order| %>
        <tr>
          <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
          <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
          <td data-rails-table-preferences-column-key="amount"><%= order.amount %></td>
        </tr>
      <% end %>
    </tbody>
  <% end %>
</div>
```

If the host app already owns the `<table>` markup, keep the same idea:

```erb
<div class="orders-table-scroll">
  <table class="orders-table">
    ...
  </table>
</div>
```

Minimal CSS baseline:

```css
.orders-table-scroll {
  max-width: 100%;
  overflow-x: auto;
}

.orders-table {
  min-width: 960px;
  border-collapse: separate;
}

.orders-table th,
.orders-table td {
  background: white;
}

.orders-table [data-rails-table-preferences-pinned="true"] {
  z-index: 3;
  background: white;
}
```

This example is intentionally small:

- the wrapper owns horizontal scrolling
- the table keeps a stable minimum width
- pinned cells get an opaque background so scrolled content does not bleed through
- final shadows, borders, and responsive polish stay in the host app

## Focus and layering checks

Pinned columns use `position: sticky`, a left offset, `z-index`, and an opaque background hook. Those defaults keep the gem predictable, but the host app still needs to verify the final stacking behavior with its real table markup and design system.

Before shipping a screen with pinned columns, check at least one horizontally scrolled state with representative interactive content:

- focused links, buttons, inputs, and filter buttons remain visible and clickable
- focus outlines are not clipped by the scroll wrapper or hidden behind a pinned cell
- pinned body cells, pinned header cells, filter panels, dropdowns, and surrounding app chrome have a clear `z-index` order
- pinned cells use an opaque background so scrolled content does not show through underneath focused controls
- the scroll container owns horizontal overflow without trapping keyboard focus outside the table workflow

For PR-level evidence, record the exact table or demo screen, scroll position, focused control or open filter button, viewport width, and whether the check used rendered browser evidence or a browser-capable handoff. Source inspection can support the review, but it is not enough by itself for focus outline, clipping, or stacking claims.

If a host app needs a different layering policy, override the provided CSS hooks near that table. For example, keep header cells above body cells, keep floating panels above pinned cells, and test the result with keyboard focus rather than relying only on mouse hover.

## Multiple pinned columns

For multiple pinned columns, the host application may set explicit left offsets if the default automatic behavior is not enough for the table layout:

```erb
<th data-rails-table-preferences-column-key="order_no" style="--rails-table-preferences-pinned-left: 0px">受注番号</th>
<th data-rails-table-preferences-column-key="customer_name" style="--rails-table-preferences-pinned-left: 120px">得意先名</th>
```

The JavaScript controller keeps width, visibility, truncation, and order settings synchronized. Complex sticky offset policies remain host-app customizable because table layout, border spacing, horizontal scroll containers, and design systems differ widely.

A practical rule of thumb is:

- start with one pinned column and the simple scroll wrapper above
- add explicit `--rails-table-preferences-pinned-left` offsets only when more than one pinned column must stay visible
- keep offset math near the table markup or host-app CSS, not inside a gem-level abstraction

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
- focus outline, z-index, and background checks for the app's real table content
- grouped table header markup
- visual styling
- export file formatting

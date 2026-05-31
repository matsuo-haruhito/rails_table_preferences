# Editor root HTML options

`table_preferences_editor(...)` accepts `html_options:` for host-app attributes that belong on the bundled editor root element.

Use it when the default partial is still correct, but the page needs a stable root `id`, an extra styling class, a generic `data-*` hook, or an `aria-*` attribute for placement inside a drawer, toolbar, modal, or analytics wrapper.

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: @table_columns,
  title: "受注一覧の表示設定",
  html_options: {
    id: "orders-table-settings",
    class: "drawer-panel",
    data: { turbo_frame: "orders_preferences", analytics_area: "orders" },
    aria: { label: "Orders table settings" }
  }
) %>
```

`resource_table_for(...)` and `tree_resource_table_for(...)` accept the same root-attribute payload as `editor_html_options:` when the bundled editor is rendered by the default resource table partial.

```erb
<%= resource_table_for(
  @orders,
  table_key: :orders,
  editor_html_options: {
    id: "orders-table-settings",
    class: "drawer-panel",
    data: { analytics_area: "orders" },
    aria: { label: "Orders table settings" }
  }
) %>
```

`editor_html_options:` is intentionally separate from table HTML options such as `id:`, `class:`, `data:`, and `aria:`. Table options continue to apply to the `<table>` element, while `editor_html_options:` applies only to the bundled editor root. `render_editor: false` still suppresses the bundled editor and ignores `editor_html_options:`.

The helper keeps the bundled `rails-table-preferences-editor` class and merges any host class you pass. Generic `data-*` values are rendered on the root element.

Rails Table Preferences-owned Stimulus wiring stays authoritative:

- `data-controller` remains `rails-table-preferences`.
- `data-rails-table-preferences-*` values such as table key, URLs, settings JSON, columns JSON, and status labels still come from the helper and bundled partial.
- Passing those keys through `html_options:` or `editor_html_options:` will not replace the gem-owned values.

`html_options:` and `editor_html_options:` are only for root attributes. They do not change the editor layout, preset controls, action buttons, generated internal ids, persistence behavior, authorization, or the bundled Stimulus controller contract. For structural changes inside the editor, copy the ERB partial instead and keep the data attributes documented in [Bundled editor i18n keys](editor_i18n.md) aligned with the controller.

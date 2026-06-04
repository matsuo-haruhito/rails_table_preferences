# Table data attribute merge boundary

`table_preferences_table_tag`, `resource_table_for`, and `tree_resource_table_for` let host apps pass ordinary table HTML options while Rails Table Preferences keeps the runtime data it needs.

## Host app controllers

When a host app passes its own Stimulus controller, Rails Table Preferences appends its controller token instead of replacing the host controller:

```erb
<%= resource_table_for(
  @orders,
  data: { controller: "orders-table", turbo_frame: "orders-frame" }
) %>
```

The rendered table includes both controller tokens, for example:

```html
<table data-controller="orders-table rails-table-preferences" data-turbo-frame="orders-frame">
```

If the host app already includes `rails-table-preferences`, the helper keeps only one copy of the token. The host controller token stays first, and the Rails Table Preferences token is still present so the bundled behavior can mount.

For an adoption-focused checklist, see [Coexisting table controllers manual QA](coexisting_table_controllers_manual_qa.md). It keeps the review on controller-token coexistence, generic host `data-*` preservation, and gem-owned runtime values without adding row selection, analytics, or inline edit behavior to Rails Table Preferences.

## Gem-owned data

Generic host app `data-*` attributes pass through. Runtime attributes owned by the gem, such as `data-rails-table-preferences-table-key-value`, `data-rails-table-preferences-settings-value`, and `data-rails-table-preferences-columns-value`, remain authoritative from Rails Table Preferences.

Use host app `data-*` attributes for surrounding UI, analytics, Turbo frames, or page-specific controllers. Do not rely on overriding `data-rails-table-preferences-*` values from HTML options; use the helper arguments such as `table_key:`, `name:`, `settings:`, and `columns:` instead.

## Scope

This merge behavior only affects rendered table attributes. It does not rename the bundled Stimulus controller, change the JavaScript mount path, or allow host apps to replace the gem-owned runtime settings payload.

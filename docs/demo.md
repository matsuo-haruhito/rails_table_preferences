# Demo screen generator

Rails Table Preferences can copy a lightweight demo screen into a host application for local browser verification.

Use this when you want to confirm the editor, table behavior, preference persistence, filters, sortable headers, fixed columns, and column groups before wiring the gem into a real business screen.

For a quick visual reference before generating the screen locally, see [Visual overview](visual_overview.md).

## Generate the demo

```bash
bin/rails generate rails_table_preferences:install --with-demo
```

This copies:

- `app/controllers/rails_table_preferences_demo/orders_controller.rb`
- `app/views/rails_table_preferences_demo/orders/index.html.erb`

The copied demo uses:

- the same owner model and current-owner method configured in `config/initializers/rails_table_preferences.rb`
- the normal `table_preferences` table for persistence
- in-memory sample rows for browser checks

The demo is intentionally lightweight. It is not a sample app, and it does not try to represent every possible host application layout.

## Demo routes

Add a route in the host application:

```ruby
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

Then visit:

```text
/rails_table_preferences_demo/orders
```

The sample rows are intentionally a little more practical than a three-row placeholder. They include repeated customer prefixes, varied statuses, dates, memo lengths, and one hidden internal-cost column so filter, sort, width, and truncation behavior are easier to spot.

The same screen now includes a lightweight export payload preview. It shows the ordered `headers` and `column_keys` that the current saved table settings would pass into `rails_table_preference_export_payload(...)`, so you can confirm hidden-column exclusion and saved order without wiring a real CSV action first.

The demo table also keeps `受注番号` pinned inside a dedicated horizontal scroll wrapper and renders a grouped header row (`受注情報` / `得意先情報` / `配送情報`). This gives you one narrow place to verify both fixed-column and column-group behavior before adding custom host-app table markup.

## Add routes

Mount the engine if it is not already mounted:

```ruby
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
```

The generated demo does not add this mount automatically because many host apps already mount the engine elsewhere.

## Demo owner prerequisites

Before opening the demo screen, make sure the host application has:

- run the generated migration
- configured `config.owner_model`
- configured `config.current_user_method`
- a persisted current owner record available in the demo request context

If the current owner is `nil`, the demo still renders, but owner-specific presets cannot be saved.

## Seeded presets

The copied controller seeds two representative presets when the screen opens:

- `共有ビュー`: a shared preset visible to everyone
- `担当ビュー`: a role preset for `operations`

This lets you confirm:

- a normal owner can load shared and role-scoped presets
- role-scoped defaults resolve before shared defaults when the host app returns the matching role in `scope_context_method`
- saving while a shared preset is selected creates or updates an owner preset instead of mutating the shared preset

The role preset appears only when the host app's configured scope context method returns `operations` in `roles`.

## Search form behavior

The generated demo includes a small GET search form that keeps saved filters and sort state through `table_preferences_hidden_fields(...)`.

This gives one practical place to confirm that:

- saved filter state becomes ordinary controller params again
- saved sort state becomes an ordinary `sort` param again
- the host app can merge search input and preference-derived hidden fields without custom JavaScript

## What the demo covers

The generated demo screen includes:

- Japanese column labels
- sample rows with repeated customer prefixes and varied status/date/memo values for practical sort and filter checks
- column visibility
- column order
- table-header drag ordering
- column width resizing
- fixed/pinned column metadata inside a horizontal scroll wrapper
- grouped header markup that mirrors column group metadata
- truncation metadata
- preset save/load/delete UI
- one shared preset example with read-only fallback behavior
- one role preset example with default resolution behavior
- a small GET search form wired through hidden fields
- a lightweight export payload preview that follows current saved column visibility/order

## What the demo does not cover

The generated demo is intentionally narrow. It does not try to cover:

- CSV file generation itself
- a real business controller or database-backed search object
- advanced sticky offset math for multiple pinned columns
- every host app layout or design system
- every scoped preset policy

For those, use the host application, sandbox app, or the more focused docs.

## What to check manually

On the demo screen, confirm:

- [ ] The editor appears above the table.
- [ ] The table appears with Japanese headers.
- [ ] The internal cost column does not appear.
- [ ] Apply hides and shows columns.
- [ ] Editor row drag changes column order.
- [ ] Table header drag changes column order.
- [ ] Header resize changes column width.
- [ ] Horizontally scrolling the demo wrapper keeps `受注番号` visible.
- [ ] After changing visibility or order, saving, and reloading, the grouped header row still matches the visible leaf headers.
- [ ] Filter panel opens.
- [ ] Searching for `東京` narrows the list to multiple matching rows.
- [ ] Header click cycles sort state.
- [ ] Sorting by `納品日` or `金額` makes the row order visibly change.

For the accessibility-side contract behind these checks, see [Accessibility baseline](accessibility.md).

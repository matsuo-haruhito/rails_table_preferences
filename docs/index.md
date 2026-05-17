# Rails Table Preferences documentation

This directory contains focused documentation for Rails Table Preferences.

## Start here

- [Practical examples](examples.md): realistic list-screen integrations for existing `search(params)` / `order_by(params[:sort])` controllers and Ransack controllers.
- [Controller integration](controller_integration.md): how to resolve saved preferences and pass filter/sort params to existing Rails controllers.
- [Filter metadata](filter_metadata.md): how to declare filterable/sortable columns and how neutral filter/sort settings are stored.
- [Filter adapters](filter_adapters.md): adapter strategy for Ransack, Datagrid, Filterrific, and host application search objects.
- [JavaScript controller notes](javascript_controller.md): responsibilities, event boundaries, and safety invariants for the bundled Stimulus controller.

## Recommended integration order

1. Install the gem and run the generated migration.
2. Mount the engine if you use the bundled JSON API.
3. Define table columns with `table_preferences_column`.
4. Render `table_preferences_editor` and `table_preferences_table_tag`.
5. Add `filter:` and `sortable: true` metadata where needed.
6. Use `rails_table_preference_params` or `rails_table_preference_merged_params` in controllers.
7. Use `table_preferences_hidden_fields` when saved filter/sort params should be submitted through an existing search form.

## Responsibility boundary

Rails Table Preferences owns:

- table display preference UI
- column visibility, order, width, and truncation settings
- saved presets and default presets
- filter/sort UI state
- adapter params for host applications or search gems

Host applications own:

- actual database search execution
- authorization
- joins and association search logic
- business-specific query behavior
- final styling and UI polish

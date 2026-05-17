# Rails Table Preferences documentation

This directory contains focused documentation for Rails Table Preferences.

## Start here

- [Quick start](quick_start.md): the shortest path from installation to a working table preference UI.
- [Decision guide](decision_guide.md): choose the right helper, adapter, or option for common use cases.
- [Scoped presets](scoped_presets.md): owner, shared, role, and organization scoped presets and default resolution.
- [Fixed columns and column groups](fixed_columns_and_groups.md): `fixed:` / `pinned:` columns, sticky CSS hooks, and `group:` metadata.
- [Export integration](export_integration.md): reuse saved column visibility/order/labels when building CSV, Excel, or report exports in the host app.
- [Accessibility baseline](accessibility.md): what the bundled editor/controller provide and what the host app still owns.
- [Demo screen generator](demo.md): `--with-demo` generator option for copying a lightweight browser verification screen into a host app.
- [Sandbox Rails app verification](sandbox.md): minimal Rails app setup for end-to-end verification before real app integration.
- [Practical examples](examples.md): realistic list-screen integrations for existing `search(params)` / `order_by(params[:sort])` controllers and Ransack controllers.
- [Troubleshooting](troubleshooting.md): common installation, Stimulus, CSS, API, filter/sort, and customization issues.
- [Manual QA checklist](manual_qa.md): browser and host application checks to run before asking real users to try the feature.
- [Release checklist](release_checklist.md): packaging, generator, CI, documentation, and sandbox checks before tagging or publishing a release.
- [Package verification](package_verification.md): build and inspect the gem package before tagging or publishing a release.
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
6. Use `fixed:` / `pinned:` and `group:` metadata only when the table needs fixed columns or grouped headers/exports.
7. Use the decision guide when choosing between controller params, hidden fields, Ransack, ignored columns, scoped presets, exports, and customization options.
8. Configure `scope_context_method` only if shared, role, or organization presets are needed.
9. Use `rails_table_preference_params` or `rails_table_preference_merged_params` in controllers.
10. Use `rails_table_preference_export_payload` when CSV/Excel/report exports should follow saved column settings.
11. Use `table_preferences_hidden_fields` when saved filter/sort params should be submitted through an existing search form.
12. Review the accessibility baseline for screens with custom styling or stricter keyboard requirements.
13. Optionally generate the demo screen with `--with-demo` for quick local browser verification.
14. Verify the feature in a sandbox Rails app.
15. Run the manual QA checklist before asking real users to try the feature.
16. Before release, run the release checklist and package verification guide.

## Responsibility boundary

Rails Table Preferences owns:

- table display preference UI
- column visibility, order, width, and truncation settings
- fixed/pinned column metadata and CSS hooks
- column group metadata
- owner, shared, role, and organization scoped presets
- saved presets and default presets
- filter/sort UI state
- adapter params for host applications or search gems
- export column payloads derived from saved display preferences
- baseline accessibility hooks for generated controls

Host applications own:

- actual database search execution
- authorization
- joins and association search logic
- business-specific query behavior
- semantic page/table structure around the generated controls
- sticky column offset and scroll-container polish for complex layouts
- grouped table header markup
- CSV, Excel, and report file generation
- administration UI for shared, role, or organization presets
- final styling and UI polish

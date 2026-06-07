# Rails Table Preferences documentation

This directory contains focused documentation for Rails Table Preferences.

## Start here

- [Quick start](quick_start.md): the shortest path from installation to a working table preference UI.
- [Production integration checklist](production_integration_checklist.md): the short path from a working demo or quick start to a real host-app index screen.
- [Production troubleshooting notes](production_troubleshooting.md): symptom-driven checks for CSRF 422s, auth redirects, owner lookup failures, unstable `table_key` values, duplicate preset names, and saved presets that do not return on real host-app screens.
- [日本語 quick start](quick_start_ja.md): a low-drift Japanese entrypoint for the main installation, editor, preset, filter/sort, export, and QA workflows.
- [Install path options](install_paths.md): choose the smallest generator option set for default `stimulus-rails`, Vite/package entrypoint, skipped copied assets, or demo verification paths.
- [Support matrix](support_matrix.md): Ruby/Rails runtime requirements, representative CI coverage, and host-app verification guidance for newer Rails releases.
- [Resource table adapters](resource_tables.md): infer user-facing columns from Active Record metadata, apply profile overrides, and register host-owned renderer mappings for TreeView or Rails Fields Kit controls.
- [Resource table editor placement checklist](render_editor_placement_manual_qa.md): focused evidence for `render_editor: false` screens that place the editor in a toolbar, drawer, tab, sidebar, or separate partial.
- [Resource table cell hooks](resource_table_cell_hooks.md): stable body-cell data attributes for light host-app styling and the boundary with custom partials.
- [Table data attribute merge boundary](table_data_attributes.md): host app `data-controller` coexistence and gem-owned `data-rails-table-preferences-*` protection rules for rendered tables.
- [Resource table formatter contract](resource_table_formatter_contract.md): formatter arity, nil-return fallback, and host-app responsibility boundaries for profile display/cell/column blocks.
- [Virtual column query boundary](virtual_columns_query_boundary.md): practical virtual/computed column examples that keep joins, preloading, filtering, and sorting in host-app code.
- [Decision guide](decision_guide.md): choose the right helper, adapter, or option for common use cases.
- [Scoped presets](scoped_presets.md): owner, shared, role, and organization scoped presets, default resolution, and minimal operating patterns.
- [Preset selector scope labels](preset_selector_scope_labels.md): package entrypoint and copied/base controller scope-label display boundaries for owner and non-owner presets.
- [Preset name save boundary](preset_name_save_boundary.md): selector, preset name input, save, and save-as-new wording boundaries so host-app copy does not imply an in-place rename API.
- [Fixed columns and column groups](fixed_columns_and_groups.md): `fixed:` / `pinned:` columns, sticky CSS hooks, horizontal scroll-container baseline, and `group:` metadata.
- [Column overflow metadata](column_overflow.md): canonical `overflow:` / `default_overflow:` values, compatibility aliases, the boundary with `default_truncate:`, and why overflow mode is host-owned rather than edited in the bundled editor.
- [Resize and auto-fit guidance](resize_auto_fit.md): resize handle root values, double-click auto-fit bounds, and the manual QA focus for dense or horizontally scrolled tables.
- [Export integration](export_integration.md): reuse saved column visibility/order/labels when building CSV, Excel, or report exports in the host app.
- [Accessibility baseline](accessibility.md): what the bundled editor/controller provide and what the host app still owns.
- [Active filter button cue](active_filter_button_cue.md): default active-filter visual cue, host-app styling boundary, and manual QA checks.
- [Bundled editor i18n keys](editor_i18n.md): preset/action/reset/filter/sort/scope/status locale keys and the boundary between locale overrides, controller-root values, copied ERB, and copied JavaScript.
- [Editor root HTML options](editor_root_options.md): add host-app root `id`, class, generic `data-*`, and `aria-*` attributes without copying the bundled editor partial.
- [Non-goals and deferred directions](non_goals.md): intentionally deferred areas such as query builder behavior, CSV/Excel generation, full admin UI, heavy browser tests, and complex sticky layouts.
- [Visual overview](visual_overview.md): representative screen illustrations for the editor, shared/scoped preset orientation, generated demo owner/scope cues, export preview, filter/sort state, and pinned-column table layout.
- [Demo screen generator](demo.md): `--with-demo` and `--with-demo-route` generator options for copying a lightweight browser verification screen into a host app.
- [Sandbox Rails app verification](sandbox.md): minimal Rails app setup for end-to-end verification before real app integration.
- [Practical examples](examples.md): realistic list-screen integrations for existing `search(params)` / `order_by(params[:sort])` controllers and Ransack controllers.
- [Helper-free controller root URLs](helper_free_controller_root_urls.md): collection/member URL ownership when an existing table partial mounts `data-controller="rails-table-preferences"` manually.
- [Troubleshooting](troubleshooting.md): common installation, Stimulus, CSS, API, filter/sort, scoped preset, legacy import, and customization issues.
- [Select filter troubleshooting](select_filter_troubleshooting.md): `values_param`, scalar select options, and host-app query ownership when select filters do not affect results.
- [Manual QA checklist](manual_qa.md): browser and host application checks to run before asking real users to try the feature.
- [Manual QA PR smoke matrix](manual_qa_pr_smoke_matrix.md): PR-scoped quick smoke guidance for docs-only, UI, helper, generator, export, layout, and scoped preset changes.
- [Hidden fields pagination evidence](hidden_fields_pagination_evidence.md): focused evidence guidance for old `page` params when saved filter/sort hidden fields roundtrip through existing search forms.
- [Release checklist](release_checklist.md): packaging, generator, CI, documentation, and sandbox checks before tagging or publishing a release.
- [Package verification](package_verification.md): build and inspect the gem package before tagging or publishing a release.
- [Mounted JSON API](json_api.md): owner preset endpoints, request/response payloads, and the boundary with non-owner scoped preset administration.
- [Controller integration](controller_integration.md): how to resolve saved preferences and pass filter/sort params to existing Rails controllers.
- [Filter metadata](filter_metadata.md): how to declare filterable/sortable columns and how neutral filter/sort settings are stored.
- [Filter adapters](filter_adapters.md): adapter strategy for Ransack, Datagrid, Filterrific, and host application search objects.
- [JavaScript entrypoints](javascript_entrypoints.md): Stimulus registration paths for default `stimulus-rails`, Vite, `app/frontend`, custom JS bundlers, and Turbo reconnect checks.
- [JavaScript controller notes](javascript_controller.md): responsibilities, event boundaries, and safety invariants for the bundled Stimulus controller.

## Maintainer entry

- [Product Profile](https://github.com/matsuo-haruhito/rails_table_preferences/blob/main/Product%20Profile.md): concise maintainer-facing overview of the product surface, responsibility boundary, and release posture.
- [AGENTS.md](https://github.com/matsuo-haruhito/rails_table_preferences/blob/main/AGENTS.md): repository guardrails, source-of-truth order, and change boundaries for assisted maintenance work.
- [CHANGELOG.md](../CHANGELOG.md): current unreleased scope and release narrative.

## Recommended integration order

1. Install the gem and run the generated migration.
2. Use the production integration checklist when moving from the quick start or demo screen to a real host-app index screen.
3. Mount the engine if you use the bundled JSON API.
4. Confirm the Stimulus controller registration path for the host app. Use the default manifest for `stimulus-rails`, or the package entrypoint for Vite / `app/frontend` apps.
5. For convention-first tables, try `resource_table_for @records` and review [Resource table adapters](resource_tables.md).
6. If the inferred resource table only needs light cell styling, use [Resource table cell hooks](resource_table_cell_hooks.md) before copying the default partial.
7. If the inferred resource table should render filter inputs or cell editors through a form-helper library, use the renderer registry context examples from [Resource table adapters](resource_tables.md) before copying a custom partial.
8. For manually controlled tables, define table columns with `table_preferences_column`.
9. Render `table_preferences_editor` and `table_preferences_table_tag`.
10. Use `html_options:` from [Editor root HTML options](editor_root_options.md) when the bundled editor root needs host-app placement attributes without copying the partial.
11. When `render_editor: false` moves a resource table editor into a toolbar, drawer, tab, sidebar, or separate partial, use the [Resource table editor placement checklist](render_editor_placement_manual_qa.md) to record placement evidence without changing the helper contract.
12. Add `filter:` and `sortable: true` metadata where needed.
13. Choose `overflow:` / `default_overflow:` values when text should ellipsize, clip, wrap, or stay single-line.
14. Tune [resize and auto-fit root values](resize_auto_fit.md) only when dense headers, custom scroll containers, or host-app CSS make the defaults hard to use.
15. Use `fixed:` / `pinned:` and `group:` metadata only when the table needs fixed columns or grouped headers/exports.
16. Use the decision guide when choosing between controller params, hidden fields, Ransack, ignored columns, scoped presets, exports, and customization options.
17. Configure `scope_context_method` only if shared, role, or organization presets are needed.
18. Use `rails_table_preference_params` or `rails_table_preference_merged_params` in controllers.
19. Use `rails_table_preference_export_payload` when CSV/Excel/report exports should follow saved column settings.
20. Use `table_preferences_hidden_fields` when saved filter/sort params should be submitted through an existing search form.
21. Review [Hidden fields pagination evidence](hidden_fields_pagination_evidence.md) when the existing search form can also submit an old `page` param.
22. Review the accessibility baseline for screens with custom styling or stricter keyboard requirements.
23. Review [Active filter button cue](active_filter_button_cue.md) when validating the default active-filter visual affordance in a host-app theme.
24. Review [Bundled editor i18n keys](editor_i18n.md) before copying ERB or JavaScript for wording-only changes.
25. Review non-goals before adding behavior that looks like a query builder, export generator, admin framework, heavy browser test stack, or complex sticky layout engine.
26. Optionally generate the demo screen with `--with-demo`, or `--with-demo-route` when the route should be added at the same time, after confirming the configured current-owner method returns a persisted owner record.
27. Verify the feature in a sandbox Rails app.
28. Review [Support matrix](support_matrix.md) when the host app's Ruby/Rails version is outside the currently documented representative CI matrix.
29. Run the manual QA checklist before asking real users to try the feature.
30. Before release, run the release checklist and package verification guide.

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
- resource table column inference and profile overrides when the helper path is used
- resource table body-cell metadata hooks for light host-app styling
- renderer registry lookup for filter/editor metadata when a host app registers renderers
- export column payloads derived from saved display preferences
- baseline accessibility hooks for generated controls

Host applications own:

- actual database search execution
- authorization
- joins and association logic
- business-specific query behavior
- semantic page/table structure around the generated controls
- sticky column offset and scroll-container polish for complex layouts
- grouped table header markup
- cell styling rules, badges, and complex custom table presentation
- renderer registrations and concrete form-helper HTML for filter/editor metadata
- CSV, Excel, and report file generation
- administration UI for shared, role, or organization presets
- final styling and UI polish

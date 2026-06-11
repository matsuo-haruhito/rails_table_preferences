# Preset selector scope labels

Rails Table Preferences has two JavaScript controller paths for the bundled editor:

- the copied/base controller path, used when a host app copies or registers the generated controller directly
- the package entrypoint controller path, used when the host app imports the packaged controller from `rails_table_preferences`

Both paths resolve the same preset payloads and keep the same resolver priority. The difference is only the selector cue shown to the user.

## Display policy

The package entrypoint controller keeps the scope label visible in the preset selector whenever a preset payload or fallback label provides one. That means an owner preset can appear as `default [Owner]` or `default [Personal]` when the packaged controller has a readable owner label.

This is intentional package-entrypoint behavior. The packaged controller is the path that adds the newer editor affordances, so it keeps scoped preset identity explicit even for owner presets. This helps a screen that mixes owner, role, organization, and shared presets make every option's scope visible without changing API response shape or resolver priority.

The copied/base controller stays more compact. It only adds the scope mark for non-owner presets, so owner-only copied-editor screens do not gain extra label noise. Host apps that copy the base controller and want the package-entrypoint cue should copy or replace that display behavior intentionally instead of assuming the two paths are identical.

## Preset selector search

The package entrypoint also adds a lightweight preset search field when the preset collection is large enough to need an extra scan cue. The search filters the native selector candidates by preset name, user-facing scope label, and raw scope type. It keeps the existing native `<select>` and `<optgroup>` structure instead of replacing it with a custom listbox.

The search is only a navigation affordance for the package entrypoint selector. It does not change the JSON response fields, the option value, the scope grouping order, default markers, editability metadata, or `data-scope-type` / `data-scope-key` attributes that the selector options already carry. Clearing the query restores the full owner / role / organization / shared grouping.

When a query has no matches, the selector is disabled and the package entrypoint shows a no-results message. That state should not load, save, delete, or infer another preset. Users can clear or change the query to return to the complete selector.

The copied/base controller does not get this search field automatically. Host apps that copied the base controller can keep their compact selector, copy the package-entrypoint pattern intentionally, or provide a host-owned preset search UI around their own admin surface.

## What does not change

This display policy and package-entrypoint search do not change:

- JSON response fields
- default or named preset resolution order
- same-name preset fallback behavior
- save, save-as-new, or delete behavior
- read-only handling for shared, role, or organization presets
- host-app authorization or scoped preset management policy

Use clear preset names when users must compare several presets in the selector. The scope label and search field are scan cues, not a duplicate-name disambiguation system.

## Related docs

- `docs/scoped_presets.md` describes scope types, resolver priority, selector grouping, and fallback labels.
- `docs/editor_i18n.md` lists the locale keys and controller-root values that feed scope labels.
- `docs/javascript_entrypoints.md` explains when a host app is using the package entrypoint instead of a copied controller path.

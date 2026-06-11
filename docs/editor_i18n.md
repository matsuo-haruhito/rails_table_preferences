# Bundled editor i18n keys

The bundled editor reads most visible copy through Rails I18n before the Stimulus controller runs. Host applications can override those keys in their locale files when the bundled markup and behavior are still acceptable.

This guide lists the main keys that are useful during host-app integration. It is not a replacement for checking `config/locales/*.yml` and `app/views/rails_table_preferences/_editor.html.erb` when changing the gem itself.

## Preset controls

These keys label the saved preset selector, preset name input, and default preset checkbox:

- `rails_table_preferences.editor.preset_select`
- `rails_table_preferences.editor.preset`
- `rails_table_preferences.editor.default_preset`
- `rails_table_preferences.editor.preset_select_hint`
- `rails_table_preferences.editor.preset_name_hint`
- `rails_table_preferences.editor.default_preset_hint`
- `rails_table_preferences.editor.read_only_preset_hint`

Use locale overrides when the host app wants different wording for the same controls. Copy the ERB partial only when the host app needs different fields, helper-text placement, or preset-control markup.

In the current bundled editor, the preset selector is the source for loading or switching saved settings, while the preset name input is the destination name used by save and save as new. If a user selects an existing preset, changes the name input, and saves, the bundled editor treats the typed name as the save target; it does not present that action as an in-place rename of the previously selected preset. Keep host-app copy close to that boundary when overriding the selector hint, name hint, or action hint. For focused review steps, see [Preset name save boundary](preset_name_save_boundary.md).

When the selected preset is read-only, the bundled save action does not overwrite that scoped preset. It creates or updates an owner preset instead, using the current preset name input as the owner preset name. The selected read-only preset name is loaded into that input first, so users can keep the same visible name or change the input before saving a personal copy. If an owner preset with that name already exists, the bundled editor keeps the existing API failure path; host apps that need detailed duplicate-name guidance should customize the failure copy or controller behavior separately.

## Actions and reset copy

These keys drive the bundled action buttons, button context, delete confirmation, and reset helper copy:

- `rails_table_preferences.editor.apply`
- `rails_table_preferences.editor.apply_context`
- `rails_table_preferences.editor.save`
- `rails_table_preferences.editor.save_context`
- `rails_table_preferences.editor.save_as_new`
- `rails_table_preferences.editor.save_as_new_context`
- `rails_table_preferences.editor.action_hint`
- `rails_table_preferences.editor.delete`
- `rails_table_preferences.editor.delete_confirm`
- `rails_table_preferences.editor.reset`
- `rails_table_preferences.editor.reset_hint`
- `rails_table_preferences.editor.reset_visible_hint`

The context keys are used in `title` / `aria-label` text so users can tell whether an action applies the current view, saves to the current preset name, or creates a new preset.

`delete_confirm` provides the base confirmation sentence. The bundled controller appends the selected preset display name from the preset selector, including any scope label already present in the option text, to the native confirmation message and the delete button's `title` / `aria-label`. Override the locale key for wording, and copy the controller only when the host app needs a different delete-confirmation composition or custom modal.

The bundled reset action keeps its existing behavior: it discards unsaved editor changes and reapplies the table's default column settings from the current column definitions. It does not roll back to the preset that was last loaded from the selector. Host apps that need a "return to loaded preset" affordance should provide separate copy, markup, or controller behavior instead of reusing the bundled reset wording.

## Column editor labels

These keys label generated editor rows and table-header affordances:

- `rails_table_preferences.editor.order`
- `rails_table_preferences.editor.width`
- `rails_table_preferences.editor.truncate`
- `rails_table_preferences.editor.drag_to_reorder`
- `rails_table_preferences.editor.resize_column`

These are safe locale override points for wording changes. Structural changes to row layout, drag behavior, resize behavior, or keyboard behavior require copied ERB / JavaScript or host-app code.

## Editor search and move labels

The package entrypoint adds column search and row move controls after the bundled editor markup is rendered. The ERB partial passes the copy to controller-root values so packaged-controller screens can localize these affordances without copying JavaScript:

- `rails_table_preferences.editor.search_columns` feeds `data-rails-table-preferences-editor-search-label-value`
- `rails_table_preferences.editor.search_columns_placeholder` feeds `data-rails-table-preferences-editor-search-placeholder-value`
- `rails_table_preferences.editor.no_search_results` feeds `data-rails-table-preferences-editor-no-search-results-label-value`
- `rails_table_preferences.editor.move_up` feeds `data-rails-table-preferences-move-up-label-value`
- `rails_table_preferences.editor.move_down` feeds `data-rails-table-preferences-move-down-label-value`

Use locale overrides for global wording changes, or override those controller-root values on one mounted editor when a single screen needs different copy.

These values are package entrypoint-only behavior. Host apps that register the copied base controller directly should not assume the search field or move buttons exist just because the ERB emits the root values. Use copied or replacement JavaScript when a copied-controller screen needs the same controls, different movement behavior, or a different search UI. Keep browser QA for the actual affordances in [Editor entrypoint affordances](editor_entrypoint_affordances.md).

## Filter and sort labels

The bundled editor passes these values to the controller root so the Stimulus controller can reuse localized labels in filter panels, filter buttons, sort controls, `title`, and `aria-label` text:

- `rails_table_preferences.editor.filter`
- `rails_table_preferences.editor.apply`
- `rails_table_preferences.editor.filter_clear`
- `rails_table_preferences.editor.filter_operator`
- `rails_table_preferences.editor.filter_operator_labels.*`
- `rails_table_preferences.editor.filter_value`
- `rails_table_preferences.editor.filter_from`
- `rails_table_preferences.editor.filter_to`
- `rails_table_preferences.editor.sort_asc`
- `rails_table_preferences.editor.sort_desc`
- `rails_table_preferences.editor.sort_clear`

Host apps can also override the generated controller-root attributes for a single mounted table, such as `data-rails-table-preferences-filter-label-value` or `data-rails-table-preferences-sort-asc-label-value`, when one screen needs wording that differs from the global locale.

Filter operator option text such as `contains`, `equals`, or range-specific summaries is controller vocabulary. The bundled editor now emits `rails_table_preferences.editor.filter_operator_labels` as `data-rails-table-preferences-filter-operator-labels-value`, so packaged-controller tables can change operator wording through locale overrides without copying the controller:

```yaml
ja:
  rails_table_preferences:
    editor:
      filter_operator_labels:
        contains: 含める
        equals: 完全一致
```

The same value can still be overridden per controller root when a single mounted table needs different wording:

```erb
data-rails-table-preferences-filter-operator-labels-value='<%= { contains: "含める", equals: "完全一致" }.to_json %>'
```

The value is a JSON object keyed by operator name. Operators omitted from the object keep the bundled defaults, and unknown custom operators fall back to the raw operator string unless the object provides a label.

This root value is provided by the package entrypoint subclass. Host apps that copy or register the base generated controller directly should not assume the package entrypoint-only value is present; use copied or replacement JavaScript when changing controller behavior, adding new operators, or supporting a controller path that does not include the package entrypoint subclass. See [JavaScript entrypoints](javascript_entrypoints.md) before relying on package-only controller behavior from a copied or host-owned controller path.

## Scope labels

The controller uses these as fallback labels when a saved preset payload does not provide a `scope_label`:

- `rails_table_preferences.editor.scope_owner`
- `rails_table_preferences.editor.scope_shared`
- `rails_table_preferences.editor.scope_role`
- `rails_table_preferences.editor.scope_organization`

Use payload-provided `scope_label` values for business-specific labels when the server already knows the human-readable owner, role, or organization name. Use locale overrides for generic fallback wording.

## Status region copy

The bundled editor exposes a live status region for async preset actions. These keys feed its progress, success, and failure messages:

- `rails_table_preferences.editor.status_region`
- `rails_table_preferences.editor.loading_status`
- `rails_table_preferences.editor.loaded_status`
- `rails_table_preferences.editor.loading_failed_status`
- `rails_table_preferences.editor.saving_status`
- `rails_table_preferences.editor.saved_status`
- `rails_table_preferences.editor.saving_failed_status`
- `rails_table_preferences.editor.saving_as_new_status`
- `rails_table_preferences.editor.saved_as_new_status`
- `rails_table_preferences.editor.saving_as_new_failed_status`
- `rails_table_preferences.editor.deleting_status`
- `rails_table_preferences.editor.deleted_status`
- `rails_table_preferences.editor.deleting_failed_status`
- `rails_table_preferences.editor.operation_failed_status`
- `rails_table_preferences.editor.resize_auto_fit_status`

`resize_auto_fit_status` is package-entrypoint-only success copy for Enter / Space auto-fit on a focused resize handle. It feeds `data-rails-table-preferences-resize-auto-fit-status-label-value` and is shown in the same status region after the one-shot auto-fit shortcut completes.

Use locale overrides for message wording. Use copied ERB / JavaScript when the host app wants a different status surface, notification system, busy-state behavior, or copied-controller support for package-entrypoint-only resize auto-fit feedback.

## Minimal host-app override example

```yaml
ja:
  rails_table_preferences:
    editor:
      preset_select: 表示設定
      apply: 画面に反映
      save: この設定を保存
      save_as_new: 新しい設定として保存
      action_hint: 画面に反映は現在の表示だけを更新し、保存は入力欄の設定名へ反映します。
      search_columns: 表示列を検索
      search_columns_placeholder: 列名・キー・グループで絞り込み
      no_search_results: 一致する列がありません。
      move_up: 1つ上へ移動
      move_down: 1つ下へ移動
      filter: 条件で絞り込む
      filter_operator_labels:
        contains: 含める
        equals: 完全一致
      sort_asc: 昇順で並び替え
      sort_desc: 降順で並び替え
      saved_status: 表示設定を保存しました。
      saving_failed_status: 表示設定を保存できませんでした。
      resize_auto_fit_status: 列幅を自動調整しました。
```

Keep overrides close to the host app's normal locale files so copied ERB and copied JavaScript stay unnecessary for wording-only changes.

## Choosing the customization path

Use the lightest path that matches the change:

1. Locale keys for global wording changes across every bundled editor.
2. Controller-root `data-rails-table-preferences-*-label-value` attributes when one mounted table needs different filter, sort, scope fallback, editor search, row move, or resize auto-fit status wording.
3. Package entrypoint `data-rails-table-preferences-filter-operator-labels-value` when a packaged-controller table only needs different filter operator display text.
4. Package entrypoint editor search / move label values when the packaged-controller table only needs different search or move button copy.
5. Copied ERB when markup, helper-text placement, or status-region structure needs to change.
6. Copied or replacement JavaScript when controller behavior, operator semantics, busy-state logic, editor search behavior, row movement, or resize auto-fit status handling needs to change.

See [Accessibility baseline](accessibility.md) for accessibility surfaces that consume these labels, [Editor entrypoint affordances](editor_entrypoint_affordances.md) for the package-only browser QA surface, and [JavaScript controller notes](javascript_controller.md) for the controller-root value contract.
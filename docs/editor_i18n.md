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

## Column editor labels

These keys label generated editor rows and table-header affordances:

- `rails_table_preferences.editor.order`
- `rails_table_preferences.editor.width`
- `rails_table_preferences.editor.truncate`
- `rails_table_preferences.editor.drag_to_reorder`
- `rails_table_preferences.editor.resize_column`

These are safe locale override points for wording changes. Structural changes to row layout, drag behavior, resize behavior, or keyboard behavior require copied ERB / JavaScript or host-app code.

## Filter and sort labels

The bundled editor passes these values to the controller root so the Stimulus controller can reuse localized labels in filter panels, filter buttons, sort controls, `title`, and `aria-label` text:

- `rails_table_preferences.editor.filter`
- `rails_table_preferences.editor.apply`
- `rails_table_preferences.editor.filter_clear`
- `rails_table_preferences.editor.filter_operator`
- `rails_table_preferences.editor.filter_value`
- `rails_table_preferences.editor.filter_from`
- `rails_table_preferences.editor.filter_to`
- `rails_table_preferences.editor.sort_asc`
- `rails_table_preferences.editor.sort_desc`
- `rails_table_preferences.editor.sort_clear`

Host apps can also override the generated controller-root attributes for a single mounted table, such as `data-rails-table-preferences-filter-label-value` or `data-rails-table-preferences-sort-asc-label-value`, when one screen needs wording that differs from the global locale.

Filter operator option text such as `contains`, `equals`, or range-specific summaries is still controller vocabulary. Use copied or replacement JavaScript if a host app needs to change behavior or vocabulary that is not exposed through locale keys or root values.

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

Use locale overrides for message wording. Use copied ERB / JavaScript when the host app wants a different status surface, notification system, or busy-state behavior.

## Minimal host-app override example

```yaml
ja:
  rails_table_preferences:
    editor:
      preset_select: 表示設定
      apply: 画面に反映
      save: この設定を保存
      save_as_new: 新しい設定として保存
      action_hint: 画面に反映は現在の表示だけを更新し、保存は選択中の設定へ反映します。
      filter: 条件で絞り込む
      sort_asc: 昇順で並び替え
      sort_desc: 降順で並び替え
      saved_status: 表示設定を保存しました。
      saving_failed_status: 表示設定を保存できませんでした。
```

Keep overrides close to the host app's normal locale files so copied ERB and copied JavaScript stay unnecessary for wording-only changes.

## Choosing the customization path

Use the lightest path that matches the change:

1. Locale keys for global wording changes across every bundled editor.
2. Controller-root `data-rails-table-preferences-*-label-value` attributes when one mounted table needs different filter, sort, or scope fallback wording.
3. Copied ERB when markup, helper-text placement, or status-region structure needs to change.
4. Copied or replacement JavaScript when controller behavior, filter operator vocabulary, busy-state logic, or filter panel interaction needs to change.

See [Accessibility baseline](accessibility.md) for accessibility surfaces that consume these labels, and [JavaScript controller notes](javascript_controller.md) for the controller-root value contract.

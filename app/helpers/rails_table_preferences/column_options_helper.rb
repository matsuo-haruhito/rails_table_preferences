# frozen_string_literal: true

module RailsTablePreferences
  module TablePreferencesHelper
    def table_preferences_column(key, label: nil, model: nil, model_name: nil, i18n_key: nil, default_visible: true, default_order: nil, default_width: nil, default_truncate: nil, pinned: false, fixed: nil, group: nil, ignored: false, ignore: nil, filter: nil, sortable: nil, sort_param: nil)
      ColumnDefinition.new(
        key: key,
        label: label,
        model: model,
        model_name: model_name,
        i18n_key: i18n_key,
        default_visible: default_visible,
        default_order: default_order,
        default_width: default_width,
        default_truncate: default_truncate,
        pinned: pinned,
        fixed: fixed,
        group: group,
        ignored: ignored,
        ignore: ignore,
        filter: filter,
        sortable: sortable,
        sort_param: sort_param
      ).to_h
    end
  end
end
